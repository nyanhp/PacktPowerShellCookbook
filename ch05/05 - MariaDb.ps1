# Connecting to additional engines via ADO.NET requires
# using providers
Invoke-WebRequest -uri https://github.com/npgsql/npgsql/releases/download/v4.0.4/Npgsql-4.0.4.msi -OutFile .\npgsql.msi
msiexec.exe /i .\npgsql.msi