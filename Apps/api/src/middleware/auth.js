const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  if (!req.header('Authorization')) {
    return res.status(401).send({ error: 'Acceso denegado: Se require autorizacion' });
  }

  const token = req.header('Authorization').replace('Bearer ', '');
  if (!token) {
    return res.status(401).send({ error: 'Acceso denegado' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch (error) {
    res.status(400).send({ error: 'Token no válido' });
  }
};

module.exports = auth;
