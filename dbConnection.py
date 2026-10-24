import pyodbc

def get_connection():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=192.168.1.166,1433;"
        "DATABASE=master;"
        "UID=sa;"
        "PWD=00000;"
        "TrustServerCertificate=yes;"
    )
    return conn