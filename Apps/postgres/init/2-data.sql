INSERT INTO esq_dash_iot.areas (nombre, orden) VALUES 
  ('Bodega Ganeral', 1),
  ('Bodega Dispositivos y Suministros', 2),
  ('Farmacia Principal', 3);

insert into esq_dash_iot.parametros (nombre, numero) values
  ('bateria_baja', 30),
  ('tiempo_inactividad_m', 60);

insert into esq_dash_iot.notificaciones (id_area, medio, id_chat) values
	(null, 'telegram', '-4249665440'),
	(1, 'telegram', '-4581916670'),
	(2, 'telegram', '-4549792647'),
	(3, 'telegram', '-4545214533');
