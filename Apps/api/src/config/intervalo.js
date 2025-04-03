const {
  comprobarAlertaIntervalo,
} = require("../controllers/alertas.controller");

function iniciarIntervalo() {
  const intervalMinutos = process.env.API_INTERVALO_MIN || 5;

  console.log(`Iniciando intervalo de ${intervalMinutos} minuto/s`);

  setInterval(() => {
    comprobarAlertaIntervalo();
  }, intervalMinutos * 60000); // Convierte minutos en milisegundos
}

module.exports = { iniciarIntervalo };
