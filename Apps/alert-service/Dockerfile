# Usar una imagen base oficial de Node.js
FROM node:lts-alpine3.19

# Establecer el directorio de trabajo
WORKDIR /usr/src/alert-service

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código de la aplicación
COPY . .

# Exponer el puerto de la aplicación
EXPOSE $ALERT_SERVICE_PORT

# Comando para ejecutar la aplicación
CMD ["npm", "start"]
