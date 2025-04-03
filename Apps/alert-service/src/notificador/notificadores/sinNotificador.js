const NotificadorInterfaz = require("../notificadorInterfaz");

module.exports = class SinNotificador extends NotificadorInterfaz {
  constructor() {
    super();
  }
  notificar(alertas) {
    console.log("Aplicacion inicada sin Notificador");
  }
};
