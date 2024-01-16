import os

# mysql+mysqlconnector://your-username:your-password@localhost/your-schema'
DATABASE_URI = 'mysql+mysqlconnector://{dbuser}:{dbpass}@{dbhost}/{dbname}'.format(
    dbuser=os.environ.get('AZURE_MYSQL_USER'),
    dbpass=os.environ.get('AZURE_MYSQL_PASSWORD'),
    dbhost=os.environ.get('AZURE_MYSQL_HOST'),
    dbname=os.environ.get('AZURE_MYSQL_NAME')
)