const { DatabaseError } = require("pg");
const { pool } = require("../config/postgres");

async function actualizarSensor(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.actualizarsensor($1, $2, $3) as resultado;",
      [x.id, x.id_area, x.fecha_instalacion]
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

async function actualizarLimites(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.actualizarlimites($1, $2, $3, $4, $5, $6) as resultado;",
      [x.id_sensor, x.tipo_medicion, x.alarma, x.advertencia, x.max, x.min]
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

async function guardarCalibracion(x = {}) {
  try {
    const result = await pool.query(
      "select esq_dash_iot.guardarcalibracion($1, $2, $3) as resultado;",
      [x.id_sensor, x.fecha, x.entidad]
    );
    return result;
  } catch (error) {
    throw new DatabaseError(`Error de Base de Datos. ${error}`);
  }
}

module.exports = {
  actualizarSensor,
  actualizarLimites,
  guardarCalibracion,
};
