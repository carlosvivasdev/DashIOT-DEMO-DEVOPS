require("dotenv").config();

const express = require("express");
const bodyParser = require("body-parser");

const notificador = require("./notificador/notificador");
const { formatearMensajeAlerta } = require("./utils/formatearMensajesAlerta");

const notif = notificador(formatearMensajeAlerta);

const app = express();

app.use(bodyParser.json());

app.post("/notificar", async (req, res) => {
  console.log('Notificacion recivida', req.body)

  const alertas = req.body;

  if (!Array.isArray(alertas)) {
    res
      .status(400)
      .send({ ok: false, error: "Se debe enviar un array de alertas" });
    return;
  }

  await notif.notificar(alertas);

  res
    .status(200)
    .send({ ok: true, observacion: "Notificacion enviada con exito" });
});

const protocol = process.env.ALERT_SERVICE_PROTOCOL || "http";
const host = process.env.ALERT_SERVICE_HOST || "localhost";
const port = process.env.ALERT_SERVICE_PORT || 4000;

app.listen(port, () => {
  console.log(
    `Servidor de notificaciones corriendo en ${protocol}://${host}:${port}`,
  );
});

 