const { getFechaString } = require("./fecha");

function formatearMensajeAlerta(alerta) {
  const data = alerta;

  const motivo = data.estado_alerta
    ? data.tipo_alerta.toUpperCase()
    : capitalizar(data.tipo_alerta) + " normalizado";

  let icono = "";
  let informacion = "";
  switch (data.tipo_alerta) {
    case "alarma":
      icono = data.estado_alerta ? "🟥" : "✅";

      informacion = data.estado_alerta
        ? `tiene ALARMA de ${data.tipo_medicion} a ${data.valor} ${
            data.unidad || ""
          }, superior al limite de ${data.limite} ${data.unidad || ""}`
        : `normalizó la alarma de ${data.tipo_medicion} con ${data.valor} ${
            data.unidad || ""
          }`;
      break;

    case "advertencia":
      icono = data.estado_alerta ? "🟨" : "✅";

      informacion = data.estado_alerta
        ? `tiene ADVERTENCIA de ${data.tipo_medicion} a ${data.valor} ${
            data.unidad || ""
          }, superior al limite de ${data.limite} ${data.unidad || ""}`
        : `normalizó la advertencia de ${data.tipo_medicion} con ${
            data.valor
          } ${data.unidad || ""}`;
      break;

    case "bateria_baja":
      icono = data.estado_alerta ? "🟨" : "✅";

      informacion = data.estado_alerta
        ? `tiene BATERÍA BAJA a ${data.valor}%, por debajo del limite de ${data.limite}%`
        : `dejó de tener batería baja`;
      break;

    case "inactividad":
      icono = data.estado_alerta ? "🟥" : "✅";

      informacion = data.estado_alerta
        ? `ha estado INACTIVO por ${data.valor} minutos, superior al limite de ${data.limite} minutos`
        : `dejó de estar inactivo`;

      break;

    default:
      return `ERROR. Tipo de alerta no establecida: ${data.tipo_alerta}. Contacte con el adminstrador `;
  }

  const mensaje =
    `<b>Motivo:</b> ${motivo} ${icono}` +
    `\n<b>Sensor:</b> ${data.nombre_sensor}` +
    `\n<b>Area:</b> ${data.id_area ? data.nombre_area : "Sin area"}` +
    `\n<b>Fecha:</b> ${getFechaString(data.fecha)}` +
    `\n<b>Informacion:</b> El sensor ${data.nombre_sensor}${
      data.id_area ? " de " + data.nombre_area : ""
    } ${informacion}.`;

  return mensaje;
}

function capitalizar(texto) {
  return texto.charAt(0).toUpperCase() + texto.slice(1);
}

module.exports = { formatearMensajeAlerta };
