const SinNotificador = require("./notificadores/sinNotificador");
const Telegram = require("./notificadores/telegram");

class Notificador {
  formateador = () => [];

  constructor(formateador = () => []) {
    this.formateador = formateador
  }

  elegir(notificador = 'telegram') {
    let notif;
    switch (notificador) {
      case 'telegram':
        const token = process.env.TELEGRAM_BOT_TOKEN || "";
        notif = new Telegram({token}, this.formateador);
        break;
      default:
        notif = new SinNotificador()
        break;
    }
    return notif;
  }
};

module.exports = (formateador = () => []) => {
  const notificardor = new Notificador(formateador)
  return notificardor.elegir()
}
