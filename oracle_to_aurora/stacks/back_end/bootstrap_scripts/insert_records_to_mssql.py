
# https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15#previous-versions
# # RedHat Enterprise Server 8 and Oracle Linux 8
# curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo

import pyodbc
exit
sudo yum - y remove unixODBC-utf16 unixODBC-utf16-devel  # to avoid conflicts
sudo ACCEPT_EULA = Y yum - y install msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA = Y yum - y install mssql-tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
yum - y install unixODBC-devel
yum - y install unixODBC unixODBC-devel
yum - y install gcc-c++
yum - y install python3-devel
pip3 install pyodbc


# Microsoft Sample Database
# https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2017.bak

conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                      'Server=RON\SQLEXPRESS;'
                      'Database=TestDB;'
                      'Trusted_Connection=yes;')

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=test;'
    'DATABASE=test;'
    'UID=admin;'
    'PWD=Sup3rPassW0rd')

cursor = conn.cursor()

cursor.execute('''
               CREATE TABLE People
               (
               Name nvarchar(50),
               Age int,
               City nvarchar(50)
               )
               ''')

Sup3rPassW0rd
fC?Q2DFCcOr*gBEhhH*llWA!!GVyPrO.

RDS_ENDPOINT = 'tcp:listener.database-1.ca64q8ficuhu.us-east-1.rds.amazonaws.com,1433'
DB_NAME = 'customers'
DB_USER_NAME = 'admin'
DB_PASWORD = 'Sup3rPassW0rd'
gen_conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};PORT=1433;SERVER=' +
                          RDS_ENDPOINT+';UID='+DB_USER_NAME+';PWD='+DB_PASWORD+';autocommit=True')
gen_conn.autocommit = True

# Create customers Database
gen_cursor = gen_conn.cursor()
SQL_command = """
                IF EXISTS(SELECT * FROM sys.databases WHERE [name] = 'customers')
                    DROP DATABASE customers
              """
gen_cursor.execute(SQL_command)
gen_cursor.execute("CREATE DATABASE customers")


# Create Table in Customer Database
customers_db_conn_str = 'DRIVER={ODBC Driver 17 for SQL Server};PORT=1433;SERVER=' + \
    RDS_ENDPOINT+';Database='+DB_NAME+';UID=' + \
    DB_USER_NAME+';PWD='+DB_PASWORD+';autocommit=True'
cust_conn = pyodbc.connect(customers_db_conn_str)
cust_conn.autocommit = True
cust_cursor = cust_conn.cursor()

cust_cursor.execute('''
 CREATE TABLE CustomerProfile (
        CustomerId INTEGER PRIMARY KEY,
        FirstName TEXT NOT NULL,
        LastName  TEXT NOT NULL,
        Age INTEGER NULL
);
''')
cust_cursor.execute('''
                INSERT INTO CustomerProfile (CustomerId, FirstName, LastName, Age)
                VALUES
                (1,'Kon','p', 55),
                (2, 'Akane','S', 66),
                (3, 'Miztiik','S', 69)
                ''')

# List all Databases
cursor.execute("SELECT name FROM master.dbo.sysdatabases")
for x in cursor:
    print(f"Database = {x}")
# List all Databases


cursor.execute('SELECT top 1 * FROM [DBNAME].[SchemaNAME].[YourTable]')
for row in cursor:
    print(row)

cust_conn.commit()
