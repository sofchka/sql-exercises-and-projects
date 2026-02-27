-- Creating DBs
USE master;
GO
CREATE DATABASE DB1;
CREATE DATABASE DB2;
CREATE DATABASE DB3;
CREATE DATABASE DB4;
CREATE DATABASE DB5;
GO

-- 1) Creating the login (server-level)
USE master;
GO
CREATE LOGIN Philipe WITH PASSWORD = 'Soft987!';
GO

-- Choosing what DB Philipe starts in
ALTER LOGIN Philipe WITH DEFAULT_DATABASE = DB1;
GO

-- 2) Giving access to the 4 databases you want
USE DB1;
GO
CREATE USER Philipe FOR LOGIN Philipe;
GO
ALTER ROLE db_datareader ADD MEMBER Philipe;
ALTER ROLE db_datawriter ADD MEMBER Philipe;
GO

USE DB2;
GO
CREATE USER Philipe FOR LOGIN Philipe;
GO
ALTER ROLE db_datareader ADD MEMBER Philipe;
ALTER ROLE db_datawriter ADD MEMBER Philipe;
GO

USE DB3;
GO
CREATE USER Philipe FOR LOGIN Philipe;
GO
ALTER ROLE db_datareader ADD MEMBER Philipe;
ALTER ROLE db_datawriter ADD MEMBER Philipe;
GO

USE DB4;
GO
CREATE USER Philipe FOR LOGIN Philipe;
GO
ALTER ROLE db_datareader ADD MEMBER Philipe;
ALTER ROLE db_datawriter ADD MEMBER Philipe;
GO

-- If we never create a USER for Philipe in DB5, he won't have access.

-- 3) Blocking access to DB5
USE DB5;
GO
CREATE USER Philipe FOR LOGIN Philipe;
GO
DENY CONNECT TO Philipe;
GO