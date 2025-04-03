# Usar una imagen base oficial de Node.js
FROM node:lts-alpine3.19

# Establecer el directorio de trabajo
WORKDIR /usr/src/api-dash-iot

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto del código de la aplicación
COPY . .

# Exponer el puerto de la aplicación
EXPOSE $API_PORT

# Comando para ejecutar la aplicación
CMD ["npm", "start"]
