import unittest
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pyodbc
from flask import Flask

from dao import manager_dao
from routes.manager_routes import manager_bp


class ManagerRoutesTest(unittest.TestCase):
    def setUp(self):
        app = Flask(__name__)
        app.register_blueprint(manager_bp, url_prefix='/manager')
        self.client = app.test_client()
        self.user = dict(id_user='employee1', nom='Test', prenom='User',
                         cin='01234567', role='employee', pw_user='secret',
                         teleph='12345678', date_naiss='2000-01-01')

    def test_dashboard_contract(self):
        payload = dict(stats={'products': 0}, products=[], invoices=[], users=[])
        with patch('routes.manager_routes.get_manager_dashboard', return_value=payload):
            response = self.client.get('/manager/dashboard')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, dict(success=True, **payload))

    def test_invoice_found_and_missing(self):
        with patch('routes.manager_routes.get_manager_invoice', return_value={'id': 1}):
            self.assertEqual(self.client.get('/manager/invoices/1').json['invoice']['id'], 1)
        with patch('routes.manager_routes.get_manager_invoice', return_value=None):
            self.assertEqual(self.client.get('/manager/invoices/1').status_code, 404)

    def test_directory(self):
        with patch('routes.manager_routes.get_manager_users', return_value=[]):
            self.assertEqual(self.client.get('/manager/users').json, {'success': True, 'users': []})

    def test_create_both_roles_and_discard_extra_fields(self):
        for role in ('employee', 'supplier'):
            with self.subTest(role=role), patch('routes.manager_routes.create_manager_user',
                    return_value={'id_user': 'employee1', 'role': role}) as create:
                response = self.client.post('/manager/users', json={**self.user, 'role': role, 'extra': 'ignored'})
                self.assertEqual(response.status_code, 201)
                self.assertNotIn('pw_user', response.json['user'])
                data = create.call_args.args[0]
                self.assertEqual(data['cin'], '01234567')
                self.assertNotIn('extra', data)

    def test_invalid_payloads_do_not_reach_database(self):
        changes = [dict(role='manager'), dict(cin='123'), dict(cin='abcdefgh'),
                   dict(id_user=''), dict(nom='x' * 51), dict(pw_user=None),
                   dict(teleph='1' * 21), dict(teleph=123),
                   dict(date_naiss='2030-01-01'), dict(date_naiss='bad'),
                   dict(date_naiss=['2000-01-01'])]
        with patch('routes.manager_routes.create_manager_user') as create:
            for change in changes:
                with self.subTest(change=change):
                    self.assertEqual(self.client.post('/manager/users', json={**self.user, **change}).status_code, 400)
            for body in ([], 'invalid', {}):
                self.assertEqual(self.client.post('/manager/users', json=body).status_code, 400)
            self.assertEqual(self.client.post('/manager/users', data='{bad', content_type='application/json').status_code, 400)
            create.assert_not_called()

    def test_duplicate_returns_conflict(self):
        with patch('routes.manager_routes.create_manager_user', side_effect=pyodbc.IntegrityError('duplicate')):
            response = self.client.post('/manager/users', json=self.user)
        self.assertEqual(response.status_code, 409)


class ManagerDaoTest(unittest.TestCase):
    def setUp(self):
        self.connection = MagicMock()
        self.cursor = self.connection.cursor.return_value
        self.patch = patch('dao.manager_dao.get_connection', return_value=self.connection)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def test_dashboard_counts_do_not_multiply_stock_by_invoice_items(self):
        self.cursor.description = [(c,) for c in ('id', 'name', 'price', 'stock')]
        self.cursor.fetchall.return_value = [(1, 'A', Decimal('5.5'), 10), (2, 'B', Decimal('20'), 0), (3, 'C', Decimal('2'), 11)]
        with patch('dao.manager_dao.get_all_invoices_for_employee', return_value=[{'status': 'pending'}, {'status': 'completed'}]), patch('dao.manager_dao.get_manager_users', return_value=[{'role': 'employee'}, {'role': 'supplier'}]):
            result = manager_dao.get_manager_dashboard()
        self.assertEqual(result['stats']['stock_value'], 77)
        self.assertEqual(result['stats']['stock_units'], 21)
        self.assertEqual(result['stats']['low_stock'], 2)
        self.assertEqual(result['stats']['invoice_statuses'], {'pending': 1, 'completed': 1})
        self.assertEqual(result['stats']['employees'], 1)
        self.cursor.close.assert_called_once()
        self.connection.close.assert_called_once()

    def test_create_is_parameterized_and_omits_password(self):
        data = dict(id_user="O'Brien", nom='Test', prenom='User', cin='01234567', role='supplier', pw_user='secret')
        user = manager_dao.create_manager_user(data)
        sql, params = self.cursor.execute.call_args.args
        self.assertNotIn("O'Brien", sql)
        self.assertEqual(params[0], "O'Brien")
        self.assertEqual(params[3], 1234567)
        self.assertNotIn('pw_user', user)
        self.connection.commit.assert_called_once()

    def test_insert_failure_rolls_back_and_closes(self):
        self.cursor.execute.side_effect = pyodbc.IntegrityError('duplicate')
        data = dict(id_user='test', nom='Test', prenom='User', cin='12345678', role='employee', pw_user='secret')
        with self.assertRaises(pyodbc.IntegrityError):
            manager_dao.create_manager_user(data)
        self.connection.rollback.assert_called_once()
        self.connection.commit.assert_not_called()
        self.cursor.close.assert_called_once()
        self.connection.close.assert_called_once()


if __name__ == '__main__':
    unittest.main()
