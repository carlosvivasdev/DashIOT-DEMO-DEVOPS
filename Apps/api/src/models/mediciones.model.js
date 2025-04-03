const { DatabaseError } = require("pg");
const { pool } = require("../config/postgres");

async function guardarMedicion(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.guardarmedicion($1, $2, $3, $4, $5, $6, $7) as resultado;",
      [
        x.device,
        x.devEUI,
        x.timestamp,
        x.data,
        x.bateria,
        x.mqtt_topic,
        x.metadata.gateway_id,
      ]
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

module.exports = {
  guardarMedicion,
};
