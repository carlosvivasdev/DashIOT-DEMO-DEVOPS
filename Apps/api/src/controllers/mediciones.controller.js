const db = require("../models/mediciones.model");

async function guardarMedicion(payload) {
  x = payload;

  db.guardarMedicion(x)
    .then((result) => {
      const data = result.rows[0].resultado[0];
      if (!data.ok) {
        console.log(data);
      }
    })
    .catch((error) => {
      console.error(`Error al guardar medicion: ${error}`);
    });
}

module.exports = { guardarMedicion };
