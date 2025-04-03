const express = require("express");
const {
  actualizarLimites,
  actualizarSensor,
  guardarCalibracion,
} = require("../controllers/sensores.controller");
const router = express.Router();

router.post("/actualizarsensor", actualizarSensor);
router.post("/actualizarlimites", actualizarLimites);
router.post("/guardarcalibracion", guardarCalibracion);

module.exports = router;
