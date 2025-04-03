#Crear imagen personalizada de Postgres
FROM postgres:14

#Directorio de trabajo en Postgres
WORKDIR /docker-entrypoint-initdb.d

# Copiar archivos de inicialización al contenedor
COPY init/. ./

