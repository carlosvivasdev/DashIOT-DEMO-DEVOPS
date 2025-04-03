module.exports = class NotificadorInterfaz {
  notificar(alertas = []) {
    return Promise.reject(
      new Error("No cumplió con la implementacion notificar"),
    );
  }

  getGrupos(alerta = {}, medio = "") {
    return alerta.notificaciones.find((n) => n.medio === medio).ids;
  }
};
