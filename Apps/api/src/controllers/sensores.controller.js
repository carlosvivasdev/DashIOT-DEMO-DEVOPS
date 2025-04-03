const db = require("../models/sensores.model");

async function actualizarSensor(req, res) {
  x = req.body;

  db.actualizarSensor(x)
    .then((result) => {
      const data = result.rows[0].resultado[0];
      console.log(data);

      if (data.ok) {
        res.status(200).json({ ok: data.ok, obserbacion: data.obserbacion, datos: data.datos});
      } else {
        res.status(500).json({ ok: false, mensaje: data.mensaje });
      }
    })
    .catch((error) => {
      console.error(error);
      res.status(500).json({ error: error.message });
    });
}

async function actualizarLimites(req, res) {
  x = req.body;
  
  db.actualizarLimites(x)
    .then((result) => {
      const data = result.rows[0].resultado[0];
      console.log(data);

      if (data.ok) {
        res.status(200).json({ ok: data.ok, obserbacion: data.obserbacion, datos: data.datos});
      } else {
        res.status(500).json({ ok: false, mensaje: data.mensaje });
      }
    })
    .catch((error) => {
      console.error(error);
      res.status(500).json({ error: error.message });
    });
}

async function guardarCalibracion(req, res) {
  x = req.body;

  db.guardarCalibracion(x)
    .then((result) => {
      const data = result.rows[0].resultado[0];
      console.log(data);

      if (data.ok) {
        res.status(200).json({ ok: data.ok, obserbacion: data.obserbacion, datos: data.datos});
      } else {
        res.status(500).json({ ok: false, mensaje: data.mensaje });
      }
    })
    .catch((error) => {
      console.error(error);
      res.status(500).json({ error: error.message });
    });
}

module.exports = { actualizarSensor, actualizarLimites, guardarCalibracion };
