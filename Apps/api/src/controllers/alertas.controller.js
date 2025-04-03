const db = require("../models/alertas.model");
const { enviarNotificacion } = require("../utils/request");

async function comprobarAlertaIntervalo() {
  db.comprobarAlertaIntervalo()
    .then((result) => {
      const data = result.rows[0].resultado[0];
      if (data.ok) {
        if (data.datos != null) {
          //console.log('enviarNotificacion intervalo', data.datos)
          enviarNotificacion(data.datos);
        }
      } else {
        console.error("Error", data);
      }
    })
    .catch((error) => {
      console.error(`Error al comprobar alerta intervalo: ${error}`);
    });
}

async function comprobarAlertaMedicion(payload) {
  let x = {
    devEUI: payload.devEUI,
    mediciones: payload.data,
    bateria: payload.bateria,
  };

  db.comprobarAlertaMedicion(x)
    .then((result) => {
      const data = result.rows[0].resultado[0];
      if (data.ok) {
        if (data.datos != null) {
          //console.log('enviarNotificacion medicion', data.datos)
          enviarNotificacion(data.datos);
        }
      } else {
        console.error("Error", data);
      }
    })
    .catch((error) => {
      console.error(`Error al comprobar alerta medicion: ${error}`);
    });
}

module.exports = { comprobarAlertaMedicion, comprobarAlertaIntervalo };
