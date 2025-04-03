require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const routes = require("./routes/index");

const { testDbConnection } = require("./config/postgres");
const { iniciarIntervalo } = require("./config/intervalo")
require("./config/broker");

const app = express();

const protocol = process.env.API_PROTOCOL || "http";
const host = process.env.API_HOST || "localhost";
const port = process.env.API_PORT || 3030;

app.use(express.static('public'))

app.use(bodyParser.json());
app.use(cors());
app.use("/api", routes);

app.get("/health", (req, res) => {
  res.status(200).send("OK");
});

testDbConnection()
  .then(() => {

    iniciarIntervalo();

    app.listen(port, () => {
      console.log(`Servidor corriendo en ${protocol}://${host}:${port}`);
    });
  })
  .catch((error) => {
    console.error("Error al iniciar el servidor:", error);
  });
 