const axios = require("axios");

async function enviarNotificacion(alertas = []) {
  const protocol = process.env.ALERT_SERVICE_PROTOCOL || "http";
  const host = process.env.ALERT_SERVICE_HOST || "alert_service";
  const port = process.env.ALERT_SERVICE_PORT || "4000";

  console.log(`Enviando notificacion a ${protocol}://${host}:${port}/notificar`, alertas)
  try {
    const res = await axios.post(
      `${protocol}://${host}:${port}/notificar`,
      alertas,
    );

    if (!res.data.ok) {
      console.error(`Error al enviar la notificacion: ${res.data.error}`);
    }
  } catch (error) {
    console.error(`Error al enviar notificacion: ${error}`);
  }
}

module.exports = { enviarNotificacion };
