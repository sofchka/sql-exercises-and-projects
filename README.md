# SQL Introduction


# 1. Mac users need Docker SQL container

Running a SQL database in a Docker container provides isolated, disposable instances for development and testing environments. Official images are available for various SQL databases like **Microsoft SQL Server (MS SQL)**, **MySQL**, and **PostgreSQL** on [Docker Hub](https://hub.docker.com/_/mysql).

Below is an example with Microsoft SQL Server.

```bash
docker run -d --name SQLSERV \
  -e ACCEPT_EULA=Y \
  -e SA_PASSWORD="Password!1" \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2019-latest
```

**Explanation:**

- **`docker run`**
    
    Creates a new container from an image and starts it.
    
- **`d`**
    
    “Detached” mode → runs in the background (you still can use the terminal).
    
- **`-name SQLSERV`**
    
    Gives the container a name so you can later do `docker start/stop/logs SQLSERV`.
    
- **`e ACCEPT_EULA=Y`**
    
    Sets an environment variable inside the container: you accept Microsoft’s license.
    
- **`e SA_PASSWORD=Password!1`**
    
    Sets the SQL Server **admin password** for user **`sa`**.
    
- **`p 1433:1433`**
    
    Port mapping:
    
- left `1433` = your Mac’s port
- right `1433` = container’s SQL Server port
    
    So you connect to SQL Server via **localhost:1433**.
    
- **`mcr.microsoft.com/mssql/server:2019-latest`**
    
    The **image** to use: Microsoft SQL Server 2019 (latest patch).
    
    If it’s not downloaded, Docker will pull it first.
    

**Useful** **commands** 

```bash
docker ps
docker start SQLSERV
docker stop SQLSERV
docker restart SQLSERV
docker logs SQLSERV
```

2. Connect from VS Code

Press Cmd + Shift + P

Choose: > MS SQL: New Connection

Enter:
``` 
Server name - 127.0.0.1,1433
Trust server certificate - ON
User name - sa ( → admin permissions)
Password - **YourPassword**
Save Password - ON
Database name - master
Encrypt - Mandatory
```

