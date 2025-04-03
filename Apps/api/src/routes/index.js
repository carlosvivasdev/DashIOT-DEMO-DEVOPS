const express = require("express");
const router = express.Router();

const sensores = require("./sensores.route");

router.use("/sensores", sensores);

module.exports = router;
