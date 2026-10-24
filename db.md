create table users (
id_user varchar(50) primary key,
nom varchar(50) not null,
prenom varchar(50) not null,
cin int not null unique ,
date_naiss date ,
teleph varchar(20),
role varchar(20) not null ,
)

select \* from users

update users set role='manager'
where id_user='toussema'

alter table users
add pw_user nvarchar(50) not null

insert into users (id_user, nom, prenom ,cin, date_naiss, teleph, role,pw_user)
values ('fachraf','Achraf','Fourati',11111110,'2003-03-10',21404820,'supplier','123456')

select \* from products

CREATE TABLE products (
id INT IDENTITY PRIMARY KEY,
name NVARCHAR(200) NOT NULL,
description NVARCHAR(500),
category NVARCHAR(100),
price DECIMAL(10,2) NOT NULL,
stock INT NOT NULL DEFAULT 0,
image_url NVARCHAR(500),
is_active BIT DEFAULT 1,
created_at DATETIME DEFAULT GETDATE()
);

INSERT INTO products (name, description, category, price, stock, image_url, is_active)
VALUES
('Wireless Mouse Pro', 'Ergonomic 2.4GHz wireless mouse with silent clicks.', 'Peripherals', 29.90, 42, '/static/products/mouse.jpg', 1),
('Mechanical Keyboard K87', 'Hot-swappable TKL keyboard with brown switches.', 'Peripherals', 89.00, 8, '/static/products/keyboard.jpg', 1),
('27" 4K Monitor', 'IPS panel, 60Hz, USB-C power delivery.', 'Displays', 329.00, 12, '/static/products/monitor.jpg', 1),
('USB-C Hub 8-in-1', 'HDMI, SD, ethernet and 100W passthrough.', 'Accessories', 49.50, 3, '/static/products/hub.jpg', 1),
('Noise Cancelling Headset', 'Over-ear headset with dual mic ANC.', 'Audio', 149.00, 25, '/static/products/headset.jpg', 1),
('1080p Webcam', 'Auto-focus webcam with privacy shutter.', 'Video', 59.00, 0, '/static/products/webcam.jpg', 1);

update products set image_url ='/static/products/hub.png' where id =4

CREATE TABLE purchase_invoices (
id INT IDENTITY PRIMARY KEY,
supplier_id INT NOT NULL,
created_by INT NOT NULL,
status NVARCHAR(20) DEFAULT 'pending',
created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE purchase_invoice_items (
id INT IDENTITY PRIMARY KEY,
invoice_id INT NOT NULL,
product_id INT NOT NULL,
qty_requested INT NOT NULL,
FOREIGN KEY (invoice_id) REFERENCES purchase_invoices(id),
FOREIGN KEY (product_id) REFERENCES products(id)
);

fitz NOT installed
reportlab NOT installed
fpdf NOT installed
pdfkit NOT installed
weasyprint NOT installed
PIL is installed!
in requ
