const getFechaString = (date) =>
  new Date(date).toLocaleString("es-ec", { timeZone: "America/Guayaquil" });

module.exports = { getFechaString };
