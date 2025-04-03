const NotificadorInterfaz = require("../notificadorInterfaz");
const axios = require("axios");

module.exports = class Telegram extends NotificadorInterfaz {
  formatMensaje;
  token;

  constructor(config, formatMensaje = (alerta) => "") {
    super();
    this.token = config.token;
    this.formatMensaje = formatMensaje;
  }

  async notificar(alertas = []) {
    try {
      for await (const alerta of alertas) {
        const grupos = this.getGrupos(alerta, "telegram");
        if (grupos == null || grupos.length === 0) return;

        const mensaje = this.formatMensaje(alerta);

        //console.log(`Enviando Mensaje a los grupos ${grupos} Telegram:`, mensaje);
        for await (const grupo of grupos) {
          await axios.post(
            `https://api.telegram.org/bot${this.token}/sendMessage`,
            {
              chat_id: grupo,
              text: mensaje,
              parse_mode: "HTML",
            }
          );
        }
      }
    } catch (e) {
      console.error(`Error al enviar mensaje de Telegram. ${e}`);
    }
  }
};
