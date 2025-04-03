const { DatabaseError } = require("pg");
const { pool } = require("../config/postgres");

async function comprobarAlertaMedicion(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.comprobarAlertaMedicion($1, $2, $3) as resultado;",
      [x.devEUI, x.mediciones, x.bateria]
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

async function comprobarAlertaIntervalo(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.comprobarAlertaIntervalo() as resultado;",
      []
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

module.exports = {
  comprobarAlertaMedicion,
  comprobarAlertaIntervalo,
};
