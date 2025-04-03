Configuración de Ingress-Nginx para manejar tráfico TCP (MQTT)

Por defecto, Ingress-Nginx está diseñado para manejar tráfico HTTP/WebSocket. Sin embargo, para protocolos como MQTT, que operan sobre TCP, es necesario realizar una configuración adicional utilizando un ConfigMap.

1. Instalación de Ingress-Nginx con soporte para TCP

Para habilitar el manejo de tráfico TCP en Ingress-Nginx, es necesario instalar o actualizar el controlador con la opción controller.extraArgs.tcp-services-configmap. Este argumento permite especificar el ConfigMap que contendrá las reglas de redirección de puertos TCP.

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.extraArgs.tcp-services-configmap=ingress-nginx/tcp-services

2. Creación del ConfigMap para servicios TCP

Una vez instalado Ingress-Nginx, debes crear un ConfigMap que defina los puertos TCP y los servicios a los que se redirigirá el tráfico. Este ConfigMap debe estar en el mismo namespace donde se instaló Ingress-Nginx.

apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: ingress-nginx
data:
  "1883": "default/emqx-svc:1883"
  "8883": "default/emqx-svc:8883"

3. Reinicio del controlador de Ingress-Nginx

kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

4.

kubectl edit svc ingress-nginx-controller -n ingress-nginx

5. 

  - name: mqtt
    nodePort: 32315
    port: 1883
    protocol: TCP
    targetPort: 1883
  - name: mqtts
    nodePort: 31284
    port: 8883
    protocol: TCP
    targetPort: 8883

4. Prueba de la configuración

host: emqx.carlosvivas.dev
Puerto: 1883 (para MQTT no seguro) o 8883 (para MQTT seguro)

Notas adicionales
- Asegúrate de que los puertos TCP (1883 y 8883 en este caso) estén abiertos en el firewall o balanceador de carga que esté delante de tu clúster de Kubernetes.
- Si necesitas agregar más servicios TCP en el futuro, simplemente actualiza el ConfigMap tcp-services y reinicia el controlador de Ingress-Nginx.
