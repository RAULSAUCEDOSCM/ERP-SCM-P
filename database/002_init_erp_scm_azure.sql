SET NOCOUNT ON;
GO

/*
    Azure SQL Database setup script for ERP_SCM.
    Run this script while connected directly to the ERP_SCM database.

    This version omits:
    - CREATE DATABASE
    - USE ERP_SCM
*/

IF OBJECT_ID(N'dbo.Companies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Companies
    (
        CompanyId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Companies PRIMARY KEY,
        CompanyCode NVARCHAR(30) NOT NULL,
        CompanyName NVARCHAR(150) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Companies_IsActive DEFAULT (1),
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Companies_CreatedAt DEFAULT (SYSDATETIME()),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Companies_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Companies_CompanyCode UNIQUE (CompanyCode)
    );
END
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RoleId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        RoleName NVARCHAR(80) NOT NULL,
        RoleDescription NVARCHAR(250) NULL,
        IsSystem BIT NOT NULL CONSTRAINT DF_Roles_IsSystem DEFAULT (0),
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName)
    );
END
GO

IF OBJECT_ID(N'dbo.Modules', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Modules
    (
        ModuleId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Modules PRIMARY KEY,
        ModuleCode NVARCHAR(40) NOT NULL,
        ModuleName NVARCHAR(100) NOT NULL,
        ModuleDescription NVARCHAR(250) NULL,
        SortOrder INT NOT NULL CONSTRAINT DF_Modules_SortOrder DEFAULT (0),
        IsActive BIT NOT NULL CONSTRAINT DF_Modules_IsActive DEFAULT (1),
        CONSTRAINT UQ_Modules_ModuleCode UNIQUE (ModuleCode)
    );
END
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        CompanyId INT NOT NULL,
        UserName NVARCHAR(80) NOT NULL,
        FullName NVARCHAR(150) NOT NULL,
        Email NVARCHAR(150) NOT NULL,
        PasswordHash VARBINARY(256) NULL,
        PasswordSalt VARBINARY(128) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
        MustChangePassword BIT NOT NULL CONSTRAINT DF_Users_MustChangePassword DEFAULT (1),
        LastLoginAt DATETIME2(0) NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Users_Companies FOREIGN KEY (CompanyId) REFERENCES dbo.Companies (CompanyId),
        CONSTRAINT UQ_Users_UserName UNIQUE (UserName),
        CONSTRAINT UQ_Users_Email UNIQUE (Email)
    );
END
GO

IF OBJECT_ID(N'dbo.UserRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRoles
    (
        UserId INT NOT NULL,
        RoleId INT NOT NULL,
        AssignedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserRoles_AssignedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
        CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId)
    );
END
GO

IF OBJECT_ID(N'dbo.UserModulePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserModulePermissions
    (
        UserId INT NOT NULL,
        ModuleId INT NOT NULL,
        CanView BIT NOT NULL CONSTRAINT DF_UserModulePermissions_CanView DEFAULT (0),
        CanCreate BIT NOT NULL CONSTRAINT DF_UserModulePermissions_CanCreate DEFAULT (0),
        CanEdit BIT NOT NULL CONSTRAINT DF_UserModulePermissions_CanEdit DEFAULT (0),
        CanDelete BIT NOT NULL CONSTRAINT DF_UserModulePermissions_CanDelete DEFAULT (0),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserModulePermissions_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_UserModulePermissions PRIMARY KEY (UserId, ModuleId),
        CONSTRAINT FK_UserModulePermissions_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_UserModulePermissions_Modules FOREIGN KEY (ModuleId) REFERENCES dbo.Modules (ModuleId)
    );
END
GO

IF OBJECT_ID(N'dbo.RoleModules', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RoleModules
    (
        RoleId INT NOT NULL,
        ModuleId INT NOT NULL,
        CanView BIT NOT NULL CONSTRAINT DF_RoleModules_CanView DEFAULT (0),
        CanCreate BIT NOT NULL CONSTRAINT DF_RoleModules_CanCreate DEFAULT (0),
        CanEdit BIT NOT NULL CONSTRAINT DF_RoleModules_CanEdit DEFAULT (0),
        CanDelete BIT NOT NULL CONSTRAINT DF_RoleModules_CanDelete DEFAULT (0),
        CONSTRAINT PK_RoleModules PRIMARY KEY (RoleId, ModuleId),
        CONSTRAINT FK_RoleModules_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId),
        CONSTRAINT FK_RoleModules_Modules FOREIGN KEY (ModuleId) REFERENCES dbo.Modules (ModuleId)
    );
END
GO

IF OBJECT_ID(N'dbo.LoginAudit', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoginAudit
    (
        LoginAuditId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LoginAudit PRIMARY KEY,
        UserId INT NULL,
        UserNameAttempted NVARCHAR(80) NOT NULL,
        WasSuccessful BIT NOT NULL,
        FailureReason NVARCHAR(200) NULL,
        IpAddress NVARCHAR(45) NULL,
        DeviceName NVARCHAR(120) NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_LoginAudit_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_LoginAudit_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Companies WHERE CompanyCode = N'CENTRAL')
BEGIN
    INSERT INTO dbo.Companies (CompanyCode, CompanyName)
    VALUES (N'CENTRAL', N'ERP SCM Central');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Administrador')
BEGIN
    INSERT INTO dbo.Roles (RoleName, RoleDescription, IsSystem)
    VALUES (N'Administrador', N'Acceso total al sistema', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Super Administrador')
BEGIN
    INSERT INTO dbo.Roles (RoleName, RoleDescription, IsSystem)
    VALUES (N'Super Administrador', N'Control total del ERP reservado para el creador del sistema', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Compras')
BEGIN
    INSERT INTO dbo.Roles (RoleName, RoleDescription, IsSystem)
    VALUES (N'Compras', N'Operacion del modulo de compras', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Almacen')
BEGIN
    INSERT INTO dbo.Roles (RoleName, RoleDescription, IsSystem)
    VALUES (N'Almacen', N'Operacion del modulo de inventario y almacen', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Ventas')
BEGIN
    INSERT INTO dbo.Roles (RoleName, RoleDescription, IsSystem)
    VALUES (N'Ventas', N'Operacion del modulo de ventas', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Modules WHERE ModuleCode = N'DASHBOARD')
BEGIN
    INSERT INTO dbo.Modules (ModuleCode, ModuleName, ModuleDescription, SortOrder)
    VALUES (N'DASHBOARD', N'Dashboard', N'Vista principal con indicadores', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Modules WHERE ModuleCode = N'INVENTORY')
BEGIN
    INSERT INTO dbo.Modules (ModuleCode, ModuleName, ModuleDescription, SortOrder)
    VALUES (N'INVENTORY', N'Inventario', N'Control de existencias y movimientos', 2);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Modules WHERE ModuleCode = N'PURCHASES')
BEGIN
    INSERT INTO dbo.Modules (ModuleCode, ModuleName, ModuleDescription, SortOrder)
    VALUES (N'PURCHASES', N'Compras', N'Gestion de ordenes y proveedores', 3);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Modules WHERE ModuleCode = N'SALES')
BEGIN
    INSERT INTO dbo.Modules (ModuleCode, ModuleName, ModuleDescription, SortOrder)
    VALUES (N'SALES', N'Ventas', N'Pedidos, facturacion y seguimiento comercial', 4);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Modules WHERE ModuleCode = N'REPORTS')
BEGIN
    INSERT INTO dbo.Modules (ModuleCode, ModuleName, ModuleDescription, SortOrder)
    VALUES (N'REPORTS', N'Reportes', N'Consultas e indicadores del negocio', 5);
END
GO

DECLARE @CompanyId INT = (SELECT TOP (1) CompanyId FROM dbo.Companies WHERE CompanyCode = N'CENTRAL');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserName = N'admin')
BEGIN
    INSERT INTO dbo.Users
    (
        CompanyId,
        UserName,
        FullName,
        Email,
        PasswordHash,
        PasswordSalt,
        MustChangePassword
    )
    VALUES
    (
        @CompanyId,
        N'admin',
        N'Administrador General',
        N'admin@erpscm.local',
        NULL,
        NULL,
        1
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserName = N'superadmin')
BEGIN
    INSERT INTO dbo.Users
    (
        CompanyId,
        UserName,
        FullName,
        Email,
        PasswordHash,
        PasswordSalt,
        MustChangePassword
    )
    VALUES
    (
        @CompanyId,
        N'superadmin',
        N'Creador del Sistema',
        N'superadmin@erpscm.local',
        NULL,
        NULL,
        1
    );
END
GO

DECLARE @SeedAdminUserId INT = (SELECT TOP (1) UserId FROM dbo.Users WHERE UserName = N'admin');
DECLARE @SeedAdminRoleId INT = (SELECT TOP (1) RoleId FROM dbo.Roles WHERE RoleName = N'Administrador');
DECLARE @SeedSuperAdminUserId INT = (SELECT TOP (1) UserId FROM dbo.Users WHERE UserName = N'superadmin');
DECLARE @SeedSuperAdminRoleId INT = (SELECT TOP (1) RoleId FROM dbo.Roles WHERE RoleName = N'Super Administrador');

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.UserRoles
    WHERE UserId = @SeedAdminUserId
      AND RoleId = @SeedAdminRoleId
)
BEGIN
    INSERT INTO dbo.UserRoles (UserId, RoleId)
    VALUES (@SeedAdminUserId, @SeedAdminRoleId);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.UserRoles
    WHERE UserId = @SeedSuperAdminUserId
      AND RoleId = @SeedSuperAdminRoleId
)
BEGIN
    INSERT INTO dbo.UserRoles (UserId, RoleId)
    VALUES (@SeedSuperAdminUserId, @SeedSuperAdminRoleId);
END
GO

INSERT INTO dbo.RoleModules (RoleId, ModuleId, CanView, CanCreate, CanEdit, CanDelete)
SELECT
    r.RoleId,
    m.ModuleId,
    1,
    CASE WHEN r.RoleName = N'Administrador' THEN 1 ELSE 0 END,
    CASE WHEN r.RoleName = N'Administrador' THEN 1 ELSE 0 END,
    CASE WHEN r.RoleName = N'Administrador' THEN 1 ELSE 0 END
FROM dbo.Roles r
CROSS JOIN dbo.Modules m
WHERE r.RoleName = N'Administrador'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.RoleModules rm
      WHERE rm.RoleId = r.RoleId
        AND rm.ModuleId = m.ModuleId
  );
GO

INSERT INTO dbo.UserModulePermissions (UserId, ModuleId, CanView, CanCreate, CanEdit, CanDelete)
SELECT
    u.UserId,
    m.ModuleId,
    1,
    1,
    1,
    1
FROM dbo.Users u
CROSS JOIN dbo.Modules m
WHERE u.UserName = N'superadmin'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.UserModulePermissions ump
      WHERE ump.UserId = u.UserId
        AND ump.ModuleId = m.ModuleId
  );
GO
