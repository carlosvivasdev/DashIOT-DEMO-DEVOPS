--
-- PostgreSQL database dump
--

-- Dumped from database version 14.14 (Debian 14.14-1.pgdg120+1)
-- Dumped by pg_dump version 14.14 (Debian 14.14-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: esq_dash_iot; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA esq_dash_iot;


--
-- Name: actualizararea(text, text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.actualizararea(_id_area text, _nombre text, _orden text, _usuario_email text, _accion text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    idnuevo int;
    elemento json;
    resultado json;
BEGIN
	case _accion
		when 'crear' then
			insert into esq_dash_iot.areas (nombre, orden) values (_nombre, _orden::int) returning id into idnuevo;
			call esq_dash_iot.logger(format('Area creada. id: %s, nombre: %s, orden: %s', idnuevo, _nombre, _orden), 'esq_dash_iot.areas', _usuario_email);

		when 'actualizar' then
			update esq_dash_iot.areas set nombre = _nombre, orden = _orden::int where id = _id_area::int;
			call esq_dash_iot.logger(format('Area actualizada. id: %s, nombre: %s, orden: %s', _id_area, _nombre, _orden), 'esq_dash_iot.areas', _usuario_email);

		else
			resultado := json_build_object('ok', false, 'mensaje', 'Error de variable.', 'variable', _accion);
			RETURN json_agg(resultado);
	end case;

	elemento := (select json_agg(to_json(m.*)) FROM esq_dash_iot.areas m WHERE m.id = idnuevo limit 1);

	resultado := json_build_object('ok', true, 'observacion', 'Area actualizado con éxito.', 'datos', elemento);

	RETURN json_agg(resultado);

exception
	when others then
		resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: actualizarlimites(text, text, text, text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.actualizarlimites(_id_sensor text, _tipo_medicion text, _alarma text, _advertencia text, _max text, _min text, _usuario_email text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    idnuevo int;
    elemento json;
    resultado json;
BEGIN
	UPDATE esq_dash_iot.limites set 		advertencia = _advertencia::float, 
		alarma = _alarma::float, 
		min = _min::float, 
		max = _max::float
	where id_sensor = _id_sensor::int and tipo_medicion = _tipo_medicion RETURNING id into idnuevo;
	IF NOT FOUND THEN		INSERT INTO esq_dash_iot.limites (id_sensor, tipo_medicion, advertencia, alarma, min, max) VALUES 			(_id_sensor::int, _tipo_medicion, _advertencia::float, _alarma::float, _min::float, _max::float) RETURNING id into idnuevo;
		call esq_dash_iot.logger(format('Nuevo limite creado. idnuevo: %s, id_sensor: %s, tipo_medicion: %s, alarma: %s, advertencia: %s', idnuevo, _id_sensor, _tipo_medicion, _alarma, _advertencia), 'esq_dash_iot.limites', _usuario_email);
	else 		call esq_dash_iot.logger(format('Limite actualizado. idnuevo: %s, id_sensor: %s, tipo_medicion: %s, alarma: %s, advertencia: %s', idnuevo, _id_sensor, _tipo_medicion, _alarma, _advertencia), 'esq_dash_iot.limites', _usuario_email);	END IF;
    elemento := (select json_agg(to_json(m.*)) FROM esq_dash_iot.limites m WHERE m.id = idnuevo limit 1);

    resultado := json_build_object('ok', true, 'observacion', 'Limite actualizado con éxito.', 'datos', elemento);
    RETURN json_agg(resultado);
exception
    when others then
        resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: actualizarsensor(text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.actualizarsensor(_id text, _id_area text, _fecha_instalacion text, _usuario_email text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    idnuevo int;
    elemento json;
    resultado json;
BEGIN
	UPDATE esq_dash_iot.sensores set 
		id_area = _id_area::int, 
		fecha_instalacion = _fecha_instalacion::timestamptz
	where id = _id::int RETURNING id into idnuevo;
	
	call esq_dash_iot.logger(format('Sensor actualizado. id_area: %s, fecha_instalacion: %s', _id_area, _fecha_instalacion), 'esq_dash_iot.sensores', _usuario_email);
	
	elemento := (select json_agg(to_json(m.*)) FROM esq_dash_iot.sensores m WHERE m.id = idnuevo limit 1);
	resultado := json_build_object('ok', true, 'observacion', 'Sensor actualizado con éxito.', 'datos', elemento);
	
	RETURN json_agg(resultado);
exception
	when others then
		resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: comprobaralertaintervalo(); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.comprobaralertaintervalo() RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
	aux_int int := null;
	aux_bool bool := null;
	rec record;
	idsensor int;
	idnuevo int;
	idsnuevos INT[] := array[]::INT[];
	elemento json;
	resultado json;
begin
	--inactividad
	for rec in
		select m.*
		from (
		  select distinct on (id_sensor)
		    id_sensor,
		    ( EXTRACT(EPOCH FROM age(now(), tiempo)) / 60 )::int as minutos,
		    ( select numero from esq_dash_iot.parametros where nombre = 'tiempo_inactividad_m' ) as limite
		  from esq_dash_iot.mediciones
		  order by id_sensor, tiempo desc
		) as m
		  inner join esq_dash_iot.sensores s on s.id = m.id_sensor
		where s.eliminado = false and minutos >= limite
	loop
		-- guardar en base con estado_alerta = true returning id_registro into idnuevo
		insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
			('inactividad', true, now(), rec.id_sensor, null, rec.limite::float, rec.minutos::float)
			returning id_registro into idnuevo;
		update esq_dash_iot.sensores set inactivo = true where id = rec.id_sensor;
		idsnuevos := array_append(idsnuevos, idnuevo);
	end loop;

	if array_length(idsnuevos, 1) > 0 then
		elemento := (select json_agg(to_json(m.*)) 
			FROM ( 
				select *, 
				( select esq_dash_iot.getnotificacionesarea(id_area::text) ) as notificaciones
				from esq_dash_iot.vmostraralertas WHERE id_registro = any(idsnuevos)
				) as m
			);

		resultado := json_build_object('ok', true, 'observacion', 'Alertas guardadas con éxito.', 'datos', elemento);
	else
		elemento := null;
		resultado := json_build_object('ok', true, 'observacion', 'No hay alertas para guardar.', 'datos', elemento);
	end if;

	RETURN json_agg(resultado);
exception
	when others then
		resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: comprobaralertamedicion(text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.comprobaralertamedicion(_dev_eui text, _mediciones_json text, _bateria text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
	aux_int int := null;
	aux_bool bool := null;
	rec record;
	idsensor int;
	idnuevo int;
	idsnuevos INT[] := array[]::INT[];
	elemento json;
	resultado json;
begin

	idsensor := esq_dash_iot.getidsensor(_dev_eui);

  if idsensor is null then
		elemento := null;
    resultado := json_build_object('ok', false, 'observacion', format('No existe el sensor %s en base', _dev_eui), 'datos', elemento);
    RETURN json_agg(resultado);
  end if;

	-- Mediciones
	for rec in
		select m.id_sensor, m.tipo_medicion, m.valor, l.alarma, l.advertencia
		from (
			SELECT
				( select id from esq_dash_iot.sensores where dev_eui = _dev_eui ) as id_sensor,
			  key AS tipo_medicion,
			  value::float AS valor
			FROM json_each_text(_mediciones_json::json)
		) as m
			inner join esq_dash_iot.limites l on m.id_sensor = l.id_sensor and m.tipo_medicion = l.tipo_medicion
	loop

		if rec.alarma is not null and rec.valor >= rec.alarma then
			-- guardar en base con estado_alerta = true returning id_registro into idnuevo
            INSERT INTO esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor)
	            VALUES ('alarma', true, NOW(), rec.id_sensor, rec.tipo_medicion, rec.alarma, rec.valor)
	            RETURNING id_registro INTO idnuevo;
			idsnuevos := array_append(idsnuevos, idnuevo);
		elseif rec.alarma is not null and rec.valor < rec.alarma then
			aux_bool := ( select estado_alerta from esq_dash_iot.alertas where id_sensor = idsensor and tipo_alerta = 'alarma' and tipo_medicion = rec.tipo_medicion order by fecha desc limit 1 );
			if aux_bool = true then
				-- guardar en base con estado_alerta = false returning id_registro into idnuevo
				insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
					('alarma', false, now(), rec.id_sensor, rec.tipo_medicion, rec.alarma, rec.valor)
					returning id_registro into idnuevo;
				idsnuevos := array_append(idsnuevos, idnuevo);
			end if;
		end if;

		if rec.advertencia is not null and rec.alarma is not null and rec.valor < rec.alarma and rec.valor >= rec.advertencia then
			-- guardar en base con estado_alerta = true returning id_registro into idnuevo
			insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
				('advertencia', true, now(), rec.id_sensor, rec.tipo_medicion, rec.advertencia, rec.valor)
				returning id_registro into idnuevo;
			idsnuevos := array_append(idsnuevos, idnuevo);
		elseif rec.advertencia is not null and rec.valor >= rec.advertencia then
			-- guardar en base con estado_alerta = true returning id_registro into idnuevo
			insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
				('advertencia', true, now(), rec.id_sensor, rec.tipo_medicion, rec.advertencia, rec.valor)
				returning id_registro into idnuevo;
			idsnuevos := array_append(idsnuevos, idnuevo);
		elseif rec.advertencia is not null and rec.valor < rec.advertencia then
			aux_bool := ( select estado_alerta from esq_dash_iot.alertas where id_sensor = idsensor and tipo_alerta = 'advertencia' and tipo_medicion = rec.tipo_medicion order by fecha desc limit 1 );
			if aux_bool = true then
				-- guardar en base con estado_alerta = false returning id_registro into idnuevo
				insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
					('advertencia', false, now(), rec.id_sensor, rec.tipo_medicion, rec.advertencia, rec.valor)
					returning id_registro into idnuevo;
				idsnuevos := array_append(idsnuevos, idnuevo);
			end if;
		end if;
	end loop;

	-- Bateria
	aux_int := ( select numero from esq_dash_iot.parametros where nombre = 'bateria_baja' );
	if _bateria::int <= aux_int then
		-- guardar en base con estado_alerta = true returning id_registro into idnuevo
		insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
			('bateria_baja', true, now(), idsensor, null, aux_int::float, _bateria::float)
			returning id_registro into idnuevo;
		idsnuevos := array_append(idsnuevos, idnuevo);
	else
		aux_bool := ( select estado_alerta from esq_dash_iot.alertas where id_sensor = idsensor and tipo_alerta = 'bateria_baja' order by fecha desc limit 1 );
		if aux_bool = true then
			-- guardar en base con estado_alerta = false returning id_registro into idnuevo
			insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
				('bateria_baja', false, now(), idsensor, null, aux_int::float, _bateria::float)
				returning id_registro into idnuevo;
			idsnuevos := array_append(idsnuevos, idnuevo);
		end if;
	end if;

	-- inactividad
	aux_bool := ( select estado_alerta from esq_dash_iot.alertas where id_sensor = idsensor and tipo_alerta = 'inactividad' order by fecha desc limit 1 );
	if aux_bool = true then
		aux_int := ( select numero from esq_dash_iot.parametros where nombre = 'tiempo_inactividad_m' );
		-- guardar en base con estado_alerta = false returning id_registro into idnuevo
		insert into esq_dash_iot.alertas (tipo_alerta, estado_alerta, fecha, id_sensor, tipo_medicion, limite, valor) values
			('inactividad', false, now(), idsensor, null, aux_int::float, 0.0)
			returning id_registro into idnuevo;
		idsnuevos := array_append(idsnuevos, idnuevo);
	end if;

	if array_length(idsnuevos, 1) > 0 then
		elemento := (select json_agg(to_json(m.*)) 
			FROM ( 
				select *, 
				( select esq_dash_iot.getnotificacionesarea(id_area::text) ) as notificaciones
				from esq_dash_iot.vmostraralertas WHERE id_registro = any(idsnuevos)
				) as m
			);
		resultado := json_build_object('ok', true, 'observacion', 'Alertas guardadas con éxito.', 'datos', elemento);
	else
		elemento := null;
		resultado := json_build_object('ok', true, 'observacion', 'No hay alertas para guardar.', 'datos', elemento);
	end if;

	RETURN json_agg(resultado);
exception
	when others then
		resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: getestadoalertasensor(text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.getestadoalertasensor(_id_sensor text, _desde text DEFAULT NULL::text, _hasta text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	estado text;
	listaestadosnumero INT[] := ARRAY[]::INT[];
	medicion record;
	alarmamaxima int;
BEGIN
-- Retornar int dependiendo de que limite esta pasando o si no tiene limite 
-- int: (0: ’Sin alarma’, 1: ‘Normal’, 2: ‘Advertencia’, 3: ‘Alarma’)
	for medicion in 
		select * from (
			select DISTINCT ON (m.id_sensor, m.tipo_medicion) 
				m.id_sensor,
				m.nombre_sensor,
				m.tipo_medicion,
				m.valor,
				l.advertencia,
				l.alarma
			from esq_dash_iot.mediciones m
				inner join esq_dash_iot.sensores s on s.id = m.id_sensor
				inner join esq_dash_iot.limites l on l.id_sensor = s.id and l.tipo_medicion = m.tipo_medicion 
			where s.id = _id_sensor::int 
			and case when (_desde, _hasta) is not null then m.tiempo between _desde::timestamptz and _hasta::timestamptz else true end
			order by m.id_sensor, m.tipo_medicion, m.tiempo desc
		) as t
	loop
		if medicion.valor >= medicion.alarma then
			listaestadosnumero := array_append(listaestadosnumero, 3);
		elsif medicion.valor >= medicion.advertencia and medicion.valor < medicion.alarma then
			listaestadosnumero := array_append(listaestadosnumero, 2);
		elseif medicion.valor < medicion.advertencia then
			listaestadosnumero := array_append(listaestadosnumero, 1);
		else 
			listaestadosnumero := array_append(listaestadosnumero, 0);
		end if;
	end loop;
	alarmamaxima := COALESCE(( SELECT max(x) FROM unnest(listaestadosnumero) as x ), 0);
	RETURN (alarmamaxima);
END;
$$;


--
-- Name: getidsensor(text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.getidsensor(_dev_eui text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	BEGIN
		return (select id from esq_dash_iot.sensores where dev_eui = _dev_eui);
	END;
$$;


--
-- Name: getnotificacionesarea(text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.getnotificacionesarea(_id_area text) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
	elemento json;
	resultado json;
BEGIN
	elemento := ( select json_agg(json_build_object(
			'medio', medio,
			'ids', ids
		)) from ( 
		select medio, array_agg(id_chat) as ids 
		from esq_dash_iot.notificaciones
		where id_area is null or id_area = _id_area::int
		group by medio ) as m
	);

	return (elemento);
END;
$$;


--
-- Name: getnumerosensoresalertaarea(text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.getnumerosensoresalertaarea(_id_area text, _estado_alerta text, _desde text DEFAULT NULL::text, _hasta text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	numerosensores int := 0;
	sensorrecord record;
	estadoalerta int;
BEGIN
-- Conseguir el numero de sensores que se encuentran el los diferente limites dentro de una area
-- Solo toma en cuenta la alerta mas alta
	for sensorrecord in
		select id from esq_dash_iot.sensores where id_area = _id_area::int and inactivo = false
	loop
		estadoalerta := ( select esq_dash_iot.getestadoalertasensor(sensorrecord.id::text, _desde, _hasta) );
		if estadoalerta = _estado_alerta::int then
			numerosensores := numerosensores + 1;
		end if;
	end loop;
	RETURN (numerosensores);
END;
$$;


--
-- Name: guardarcalibracion(text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.guardarcalibracion(_id_sensor text, _fecha text, _entidad text, _usuario_email text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
    idnuevo int;
    elemento json;
    resultado json;
BEGIN
	insert into esq_dash_iot.calibraciones (id_sensor, fecha, entidad) values (_id_sensor::int, _fecha::timestamptz, _entidad) returning id into idnuevo;

	call esq_dash_iot.logger(format('Nueva Calibracion guardada. idnuevo: %s, id_sensor: %s, fecha: %s, entidad: %s', idnuevo, _id_sensor, _fecha, _entidad), 'esq_dash_iot.calibraciones', _usuario_email);

    elemento := (select json_agg(to_json(m.*)) FROM esq_dash_iot.calibraciones m WHERE id = idnuevo);

    resultado := json_build_object('ok', true, 'obserbacion', 'Calibración guardada con éxito.', 'datos', elemento);

    RETURN json_agg(resultado);
exception
    when others then
        resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: guardarmedicion(text, text, text, text, text, text, text); Type: FUNCTION; Schema: esq_dash_iot; Owner: -
--

CREATE FUNCTION esq_dash_iot.guardarmedicion(_nombre_sensor text, _dev_eui text, _tiempo text, _mediciones_json text, _bateria text, _topic text, _nombre_gateway text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
	idnuevo int;
	idmediciones INT[] := array[]::INT[];
	idgateway int;
	idsensor int;
	tipo_medicion text;
	aux int := null;
	valor text;
	elemento json;
	resultado json;
begin
	-- verificar si el gateway existe en la tabla gateways, si no crearlo
	SELECT id into idgateway FROM esq_dash_iot.gateways WHERE nombre = _nombre_gateway limit 1;	
	IF NOT FOUND THEN
		INSERT INTO esq_dash_iot.gateways (nombre, estado) VALUES (_nombre_gateway, true) RETURNING id into idgateway;
		call esq_dash_iot.logger(format('Nuevo Gateway registrado. id: %s, nombre: %s', idgateway, _nombre_gateway), 'esq_dash_iot.gateways');
	END IF;
	
	-- verificar si el sensor existe en la tabla sensores, si no crearlo
	SELECT id into idsensor FROM esq_dash_iot.sensores WHERE dev_eui = _dev_eui limit 1;
	IF NOT FOUND THEN
		INSERT INTO esq_dash_iot.sensores (id_gateway, nombre_sensor, dev_eui, bateria, topic, inactivo) VALUES 
			(idgateway, _nombre_sensor, _dev_eui, _bateria::int, _topic, false) RETURNING id into idsensor;
		call esq_dash_iot.logger(format('Nuevo Sensor registrado. id: %s, nombre: %s, DevEUI : %s', idsensor, _nombre_sensor, _dev_eui), 'esq_dash_iot.sensores');
	END IF;
	
	-- Si el gateway cambia modificar el valor de id_gateway del sensor y actualizar mas datos
	UPDATE esq_dash_iot.sensores set 
		nombre_sensor = _nombre_sensor,
		id_gateway = idgateway, 
		bateria = _bateria::int, 
		topic = _topic,
		inactivo = false
	where id = idsensor;
	
	-- guardar los datos en la tabla mediciones por cada medicion
	FOR tipo_medicion, valor IN
		SELECT key, value FROM json_each_text(_mediciones_json::json)
	LOOP
		-- verificar si existe el tipo de medicion en la tabla tipo_mediciones
		SELECT id into aux FROM esq_dash_iot.tipo_mediciones WHERE nombre = tipo_medicion limit 1;
		IF aux is null THEN
			INSERT INTO esq_dash_iot.tipo_mediciones (nombre) VALUES (tipo_medicion);
			call esq_dash_iot.logger(format('Nuevo tipo de medicion agregado: %s. Por el sensor %s', tipo_medicion, idsensor), 'esq_dash_iot.tipo_mediciones');
		END IF;
		
		INSERT INTO esq_dash_iot.mediciones (id_sensor, nombre_sensor, tiempo, tipo_medicion, valor) VALUES
			(idsensor, _nombre_sensor, _tiempo::timestamptz, tipo_medicion, valor::float) returning id_registro into idnuevo;
		idmediciones := array_append(idmediciones, idnuevo);
	END LOOP;
	
	elemento := (select json_agg(to_json(m.*)) FROM esq_dash_iot.mediciones m WHERE id_registro = any(idmediciones));
	
	resultado := json_build_object('ok', true, 'obserbacion', 'Medicion guardada con éxito.', 'datos', elemento);
	
	RETURN json_agg(resultado);
exception
	when others then
		resultado := (SELECT json_build_object('ok',FALSE,'mensaje', SQLERRM || ' Ocurrió un error inesperado. Por favor contáctese con el administrador de la aplicación.','id',idnuevo));
	RETURN json_agg(resultado);
END;
$$;


--
-- Name: logger(text, text, text); Type: PROCEDURE; Schema: esq_dash_iot; Owner: -
--

CREATE PROCEDURE esq_dash_iot.logger(IN _log text, IN _tabla text, IN _usuario_email_gf text DEFAULT NULL::text)
    LANGUAGE sql
    AS $$
	insert into esq_dash_iot.logs (tiempo, tabla, log, usuario_email_gf) values (now(), _tabla, _log, _usuario_email_gf);
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alertas; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.alertas (
    id_registro integer NOT NULL,
    tipo_alerta character varying(50) NOT NULL,
    estado_alerta boolean NOT NULL,
    fecha timestamp with time zone NOT NULL,
    id_sensor integer NOT NULL,
    tipo_medicion character varying(50),
    limite double precision,
    valor double precision
);


--
-- Name: alertas_id_registro_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.alertas_id_registro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alertas_id_registro_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.alertas_id_registro_seq OWNED BY esq_dash_iot.alertas.id_registro;


--
-- Name: areas; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.areas (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    orden integer
);


--
-- Name: areas_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: areas_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.areas_id_seq OWNED BY esq_dash_iot.areas.id;


--
-- Name: calibraciones; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.calibraciones (
    id integer NOT NULL,
    id_sensor integer NOT NULL,
    fecha timestamp with time zone NOT NULL,
    entidad character varying(250)
);


--
-- Name: calibraciones_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.calibraciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calibraciones_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.calibraciones_id_seq OWNED BY esq_dash_iot.calibraciones.id;


--
-- Name: gateways; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.gateways (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    estado boolean DEFAULT true
);


--
-- Name: gateways_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.gateways_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gateways_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.gateways_id_seq OWNED BY esq_dash_iot.gateways.id;


--
-- Name: limites; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.limites (
    id integer NOT NULL,
    id_sensor integer NOT NULL,
    tipo_medicion character varying(50),
    min double precision,
    max double precision,
    advertencia double precision,
    alarma double precision
);


--
-- Name: limites_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.limites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: limites_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.limites_id_seq OWNED BY esq_dash_iot.limites.id;


--
-- Name: logs; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.logs (
    id_registro integer NOT NULL,
    tiempo timestamp with time zone NOT NULL,
    usuario_email_gf text,
    tabla text,
    log text NOT NULL
);


--
-- Name: logs_id_registro_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.logs_id_registro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_registro_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.logs_id_registro_seq OWNED BY esq_dash_iot.logs.id_registro;


--
-- Name: mediciones; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.mediciones (
    id_registro integer NOT NULL,
    id_sensor integer NOT NULL,
    nombre_sensor character varying(50),
    tiempo timestamp with time zone NOT NULL,
    tipo_medicion character varying(50),
    valor double precision
);


--
-- Name: mediciones_id_registro_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.mediciones_id_registro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mediciones_id_registro_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.mediciones_id_registro_seq OWNED BY esq_dash_iot.mediciones.id_registro;


--
-- Name: notificaciones; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.notificaciones (
    id integer NOT NULL,
    id_area integer,
    medio character varying(50) NOT NULL,
    id_chat text NOT NULL
);


--
-- Name: notificaciones_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.notificaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notificaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.notificaciones_id_seq OWNED BY esq_dash_iot.notificaciones.id;


--
-- Name: parametros; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.parametros (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    numero integer,
    "decimal" double precision,
    texto character varying(50) DEFAULT NULL::character varying
);


--
-- Name: parametros_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.parametros_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parametros_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.parametros_id_seq OWNED BY esq_dash_iot.parametros.id;


--
-- Name: sensores; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.sensores (
    id integer NOT NULL,
    id_gateway integer NOT NULL,
    nombre_sensor character varying(50) NOT NULL,
    dev_eui character varying(50) NOT NULL,
    bateria integer,
    id_area integer,
    fecha_instalacion timestamp with time zone DEFAULT now(),
    topic character varying(50),
    inactivo boolean DEFAULT false NOT NULL,
    eliminado boolean DEFAULT false NOT NULL
);


--
-- Name: sensores_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.sensores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sensores_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.sensores_id_seq OWNED BY esq_dash_iot.sensores.id;


--
-- Name: tipo_mediciones; Type: TABLE; Schema: esq_dash_iot; Owner: -
--

CREATE TABLE esq_dash_iot.tipo_mediciones (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    unidad character varying(10)
);


--
-- Name: tipo_mediciones_id_seq; Type: SEQUENCE; Schema: esq_dash_iot; Owner: -
--

CREATE SEQUENCE esq_dash_iot.tipo_mediciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_mediciones_id_seq; Type: SEQUENCE OWNED BY; Schema: esq_dash_iot; Owner: -
--

ALTER SEQUENCE esq_dash_iot.tipo_mediciones_id_seq OWNED BY esq_dash_iot.tipo_mediciones.id;


--
-- Name: vmostraralertas; Type: VIEW; Schema: esq_dash_iot; Owner: -
--

CREATE VIEW esq_dash_iot.vmostraralertas AS
 SELECT a.id_registro,
    a.tipo_alerta,
    a.estado_alerta,
    a.fecha,
    a.id_sensor,
    s.nombre_sensor,
    a.tipo_medicion,
    tm.unidad,
    a.limite,
    a.valor,
    s.id_area,
    areas.nombre AS nombre_area
   FROM (((esq_dash_iot.alertas a
     JOIN esq_dash_iot.sensores s ON ((s.id = a.id_sensor)))
     LEFT JOIN esq_dash_iot.areas ON ((areas.id = s.id_area)))
     LEFT JOIN esq_dash_iot.tipo_mediciones tm ON (((a.tipo_medicion)::text = (tm.nombre)::text)));


--
-- Name: alertas id_registro; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.alertas ALTER COLUMN id_registro SET DEFAULT nextval('esq_dash_iot.alertas_id_registro_seq'::regclass);


--
-- Name: areas id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.areas ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.areas_id_seq'::regclass);


--
-- Name: calibraciones id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.calibraciones ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.calibraciones_id_seq'::regclass);


--
-- Name: gateways id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.gateways ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.gateways_id_seq'::regclass);


--
-- Name: limites id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.limites ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.limites_id_seq'::regclass);


--
-- Name: logs id_registro; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.logs ALTER COLUMN id_registro SET DEFAULT nextval('esq_dash_iot.logs_id_registro_seq'::regclass);


--
-- Name: mediciones id_registro; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.mediciones ALTER COLUMN id_registro SET DEFAULT nextval('esq_dash_iot.mediciones_id_registro_seq'::regclass);


--
-- Name: notificaciones id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.notificaciones ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.notificaciones_id_seq'::regclass);


--
-- Name: parametros id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.parametros ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.parametros_id_seq'::regclass);


--
-- Name: sensores id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.sensores ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.sensores_id_seq'::regclass);


--
-- Name: tipo_mediciones id; Type: DEFAULT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.tipo_mediciones ALTER COLUMN id SET DEFAULT nextval('esq_dash_iot.tipo_mediciones_id_seq'::regclass);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id_registro);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: calibraciones calibraciones_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.calibraciones
    ADD CONSTRAINT calibraciones_pkey PRIMARY KEY (id);


--
-- Name: gateways gateways_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.gateways
    ADD CONSTRAINT gateways_pkey PRIMARY KEY (id);


--
-- Name: limites limites_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.limites
    ADD CONSTRAINT limites_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pk; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.logs
    ADD CONSTRAINT logs_pk PRIMARY KEY (id_registro);


--
-- Name: mediciones mediciones_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.mediciones
    ADD CONSTRAINT mediciones_pkey PRIMARY KEY (id_registro);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);


--
-- Name: parametros parametros_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.parametros
    ADD CONSTRAINT parametros_pkey PRIMARY KEY (id);


--
-- Name: sensores sensores_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.sensores
    ADD CONSTRAINT sensores_pkey PRIMARY KEY (id);


--
-- Name: tipo_mediciones tipo_mediciones_pkey; Type: CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.tipo_mediciones
    ADD CONSTRAINT tipo_mediciones_pkey PRIMARY KEY (id);


--
-- Name: calibraciones FK_calibraciones.id_sensor; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.calibraciones
    ADD CONSTRAINT "FK_calibraciones.id_sensor" FOREIGN KEY (id_sensor) REFERENCES esq_dash_iot.sensores(id);


--
-- Name: limites FK_limites.id_sensor; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.limites
    ADD CONSTRAINT "FK_limites.id_sensor" FOREIGN KEY (id_sensor) REFERENCES esq_dash_iot.sensores(id);


--
-- Name: mediciones FK_mediciones.id_sensor; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.mediciones
    ADD CONSTRAINT "FK_mediciones.id_sensor" FOREIGN KEY (id_sensor) REFERENCES esq_dash_iot.sensores(id);


--
-- Name: notificaciones notificaciones_id_area_fkey; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.notificaciones
    ADD CONSTRAINT notificaciones_id_area_fkey FOREIGN KEY (id_area) REFERENCES esq_dash_iot.areas(id);


--
-- Name: sensores sensores_id_area_fkey; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.sensores
    ADD CONSTRAINT sensores_id_area_fkey FOREIGN KEY (id_area) REFERENCES esq_dash_iot.areas(id);


--
-- Name: sensores sensores_id_gateway_fkey; Type: FK CONSTRAINT; Schema: esq_dash_iot; Owner: -
--

ALTER TABLE ONLY esq_dash_iot.sensores
    ADD CONSTRAINT sensores_id_gateway_fkey FOREIGN KEY (id_gateway) REFERENCES esq_dash_iot.gateways(id);


--
-- PostgreSQL database dump complete
--

