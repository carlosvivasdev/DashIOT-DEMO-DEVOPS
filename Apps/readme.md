# **dash-iot**
## **Comandos**
Levantar docker compose

```bash
docker compose up -d --build
```

Detener docker compose y eliminar volumenes

```bash
docker compose down -v
```

Guardar la estructura de la base de datos

```bash
docker exec -t postgres-dash-iot pg_dump -n esq_dash_iot --schema-only --no-owner dash-iot -f /tmp/1-schema.sql && docker cp postgres-dash-iot:/tmp/1-schema.sql postgres/init/1-schema.sql
```

Guardar los dashboards de grafana respetando la estructura de carpetas
```bash
bash ./grafana-export.sh
```

## **Servicios**  
ArgoCD => https://128.199.15.192:31001/ 
Grafana => http://128.199.15.192:30070/  
Api-Dash => http://128.199.15.192:30055/  
Alert-Service => http://128.199.15.192:30056/  
EMQX => http://128.199.15.192:30054/ (mqtt:30050; http:30051; ws:30052; mqtts:30053)
