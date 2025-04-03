const mqtt = require("mqtt");
const { guardarMedicion } = require("../controllers/mediciones.controller");
const { comprobarAlertaMedicion } = require("../controllers/alertas.controller");

const protocol = process.env.BROKER_PROTOCOL;
const host = process.env.BROKER_HOST;
const port = process.env.BROKER_PORT;
const clientId = `mqtt_${Math.random().toString(16).slice(3)}`;

const connectUrl = `${protocol}://${host}:${port}`;

const mqttClient = mqtt.connect(connectUrl, {
  clientId,
  clean: true,
  connectTimeout: 4000,
  username: process.env.BROKER_USER,
  password: process.env.BROKER_PASS,
  reconnectPeriod: 5000,
});

const topic = process.env.API_MQTT_TOPIC || "";

mqttClient.on("connect", () => {
  console.log("Conexión al broker exitosa");
  mqttClient.subscribe([topic], () => {
    console.log(`Suscrito al topic '${topic}'`);
  });
});

// TODO: una manera de identificar que mensajes son mediciones
mqttClient.on('message', async (topic, payload) => {
  const data = { ...JSON.parse(payload.toString()), topic }

  await guardarMedicion(data);
  await comprobarAlertaMedicion(data);
});

mqttClient.on("error", (error) => {
  console.log('Error al conectarse al broker')
  console.error(error)
})

module.exports = { mqttClient };
