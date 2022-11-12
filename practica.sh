#!/bin/bash

# Esto no va para el TP es para lo de practica
docker-compose down

docker-compose up -d

echo "waiting for sql server..."

sleep 10

docker-compose exec gdd-practica /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'Gdd2022!' -Q "SELECT @@VERSION"

echo "starting database bootstrap"

docker exec -it gdd-practica /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'Gdd2022!' -i /var/opt/scripts/init.sql -o /var/opt/output/init.txt

DATA=$(sudo docker exec -it gdd-practica /opt/mssql-tools/bin/sqlcmd -S localhost \
    -U SA -P 'Gdd2022!' \
    -Q 'RESTORE FILELISTONLY FROM DISK = "/var/opt/mssql/backup/GD2015C1.bak"' |
    tr -s ' ' | cut -d " " -f 1 | sed '3q;d')

LOG=$(sudo docker exec -it gdd-practica /opt/mssql-tools/bin/sqlcmd -S localhost \
    -U SA -P 'Gdd2022!' \
    -Q 'RESTORE FILELISTONLY FROM DISK = "/var/opt/mssql/backup/GD2015C1.bak"' |
    tr -s ' ' | cut -d " " -f 1 | sed '4q;d')

echo "Data file name: $DATA"
echo "Log file name: $LOG"

docker exec -it gdd-practica /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'Gdd2022!' -i /var/opt/scripts/restore.sql -o /var/opt/output/restore.txt
