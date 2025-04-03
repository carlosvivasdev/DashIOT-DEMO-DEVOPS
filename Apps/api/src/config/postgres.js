const { Pool } = require("pg");

const pool = new Pool({
  user: process.env.POSTGRES_USER,
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.POSTGRES_PORT,
});

const testDbConnection = async () => {
  try {
    await pool.query("SELECT NOW()");
    console.log("Conexión a la base de datos exitosa");
  } catch (error) {
    console.error("Error al conectarse a la base de datos:", error);
    process.exit(1); // Salir con error
  }
};

module.exports = { pool, testDbConnection };
