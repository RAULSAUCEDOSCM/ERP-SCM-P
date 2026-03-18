# ERP_SCM en Azure SQL

## Archivo recomendado

Usa este script cuando ya hayas creado la base de datos en Azure:

- `database/002_init_erp_scm_azure.sql`

## Pasos

1. Crea una base de datos llamada `ERP_SCM` en Azure SQL Database.
2. En el firewall del servidor SQL, agrega tu IP cliente.
3. Conectate desde Azure Data Studio, SSMS o VS Code a la base `ERP_SCM`.
4. Ejecuta `database/002_init_erp_scm_azure.sql`.

## Conexion de ejemplo

```text
Server=tcp:TU_SERVIDOR.database.windows.net,1433;
Initial Catalog=ERP_SCM;
Persist Security Info=False;
User ID=TU_USUARIO;
Password=TU_PASSWORD;
MultipleActiveResultSets=False;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
```

## Notas

- `database/001_init_erp_scm.sql` es para SQL Server tradicional porque incluye `CREATE DATABASE` y `USE ERP_SCM`.
- `database/002_init_erp_scm_azure.sql` es la variante pensada para Azure SQL Database.
- El script es idempotente en la creacion de tablas y en los datos semilla principales.
