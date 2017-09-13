--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: fnc_con_req(integer); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION fnc_con_req(cn_reqv integer) RETURNS TABLE(cn_req integer, cdate date, ccc_cia character varying, ccc_dimension character varying, cped_comp character varying, cgerencia character varying, cuso character varying, csolicitado integer, csolicitados text, crev_almacenp integer, crev_almacenps text, caprob integer, caprobs text, corden_comp integer, crecepcion integer, cnx integer, cobservacion character varying, cstatus character varying, ccodprod integer, cproddesc character varying, cunid character varying, ccant double precision, cpunit double precision, cdesc double precision, civa double precision)
    LANGUAGE plpgsql
    AS $$

BEGIN
RETURN QUERY  SELECT tmr.cn_req, tmr.cdate, tmr.ccc_cia, tmr.ccc_dimension, tmr.cped_comp, tmr.cgerencia, tmr.cuso, 
tmr.csolicitado, (SELECT (capellido || ', ' || cnombre) FROM t_empleados WHERE cci = tmr.csolicitado) as csolicitados,
tmr.crev_almacenp, (SELECT (capellido || ', ' || cnombre) FROM t_empleados WHERE cci = tmr.crev_almacenp) as crev_almacenps,
tmr.caprob, (SELECT (capellido || ', ' || cnombre) FROM t_empleados WHERE cci = tmr.caprob) as caprobs,
tmr.corden_comp, tmr.crecepcion, tmr.cnx, tmr.cobservacion, 
(SELECT cdescripcion FROM t_status WHERE id = tmr.cstatus) AS status,
tdr. ccodprod, (SELECT cdescripcion FROM tm_producto WHERE codprod = tdr.ccodprod) AS cproddesc,
(SELECT ctipounidad FROM tm_producto WHERE codprod = tdr.ccodprod) as cunid, 
tdr.ccant, tdr.cpunit, tdr.cdesc, 
(SELECT c_iva FROM tm_producto WHERE codprod = tdr.ccodprod) as civa
 FROM tm_req AS tmr INNER JOIN td_req AS tdr ON tmr.cn_req = tdr.cn_req
		 WHERE tmr.cn_req = cn_reqv;
END;		 
$$;


ALTER FUNCTION public.fnc_con_req(cn_reqv integer) OWNER TO joec;

--
-- Name: fnc_reg_factm_1(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION fnc_reg_factm_1() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
if (NEW.cstatus = 4 AND OLD.ct_servicio = false)
then
	--inventario
	INSERT INTO tm_inventario (cid_fact, ccodfact, clote, codprod, ct_unidad, ccant, cfechai, cfechaf, cpunit)
	SELECT tmf.id, tmf.ccodfact, tdf.clote, tdf.ccodprod, tp.ctipounidad, tdf.ccant, tmf.cfecha, tmf.cfechap, tdf.cpunit
	FROM td_factura tdf
	JOIN tm_producto tp ON tdf.ccodprod = tp.codprod
	JOIN tm_factura tmf ON tdf.clote = tmf.clote AND tdf.ccodfact = tmf.ccodfact
	WHERE NOT (tdf.ccodprod IN ( SELECT tm_inventario.codprod FROM tm_inventario WHERE cid_fact = NEW.id))
	AND tmf.id = NEW.id;
	--inventario
	--control de pago
		if not exists(SELECT * FROM tm_controlpago WHERE ccodfact = NEW.ccodfact AND clote = NEW.clote)
			then
				INSERT INTO tm_controlpago (ccodprov, crif, cproveedor, cfecha_emi, cfecha_lim, ccodfact, clote, ctotal, cstatus)
				SELECT tp.id, tp.crif, tp.cnomb_fis, tmf.cfecha, tmf.cfechap, tmf.ccodfact, tmf.clote, tmf.ctot, 6 AS cstatus
				FROM tm_factura AS tmf INNER JOIN tm_proveedor AS tp ON tmf.cproveedor = tp.id
				WHERE tmf.id = NEW.id;
			end if;
	--control de pago
end if;

		
 
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.fnc_reg_factm_1() OWNER TO joec;

--
-- Name: fnc_rep_cons2(date, date); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION fnc_rep_cons2(fini date, ffin date) RETURNS TABLE(cconcepto character varying, ctipoalmacen smallint, cdescripcion character varying, codprod integer, descripcion character varying, ctunidad character varying, unidad_con double precision, monto_con double precision, uni_prom double precision, monto_prom double precision, dias integer)
    LANGUAGE plpgsql
    AS $$

BEGIN
RETURN QUERY  

SELECT tms.cconcepto, tmp.ctipoalmacen, ttal.cdesc_cort, tds.codprod, tmp.cdescripcion as descripcion, tmp.ctipounidad as ctunidad, SUM(tds.ccant) as unidad_con, SUM(tds.ctot) as monto_con,
(SUM(tds.ccant) / ((MAX(tms.cfecha) - MIN(tms.cfecha)) + 1)) AS uni_prom, (SUM(tds.ctot) / ((MAX(tms.cfecha) - MIN(tms.cfecha)) + 1)) AS monto_prom, ((MAX(tms.cfecha) - MIN(tms.cfecha)) + 1) AS dias

FROM tm_salida_inv as tms INNER JOIN td_salida_inv AS tds ON tms.id = tds.cidm
INNER JOIN tm_producto AS tmp ON tds.codprod = tmp.codprod
INNER JOIN ttipo_almacen as ttal ON tms.ctipo_almacen = ttal.ctipoalmacen
WHERE tms.cfecha BETWEEN fini and ffin
GROUP BY tms.cconcepto, tmp.ctipoalmacen, ttal.cdesc_cort, tds.codprod, descripcion, ctunidad
ORDER BY tds.codprod;

END;         
$$;


ALTER FUNCTION public.fnc_rep_cons2(fini date, ffin date) OWNER TO joec;

--
-- Name: fnc_test(integer); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION fnc_test(cn_reqv integer) RETURNS TABLE(cn_req integer, cdate date, ccc_cia character varying, ccc_dimension character varying, cped_comp character varying, cgerencia character varying, cuso character varying, csolicitado character varying, crev_almacenp character varying, caprob character varying, corden_comp integer, crecepcion integer, cnx integer, cobservacion character varying, cstatus smallint, ccodprod integer, cunid character varying, ccant double precision, cpunit double precision, cdesc double precision)
    LANGUAGE plpgsql
    AS $$

BEGIN
RETURN QUERY SELECT tm.cn_req, tm.cdate, tm.ccc_cia, tm.ccc_dimension, tm.cped_comp, tm.cgerencia, tm.cuso, 
			cast(tm.csolicitado AS character varying(100)), cast(tm.crev_almacenp AS character varying(100)), cast(tm.caprob AS character varying(100)), 
			tm.corden_comp, tm.crecepcion, tm.cnx, tm.cobservacion, tm.cstatus,
			td.ccodprod, td.cunid, td.ccant, td.cpunit, td.cdesc 
			FROM tm_req AS tm INNER JOIN td_req AS td ON tm.cn_req = td.cn_req 
			WHERE tm.cn_req = 159;
			END;
$$;


ALTER FUNCTION public.fnc_test(cn_reqv integer) OWNER TO joec;

--
-- Name: td_entrada_inv_d(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION td_entrada_inv_d() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
  --INSERT INTO test_salida(cant_ant, cant_new, cant_tot, codprod) SELECT ccant, NEW.ccant, (ccant - NEW.ccant), codprod FROM tm_inventario WHERE ccodfact = NEW.ccodfact AND clote = NEW.clote AND codprod = NEW.codprod;
 UPDATE tm_inventario SET ccant = (ccant + NEW.ccant) WHERE ccodfact = NEW.ccodfact AND clote = NEW.clote AND codprod = NEW.codprod;
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.td_entrada_inv_d() OWNER TO joec;

--
-- Name: td_salida_inv_d(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION td_salida_inv_d() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
  --INSERT INTO test_salida(cant_ant, cant_new, cant_tot, codprod) SELECT ccant, NEW.ccant, (ccant - NEW.ccant), codprod FROM tm_inventario WHERE ccodfact = NEW.ccodfact AND clote = NEW.clote AND codprod = NEW.codprod;
 UPDATE tm_inventario SET ccant = (ccant - NEW.ccant) WHERE ccodfact = NEW.ccodfact AND clote = NEW.clote AND codprod = NEW.codprod;
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.td_salida_inv_d() OWNER TO joec;

--
-- Name: test(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION test() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
 INSERT INTO test_trigger(val1, val2, val3) VALUES (NEW.cn_req, '1', NEW.id);  
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.test() OWNER TO joec;

--
-- Name: test_fact(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION test_fact() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
 INSERT INTO test_trigger(val1, val2, val3) VALUES 
 (NEW.ccodprod, 
 (SELECT cdescripcion FROM tm_producto WHERE codprod = NEW.ccodprod), 
 (SELECT ctipoalmacen FROM tm_producto WHERE codprod = NEW.ccodprod)); 
 
  
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.test_fact() OWNER TO joec;

--
-- Name: upd_req_oc_ins(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION upd_req_oc_ins() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
 UPDATE tm_req SET cstatus = 4 WHERE cstatus = 1 AND cn_req = NEW.cn_req;
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.upd_req_oc_ins() OWNER TO joec;

--
-- Name: upd_status_oc(); Type: FUNCTION; Schema: public; Owner: joec
--

CREATE FUNCTION upd_status_oc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  

if exists(SELECT * FROM tm_ordencompra WHERE id = NEW.id AND (caprob1st = TRUE AND caprob2st = TRUE) AND cstatus = 1)
then
UPDATE tm_ordencompra SET cstatus = 4 WHERE id = NEW.id AND (caprob1st = TRUE AND caprob2st = TRUE);
end if;
 
RETURN NEW;  
END;  
$$;


ALTER FUNCTION public.upd_status_oc() OWNER TO joec;

--
-- Name: seq_tm_contropago; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_contropago
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_contropago OWNER TO joec;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: t_status; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_status (
    id smallint NOT NULL,
    cdescripcion character varying(20)
);


ALTER TABLE t_status OWNER TO joec;

--
-- Name: tm_controlpago; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_controlpago (
    id integer DEFAULT nextval('seq_tm_contropago'::regclass) NOT NULL,
    ccodprov integer DEFAULT 0 NOT NULL,
    crif character varying(50) DEFAULT 0 NOT NULL,
    cproveedor character varying(255) DEFAULT 0 NOT NULL,
    cfecha_emi date NOT NULL,
    cfecha_lim date,
    ccodfact character varying(150) DEFAULT 0 NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    ctotal double precision DEFAULT 0 NOT NULL,
    cstatus smallint DEFAULT 0 NOT NULL
);


ALTER TABLE tm_controlpago OWNER TO joec;

--
-- Name: dbv_controlpago; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_controlpago AS
 SELECT tcp.id,
    tcp.ccodprov,
    tcp.crif,
    tcp.cproveedor,
    tcp.cfecha_emi,
    tcp.cfecha_lim,
    tcp.ccodfact,
    tcp.clote,
    tcp.ctotal,
    tcp.cstatus,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tcp.cstatus)) AS status
   FROM tm_controlpago tcp;


ALTER TABLE dbv_controlpago OWNER TO joec;

--
-- Name: seq_t_cargo; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_t_cargo
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_t_cargo OWNER TO joec;

--
-- Name: seq_td_ordencompra; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_ordencompra
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_ordencompra OWNER TO joec;

--
-- Name: seq_td_req; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_req
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_req OWNER TO joec;

--
-- Name: seq_tm_req; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_req
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_req OWNER TO joec;

--
-- Name: t_cargo; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_cargo (
    id integer DEFAULT nextval('seq_t_cargo'::regclass) NOT NULL,
    cdescripcion character varying(100) NOT NULL,
    caprob boolean DEFAULT false NOT NULL
);


ALTER TABLE t_cargo OWNER TO joec;

--
-- Name: t_empleados; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_empleados (
    cci integer NOT NULL,
    cnombre character varying(100) NOT NULL,
    capellido character varying(100) NOT NULL,
    cgroup smallint NOT NULL,
    ctelefono character varying(15),
    cemail character varying(255),
    cfirma boolean DEFAULT false NOT NULL,
    ccargo smallint DEFAULT 0 NOT NULL
);


ALTER TABLE t_empleados OWNER TO joec;

--
-- Name: td_ordencompra; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_ordencompra (
    id integer DEFAULT nextval('seq_td_ordencompra'::regclass) NOT NULL,
    cnorden integer NOT NULL,
    ccodprod integer NOT NULL,
    cdescripcion character varying(150),
    ctipounidad character varying(50) NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    cpunit double precision DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    cdesc double precision DEFAULT 0 NOT NULL,
    c_iva double precision DEFAULT 0 NOT NULL,
    cstot double precision DEFAULT 0 NOT NULL,
    cn_req integer DEFAULT 0 NOT NULL,
    cdesc_serv character varying(255) DEFAULT ''::character varying NOT NULL,
    ct_directa boolean DEFAULT false NOT NULL
);


ALTER TABLE td_ordencompra OWNER TO joec;

--
-- Name: td_req; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_req (
    id integer DEFAULT nextval('seq_td_req'::regclass) NOT NULL,
    cn_req integer NOT NULL,
    citem smallint NOT NULL,
    ccodprod integer NOT NULL,
    ccant double precision DEFAULT 0.00 NOT NULL,
    cpunit double precision DEFAULT 0.00 NOT NULL,
    cdesc double precision DEFAULT 0.00 NOT NULL
);


ALTER TABLE td_req OWNER TO joec;

--
-- Name: tm_producto; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_producto (
    codprod integer NOT NULL,
    cdescripcion character varying(250) NOT NULL,
    ctipoprod smallint NOT NULL,
    ctipoalmacen smallint NOT NULL,
    ctipounidad character varying(30) NOT NULL,
    c_iva double precision DEFAULT 0.00 NOT NULL,
    ce_iva boolean DEFAULT false NOT NULL,
    cm_prima boolean DEFAULT true NOT NULL
);


ALTER TABLE tm_producto OWNER TO joec;

--
-- Name: tm_req; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_req (
    id integer DEFAULT nextval('seq_tm_req'::regclass) NOT NULL,
    cn_req integer NOT NULL,
    cdate date NOT NULL,
    ccc_cia character varying(30) DEFAULT ''::character varying NOT NULL,
    ccc_dimension character varying(150) DEFAULT ''::character varying NOT NULL,
    cped_comp character varying(100) NOT NULL,
    cgerencia character varying(100),
    cuso character varying(100) NOT NULL,
    csolicitado integer DEFAULT 0 NOT NULL,
    crev_almacenp integer DEFAULT 0 NOT NULL,
    caprob integer NOT NULL,
    corden_comp integer DEFAULT 0 NOT NULL,
    crecepcion integer DEFAULT 0 NOT NULL,
    cnx integer DEFAULT 0 NOT NULL,
    cobservacion character varying(255) DEFAULT ''::character varying NOT NULL,
    cstatus smallint DEFAULT 1 NOT NULL,
    ct_servicio boolean DEFAULT false NOT NULL
);


ALTER TABLE tm_req OWNER TO joec;

--
-- Name: dbv_det_req; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_det_req AS
 SELECT tmr.cn_req,
    tmr.cdate,
    tmr.ccc_cia,
    tmr.ccc_dimension,
    tmr.cped_comp,
    tmr.cgerencia,
    ( SELECT t_cargo.cdescripcion
           FROM t_cargo
          WHERE (t_cargo.id = (tmr.cgerencia)::integer)) AS cgerencias,
    tmr.cuso,
    tmr.csolicitado,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.csolicitado)) AS csolicitados,
    tmr.crev_almacenp,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.crev_almacenp)) AS crev_almacenps,
    tmr.caprob,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.caprob)) AS caprobs,
    tmr.corden_comp,
    tmr.crecepcion,
    tmr.cnx,
    tmr.cobservacion,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmr.cstatus)) AS status,
    tdr.ccodprod,
    ( SELECT tm_producto.cdescripcion
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS cproddesc,
    ( SELECT tm_producto.ctipounidad
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS cunid,
    tdr.ccant,
    tdr.cpunit,
    tdr.cdesc,
    ( SELECT tm_producto.c_iva
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS c_iva
   FROM (tm_req tmr
     JOIN td_req tdr ON ((tmr.cn_req = tdr.cn_req)))
  WHERE (NOT (tdr.ccodprod IN ( SELECT td_ordencompra.ccodprod
           FROM td_ordencompra
          WHERE (td_ordencompra.cn_req = tmr.cn_req))));


ALTER TABLE dbv_det_req OWNER TO joec;

--
-- Name: dbv_det_req_com; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_det_req_com AS
 SELECT tmr.cn_req,
    tmr.cdate,
    tmr.ccc_cia,
    tmr.ccc_dimension,
    tmr.cped_comp,
    tmr.cgerencia,
    ( SELECT t_cargo.cdescripcion
           FROM t_cargo
          WHERE (t_cargo.id = (tmr.cgerencia)::integer)) AS cgerencias,
    tmr.cuso,
    tmr.csolicitado,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.csolicitado)) AS csolicitados,
    tmr.crev_almacenp,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.crev_almacenp)) AS crev_almacenps,
    tmr.caprob,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.caprob)) AS caprobs,
    tmr.corden_comp,
    tmr.crecepcion,
    tmr.cnx,
    tmr.cobservacion,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmr.cstatus)) AS status,
    tdr.ccodprod,
    ( SELECT tm_producto.cdescripcion
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS cproddesc,
    ( SELECT tm_producto.ctipounidad
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS cunid,
    tdr.ccant,
    tdr.cpunit,
    tdr.cdesc,
    ( SELECT tm_producto.c_iva
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS c_iva
   FROM (tm_req tmr
     JOIN td_req tdr ON ((tmr.cn_req = tdr.cn_req)));


ALTER TABLE dbv_det_req_com OWNER TO joec;

--
-- Name: td_req_serv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_req_serv (
    id integer DEFAULT nextval('seq_td_req'::regclass) NOT NULL,
    cn_req integer NOT NULL,
    citem smallint NOT NULL,
    ccodprod integer NOT NULL,
    cdescripcion character varying(255) DEFAULT ''::character varying NOT NULL,
    ccant double precision DEFAULT 0.00 NOT NULL,
    cpunit double precision DEFAULT 0.00 NOT NULL,
    cdesc double precision DEFAULT 0.00 NOT NULL
);


ALTER TABLE td_req_serv OWNER TO joec;

--
-- Name: dbv_det_req_ser; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_det_req_ser AS
 SELECT tmr.cn_req,
    tmr.cdate,
    tmr.ccc_cia,
    tmr.ccc_dimension,
    tmr.cped_comp,
    tmr.cgerencia,
    ( SELECT t_cargo.cdescripcion
           FROM t_cargo
          WHERE (t_cargo.id = (tmr.cgerencia)::integer)) AS cgerencias,
    tmr.cuso,
    tmr.csolicitado,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.csolicitado)) AS csolicitados,
    tmr.crev_almacenp,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.crev_almacenp)) AS crev_almacenps,
    tmr.caprob,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmr.caprob)) AS caprobs,
    tmr.corden_comp,
    tmr.crecepcion,
    tmr.cnx,
    tmr.cobservacion,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmr.cstatus)) AS status,
    tdr.ccodprod,
    ( SELECT tm_producto.cdescripcion
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS cproddesc,
    tdr.cdescripcion,
    tdr.ccant,
    tdr.cpunit,
    tdr.cdesc,
    ( SELECT tm_producto.c_iva
           FROM tm_producto
          WHERE (tm_producto.codprod = tdr.ccodprod)) AS c_iva
   FROM (tm_req tmr
     JOIN td_req_serv tdr ON ((tmr.cn_req = tdr.cn_req)));


ALTER TABLE dbv_det_req_ser OWNER TO joec;

--
-- Name: seq_td_factura; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_factura
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_factura OWNER TO joec;

--
-- Name: seq_tm_factura_ent; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_factura_ent
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_factura_ent OWNER TO joec;

--
-- Name: seq_tm_proveedor; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_proveedor
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_proveedor OWNER TO joec;

--
-- Name: t_pago; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_pago (
    id smallint NOT NULL,
    cdescripcion character varying NOT NULL
);


ALTER TABLE t_pago OWNER TO joec;

--
-- Name: td_factura; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_factura (
    id integer DEFAULT nextval('seq_td_factura'::regclass) NOT NULL,
    ccodfact character varying(150) NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccodprod integer DEFAULT 0 NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    cpunit double precision DEFAULT 0 NOT NULL,
    cdesc double precision DEFAULT 0 NOT NULL,
    civa double precision DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    cstot double precision DEFAULT 0 NOT NULL,
    cstatus smallint DEFAULT 4 NOT NULL
);


ALTER TABLE td_factura OWNER TO joec;

--
-- Name: tm_factura; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_factura (
    id integer DEFAULT nextval('seq_tm_factura_ent'::regclass) NOT NULL,
    cfecha date NOT NULL,
    cfechap date,
    cordencomp integer DEFAULT 0 NOT NULL,
    cproveedor integer NOT NULL,
    ccodfact character varying(150),
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccon_pago smallint,
    crecib integer NOT NULL,
    caprob integer NOT NULL,
    ct_cantp double precision,
    csubtot double precision NOT NULL,
    ctot double precision NOT NULL,
    cstatus smallint DEFAULT 1 NOT NULL,
    cf_dir boolean DEFAULT false NOT NULL,
    ct_servicio boolean DEFAULT false NOT NULL
);


ALTER TABLE tm_factura OWNER TO joec;

--
-- Name: tm_proveedor; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_proveedor (
    id integer DEFAULT nextval('seq_tm_proveedor'::regclass) NOT NULL,
    crif character varying(30) NOT NULL,
    cnomb_fis character varying(255) NOT NULL,
    cnomb_com character varying(255),
    ctlf1 character varying(30),
    ctlf2 character varying(30),
    cemail character varying(100),
    cdireccion character varying(255),
    cestado character varying(255),
    ctipoprod smallint DEFAULT 1 NOT NULL
);


ALTER TABLE tm_proveedor OWNER TO joec;

--
-- Name: dbv_fact_det; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_fact_det AS
 SELECT tmf.id,
    tmf.cfecha,
    tmf.cfechap,
    tmf.ccodfact,
    tmf.clote,
    tmf.ct_cantp,
    tmf.csubtot,
    tmf.ctot,
    tst.cdescripcion AS cstatus,
    tip.cdescripcion AS ctipo_pago,
    tmp.cnomb_fis,
    tmp.crif,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmf.caprob)) AS caprob,
    ( SELECT ((tm_producto.codprod || '-'::text) || (tm_producto.cdescripcion)::text)
           FROM tm_producto
          WHERE (tm_producto.codprod = tdf.ccodprod)) AS cprod,
    tdf.ccant,
    tdf.cpunit,
    tdf.cdesc,
    tdf.civa,
    tdf.cstot AS cstot_prod,
    tdf.ctot AS ctot_prod
   FROM ((((tm_factura tmf
     JOIN tm_proveedor tmp ON ((tmf.cproveedor = tmp.id)))
     JOIN t_pago tip ON ((tmf.ccon_pago = tip.id)))
     JOIN t_status tst ON ((tmf.cstatus = tst.id)))
     JOIN td_factura tdf ON (((tmf.ccodfact)::text = (tdf.ccodfact)::text)));


ALTER TABLE dbv_fact_det OWNER TO joec;

--
-- Name: dbv_fact_ms; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_fact_ms AS
 SELECT tmf.cfecha,
    tmf.cfechap,
    tmf.ccodfact,
    tmf.clote,
    tmf.ct_cantp,
    tmf.csubtot,
    tmf.ctot,
    tst.cdescripcion AS cstatus,
    tip.cdescripcion AS ctipo_pago,
    tmp.id,
    tmp.cnomb_fis,
    tmp.crif,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmf.caprob)) AS caprob
   FROM (((tm_factura tmf
     JOIN tm_proveedor tmp ON ((tmf.cproveedor = tmp.id)))
     JOIN t_pago tip ON ((tmf.ccon_pago = tip.id)))
     JOIN t_status tst ON ((tmf.cstatus = tst.id)));


ALTER TABLE dbv_fact_ms OWNER TO joec;

--
-- Name: dbv_inv_m; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_m AS
 SELECT tmf.id,
    tmf.ccodfact,
    tdf.clote,
    tdf.ccodprod,
    tp.ctipounidad,
    tdf.ccant,
    tmf.cfecha,
    tmf.cfechap
   FROM ((td_factura tdf
     JOIN tm_producto tp ON ((tdf.ccodprod = tp.codprod)))
     JOIN tm_factura tmf ON ((((tdf.clote)::text = (tmf.clote)::text) AND ((tdf.ccodfact)::text = (tmf.ccodfact)::text))));


ALTER TABLE dbv_inv_m OWNER TO joec;

--
-- Name: seq_tm_inventario; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_inventario
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_inventario OWNER TO joec;

--
-- Name: tm_inventario; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_inventario (
    id integer DEFAULT nextval('seq_tm_inventario'::regclass) NOT NULL,
    cid_fact integer DEFAULT 0 NOT NULL,
    ccodfact character varying(150) DEFAULT 0 NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    codprod integer DEFAULT 0 NOT NULL,
    ct_unidad character varying(20) DEFAULT 0 NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    cfechai date,
    cfechaf date,
    cpunit double precision DEFAULT 0 NOT NULL,
    cfecha_reg date DEFAULT now() NOT NULL
);


ALTER TABLE tm_inventario OWNER TO joec;

--
-- Name: ttipo_almacen; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE ttipo_almacen (
    ctipoalmacen smallint NOT NULL,
    cdescripcion character varying NOT NULL,
    cdesc_cort character varying(10) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE ttipo_almacen OWNER TO joec;

--
-- Name: dbv_inv_prov; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_prov AS
 SELECT tpr.id AS idprov,
    tpr.crif,
    tpr.cnomb_fis,
    ti.ccodfact,
    ti.clote,
    ttal.cdescripcion AS ctipoalm,
    tp.ctipoalmacen,
    ti.codprod,
    tp.cdescripcion,
    ti.ct_unidad,
    ti.ccant,
    ti.cfechai,
    ti.cfechaf,
    ti.cpunit
   FROM ((((tm_inventario ti
     JOIN tm_producto tp ON ((ti.codprod = tp.codprod)))
     JOIN tm_factura tmf ON (((ti.ccodfact)::text = (tmf.ccodfact)::text)))
     JOIN tm_proveedor tpr ON ((tmf.cproveedor = tpr.id)))
     JOIN ttipo_almacen ttal ON ((tp.ctipoalmacen = ttal.ctipoalmacen)))
  WHERE (ti.ccant > (0)::double precision);


ALTER TABLE dbv_inv_prov OWNER TO joec;

--
-- Name: dbv_inv_prov2; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_prov2 AS
 SELECT tpr.id AS idprov,
    tpr.crif,
    tpr.cnomb_fis,
    ti.ccodfact,
    ti.clote,
    ttal.cdescripcion AS ctipoalm,
    tp.ctipoalmacen,
    ti.codprod,
    tp.cdescripcion,
    ti.ct_unidad,
    ti.ccant,
    ti.cfechai,
    ti.cfechaf,
    ti.cpunit,
    ( SELECT sum((dbv_inv_prov.ccant * dbv_inv_prov.cpunit)) AS sum
           FROM dbv_inv_prov
          WHERE (dbv_inv_prov.ctipoalmacen = tp.ctipoalmacen)) AS ctotalm,
    ( SELECT sum((dbv_inv_prov.ccant * dbv_inv_prov.cpunit)) AS sum
           FROM dbv_inv_prov) AS ctotalmg
   FROM ((((tm_inventario ti
     JOIN tm_producto tp ON ((ti.codprod = tp.codprod)))
     JOIN tm_factura tmf ON (((ti.ccodfact)::text = (tmf.ccodfact)::text)))
     JOIN tm_proveedor tpr ON ((tmf.cproveedor = tpr.id)))
     JOIN ttipo_almacen ttal ON ((tp.ctipoalmacen = ttal.ctipoalmacen)))
  WHERE (ti.ccant > (0)::double precision);


ALTER TABLE dbv_inv_prov2 OWNER TO joec;

--
-- Name: seq_tm_invstock; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_invstock
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_invstock OWNER TO joec;

--
-- Name: tm_invstock; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_invstock (
    id integer DEFAULT nextval('seq_tm_invstock'::regclass) NOT NULL,
    ctipo_almacen smallint DEFAULT 0 NOT NULL,
    ccodprod integer DEFAULT 0 NOT NULL,
    ctunidad character varying(50) DEFAULT ''::character varying NOT NULL,
    cstock_min double precision DEFAULT 0 NOT NULL,
    cstock_max double precision DEFAULT 0 NOT NULL,
    cstock_crit double precision DEFAULT 0 NOT NULL
);


ALTER TABLE tm_invstock OWNER TO joec;

--
-- Name: dbv_inv_prov3; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_prov3 AS
 SELECT dbv_inv_prov2.ctipoalmacen,
    dbv_inv_prov2.ctipoalm,
    dbv_inv_prov2.codprod,
    dbv_inv_prov2.cdescripcion,
    dbv_inv_prov2.ct_unidad,
    sum(dbv_inv_prov2.ccant) AS ccant,
    sum((dbv_inv_prov2.ccant * dbv_inv_prov2.cpunit)) AS ctot,
    max(dbv_inv_prov2.cpunit) AS cpunit,
    dbv_inv_prov2.ctotalm,
    dbv_inv_prov2.ctotalmg,
    ( SELECT
                CASE
                    WHEN (tm_invstock.cstock_min < sum(dbv_inv_prov2.ccant)) THEN 1
                    WHEN ((tm_invstock.cstock_min >= sum(dbv_inv_prov2.ccant)) AND (tm_invstock.cstock_crit < sum(dbv_inv_prov2.ccant))) THEN 2
                    WHEN (tm_invstock.cstock_crit >= sum(dbv_inv_prov2.ccant)) THEN 3
                    ELSE 0
                END AS "case"
           FROM tm_invstock
          WHERE (tm_invstock.ccodprod = dbv_inv_prov2.codprod)) AS stock
   FROM dbv_inv_prov2
  GROUP BY dbv_inv_prov2.ctipoalmacen, dbv_inv_prov2.ctipoalm, dbv_inv_prov2.codprod, dbv_inv_prov2.cdescripcion, dbv_inv_prov2.ct_unidad, dbv_inv_prov2.ctotalm, dbv_inv_prov2.ctotalmg
  ORDER BY dbv_inv_prov2.ctipoalm, dbv_inv_prov2.codprod;


ALTER TABLE dbv_inv_prov3 OWNER TO joec;

--
-- Name: dbv_inv_prov3_old; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_prov3_old AS
 SELECT dbv_inv_prov2.idprov,
    dbv_inv_prov2.crif,
    dbv_inv_prov2.cnomb_fis,
    dbv_inv_prov2.ccodfact,
    dbv_inv_prov2.clote,
    dbv_inv_prov2.ctipoalm,
    dbv_inv_prov2.ctipoalmacen,
    dbv_inv_prov2.codprod,
    dbv_inv_prov2.cdescripcion,
    dbv_inv_prov2.ct_unidad,
    dbv_inv_prov2.ccant,
    dbv_inv_prov2.cfechai,
    dbv_inv_prov2.cfechaf,
    dbv_inv_prov2.cpunit,
    dbv_inv_prov2.ctotalm,
    dbv_inv_prov2.ctotalmg,
    ( SELECT
                CASE
                    WHEN (tm_invstock.cstock_min < dbv_inv_prov2.ccant) THEN 1
                    WHEN ((tm_invstock.cstock_min >= dbv_inv_prov2.ccant) AND (tm_invstock.cstock_crit < dbv_inv_prov2.ccant)) THEN 2
                    WHEN (tm_invstock.cstock_crit >= dbv_inv_prov2.ccant) THEN 3
                    ELSE 0
                END AS "case"
           FROM tm_invstock
          WHERE (tm_invstock.ccodprod = dbv_inv_prov2.codprod)) AS stock
   FROM dbv_inv_prov2;


ALTER TABLE dbv_inv_prov3_old OWNER TO joec;

--
-- Name: dbv_inv_stock; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_inv_stock AS
 SELECT tmp.codprod,
    tmp.cdescripcion,
    tmp.ctipoalmacen,
    ttal.cdescripcion AS calmacen,
    sum(tin.ccant) AS ccant,
    tmp.ctipounidad,
        CASE
            WHEN (tst.cstock_min < sum(tin.ccant)) THEN 1
            WHEN ((tst.cstock_min >= sum(tin.ccant)) AND (tst.cstock_crit < sum(tin.ccant))) THEN 2
            WHEN (tst.cstock_crit >= sum(tin.ccant)) THEN 3
            ELSE 0
        END AS calert,
    tst.cstock_crit,
    tst.cstock_min,
    tst.cstock_max
   FROM (((tm_inventario tin
     JOIN tm_invstock tst ON ((tin.codprod = tst.ccodprod)))
     JOIN tm_producto tmp ON ((tin.codprod = tmp.codprod)))
     JOIN ttipo_almacen ttal ON ((tmp.ctipoalmacen = ttal.ctipoalmacen)))
  WHERE (tst.cstock_crit > (0)::double precision)
  GROUP BY tmp.codprod, tmp.cdescripcion, tmp.ctipoalmacen, ttal.cdescripcion, tmp.ctipounidad, tst.cstock_crit, tst.cstock_min, tst.cstock_max
  ORDER BY tmp.codprod;


ALTER TABLE dbv_inv_stock OWNER TO joec;

--
-- Name: dbv_mst_productos; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_mst_productos AS
 SELECT tp.codprod,
    tp.cdescripcion,
    tp.ctipoprod,
    tp.ctipoalmacen,
    tta.cdescripcion AS desc_almacen,
    tp.ctipounidad,
    tp.c_iva,
    tp.ce_iva
   FROM (tm_producto tp
     JOIN ttipo_almacen tta ON ((tp.ctipoalmacen = tta.ctipoalmacen)));


ALTER TABLE dbv_mst_productos OWNER TO joec;

--
-- Name: seq_tm_ordencompra; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_ordencompra
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_ordencompra OWNER TO joec;

--
-- Name: tm_ordencompra; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_ordencompra (
    id integer DEFAULT nextval('seq_tm_ordencompra'::regclass) NOT NULL,
    cfecha date NOT NULL,
    cproveedor integer NOT NULL,
    cprovnombre character varying(150) NOT NULL,
    ctipo_pago smallint NOT NULL,
    csolicitado integer NOT NULL,
    caprob1 integer NOT NULL,
    caprob2 integer NOT NULL,
    ctotal double precision DEFAULT 0 NOT NULL,
    cobservaciones character varying(255) DEFAULT ''::character varying NOT NULL,
    cdescripcion character varying(150) DEFAULT 'Orden de Compra'::character varying NOT NULL,
    cn_req integer DEFAULT 0 NOT NULL,
    cstatus smallint DEFAULT 1 NOT NULL,
    caprob2st boolean DEFAULT false NOT NULL,
    caprob1st boolean DEFAULT false NOT NULL,
    cfecha_est1 date,
    cfecha_est2 date,
    cstotal double precision DEFAULT 0 NOT NULL,
    c_cotizacion character varying(100) DEFAULT 0 NOT NULL,
    ct_servicio boolean DEFAULT false NOT NULL,
    ct_directa boolean DEFAULT false NOT NULL
);


ALTER TABLE tm_ordencompra OWNER TO joec;

--
-- Name: dbv_oc_con; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_oc_con AS
 SELECT tmc.cfecha,
    tmc.id,
    ( SELECT t_cargo.cdescripcion
           FROM t_cargo
          WHERE (t_cargo.id = tmc.csolicitado)) AS csolicitado,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob1)) AS caprob1,
    tmc.caprob1st,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob2)) AS caprob2,
    tmc.caprob2st,
    tmp.crif,
    tmp.cnomb_fis,
    tp.cdescripcion,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmc.cstatus)) AS cstatus
   FROM ((tm_ordencompra tmc
     JOIN tm_proveedor tmp ON ((tmc.cproveedor = tmp.id)))
     JOIN t_pago tp ON ((tmc.ctipo_pago = tp.id)));


ALTER TABLE dbv_oc_con OWNER TO joec;

--
-- Name: t_group_cargo; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_group_cargo (
    id smallint DEFAULT 0 NOT NULL,
    cdescripcion character varying(50) DEFAULT 0 NOT NULL,
    caprob boolean DEFAULT false NOT NULL,
    cgroup smallint DEFAULT 0 NOT NULL
);


ALTER TABLE t_group_cargo OWNER TO joec;

--
-- Name: dbv_oc_con_det; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_oc_con_det AS
 SELECT tmc.cfecha,
    tmc.id,
    tmc.cn_req,
    tmc.c_cotizacion,
    tmp.id AS idp,
    tmp.crif,
    tmc.cprovnombre,
    tmp.ctlf1,
    tmp.cdireccion,
    tmc.ctipo_pago,
    ( SELECT t_pago.cdescripcion
           FROM t_pago
          WHERE (t_pago.id = tmc.ctipo_pago)) AS ctipo_pagos,
    ( SELECT tcx.cdescripcion
           FROM (tm_req trx
             JOIN t_cargo tcx ON (((trx.cgerencia)::integer = tcx.id)))
          WHERE (trx.cn_req = tmc.cn_req)) AS cgersol,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.csolicitado)) AS csolicitado,
    tmc.caprob1 AS caprob1cci,
    tmc.caprob1st,
    ( SELECT (((tgz.cdescripcion)::text || ' DE '::text) || (tcz.cdescripcion)::text)
           FROM ((t_empleados tez
             JOIN t_cargo tcz ON ((tez.cgroup = tcz.id)))
             JOIN t_group_cargo tgz ON ((tez.ccargo = tgz.id)))
          WHERE (tez.cci = tmc.caprob1)) AS caprob1cargo,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob1)) AS caprob1,
    tmc.caprob2 AS caprob2cci,
    tmc.caprob2st,
    ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob2)) AS caprob2,
    ( SELECT (((tgz.cdescripcion)::text || ' DE '::text) || (tcz.cdescripcion)::text)
           FROM ((t_empleados tez
             JOIN t_cargo tcz ON ((tez.cgroup = tcz.id)))
             JOIN t_group_cargo tgz ON ((tez.ccargo = tgz.id)))
          WHERE (tez.cci = tmc.caprob2)) AS caprob2cargo,
    tmc.cstotal,
    tmc.ctotal,
    tmc.cobservaciones,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmc.cstatus)) AS cstatuss,
    tmc.cstatus,
    tmc.cfecha_est1,
    tmc.cfecha_est2,
    tdc.ccodprod,
    ( SELECT tm_producto.cdescripcion
           FROM tm_producto
          WHERE (tm_producto.codprod = tdc.ccodprod)) AS cdescp,
    tdc.cdescripcion,
    tdc.ctipounidad,
    tdc.ccant,
    tdc.cpunit,
    tdc.cstot,
    tdc.ctot,
    tdc.cdesc,
    tdc.c_iva,
    (tmc.ctotal - tmc.cstotal) AS ivaf,
    tmc.ct_servicio,
    tdc.cdesc_serv
   FROM ((tm_ordencompra tmc
     JOIN td_ordencompra tdc ON ((tmc.id = tdc.cnorden)))
     JOIN tm_proveedor tmp ON ((tmc.cproveedor = tmp.id)));


ALTER TABLE dbv_oc_con_det OWNER TO joec;

--
-- Name: dbv_oc_con_ms; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_oc_con_ms AS
 SELECT tmc.cfecha,
    tmc.id,
    tmc.cn_req,
    tmp.crif,
    tmp.id AS pid,
    tmp.cnomb_fis,
    tmp.ctlf1,
    tmp.cdireccion,
    ( SELECT t_pago.cdescripcion
           FROM t_pago
          WHERE (t_pago.id = tmc.ctipo_pago)) AS ctipo_pago,
    ((tmc.csolicitado || ' - '::text) || ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.csolicitado))) AS csolicitado,
    ((tmc.caprob1 || ' - '::text) || ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob1))) AS caprob1,
    ((tmc.caprob2 || ' - '::text) || ( SELECT (((t_empleados.capellido)::text || ', '::text) || (t_empleados.cnombre)::text)
           FROM t_empleados
          WHERE (t_empleados.cci = tmc.caprob2))) AS caprob2,
    tmc.ctotal,
    tmc.cobservaciones,
    ( SELECT t_status.cdescripcion
           FROM t_status
          WHERE (t_status.id = tmc.cstatus)) AS cstatuss,
    tmc.cstatus
   FROM (tm_ordencompra tmc
     JOIN tm_proveedor tmp ON ((tmc.cproveedor = tmp.id)))
  WHERE (NOT (tmc.id IN ( SELECT tm_factura.cordencomp
           FROM tm_factura)));


ALTER TABLE dbv_oc_con_ms OWNER TO joec;

--
-- Name: dbv_oc_status; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_oc_status AS
 SELECT tmo.id,
    tmo.cfecha,
    tmo.cproveedor,
    tmo.cprovnombre,
    tp.crif,
    tmo.ctotal,
    tmo.cobservaciones,
    tmo.cstatus,
    ts.cdescripcion
   FROM ((tm_ordencompra tmo
     JOIN t_status ts ON ((tmo.cstatus = ts.id)))
     JOIN tm_proveedor tp ON ((tmo.cproveedor = tp.id)));


ALTER TABLE dbv_oc_status OWNER TO joec;

--
-- Name: dbv_req_oc; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_req_oc AS
 SELECT tm_req.cn_req,
    tm_req.cdate,
    tm_req.cstatus,
    t_status.cdescripcion,
    t_cargo.cdescripcion AS cdescripcionger
   FROM ((tm_req
     JOIN t_status ON ((tm_req.cstatus = t_status.id)))
     JOIN t_cargo ON (((tm_req.cgerencia)::integer = t_cargo.id)))
  WHERE (NOT (tm_req.cn_req IN ( SELECT tm_ordencompra.cn_req
           FROM tm_ordencompra)));


ALTER TABLE dbv_req_oc OWNER TO joec;

--
-- Name: dbv_req_oc2; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_req_oc2 AS
 SELECT tmr.cn_req,
    tmr.cdate,
    tmr.cstatus,
    tst.cdescripcion,
    tc.cdescripcion AS cdescripcionger
   FROM (((tm_req tmr
     JOIN td_req tdr ON ((tmr.cn_req = tdr.cn_req)))
     JOIN t_status tst ON ((tmr.cstatus = tst.id)))
     JOIN t_cargo tc ON (((tmr.cgerencia)::integer = tc.id)))
  WHERE (NOT (tdr.ccodprod IN ( SELECT td_ordencompra.ccodprod
           FROM td_ordencompra
          WHERE (td_ordencompra.cn_req = tmr.cn_req))))
  GROUP BY tmr.cn_req, tmr.cdate, tmr.cstatus, tst.cdescripcion, tc.cdescripcion;


ALTER TABLE dbv_req_oc2 OWNER TO joec;

--
-- Name: dbv_req_oc3; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_req_oc3 AS
 SELECT tmr.cn_req,
    tmr.cdate,
    tmr.cstatus,
    tst.cdescripcion,
    tc.cdescripcion AS cdescripcionger,
    tmr.ct_servicio
   FROM ((((tm_req tmr
     LEFT JOIN td_req tdr ON ((tmr.cn_req = tdr.cn_req)))
     LEFT JOIN td_req_serv tdrs ON ((tmr.cn_req = tdrs.cn_req)))
     JOIN t_status tst ON ((tmr.cstatus = tst.id)))
     JOIN t_cargo tc ON (((tmr.cgerencia)::integer = tc.id)))
  WHERE (NOT (tdr.ccodprod IN ( SELECT td_ordencompra.ccodprod
           FROM td_ordencompra
          WHERE (td_ordencompra.cn_req = tmr.cn_req))))
  GROUP BY tmr.cn_req, tmr.cdate, tmr.cstatus, tst.cdescripcion, tc.cdescripcion, tmr.ct_servicio
  ORDER BY tmr.cstatus, tmr.cn_req;


ALTER TABLE dbv_req_oc3 OWNER TO joec;

--
-- Name: dbv_req_status; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_req_status AS
 SELECT tm_req.cn_req,
    tm_req.cdate,
    tm_req.cstatus,
    t_status.cdescripcion,
    tm_req.ct_servicio,
    ( SELECT t_cargo.cdescripcion
           FROM t_cargo
          WHERE (t_cargo.id = (tm_req.cgerencia)::integer)) AS gerencia,
    tm_req.cuso
   FROM (tm_req
     JOIN t_status ON ((tm_req.cstatus = t_status.id)));


ALTER TABLE dbv_req_status OWNER TO joec;

--
-- Name: seq_md_menu; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_md_menu
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_md_menu OWNER TO joec;

--
-- Name: md_menu; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE md_menu (
    id integer DEFAULT nextval('seq_md_menu'::regclass) NOT NULL,
    cid_m integer DEFAULT 1 NOT NULL,
    cd_click character varying(150) DEFAULT 0,
    cd_class_i character varying(150) DEFAULT 0 NOT NULL,
    cd_title character varying(150) DEFAULT 0 NOT NULL
);


ALTER TABLE md_menu OWNER TO joec;

--
-- Name: seq_mm_menu; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_mm_menu
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_mm_menu OWNER TO joec;

--
-- Name: mm_menu; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE mm_menu (
    id integer DEFAULT nextval('seq_mm_menu'::regclass) NOT NULL,
    cm_head_c character varying(50),
    cm_head_p character varying(50),
    cm_head_i character varying(60),
    cm_title character varying(100),
    cm_t_sc character varying(100),
    cm_t_ic character varying(100),
    cm_op_c character varying(50),
    cm_op_id integer DEFAULT currval('seq_mm_menu'::regclass),
    cm_level smallint DEFAULT 0 NOT NULL,
    cm_sub smallint DEFAULT 0 NOT NULL
);


ALTER TABLE mm_menu OWNER TO joec;

--
-- Name: usr_menu; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE usr_menu (
    id integer DEFAULT 0 NOT NULL,
    cusr integer DEFAULT 0 NOT NULL,
    cid_m integer,
    cid_d integer
);


ALTER TABLE usr_menu OWNER TO joec;

--
-- Name: dbv_sideb_men_did; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_sideb_men_did AS
 SELECT usr.cusr,
    m.cm_op_id AS menid,
    (((((('<li><a onclick="'::text || (d.cd_click)::text) || '"><i class="'::text) || (d.cd_class_i)::text) || '"></i> '::text) || (d.cd_title)::text) || '</a></li>'::text) AS opc,
    m.cm_level
   FROM ((usr_menu usr
     JOIN md_menu d ON ((usr.cid_d = d.id)))
     JOIN mm_menu m ON ((m.id = d.cid_m)))
  ORDER BY d.id;


ALTER TABLE dbv_sideb_men_did OWNER TO joec;

--
-- Name: dbv_sideb_men_mid; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE dbv_sideb_men_mid (
    cusr integer,
    menid integer,
    cm_level smallint,
    cm_sub smallint,
    head text,
    fin unknown
);

ALTER TABLE ONLY dbv_sideb_men_mid REPLICA IDENTITY NOTHING;


ALTER TABLE dbv_sideb_men_mid OWNER TO joec;

--
-- Name: dbv_sideb_menum; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_sideb_menum AS
 SELECT m.id AS menid,
    ((((((((((((((((((((('<li class="'::text || (m.cm_head_c)::text) || '">'::text) || '<a href="'::text) || (m.cm_head_p)::text) || '">'::text) || '<i class="'::text) || (m.cm_head_i)::text) || '"></i>'::text) || '<span>'::text) || (m.cm_title)::text) || '</span>'::text) || '<span class="'::text) || (m.cm_t_sc)::text) || '">'::text) || '<i class="'::text) || (m.cm_t_ic)::text) || '"></i></span></a><ul class="'::text) || (m.cm_op_c)::text) || '" id="op_'::text) || m.id) || '">'::text) AS head,
    '</ul></li>' AS fin
   FROM mm_menu m;


ALTER TABLE dbv_sideb_menum OWNER TO joec;

--
-- Name: dbv_sideb_menuop; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_sideb_menuop AS
 SELECT m.id AS menid,
    (((((('<li><a onclick="'::text || (d.cd_click)::text) || '"><i class="'::text) || (d.cd_class_i)::text) || '"></i> '::text) || (d.cd_title)::text) || '</a></li>'::text) AS opc
   FROM (mm_menu m
     JOIN md_menu d ON ((m.id = d.cid_m)));


ALTER TABLE dbv_sideb_menuop OWNER TO joec;

--
-- Name: dbv_sidebar_menu; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_sidebar_menu AS
 SELECT m.id AS menid,
    ((((((((((((((((((('<li class="'::text || (m.cm_head_c)::text) || '">'::text) || '<a href="'::text) || (m.cm_head_p)::text) || '">'::text) || '<i class="'::text) || (m.cm_head_i)::text) || '"></i>'::text) || '<span>'::text) || (m.cm_title)::text) || '</span>'::text) || '<span class="'::text) || (m.cm_t_sc)::text) || '">'::text) || '<i class="'::text) || (m.cm_t_ic)::text) || '"></i></span></a><ul class="'::text) || (m.cm_op_c)::text) || '">'::text) AS head,
    (((((('<li><a onclick="'::text || (d.cd_click)::text) || '"><i class="'::text) || (d.cd_class_i)::text) || '"></i> '::text) || (d.cd_title)::text) || '</a></li>'::text) AS opc,
    '</ul></li>' AS fin
   FROM (mm_menu m
     JOIN md_menu d ON ((m.id = d.cid_m)));


ALTER TABLE dbv_sidebar_menu OWNER TO joec;

--
-- Name: usr_log; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE usr_log (
    cci integer DEFAULT 0 NOT NULL,
    cpass character varying(255) DEFAULT 0 NOT NULL,
    cd_upd date DEFAULT now() NOT NULL,
    cd_change date
);


ALTER TABLE usr_log OWNER TO joec;

--
-- Name: dbv_usr_login; Type: VIEW; Schema: public; Owner: joec
--

CREATE VIEW dbv_usr_login AS
 SELECT te.cci,
    (((te.capellido)::text || ', '::text) || (te.cnombre)::text) AS nombre,
    tc.cdescripcion AS gerencia,
    tgc.cdescripcion AS cargo,
    ul.cpass
   FROM (((usr_log ul
     JOIN t_empleados te ON ((ul.cci = te.cci)))
     JOIN t_cargo tc ON ((te.cgroup = tc.id)))
     JOIN t_group_cargo tgc ON ((te.ccargo = tgc.id)));


ALTER TABLE dbv_usr_login OWNER TO joec;

--
-- Name: seq_td_contropago; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_contropago
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_contropago OWNER TO joec;

--
-- Name: seq_td_entrada_inv; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_entrada_inv
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_entrada_inv OWNER TO joec;

--
-- Name: seq_td_salida_inv; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_salida_inv
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_salida_inv OWNER TO joec;

--
-- Name: seq_td_salidad; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_td_salidad
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_td_salidad OWNER TO joec;

--
-- Name: seq_tm_entrada_inv; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_entrada_inv
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_entrada_inv OWNER TO joec;

--
-- Name: seq_tm_hist_precios; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_hist_precios
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_hist_precios OWNER TO joec;

--
-- Name: seq_tm_salida_inv; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_salida_inv
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_salida_inv OWNER TO joec;

--
-- Name: seq_tm_salidam; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tm_salidam
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tm_salidam OWNER TO joec;

--
-- Name: seq_tmentradad; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tmentradad
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tmentradad OWNER TO joec;

--
-- Name: seq_tmentradam; Type: SEQUENCE; Schema: public; Owner: joec
--

CREATE SEQUENCE seq_tmentradam
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE seq_tmentradam OWNER TO joec;

--
-- Name: t_banco; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_banco (
    id smallint DEFAULT 0 NOT NULL,
    cdescripcion character varying(50) DEFAULT 0 NOT NULL
);


ALTER TABLE t_banco OWNER TO joec;

--
-- Name: t_conceptopago; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE t_conceptopago (
    id smallint DEFAULT 0 NOT NULL,
    cconcepto character varying(50) DEFAULT 0 NOT NULL
);


ALTER TABLE t_conceptopago OWNER TO joec;

--
-- Name: td_controlpago; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_controlpago (
    id integer DEFAULT nextval('seq_td_contropago'::regclass) NOT NULL,
    codcpm integer DEFAULT 0 NOT NULL,
    cfecha date,
    cmonto double precision DEFAULT 0 NOT NULL,
    cconcepto smallint DEFAULT 0 NOT NULL,
    ccod_ref character varying(100) DEFAULT 0 NOT NULL,
    cbanco_emi smallint DEFAULT 0 NOT NULL,
    cbanco_des smallint DEFAULT 0 NOT NULL
);


ALTER TABLE td_controlpago OWNER TO joec;

--
-- Name: td_entrada_inv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_entrada_inv (
    id integer DEFAULT nextval('seq_td_entrada_inv'::regclass) NOT NULL,
    cidm integer DEFAULT 0 NOT NULL,
    codprod integer DEFAULT 0 NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    ct_unidad character varying(50) DEFAULT 0 NOT NULL,
    cpunit double precision DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccodfact character varying(150) DEFAULT 0 NOT NULL
);


ALTER TABLE td_entrada_inv OWNER TO joec;

--
-- Name: td_entradad; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_entradad (
    id integer DEFAULT nextval('seq_tmentradad'::regclass) NOT NULL,
    ccodfact character varying(100) NOT NULL,
    ccodprod numeric(150,0) NOT NULL,
    cfecha date DEFAULT now() NOT NULL,
    cpeso double precision DEFAULT 0 NOT NULL,
    cunidad integer DEFAULT 0 NOT NULL
);


ALTER TABLE td_entradad OWNER TO joec;

--
-- Name: td_factura_serv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_factura_serv (
    id integer DEFAULT nextval('seq_td_factura'::regclass) NOT NULL,
    ccodfact character varying(150) NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    cdescripcion text DEFAULT ''::text NOT NULL,
    cpunit double precision DEFAULT 0 NOT NULL,
    cdesc double precision DEFAULT 0 NOT NULL,
    civa double precision DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    cstot double precision DEFAULT 0 NOT NULL,
    cstatus smallint DEFAULT 4 NOT NULL
);


ALTER TABLE td_factura_serv OWNER TO joec;

--
-- Name: td_salida_inv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_salida_inv (
    id integer DEFAULT nextval('seq_td_salida_inv'::regclass) NOT NULL,
    cidm integer DEFAULT 0 NOT NULL,
    codprod integer DEFAULT 0 NOT NULL,
    ccant double precision DEFAULT 0 NOT NULL,
    ct_unidad character varying(50) DEFAULT 0 NOT NULL,
    cpunit double precision DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccodfact character varying(150) DEFAULT 0 NOT NULL
);


ALTER TABLE td_salida_inv OWNER TO joec;

--
-- Name: td_salidad; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE td_salidad (
    id integer DEFAULT nextval('seq_td_salidad'::regclass) NOT NULL,
    ccodsalida integer NOT NULL,
    ccantidad integer,
    cunidad integer,
    cdescripcion character varying(255) NOT NULL
);


ALTER TABLE td_salidad OWNER TO joec;

--
-- Name: test_salida; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE test_salida (
    cant_ant double precision DEFAULT 0 NOT NULL,
    cant_new double precision,
    cant_tot double precision,
    codprod integer
);


ALTER TABLE test_salida OWNER TO joec;

--
-- Name: test_trigger; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE test_trigger (
    val1 integer,
    val2 character varying(25),
    val3 smallint DEFAULT 0
);


ALTER TABLE test_trigger OWNER TO joec;

--
-- Name: tm_entrada_inv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_entrada_inv (
    id integer DEFAULT nextval('seq_tm_entrada_inv'::regclass) NOT NULL,
    cconcepto character varying(50) DEFAULT 0 NOT NULL,
    ctipo_almacen smallint DEFAULT 0 NOT NULL,
    codprod integer DEFAULT 0 NOT NULL,
    cpreparado integer DEFAULT 0 NOT NULL,
    caprobado integer DEFAULT 0 NOT NULL,
    ca_cant smallint DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    cfecha date DEFAULT now() NOT NULL,
    calmacenp integer DEFAULT 0 NOT NULL,
    cncontrol integer DEFAULT 0 NOT NULL,
    cobservacion character varying(255) DEFAULT 0 NOT NULL,
    cncontrol_sal integer DEFAULT 0 NOT NULL,
    cid_fact integer DEFAULT 0 NOT NULL
);


ALTER TABLE tm_entrada_inv OWNER TO joec;

--
-- Name: tm_entradam; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_entradam (
    id integer DEFAULT nextval('seq_tmentradam'::regclass) NOT NULL,
    ccodfact character varying(150) NOT NULL,
    cfecha date NOT NULL,
    crecepcion integer NOT NULL
);


ALTER TABLE tm_entradam OWNER TO joec;

--
-- Name: tm_factura_dir; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_factura_dir (
    id integer DEFAULT nextval('seq_tm_factura_ent'::regclass) NOT NULL,
    cfecha date DEFAULT now() NOT NULL,
    cfechap date,
    cproveedor integer NOT NULL,
    ccodfact character varying(150),
    clote character varying(150) DEFAULT 0 NOT NULL,
    ccon_pago smallint,
    crecib integer NOT NULL,
    caprob integer NOT NULL,
    ct_cantp double precision,
    csubtot double precision NOT NULL,
    ctot double precision NOT NULL,
    cstatus smallint DEFAULT 1 NOT NULL
);


ALTER TABLE tm_factura_dir OWNER TO joec;

--
-- Name: tm_producto_fin; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_producto_fin (
    codprodt character varying(10) DEFAULT 0 NOT NULL,
    cdescripcion character varying(150) DEFAULT 0 NOT NULL,
    tunidad character varying(10) DEFAULT 0 NOT NULL,
    civa double precision DEFAULT 0 NOT NULL
);


ALTER TABLE tm_producto_fin OWNER TO joec;

--
-- Name: tm_salida_inv; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_salida_inv (
    id integer DEFAULT nextval('seq_tm_salida_inv'::regclass) NOT NULL,
    cconcepto character varying(50) DEFAULT 0 NOT NULL,
    ctipo_almacen smallint DEFAULT 0 NOT NULL,
    codprod integer DEFAULT 0 NOT NULL,
    cpreparado integer DEFAULT 0 NOT NULL,
    caprobado integer DEFAULT 0 NOT NULL,
    ca_cant smallint DEFAULT 0 NOT NULL,
    ctot double precision DEFAULT 0 NOT NULL,
    cfecha date DEFAULT now() NOT NULL,
    calmacenp integer DEFAULT 0 NOT NULL,
    cncontrol integer DEFAULT 0 NOT NULL,
    cobservacion character varying(255) DEFAULT 0 NOT NULL
);


ALTER TABLE tm_salida_inv OWNER TO joec;

--
-- Name: tm_salidam; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE tm_salidam (
    id integer DEFAULT nextval('seq_tm_salidam'::regclass) NOT NULL,
    ccodsalida integer NOT NULL,
    cfecha date NOT NULL,
    corigen character varying(100) NOT NULL,
    cdestino character varying(100) NOT NULL,
    cfecha_ret date NOT NULL,
    cconcepto smallint NOT NULL,
    ctot_cant integer NOT NULL,
    ctot_uni integer NOT NULL,
    cdp_emp integer DEFAULT 0,
    cdp_ci integer DEFAULT 0,
    cdp_nombre character varying(100) DEFAULT NULL::character varying NOT NULL,
    cdp_empresa character varying(255),
    cdp_tel_contac character varying(50) DEFAULT 0,
    cdp_prep character varying(150),
    cdp_aprob character varying(150) NOT NULL,
    cconcepto_desc character varying(255) DEFAULT NULL::character varying NOT NULL
);


ALTER TABLE tm_salidam OWNER TO joec;

--
-- Name: ttipo_producto; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE ttipo_producto (
    id integer NOT NULL,
    ctipoprod smallint NOT NULL,
    cdescripcion character varying(200) NOT NULL
);


ALTER TABLE ttipo_producto OWNER TO joec;

--
-- Name: ttipo_salida; Type: TABLE; Schema: public; Owner: joec; Tablespace: 
--

CREATE TABLE ttipo_salida (
    cconcepto smallint NOT NULL,
    cdescripcion character varying(255) NOT NULL
);


ALTER TABLE ttipo_salida OWNER TO joec;

--
-- Data for Name: md_menu; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY md_menu (id, cid_m, cd_click, cd_class_i, cd_title) FROM stdin;
1	1	Reg_Req()	fa fa-circle-o	Registrar
2	1	Con_Req()	fa fa-circle-o	Consultar
3	2	Reg_Ord_Comp()	fa fa-circle-o	Registrar
4	2	Con_Ord_Comp()	fa fa-circle-o	Consultar
5	3	Reg_Fact_Ent()	fa fa-circle-o	Registrar
6	3	Con_Fact_Ent()	fa fa-circle-o	Consultar
7	4	Con_Inv()	fa fa-circle-o	Consultar
8	4	reg_Inv_Sal()	fa fa-circle-o	Reg. Salida
9	4	reg_Inv_Ent()	fa fa-circle-o	Reg. Entrada
13	6	Reg_mstProd()	fa fa-circle-o	Registrar
14	6	MstProd()	fa fa-circle-o	Consultar
15	7	Reg_mstProv()	fa fa-circle-o	Registrar
16	7	Con_mstProv()	fa fa-circle-o	Consultar
17	8	Reg_Usr()	fa fa-circle-o	Registrar
18	8	Con_Usr()	fa fa-circle-o	Consultar
0	0	0	0	0
10	9	aprob_con_Req()	fa fa-circle-o	Requisicion
11	9	aprob_con_Oc()	fa fa-circle-o	Orden de Compra
12	9	aprob_con_Fact_en()	fa fa-circle-o	Factura de Compra
\.


--
-- Data for Name: mm_menu; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY mm_menu (id, cm_head_c, cm_head_p, cm_head_i, cm_title, cm_t_sc, cm_t_ic, cm_op_c, cm_op_id, cm_level, cm_sub) FROM stdin;
1	treeview	#	fa fa-share	Requisicion	pull-right-container	fa fa-angle-left pull-right	treeview-menu	1	0	0
2	treeview	#	fa fa-share	Ord. De Compra	pull-right-container	fa fa-angle-left pull-right	treeview-menu	2	0	0
3	treeview	#	fa fa-share	Factura Compra	pull-right-container	fa fa-angle-left pull-right	treeview-menu	3	0	0
4	treeview	#	fa fa-share	Inventario	pull-right-container	fa fa-angle-left pull-right	treeview-menu	4	0	0
0	\N	\N	\N	\N	\N	\N	\N	0	0	0
5	treeview	#	fa fa-share	Registros	pull-right-container	fa fa-angle-left pull-right	treeview-menu	5	0	0
6	treeview	#	fa fa-share	Productos	pull-right-container	fa fa-angle-left pull-right	treeview-menu	6	1	5
7	treeview	#	fa fa-share	Proveedor	pull-right-container	fa fa-angle-left pull-right	treeview-menu	7	1	5
8	treeview	#	fa fa-share	Usuarios	pull-right-container	fa fa-angle-left pull-right	treeview-menu	8	1	5
9	treeview	#	fa fa-share	Aprobacion	pull-right-container	fa fa-angle-left pull-right	treeview-menu	9	0	0
\.


--
-- Name: seq_md_menu; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_md_menu', 18, true);


--
-- Name: seq_mm_menu; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_mm_menu', 8, true);


--
-- Name: seq_t_cargo; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_t_cargo', 4, true);


--
-- Name: seq_td_contropago; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_contropago', 1, false);


--
-- Name: seq_td_entrada_inv; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_entrada_inv', 23, true);


--
-- Name: seq_td_factura; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_factura', 531, true);


--
-- Name: seq_td_ordencompra; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_ordencompra', 203, true);


--
-- Name: seq_td_req; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_req', 211, true);


--
-- Name: seq_td_salida_inv; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_salida_inv', 2738, true);


--
-- Name: seq_td_salidad; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_td_salidad', 1, false);


--
-- Name: seq_tm_contropago; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_contropago', 269, true);


--
-- Name: seq_tm_entrada_inv; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_entrada_inv', 13, true);


--
-- Name: seq_tm_factura_ent; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_factura_ent', 278, true);


--
-- Name: seq_tm_hist_precios; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_hist_precios', 1, false);


--
-- Name: seq_tm_inventario; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_inventario', 918, true);


--
-- Name: seq_tm_invstock; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_invstock', 127, true);


--
-- Name: seq_tm_ordencompra; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_ordencompra', 105, true);


--
-- Name: seq_tm_proveedor; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_proveedor', 101, true);


--
-- Name: seq_tm_req; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_req', 68, true);


--
-- Name: seq_tm_salida_inv; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_salida_inv', 342, true);


--
-- Name: seq_tm_salidam; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tm_salidam', 1, false);


--
-- Name: seq_tmentradad; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tmentradad', 1, true);


--
-- Name: seq_tmentradam; Type: SEQUENCE SET; Schema: public; Owner: joec
--

SELECT pg_catalog.setval('seq_tmentradam', 1, false);


--
-- Data for Name: t_banco; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_banco (id, cdescripcion) FROM stdin;
0	
1	BANCO DE VENEZUELA
2	BANESCO
3	BANCO OCCIDENTAL DE DESCUENTO BOD
4	BBVA PROVINCIAL
5	BANCO NACIONAL DE CRÉDITO
6	MERCANTIL
7	BANCO EXTERIOR
8	VENEZOLANO DE CRÉDITO
9	BANCARIBE
10	BANCO DEL TESORO
11	BANCO FONDO COMÚN
12	BANPLUS
13	BANCO CARONÍ
14	BANCRECER
15	BANCO PLAZA
16	BANFANB
17	BICENTENARIO BANCO UNIVERSAL
18	BANCO ACTIVO
19	DEL SUR
20	100% BANCO
21	BANCO AGRÍCOLA DE VENEZUELA
22	MI BANCO
23	BANCO SOFITASA
24	BANCAMIGA
25	CITIBANK
26	BANCOEX
27	BANGENTE
28	BANCO DE EXPORTACIÓN Y COMERCIO
29	NOVO BANCO
30	BANCO INTERNACIONAL DE DESARROLLO
\.


--
-- Data for Name: t_cargo; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_cargo (id, cdescripcion, caprob) FROM stdin;
6	ALMACEN	f
1	VENTAS	t
2	LOGISTICA	t
3	AMINISTRACION	t
4	PRODUCCION	t
5	SEGURIDAD	t
7	COMPRA	f
8	MANTENIMIENTO MECANICO	t
9	SISTEMAS	t
\.


--
-- Data for Name: t_conceptopago; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_conceptopago (id, cconcepto) FROM stdin;
1	Total
2	Abono
\.


--
-- Data for Name: t_empleados; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_empleados (cci, cnombre, capellido, cgroup, ctelefono, cemail, cfirma, ccargo) FROM stdin;
3	FREDDY	MARCHENA	3	0	email@email.com	t	1
4	JOSE	MARCHENA	4	0	email@email.com	t	1
5	FRANKLIN	TENIA	5	0	email@email.com	f	1
0	NOMBRE	APELLIDO	0	4243687585	email@email.com	f	0
14183912	JESUS E.	PINO S.	1	0	email@email.com	t	1
14183910	JESUS O.	PINO S.	2	0	email@email.com	t	1
19132888	JOSE R.	ECHANDI S.	9	0	email@email.com	t	1
6	REIVY	GARCIA	8	0	email@email.com	f	1
20384856	MARIA A.	ZABALA G.	7	0	email@email.com	f	20
\.


--
-- Data for Name: t_group_cargo; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_group_cargo (id, cdescripcion, caprob, cgroup) FROM stdin;
6	ASISTENTE ADM. II	f	3
5	ASISTENTE ADM. I	f	3
4	ASISTENTE CON. II	f	3
3	ASISTENTE CON. I	f	3
2	CONTADOR	f	3
1	GERENTE	t	3
7	CAJERA	f	1
8	JEFE DESCPACHO	f	1
9	MECANICO	f	2
10	SUPERVISOR	f	2
11	MANTENIMIENTO	f	2
12	DEP. COMPRAS	f	2
13	MECANICOS	f	4
14	SUPERVISOR PRODUCCION	f	4
15	SUPERVISOR ALMACEN	f	4
16	VIGILANTE	f	5
17	SERV. MEDICO	f	5
18	DEPT. SEGURIDAD Y SALUD LABORAL	f	5
19	ASISTENTE	f	7
20	JEFE	f	3
\.


--
-- Data for Name: t_pago; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_pago (id, cdescripcion) FROM stdin;
1	Contado
2	Credito
3	Efectivo
4	Deposito
5	Cheque
6	Pre-Pagado
\.


--
-- Data for Name: t_status; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY t_status (id, cdescripcion) FROM stdin;
1	Solicitado
2	Revision
3	Modificado
4	Aprobado
5	Anulado
6	Pendiente
7	Abonado
8	Cancelado
9	Devolucion
10	Procesado
\.


--
-- Data for Name: td_controlpago; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_controlpago (id, codcpm, cfecha, cmonto, cconcepto, ccod_ref, cbanco_emi, cbanco_des) FROM stdin;
\.


--
-- Data for Name: td_entrada_inv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_entrada_inv (id, cidm, codprod, ccant, ct_unidad, cpunit, ctot, clote, ccodfact) FROM stdin;
14	10	200004	500	Kg	10000	5000000	0-0	0-0
15	10	200005	3000	Kg	4600	13800000	0-0	0-0
16	10	200008	500	Kg	14900	7450000	0-0	0-0
17	10	200035	500	Kg	9687.5	4843750	0-0	0-0
18	11	100002	431.5	Kg	5000	2157500	0-0	0-0
19	11	100029	3310	Kg	6200	20522000	0-0	0-0
20	11	100030	733.5	Kg	6000	4401000	0-0	0-0
21	11	100032	51	Kg	6000	306000	0-0	0-0
22	12	100002	773.5	Kg	5000	3867500	0-0	0-0
23	13	100002	221.5	Kg	5500	1218250	10-165	10-165
\.


--
-- Data for Name: td_entradad; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_entradad (id, ccodfact, ccodprod, cfecha, cpeso, cunidad) FROM stdin;
\.


--
-- Data for Name: td_factura; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_factura (id, ccodfact, clote, ccodprod, ccant, cpunit, cdesc, civa, ctot, cstot, cstatus) FROM stdin;
128	7-3455	2-3455	200007	750	2800	0	0	2100000	2100000	4
129	8-15102	3-15102	200057	5	565230	0	0	2826150	2826150	4
130	8-15102	3-15102	200034	20	78298	0	0	1565960	1565960	4
131	10-165	10-165	100002	4403	5500	0	0	24216500	24216500	4
132	11-279	11-279	100004	287.5	3650	0	0	1049375	1049375	4
133	12-930	12-930	100015	7600	2500	0	0	19000000	19000000	4
134	9-488	9-488	100021	200	30000	0	0	6000000	6000000	4
135	16-109555	4-109555	300011	4	4388	0	12	15445.7600000000002	17552	4
136	16-109555	4-109555	300012	4	6599	0	12	23228.4799999999996	26396	4
137	17-304	5-304	200092	10000	1480	0	12	14800000	16576000	4
176	24-28449	24-28449	300060	4	45278.8099999999977	0	12	181115.239999999991	202849.070000000007	4
138	14-38	14-38	300013	5	31846.5600000000013	0	12	178340.739999999991	159232.799999999988	4
140	14-38	14-38	300015	5	48160	0	12	269696	240800	4
139	14-38	14-38	300014	2	7939.26000000000022	0	12	17783.9399999999987	15878.5200000000004	4
141	14-38	14-38	300016	2	37980	0	12	85075.1999999999971	75960	4
142	18-10598	18-10598	300017	5	6000	0	12	33600	30000	4
172	38-19198	38-19198	300058	20	17100	0	12	383040	342000	4
148	23-138	23-138	100030	1020	7000	0	0	7140000	7140000	4
149	19-37671	19-37671	300020	2	13071.4200000000001	0	12	29279.9799999999996	26142.8400000000001	4
150	19-37671	19-37671	300024	1	9566.32999999999993	0	12	11999.9899999999998	10714.2800000000007	4
151	21-10446	21-10446	300018	1	35000	0	12	39200	35000	4
152	20-12134	20-12134	300019	1	98214.2899999999936	0	12	110000	98214.2899999999936	4
155	24-28232	24-28232	300030	10	14285.7099999999991	0	12	159999.950000000012	142857.100000000006	4
154	24-28232	24-28232	300029	10	8928.56999999999971	0	12	99999.9900000000052	89285.6999999999971	4
156	31-3025	31-3025	200047	3000	5100	0	0	15300000	15300000	4
157	31-3025	31-3025	200061	15	8500	0	0	127500	127500	4
158	28-21409	28-21409	301004	54000	89.0900000000000034	0	12	5388163.20000000019	4810860	4
159	28-21409	28-21409	301007	16400	282.389999999999986	0	12	5183969.51999999955	4631196	4
147	24-28187	24-28187	300023	5	208585.739999999991	0	12	1168080.1399999999	1042928.69999999995	4
146	24-28191	24-28191	300022	2	148500	0	12	332640	297000	4
145	24-28191	24-28191	300021	2	64500	0	12	144480	129000	4
153	26-598	26-598	100003	4896	3600	0	0	17625600	17625600	4
160	12-931	12-931	100015	3048	2500	0	0	7620000	7620000	4
161	12-931	12-931	100006	708	3600	0	0	2548800	2548800	4
162	10-168	10-168	100002	4998.5	5500	0	0	27491750	27491750	4
163	34-468	34-468	200065	300	23900	0	12	7170000	8030400	4
164	34-470	34-470	200065	200	23900	0	12	4780000	5353600	4
165	35-13667	35-13667	300051	2	1741.06999999999994	0	12	3482.13999999999987	3899.99679999999989	4
166	35-13667	35-13667	300053	4	1428.56999999999994	0	12	5714.27999999999975	6399.99359999999979	4
167	35-13667	35-13667	300052	2	1741.06999999999994	0	12	3482.13999999999987	3899.99679999999989	4
168	16-109601	16-109601	300054	3	10199	0	12	30597	34268.6399999999994	4
169	16-109601	16-109601	300055	3	38303.4300000000003	0	12	114910.289999999994	128699.524799999985	4
170	16-109601	16-109601	300056	3	11652.1200000000008	0	12	34956.3600000000006	39151.1232000000018	4
171	37-234514	37-234514	300057	10	1696.43000000000006	0	12	16964.2999999999993	19000.0159999999996	4
174	39-691	39-691	200004	1000	7900	0	12	7900000	8848000	4
175	40-2439	40-2439	100004	1011	3300	0	0	3336300	3336300	4
178	32-3934	32-3934	200094	1500	4550	0	0	6825000	6825000	4
179	32-3934	32-3934	200005	1500	7980	0	12	11970000	13406400	4
181	19-37835	19-37835	300063	2	36642.8499999999985	0	12	73285.6999999999971	82079.9839999999967	4
182	19-37835	19-37835	300064	1	13392.8600000000006	0	12	13392.8600000000006	15000.003200000001	4
183	19-37835	19-37835	300066	1	75000	0	12	75000	84000	4
184	19-37835	19-37835	300065	1	11785.7199999999993	0	12	11785.7199999999993	13200.0063999999984	4
185	19-37835	19-37835	300071	2	1470.84999999999991	0	12	2941.69999999999982	3294.70399999999972	4
186	19-37835	19-37835	300067	2	20892.8499999999985	0	12	41785.6999999999971	46799.9839999999967	4
187	19-37835	19-37835	300070	1	37714.3000000000029	0	12	37714.3000000000029	42240.0160000000033	4
188	19-37835	19-37835	300068	1	7920	0	12	7920	8870.39999999999964	4
177	44-1585	44-1585	300061	1	500000	0	12	560000	500000	4
180	46-627	46-627	300062	7	5500	0	12	43120	38500	4
173	38-19176	38-19176	300059	7	617850.060000000056	0	12	4843944.46999999974	4324950.41999999993	4
189	19-37835	19-37835	300069	2	21428.5699999999997	0	12	42857.1399999999994	47999.9968000000008	4
190	34-473	34-473	200065	500	23900	0	12	11950000	13384000	4
191	47-127	47-127	300072	2000	245	0	12	490000	548800	4
192	47-127	47-127	300073	2	20500	0	12	41000	45920	4
194	49-4243	49-4243	200004	500	11200	0	12	5600000	6272000	4
195	24-28505	24-28505	300074	2	87500	0	12	175000	196000	4
196	24-28505	24-28505	300075	1	15178.5699999999997	0	12	15178.5699999999997	16999.9984000000004	4
197	24-28505	24-28505	300076	1	15178.5699999999997	0	12	15178.5699999999997	16999.9984000000004	4
198	17-277	11-277	200098	87000	435	0	12	37845000	42386400	4
200	34-479	34-479	200065	20	23900	0	12	478000	535360	4
201	53-17246	53-17246	200009	17	64801.0590000000011	0	12	1101618	1233812.15999999992	4
202	53-17245	53-17245	200011	56	45967.5	0	12	2574180	2883081.60000000009	4
203	14-42	17-42	300077	1	696428.569999999949	0	12	696428.569999999949	780000	4
204	14-42	17-42	300079	6	9598.20999999999913	0	12	57589.260000000002	64499.9700000000012	4
205	14-42	17-42	300078	12	4901.71000000000004	0	12	58820.5199999999968	65878.9799999999959	4
206	25-2168	7-2168	300026	17	358200	0	12	6089400	6820128	4
207	25-2168	7-2168	300027	17	34150	0	12	580550	650216	4
208	25-2168	7-2168	300028	17	18700	0	12	317900	356048	4
210	11-283	11-283	100006	1064	7800	0	0	8299200	8299200	4
212	40-1230	40-1230	100004	1795.5	2900	0	0	5206950	5206950	4
213	11-283100	11-283100	100004	548	2900	0	0	1589200	1589200	4
214	45-1231	45-1231	100004	2241.5	2900	0	0	6500350	6500350	4
215	11-1232	11-1232	100016	351.5	4000	0	0	1406000	1406000	4
216	51-1233	51-1233	100006	1585.5	7200	0	0	11415600	11415600	4
217	11-1234	11-1234	100016	817.5	4000	0	0	3270000	3270000	4
218	11-1235	11-1235	100004	3298	3950	0	0	13027100	13027100	4
257	31-2017220	31-2017220	200064	900	9300	0	12	8370000	9374400	4
258	85-58	85-58	200099	86900	400	0	12	38931200	34760000	4
259	70-37360	70-37360	100002	1971.29999999999995	6900	0	0	13601970	13601970	4
209	49-4312	49-4312	200004	1000	11200	0	12	12544000	11200000	4
219	34-481	34-481	200065	500	24400	0	12	12200000	13664000	4
220	40-2017	40-2017	100004	295.5	3600	0	0	1063800	1063800	4
221	11-2017	11-2017	100006	544.5	7800	0	0	4247100	4247100	4
222	46-0634	46-0634	300062	30	5500	0	12	165000	184800	4
223	46-0634	46-0634	300083	32	5450	0	12	174400	195328	4
224	46-0634	46-0634	300084	2	29000	0	12	58000	64960	4
225	18-10628	9-10628	300032	5	1230	0	12	6150	6888	4
226	18-10628	9-10628	300033	5	720	0	12	3600	4032	4
227	18-10628	9-10628	300034	5	720	0	12	3600	4032	4
228	57-27	57-27	100037	1706	6750	0	8	11515500	12436740	4
229	61-1691	61-1691	300098	6	19800	0	12	118800	133056	4
230	61-1691	61-1691	300099	1	75000	0	12	75000	84000	4
231	34-485	34-485	200065	500	30000	0	12	15000000	16800000	4
232	11-2306004	11-2306004	100004	1923.5	3950	0	0	7597825	7597825	4
233	11-2306016	11-2306016	100016	1087.5	4000	0	0	4350000	4350000	4
234	62-27376	62-27376	3000100	2	490000	0	12	980000	1097600	4
235	63-1669	63-1669	3000101	1	1450000	0	12	1450000	1624000	4
236	59-347041	25-347041	300089	1	71735	0	12	71735	80343.1999999999971	4
237	59-347041	25-347041	300090	1	74562	0	12	74562	83509.4400000000023	4
239	52-2757	18-2757	300080	10	12960	0	12	129600	145152	4
240	52-2757	18-2757	300081	10	7350	0	12	73500	82320	4
241	47-128	47-128	300073	4	35000	0	12	140000	156800	4
242	67-5814	67-5814	3000120	2	88000	0	12	176000	197120	4
243	67-5814	67-5814	3000121	3	88000	0	12	264000	295680	4
244	67-5814	67-5814	3000122	3	8000	0	12	24000	26880	4
245	67-5814	67-5814	3000123	3	43000	0	12	129000	144480	4
246	50-6958	16-6958	200095	240	1980	0	12	475200	532224	4
247	68-995	68-995	100021	30	40000	0	12	1200000	1344000	4
248	49-4393	49-4393	200004	500	11700	0	12	5850000	6552000	4
249	34-488	34-488	200065	300	34000	0	12	10200000	11424000	4
260	71-1907	71-1907	100016	950	5500	0	0	5225000	5225000	4
238	59-347041	25-347041	300094	20	2340.0300000000002	0	12	46800.5999999999985	52416.6699999999983	4
250	32-4582	24-004582	200094	3000	5000	0	0	15000000	15000000	4
251	8-11021	23-0011021	200058	5	701315	0	12	3927364	3506575	4
252	65-23554	32-0023554	3000111	8	64102	0	12	57435392	512816	4
253	65-23554	32-0023554	3000112	1	50700	0	12	56784	50700	4
254	65-23554	32-0023554	3000113	1	4800	0	12	5376	4800	4
255	65-23554	32-0023554	3000115	5	136610	0	12	765016	683050	4
256	65-23554	32-0023554	3000110	1	102762	0	12	11509344	102762	4
261	71-1907	71-1907	100034	2146	6000	0	0	12876000	12876000	4
262	71-1907	71-1907	100001	526	6800	0	0	3576800	3576800	4
265	31-3035	31-3035	200064	5010	9300	0	0	46593000	46593000	4
263	77-1335	77-1335	100036	503.5	3800	0	0	1913300	1913300	4
264	77-1335	77-1335	100003	2503	5500	0	0	13766500	13766500	4
266	24-28792	24-28792	300021	4	68335	0	12	273340	3061408	4
267	24-28792	24-28792	3000102	4	15960	0	12	63840	715008	4
268	24-28790	24-28790	3000124	1	743600	0	12	743600	832832	4
199	33-23992	12-23992	200085	70400	360	0	12	25344000	28385280	4
269	72-2811	72-2811	100022	3942.59999999999991	5600	0	0	22078560	22078560	4
270	73-947	73-947	3000125	2	100000	0	12	200000	224000	4
271	73-947	73-947	3000126	4	120000	0	12	480000	537600	4
272	73-947	73-947	3000127	1	120000	0	12	120000	134400	4
273	24-287993	24-287993	3000128	1	31250	0	12	31250	35000	4
278	75-991	75-991	100002	2172.19999999999982	6700	0	0	14553740	14553740	4
279	76-43	76-43	100016	700.5	5500	0	0	3852750	3852750	4
282	78-780607	78-780607	100002	3017.5	6200	0	0	18708500	18708500	4
283	79-790607	79-790607	100002	1506.5	6900	0	0	10394850	10394850	4
284	11-294	11-294	100016	1601	5500	0	0	8805500	8805500	4
285	14-44	36-44	300086	36	14142.8500000000004	0	12	5702397119999999	5091426	4
286	14-44	36-44	300093	3	4400	0	12	14784	13200	4
287	14-44	36-44	300091	3	18590	0	12	624624	55770	4
288	14-45	14-45	3000135	1	31428.5699999999997	0	12	3142857	351999984	4
289	14-45	14-45	3000136	3	2970	0	12	8910	99792	4
290	14-45	14-45	3000137	6	3980	0	12	23880	267456	4
291	14-45	14-45	3000138	1	2380	0	12	2380	26656	4
292	14-45	14-45	300078	1	7650	0	12	7650	8568	4
293	14-45	14-45	3000139	2	2180	0	12	4360	48832	4
294	14-45	14-45	3000140	2	8592	0	12	17184	1924608	4
295	66-39005	31-39005	3000116	2	1906000	0	12	4269440	3812000	4
296	66-39005	31-39005	3000117	4	51000	0	12	228480	204000	4
297	66-39005	31-39005	3000118	2	57000	0	12	127680	114000	4
298	66-39005	31-39005	3000119	2	8500	0	12	19040	17000	4
299	64-7969	33-7969	3000105	1	376094.010000000009	0	12	4212252912	37609401	4
300	64-7969	33-7969	3000109	2	1995386.62000000011	0	12	44696660288	399077324	4
301	64-7969	33-7969	3000106	2	1922257.21999999997	0	12	43058561728	384451444	4
302	64-7969	33-7969	3000107	2	1473034	0	12	329959616	2946068	4
303	64-7969	33-7969	3000108	12	121882.320000000007	0	12	16380983808000002	146258784	4
304	63-1671	63-1671	3000141	1	1650000	0	12	1650000	1848000	4
305	38-19318	38-19318	3000142	68	52008.9199999999983	0	12	353660656	39609993472	4
306	7-3423	7-3423	200007	10	140000	0	12	1400000	1568000	4
307	39-780	37-780	200004	500	11750	0	12	6580000	5875000	4
308	59-347540	40-347540	3000133	3	3574.98999999999978	0	12	120119664	1072497	4
309	59-347540	40-347540	3000134	3	2925	0	12	9828	8775	4
311	81-212	81-212	100030	17.5	8300	0	0	145250	145250	4
312	81-212	81-212	100038	17.5	6300	0	0	110250	110250	4
313	60-4458	60-4458	3000148	1	19990	0	12	19990	223888	4
314	60-4458	60-4458	3000149	1	115000	0	12	115000	128800	4
315	82-14398	82-14398	3000150	1	68000	0	12	68000	76160	4
316	18-10696	18-10696	3000151	90	350	0	12	31500	35280	4
317	18-10696	18-10696	3000152	6	6000	0	12	36000	40320	4
318	18-11703	18-11703	3000153	3	24400	0	12	73200	81984	4
319	18-11702	18-11702	3000154	10	24800	0	12	248000	277760	4
320	18-11702	18-11702	3000156	6	4000	0	12	24000	26880	4
321	18-11702	18-11702	3000155	2	33000	0	12	66000	73920	4
322	19-38296	19-38296	300063	1	45803.5599999999977	0	12	4580356	51299987200000000	4
323	19-38296	19-38296	3000157	2	2892.86000000000013	0	12	578572	64800064	4
324	32-4604	35-4604	200008	500	18500	0	12	10360000	9250000	4
325	16-110798	16-110798	3000158	100	18545	0	12	1854500	2077040	4
327	59-347725	44-347725	3000144	12	255668	0	12	343617792	3068016	4
328	59-347725	44-347725	3000145	12	113752	0	12	152882688	1365024	4
329	59-347725	44-347725	3000146	12	2613	0	12	3511872	31356	4
330	59-347725	44-347725	3000147	12	10504	0	12	14117376	126048	4
341	24-28944	24-28944	3000172	1	354100	0	12	354100	396592	4
342	84-754	84-754	3000173	6	1410.71000000000004	0	12	846426	94799712	4
281	77-1337	77-1337	100003	2524.5	6000	0	0	15147000	15147000	4
280	77-1337	77-1337	100036	2067.5	3800	0	0	7856500	7856500	4
331	7-3433	42-3433	2000102	3000	7940	0	0	23820000	23820000	4
332	19-38332	19-38332	3000168	1	2544.63999999999987	0	12	254464	28499968	4
333	19-38332	19-38332	300046	4	2232.13999999999987	0	12	892856	99999872	4
335	19-38332	19-38332	3000170	3	10937.5	0	12	328125	36750	4
336	19-38332	19-38332	300066	1	48214.2900000000009	0	12	4821429	540000048	4
337	19-38332	19-38332	3000171	1	2345.13000000000011	0	12	234513	26265456	4
346	53-17276	30-17276	200010	32	71662.5	0	12	2568384	2293200	4
347	79-790713	79-790713	100002	3003	6900	0	0	20720700	20720700	4
344	77-2343	77-2343	100036	924.5	4000	0	0	3698000	3698000	4
345	77-2343	77-2343	100039	2854	9000	0	0	25686000	25686000	4
310	80-476609	80-476609	100002	2885.5	6900	0	0	19909950	19909950	4
343	11-0298	11-0298	100006	1424	10200	0	0	14524800	14524800	4
326	59-347725	44-347725	3000246	24	15574	0	12	41862912	373776	4
334	19-38332	19-38332	3000247	3	5303.57999999999993	0	12	1591074	178200288	4
349	18-10711	18-10711	300048	50	4480	0	12	224000	250880	4
350	69-1423	45-1423	200080	10500	2182	0	12	25660320	22911000	4
351	11-111307	11-111307	100006	668.5	10200	0	0	6818700	6818700	4
352	18-10699	18-10699	3000131	6	72800	0	12	436800	489216	4
353	18-10699	18-10699	3000132	2	115200	0	12	230400	258048	4
354	18-10700	18-10700	3000177	2	45000	0	12	90000	100800	4
355	18-10700	18-10700	3000178	5	6000	0	12	30000	33600	4
356	60-4471	60-4471	3000179	5	59590	0	12	297950	333704	4
357	60-4471	60-4471	3000180	1	105950	0	12	105950	118664	4
359	60-4450	60-4450	3000181	3	43500	0	12	130500	146160	4
360	18-11711	50-11711	300048	50	4480	0	12	250880	224000	4
361	18-11699	39-11699	3000131	6	72800	0	12	489216	436800	4
362	18-11699	39-11699	3000132	2	115200	0	12	258048	230400	4
364	18-11700	38-11700	3000129	2	45000	0	12	100800	90000	4
365	48-459	48-459	100030	518	7500	0	0	3885000	3885000	4
366	24-28987	41-28987	3000143	1	2175400.45000000019	0	12	2436448504	217540045	4
367	50-8229	49-8229	200068	1000	615	0	12	688800	615000	4
368	50-8230	46-8230	200095	960	1780	0	12	1913856	1708800	4
369	83-40	83-40	3000187	3	200000	0	12	600000	672000	4
370	83-40	83-40	3000188	3	35000	0	12	105000	117600	4
371	83-40	83-40	3000189	1	90000	0	12	90000	100800	4
372	83-40	83-40	3000190	4	5000	0	12	20000	22400	4
373	19-38393	19-38393	3000182	4	1031.49000000000001	0	12	412596	46210752	4
374	19-38393	19-38393	3000183	4	982.139999999999986	0	12	392856	43999872	4
375	19-38383	19-38383	3000191	1	4821.43000000000029	0	12	482143	54000016000000008	4
376	19-38383	19-38383	3000192	1	2544.63999999999987	0	12	254464	28499968	4
377	14-53	14-53	3000193	16	37000	0	12	592000	663040	4
452	14-56	94-56	3000237	3	37500	0	12	126000	112500	4
348	10-172	10-172	100002	2839	6400	0	0	18169600	18169600	4
453	24-29107	24-29107	3000241	2	64633.9300000000003	0	12	12926786	1447800032	4
378	11-298	11-298	100016	1094.5	5500	0	0	6019750	6019750	4
379	32-4626	89-4626	200005	3000	5500	0	0	16500000	16500000	4
380	49-4655	87-4655	200004	500	14200	0	12	7952000	7100000	4
381	49-4654	49-4654	200004	500	14200	0	12	7100000	7952000	4
382	58-47	58-47	3000214	1	350000	0	12	350000	392000	4
383	58-47	58-47	3000215	3	95000	0	12	285000	319200	4
384	58-47	58-47	3000216	2	90000	0	12	180000	201600	4
385	58-47	58-47	3000217	1	125000	0	12	125000	140000	4
386	58-47	58-47	3000218	4	22500	0	12	90000	100800	4
387	58-47	58-47	3000219	1	60000	0	12	60000	67200	4
388	58-47	58-47	3000220	2	12000	0	12	24000	26880	4
389	58-47	58-47	3000221	1	345000	0	12	345000	386400	4
390	90-359	90-359	3000174	10562	20	0	12	211240	2365888	4
391	90-359	90-359	3000222	1	190000	0	12	190000	212800	4
392	91-2417	91-2417	3000223	12	80000	0	12	960000	1075200	4
393	91-2417	91-2417	3000224	1	34500	0	12	34500	38640	4
394	91-2417	91-2417	3000225	1	2500000	0	12	2500000	2800000	4
395	91-2417	91-2417	3000226	11	23000	0	12	253000	283360	4
396	91-2417	91-2417	3000227	1	1500000	0	12	1500000	1680000	4
397	79-13	79-13	3000230	5	80500	0	12	402500	450800	4
398	79-14	79-14	100002	1484	6900	0	0	10239600	10239600	4
399	18-10719	18-10719	3000228	2	45280	0	12	90560	1014272	4
400	18-10719	18-10719	3000229	2	96000	0	12	192000	215040	4
401	18-10719	18-10719	300050	2	88000	0	12	176000	197120	4
402	18-11721	18-11721	3000231	1	26900	0	12	26900	30128	4
403	18-11721	18-11721	3000233	1	18700	0	12	18700	20944	4
404	18-11721	18-11721	3000232	1	19000	0	12	19000	21280	4
405	18-117709	18-117709	3000234	1	272000	0	12	272000	304640	4
406	93-1626	93-1626	3000235	2	280000	0	12	560000	627200	4
411	76-86	76-86	100030	139.5	10000	0	0	1395000	1395000	4
412	48-483	48-483	100041	500	10000	0	0	5000000	5000000	4
413	48-483	48-483	100030	619	9500	0	0	5880500	5880500	4
414	48-483	48-483	100040	202	9500	0	0	1919000	1919000	4
415	92-1707	92-1707	100002	1751.5	6900	0	0	12085350	12085350	4
416	77-771907	77-771907	100015	2152.5	3000	0	0	6457500	6457500	4
417	11-111907	11-111907	100006	400	10200	0	0	4080000	4080000	4
418	77-772007	77-772007	100003	3031.5	6500	0	0	19704750	19704750	4
454	24-29107	24-29107	3000242	1	130558.399999999994	0	12	1305584	146225408	4
455	64-7998	51-7998	3000160	2	340200	0	12	762048	680400	4
456	64-7998	51-7998	3000161	2	235620	0	12	5277888	471240	4
457	64-7998	51-7998	3000162	5	71868.6000000000058	0	12	40246416	359343	4
458	64-7998	51-7998	3000163	100	1406.70000000000005	0	12	1575504	140670	4
459	76-89	76-89	100030	1972	10000	0	0	19720000	19720000	4
460	11-112107	11-112107	100006	279	10200	0	0	2845800	2845800	4
461	89-2073	90-2073	3000195	1	750000	0	12	840000	750000	4
462	89-2073	90-2073	3000196	1	750000	0	12	840000	750000	4
463	89-2073	90-2073	3000197	1	250000	0	12	280000	250000	4
464	89-2073	90-2073	3000198	8	175000	0	12	1568000	1400000	4
465	89-2073	90-2073	3000199	60	11025	0	12	740880	661500	4
466	89-2073	90-2073	3000200	16	175000	0	12	3136000	2800000	4
467	89-2073	90-2073	3000201	1	60000	0	12	67200	60000	4
468	89-2073	90-2073	3000202	10	20000	0	12	224000	200000	4
469	89-2075	92-2075	3000212	1	136500	0	12	152880	136500	4
470	89-2075	92-2075	3000213	1	200000	0	12	224000	200000	4
471	89-2074	91-2074	3000203	1	19435000	0	12	21767200	19435000	4
472	89-2074	91-2074	3000204	1	90000	0	12	100800	90000	4
473	89-2074	91-2074	3000205	1	570000	0	12	638400	570000	4
474	89-2074	91-2074	3000206	1	69000	0	12	77280	69000	4
475	89-2074	91-2074	3000208	1	850000	0	12	952000	850000	4
476	89-2074	91-2074	3000209	1	120000	0	12	134400	120000	4
477	89-2074	91-2074	3000210	1	1123309.39999999991	0	12	1258106528	11233094	4
478	89-2074	91-2074	3000211	1	1689360	0	12	18920832	1689360	4
479	47-130	47-130	300072	2000	275	0	12	550000	616000	4
480	47-130	47-130	3000244	12	17900	0	12	214800	240576	4
481	89-2076	101-2076	3000243	1	6869500	0	12	7693840	6869500	4
512	7-3538	7-3538	2000102	4500	8666.66666666666788	0	0	39000000	39000000	4
451	80-476730	80-476730	100002	1943	6900	0	0	13406700	13406700	4
515	63-1676	63-1676	3000257	1	976000	0	12	976000	1093120	4
516	63-1676	63-1676	3000258	1	1377000	0	12	1377000	1542240	4
517	99-487	99-487	100004	2268.5	4250	0	0	9641125	9641125	4
518	18-11734	103-11734	3000250	3	58300	0	12	195888	174900	4
519	18-11734	103-11734	3000251	1	307700	0	12	344624	307700	4
520	18-11734	103-11734	3000252	100	296	0	12	33152	29600	4
521	18-11734	103-11734	3000253	100	466	0	12	52192	46600	4
522	18-11734	103-11734	3000254	2	23300	0	12	52192	46600	4
523	18-11734	103-11734	3000255	1	261120	0	12	2924544	261120	4
524	18-11734	103-11734	3000256	2	11224	0	12	2514176	22448	4
525	8-15232	43-15232	200055	10	55313	0	12	6195056	553130	4
526	9-92507	9-92507	100021	150	65000	0	12	9750000	10920000	4
527	80-802507	80-802507	100002	3299.5	6900	0	0	22766550	22766550	4
528	100-1727	100-1727	100002	3343.5	6500	0	0	21732750	21732750	4
363	18-11700	38-11700	3000245	5	6000	0	12	33600	30000	4
513	98-982507	98-982507	200081	1000	3700	0	12	4144000	3700000	4
514	98-982507	98-982507	200082	1000	5985	0	12	6703200	5985000	4
529	8-15262	102-15262	200058	5	771984	0	12	43231104	3859920	4
530	12-943	12-943	100003	5034.5	6000	0	0	30207000	30207000	4
531	88-390	88-390	200065	1000	31768.75	0	12	31768750	35581000	4
\.


--
-- Data for Name: td_factura_serv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_factura_serv (id, ccodfact, clote, ccant, cdescripcion, cpunit, cdesc, civa, ctot, cstot, cstatus) FROM stdin;
274	74-2628	74-2628	1	SERVICIO DE FUMIGACION COMERCIAL	300000	0	12	336	300	4
275	58-43	58-43	3	MANTENIMIENTO GENERAL A MOTORES VENTILADORES AXIAL FAN 14" PARA CAVA CDM (REBOBINADO, CAMBIO DE RODAMIENTOS Y CAPACITORES) 1 MES DE GARANTIA	380000	0	12	1.27600000000000002	1.1399999999999999	4
276	58-43	58-43	1	INSTALACION Y CONEXION DE 4 MOTORES VENTILADORES REVISION Y SEGUIMIENTO A UNIDAD CONDENSADORA Y RECARGA DE GAS AL SISTEMA	190000	0	12	212.800000000000011	190	4
277	58-43	58-43	1	BOMBONA DE NITROGENO	95000	0	12	106.400000000000006	95	4
338	58-46	58-46	3	MANTENIMIENTO GENERAL A MOTORES VENTILADORES AXIAL FAN 16" (REBOBINADOS, CAMBIO DE CAPACITORES Y RODAMIENTOS) PARA CAVA DE PRODUCTOS TERMINADOS	420000	0	12	1.41100000000000003	1.26000000000000001	4
339	58-46	58-46	1	GALON DE ACEITE 68 (PARA CAVA CDM)	240000	0	12	268.800000000000011	240	4
340	58-46	58-46	1	BOMBONA DE NITROGENO (PARA USO INTERNO)	125000	0	12	140	125	4
358	86-2549	86-2549	1	RECTIFICADO DE CUCHILLA 8 PUNTA PARA MOLINO WOLFKING 400	80000	0	12	89.5999999999999943	80	4
407	94-50	94-50	1	ENLACE DEDICADO A INTERNET AID 2MB (255.98$ T/C DICOM BS. 2200 26/06/2017)	563156	0	12	630.734000000000037	563.155999999999949	4
408	24-29026	24-29026	1	RODAMIENTO AUTOMOTRIZ MU1313UM-BOW	3150000	0	12	3.52800000000000002	3.14999999999999991	4
409	95-40733	95-40733	1	DESMONTAJE DE COMPRESOR DE 10HP EN CAVA DE AHUMADO LIMPIEZA DE SISTEMAS CON DIELECTRICO Y NITROGENO, INCLUYE LAVADO DE TODOS LOS COMPONENTES CONTAMINADOS DEL SISTEMA	680000	0	12	761.600000000000023	680	4
410	95-40733	95-40733	1	INSTALACION DE COMPRESOR DE 10HP OPERATIVO, INCLUYTE MANTENIMIENTO, BUSQUEDA Y CORRECCION DE FUGAS EN UNIDAD CONDENSADORA Y UNIDAD EVAPORADORA, INSTALACION DE 4 MOTORES VENTILADORES EN DIFUSOR, SUMINISTRO Y CAMBIO DE ACEITE, VACIO, CARGA DE GAS Y PUESTA EN FUNCIONAMIENTO DE LA CAVA	970000	0	12	1.08600000000000008	970	4
\.


--
-- Data for Name: td_ordencompra; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_ordencompra (id, cnorden, ccodprod, cdescripcion, ctipounidad, ccant, cpunit, ctot, cdesc, c_iva, cstot, cn_req, cdesc_serv, ct_directa) FROM stdin;
1	1	100001	AJO MOLIDO	Kg	378	6500	0	0	2457000	2457000	0		f
2	1	100002	C.D.M DE POLLO	Kg	6918	5000	0	0	34590000	34590000	0		f
3	1	100003	CACHETE DE RES	Kg	3723	3000	0	0	11169000	11169000	0		f
4	1	100004	CARAPACHO DE POLLO	Kg	1990	2980	0	0	5930200	5930200	0		f
5	1	100005	CARETA	Kg	11237	4200	0	0	47195400	47195400	0		f
6	1	100006	CARNE DE CABEZA	Kg	3515	5700	0	0	20035500	20035500	0		f
7	1	100007	CARNE DE RES	Kg	1230	2700	0	0	3321000	3321000	0		f
8	1	100008	CHULETA DE LECHON	Kg	7124	7200	0	0	51292800	51292800	0		f
9	1	100009	CHULETA DE MADRE	Kg	0	0	0	0	0	0	0		f
10	1	100010	COPA DE LECHON	Kg	405	7700	0	0	3118500	3118500	0		f
11	1	100011	COSTILLA CARNICERA DE LECHON	Kg	715	7500	0	0	5362500	5362500	0		f
12	1	100012	COSTILLA CARNICERA DE MADRE	Kg	0	0	0	0	0	0	0		f
13	1	100013	COSTILLA CHINA DE LECHON 	Kg	2201	7500	0	0	16507500	16507500	0		f
14	1	100014	COSTILLA CHINA DE MADRE	Kg	0	0	0	0	0	0	0		f
15	1	100015	CRIADILLAS	Kg	6512	1800	0	0	11721600	11721600	0		f
16	1	100016	CUERO PP	Kg	3454	4000	0	0	13816000	13816000	0		f
17	1	100017	CUERO TALLADO	Kg	464	4000	0	0	1856000	1856000	0		f
18	1	100018	CUERO TRATADO	Kg	0	2000	0	0	0	0	0		f
19	1	100019	HUESO Y CODILLO	Kg	0	0	0	0	0	0	0		f
20	1	100020	LECHONES	Kg	0	5510	0	0	0	0	0		f
21	1	100021	MADEJA	Unidad	75	30000	0	0	2250000	2250000	0		f
22	1	100022	MADRES	Kg	0	4550	0	0	0	0	0		f
23	1	100023	OREJAS	Kg	262	1200	0	0	314400	314400	0		f
24	1	100024	PALETA DE LECHON	Kg	2012	7700	0	0	15492400	15492400	0		f
25	1	100025	PAPADA SIN CUERO	Kg	6321	4600	0	0	29076600	29076600	0		f
26	1	100026	PATA DE LECHON	Kg	0	2250	0	0	0	0	0		f
27	1	100027	PATA DE MADRE	Kg	0	0	0	0	0	0	0		f
28	1	100028	PERNIL DE LECHON	Kg	4361	8000	0	0	34888000	34888000	0		f
29	1	100029	PERNIL Y PALETA DE MADRE	Kg	1322	6200	0	0	8196400	8196400	0		f
30	1	100030	RECORTE DE PRIMERA	Kg	0	6000	0	0	0	0	0		f
31	1	100031	RECORTE DE TERCERA	Kg	220	3800	0	0	836000	836000	0		f
32	1	100032	RECORTE DE TOCINETA	Kg	0	0	0	0	0	0	0		f
33	1	100033	RECORTE ROJO	Kg	14	3500	0	0	49000	49000	0		f
34	1	100034	TOCINETA	Kg	597	0	0	0	0	0	0		f
35	1	100035	TOCINO	Kg	2445	4200	0	0	10269000	10269000	0		f
36	1	100036	TRASTE	Kg	1339	3000	0	0	4017000	4017000	0		f
37	2	200007	200007 - AZUCAR	Kg	750	2800	2100000	0	0	2100000	99		f
38	3	200057	200057 - OLEO FRANFOURT	Kg	5	565230	2826150	0	0	2826150	114		f
39	3	200034	200034 - CONDIMENTO POLACA	Kg	20	78298	1565960	0	0	1565960	114		f
40	4	300011	300011 - DISCO DE CORTE DE ESMERIL PEQUEÑO DE 4"	Unidad	4	4388	17552	0	12	15445.7600000000002	125		f
41	4	300012	300012 - DISCO DE ESMERIL GRANDE DE CORTE DE 7"	Unidad	4	6599	26396	0	12	23228.4799999999996	125		f
52	10	200058	200058 - OLEO MORTADELA	Kg	5	561292	3143235.20000000019	0	12	2806460	159		f
43	6	200005	200005 - ALMIDON DE YUCA	Kg	1500	7980	13406400	0	12	11970000	145		f
53	11	200098	200098 - TRIPA CELULOSA 19X95	Metro	87000	435	42386400	0	12	37845000	100159		f
44	6	200094	200094 - ALMIDON DE YUCA (E)	Kg	1500	4550	7644000	0	0	6825000	145		f
54	12	200099	200099 - CERO MERMA CAL 22	Metro	70400	360	28385280	0	12	25344000	10159		f
42	5	200092	200092 - TRIPA PLASTICA F2 CALIBRE 72 COLOR CARMIN ( CARTON 2000KM)	Caja	10000	1480	16576000	0	12	14800000	120		f
45	7	300026	300026 - CAMARA BULLET HDCVI 1/3" CCD CMOS 1.3MP 2.7-12 MM IR 30M IP 67. DAHUA	Unidad	17	358200	6820128	0	12	6089400	100000		f
46	7	300027	300027 - TRANSFORMADOR 12VDC 1.25A	Unidad	17	34150	650216	0	12	580550	100000		f
47	7	300028	300028 - VIDEO BALUM PASIVO HDCVI 400 MTS (PAR)	Unidad	17	18700	356048	0	12	317900	100000		f
48	8	200096	200096 - TRIPA VISCOFAN CERO MERMA CAL. 75	Metro	50000	2149	120344000	0	12	107450000	100001		f
49	9	300032	300032 - LIJA 80 PLIEGOS	Unidad	5	1230	6888	0	12	6150	146		f
50	9	300033	300033 - LIJA 400 PLIEGOS	Unidad	5	720	4032	0	12	3600	146		f
51	9	300034	300034 - LIJA 220 PLIEGOS	Unidad	5	720	4032	0	12	3600	146		f
55	13	200058	200058 - OLEO MORTADELA	Kg	5	561292	3143235.20000000019	0	12	2806460	166		f
62	18	300080	300080 - MANGUERA DE POLIURETANO 8 MM	Mts	10	12960	145152	0	12	129600	167		f
57	15	200004	200004 - ALMIDON DE PAPA	Kg	1000	9810	10987200	0	12	9810000	166		f
56	14	200004	200004 - ALMIDON DE PAPA	Kg	1000	9810	10987200	0	12	9810000	166		f
58	16	200095	200095 - HIPOCLORITO DE SODIO AL 12%	Litro	240	1980	475200	0	0	475200	153		f
59	17	300077	300077 - CALCULADORA DE 12 DIGITOS	Uni	1	69642857	780000	0	12	696428.569999999949	140		f
60	17	300079	300079 - BLOCK DE  RAYAS	Uni	12	959821	128999.940000000002	0	12	115178.520000000004	140		f
61	17	300078	300078 - CAJA DE LAPICEROS NEGROS DE 12 UNIDADES	Uni	6	490171	32939.489999999998	0	12	29410.2599999999984	140		f
63	18	300081	300081 - MANGUERA DE POLIURETANO DE 6 MM	Mts	10	7350	82320	0	12	73500	167		f
64	18	300082	300082 - SILENCIADOR DE BRONCE 1"	Mts	2	39892	89358.0800000000017	0	12	79784	167		f
65	19	300085	300085 - CANAL EN LAMINA GALVANIZADA CALIBRE 24 DESARROLLO 72 REMACHADA, SOLDADA A ESTAÑO LOS EMPATES, TAPAS	Mts	5	70560	395136	0	12	352800	172		f
70	21	800001	800001 - UNIDAD DE REFRIGERACION 1	.	1	70000	78400	0	12	70000	168	 MANTENIMIENTO A TABLERO ELECTRICO	f
71	21	800002	800002 - EQUIPO DE REFRIGERACION  2	.	1	70000	78400	0	12	70000	168	 MANTENIMIENTO A TABLERO ELECTRICO	f
72	21	800001	800001 - UNIDAD DE REFRIGERACION 1	.	1	30000	33600	0	12	30000	168	 INSTALACION DE TERMOSTATO	f
73	21	800002	800002 - EQUIPO DE REFRIGERACION  2	.	1	30000	33600	0	12	30000	168	 INSTALACION DE TERMOSTATO	f
108	39	3000131	3000131 - SELECTOR 3 POSICIONES 22MM	Uni	6	72800	489216	0	12	436800	10101		f
109	39	3000132	3000132 - TERMOSTATO PARA CAVA 0 A 24 GRADOS	Uni	2	115200	258048	0	12	230400	10101		f
74	22	800003	800003 - SEGUN PRESUPUESTO 001 PARA CAVA DE EMPAQUE DE PROYECTOS ARM 2013 , C.A.	.	1	1590000	1780800	0	12	1590000	169	 0	f
75	23	200058	200058 - OLEO MORTADELA	Kg	5	701315	3927364	0	12	3506575	174		f
110	40	3000133	3000133 - BOLSAS PLASTICAS 15KG C/ASA (10X100)	Bulto	3	357499	12011.9699999999993	0	12	10724.9699999999993	10102		f
111	40	3000134	3000134 - BOLSAS PLASTICAS 10KG C/ASA (10X100)	Bulto	3	2925	9828	0	12	8775	10102		f
112	41	3000143	3000143 - RODAMIENTO DE/ RODILLOS BOWER MU1313V-BOW	Uni	1	217540045	2436448.5	0	12	2175400.45000000019	187		f
113	42	2000102	2000102 - HARINA DE TRIGO	Kg	3000	7800	23400000	0	0	23400000	188		f
76	24	200094	200094 - ALMIDON DE YUCA (E)	Kg	3000	5000	15000000	0	0	15000000	174		f
77	25	300089	300089 - VASOS 7 OZ	Caja	1	71735	80343.1999999999971	0	12	71735	173		f
78	25	300090	300090 - VASOS V-2	Caja	1	74562	83509.4400000000023	0	12	74562	173		f
79	26	300094	300094 - BOLSAS DE 5 KG	Bulto	2	2340030	52416.6699999999983	0	12	46800.5999999999985	171		f
80	27	300092	300092 - CINTA IMPRESORA APSOM FX2190	Uni	3	45990	154526.399999999994	0	12	137970	173		f
81	28	300096	300096 - MOUSE USB	Rollo	1	19990	22388.7999999999993	0	12	19990	163		f
82	29	3000102	3000102 - ESTOPERA 17-30-5	Uni	4	68335	306140.799999999988	0	12	273340	160		f
83	29	300060	300060 - RODAMIENTO 6202	Uni	4	15960	71500.8000000000029	0	12	63840	160		f
84	30	200010	200010 - BOLSA 49X75	Bulto	15	143325	2407860	0	12	2149875	175		f
85	31	3000116	3000116 - CONECTOR DE 80 AMPERIOS 220 VOLTIOS 1NA+1NC MARCA TELEMECANQUE MODELO LC1D80M7. PARA CONGELADORA	Uni	2	1906000	4269440	0	12	3812000	100771		f
86	31	3000117	3000117 - BLOQUE DE CONTACTO FRONTAL MODELO LAND11 1NA+1NC	Uni	4	51000	228480	0	12	204000	100771		f
87	31	3000118	3000118 - ROLLO TEIPE 33	Uni	2	57000	127680	0	12	114000	100771		f
88	31	3000119	3000119 - 10 PAQUETE DE MARQUILLAS DEN NUMEROS DEL 0 AL 9	Uni	2	8500	19040	0	12	17000	100771		f
89	32	3000111	3000111 - TERMINAL ZAPATO BRONCE P-400 P/CABLE 2/0 AL 500MCM	Uni	8	64102	574353.920000000042	0	12	512816	1006804		f
90	32	3000112	3000112 - BARRA COPPERWELD 3/8 X 240MTS	Uni	1	50700	56784	0	12	50700	1006804		f
91	32	3000113	3000113 - CONECTOR BARRA COPPERWELD 5/8	Uni	1	4800	5376	0	12	4800	1006804		f
92	32	3000114	3000114 - CABLE THHW (TF) N° 18 ROJO AWG 90	Uni	100	13492	151110.399999999994	0	12	134920	1006804		f
93	32	3000115	3000115 - SUPERVISOR TRIF C/PROT VOLTFAS PERD E INVERT 208/220V	Uni	5	136610	765016	0	12	683050	1006804		f
94	32	3000110	3000110 - RELE TEMPORIZADOR MULTIRANGO 0.05S-3H	Uni	1	102762	115093.440000000002	0	12	102762	1006804		f
95	33	3000105	3000105 - GUARDAMOTOR MAGNETOTERMICO 17-23A, 50KA EN 440VCA,  ACCIONADO POR PULSADORES	Uni	1	37609401	421225.289999999979	0	12	376094.010000000009	1008023		f
96	33	3000109	3000109 - GUARDAMOTOR MAGNETOTERMICO 56-80A, 50KA EN 440VCA, ACCIONADO POR MANDO GIRATORIO	Uni	2	199538662	4469666.03000000026	0	12	3990773.24000000022	1008023		f
97	33	3000106	3000106 - GUARDAMOTOR MAGNETOTERMICO 37-50A, 50KA EN 440VCA, ACCIONADO POR MANDO GIRATORIO	Uni	2	192225722	4305856.16999999993	0	12	3844514.43999999994	1008023		f
98	33	3000107	3000107 - CONTACTOR 3 POLOS, CATEGORIA AC3, 65A 1NA+1NC, 220VCA. EVERLINK	Uni	2	147303489	3299598.14999999991	0	12	2946069.7799999998	1008023		f
99	33	3000108	3000108 - INTERRUPTOR TERMOMAGNETICO ACTI 9, IC60N, 1 POLO, 6A	Uni	16	12188232	2184131.16999999993	0	12	1950117.12000000011	1008023		f
100	34	200075	200075 - TRIPA DE CELULOSA VISKEY 20X95	Caja	87000	430	41899200	0	12	37410000	176		f
101	35	200008	200008 - B.Z.T.	Kg	500	18500	10360000	0	12	9250000	176		f
102	36	300086	300086 - CARPETA LOMO ANCHO TIPO CARTA	Uni	36	1414285	570239.709999999963	0	12	509142.599999999977	173		f
103	36	300093	300093 - GANCHOS PARA CARPETAS	Caja	3	4400	14784	0	12	13200	173		f
104	36	300091	300091 - CLIPS NEGROS GRANDES	Uni	3	18590	62462.4000000000015	0	12	55770	173		f
105	37	200004	200004 - ALMIDON DE PAPA	Kg	1000	11750	13160000	0	12	11750000	176		f
107	38	3000129	3000129 - CARBONES PARA TRONZADORA	Uni	2	45000	100800	0	12	90000	178		f
114	43	200055	200055 - OLEO ALMENDRA	Kg	10	55313	619505.599999999977	0	12	553130	145		f
116	44	3000144	3000144 - COLETOS DE TELA	Uni	12	255668	34361.7799999999988	0	12	30680.1599999999999	183		f
117	44	3000145	3000145 - LANILLAS	Uni	12	113752	15288.2700000000004	0	12	13650.2399999999998	183		f
118	44	3000146	3000146 - CEPILLOS DE CERDAS FINAS	Uni	12	2613	35118.7200000000012	0	12	31356	183		f
119	44	3000147	3000147 - PALOS PARA ESCOBA	Uni	12	10504	14117.3799999999992	0	12	12604.7999999999993	183		f
122	47	200003	200003 - AGROGEL	Kg	1000	18738	20986560	0	12	18738000	189		f
123	48	200085	200085 - TRIPA POLIAMIDA CERO MERMA S/IMP CAL 22 (mts)	Mts	70400	410	32327680	0	12	28864000	189		f
124	49	200068	200068 - SAL	Kg	1000	615	688800	0	12	615000	1780		f
115	44	3000246	3000246 - ESPONJAS DE ALAMBRE	0	24	15574	41862.9100000000035	0	12	37377.5999999999985	183		f
120	45	200080	200080 - TRIPA MORTADELA ESPECIAL 75 AP (mts)	Mts	10000	2182	24438400	0	12	21820000	189		f
106	38	3000245	3000245 - TEIPE NEGRO COBRA	Uni	5	6000	33600	0	12	30000	178		f
125	50	300048	300048 - MANGUERA DE 3/4	Mts	50	4480	250880	0	12	224000	154		f
126	51	3000160	3000160 - GUARDAMOTOR MAGNETOTERMICO 9-14A, 50 KA EN 440V CA. ACCIONADO POR PULSADORES	Uni	2	340200	762048	0	12	680400	190		f
127	51	3000161	3000161 - CONTACTOR 3 POLOS, CATEGORIA AC3, 18 A 1NA + 1NC 220V CA	Uni	2	235620	527788.800000000047	0	12	471240	190		f
128	51	3000162	3000162 - INTERRUPTOR TERMOMAGNETICO ACTI 9, IC6ON, 2 POLOS 10A	Uni	5	718686	402464.159999999974	0	12	359343	190		f
129	51	3000163	3000163 - CABLE MONOPOLAR HELUKABEL SERIE H05V-K 0.75MM2 (18AWG) COLOR ROJO, 80°C	Mts	100	14067	157550.399999999994	0	12	140670	190		f
189	95	3000238	3000238 - CAMISA OXFORD TALLA S DE CABALLEROS COLOR BLANCO	Uni	6	44459.8099999999977	298769.919999999984	0	12	266758.859999999986	151		f
202	104	200075	200075 - TRIPA DE CELULOSA VISKEY 20X95	Caja	89600	420	42147840	0	12	37632000	201		f
121	46	200095	200095 - HIPOCLORITO DE SODIO AL 12%	Litro	960	1780	1913856	0	0	1708800	186		f
160	84	200064	200064 - PROTEINA DE CEREAL	Kg	5000	9300	52080000	0	12	46500000	189		f
161	85	200005	200005 - ALMIDON DE YUCA	Kg	4000	5000	22400000	0	12	20000000	189		f
162	86	3000184	3000184 - CONTACTO AUX GV3A01 TELEMECANIQUE	Uni	2	146000	327040	0	12	292000	999111999		f
164	86	3000186	3000186 - BRAKER CDB6L1C6	Uni	2	50000	112000	0	12	100000	999111999		f
163	86	3000185	3000185 - CONTACTO AUX GV3A08 TELEMECANIQUE	Uni	2	250000	560000	0	12	500000	999111999		f
166	87	200004	200004 - ALMIDON DE PAPA	Kg	1000	14200	15904000	0	12	14200000	198		f
192	100	3000161	3000161 - CONTACTOR 3 POLOS, CATEGORIA AC3, 18 A 1NA + 1NC 220V CA	Uni	1	235620	263894.400000000023	0	12	235620	0		t
165	87	100002	100002 - C.D.M DE POLLO	Kg	2000	6500	13000000	0	0	13000000	198		f
167	88	200065	200065 - AISLADO DE SOYA (PROTEINA DE JAMON)	Kg	1000	3176875	35581000	0	12	31768750	189		f
168	89	200005	200005 - ALMIDON DE YUCA	Kg	3000	5500	18480000	0	12	16500000	189		f
169	90	3000195	3000195 - DESMONTAJE DEL EQUIPO DE BOMBEO SUMERGIBLE CON SUS ACCESORIOS PARA SU EVALUACION ELECTROMECANICA	Uni	1	750000	840000	0	12	750000	1980		f
170	90	3000196	3000196 - INSTALACION DE LA TUBERIA DE LIMPIEZA Y AIRE PARA LIMPIEZA , DESARROLLO Y DESINFECCION DEL POZO	Rollo	1	750000	840000	0	12	750000	1980		f
171	90	3000197	3000197 - SUMINISTRO Y APLICACION DE PRODUCTO DISPERSANTE DE ARCILLAS PARA LA LIMPIEZA DEL EMPAQUE DE GRAVA WL	Uni	1	250000	280000	0	12	250000	1980		f
172	90	3000198	3000198 - APLICACION DE AGENTES QUIMICOS EN EL POZO MEDIANTE LA UTILIZACION DE COMPRESOR ALTA CAPACIDAD	Uni	8	175000	1568000	0	12	1400000	1980		f
173	90	3000199	3000199 - SUMINISTRO Y APLICACION DE AGENTE QUIMICO (MN-500)	Uni	60	11025	740880	0	12	661500	1980		f
174	90	3000200	3000200 - LIMPIEZA Y DESARROLLO DEL POZO CON AIRE UTILIZANDO COMPRESOR	Uni	16	175000	3136000	0	12	2800000	1980		f
175	90	3000201	3000201 - REVISION ELECTROMECANICA DEL EQUIPO SUMERGIBLE Y SUS ACCESORIOS	Uni	1	60000	67200	0	12	60000	1980		f
176	90	3000202	3000202 - SUMINISTRO TRANSPORTE Y COLOCACION DE GRAVA SELECCIONADA	Uni	10	20000	224000	0	12	200000	1980		f
177	91	3000203	3000203 - MOTOR SUMERGIBLE MARCA HITACHI 10 HP /230 VAC 6" TRIFASICO	Rollo	1	19435000	21767200	0	12	19435000	1980		f
178	91	3000204	3000204 - AJUSTE DE CUERPO DE BOMBA, ACOPLE A MOTOR Y PRUEBA EN BANCO.	Uni	1	90000	100800	0	12	90000	1980		f
179	91	3000205	3000205 - EMPALME VULCANIZADO MODELO 82-A2DE 3M	Rollo	1	570000	638400	0	12	570000	1980		f
180	91	3000206	3000206 - MANOMETRO DE RANGO 0-200 PSIG	Uni	1	69000	77280	0	12	69000	1980		f
181	91	3000208	3000208 - INSTALACION DE EQUIPO DE BOMBEO SUMERGIBLE 6" MENOR DE 100 M PROFUND	Uni	1	850000	952000	0	12	850000	1980		f
182	91	3000209	3000209 - ARRANQUE Y PUESTA EN MARCHA DEL EQUIPO DE BOMBEO	Rollo	1	120000	134400	0	12	120000	1980		f
183	91	3000210	3000210 - RELE MINI- SUBTRONIC ESPECIAL PARA BOMBAS SUMERGIBLES MODELO 10-32 A 480V	Uni	1	112330940	1258106.53000000003	0	12	1123309.39999999991	1980		f
184	91	3000211	3000211 - BREAKER SOLO MAGNETICO TRIPOLAR DE 40 AMP MARCA WEG	Uni	1	1689360	1892083.19999999995	0	12	1689360	1980		f
185	92	3000212	3000212 - PINTURA ANTICORROSCIVA FERROPROTECTOR	GALON	1	136500	152880	0	12	136500	199		f
186	92	3000213	3000213 - LIMPIEZA MECANICA DE COLUMNA DE DESCARGA, APLICACION DE FERROPROTECTOR Y VERIFICACION DE ROSCAS	Uni	1	200000	224000	0	12	200000	199		f
187	93	3000236	3000236 - BOTA DE SEGURIDAD MARCA FION MODELO 70020	Uni	2	145200	325248	0	12	290400	155		f
188	94	3000237	3000237 - LIBROS DE ACTA DE 300 FOLIOS	Uni	3	37500	126000	0	12	112500	191		f
193	101	3000243	3000243 - BOMBA SUMERIGIBLE	Uni	1	6869500	7693840	0	12	6869500	206		f
190	95	3000239	3000239 - CAMISA OXFORD M/C TALLA S COLOR GRIS	Uni	4	44459.8099999999977	199179.950000000012	0	12	177839.239999999991	151		f
194	102	200058	200058 - OLEO MORTADELA	Kg	5	771984	4323110.40000000037	0	12	3859920	201		f
195	103	3000250	3000250 - REGLETA PARA 110 V CON PROTECTOR DE FASE	Uni	3	58300	195888	0	12	174900	205		f
196	103	3000251	3000251 - ESCALERA DE 4 PELDAÑOS	Uni	1	307700	344624	0	12	307700	205		f
197	103	3000252	3000252 - CINTA TIRRAJE DE 14"	Uni	100	296	33152	0	12	29600	205		f
198	103	3000253	3000253 - CINTA TIRRAJE DE 18"	Uni	100	466	52192	0	12	46600	205		f
199	103	3000254	3000254 - BROCHA DE 4"	Uni	2	23300	52192	0	12	46600	205		f
200	103	3000255	3000255 - PINTURA ALUMINIO	Uni	1	261120	292454.400000000023	0	12	261120	205		f
201	103	3000256	3000256 - TIRRO BLANCO DE 1"	Uni	2	11224	25141.7599999999984	0	12	22448	205		f
191	95	3000240	3000240 - CAMISA M 3/4 TALLA S DE DAMA COLOR BLANCO	Uni	1	44459.8099999999977	49794.989999999998	0	12	44459.8099999999977	151		f
203	105	200051	200051 - LOOPS CRUDO	Uni	40000	55906	2504588800	0	12	2236240000	201		f
\.


--
-- Data for Name: td_req; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_req (id, cn_req, citem, ccodprod, ccant, cpunit, cdesc) FROM stdin;
1	0	0	100001	378	0	0
2	0	1	100002	6918	0	0
3	0	2	100003	3723	0	0
4	0	3	100004	1990	0	0
5	0	4	100005	11237	0	0
6	0	5	100006	3515	0	0
7	0	6	100007	1230	0	0
8	0	7	100008	7124	0	0
9	0	8	100009	0	0	0
10	0	9	100010	405	0	0
11	0	10	100011	715	0	0
12	0	11	100012	0	0	0
13	0	12	100013	2201	0	0
14	0	13	100014	0	0	0
15	0	14	100015	6512	0	0
16	0	15	100016	3454	0	0
17	0	16	100017	464	0	0
18	0	17	100018	0	0	0
19	0	18	100019	0	0	0
20	0	19	100020	0	0	0
21	0	20	100021	75	0	0
22	0	21	100022	0	0	0
23	0	22	100023	262	0	0
24	0	23	100024	2012	0	0
25	0	24	100025	6321	0	0
26	0	25	100026	0	0	0
27	0	26	100027	0	0	0
28	0	27	100028	4361	0	0
29	0	28	100029	1322	0	0
30	0	29	100030	0	0	0
31	0	30	100031	220	0	0
32	0	31	100032	0	0	0
33	0	32	100033	14	0	0
34	0	33	100034	597	0	0
35	0	34	100035	2445	0	0
36	0	35	100036	1339	0	0
37	99	1	200007	750	2800	0
38	114	1	200057	10	0	0
39	114	2	200034	40	78298	0
40	120	1	200092	10000	1480000	0
41	125	1	300011	4	4388	0
42	125	2	300012	4	6599	0
43	148	1	300025	1	1571780491	0
44	147	1	300026	17	369215	0
45	147	2	300027	17	35700	0
46	147	3	300028	17	19250	0
49	145	1	200005	5000	7980	0
50	145	2	200094	5000	4550	0
51	145	3	200065	3000	24400	0
52	145	4	200058	10	0	0
53	145	5	200055	10	0	0
54	145	6	200081	5000	0	0
55	145	7	200004	3000	0	0
56	145	8	200022	10	0	0
57	145	9	200064	10000	0	0
58	153	1	200095	225	0	0
59	146	1	300032	5	1230	0
60	146	2	300033	5	720	0
61	146	3	300034	5	720	0
62	144	1	300035	2	0	0
63	144	2	300037	2	0	0
64	144	3	300038	2	0	0
65	144	4	300041	3	0	0
66	144	5	300039	10	0	0
67	144	6	300040	10	0	0
68	144	7	300042	3	0	0
69	144	8	300043	5	0	0
70	100000	1	300026	17	358200	0
71	100000	2	300027	17	34150	0
72	100000	3	300028	17	18700	0
73	100001	1	200096	50000	2149	0
74	159	1	200058	5	561292	0
75	100159	1	200098	87000	435	0
76	10159	1	200099	70400	360	0
77	166	1	200004	2000	9810	0
78	166	2	200058	5	561292	0
79	140	1	300077	696428.569999999949	0	0
80	140	2	300079	4901.71000000000004	0	0
81	140	3	300078	9598.20999999999913	0	0
82	167	1	300080	10	12960	0
83	167	2	300081	10	7350	0
84	167	3	300082	2	39892	0
85	172	1	300085	5	70560	0
92	174	2	200058	5	0	0
108	175	1	200010	15	143325	0
91	174	1	200094	3000	0	0
109	1006804	1	3000111	8	64102	0
110	1006804	2	3000112	1	50700	0
111	1006804	3	3000113	1	4800	0
112	1006804	4	3000114	100	1349.20000000000005	0
93	173	1	300086	36	0	0
94	173	2	300093	3	0	0
95	173	3	300073	12	0	0
96	173	4	300089	1	0	0
97	173	5	300090	1	0	0
98	173	6	300091	3	0	0
99	173	7	300092	3	0	0
100	171	1	300094	2	0	0
101	163	1	300021	4	0	0
102	163	2	300096	1	0	0
103	163	3	300097	6	0	0
104	160	1	3000102	4	0	0
105	160	2	300097	6	0	0
106	160	3	300060	4	0	0
107	160	4	3000104	2	0	0
113	1006804	5	3000115	5	136610	0
114	1006804	6	3000110	1	102762	0
115	100771	1	3000116	2	1906000	0
116	100771	2	3000117	4	51000	0
117	100771	3	3000118	2	57000	0
118	100771	4	3000119	2	8500	0
119	1008023	1	3000105	1	376094.010000000009	0
120	1008023	2	3000109	2	1995386.62000000011	0
121	1008023	3	3000106	2	1922257.21999999997	0
122	1008023	4	3000107	2	1473034.8899999999	0
123	1008023	5	3000108	16	121882.320000000007	0
124	176	1	200005	5000	0	0
125	176	2	200004	3000	0	0
126	176	3	200065	2000	0	0
127	176	4	200047	3000	0	0
128	176	5	200075	20	0	0
129	176	6	200007	750	0	0
130	176	7	200057	20	0	0
131	176	8	200059	20	0	0
132	176	9	200008	500	0	0
133	176	10	2000100	2000	0	0
135	178	2	3000129	2	0	0
136	178	3	3000130	10	0	0
137	10101	1	3000131	6	72800	0
138	10101	2	3000132	2	115200	0
139	10102	1	3000133	3	3574.98999999999978	0
140	10102	2	3000134	3	2925	0
142	187	1	3000143	1	0	0
143	188	1	2000102	3000	7800	0
145	183	2	3000144	12	2556.67999999999984	0
146	183	3	3000145	12	1137.51999999999998	0
147	183	4	3000146	12	2613	0
148	183	5	3000147	12	1050.40000000000009	0
149	189	1	200004	3000	0	0
150	189	2	200005	5000	0	0
151	189	3	200047	3000	0	0
152	189	4	200085	70400	0	0
153	189	5	200058	5	0	0
154	189	6	200065	1000	0	0
155	189	7	200089	2000	0	0
156	189	8	200003	2000	0	0
157	189	9	200064	5000	0	0
158	189	10	200080	10000	0	0
159	1780	1	200068	1000	0	0
160	154	1	300048	50	4480	0
161	190	1	3000160	2	340200	0
162	190	2	3000161	2	235620	0
163	190	3	3000162	5	43121.1600000000035	0
164	190	4	3000163	100	16880.4000000000015	0
141	186	1	200095	840	0	0
165	999111999	1	3000184	2	146000	0
166	999111999	2	3000185	2	250000	0
167	999111999	3	3000186	2	50000	0
168	198	1	100002	2000	6300	0
169	198	2	200004	1000	14200	0
170	1980	1	3000207	1	0	0
171	1980	2	3000195	1	0	0
172	1980	3	3000196	1	0	0
173	1980	4	3000197	1	0	0
174	1980	5	3000198	8	0	0
175	1980	6	3000199	60	0	0
176	1980	7	3000200	16	0	0
177	1980	8	3000201	1	0	0
178	1980	9	3000202	10	0	0
179	1980	10	3000203	1	0	0
180	1980	11	3000204	1	0	0
181	1980	12	3000205	1	0	0
182	1980	13	3000206	1	0	0
183	1980	1	3000207	1	0	0
184	1980	15	3000208	1	0	0
185	1980	16	3000209	1	0	0
186	1980	17	3000210	1	0	0
187	1980	18	3000211	1	0	0
188	199	1	3000212	1	0	0
189	199	2	3000213	1	0	0
190	155	1	3000236	2	145200	0
191	191	1	3000237	3	37500	0
192	151	1	3000238	6	0	0
193	151	2	3000239	4	0	0
194	151	3	3000240	1	0	0
195	206	1	3000243	1	0	0
196	201	1	200007	1000	0	0
197	201	2	200057	5	0	0
198	201	3	200058	5	0	0
199	201	4	200075	15	0	0
200	201	5	200031	10	0	0
201	201	6	200065	1000	0	0
202	201	7	200051	2	0	0
203	201	8	200064	5000	0	0
204	201	9	2000100	2	0	0
205	205	1	3000250	3	0	0
206	205	2	3000251	1	0	0
207	205	3	3000252	1	0	0
208	205	4	3000253	1	0	0
209	205	5	3000254	2	0	0
210	205	6	3000255	1	0	0
211	205	7	3000256	2	0	0
134	178	1	3000245	5	0	0
144	183	1	3000246	24	1557.40000000000009	0
\.


--
-- Data for Name: td_req_serv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_req_serv (id, cn_req, citem, ccodprod, cdescripcion, ccant, cpunit, cdesc) FROM stdin;
86	168	1	800001	MANTENIMIENTO A TABLERO ELECTRICO	1	0	0
88	168	3	800002	MANTENIMIENTO A TABLERO ELECTRICO	1	0	0
87	168	1	800001	INSTALACION DE TERMOSTATO	1	0	0
89	168	3	800002	INSTALACION DE TERMOSTATO	1	0	0
90	169	1	800003	0	0	0	0
\.


--
-- Data for Name: td_salida_inv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_salida_inv (id, cidm, codprod, ccant, ct_unidad, cpunit, ctot, clote, ccodfact) FROM stdin;
17	42	100001	370	Kg	6500	2405000	0-0	0-0
18	42	100002	6900	Kg	5000	34500000	0-0	0-0
19	43	200007	23	Kg	3700	85100	0-0	0-0
20	43	200068	134	Kg	64	8576	0-0	0-0
21	43	200069	17	Kg	2800	47600	0-0	0-0
22	43	200036	5	Kg	14100	70500	0-0	0-0
23	43	200003	30	Kg	12490	374700	0-0	0-0
24	43	200064	180	Kg	3200	576000	0-0	0-0
25	43	200065	10	Kg	17798	177980	0-0	0-0
26	43	200005	425	Kg	4600	1955000	0-0	0-0
27	43	200047	120	Kg	3600	432000	0-0	0-0
28	43	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
29	43	200057	0.200000000000000011	Kg	522453	104490.600000000006	0-0	0-0
30	43	200060	0.0500000000000000028	Kg	647948	32397.4000000000015	0-0	0-0
31	43	200059	0.0500000000000000028	Kg	304618	15230.9000000000015	0-0	0-0
32	43	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
33	43	200058	0.699999999999999956	Kg	451416	315991.199999999953	0-0	0-0
34	43	200055	0.100000000000000006	Kg	99825	9982.5	0-0	0-0
35	43	200049	1	Kg	61000	61000	0-0	0-0
36	43	200028	0.239999999999999991	Kg	90000	21600	0-0	0-0
37	43	200030	0.299999999999999989	Kg	22000	6600	0-0	0-0
38	43	200029	7.79999999999999982	Kg	27.5700000000000003	215.045999999999992	0-0	0-0
39	43	200074	195	Metro	1780.42000000000007	347181.900000000023	0-0	0-0
40	43	200080	1310	Metro	1680	2200800	0-0	0-0
41	43	200010	7	Bulto	62105	434735	0-0	0-0
42	43	200013	0.200000000000000011	Caja	1383000	276600	0-0	0-0
43	43	200075	1	Caja	2950000	2950000	0-0	0-0
44	43	200041	0.200000000000000011	Caja	1837500	367500	0-0	0-0
45	45	100002	2552	Kg	5000	12760000	0-0	0-0
46	45	100003	1925	Kg	3000	5775000	0-0	0-0
47	45	100008	295	Kg	7200	2124000	0-0	0-0
48	45	100009	250	Kg	0	0	0-0	0-0
49	45	100015	397	Kg	1800	714600	0-0	0-0
50	45	100034	305.5	Kg	0	0	0-0	0-0
51	45	100035	936.5	Kg	4200	3933300	0-0	0-0
52	45	100036	154	Kg	3000	462000	0-0	0-0
53	45	100019	130.5	Kg	0	0	0-0	0-0
54	46	200035	32	Kg	9687.5	310000	0-0	0-0
55	46	200008	12	Kg	14900	178800	0-0	0-0
56	46	200038	12	Kg	9300	111600	0-0	0-0
57	47	200007	57	Kg	3700	210900	0-0	0-0
58	47	200068	240	Kg	64	15360	0-0	0-0
59	47	200035	36	Kg	9687.5	348750	0-0	0-0
60	47	200069	23	Kg	2800	64400	0-0	0-0
61	47	200008	14	Kg	14900	208600	0-0	0-0
62	47	200038	14	Kg	9300	130200	0-0	0-0
63	47	200036	5	Kg	14100	70500	0-0	0-0
64	47	200003	50	Kg	12490	624500	0-0	0-0
65	47	200064	490	Kg	3200	1568000	0-0	0-0
66	47	200005	575	Kg	4600	2645000	0-0	0-0
67	47	200057	0.200000000000000011	Kg	522453	104490.600000000006	0-0	0-0
68	47	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
69	47	200059	0.100000000000000006	Kg	304618	30461.8000000000029	0-0	0-0
70	47	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
71	47	200058	0.599999999999999978	Kg	451416	270849.599999999977	0-0	0-0
72	47	200055	0.0599999999999999978	Kg	99825	5989.5	0-0	0-0
73	47	200049	1	Kg	61000	61000	0-0	0-0
74	47	200028	0.320000000000000007	Kg	90000	28800	0-0	0-0
75	47	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
76	47	200001	23.8000000000000007	Kg	16.2199999999999989	386.036000000000001	0-0	0-0
77	47	200029	10.1999999999999993	Kg	27.5700000000000003	281.213999999999999	0-0	0-0
78	47	200002	5	Kg	32	160	0-0	0-0
79	47	200047	240	Kg	3600	864000	0-0	0-0
80	49	100001	41	Kg	6500	266500	0-0	0-0
81	49	100002	3939	Kg	5000	19695000	0-0	0-0
82	49	100004	6525	Kg	2980	19444500	0-0	0-0
83	49	100006	249	Kg	5700	1419300	0-0	0-0
84	49	100015	702	Kg	1800	1263600	0-0	0-0
85	49	100016	760	Kg	4000	3040000	0-0	0-0
86	49	100017	486	Kg	4000	1944000	0-0	0-0
87	49	100036	194.5	Kg	3000	583500	0-0	0-0
88	50	100006	50.5	Kg	5700	287850	0-0	0-0
89	50	100015	536.5	Kg	1800	965700	0-0	0-0
90	50	100035	335.5	Kg	4200	1409100	0-0	0-0
91	50	100002	2508.5	Kg	5000	12542500	0-0	0-0
92	51	200001	11.1999999999999993	Kg	16.2199999999999989	181.663999999999987	0-0	0-0
93	51	200002	67	Kg	32	2144	0-0	0-0
94	51	200003	20	Kg	12490	249800	0-0	0-0
95	51	200005	350	Kg	4600	1610000	0-0	0-0
96	51	200008	8	Kg	14900	119200	0-0	0-0
97	51	200035	16	Kg	9687.5	155000	0-0	0-0
98	51	200036	4	Kg	14100	56400	0-0	0-0
99	51	200038	8	Kg	9300	74400	0-0	0-0
100	51	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
101	51	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
102	51	200059	0.100000000000000006	Kg	304618	30461.8000000000029	0-0	0-0
103	51	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
104	51	200064	360	Kg	3200	1152000	0-0	0-0
105	51	200065	10	Kg	17798	177980	0-0	0-0
106	51	200068	100	Kg	64	6400	0-0	0-0
107	51	200069	10	Kg	2800	28000	0-0	0-0
108	51	200075	1	Caja	2950000	2950000	0-0	0-0
109	51	200088	3	Metro	0	0	0-0	0-0
110	51	200007	26	Kg	3700	96200	0-0	0-0
111	51	200028	1.60000000000000009	Kg	90000	144000	0-0	0-0
112	51	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
113	52	100004	1707	Kg	2980	5086860	0-0	0-0
114	53	100002	2460	Kg	5000	12300000	0-0	0-0
115	53	100015	523.5	Kg	1800	942300	0-0	0-0
116	53	100006	120	Kg	5700	684000	0-0	0-0
117	54	200001	16.8000000000000007	Kg	16.2199999999999989	272.495999999999981	0-0	0-0
118	54	200003	30	Kg	12490	374700	0-0	0-0
119	54	200005	400	Kg	4600	1840000	0-0	0-0
120	54	200007	36	Kg	3700	133200	0-0	0-0
121	54	200008	12	Kg	14900	178800	0-0	0-0
122	54	200029	7.20000000000000018	Kg	27.5700000000000003	198.504000000000019	0-0	0-0
123	54	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
124	54	200035	30	Kg	9687.5	290625	0-0	0-0
125	54	200036	5	Kg	14100	70500	0-0	0-0
126	54	200038	12	Kg	9300	111600	0-0	0-0
127	54	200051	4000	Unidad	40	160000	0-0	0-0
128	54	200055	0.0599999999999999978	Kg	99825	5989.5	0-0	0-0
129	54	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
131	54	200058	0.599999999999999978	Kg	451416	270849.599999999977	0-0	0-0
132	54	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
133	54	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
134	54	200064	550	Kg	3200	1760000	0-0	0-0
135	54	200068	150	Kg	64	9600	0-0	0-0
136	54	200069	15	Kg	2800	42000	0-0	0-0
137	54	200074	300	Metro	1780.42000000000007	534126	0-0	0-0
138	54	200081	1000	Metro	1800	1800000	0-0	0-0
139	54	200013	1	Caja	1383000	1383000	0-0	0-0
130	54	200057	0.299999999999999989	Kg	522453	15673.5900000000001	0-0	0-0
140	55	100002	3219	Kg	5000	16095000	0-0	0-0
141	55	100011	351	Kg	7500	2632500	0-0	0-0
142	55	100015	571	Kg	1800	1027800	0-0	0-0
143	55	100006	119	Kg	5700	678300	0-0	0-0
144	55	100035	619	Kg	4200	2599800	0-0	0-0
145	56	100004	1764.5	Kg	2980	5258210	0-0	0-0
146	56	100035	253	Kg	4200	1062600	0-0	0-0
147	57	100035	299.5	Kg	4200	1257900	0-0	0-0
148	58	100002	2784	Kg	5000	13920000	0-0	0-0
149	58	100007	420.5	Kg	2700	1135350	0-0	0-0
150	58	100006	123	Kg	5700	701100	0-0	0-0
151	58	100015	559	Kg	1800	1006200	0-0	0-0
152	58	100016	1196	Kg	4000	4784000	0-0	0-0
153	58	100023	13	Kg	1200	15600	0-0	0-0
154	59	200001	15.4000000000000004	Kg	16.2199999999999989	249.787999999999982	0-0	0-0
155	59	200005	575	Kg	4600	2645000	0-0	0-0
156	59	200008	12	Kg	14900	178800	0-0	0-0
157	59	200007	25	Kg	3700	92500	0-0	0-0
158	59	200010	1	Bulto	62105	62105	0-0	0-0
159	59	200013	1	Caja	1383000	1383000	0-0	0-0
160	59	200029	6.59999999999999964	Kg	27.5700000000000003	181.961999999999989	0-0	0-0
161	59	200030	0.299999999999999989	Kg	22000	6600	0-0	0-0
162	59	200035	25	Kg	9687.5	242187.5	0-0	0-0
163	59	200036	4	Kg	14100	56400	0-0	0-0
164	59	200038	12	Kg	9300	111600	0-0	0-0
165	59	200055	0.100000000000000006	Kg	99825	9982.5	0-0	0-0
166	59	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
167	59	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
168	59	200058	0.699999999999999956	Kg	451416	315991.199999999953	0-0	0-0
169	59	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
170	59	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
171	59	200064	480	Kg	3200	1536000	0-0	0-0
172	59	200065	20	Kg	17798	355960	0-0	0-0
173	59	200068	123	Kg	64	7872	0-0	0-0
174	59	200069	13	Kg	2800	36400	0-0	0-0
175	59	200075	1	Caja	2950000	2950000	0-0	0-0
176	59	200080	812.5	Metro	1680	1365000	0-0	0-0
177	59	200082	50	.	2835	141750	0-0	0-0
178	59	200003	28	Kg	12490	349720	0-0	0-0
179	60	200001	16.8000000000000007	Kg	16.2199999999999989	272.495999999999981	0-0	0-0
180	60	200003	40	Kg	12490	499600	0-0	0-0
181	60	200004	100	Kg	10000	1000000	0-0	0-0
182	60	200005	525	Kg	4600	2415000	0-0	0-0
183	60	200008	16	Kg	14900	238400	0-0	0-0
184	60	200029	7.20000000000000018	Kg	27.5700000000000003	198.504000000000019	0-0	0-0
185	60	200035	38	Kg	9687.5	368125	0-0	0-0
186	60	200036	6	Kg	14100	84600	0-0	0-0
187	60	200038	16	Kg	9300	148800	0-0	0-0
188	60	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
189	60	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
190	60	200058	0.400000000000000022	Kg	451416	180566.400000000023	0-0	0-0
191	60	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
192	60	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
193	60	200064	50	Kg	3200	160000	0-0	0-0
194	60	200065	700	Kg	17798	12458600	0-0	0-0
195	60	200068	150	Kg	64	9600	0-0	0-0
196	60	200069	20	Kg	2800	56000	0-0	0-0
197	60	200075	1	Caja	2950000	2950000	0-0	0-0
198	61	100002	1747.5	Kg	5000	8737500	0-0	0-0
199	61	100006	140	Kg	5700	798000	0-0	0-0
200	61	100007	153	Kg	2700	413100	0-0	0-0
201	61	100013	18.5	Kg	7500	138750	0-0	0-0
202	61	100015	540.5	Kg	1800	972900	0-0	0-0
203	61	100023	5	Kg	1200	6000	0-0	0-0
204	61	100025	20	Kg	4600	92000	0-0	0-0
205	61	100027	80	Kg	400	32000	0-0	0-0
206	62	100004	463	Kg	2980	1379740	0-0	0-0
207	62	100029	449	Kg	6200	2783800	0-0	0-0
208	62	100032	130	Kg	6000	780000	0-0	0-0
209	62	100035	322	Kg	4200	1352400	0-0	0-0
210	63	200080	812.5	Metro	1680	1365000	0-0	0-0
211	63	200051	4000	Unidad	40	160000	0-0	0-0
212	63	200003	9	Kg	12490	112410	0-0	0-0
213	63	200041	0.200000000000000011	Caja	1837500	367500	0-0	0-0
214	64	200007	2.79999999999999982	Kg	3700	10360	0-0	0-0
215	64	200068	24	Kg	64	1536	0-0	0-0
216	64	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
217	64	200069	2.39999999999999991	Kg	2800	6720	0-0	0-0
218	64	200008	2	Kg	14900	29800	0-0	0-0
219	64	200038	2	Kg	9300	18600	0-0	0-0
220	64	200035	5	Kg	9687.5	48437.5	0-0	0-0
221	64	200058	0.200000000000000011	Kg	451416	90283.2000000000116	0-0	0-0
222	64	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
223	64	200065	80	Kg	17798	1423840	0-0	0-0
224	64	200005	75	Kg	4600	345000	0-0	0-0
225	65	200086	500	Metro	2480	1240000	0-0	0-0
226	66	100035	300	Kg	4200	1260000	0-0	0-0
227	66	100007	142	Kg	2700	383400	0-0	0-0
228	66	100002	1569	Kg	5000	7845000	0-0	0-0
229	66	100036	243.5	Kg	3000	730500	0-0	0-0
230	66	100015	241	Kg	1800	433800	0-0	0-0
231	67	100002	500	Kg	5000	2500000	0-0	0-0
232	67	100007	146	Kg	2700	394200	0-0	0-0
233	67	100006	133	Kg	5700	758100	0-0	0-0
234	68	200075	1	Caja	2950000	2950000	0-0	0-0
235	68	200007	23	Kg	3700	85100	0-0	0-0
236	68	200068	36	Kg	64	2304	0-0	0-0
237	68	200069	4	Kg	2800	11200	0-0	0-0
238	68	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
239	68	200035	6	Kg	9687.5	58125	0-0	0-0
240	68	200008	4	Kg	14900	59600	0-0	0-0
241	68	200038	4	Kg	9300	37200	0-0	0-0
242	68	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
243	68	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
244	68	200060	0.0500000000000000028	Kg	647948	32397.4000000000015	0-0	0-0
245	68	200057	0.0500000000000000028	Kg	522453	26122.6500000000015	0-0	0-0
246	68	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
247	68	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
248	68	200005	100	Kg	4600	460000	0-0	0-0
249	68	200065	100	Kg	17798	1779800	0-0	0-0
250	68	200003	5	Kg	12490	62450	0-0	0-0
251	68	200028	0.0700000000000000067	Kg	90000	6300.00000000000091	0-0	0-0
252	69	100015	240.5	Kg	1800	432900	0-0	0-0
253	69	100002	1169.5	Kg	5000	5847500	0-0	0-0
254	70	200086	200	Metro	2480	496000	0-0	0-0
255	71	200007	16	Kg	3700	59200	0-0	0-0
256	71	200068	36	Kg	64	2304	0-0	0-0
257	71	200069	4	Kg	2800	11200	0-0	0-0
258	71	200036	4	Kg	14100	56400	0-0	0-0
259	71	200003	10	Kg	12490	124900	0-0	0-0
260	71	200008	4	Kg	14900	59600	0-0	0-0
261	71	200038	4	Kg	9300	37200	0-0	0-0
262	71	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
263	71	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
264	71	200028	1.12000000000000011	Kg	90000	100800.000000000015	0-0	0-0
265	71	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
266	71	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
267	71	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
268	71	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
269	71	200005	200	Kg	4600	920000	0-0	0-0
270	71	200085	1	Caja	1091200	1091200	0-0	0-0
271	71	200065	160	Kg	17798	2847680	0-0	0-0
272	72	200065	40	Kg	17798	711920	0-0	0-0
273	72	200007	1.39999999999999991	Kg	3700	5180	0-0	0-0
274	72	200068	24	Kg	64	1536	0-0	0-0
275	72	200069	1.02000000000000002	Kg	2800	2856	0-0	0-0
276	72	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
277	72	200003	2.5	Kg	12490	31225	0-0	0-0
278	72	200058	0.100000000000000006	Kg	451416	45141.6000000000058	0-0	0-0
279	72	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
280	72	200005	37.5	Kg	4600	172500	0-0	0-0
281	72	200008	1	Kg	14900	14900	0-0	0-0
282	72	200038	1	Kg	9300	9300	0-0	0-0
283	72	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
284	72	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
285	72	200028	0.0050000000000000001	Kg	90000	450	0-0	0-0
286	72	200055	0.00300000000000000006	Kg	99825	299.475000000000023	0-0	0-0
287	73	200007	4.5	Kg	3700	16650	0-0	0-0
288	73	200068	12	Kg	64	768	0-0	0-0
289	73	200035	2	Kg	9687.5	19375	0-0	0-0
290	73	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
291	73	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
292	73	200008	1	Kg	14900	14900	0-0	0-0
293	73	200038	1	Kg	9300	9300	0-0	0-0
294	73	200003	2.5	Kg	12490	31225	0-0	0-0
295	73	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
296	73	200001	1.5	Kg	16.2199999999999989	24.3299999999999983	0-0	0-0
297	73	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
298	73	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
299	73	200065	20	Kg	17798	355960	0-0	0-0
300	73	200005	25	Kg	4600	115000	0-0	0-0
301	74	200007	4	Kg	3700	14800	0-0	0-0
302	74	200068	20.1999999999999993	Kg	64	1292.79999999999995	0-0	0-0
303	74	200069	2	Kg	2800	5600	0-0	0-0
304	74	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
305	74	200008	2	Kg	14900	29800	0-0	0-0
306	74	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
307	74	200061	0.800000000000000044	Kg	9000	7200	0-0	0-0
308	74	200005	50	Kg	4600	230000	0-0	0-0
309	74	200036	1	Kg	14100	14100	0-0	0-0
310	74	200035	4	Kg	9687.5	38750	0-0	0-0
311	74	200003	5	Kg	12490	62450	0-0	0-0
312	74	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
313	74	200038	2	Kg	9300	18600	0-0	0-0
314	74	200065	40	Kg	17798	711920	0-0	0-0
315	74	200062	0.200000000000000011	Kg	42000	8400	0-0	0-0
316	75	200051	100	Unidad	40	4000	0-0	0-0
317	75	200082	100	.	2835	283500	0-0	0-0
318	75	200007	1.39999999999999991	Kg	3700	5180	0-0	0-0
319	75	200068	12	Kg	64	768	0-0	0-0
320	75	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
321	75	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
322	75	200008	1	Kg	14900	14900	0-0	0-0
323	75	200038	1	Kg	9300	9300	0-0	0-0
324	75	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
325	75	200003	2.5	Kg	12490	31225	0-0	0-0
326	75	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
327	75	200029	6	Kg	27.5700000000000003	165.420000000000016	0-0	0-0
328	75	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
329	75	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
330	75	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
331	75	200065	40	Kg	17798	711920	0-0	0-0
332	75	200005	37.5	Kg	4600	172500	0-0	0-0
334	76	200010	1	Bulto	62105	62105	0-0	0-0
335	76	200009	1	Bulto	62105	62105	0-0	0-0
336	77	100002	177	Kg	5000	885000	0-0	0-0
337	77	100005	136	Kg	4200	571200	0-0	0-0
338	77	100006	140	Kg	5700	798000	0-0	0-0
339	78	100002	354	Kg	5000	1770000	0-0	0-0
340	78	100007	53	Kg	2700	143100	0-0	0-0
341	78	100006	148	Kg	5700	843600	0-0	0-0
342	78	100030	178	Kg	6000	1068000	0-0	0-0
343	78	100031	84.5	Kg	3800	321100	0-0	0-0
344	79	100025	22	Kg	4600	101200	0-0	0-0
345	79	100007	23.5	Kg	2700	63450	0-0	0-0
346	79	100015	60	Kg	1800	108000	0-0	0-0
347	79	100006	132	Kg	5700	752400	0-0	0-0
348	79	100030	120.5	Kg	6000	723000	0-0	0-0
349	80	100002	881	Kg	5000	4405000	0-0	0-0
351	81	100002	224	Kg	5000	1120000	0-0	0-0
352	81	100007	75.5	Kg	2700	203850	0-0	0-0
353	81	100006	85	Kg	5700	484500	0-0	0-0
354	82	100002	278.5	Kg	5000	1392500	0-0	0-0
355	82	100007	70	Kg	2700	189000	0-0	0-0
356	82	100006	39.5	Kg	5700	225150	0-0	0-0
350	80	100015	81.5	Kg	1800	328500	0-0	0-0
357	80	100015	101	Kg	2500	252500	12-930	12-930
333	76	200013	0.400000000000000022	Caja	1383000	829800000	0-0	0-0
358	76	200075	1	Caja	2950000	2950000	0-0	0-0
359	83	200007	24	Kg	3700	88800	0-0	0-0
360	83	200068	54	Kg	64	3456	0-0	0-0
361	83	200069	6	Kg	2800	16800	0-0	0-0
362	83	200035	15	Kg	9687.5	145312.5	0-0	0-0
363	83	200008	6	Kg	14900	89400	0-0	0-0
364	83	200038	6	Kg	9300	55800	0-0	0-0
365	83	200003	15	Kg	12490	187350	0-0	0-0
366	83	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
367	83	200075	0.5	Caja	2950000	1475000	0-0	0-0
368	83	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
369	83	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
370	83	200060	0.149999999999999994	Kg	647948	97192.1999999999971	0-0	0-0
371	83	200056	0.299999999999999989	Kg	166195	49858.5	0-0	0-0
372	83	200059	0.900000000000000022	Kg	304618	274156.200000000012	0-0	0-0
373	83	200057	0.149999999999999994	Kg	522453	78367.9499999999971	0-0	0-0
374	83	200065	140	Kg	17798	2491720	0-0	0-0
375	83	200005	300	Kg	4600	1380000	0-0	0-0
376	84	200068	24	Kg	64	1536	0-0	0-0
377	84	200007	2.79999999999999982	Kg	3700	10360	0-0	0-0
378	84	200069	2.39999999999999991	Kg	2800	6720	0-0	0-0
379	84	200035	10	Kg	9687.5	96875	0-0	0-0
380	84	200008	2	Kg	14900	29800	0-0	0-0
381	84	200038	2	Kg	9300	18600	0-0	0-0
382	84	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
383	84	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
384	84	200003	5	Kg	12490	62450	0-0	0-0
385	84	200001	1.19999999999999996	Kg	16.2199999999999989	19.4639999999999986	0-0	0-0
386	84	200058	0.200000000000000011	Kg	451416	90283.2000000000116	0-0	0-0
387	84	200055	0.0299999999999999989	Kg	99825	2994.75	0-0	0-0
388	84	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
389	84	200065	80	Kg	17798	1423840	0-0	0-0
390	84	200005	75	Kg	4600	345000	0-0	0-0
391	85	200013	0.46000000000000002	Caja	1383000	636180	0-0	0-0
392	85	200010	4	Bulto	62105	248420	0-0	0-0
393	85	200069	1	Kg	2800	2800	0-0	0-0
394	85	200068	25	Kg	64	1600	0-0	0-0
395	85	200049	1	Kg	61000	61000	0-0	0-0
396	86	100025	20.5	Kg	4600	94300	0-0	0-0
397	86	100030	124	Kg	6000	744000	0-0	0-0
398	86	100007	25	Kg	2700	67500	0-0	0-0
399	86	100006	128	Kg	5700	729600	0-0	0-0
400	86	100015	61	Kg	2500	152500	12-930	12-930
401	87	100002	1450.5	Kg	5500	7977750	10-165	10-165
402	87	100015	322.5	Kg	2500	806250	12-930	12-930
403	88	100002	500	Kg	5500	2750000	10-165	10-165
404	88	100006	150	Kg	5700	855000	0-0	0-0
405	88	100007	135.5	Kg	2700	365850	0-0	0-0
406	89	100002	189.5	Kg	5000	947500	0-0	0-0
407	89	100005	135	Kg	4200	567000	0-0	0-0
408	89	100006	124.5	Kg	5700	709650	0-0	0-0
409	90	100002	183	Kg	5000	915000	0-0	0-0
410	90	100025	20	Kg	4600	92000	0-0	0-0
411	90	100030	25	Kg	7000	175000	23-138	23-138
412	90	100006	198	Kg	5700	1128600	0-0	0-0
413	91	100002	1161.5	Kg	5500	6388250	10-165	10-165
414	91	100015	241	Kg	2500	602500	12-930	12-930
415	92	200075	0.5	Caja	2950000	1475000	0-0	0-0
416	92	200007	16	Kg	3700	59200	0-0	0-0
417	92	200068	36	Kg	64	2304	0-0	0-0
418	92	200069	4	Kg	2800	11200	0-0	0-0
419	92	200035	10	Kg	9687.5	96875	0-0	0-0
420	92	200036	4	Kg	14100	56400	0-0	0-0
421	92	200008	4	Kg	14900	59600	0-0	0-0
422	92	200038	4	Kg	9300	37200	0-0	0-0
423	92	200003	10	Kg	12490	124900	0-0	0-0
424	92	200001	3.60000000000000009	Kg	16.2199999999999989	58.3919999999999959	0-0	0-0
425	92	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
426	92	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
427	92	200005	187.5	Kg	4600	862500	0-0	0-0
428	92	200065	150	Kg	17798	2669700	0-0	0-0
429	92	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
430	92	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
431	92	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
432	92	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
433	93	200007	2	Kg	3700	7400	0-0	0-0
434	93	200068	10	Kg	64	640	0-0	0-0
435	93	200069	1	Kg	2800	2800	0-0	0-0
436	93	200036	0.5	Kg	14100	7050	0-0	0-0
437	93	200003	2.5	Kg	12490	31225	0-0	0-0
438	93	200008	0.100000000000000006	Kg	14900	1490	0-0	0-0
439	93	200038	0.100000000000000006	Kg	9300	930	0-0	0-0
440	93	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
441	93	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
443	93	200065	20	Kg	17798	355960	0-0	0-0
444	93	200005	25	Kg	4600	115000	0-0	0-0
445	93	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
446	93	200061	0.400000000000000022	Kg	9000	3600	0-0	0-0
447	93	200056	0.0100000000000000002	Kg	166195	1661.95000000000005	0-0	0-0
448	93	200035	0.200000000000000011	Kg	9687.5	1937.5	0-0	0-0
449	93	200013	0.849999999999999978	Caja	1383000	1175550	0-0	0-0
450	93	200015	0.0100000000000000002	Caja	1750000	17500	0-0	0-0
541	99	200028	0.0050000000000000001	Kg	90000	450	0-0	0-0
442	93	200028	0.0050000000000000001	Kg	90000	450	0-0	0-0
451	94	200082	100	.	2835	283500	0-0	0-0
452	94	200051	100	Unidad	40	4000	0-0	0-0
453	94	200007	1.39999999999999991	Kg	3700	5180	0-0	0-0
454	94	200068	11	Kg	64	704	0-0	0-0
455	94	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
456	94	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
457	94	200008	1	Kg	14900	14900	0-0	0-0
458	94	200038	1	Kg	9300	9300	0-0	0-0
459	94	200003	2.5	Kg	12490	31225	0-0	0-0
460	94	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
461	94	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
462	94	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
463	94	200058	0.100000000000000006	Kg	451416	45141.6000000000058	0-0	0-0
464	94	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
465	94	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
467	94	200005	37.5	Kg	4600	172500	0-0	0-0
468	94	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
469	95	200007	0.699999999999999956	Kg	3700	2590	0-0	0-0
470	95	200007	3.79999999999999982	Kg	2800	10640	2-3455	7-3455
471	95	200068	11	Kg	64	704	0-0	0-0
472	95	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
473	95	200008	1	Kg	14900	14900	0-0	0-0
474	95	200038	1	Kg	9300	9300	0-0	0-0
475	95	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
476	95	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
477	95	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
478	95	200065	20	Kg	17798	355960	0-0	0-0
479	95	200005	25	Kg	4600	115000	0-0	0-0
480	95	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
481	95	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
482	95	200003	2.5	Kg	12490	31225	0-0	0-0
483	95	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
466	94	200065	40	Kg	17798	711920	0-0	0-0
484	96	200007	8	Kg	2800	22400	2-3455	7-3455
485	96	200068	18	Kg	64	1152	0-0	0-0
486	96	200069	2	Kg	2800	5600	0-0	0-0
487	96	200008	2	Kg	14900	29800	0-0	0-0
488	96	200038	2	Kg	9300	18600	0-0	0-0
489	96	200035	3	Kg	9687.5	29062.5	0-0	0-0
490	96	200003	5	Kg	12490	62450	0-0	0-0
491	96	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
492	96	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
493	96	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
494	96	200060	0.0500000000000000028	Kg	647948	32397.4000000000015	0-0	0-0
495	96	200056	0.0100000000000000002	Kg	166195	1661.95000000000005	0-0	0-0
496	96	200057	0.0500000000000000028	Kg	522453	26122.6500000000015	0-0	0-0
497	96	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
498	96	200065	20	Kg	17798	355960	0-0	0-0
499	96	200047	60	Kg	5100	306000	31-3025	31-3025
500	96	200005	100	Kg	4600	460000	0-0	0-0
501	96	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
502	96	200085	1	Caja	1091200	1091200	0-0	0-0
503	97	200074	420	Metro	1780.42000000000007	747776.400000000023	0-0	0-0
504	97	200007	4	Kg	2800	11200	2-3455	7-3455
505	97	200068	22	Kg	64	1408	0-0	0-0
506	97	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
507	97	200008	2	Kg	14900	29800	0-0	0-0
508	97	200038	2	Kg	9300	18600	0-0	0-0
509	97	200003	5	Kg	12490	62450	0-0	0-0
510	97	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
511	97	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
512	97	200035	5	Kg	9687.5	48437.5	0-0	0-0
513	97	200065	80	Kg	17798	1423840	0-0	0-0
514	97	200005	75	Kg	4600	345000	0-0	0-0
515	97	200057	0.200000000000000011	Kg	522453	104490.600000000006	0-0	0-0
516	97	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
517	97	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
518	98	200007	4.5	Kg	2800	12600	2-3455	7-3455
519	98	200068	11	Kg	64	704	0-0	0-0
520	98	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
521	98	200008	1	Kg	14900	14900	0-0	0-0
522	98	200038	1	Kg	9300	9300	0-0	0-0
523	98	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
524	98	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
525	98	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
526	98	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
527	98	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
528	98	200003	2.5	Kg	12490	31225	0-0	0-0
529	98	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
530	98	200065	20	Kg	17798	355960	0-0	0-0
531	98	200005	25	Kg	4600	115000	0-0	0-0
532	99	200007	2	Kg	2800	5600	2-3455	7-3455
533	99	200068	10	Kg	64	640	0-0	0-0
534	99	200069	1	Kg	2800	2800	0-0	0-0
535	99	200036	0.5	Kg	14100	7050	0-0	0-0
536	99	200008	1	Kg	14900	14900	0-0	0-0
537	99	200038	1	Kg	9300	9300	0-0	0-0
538	99	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
539	99	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
540	99	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
542	99	200003	2.5	Kg	12490	31225	0-0	0-0
543	99	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
544	99	200061	0.400000000000000022	Kg	9000	3600	0-0	0-0
545	99	200065	20	Kg	17798	355960	0-0	0-0
546	99	200005	25	Kg	4600	115000	0-0	0-0
547	100	200007	1	Kg	2800	2800	2-3455	7-3455
548	100	200068	4.79999999999999982	Kg	64	307.199999999999989	0-0	0-0
549	100	200069	0.5	Kg	2800	1400	0-0	0-0
550	100	200035	1	Kg	9687.5	9687.5	0-0	0-0
551	100	200008	0.400000000000000022	Kg	14900	5960	0-0	0-0
552	100	200038	0.400000000000000022	Kg	9300	3720	0-0	0-0
553	100	200036	0.160000000000000003	Kg	14100	2256	0-0	0-0
554	100	200003	1	Kg	12490	12490	0-0	0-0
555	100	200001	0.560000000000000053	Kg	16.2199999999999989	9.08319999999999972	0-0	0-0
556	100	200029	0.239999999999999991	Kg	27.5700000000000003	6.61679999999999957	0-0	0-0
558	100	200005	3.75	Kg	4600	17250	0-0	0-0
559	100	200004	11.25	Kg	10000	112500	0-0	0-0
560	100	200047	4	Kg	5100	20400	31-3025	31-3025
561	100	200065	12	Kg	17798	213576	0-0	0-0
562	100	200058	0.0400000000000000008	Kg	451416	18056.6399999999994	0-0	0-0
640	110	100002	276.5	Kg	5000	1382500	0-0	0-0
557	100	200028	0.0050000000000000001	Kg	90000	450	0-0	0-0
563	101	200013	0.400000000000000022	Caja	1383000	553200	0-0	0-0
564	101	200010	1	Bulto	62105	62105	0-0	0-0
565	102	100002	214	Kg	5000	1070000	0-0	0-0
566	102	100005	119	Kg	4200	499800	0-0	0-0
567	102	100006	125	Kg	5700	712500	0-0	0-0
568	103	100002	487	Kg	5000	2435000	0-0	0-0
569	104	100002	812	Kg	5000	4060000	0-0	0-0
570	105	200075	1	Caja	2950000	2950000	0-0	0-0
571	105	200007	16	Kg	2800	44800	2-3455	7-3455
572	105	200068	36	Kg	64	2304	0-0	0-0
573	105	200069	4	Kg	2800	11200	0-0	0-0
574	105	200008	4	Kg	14900	59600	0-0	0-0
575	105	200038	4	Kg	9300	37200	0-0	0-0
576	105	200003	10	Kg	12490	124900	0-0	0-0
577	105	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
578	105	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
579	105	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
580	105	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
581	105	200065	40	Kg	17798	711920	0-0	0-0
582	105	200005	200	Kg	4600	920000	0-0	0-0
583	105	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
584	105	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
585	105	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
586	105	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
587	105	200047	120	Kg	5100	612000	31-3025	31-3025
588	105	200035	10	Kg	9687.5	96875	0-0	0-0
589	106	200007	2	Kg	2800	5600	2-3455	7-3455
590	106	200068	10	Kg	64	640	0-0	0-0
591	106	200069	1	Kg	2800	2800	0-0	0-0
592	106	200036	0.5	Kg	14100	7050	0-0	0-0
593	106	200003	2.5	Kg	12490	31225	0-0	0-0
594	106	200035	2	Kg	9687.5	19375	0-0	0-0
595	106	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
596	106	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
598	106	200065	20	Kg	17798	355960	0-0	0-0
599	106	200005	25	Kg	4600	115000	0-0	0-0
600	106	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
601	106	200061	0.5	Kg	9000	4500	0-0	0-0
602	106	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
603	106	200008	1	Kg	14900	14900	0-0	0-0
604	106	200038	1	Kg	9300	9300	0-0	0-0
641	110	100006	28.5	Kg	5700	162450	0-0	0-0
597	106	200028	0.0050000000000000001	Kg	90000	450	0-0	0-0
605	107	200007	4.5	Kg	2800	12600	2-3455	7-3455
606	107	200068	11	Kg	64	704	0-0	0-0
607	107	200069	1.19999999999999996	Kg	2800	3360	0-0	0-0
608	107	200003	2.5	Kg	12490	31225	0-0	0-0
609	107	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
610	107	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
611	107	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
612	107	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
613	107	200065	20	Kg	17798	355960	0-0	0-0
614	107	200005	25	Kg	4600	115000	0-0	0-0
615	107	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
616	107	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
617	107	200008	1	Kg	14900	14900	0-0	0-0
618	107	200038	1	Kg	9300	9300	0-0	0-0
619	108	200068	22	Kg	64	1408	0-0	0-0
620	108	200007	5	Kg	2800	14000	2-3455	7-3455
621	108	200035	5	Kg	9687.5	48437.5	0-0	0-0
622	108	200038	2	Kg	9300	18600	0-0	0-0
623	108	200008	2	Kg	14900	29800	0-0	0-0
624	108	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
625	108	200069	2.5	Kg	2800	7000	0-0	0-0
626	108	200058	0.200000000000000011	Kg	451416	90283.2000000000116	0-0	0-0
627	108	200003	5	Kg	12490	62450	0-0	0-0
628	108	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
629	108	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
630	108	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
631	108	200047	40	Kg	5100	204000	31-3025	31-3025
632	108	200065	40	Kg	17798	711920	0-0	0-0
633	108	200005	37.5	Kg	4600	172500	0-0	0-0
634	108	200004	37.5	Kg	10000	375000	0-0	0-0
635	109	200007	5	Kg	2800	14000	2-3455	7-3455
636	109	200008	1	Kg	14900	14900	0-0	0-0
637	109	200068	25	Kg	64	1600	0-0	0-0
638	109	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
639	109	200049	1.5	Kg	61000	91500	0-0	0-0
642	110	100003	79	Kg	3600	284400	26-598	26-598
643	111	100002	180	Kg	5000	900000	0-0	0-0
644	111	100003	55	Kg	3600	198000	26-598	26-598
645	111	100006	136	Kg	5700	775200	0-0	0-0
646	111	100029	47	Kg	6200	291400	0-0	0-0
647	113	100015	8	Kg	2500	20000	12-931	12-931
648	113	100036	8	Kg	3000	24000	0-0	0-0
649	113	100003	20	Kg	3600	72000	26-598	26-598
650	113	100002	34	Kg	5000	170000	0-0	0-0
651	114	100015	8	Kg	2500	20000	12-931	12-931
652	114	100036	8	Kg	3000	24000	0-0	0-0
653	114	100003	20	Kg	3600	72000	26-598	26-598
654	114	100030	17	Kg	6000	102000	0-0	0-0
655	114	100006	17	Kg	5700	96900	0-0	0-0
656	115	100015	2125	Kg	2500	5312500	12-931	12-931
657	115	100002	752.5	Kg	5000	3762500	0-0	0-0
658	115	100002	248.5	Kg	5500	1366750	10-165	10-165
659	116	100002	341	Kg	5500	1875500	10-165	10-165
660	116	100015	80	Kg	2500	200000	12-931	12-931
661	116	100036	83	Kg	3000	249000	0-0	0-0
662	116	100003	200	Kg	3600	720000	26-598	26-598
663	117	100002	196	Kg	5500	1078000	10-165	10-165
664	117	100005	120	Kg	4200	504000	0-0	0-0
665	117	100006	135	Kg	5700	769500	0-0	0-0
666	118	100002	171.5	Kg	5500	943250	10-165	10-165
667	118	100003	55	Kg	3600	198000	26-598	26-598
668	118	100032	46	Kg	6000	276000	0-0	0-0
669	118	100006	140	Kg	5700	798000	0-0	0-0
670	119	100015	215.5	Kg	2500	538750	12-931	12-931
671	119	100002	988	Kg	5500	5434000	10-168	10-168
672	120	100002	555.5	Kg	5500	3055250	10-165	10-165
673	120	100002	128	Kg	5500	704000	10-168	10-168
674	120	100015	160	Kg	2500	400000	12-931	12-931
675	120	100003	399.5	Kg	3600	1438200	26-598	26-598
676	120	100036	162.5	Kg	3000	487500	0-0	0-0
677	121	100002	684	Kg	5500	3762000	10-168	10-168
678	121	100015	160	Kg	2500	400000	12-931	12-931
679	121	100003	399.5	Kg	3600	1438200	26-598	26-598
680	121	100036	160	Kg	3000	480000	0-0	0-0
681	122	200068	16	Kg	64	1024	0-0	0-0
682	122	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
683	122	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
684	122	200003	6.5	Kg	12490	81185	0-0	0-0
685	122	200008	1	Kg	14900	14900	0-0	0-0
686	122	200038	1.39999999999999991	Kg	9300	13020	0-0	0-0
687	122	200065	15	Kg	17798	266970	0-0	0-0
688	122	200004	30	Kg	10000	300000	0-0	0-0
689	122	200031	0.0700000000000000067	Kg	100352	7024.64000000000033	0-0	0-0
690	122	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
691	122	200007	7	Kg	2800	19600	2-3455	7-3455
692	122	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
693	122	200028	1.39999999999999991	Kg	90000	125999.999999999985	0-0	0-0
694	123	200007	16	Kg	2800	44800	2-3455	7-3455
695	123	200068	36	Kg	64	2304	0-0	0-0
696	123	200069	4	Kg	2800	11200	0-0	0-0
697	123	200008	4	Kg	14900	59600	0-0	0-0
698	123	200038	4	Kg	9300	37200	0-0	0-0
699	123	200003	10	Kg	12490	124900	0-0	0-0
700	123	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
701	123	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
702	123	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
703	123	200035	10	Kg	9687.5	96875	0-0	0-0
704	123	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
705	123	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
706	123	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
707	123	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
708	123	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
709	123	200065	40	Kg	17798	711920	0-0	0-0
710	123	200005	100	Kg	4600	460000	0-0	0-0
711	123	200004	100	Kg	10000	1000000	0-0	0-0
712	123	200047	170	Kg	5100	867000	31-3025	31-3025
713	124	200080	812.5	Metro	1680	1365000	0-0	0-0
714	124	200092	100	Metro	1480	148000	5-304	17-304
715	124	200007	10	Kg	2800	28000	2-3455	7-3455
716	124	200068	44	Kg	64	2816	0-0	0-0
717	124	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
718	124	200003	10	Kg	12490	124900	0-0	0-0
719	124	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
720	124	200008	4	Kg	14900	59600	0-0	0-0
721	124	200038	4	Kg	9300	37200	0-0	0-0
722	124	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
723	124	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
724	124	200035	10	Kg	9687.5	96875	0-0	0-0
725	124	200065	80	Kg	23900	1912000	34-470	34-470
726	124	200005	75	Kg	4600	345000	0-0	0-0
727	124	200004	75	Kg	10000	750000	0-0	0-0
728	124	200058	0.400000000000000022	Kg	451416	180566.400000000023	0-0	0-0
729	124	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
730	124	200047	80	Kg	5100	408000	31-3025	31-3025
731	125	200068	37.5	Kg	64	2400	0-0	0-0
732	125	200008	1	Kg	14900	14900	0-0	0-0
733	125	200069	4.5	Kg	2800	12600	0-0	0-0
734	125	200035	15	Kg	9687.5	145312.5	0-0	0-0
735	125	200036	0.5	Kg	14100	7050	0-0	0-0
736	125	200065	10	Kg	17798	177980	0-0	0-0
737	125	200007	15	Kg	2800	42000	2-3455	7-3455
738	126	200069	1	Kg	2800	2800	0-0	0-0
739	126	200049	1	Kg	61000	61000	0-0	0-0
740	127	200010	4	Bulto	62105	248420	0-0	0-0
741	127	200051	4000	Unidad	40	160000	0-0	0-0
742	127	200077	160	Metro	3200	512000	0-0	0-0
743	127	200078	240	Metro	2620	628800	0-0	0-0
744	127	200076	100	Metro	2770	277000	0-0	0-0
745	128	200068	26	Kg	64	1664	0-0	0-0
746	128	200007	7	Kg	2800	19600	2-3455	7-3455
747	128	200003	13	Kg	12490	162370	0-0	0-0
748	128	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
749	128	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
750	128	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
751	128	200031	0.100000000000000006	Kg	100352	10035.2000000000007	0-0	0-0
752	128	200008	1.60000000000000009	Kg	14900	23840	0-0	0-0
753	128	200038	2.79999999999999982	Kg	9300	26040	0-0	0-0
754	128	200035	9	Kg	9687.5	87187.5	0-0	0-0
755	128	200004	100	Kg	10000	1000000	0-0	0-0
756	128	200065	30	Kg	17798	533940	0-0	0-0
757	128	200069	4	Kg	2800	11200	0-0	0-0
758	128	200049	3	Kg	61000	183000	0-0	0-0
759	129	200068	26	Kg	64	1664	0-0	0-0
760	129	200007	7	Kg	2800	19600	2-3455	7-3455
761	129	200003	13	Kg	12490	162370	0-0	0-0
762	129	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
763	129	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
764	129	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
765	129	200031	0.100000000000000006	Kg	100352	10035.2000000000007	0-0	0-0
766	129	200008	1.60000000000000009	Kg	14900	23840	0-0	0-0
767	129	200038	2.79999999999999982	Kg	9300	26040	0-0	0-0
768	129	200035	9	Kg	9687.5	87187.5	0-0	0-0
769	129	200004	100	Kg	10000	1000000	0-0	0-0
770	129	200065	30	Kg	17798	533940	0-0	0-0
771	129	200069	4	Kg	2800	11200	0-0	0-0
772	130	200068	16	Kg	64	1024	0-0	0-0
773	130	200007	7	Kg	2800	19600	2-3455	7-3455
774	130	200032	6.5	Kg	12900	83850	0-0	0-0
775	130	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
776	130	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
777	130	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
779	130	200008	1	Kg	14900	14900	0-0	0-0
780	130	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
781	130	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
782	130	200004	50	Kg	10000	500000	0-0	0-0
783	130	200065	20	Kg	23900	478000	34-470	34-470
784	130	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
778	130	200031	0.0749999999999999972	Kg	100352	7024.64000000000033	0-0	0-0
785	131	200080	312.5	Metro	1680	525000	0-0	0-0
786	131	200092	100	Metro	1480	148000	5-304	17-304
787	131	200068	22	Kg	64	1408	0-0	0-0
788	131	200007	5	Kg	2800	14000	2-3455	7-3455
789	131	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
790	131	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
791	131	200003	5	Kg	12490	62450	0-0	0-0
792	131	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
793	131	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
794	131	200035	5	Kg	9687.5	48437.5	0-0	0-0
795	131	200008	2	Kg	14900	29800	0-0	0-0
796	131	200038	2	Kg	9300	18600	0-0	0-0
797	131	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
798	131	200005	75	Kg	4600	345000	0-0	0-0
799	131	200004	75	Kg	10000	750000	0-0	0-0
800	131	200058	0.400000000000000022	Kg	451416	180566.400000000023	0-0	0-0
801	131	200065	80	Kg	23900	1912000	34-470	34-470
802	131	200047	80	Kg	5100	408000	31-3025	31-3025
803	132	200068	10	Kg	64	640	0-0	0-0
804	132	200035	1	Kg	9687.5	9687.5	0-0	0-0
805	132	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
806	133	200068	22	Kg	64	1408	0-0	0-0
807	133	200069	2.39999999999999991	Kg	2800	6720	0-0	0-0
808	133	200035	5	Kg	9687.5	48437.5	0-0	0-0
809	133	200007	2.79999999999999982	Kg	2800	7839.99999999999909	2-3455	7-3455
810	133	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
811	133	200003	5	Kg	12490	62450	0-0	0-0
812	133	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
813	133	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
814	133	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
815	133	200008	2	Kg	14900	29800	0-0	0-0
816	133	200038	2	Kg	9300	18600	0-0	0-0
817	133	200058	0.200000000000000011	Kg	451416	90283.2000000000116	0-0	0-0
818	133	200005	75	Kg	4600	345000	0-0	0-0
819	133	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
820	133	200055	0.0599999999999999978	Kg	99825	5989.5	0-0	0-0
821	134	200080	312.5	Metro	1680	525000	0-0	0-0
822	134	200068	22	Kg	64	1408	0-0	0-0
823	134	200069	2.39999999999999991	Kg	2800	6720	0-0	0-0
824	134	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
825	134	200007	5	Kg	2800	14000	2-3455	7-3455
826	134	200035	34	Kg	9687.5	329375	0-0	0-0
827	134	200008	2	Kg	14900	29800	0-0	0-0
828	134	200038	2	Kg	9300	18600	0-0	0-0
829	134	200003	2.5	Kg	12490	31225	0-0	0-0
830	134	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
831	134	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
832	134	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
833	134	200005	37.5	Kg	4600	172500	0-0	0-0
834	134	200047	40	Kg	5100	204000	31-3025	31-3025
835	134	200065	40	Kg	23900	956000	34-468	34-468
836	135	200074	365	Metro	1780.42000000000007	649853.300000000047	0-0	0-0
837	135	200068	22	Kg	64	1408	0-0	0-0
838	135	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
839	135	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
840	135	200007	6	Kg	2800	16800	2-3455	7-3455
841	135	200008	2	Kg	14900	29800	0-0	0-0
842	135	200038	2	Kg	9300	18600	0-0	0-0
843	135	200003	5	Kg	12490	62450	0-0	0-0
844	135	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
845	135	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
846	135	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
847	135	200057	0.200000000000000011	Kg	522453	104490.600000000006	0-0	0-0
848	135	200035	5	Kg	9687.5	48437.5	0-0	0-0
849	135	200005	75	Kg	4600	345000	0-0	0-0
850	135	200065	80	Kg	23900	1912000	34-468	34-468
851	136	200068	11	Kg	64	704	0-0	0-0
852	136	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
853	136	200007	2	Kg	2800	5600	2-3455	7-3455
854	136	200035	2	Kg	9687.5	19375	0-0	0-0
855	136	200008	1	Kg	14900	14900	0-0	0-0
856	136	200038	1	Kg	9300	9300	0-0	0-0
857	136	200061	0.5	Kg	9000	4500	0-0	0-0
858	136	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
859	136	200003	2.5	Kg	12490	31225	0-0	0-0
860	136	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
861	136	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
862	136	200065	20	Kg	23900	478000	34-468	34-468
863	136	200005	25	Kg	4600	115000	0-0	0-0
864	136	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
865	136	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
866	136	200036	0.5	Kg	14100	7050	0-0	0-0
867	137	200068	16	Kg	64	1024	0-0	0-0
868	137	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
869	137	200007	7	Kg	2800	19600	2-3455	7-3455
870	137	200031	0.0700000000000000067	Kg	100352	7024.64000000000033	0-0	0-0
871	137	200065	15	Kg	23900	358500	34-468	34-468
872	137	200001	0.599999999999999978	Kg	16.2199999999999989	9.73199999999999932	0-0	0-0
873	137	200029	1.39999999999999991	Kg	27.5700000000000003	38.597999999999999	0-0	0-0
874	137	200032	6.5	Kg	12900	83850	0-0	0-0
875	137	200008	1.39999999999999991	Kg	14900	20860	0-0	0-0
876	137	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
877	137	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
878	137	200005	50	Kg	4600	230000	0-0	0-0
879	138	200068	36	Kg	64	2304	0-0	0-0
880	138	200069	4	Kg	2800	11200	0-0	0-0
881	138	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
882	138	200007	16	Kg	2800	44800	2-3455	7-3455
883	138	200008	4	Kg	14900	59600	0-0	0-0
884	138	200038	4	Kg	9300	37200	0-0	0-0
885	138	200003	10	Kg	12490	124900	0-0	0-0
886	138	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
887	138	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
888	138	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
889	138	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
890	138	200057	0.100000000000000006	Kg	522453	52245.3000000000029	0-0	0-0
891	138	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
892	138	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
893	138	200065	40	Kg	23900	956000	34-468	34-468
894	138	200005	100	Kg	4600	460000	0-0	0-0
895	138	200047	100	Kg	5100	510000	31-3025	31-3025
896	138	200035	10	Kg	9687.5	96875	0-0	0-0
897	139	200068	10	Kg	64	640	0-0	0-0
898	139	200007	1.5	Kg	2800	4200	2-3455	7-3455
899	139	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
900	139	200069	1.5	Kg	2800	4200	0-0	0-0
901	139	200035	2.29999999999999982	Kg	9687.5	22281.25	0-0	0-0
902	139	200009	0.5	Bulto	62105	31052.5	0-0	0-0
903	139	200041	0.5	Caja	1837500	918750	0-0	0-0
904	139	200075	1	Caja	2950000	2950000	0-0	0-0
905	139	200085	1	Caja	1091200	1091200	0-0	0-0
906	140	100002	182	Kg	5500	1001000	10-168	10-168
907	140	100003	55	Kg	3600	198000	26-598	26-598
908	140	100032	20	Kg	6000	120000	0-0	0-0
909	140	100006	140	Kg	5700	798000	0-0	0-0
910	141	100002	800	Kg	5500	4400000	10-168	10-168
911	142	100025	20	Kg	4600	92000	0-0	0-0
912	142	100015	60	Kg	2500	150000	12-931	12-931
913	142	100006	121	Kg	3600	435600	12-931	12-931
914	142	100030	120	Kg	6000	720000	0-0	0-0
915	143	100002	488	Kg	5500	2684000	10-168	10-168
916	143	100003	180	Kg	3600	648000	26-598	26-598
917	143	100006	114.5	Kg	5700	652650	0-0	0-0
918	144	100002	137	Kg	5500	753500	10-168	10-168
919	144	100015	172	Kg	2500	430000	12-931	12-931
920	145	100002	338	Kg	5500	1859000	10-168	10-168
921	145	100003	202	Kg	3600	727200	26-598	26-598
922	145	100036	80.5	Kg	3000	241500	0-0	0-0
923	146	100003	392	Kg	3600	1411200	26-598	26-598
924	140	100031	20	Kg	3800	76000	0-0	0-0
926	138	200004	100	Kg	7900	790000	39-691	39-691
927	147	100002	2	Kg	5500	11000	10-168	10-168
928	147	100015	15	Kg	2500	37500	12-930	12-930
929	148	100002	2	Kg	5500	11000	10-168	10-168
930	148	100015	15	Kg	2500	37500	12-931	12-931
931	148	100036	36	Kg	3000	108000	0-0	0-0
932	149	200068	18	Kg	64	1152	0-0	0-0
933	149	200007	8	Kg	2800	22400	2-3455	7-3455
934	149	200069	2	Kg	2800	5600	0-0	0-0
935	149	200035	3	Kg	9687.5	29062.5	0-0	0-0
936	149	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
937	149	200008	2	Kg	14900	29800	0-0	0-0
938	149	200038	2	Kg	9300	18600	0-0	0-0
939	149	200003	5	Kg	12490	62450	0-0	0-0
940	149	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
941	149	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
942	149	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
943	149	200060	0.0500000000000000028	Kg	647948	32397.4000000000015	0-0	0-0
944	149	200056	0.0100000000000000002	Kg	166195	1661.95000000000005	0-0	0-0
945	149	200057	0.25	Kg	522453	130613.25	0-0	0-0
946	149	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
947	149	200065	20	Kg	23900	478000	34-470	34-470
948	149	200005	50	Kg	7980	399000	32-3934	32-3934
949	149	200004	50	Kg	7900	395000	39-691	39-691
950	149	200047	60	Kg	5100	306000	31-3025	31-3025
951	150	200068	10	Kg	64	640	0-0	0-0
952	150	200069	2	Kg	2800	5600	0-0	0-0
953	150	200007	2	Kg	2800	5600	2-3455	7-3455
954	150	200035	2	Kg	9687.5	19375	0-0	0-0
955	150	200036	0.5	Kg	14100	7050	0-0	0-0
956	150	200008	1	Kg	14900	14900	0-0	0-0
957	150	200038	1	Kg	9300	9300	0-0	0-0
958	150	200003	2.5	Kg	12490	31225	0-0	0-0
959	150	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
960	150	200028	0.599999999999999978	Kg	90000	54000	0-0	0-0
961	150	200029	0.0500000000000000028	Kg	27.5700000000000003	1.37850000000000006	0-0	0-0
962	150	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
963	150	200062	0.0100000000000000002	Kg	42000	420	0-0	0-0
964	150	200061	0.0500000000000000028	Kg	8500	425	31-3025	31-3025
965	150	200065	20	Kg	23900	478000	34-473	34-473
966	150	200005	25	Kg	4600	115000	0-0	0-0
967	151	200080	250	Metro	1680	420000	0-0	0-0
968	151	200092	300	Metro	1480	444000	5-304	17-304
969	151	200068	33	Kg	64	2112	0-0	0-0
970	151	200069	3.89999999999999991	Kg	2800	10920	0-0	0-0
971	151	200007	7.5	Kg	2800	21000	2-3455	7-3455
972	151	200035	7.5	Kg	9687.5	72656.25	0-0	0-0
973	151	200036	1.19999999999999996	Kg	14100	16920	0-0	0-0
974	151	200008	3	Kg	14900	44700	0-0	0-0
975	151	200038	3	Kg	9300	27900	0-0	0-0
976	151	200003	7.5	Kg	12490	93675	0-0	0-0
977	151	200001	4.20000000000000018	Kg	16.2199999999999989	68.1239999999999952	0-0	0-0
978	151	200029	1.80000000000000004	Kg	27.5700000000000003	49.6260000000000048	0-0	0-0
979	151	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
980	151	200058	0.299999999999999989	Kg	451416	135424.799999999988	0-0	0-0
981	151	200065	60	Kg	23900	1434000	34-473	34-473
982	151	200005	37.5	Kg	4600	172500	0-0	0-0
983	151	200004	37.5	Kg	7900	296250	39-691	39-691
984	151	200047	60	Kg	5100	306000	31-3025	31-3025
985	152	200068	16	Kg	64	1024	0-0	0-0
986	152	200007	7	Kg	2800	19600	2-3455	7-3455
987	152	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
988	152	200035	6.5	Kg	9687.5	62968.75	0-0	0-0
989	152	200008	1.39999999999999991	Kg	14900	20860	0-0	0-0
990	152	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
991	152	200032	6.5	Kg	12900	83850	0-0	0-0
992	152	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
993	152	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
994	152	200031	0.0899999999999999967	Kg	100352	9031.68000000000029	0-0	0-0
995	152	200065	15	Kg	23900	358500	34-473	34-473
996	152	200004	50	Kg	7900	395000	39-691	39-691
997	153	200068	32	Kg	64	2048	0-0	0-0
998	153	200007	14	Kg	2800	39200	2-3455	7-3455
999	153	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1000	153	200035	9	Kg	9687.5	87187.5	0-0	0-0
1001	153	200008	2.79999999999999982	Kg	14900	41720	0-0	0-0
1002	153	200038	3.20000000000000018	Kg	9300	29760	0-0	0-0
1003	153	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1004	153	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1005	153	200031	0.0100000000000000002	Kg	100352	1003.51999999999998	0-0	0-0
1006	153	200004	100	Kg	7900	790000	39-691	39-691
1007	153	200003	13	Kg	12490	162370	0-0	0-0
1008	153	200065	30	Kg	23900	717000	34-473	34-473
1016	155	100037	236.5	Kg	6750	1596375	0-0	0-0
925	133	200065	55	Kg	23900	1314500	34-468	34-468
1010	133	200065	25	Kg	23900	597500	34-473	34-473
1011	154	100002	174.5	Kg	5500	959750	10-168	10-168
1012	154	100003	65	Kg	3600	234000	26-598	26-598
1013	154	100031	35	Kg	3800	133000	0-0	0-0
1014	154	100006	75	Kg	5700	427500	0-0	0-0
1015	154	100030	70	Kg	6000	420000	0-0	0-0
1017	155	100003	93	Kg	3600	334800	26-598	26-598
1018	155	100006	63.5	Kg	3600	228600	12-931	12-931
1019	156	100015	115.5	Kg	2500	288750	12-930	12-930
1020	156	100002	286	Kg	5500	1573000	10-168	10-168
1021	157	100002	200	Kg	5500	1100000	10-168	10-168
1022	157	100005	119.5	Kg	4200	501900	0-0	0-0
1023	157	100006	125	Kg	5700	712500	0-0	0-0
1024	158	200068	54	Kg	64	3456	0-0	0-0
1025	158	200069	6	Kg	2800	16800	0-0	0-0
1026	158	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1027	158	200035	4	Kg	9687.5	38750	0-0	0-0
1028	158	200007	24	Kg	2800	67200	2-3455	7-3455
1029	158	200008	6	Kg	14900	89400	0-0	0-0
1030	158	200038	6	Kg	9300	55800	0-0	0-0
1031	158	200003	15	Kg	12490	187350	0-0	0-0
1032	158	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
1033	158	200029	5.59999999999999964	Kg	27.5700000000000003	154.391999999999996	0-0	0-0
1034	158	200028	1.60000000000000009	Kg	90000	144000	0-0	0-0
1035	158	200060	0.5	Kg	647948	323974	0-0	0-0
1036	158	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
1037	158	200059	0.149999999999999994	Kg	304618	45692.6999999999971	0-0	0-0
1038	158	200065	60	Kg	23900	1434000	34-473	34-473
1039	158	200005	150	Kg	4600	690000	0-0	0-0
1040	158	200004	150	Kg	7900	1185000	39-691	39-691
1041	158	200047	180	Kg	5100	918000	31-3025	31-3025
1042	158	200057	0.0899999999999999967	Kg	565230	50870.6999999999971	3-15102	8-15102
1043	158	200085	0.5	Caja	1091200	545600	0-0	0-0
1044	159	200068	11	Kg	64	704	0-0	0-0
1045	159	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1046	159	200007	1.39999999999999991	Kg	2800	3919.99999999999955	2-3455	7-3455
1047	159	200003	2.5	Kg	12490	31225	0-0	0-0
1048	159	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1049	159	200008	1	Kg	14900	14900	0-0	0-0
1050	159	200038	1	Kg	9300	9300	0-0	0-0
1051	159	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1052	159	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1053	159	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1055	159	200005	37.5	Kg	4600	172500	0-0	0-0
1054	159	200058	0.100000000000000006	Kg	451416	45141.6000000000058	0-0	0-0
1056	159	200065	40	Kg	23900	956000	34-473	34-473
1057	160	200068	11	Kg	64	704	0-0	0-0
1058	160	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1059	160	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1060	160	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1061	160	200003	2.5	Kg	12490	31225	0-0	0-0
1062	160	200008	1	Kg	14900	14900	0-0	0-0
1063	160	200038	1	Kg	9300	9300	0-0	0-0
1064	160	200007	4.5	Kg	2800	12600	2-3455	7-3455
1065	160	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1066	160	200028	0.400000000000000022	Kg	90000	36000	0-0	0-0
1067	160	200029	0.0299999999999999989	Kg	27.5700000000000003	0.827099999999999946	0-0	0-0
1068	160	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1069	160	200005	25	Kg	4600	115000	0-0	0-0
1070	160	200065	20	Kg	23900	478000	34-473	34-473
1071	161	200068	26	Kg	64	1664	0-0	0-0
1072	161	200007	7	Kg	2800	19600	2-3455	7-3455
1073	161	200008	2.79999999999999982	Kg	14900	41720	0-0	0-0
1074	161	200038	3.20000000000000018	Kg	9300	29760	0-0	0-0
1075	161	200035	13	Kg	9687.5	125937.5	0-0	0-0
1076	161	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1077	161	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1078	161	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1079	161	200003	13	Kg	12490	162370	0-0	0-0
1080	161	200031	0.0100000000000000002	Kg	100352	1003.51999999999998	0-0	0-0
1081	161	200065	30	Kg	23900	717000	34-473	34-473
1082	161	200004	100	Kg	11200	1120000	49-4243	49-4243
1083	161	200069	4	Kg	2800	11200	0-0	0-0
1084	162	200068	16	Kg	64	1024	0-0	0-0
1085	162	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
1086	162	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
1087	162	200003	6.5	Kg	12490	81185	0-0	0-0
1088	162	200007	7	Kg	2800	19600	2-3455	7-3455
1089	162	200008	1.39999999999999991	Kg	14900	20860	0-0	0-0
1090	162	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
1091	162	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1092	162	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1093	162	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
1094	162	200065	15	Kg	23900	358500	34-473	34-473
1095	162	200004	50	Kg	7900	395000	39-691	39-691
1096	162	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1097	163	200068	5	Kg	64	320	0-0	0-0
1098	163	200035	1	Kg	9687.5	9687.5	0-0	0-0
1099	163	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1100	164	200076	50	Metro	2770	138500	0-0	0-0
1101	164	200077	240	Metro	3200	768000	0-0	0-0
1102	164	200069	1	Kg	2800	2800	0-0	0-0
1103	164	200049	1	Kg	61000	61000	0-0	0-0
1104	165	200068	33	Kg	64	2112	0-0	0-0
1105	165	200069	3.89999999999999991	Kg	2800	10920	0-0	0-0
1106	165	200007	4.20000000000000018	Kg	2800	11760	2-3455	7-3455
1107	165	200036	1.19999999999999996	Kg	14100	16920	0-0	0-0
1108	165	200035	7.5	Kg	9687.5	72656.25	0-0	0-0
1109	165	200003	7.5	Kg	12490	93675	0-0	0-0
1110	165	200008	3	Kg	14900	44700	0-0	0-0
1111	165	200038	3	Kg	9300	27900	0-0	0-0
1112	165	200001	4.20000000000000018	Kg	16.2199999999999989	68.1239999999999952	0-0	0-0
1113	165	200029	1.80000000000000004	Kg	27.5700000000000003	49.6260000000000048	0-0	0-0
1114	165	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1116	165	200030	0.299999999999999989	Kg	22000	6600	0-0	0-0
1117	165	200065	120	Kg	23900	2868000	34-473	34-473
1118	165	200005	112.5	Kg	4600	517500	0-0	0-0
1119	166	200092	100	Metro	1480	148000	5-304	17-304
1120	166	200051	125	Unidad	40	5000	0-0	0-0
1121	166	200068	11	Kg	64	704	0-0	0-0
1122	166	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1123	166	200007	1.39999999999999991	Kg	2800	3919.99999999999955	2-3455	7-3455
1124	166	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1125	166	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1126	166	200003	2.5	Kg	12490	31225	0-0	0-0
1127	166	200008	1	Kg	14900	14900	0-0	0-0
1128	166	200038	1	Kg	9300	9300	0-0	0-0
1129	166	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1130	166	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1131	166	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
1132	166	200030	0.140000000000000013	Kg	22000	3080.00000000000045	0-0	0-0
1134	166	200065	40	Kg	23900	956000	34-473	34-473
1135	166	200005	112.5	Kg	4600	517500	0-0	0-0
1136	166	200004	25	Kg	11200	280000	49-4243	49-4243
1137	166	200078	240	Metro	2620	628800	0-0	0-0
1138	166	200077	80	Metro	3200	256000	0-0	0-0
1139	166	200012	0.5	Caja	2775000	1387500	0-0	0-0
1140	167	200007	30	Kg	2800	84000	2-3455	7-3455
1141	167	200065	15	Kg	23900	358500	34-473	34-473
1142	167	200036	0.5	Kg	14100	7050	0-0	0-0
1143	167	200008	3	Kg	14900	44700	0-0	0-0
1144	167	200035	25	Kg	9687.5	242187.5	0-0	0-0
1145	167	200069	9	Kg	2800	25200	0-0	0-0
1146	167	200068	75	Kg	64	4800	0-0	0-0
1147	168	200049	3	Kg	61000	183000	0-0	0-0
1148	168	200069	3	Kg	2800	8400	0-0	0-0
1149	169	100037	709.5	Kg	6750	4789125	0-0	0-0
1150	169	100003	272.5	Kg	3600	981000	26-598	26-598
1151	169	100006	192.5	Kg	3600	693000	12-931	12-931
1152	170	100037	306	Kg	6750	2065500	0-0	0-0
1153	170	100003	83	Kg	3600	298800	26-598	26-598
1154	171	200075	1	Caja	2950000	2950000	0-0	0-0
1155	171	200068	45	Kg	64	2880	0-0	0-0
1156	171	200069	5	Kg	2800	14000	0-0	0-0
1157	171	200007	20	Kg	2800	56000	2-3455	7-3455
1158	171	200003	12.5	Kg	12490	156125	0-0	0-0
1159	171	200036	2	Kg	14100	28200	0-0	0-0
1133	166	200058	0.100000000000000006	Kg	628647.040000000037	62864.7039999999979	0-0	0-0
1160	171	200008	5	Kg	14900	74500	0-0	0-0
1161	171	200038	5	Kg	9300	46500	0-0	0-0
1162	171	200001	7	Kg	16.2199999999999989	113.539999999999992	0-0	0-0
1163	171	200028	3	Kg	90000	270000	0-0	0-0
1164	171	200029	0.25	Kg	27.5700000000000003	6.89250000000000007	0-0	0-0
1165	171	200060	0.25	Kg	647948	161987	0-0	0-0
1166	171	200056	0.25	Kg	166195	41548.75	0-0	0-0
1167	171	200059	0.5	Kg	304618	152309	0-0	0-0
1168	171	200057	0.25	Kg	565230	141307.5	3-15102	8-15102
1169	171	200005	50	Kg	7980	399000	32-3934	32-3934
1170	171	200004	125	Kg	11200	1400000	49-4243	49-4243
1171	171	200035	125	Kg	9687.5	1210937.5	0-0	0-0
1172	171	200065	12.5	Kg	23900	298750	34-473	34-473
1173	172	200068	22	Kg	64	1408	0-0	0-0
1174	172	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
1175	172	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1176	172	200007	2.79999999999999982	Kg	2800	7839.99999999999909	2-3455	7-3455
1177	172	200003	5	Kg	12490	62450	0-0	0-0
1178	172	200008	2	Kg	14900	29800	0-0	0-0
1179	172	200038	2	Kg	9300	18600	0-0	0-0
1180	172	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1181	172	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1182	172	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
1183	172	200035	5	Kg	9687.5	48437.5	0-0	0-0
1185	172	200030	0.200000000000000011	Kg	22000	4400	0-0	0-0
1186	172	200055	0.0599999999999999978	Kg	99825	5989.5	0-0	0-0
1187	172	200065	80	Kg	23900	1912000	34-473	34-473
1188	172	200005	75	Kg	4600	345000	0-0	0-0
1189	173	200074	57	Metro	1780.42000000000007	101483.940000000002	0-0	0-0
1190	173	200068	11	Kg	64	704	0-0	0-0
1191	173	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1192	173	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1193	173	200007	3	Kg	2800	8400	2-3455	7-3455
1194	173	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1195	173	200003	2.5	Kg	12490	31225	0-0	0-0
1196	173	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1197	173	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1198	173	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1199	173	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
1200	173	200065	40	Kg	23900	956000	34-473	34-473
1201	173	200005	37.5	Kg	7980	299250	32-3934	32-3934
1202	173	200008	1	Kg	14900	14900	0-0	0-0
1203	173	200038	1	Kg	9300	9300	0-0	0-0
1204	174	200068	11	Kg	64	704	0-0	0-0
1205	174	200069	0.400000000000000022	Kg	2800	1120	0-0	0-0
1206	174	200007	4.5	Kg	2800	12600	2-3455	7-3455
1207	174	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1208	174	200008	1	Kg	14900	14900	0-0	0-0
1209	174	200038	1	Kg	9300	9300	0-0	0-0
1210	174	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1211	174	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1212	174	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1213	174	200065	20	Kg	23900	478000	34-479	34-479
1214	174	200005	25	Kg	4600	115000	0-0	0-0
1215	174	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1216	174	200003	2.5	Kg	12490	31225	0-0	0-0
1217	175	200007	30	Kg	2800	84000	2-3455	7-3455
1218	175	200065	15	Kg	23900	358500	34-473	34-473
1219	175	200069	10	Kg	2800	28000	0-0	0-0
1220	175	200008	3	Kg	14900	44700	0-0	0-0
1221	175	200036	0.5	Kg	14100	7050	0-0	0-0
1222	175	200035	25	Kg	9687.5	242187.5	0-0	0-0
1223	175	200068	75	Kg	64	4800	0-0	0-0
1224	175	200049	1	Kg	61000	61000	0-0	0-0
1225	176	200009	0.5	Bulto	62105	31052.5	0-0	0-0
1226	176	200054	1	Rollo	50000	50000	0-0	0-0
1227	176	200068	27	Kg	64	1728	0-0	0-0
1228	176	200009	0.5	Bulto	64801.0590000000011	32400.5295000000006	53-17246	53-17246
1232	178	100037	260	Kg	6750	1755000	0-0	0-0
1233	178	100003	184	Kg	3600	662400	26-598	26-598
1234	178	100006	142	Kg	5700	809400	0-0	0-0
1235	179	100002	400	Kg	5500	2200000	10-168	10-168
1251	183	200058	0.200000000000000011	Kg	628647.040000000037	125729.407999999996	0-0	0-0
1184	172	200058	0.200000000000000011	Kg	628647.040000000037	125729.407999999996	0-0	0-0
1229	177	100002	195	Kg	5500	1072500	10-168	10-168
1230	177	100005	134.5	Kg	4200	564900	0-0	0-0
1231	177	100006	131.5	Kg	3600	473400	12-931	12-931
1236	182	100002	1223	Kg	5500	6726500	10-168	10-168
1237	182	100015	44.5	Kg	2500	111250	12-931	12-931
1238	182	100015	251.5	Kg	2500	628750	12-930	12-930
1239	183	200079	650	Metro	867.740000000000009	564031	0-0	0-0
1240	183	200068	22	Kg	64	1408	0-0	0-0
1241	183	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
1242	183	200007	5	Kg	2800	14000	2-3455	7-3455
1243	183	200035	5	Kg	9687.5	48437.5	0-0	0-0
1244	183	200003	5	Kg	12490	62450	0-0	0-0
1245	183	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1246	183	200008	2	Kg	14900	29800	0-0	0-0
1247	183	200038	2	Kg	9300	18600	0-0	0-0
1248	183	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1249	183	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1250	183	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
1252	183	200004	37.5	Kg	11200	420000	49-2329	49-2329
1253	183	200005	37.5	Kg	4600	172500	0-0	0-0
1254	183	200047	20	Kg	5100	102000	31-3025	31-3025
1255	183	200065	60	Kg	23900	1434000	34-473	34-473
1256	184	200068	10	Kg	64	640	0-0	0-0
1257	184	200069	1	Kg	2800	2800	0-0	0-0
1258	184	200007	2	Kg	2800	5600	2-3455	7-3455
1259	184	200003	2.5	Kg	12490	31225	0-0	0-0
1260	184	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1261	184	200036	0.5	Kg	14100	7050	0-0	0-0
1262	184	200008	1	Kg	14900	14900	0-0	0-0
1263	184	200038	1	Kg	9300	9300	0-0	0-0
1264	184	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1265	184	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1266	184	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1267	184	200065	20	Kg	23900	478000	34-473	34-473
1268	184	200005	25	Kg	4600	115000	0-0	0-0
1269	184	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
1270	184	200061	0.5	Kg	8500	4250	31-3025	31-3025
1271	184	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
1272	185	200068	11	Kg	64	704	0-0	0-0
1273	185	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1274	185	200007	4.5	Kg	2800	12600	2-3455	7-3455
1275	185	200003	2.5	Kg	12490	31225	0-0	0-0
1276	185	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1277	185	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1278	185	200008	1	Kg	14900	14900	0-0	0-0
1279	185	200038	1	Kg	9300	9300	0-0	0-0
1280	185	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1281	185	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1282	185	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1283	185	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1284	185	200065	20	Kg	23900	478000	34-473	34-473
1285	185	200004	25	Kg	11200	280000	49-2329	49-2329
1286	186	200069	2	Kg	2800	5600	0-0	0-0
1287	186	200049	2	Kg	61000	122000	0-0	0-0
1288	186	200068	12.5	Kg	64	800	0-0	0-0
1289	187	100002	175	Kg	5000	875000	0-0	0-0
1290	187	100003	50	Kg	3600	180000	26-598	26-598
1291	187	100025	40	Kg	4600	184000	0-0	0-0
1292	187	100030	75	Kg	7000	525000	23-138	23-138
1293	188	100002	190	Kg	5000	950000	0-0	0-0
1294	188	100005	134.5	Kg	4200	564900	0-0	0-0
1295	188	100006	125	Kg	3600	450000	12-931	12-931
1296	189	100002	340	Kg	5000	1700000	0-0	0-0
1297	189	100003	200	Kg	3600	720000	26-598	26-598
1298	189	100015	82	Kg	2500	205000	12-930	12-930
1299	189	100036	80	Kg	3000	240000	0-0	0-0
1300	190	200041	5000	Uni	73.5	367500	0-0	0-0
1301	190	200013	600	Uni	922	553200	0-0	0-0
1302	190	200009	1	Bulto	64801.0590000000011	64801.0590000000011	53-17246	53-17246
1303	191	100002	690	Kg	5000	3450000	0-0	0-0
1304	191	100015	159.5	Kg	2500	398750	12-930	12-930
1305	191	100003	400	Kg	3600	1440000	26-598	26-598
1306	191	100036	150	Kg	3000	450000	0-0	0-0
1307	192	100002	1440	Kg	5000	7200000	0-0	0-0
1308	192	100015	364	Kg	2500	910000	12-930	12-930
1325	193	200098	1	Mts	435	435	11-277	17-277
1327	193	200085	1	Caja	1091200	1091200	0-0	0-0
1342	194	200051	4000	Unidad	40	160000	0-0	0-0
1343	194	200079	300	Metro	867.740000000000009	260322	0-0	0-0
1344	195	200068	16	Kg	64	1024	0-0	0-0
1345	195	200007	7	Kg	2800	19600	2-3455	7-3455
1346	195	200008	0.900000000000000022	Kg	14900	13410	0-0	0-0
1347	195	200038	1.39999999999999991	Kg	9300	13020	0-0	0-0
1348	195	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1349	195	200035	4	Kg	9687.5	38750	0-0	0-0
1350	195	200065	15	Kg	23900	358500	34-473	34-473
1351	195	200004	50	Kg	11200	560000	49-4312	49-4312
1352	195	200031	0.5	Kg	100352	50176	0-0	0-0
1353	195	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
1354	195	200003	6.5	Kg	12490	81185	0-0	0-0
1355	196	200068	10	Kg	64	640	0-0	0-0
1356	196	200035	2	Kg	9687.5	19375	0-0	0-0
1357	196	200007	1.5	Kg	2800	4200	2-3455	7-3455
1358	196	200069	1.5	Kg	2800	4200	0-0	0-0
1359	196	200036	0.5	Kg	14100	7050	0-0	0-0
1309	193	200068	54	Kg	64	3456	0-0	0-0
1310	193	200007	24	Kg	2800	67200	2-3455	7-3455
1311	193	200035	9	Kg	9687.5	87187.5	0-0	0-0
1312	193	200008	4.20000000000000018	Kg	14900	62580	0-0	0-0
1328	194	200068	48	Kg	64	3072	0-0	0-0
1329	194	200007	10	Kg	2800	28000	2-3455	7-3455
1330	194	200035	8	Kg	9687.5	77500	0-0	0-0
1331	194	200008	4	Kg	14900	59600	0-0	0-0
1332	194	200038	4	Kg	9300	37200	0-0	0-0
1333	194	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1335	194	200028	2	Kg	90000	180000	0-0	0-0
1336	194	200004	150	Kg	11200	1680000	49-4243	49-4243
1337	194	200005	150	Kg	4600	690000	0-0	0-0
1338	194	200065	120	Kg	24400	2928000	34-481	34-481
1339	194	200047	40	Kg	5100	204000	31-3025	31-3025
1340	194	200069	5.59999999999999964	Kg	2800	15680	0-0	0-0
1341	194	200003	10	Kg	12490	124900	0-0	0-0
1334	194	200058	0.400000000000000022	Kg	628647.040000000037	251458.815999999992	0-0	0-0
1313	193	200038	4.20000000000000018	Kg	9300	39060	0-0	0-0
1314	193	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
1315	193	200060	1.5	Kg	647948	971922	0-0	0-0
1316	193	200057	1.5	Kg	565230	847845	3-15102	8-15102
1317	193	200059	0.900000000000000022	Kg	304618	274156.200000000012	0-0	0-0
1318	193	200056	3	Kg	166195	498585	0-0	0-0
1319	193	200028	1.5	Kg	90000	135000	0-0	0-0
1320	193	200004	150	Kg	11200	1680000	49-4312	49-4312
1321	193	200005	150	Kg	4600	690000	0-0	0-0
1322	193	200047	180	Kg	5100	918000	31-3025	31-3025
1323	193	200065	60	Kg	24400	1464000	34-481	34-481
1324	193	200069	6	Kg	2800	16800	0-0	0-0
1326	193	200003	7.5	Kg	12490	93675	0-0	0-0
1360	197	200068	12	Kg	64	768	0-0	0-0
1361	197	200007	1.39999999999999991	Kg	2800	3919.99999999999955	2-3455	7-3455
1362	197	200035	2.29999999999999982	Kg	9687.5	22281.25	0-0	0-0
1363	197	200038	1	Kg	9300	9300	0-0	0-0
1364	197	200008	1	Kg	14900	14900	0-0	0-0
1365	197	200065	40	Kg	23900	956000	34-473	34-473
1366	197	200004	37.5	Kg	11200	420000	49-4312	49-4312
1368	197	200055	1.03000000000000003	Kg	99825	102819.75	0-0	0-0
1369	197	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1370	197	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1371	197	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1372	197	200082	100	.	2835	283500	0-0	0-0
1373	197	200051	100	Unidad	40	4000	0-0	0-0
1374	197	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1375	198	200068	11	Kg	64	704	0-0	0-0
1376	198	200007	2	Kg	2800	5600	2-3455	7-3455
1377	198	200035	2	Kg	9687.5	19375	0-0	0-0
1378	198	200038	1	Kg	9300	9300	0-0	0-0
1379	198	200008	1	Kg	14900	14900	0-0	0-0
1380	198	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1381	198	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1382	198	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1383	198	200065	40	Kg	24400	976000	34-481	34-481
1384	198	200005	37.5	Kg	7980	299250	32-3934	32-3934
1385	198	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
1386	198	200074	180	Metro	1780.42000000000007	320475.600000000035	0-0	0-0
1387	199	200068	36	Kg	64	2304	0-0	0-0
1388	199	200007	16	Kg	2800	44800	2-3455	7-3455
1389	199	200035	6	Kg	9687.5	58125	0-0	0-0
1390	199	200008	2.79999999999999982	Kg	14900	41720	0-0	0-0
1391	199	200038	2.79999999999999982	Kg	9300	26040	0-0	0-0
1392	199	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1393	199	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
1394	199	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
1395	199	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
1396	199	200056	0.200000000000000011	Kg	166195	33239	0-0	0-0
1397	199	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
1398	199	200004	100	Kg	11200	1120000	49-4312	49-4312
1399	199	200005	100	Kg	4600	460000	0-0	0-0
1400	199	200047	120	Kg	5100	612000	31-3025	31-3025
1401	199	200065	40	Kg	24400	976000	34-481	34-481
1402	199	200069	40	Kg	2800	112000	0-0	0-0
1403	199	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1404	199	200029	24	Kg	27.5700000000000003	661.680000000000064	0-0	0-0
1405	199	200003	10	Kg	12490	124900	0-0	0-0
1406	200	200053	1	Bulto	1404	1404	0-0	0-0
1407	200	200085	1	Caja	1091200	1091200	0-0	0-0
1408	200	200013	1100	Uni	922	1014200	0-0	0-0
1409	200	200010	2	Bulto	62105	124210	0-0	0-0
1410	200	200011	1	Bulto	45967.5	45967.5	53-17245	53-17245
1411	200	200080	750	Metro	1680	1260000	0-0	0-0
1412	200	200041	5000	Uni	73.5	367500	0-0	0-0
1413	201	200068	3	Kg	64	192	0-0	0-0
1414	201	200035	1	Kg	9687.5	9687.5	0-0	0-0
1415	201	200028	0.299999999999999989	Kg	90000	27000	0-0	0-0
1416	203	200068	48	Kg	64	3072	0-0	0-0
1417	203	200007	10	Kg	2800	28000	2-3455	7-3455
1418	203	200035	8	Kg	9687.5	77500	0-0	0-0
1419	203	200008	4	Kg	14900	59600	0-0	0-0
1420	203	200038	4	Kg	9300	37200	0-0	0-0
1421	203	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1423	203	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
1424	203	200004	150	Kg	11200	1680000	49-4312	49-4312
1425	203	200005	150	Kg	4600	690000	0-0	0-0
1426	203	200047	40	Kg	5100	204000	31-3025	31-3025
1427	203	200069	5.59999999999999964	Kg	2800	15679.9999999999982	0-0	0-0
1428	203	200003	10	Kg	12490	124900	0-0	0-0
1429	203	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1430	203	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1431	203	200065	120	Kg	24400	2928000	34-481	34-481
1432	204	100004	295.5	Kg	3600	1063800	40-2017	40-2017
1433	205	100002	967	Kg	5000	4835000	0-0	0-0
1434	205	100015	238	Kg	2500	595000	12-930	12-930
1435	206	100002	400	Kg	5000	2000000	0-0	0-0
1436	207	100002	772	Kg	5000	3860000	0-0	0-0
1437	207	100007	399.5	Kg	7000	2796500	0-0	0-0
1438	207	100036	81	Kg	3000	243000	0-0	0-0
1439	207	100015	160	Kg	2500	400000	12-930	12-930
1440	208	100002	299.5	Kg	5000	1497500	0-0	0-0
1441	208	100003	81.5	Kg	3600	293400	26-598	26-598
1442	209	200007	30	Kg	2800	84000	2-3455	7-3455
1443	209	200035	20	Kg	9687.5	193750	0-0	0-0
1444	209	200065	15	Kg	23900	358500	34-473	34-473
1445	209	200008	3	Kg	14900	44700	0-0	0-0
1446	209	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
1447	209	200069	9	Kg	2800	25200	0-0	0-0
1448	209	200068	75	Kg	64	4800	0-0	0-0
1449	210	200068	18	Kg	64	1152	0-0	0-0
1450	210	200007	8	Kg	2800	22400	2-3455	7-3455
1422	203	200058	0.400000000000000022	Kg	628647.040000000037	251458.815999999992	0-0	0-0
1451	210	200035	3	Kg	9687.5	29062.5	0-0	0-0
1452	210	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1453	210	200008	1.60000000000000009	Kg	14900	23840	0-0	0-0
1454	210	200038	1.80000000000000004	Kg	9300	16740	0-0	0-0
1455	210	200028	0.5	Kg	90000	45000	0-0	0-0
1456	210	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1457	210	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1458	210	200060	0.5	Kg	647948	323974	0-0	0-0
1459	210	200057	0.5	Kg	565230	282615	3-15102	8-15102
1460	210	200059	0.5	Kg	304618	152309	0-0	0-0
1461	210	200056	0.5	Kg	166195	83097.5	0-0	0-0
1462	210	200065	20	Kg	23900	478000	34-473	34-473
1463	210	200004	50	Kg	11200	560000	49-4312	49-4312
1464	210	200005	50	Kg	4600	230000	0-0	0-0
1465	210	200047	60	Kg	5100	306000	31-3025	31-3025
1466	211	200068	24	Kg	64	1536	0-0	0-0
1467	211	200007	5	Kg	2800	14000	2-3455	7-3455
1468	211	200035	4	Kg	9687.5	38750	0-0	0-0
1469	211	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1470	211	200008	2	Kg	14900	29800	0-0	0-0
1471	211	200038	2	Kg	9300	18600	0-0	0-0
1472	211	200028	0.800000000000000044	Kg	90000	72000	0-0	0-0
1473	211	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1474	211	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1476	211	200065	40	Kg	24400	976000	34-481	34-481
1477	211	200047	20	Kg	5100	102000	31-3025	31-3025
1478	211	200004	37	Kg	11200	414400	49-4312	49-4312
1479	211	200005	37	Kg	4600	170200	0-0	0-0
1480	212	200068	12	Kg	64	768	0-0	0-0
1481	212	200007	2.5	Kg	2800	7000	2-3455	7-3455
1482	212	200035	2	Kg	9687.5	19375	0-0	0-0
1483	212	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1484	212	200008	1	Kg	14900	14900	0-0	0-0
1485	212	200038	1	Kg	9300	9300	0-0	0-0
1486	212	200028	0.5	Kg	90000	45000	0-0	0-0
1487	212	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1488	212	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1490	212	200065	25	Kg	24400	610000	34-481	34-481
1491	212	200047	15	Kg	5100	76500	31-3025	31-3025
1492	212	200004	18.75	Kg	11200	210000	49-4312	49-4312
1493	212	200005	18.75	Kg	7980	149625	32-3934	32-3934
1494	213	200079	300	Metro	867.740000000000009	260322	0-0	0-0
1495	213	200013	100	Uni	922	92200	0-0	0-0
1496	213	200016	10	Uni	5000	50000	0-0	0-0
1497	214	100025	37	Kg	4600	170200	0-0	0-0
1498	214	100015	63	Kg	2500	157500	12-930	12-930
1500	214	100006	243	Kg	7800	1895400	11-2017	11-2017
1501	215	100002	451	Kg	5500	2480500	40-2017	40-2017
1502	215	100007	169	Kg	7000	1183000	0-0	0-0
1504	215	100015	77	Kg	2500	192500	12-930	12-930
1505	216	200068	36	Kg	64	2304	0-0	0-0
1506	216	200007	16	Kg	2800	44800	2-3455	7-3455
1507	216	200035	6	Kg	9687.5	58125	0-0	0-0
1508	216	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1509	216	200008	2.79999999999999982	Kg	14900	41720	0-0	0-0
1510	216	200038	0.640000000000000013	Kg	9300	5952	0-0	0-0
1511	216	200069	4	Kg	2800	11200	0-0	0-0
1512	216	200065	40	Kg	24400	976000	34-481	34-481
1513	216	200047	120	Kg	5100	612000	31-3025	31-3025
1514	216	200004	100	Kg	11200	1120000	49-4312	49-4312
1515	216	200005	100	Kg	4600	460000	0-0	0-0
1516	216	200060	1	Kg	647948	647948	0-0	0-0
1517	216	200057	1	Kg	565230	565230	3-15102	8-15102
1518	216	200056	1	Kg	166195	166195	0-0	0-0
1519	216	200059	1	Kg	304618	304618	0-0	0-0
1520	216	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1521	216	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1522	216	200028	1	Kg	90000	90000	0-0	0-0
1523	216	200085	0.5	Caja	1091200	545600	0-0	0-0
1524	217	200068	5	Kg	64	320	0-0	0-0
1525	217	200035	1	Kg	9687.5	9687.5	0-0	0-0
1526	217	200028	0.299999999999999989	Kg	90000	27000	0-0	0-0
1527	217	200013	100	Uni	922	92200	0-0	0-0
1528	218	100002	840	Kg	5500	4620000	0-0	0-0
1529	218	100003	412	Kg	3600	1483200	26-598	26-598
1530	218	100015	163.5	Kg	2500	408750	12-930	12-930
1531	219	100002	964	Kg	5500	5302000	0-0	0-0
1532	219	100015	240	Kg	2500	600000	12-930	12-930
1533	220	200068	48	Kg	64	3072	0-0	0-0
1534	220	200007	10	Kg	2800	28000	2-3455	7-3455
1535	220	200035	8	Kg	9687.5	77500	0-0	0-0
1536	220	200038	4	Kg	9300	37200	0-0	0-0
1537	220	200008	4	Kg	14900	59600	0-0	0-0
1538	220	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
1539	220	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1541	220	200047	60	Kg	5100	306000	31-3025	31-3025
1542	220	200004	75	Kg	11200	840000	49-4312	49-4312
1543	220	200005	75	Kg	4600	345000	0-0	0-0
1544	220	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1545	220	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1546	220	200028	0.5	Kg	90000	45000	0-0	0-0
1547	220	200079	650	Metro	867.740000000000009	564031	0-0	0-0
1548	220	200041	2500	Uni	73.5	183750	0-0	0-0
1549	220	200065	100	Kg	30000	3000000	34-485	34-485
1550	221	200068	18	Kg	64	1152	0-0	0-0
1551	221	200069	2	Kg	2800	5600	0-0	0-0
1552	221	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1553	221	200007	10	Kg	2800	28000	2-3455	7-3455
1540	220	200058	0.5	Kg	628647.040000000037	314323.520000000019	0-0	0-0
1503	215	100030	27	Kg	7500	202500	48-459	48-459
1489	212	200058	0.100000000000000006	Kg	628647.040000000037	62864.7039999999979	0-0	0-0
1499	214	100030	239	Kg	7500	1792500	48-459	48-459
1554	221	200035	3	Kg	9687.5	29062.5	0-0	0-0
1555	221	200003	5	Kg	12490	62450	0-0	0-0
1556	221	200008	2	Kg	14900	29800	0-0	0-0
1557	221	200038	2	Kg	9300	18600	0-0	0-0
1558	221	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1559	221	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1560	221	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1561	221	200065	20	Kg	30000	600000	34-485	34-485
1562	221	200047	60	Kg	5100	306000	31-3025	31-3025
1563	221	200005	50	Kg	4600	230000	0-0	0-0
1564	221	200004	50	Kg	11200	560000	49-4312	49-4312
1565	221	200060	0.0500000000000000028	Kg	647948	32397.4000000000015	0-0	0-0
1566	221	200057	0.0500000000000000028	Kg	565230	28261.5	3-15102	8-15102
1567	221	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
1568	221	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1569	222	200068	11	Kg	64	704	0-0	0-0
1570	222	200007	1.39999999999999991	Kg	2800	3919.99999999999955	2-3455	7-3455
1571	222	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1572	222	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1573	222	200003	2.5	Kg	12490	31225	0-0	0-0
1574	222	200008	1	Kg	14900	14900	0-0	0-0
1575	222	200038	1	Kg	9300	9300	0-0	0-0
1576	222	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1577	222	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1578	222	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
1579	222	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
1580	222	200060	0.119999999999999996	Kg	647948	77753.7599999999948	0-0	0-0
1581	222	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
1582	222	200065	40	Kg	30000	1200000	34-485	34-485
1583	222	200005	25	Kg	7980	199500	32-3934	32-3934
1584	222	200004	12.5	Kg	11200	140000	49-4312	49-4312
1585	222	200051	100	Unidad	40	4000	0-0	0-0
1586	222	200082	100	.	2835	283500	0-0	0-0
1587	223	200079	650	Metro	867.740000000000009	564031	0-0	0-0
1588	223	200068	44	Kg	64	2816	0-0	0-0
1589	223	200007	10	Kg	2800	28000	2-3455	7-3455
1590	223	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
1591	223	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1592	223	200035	10	Kg	9687.5	96875	0-0	0-0
1593	223	200003	10	Kg	12490	124900	0-0	0-0
1594	223	200008	4	Kg	14900	59600	0-0	0-0
1595	223	200038	4	Kg	9300	37200	0-0	0-0
1596	223	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1597	223	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1598	223	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
1600	223	200065	100	Kg	30000	3000000	34-485	34-485
1601	223	200047	60	Kg	5100	306000	31-3025	31-3025
1602	223	200004	75	Kg	11200	840000	49-4312	49-4312
1603	223	200005	75	Kg	4600	345000	0-0	0-0
1604	224	200068	10	Kg	64	640	0-0	0-0
1605	224	200069	0.5	Kg	2800	1400	0-0	0-0
1606	224	200036	2.5	Kg	14100	35250	0-0	0-0
1607	224	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1608	224	200003	2	Kg	12490	24980	0-0	0-0
1609	224	200007	1	Kg	2800	2800	2-3455	7-3455
1610	224	200008	1	Kg	14900	14900	0-0	0-0
1611	224	200038	1.39999999999999991	Kg	9300	13020	0-0	0-0
1612	224	200001	0.599999999999999978	Kg	16.2199999999999989	9.73199999999999932	0-0	0-0
1613	224	200029	0.0500000000000000028	Kg	27.5700000000000003	1.37850000000000006	0-0	0-0
1614	224	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
1615	224	200056	0.100000000000000006	Kg	166195	16619.5	0-0	0-0
1616	224	200062	0.5	Kg	42000	21000	0-0	0-0
1617	224	200061	0.5	Kg	8500	4250	31-3025	31-3025
1618	224	200065	20	Kg	30000	600000	34-485	34-485
1619	224	200005	25	Kg	7980	199500	32-3934	32-3934
1620	225	200068	11	Kg	64	704	0-0	0-0
1621	225	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1622	225	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1623	225	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1624	225	200003	2.5	Kg	12490	31225	0-0	0-0
1625	225	200007	4.5	Kg	2800	12600	2-3455	7-3455
1626	225	200008	1	Kg	14900	14900	0-0	0-0
1627	225	200038	1	Kg	9300	9300	0-0	0-0
1628	225	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1629	225	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1630	225	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1631	225	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1632	225	200065	20	Kg	30000	600000	34-485	34-485
1633	225	200005	25	Kg	7980	199500	32-3934	32-3934
1634	226	200013	400	Uni	922	368800	0-0	0-0
1635	226	200010	2	Bulto	62105	124210	0-0	0-0
1636	227	100002	177.5	Kg	5500	976250	0-0	0-0
1637	227	100025	41	Kg	4600	188600	0-0	0-0
1638	227	100006	143	Kg	5700	815100	0-0	0-0
1639	227	100007	48.5	Kg	7000	339500	0-0	0-0
1640	231	100002	192	Kg	5500	1056000	0-0	0-0
1641	231	100005	138	Kg	4200	579600	0-0	0-0
1642	231	100006	125.5	Kg	7200	903600	51-1233	51-1233
1643	233	100002	483	Kg	5500	2656500	0-0	0-0
1644	233	100015	120	Kg	2500	300000	12-930	12-930
1645	234	100002	750	Kg	5500	4125000	0-0	0-0
1646	234	100007	407.5	Kg	7000	2852500	0-0	0-0
1647	234	100015	239.5	Kg	2500	598750	12-930	12-930
1648	235	100002	375.5	Kg	5500	2065250	0-0	0-0
1649	235	100003	205	Kg	3600	738000	26-598	26-598
1650	235	100015	126.5	Kg	2500	316250	12-930	12-930
1651	236	200068	22	Kg	64	1408	0-0	0-0
1652	236	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
1653	236	200007	5	Kg	2800	14000	2-3455	7-3455
1654	236	200008	2	Kg	14900	29800	0-0	0-0
1655	236	200038	2	Kg	9300	18600	0-0	0-0
1656	236	200035	5	Kg	9687.5	48437.5	0-0	0-0
1657	236	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1658	236	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1659	236	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
1660	236	200003	5	Kg	12490	62450	0-0	0-0
1661	236	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
1662	236	200065	50	Kg	30000	1500000	34-485	34-485
1663	236	200047	30	Kg	5100	153000	31-3025	31-3025
1664	236	200004	37.5	Kg	11200	420000	49-4312	49-4312
1665	236	200005	37.5	Kg	7980	299250	32-3934	32-3934
1666	236	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1667	236	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
1668	236	200056	0.100000000000000006	Kg	166195	16619.5	0-0	0-0
1669	236	200059	0.100000000000000006	Kg	304618	30461.8000000000029	0-0	0-0
1670	237	200007	7	Kg	2800	19600	2-3455	7-3455
1671	237	200069	2	Kg	2800	5600	0-0	0-0
1672	237	200049	2	Kg	61000	122000	0-0	0-0
1673	237	200068	50	Kg	64	3200	0-0	0-0
1674	238	200019	100	Uni	1956	195600	0-0	0-0
1675	238	200011	1	Bulto	62105	62105	0-0	0-0
1676	238	200010	1	Bulto	62105	62105	0-0	0-0
1677	238	200013	600	Uni	922	553200	0-0	0-0
1678	238	200051	4000	Unidad	40	160000	0-0	0-0
1115	165	200058	0.299999999999999989	Kg	628647.040000000037	188594.111999999994	0-0	0-0
1367	197	200058	0.100000000000000006	Kg	628647.040000000037	62864.7039999999979	0-0	0-0
1475	211	200058	0.200000000000000011	Kg	628647.040000000037	125729.407999999996	0-0	0-0
1599	223	200058	0.400000000000000022	Kg	628647.040000000037	251458.815999999992	0-0	0-0
1679	239	200028	1	Kg	90000	90000	0-0	0-0
1680	239	200068	36	Kg	64	2304	0-0	0-0
1681	239	200007	16	Kg	2800	44800	2-3455	7-3455
1682	239	200035	6	Kg	9687.5	58125	0-0	0-0
1683	239	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1684	239	200008	2.79999999999999982	Kg	14900	41720	0-0	0-0
1685	239	200038	3.20000000000000018	Kg	9300	29760	0-0	0-0
1686	239	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1687	239	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1688	239	200069	4	Kg	2800	11200	0-0	0-0
1689	239	200060	1	Kg	647948	647948	0-0	0-0
1690	239	200057	1	Kg	565230	565230	3-15102	8-15102
1691	239	200059	1	Kg	304618	304618	0-0	0-0
1692	239	200056	2	Kg	166195	332390	0-0	0-0
1693	239	200004	100	Kg	11700	1170000	49-4393	49-4393
1694	239	200005	125	Kg	7980	997500	32-3934	32-3934
1695	239	200047	120	Kg	5100	612000	31-3025	31-3025
1696	239	200065	40	Kg	30000	1200000	34-485	34-485
1697	239	200098	8700	Mts	435	3784500	11-277	17-277
1698	239	200003	10	Kg	12490	124900	0-0	0-0
1699	240	200068	24	Kg	64	1536	0-0	0-0
1700	240	200007	5	Kg	2800	14000	2-3455	7-3455
1701	240	200035	4	Kg	9687.5	38750	0-0	0-0
1702	240	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
1703	240	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1704	240	200038	2	Kg	9300	18600	0-0	0-0
1705	240	200008	2	Kg	14900	29800	0-0	0-0
1706	240	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1707	240	200029	1.5	Kg	27.5700000000000003	41.355000000000004	0-0	0-0
1708	240	200058	0.200000000000000011	Kg	628647.040000000037	125729.40800000001	0-0	0-0
1709	240	200004	37.5	Kg	11200	420000	49-4312	49-4312
1710	240	200005	37.5	Kg	7980	299250	32-3934	32-3934
1711	240	200003	5	Kg	12490	62450	0-0	0-0
1712	240	200028	1	Kg	90000	90000	0-0	0-0
1713	240	200041	2500	Uni	73.5	183750	0-0	0-0
1714	240	200080	650	Metro	1680	1092000	0-0	0-0
1715	241	200068	5	Kg	64	320	0-0	0-0
1716	241	200035	1	Kg	9687.5	9687.5	0-0	0-0
1717	241	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1719	242	200075	1	Caja	3736700	3736700	34-2095	69-2095
1721	242	200068	27	Kg	64	1728	0-0	0-0
1722	242	200007	12	Kg	2800	33600	2-3455	7-3455
1723	242	200036	1.19999999999999996	Kg	14100	16920	0-0	0-0
1724	242	200003	7.5	Kg	12490	93675	0-0	0-0
1725	242	200035	7.5	Kg	9687.5	72656.25	0-0	0-0
1726	242	200008	3	Kg	14900	44700	0-0	0-0
1727	242	200038	3	Kg	9300	27900	0-0	0-0
1728	242	200001	4.20000000000000018	Kg	16.2199999999999989	68.1239999999999952	0-0	0-0
1729	242	200029	0.0899999999999999967	Kg	27.5700000000000003	2.48130000000000006	0-0	0-0
1730	242	200028	1.80000000000000004	Kg	90000	162000	0-0	0-0
1731	242	200060	0.75	Kg	647948	485961	0-0	0-0
1732	242	200057	0.75	Kg	565230	423922.5	3-15102	8-15102
1733	242	200059	0.450000000000000011	Kg	304618	137078.100000000006	0-0	0-0
1734	242	200056	0.149999999999999994	Kg	166195	24929.25	0-0	0-0
1735	242	200005	75	Kg	7980	598500	32-3934	32-3934
1736	242	200004	75	Kg	11700	877500	49-4393	49-4393
1738	242	200047	90	Kg	5100	459000	31-3025	31-3025
1739	242	200069	3	Kg	2800	8400	0-0	0-0
1740	243	200099	7040	Mts	360	2534400	12-23992	33-23992
1741	243	200069	3	Kg	2800	8400	0-0	0-0
1742	243	200068	27	Kg	64	1728	0-0	0-0
1743	243	200007	12	Kg	2800	33600	2-3455	7-3455
1744	243	200036	1.19999999999999996	Kg	14100	16920	0-0	0-0
1745	243	200003	7.5	Kg	12490	93675	0-0	0-0
1746	243	200035	7.5	Kg	9687.5	72656.25	0-0	0-0
1747	243	200008	3	Kg	14900	44700	0-0	0-0
1748	243	200038	3	Kg	9300	27900	0-0	0-0
1749	243	200001	4.20000000000000018	Kg	16.2199999999999989	68.1239999999999952	0-0	0-0
1750	243	200029	1.80000000000000004	Kg	27.5700000000000003	49.6260000000000048	0-0	0-0
1751	243	200028	0.75	Kg	90000	67500	0-0	0-0
1752	243	200060	0.75	Kg	647948	485961	0-0	0-0
1720	242	200099	8690	Mts	360	360	12-23992	33-23992
1718	240	200064	120	Kg	9300	1116000	31-3035	31-3035
1737	242	200064	30	Kg	9300	279000	31-3035	31-3035
1753	243	200057	0.450000000000000011	Kg	565230	254353.5	3-15102	8-15102
1754	243	200059	0.450000000000000011	Kg	304618	137078.100000000006	0-0	0-0
1755	243	200056	0.450000000000000011	Kg	166195	74787.75	0-0	0-0
1756	243	200005	75	Kg	7980	598500	32-3934	32-3934
1757	243	200004	75	Kg	11700	877500	49-4393	49-4393
1759	243	200047	90	Kg	5100	459000	31-3025	31-3025
1760	244	200076	80	Metro	2770	221600	0-0	0-0
1761	244	200007	7	Kg	2800	19600	2-3455	7-3455
1762	244	200068	16	Kg	64	1024	0-0	0-0
1763	244	200008	1	Kg	14900	14900	0-0	0-0
1764	244	200038	1.39999999999999991	Kg	9300	13020	0-0	0-0
1765	244	200032	6.5	Kg	12900	83850	0-0	0-0
1766	244	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1767	244	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
1768	244	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1769	244	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1770	244	200031	0.849999999999999978	Kg	100352	85299.1999999999971	0-0	0-0
1771	244	200065	15	Kg	30000	450000	34-485	34-485
1772	244	200004	50	Kg	11700	585000	49-4393	49-4393
1773	244	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
1774	245	200068	11	Kg	64	704	0-0	0-0
1775	245	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1776	245	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1777	245	200003	2.5	Kg	12490	31225	0-0	0-0
1778	245	200007	1.39999999999999991	Kg	2800	3919.99999999999955	2-3455	7-3455
1779	245	200008	1	Kg	14900	14900	0-0	0-0
1780	245	200038	1	Kg	9300	9300	0-0	0-0
1781	245	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
1782	245	200065	40	Kg	30000	1200000	34-485	34-485
1783	245	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1784	245	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1785	245	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
1786	245	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
1787	245	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
1788	245	200031	0.5	Kg	100352	50176	0-0	0-0
1789	245	200005	12.5	Kg	7980	99750	32-3934	32-3934
1790	245	200004	25	Kg	11700	292500	49-4393	49-4393
1791	245	200082	100	.	2835	283500	0-0	0-0
1792	245	200051	100	Unidad	40	4000	0-0	0-0
1793	246	200068	11	Kg	64	704	0-0	0-0
1794	246	200007	4.5	Kg	2800	12600	2-3455	7-3455
1795	246	200036	0.0400000000000000008	Kg	14100	564	0-0	0-0
1796	246	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1797	246	200003	2.5	Kg	12490	31225	0-0	0-0
1798	246	200008	1	Kg	14900	14900	0-0	0-0
1799	246	200038	1	Kg	9300	9300	0-0	0-0
1800	246	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1801	246	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1802	246	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1803	246	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
1805	246	200005	25	Kg	7980	199500	32-3934	32-3934
1806	246	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
1807	247	200068	10	Kg	64	640	0-0	0-0
1808	247	200007	2	Kg	2800	5600	2-3455	7-3455
1809	247	200036	0.5	Kg	14100	7050	0-0	0-0
1810	247	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
1811	247	200003	2.5	Kg	12490	31225	0-0	0-0
1812	247	200008	1	Kg	14900	14900	0-0	0-0
1813	247	200038	1	Kg	9300	9300	0-0	0-0
1814	247	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1815	247	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1816	247	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
1817	247	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
1819	247	200005	25	Kg	7980	199500	32-3934	32-3934
1820	247	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
1821	247	200061	0.400000000000000022	Kg	9000	3600	0-0	0-0
1822	247	200069	1	Kg	2800	2800	0-0	0-0
1823	248	200080	650	Metro	1680	1092000	0-0	0-0
1824	248	200068	75	Kg	64	4800	0-0	0-0
1825	248	200035	15	Kg	9687.5	145312.5	0-0	0-0
1826	248	200069	8	Kg	2800	22400	0-0	0-0
1827	248	200001	1.5	Kg	16.2199999999999989	24.3299999999999983	0-0	0-0
1828	248	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
1829	248	200007	15	Kg	2800	42000	2-3455	7-3455
1830	248	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
1831	248	200008	6	Kg	14900	89400	0-0	0-0
1832	248	200038	6	Kg	9300	55800	0-0	0-0
1833	248	200003	30	Kg	12490	374700	0-0	0-0
1834	248	200058	0.400000000000000022	Kg	701315	280526	23-0011021	8-11021
1836	248	200005	112.5	Kg	7980	897750	32-3934	32-3934
1837	248	200004	112.5	Kg	11700	1316250	49-4393	49-4393
1838	248	200047	90	Kg	5100	459000	31-3025	31-3025
1839	249	100002	192	Kg	6900	1324800	70-37360	70-37360
1840	249	100005	120.5	Kg	4200	506100	0-0	0-0
1841	249	100006	138	Kg	7800	1076400	11-283	11-283
1842	250	100002	178.5	Kg	6900	1231650	70-37360	70-37360
1843	250	100025	40	Kg	4600	184000	0-0	0-0
1845	250	100006	140	Kg	7800	1092000	11-283	11-283
1846	251	100002	871.5	Kg	6900	6013350	70-37360	70-37360
1848	251	100007	606.5	Kg	7000	4245500	0-0	0-0
1849	251	100015	360	Kg	2500	900000	12-930	12-930
1850	251	100006	122	Kg	7800	951600	11-283	11-283
1851	251	100035	300	Kg	4200	1260000	0-0	0-0
1852	252	100025	82	Kg	4600	377200	0-0	0-0
1853	252	100015	230	Kg	2500	575000	12-930	12-930
1855	252	100006	596.5	Kg	7800	4652700	11-283	11-283
1844	250	100003	53	Kg	5500	291500	77-1335	77-1335
1818	247	200064	20	Kg	9300	186000	31-3035	31-3035
1804	246	200064	30	Kg	9300	279000	31-3035	31-3035
1835	248	200064	180	Kg	9300	1674000	31-3035	31-3035
1847	251	100036	121	Kg	3800	459800	77-1335	77-1335
1856	253	100002	662	Kg	6900	4567800	70-37360	70-37360
1857	253	100015	164	Kg	2500	410000	12-930	12-930
1858	253	100006	66.5	Kg	7800	518700	11-283	11-283
1859	254	100006	60	Kg	7800	468000	11-283	11-283
1860	254	100007	80.5	Kg	7000	563500	0-0	0-0
1861	255	100018	396.5	Kg	2000	793000	0-0	0-0
1862	255	100003	424.5	Kg	3600	1528200	26-598	26-598
1863	256	200007	7	Kg	2800	19600	2-3455	7-3455
1864	256	200069	1	Kg	2800	2800	0-0	0-0
1865	256	200049	1	Kg	61000	61000	0-0	0-0
1866	256	200068	13	Kg	64	832	0-0	0-0
1867	256	200036	3.29999999999999982	Kg	14100	46530	0-0	0-0
1868	256	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
1869	257	200068	50	Kg	64	3200	0-0	0-0
1870	257	200069	2	Kg	2800	5600	0-0	0-0
1871	257	200049	2	Kg	61000	122000	0-0	0-0
1758	243	200064	30	Kg	9300	279000	31-3035	31-3035
1872	258	200068	32	Kg	64	2048	0-0	0-0
1873	258	200069	3.60000000000000009	Kg	2800	10080	0-0	0-0
1874	258	200007	14	Kg	2800	39200	2-3455	7-3455
1875	258	200008	1.80000000000000004	Kg	14900	26820	0-0	0-0
1876	258	200038	3.20000000000000018	Kg	9300	29760	0-0	0-0
1877	258	200032	13	Kg	12900	167700	0-0	0-0
1878	258	200035	8	Kg	9687.5	77500	0-0	0-0
1879	258	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1880	258	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1881	258	200031	0.170000000000000012	Kg	100352	17059.8400000000001	0-0	0-0
1882	258	200004	100	Kg	11700	1170000	49-4393	49-4393
1883	258	200065	40	Kg	34000	1360000	34-488	34-488
1884	259	200068	16	Kg	64	1024	0-0	0-0
1885	259	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
1886	259	200007	7	Kg	2800	19600	2-3455	7-3455
1887	259	200008	0.900000000000000022	Kg	14900	13410	0-0	0-0
1888	259	200038	16	Kg	9300	148800	0-0	0-0
1889	259	200003	6.5	Kg	12490	81185	0-0	0-0
1890	259	200035	4	Kg	9687.5	38750	0-0	0-0
1891	259	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
1892	259	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
1893	259	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
1894	259	200065	15	Kg	34000	510000	34-488	34-488
1895	259	200004	50	Kg	11700	585000	49-4393	49-4393
1896	260	200068	26	Kg	64	1664	0-0	0-0
1897	260	200069	4	Kg	2800	11200	0-0	0-0
1898	260	200007	7	Kg	2800	19600	2-3455	7-3455
1899	260	200008	1.60000000000000009	Kg	14900	23840	0-0	0-0
1900	260	200038	2.79999999999999982	Kg	9300	26040	0-0	0-0
1901	260	200003	13	Kg	12490	162370	0-0	0-0
1902	260	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1903	260	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1904	260	200031	0.100000000000000006	Kg	100352	10035.2000000000007	0-0	0-0
1905	260	200065	15	Kg	34000	510000	34-488	34-488
1906	260	200004	100	Kg	11700	1170000	49-4393	49-4393
1907	261	200075	1	Caja	2950000	2950000	0-0	0-0
1908	261	200085	1	Mts	360	360	12-23992	33-23992
1909	261	200068	36	Kg	64	2304	0-0	0-0
1910	261	200069	4	Kg	2800	11200	0-0	0-0
1911	261	200007	16	Kg	2800	44800	2-3455	7-3455
1912	261	200008	4	Kg	14900	59600	0-0	0-0
1913	261	200038	4	Kg	9300	37200	0-0	0-0
1914	261	200003	10	Kg	12490	124900	0-0	0-0
1915	261	200035	6	Kg	9687.5	58125	0-0	0-0
1916	261	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
1917	261	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
1918	261	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
1919	261	200028	0.119999999999999996	Kg	90000	10800	0-0	0-0
1920	261	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
1921	261	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
1922	261	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
1923	261	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
1924	261	200065	40	Kg	34000	1360000	34-488	34-488
1925	261	200005	100	Kg	7980	798000	32-3934	32-3934
1926	261	200004	100	Kg	11700	1170000	49-4393	49-4393
1927	262	200007	7	Kg	2800	19600	2-3455	7-3455
1928	262	200069	1	Kg	2800	2800	0-0	0-0
1929	262	200068	37.5	Kg	64	2400	0-0	0-0
1930	263	200069	1	Kg	2800	2800	0-0	0-0
1931	263	200049	1	Kg	61000	61000	0-0	0-0
1932	263	200013	100	Uni	922	92200	0-0	0-0
1933	263	200011	1	Bulto	62105	62105	0-0	0-0
1934	263	200053	1	Bulto	1404	1404	0-0	0-0
1935	264	200068	75	Kg	64	4800	0-0	0-0
1936	264	200069	8	Kg	2800	22400	0-0	0-0
1937	264	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
1938	264	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
1939	264	200007	7.5	Kg	2800	21000	2-3455	7-3455
1940	264	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
1941	264	200008	6	Kg	14900	89400	0-0	0-0
1942	264	200038	6	Kg	9300	55800	0-0	0-0
1943	264	200003	20	Kg	12490	249800	0-0	0-0
1944	264	200058	0.400000000000000022	Kg	628647.040000000037	251458.816000000021	0-0	0-0
1945	264	200064	180	Kg	9300	1674000	31-3035	31-3035
1946	264	200004	112.5	Kg	11700	1316250	49-4393	49-4393
1947	264	200005	112.5	Kg	7980	897750	32-3934	32-3934
1948	264	200092	1300	Metro	1480	1924000	5-304	17-304
1949	265	200075	1	Caja	3736700	3736700	34-2095	69-2095
1950	265	200068	75	Kg	64	4800	0-0	0-0
1951	265	200069	8	Kg	2800	22400	0-0	0-0
1952	265	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
1953	265	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
1954	265	200007	25	Kg	2800	70000	2-3455	7-3455
1955	265	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
1956	265	200008	6	Kg	14900	89400	0-0	0-0
1957	265	200038	6	Kg	9300	55800	0-0	0-0
1958	265	200003	20	Kg	12490	249800	0-0	0-0
1959	265	200085	2	Mts	360	720	12-23992	33-23992
1960	265	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
1961	265	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
1962	265	200059	0.100000000000000006	Kg	304618	30461.8000000000029	0-0	0-0
1963	265	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
1964	265	200028	0.200000000000000011	Kg	90000	18000	0-0	0-0
1965	265	200065	15	Kg	30000	450000	34-485	34-485
1966	265	200065	85	Kg	34000	2890000	34-488	34-488
1967	265	200004	150	Kg	11700	1755000	49-4393	49-4393
1968	265	200005	250	Kg	7980	1995000	32-3934	32-3934
1969	266	200068	22	Kg	64	1408	0-0	0-0
1970	266	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
1971	266	200007	5	Kg	2800	14000	2-3455	7-3455
1972	266	200003	5	Kg	12490	62450	0-0	0-0
1973	266	200035	5	Kg	9687.5	48437.5	0-0	0-0
1974	266	200008	2	Kg	14900	29800	0-0	0-0
1975	266	200038	2	Kg	9300	18600	0-0	0-0
1976	266	200036	0.800000000000000044	Kg	14100	11280	0-0	0-0
1977	266	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
1978	266	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
1979	266	200028	0.0100000000000000002	Kg	90000	900	0-0	0-0
1980	266	200064	80	Kg	9300	744000	31-3035	31-3035
1981	266	200005	75	Kg	7980	598500	32-3934	32-3934
1982	266	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
1983	266	200041	5000	Uni	73.5	367500	0-0	0-0
1984	266	200051	4000	Unidad	40	160000	0-0	0-0
1985	267	200068	5	Kg	64	320	0-0	0-0
1986	267	200035	1	Kg	9687.5	9687.5	0-0	0-0
1987	267	200028	0.299999999999999989	Kg	90000	27000	0-0	0-0
1988	268	100025	40	Kg	4600	184000	0-0	0-0
1989	268	100029	71	Kg	6200	440200	0-0	0-0
1990	268	100006	413.5	Kg	7800	3225300	11-283	11-283
1991	268	100015	117	Kg	2500	292500	12-930	12-930
1992	269	100002	67.2999999999999972	Kg	6900	464370	70-37360	70-37360
1993	269	100002	1506.5	Kg	6900	10394850	79-790607	79-790607
1994	269	100002	335.199999999999989	Kg	6700	2245840	75-991	75-991
1995	269	100015	500	Kg	2500	1250000	12-930	12-930
1996	270	100002	805.5	Kg	6700	5396850	75-991	75-991
1997	271	100002	1030	Kg	6700	6901000	75-991	75-991
1999	271	100015	342.5	Kg	2500	856250	12-930	12-930
2000	271	100007	605.5	Kg	7000	4238500	0-0	0-0
2001	272	200068	11	Kg	64	704	0-0	0-0
2002	272	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2003	272	200008	1	Kg	14900	14900	0-0	0-0
2004	272	200038	1	Kg	9300	9300	0-0	0-0
2005	272	200003	2.5	Kg	12490	31225	0-0	0-0
2006	272	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2007	272	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2008	272	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2009	272	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2010	272	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2011	272	200065	40	Kg	34000	1360000	34-488	34-488
2012	272	200005	37.5	Kg	7980	299250	32-3934	32-3934
2013	272	200058	0.100000000000000006	Kg	628647.040000000037	62864.7040000000052	0-0	0-0
2014	272	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
2015	272	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
2016	272	200082	100	.	2835	283500	0-0	0-0
2017	272	200051	200	Unidad	40	8000	0-0	0-0
2018	272	200007	1.39999999999999991	Kg	140000	196000	7-3423	7-3423
2019	273	200068	75	Kg	64	4800	0-0	0-0
2020	273	200069	8	Kg	2800	22400	0-0	0-0
2021	273	200007	15	Kg	2800	42000	7-3423	7-3423
2022	273	200008	6	Kg	14900	89400	0-0	0-0
2023	273	200038	6	Kg	9300	55800	0-0	0-0
2024	273	200003	15	Kg	12490	187350	0-0	0-0
2025	273	200035	15	Kg	9687.5	145312.5	0-0	0-0
2026	273	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2027	273	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
2028	273	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
2029	273	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2030	273	200058	0.400000000000000022	Kg	628647.040000000037	251458.816000000021	0-0	0-0
2031	273	200064	210	Kg	9300	1953000	31-3035	31-3035
2032	273	200005	225.5	Kg	7980	1799490	32-3934	32-3934
2033	273	200004	225.5	Kg	11750	2649625	37-780	39-780
2034	273	200047	60	Kg	5100	306000	31-3025	31-3025
2035	273	200080	650	Metro	1680	1092000	0-0	0-0
2036	274	200069	1	Kg	2800	2800	0-0	0-0
2037	274	200049	1	Kg	61000	61000	0-0	0-0
2038	275	200013	200	Uni	922	184400	0-0	0-0
2039	275	200076	100	Metro	2770	277000	0-0	0-0
2040	275	200011	5	Bulto	62105	310525	0-0	0-0
2041	275	200053	1	Bulto	1404	1404	0-0	0-0
2042	275	200051	4000	Unidad	40	160000	0-0	0-0
2043	275	200088	110	Metro	0	0	0-0	0-0
2044	275	200047	15	Kg	5100	76500	31-3025	31-3025
2045	276	100002	307	Kg	6200	1903400	78-780607	78-780607
2046	276	100007	80	Kg	7000	560000	0-0	0-0
2047	276	100035	50	Kg	4200	210000	0-0	0-0
2048	277	100002	931	Kg	6200	5772200	78-780607	78-780607
2050	277	100015	358	Kg	2500	895000	12-930	12-930
2052	277	100035	150	Kg	4200	630000	0-0	0-0
2053	278	100022	3942.59999999999991	Kg	5600	22078560	72-2811	72-2811
2054	279	100001	21.5	Kg	6800	146200	71-1907	71-1907
2055	279	100015	0.5	Kg	2500	1250	12-930	12-930
2056	279	100016	40	Kg	5500	220000	71-1907	71-1907
2057	279	100008	20	Kg	7200	144000	0-0	0-0
2058	280	200098	8690	Mts	435	3780150	11-277	17-277
2049	277	100036	120	Kg	3800	456000	77-1337	77-1337
2051	277	100003	676	Kg	6000	4056000	77-1337	77-1337
2059	280	200068	72	Kg	64	4608	0-0	0-0
2060	280	200007	32	Kg	2800	89600	7-3423	7-3423
2061	280	200035	20	Kg	9687.5	193750	0-0	0-0
2062	280	200036	3.20000000000000018	Kg	14100	45120	0-0	0-0
2063	280	200003	20	Kg	12490	249800	0-0	0-0
2064	280	200008	8	Kg	14900	119200	0-0	0-0
2065	280	200038	8	Kg	9300	74400	0-0	0-0
2066	280	200001	11.1999999999999993	Kg	16.2199999999999989	181.663999999999987	0-0	0-0
2067	280	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2068	280	200028	0.200000000000000011	Kg	90000	18000	0-0	0-0
2069	280	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2070	280	200056	0.400000000000000022	Kg	166195	66478	0-0	0-0
2071	280	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
2072	280	200059	0.239999999999999991	Kg	304618	73108.3199999999924	0-0	0-0
2073	280	200064	320	Kg	9300	2976000	31-3035	31-3035
2074	280	200004	200	Kg	11750	2350000	37-780	39-780
2075	280	200005	200	Kg	7980	1596000	32-3934	32-3934
2076	280	200069	8	Kg	2800	22400	0-0	0-0
2077	281	200068	75	Kg	64	4800	0-0	0-0
2078	281	200007	15	Kg	2800	42000	7-3423	7-3423
2079	281	200035	15	Kg	9687.5	145312.5	0-0	0-0
2080	281	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2081	281	200003	15	Kg	12490	187350	0-0	0-0
2082	281	200008	6	Kg	14900	89400	0-0	0-0
2083	281	200038	6	Kg	9300	55800	0-0	0-0
2084	281	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
2085	281	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
2086	281	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2087	281	200064	270	Kg	9300	2511000	31-3035	31-3035
2088	281	200005	150	Kg	7980	1197000	32-3934	32-3934
2090	281	200069	8	Kg	2800	22400	0-0	0-0
2091	281	200058	0.299999999999999989	Kg	628647.040000000037	188594.111999999994	0-0	0-0
2092	281	200058	0.100000000000000006	Kg	701315	70131.5	23-0011021	8-11021
2093	281	200080	650	Metro	1680	1092000	0-0	0-0
2089	281	200004	75	Kg	11750	1762500	37-780	39-780
2094	282	200068	16	Kg	64	1024	0-0	0-0
2095	282	200007	7	Kg	2800	19600	7-3423	7-3423
2096	282	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
2097	282	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
2098	282	200003	6.5	Kg	12490	81185	0-0	0-0
2099	282	200008	1	Kg	14900	14900	0-0	0-0
2100	282	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
2101	282	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2102	282	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2103	282	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2104	282	200065	15	Kg	34000	510000	34-488	34-488
2105	282	200004	50	Kg	11750	587500	37-780	39-780
2106	283	200068	13	Kg	64	832	0-0	0-0
2107	283	200069	2	Kg	2800	5600	0-0	0-0
2108	283	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
2109	283	200007	3.5	Kg	2800	9800	7-3423	7-3423
2110	283	200003	6.5	Kg	12490	81185	0-0	0-0
2111	283	200008	0.800000000000000044	Kg	14900	11920	0-0	0-0
2112	283	200038	1.39999999999999991	Kg	9300	13020	0-0	0-0
2113	283	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2114	283	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2115	283	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2116	283	200065	15	Kg	34000	510000	34-488	34-488
2117	283	200004	50	Kg	11750	587500	37-780	39-780
2118	284	200082	100	.	2835	283500	0-0	0-0
2119	284	200051	100	Unidad	40	4000	0-0	0-0
2120	284	200068	11	Kg	64	704	0-0	0-0
2121	284	200007	1.39999999999999991	Kg	2800	3919.99999999999955	7-3423	7-3423
2122	284	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2123	284	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2124	284	200003	2.5	Kg	12490	31225	0-0	0-0
2125	284	200008	1	Kg	14900	14900	0-0	0-0
2126	284	200038	1	Kg	9300	9300	0-0	0-0
2127	284	200001	2.39999999999999991	Kg	16.2199999999999989	38.9279999999999973	0-0	0-0
2128	284	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2129	284	200031	0.5	Kg	100352	50176	0-0	0-0
2130	284	200058	0.100000000000000006	Kg	701315	70131.5	23-0011021	8-11021
2131	284	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
2132	284	200030	0.140000000000000013	Kg	22000	3080.00000000000045	0-0	0-0
2133	284	200065	40	Kg	34000	1360000	34-488	34-488
2134	284	200005	25	Kg	7980	199500	32-3934	32-3934
2135	284	200004	12.5	Kg	11750	146875	37-780	39-780
2136	285	200068	75	Kg	64	4800	0-0	0-0
2137	285	200007	14	Kg	2800	39200	7-3423	7-3423
2138	285	200069	3	Kg	2800	8400	0-0	0-0
2139	285	200049	1	Kg	61000	61000	0-0	0-0
2140	286	200011	6	Bulto	62105	372630	0-0	0-0
2141	286	200053	1	Bulto	1404	1404	0-0	0-0
2142	286	200013	400	Uni	922	368800	0-0	0-0
2143	287	200068	11.5	Kg	64	736	0-0	0-0
2144	287	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
2145	287	200007	1.5	Kg	2800	4200	7-3423	7-3423
2146	287	200035	2.29999999999999982	Kg	9687.5	22281.25	0-0	0-0
2147	288	200068	10	Kg	64	640	0-0	0-0
2148	288	200035	2	Kg	9687.5	19375	0-0	0-0
2149	288	200028	0.0599999999999999978	Kg	90000	5400	0-0	0-0
2150	288	200064	20	Kg	9300	186000	31-3035	31-3035
2151	289	100025	96	Kg	4600	441600	0-0	0-0
2152	289	100032	44.5	Kg	6000	267000	0-0	0-0
2153	289	100005	2020	Kg	4200	8484000	0-0	0-0
2154	289	100013	929	Kg	7500	6967500	0-0	0-0
2155	289	100007	388	Kg	7000	2716000	0-0	0-0
2157	289	100002	1744.5	Kg	6200	10815900	78-780607	78-780607
2159	289	100016	910	Kg	5500	5005000	71-1907	71-1907
2160	289	100016	289.5	Kg	5500	1592250	11-294	11-294
2156	289	100003	1332.5	Kg	5500	7328750	77-1335	77-1335
2158	289	100002	1345.5	Kg	6900	9283950	80-476609	80-476609
2161	289	100036	120.5	Kg	3800	457900	77-123	77-123
2162	289	100015	840	Kg	2500	2100000	12-930	12-930
2163	289	100029	96	Kg	6200	595200	0-0	0-0
1998	271	100036	118	Kg	3800	448400	77-1335	77-1335
2164	290	200092	1300	Metro	1480	1924000	5-304	17-304
2165	290	200068	75	Kg	64	4800	0-0	0-0
2166	290	200069	8	Kg	2800	22400	0-0	0-0
2167	290	200035	15	Kg	9687.5	145312.5	0-0	0-0
2168	290	200003	20	Kg	12490	249800	0-0	0-0
2169	290	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2170	290	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
2171	290	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
2172	290	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2173	290	200008	6	Kg	14900	89400	0-0	0-0
2174	290	200038	6	Kg	9300	55800	0-0	0-0
2175	290	200058	0.400000000000000022	Kg	701315	280526	23-0011021	8-11021
2176	290	200064	270	Kg	9300	2511000	31-3035	31-3035
2177	290	200094	225	Kg	4550	1023750	32-3934	32-3934
2178	290	200007	15	Kg	2800	42000	7-3423	7-3423
2181	291	100003	425	Kg	5500	2337500	77-1335	77-1335
2182	291	100006	404	Kg	7800	3151200	11-283	11-283
2183	291	100015	723	Kg	2500	1807500	12-930	12-930
2184	291	100025	44.5	Kg	4600	204700	0-0	0-0
2185	291	100017	30.5	Kg	4000	122000	0-0	0-0
2186	291	100036	144	Kg	3800	547200	77-1335	77-1335
2187	291	100036	38.5	Kg	3800	146300	77-1337	77-1337
2188	292	200098	4350	Mts	435	1892250	11-277	17-277
2189	292	200085	14080	Mts	360	5068800	12-23992	33-23992
2190	292	200068	66	Kg	64	4224	0-0	0-0
2191	292	200069	6	Kg	2800	16800	0-0	0-0
2192	292	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2193	292	200007	15	Kg	2800	42000	7-3423	7-3423
2194	292	200035	15	Kg	9687.5	145312.5	0-0	0-0
2195	292	200003	6	Kg	12490	74940	0-0	0-0
2196	292	200008	6	Kg	14900	89400	0-0	0-0
2197	292	200038	8.40000000000000036	Kg	9300	78120	0-0	0-0
2198	292	200001	3.60000000000000009	Kg	16.2199999999999989	58.3919999999999959	0-0	0-0
2199	292	200029	0.160000000000000003	Kg	27.5700000000000003	4.41120000000000001	0-0	0-0
2200	292	200028	0.149999999999999994	Kg	90000	13500	0-0	0-0
2201	292	200060	0.149999999999999994	Kg	647948	97192.1999999999971	0-0	0-0
2202	292	200057	0.0299999999999999989	Kg	565230	16956.8999999999978	3-15102	8-15102
2203	292	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
2204	292	200059	0.0899999999999999967	Kg	304618	27415.619999999999	0-0	0-0
2205	292	200094	150	Kg	4550	682500	32-3934	32-3934
2206	292	200064	240	Kg	9300	2232000	31-3035	31-3035
2207	293	200013	800	Uni	922	737600	0-0	0-0
2208	293	200088	220	Metro	0	0	0-0	0-0
2209	293	200077	120	Metro	3200	384000	0-0	0-0
2210	293	200041	5000	Uni	73.5	367500	0-0	0-0
2211	294	200068	10	Kg	64	640	0-0	0-0
2212	294	200035	2.29999999999999982	Kg	9687.5	22281.25	0-0	0-0
2213	294	200069	1.5	Kg	2800	4200	0-0	0-0
2214	294	200007	1.5	Kg	2800	4200	7-3423	7-3423
2215	294	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
2216	295	200068	5	Kg	64	320	0-0	0-0
2217	295	200035	1	Kg	9687.5	9687.5	0-0	0-0
2218	295	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2219	295	200064	10	Kg	9300	93000	31-3035	31-3035
2220	296	200085	7040	Mts	360	2534400	12-23992	33-23992
2221	296	200098	8700	Mts	435	3784500	11-277	17-277
2222	296	200068	72	Kg	64	4608	0-0	0-0
2223	296	200069	8	Kg	2800	22400	0-0	0-0
2224	296	200007	32	Kg	2800	89600	7-3423	7-3423
2225	296	200035	20	Kg	9687.5	193750	0-0	0-0
2226	296	200036	3.20000000000000018	Kg	14100	45120	0-0	0-0
2227	296	200003	20	Kg	12490	249800	0-0	0-0
2228	296	200008	8	Kg	14900	119200	0-0	0-0
2229	296	200038	8	Kg	9300	74400	0-0	0-0
2230	296	200001	11.1999999999999993	Kg	16.2199999999999989	181.663999999999987	0-0	0-0
2231	296	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2235	296	200056	0.0400000000000000008	Kg	166195	6647.80000000000018	0-0	0-0
2236	296	200059	0.119999999999999996	Kg	304618	36554.1599999999962	0-0	0-0
2237	296	200064	320	Kg	9300	2976000	31-3035	31-3035
2238	296	200005	400	Kg	4600	1840000	0-0	0-0
2239	297	200080	750	Metro	1680	1260000	0-0	0-0
2240	297	200068	44	Kg	64	2816	0-0	0-0
2241	297	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
2242	297	200007	10	Kg	2800	28000	7-3423	7-3423
2243	297	200035	10	Kg	9687.5	96875	0-0	0-0
2244	297	200003	10	Kg	12490	124900	0-0	0-0
2245	297	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
2246	297	200008	4	Kg	14900	59600	0-0	0-0
2247	297	200038	4	Kg	9300	37200	0-0	0-0
2248	297	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
2249	297	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
2250	297	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
2251	297	200058	0.400000000000000022	Kg	701315	280526	23-0011021	8-11021
2252	297	200064	140	Kg	9300	1302000	31-3035	31-3035
2253	297	200005	150	Kg	4600	690000	0-0	0-0
2254	297	2000102	60	Kg	7940	476400	42-3433	7-3433
2255	298	200082	150	.	2835	425250	0-0	0-0
2256	298	200051	200	Unidad	40	8000	0-0	0-0
2257	298	200068	11	Kg	64	704	0-0	0-0
2258	298	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2259	298	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2260	298	200003	2.29999999999999982	Kg	12490	28726.9999999999964	0-0	0-0
2261	298	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2262	298	200007	1.39999999999999991	Kg	2800	3919.99999999999955	7-3423	7-3423
2233	296	200060	0.200000000000000011	Kg	647948	12958.9600000000009	0-0	0-0
2234	296	200057	0.200000000000000011	Kg	565230	11304.6000000000004	3-15102	8-15102
2180	291	100030	78	Kg	7500	585000	48-459	48-459
2179	291	100002	1509.5	Kg	6900	10415550	80-476609	80-476609
2263	298	200008	1	Kg	14900	14900	0-0	0-0
2264	298	200038	1	Kg	9300	9300	0-0	0-0
2265	298	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2266	298	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2267	298	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2268	298	200058	0.100000000000000006	Kg	701315	70131.5	23-0011021	8-11021
2269	298	200055	0.400000000000000022	Kg	99825	39930	0-0	0-0
2270	298	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
2271	298	200064	20	Kg	9300	186000	31-3035	31-3035
2272	298	200065	20	Kg	34000	680000	34-488	34-488
2273	298	200005	57.5	Kg	4600	264500	0-0	0-0
2274	299	200074	303	Metro	1780.42000000000007	539467.260000000009	0-0	0-0
2275	299	200068	22	Kg	64	1408	0-0	0-0
2276	299	200069	2.60000000000000009	Kg	2800	7280	0-0	0-0
2277	299	200007	8	Kg	2800	22400	7-3423	7-3423
2278	299	200035	0.800000000000000044	Kg	9687.5	7750	0-0	0-0
2279	299	200036	5	Kg	14100	70500	0-0	0-0
2280	299	200008	2	Kg	14900	29800	0-0	0-0
2281	299	200038	2	Kg	9300	18600	0-0	0-0
2282	299	200003	5	Kg	12490	62450	0-0	0-0
2283	299	200001	2.79999999999999982	Kg	16.2199999999999989	45.4159999999999968	0-0	0-0
2284	299	200029	1.19999999999999996	Kg	27.5700000000000003	33.0839999999999961	0-0	0-0
2285	299	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
2286	299	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2287	299	200064	60	Kg	9300	558000	31-3035	31-3035
2288	299	200005	75	Kg	4600	345000	0-0	0-0
2289	300	200011	1	Bulto	62105	62105	0-0	0-0
2290	300	200010	2	Bulto	71662.5	143325	30-17276	53-17276
2291	300	200013	100	Uni	922	92200	0-0	0-0
2292	300	200009	1	Bulto	64801.0590000000011	64801.0590000000011	53-17246	53-17246
2293	300	200041	5000	Uni	73.5	367500	0-0	0-0
2294	300	200051	4000	Unidad	40	160000	0-0	0-0
2295	301	200068	10	Kg	64	640	0-0	0-0
2296	301	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
2297	301	200007	1.5	Kg	2800	4200	7-3423	7-3423
2298	301	200069	1.5	Kg	2800	4200	0-0	0-0
2299	301	200035	2.29999999999999982	Kg	9687.5	22281.25	0-0	0-0
2232	296	200028	0.200000000000000011	Kg	90000	1800	0-0	0-0
2300	302	100007	79.5	Kg	7000	556500	0-0	0-0
2301	302	100035	150	Kg	4200	630000	0-0	0-0
2302	302	100003	451	Kg	5500	2480500	77-1335	77-1335
2303	302	100003	348.5	Kg	6000	2091000	77-1337	77-1337
2305	302	100015	732	Kg	2500	1830000	12-930	12-930
2306	302	100002	1579.5	Kg	6400	10108800	10-100713	10-100713
2307	302	100002	2170.5	Kg	6900	14976450	79-790713	79-790713
2308	303	200082	100	.	2835	283500	0-0	0-0
2309	303	200068	11	Kg	64	704	0-0	0-0
2310	303	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2311	303	200007	1.39999999999999991	Kg	2800	3919.99999999999955	7-3423	7-3423
2312	303	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2313	303	200003	2.5	Kg	12490	31225	0-0	0-0
2314	303	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2315	303	200008	1	Kg	14900	14900	0-0	0-0
2316	303	200038	1	Kg	9300	9300	0-0	0-0
2317	303	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2318	303	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2319	303	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2320	303	200058	0.100000000000000006	Kg	701315	70131.5	23-0011021	8-11021
2321	303	200030	0.100000000000000006	Kg	22000	2200	0-0	0-0
2322	303	200055	0.0400000000000000008	Kg	99825	3993	0-0	0-0
2323	303	200065	25	Kg	34000	850000	34-488	34-488
2324	303	200064	20	Kg	9300	186000	31-3035	31-3035
2325	303	200005	37.5	Kg	4600	172500	0-0	0-0
2326	303	200013	1100	Uni	922	1014200	0-0	0-0
2327	303	200009	2	Bulto	64801.0590000000011	129602.118000000002	53-17246	53-17246
2328	303	200010	1	Bulto	71662.5	71662.5	30-17276	53-17276
2329	304	200068	5	Kg	64	320	0-0	0-0
2330	304	200035	1	Kg	9687.5	9687.5	0-0	0-0
2331	304	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2332	304	200064	10	Kg	9300	93000	31-3035	31-3035
2333	305	200098	8700	Mts	435	3784500	11-277	17-277
2335	305	200068	72	Kg	64	4608	0-0	0-0
2336	305	200069	8	Kg	2800	22400	0-0	0-0
2337	305	200035	20	Kg	9687.5	193750	0-0	0-0
2338	305	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2339	305	200003	20	Kg	12490	249800	0-0	0-0
2340	305	200008	8	Kg	14900	119200	0-0	0-0
2341	305	200038	8	Kg	9300	74400	0-0	0-0
2342	305	200001	11.1999999999999993	Kg	16.2199999999999989	181.663999999999987	0-0	0-0
2343	305	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2344	305	200028	0.160000000000000003	Kg	90000	14400	0-0	0-0
2345	305	200007	32	Kg	2800	89600	7-3423	7-3423
2346	305	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
2347	305	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2348	305	200056	0.0400000000000000008	Kg	166195	6647.80000000000018	0-0	0-0
2349	305	200059	0.119999999999999996	Kg	304618	36554.1599999999962	0-0	0-0
2350	305	200005	400	Kg	4600	1840000	0-0	0-0
2351	305	200064	320	Kg	9300	2976000	31-3035	31-3035
2352	306	100002	1250	Kg	6900	8625000	79-790713	79-790713
2353	306	100035	50	Kg	4200	210000	0-0	0-0
2354	306	100025	92	Kg	4600	423200	0-0	0-0
2355	306	100007	79	Kg	7000	553000	0-0	0-0
2356	306	100016	400	Kg	5500	2200000	76-43	76-43
2357	306	100015	483.5	Kg	2500	1208750	12-930	12-930
2358	306	100006	110.5	Kg	7800	861900	11-283	11-283
2359	306	100006	668.5	Kg	10200	6818700	11-111307	11-111307
2334	305	200099	13035	Mts	400	5214000	85-58	85-58
1854	252	100030	362	Kg	7500	2715000	48-459	48-459
2361	307	200099	4345	Mts	400	1738000	85-58	85-58
2362	307	200085	7040	Mts	360	2534400	12-23992	33-23992
2360	306	100006	119	Kg	10200	1213800	11-0298	11-0298
2363	307	200068	72	Kg	64	4608	0-0	0-0
2364	307	200069	8	Kg	2800	22400	0-0	0-0
2365	307	200007	32	Kg	2800	89600	7-3423	7-3423
2366	307	200036	3.20000000000000018	Kg	14100	45120	0-0	0-0
2367	307	200035	20	Kg	9687.5	193750	0-0	0-0
2368	307	200003	20	Kg	12490	249800	0-0	0-0
2369	307	200008	8	Kg	14900	119200	0-0	0-0
2370	307	200038	8	Kg	9300	74400	0-0	0-0
2371	307	200001	11.8000000000000007	Kg	16.2199999999999989	191.395999999999987	0-0	0-0
2372	307	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2373	307	200028	0.200000000000000011	Kg	90000	18000	0-0	0-0
2374	307	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
2375	307	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2376	307	200056	0.0400000000000000008	Kg	166195	6647.80000000000018	0-0	0-0
2377	307	200059	0.119999999999999996	Kg	304618	36554.1599999999962	0-0	0-0
2378	307	200064	320	Kg	9300	2976000	31-3035	31-3035
2379	307	200005	400	Kg	4600	1840000	0-0	0-0
2380	307	200013	900	Uni	922	829800	0-0	0-0
2381	308	100002	1934	Kg	6900	13344600	79-790607	79-790607
2382	308	100015	472	Kg	2500	1180000	12-930	12-930
2383	309	100034	2000	Kg	7000	14000000	0-0	0-0
2386	310	200068	54	Kg	64	3456	0-0	0-0
2387	310	200069	6	Kg	2800	16800	0-0	0-0
2388	310	200007	24	Kg	2800	67200	7-3423	7-3423
2389	310	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2390	310	200035	15	Kg	9687.5	145312.5	0-0	0-0
2391	310	200003	15	Kg	12490	187350	0-0	0-0
2392	310	200008	6	Kg	18500	111000	35-4604	32-4604
2393	310	200038	6	Kg	9300	55800	0-0	0-0
2394	310	200001	8.40000000000000036	Kg	16.2199999999999989	136.24799999999999	0-0	0-0
2395	310	200029	3.60000000000000009	Kg	27.5700000000000003	99.2520000000000095	0-0	0-0
2396	310	200028	0.179999999999999993	Kg	90000	16200	0-0	0-0
2397	310	200060	0.149999999999999994	Kg	647948	97192.1999999999971	0-0	0-0
2398	310	200057	0.149999999999999994	Kg	565230	84784.5	3-15102	8-15102
2399	310	200056	0.0299999999999999989	Kg	166195	4985.84999999999945	0-0	0-0
2400	310	200059	0.0899999999999999967	Kg	304618	27415.619999999999	0-0	0-0
2401	310	200005	300	Kg	4600	1380000	0-0	0-0
2402	310	200064	250	Kg	9300	2325000	31-3035	31-3035
2403	311	200068	15	Kg	64	960	0-0	0-0
2404	311	200035	3.29999999999999982	Kg	9687.5	31968.75	0-0	0-0
2405	311	200064	10	Kg	9300	93000	31-3035	31-3035
2406	311	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2407	311	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
2408	311	200069	1.5	Kg	2800	4200	0-0	0-0
2409	311	200007	1.5	Kg	2800	4200	7-3423	7-3423
2410	311	200013	1400	Uni	922	1290800	0-0	0-0
2411	312	100005	2001	Kg	4200	8404200	0-0	0-0
2412	312	100016	1266	Kg	5500	6963000	11-294	11-294
2413	312	100002	119	Kg	6900	821100	79-790607	79-790607
2414	312	100007	41	Kg	7000	287000	0-0	0-0
2415	312	100025	136	Kg	4600	625600	0-0	0-0
2304	302	100036	68	Kg	4000	272000	77-2343	77-2343
2416	312	100006	1603.5	Kg	10200	16355700	11-0298	11-0298
2417	313	200092	650	Metro	1480	962000	5-304	17-304
2418	313	200068	75	Kg	64	4800	0-0	0-0
2419	313	200069	8	Kg	2800	22400	0-0	0-0
2420	313	200007	15	Kg	2800	42000	7-3423	7-3423
2421	313	200036	2.39999999999999991	Kg	14100	33840	0-0	0-0
2422	313	200035	15	Kg	9687.5	145312.5	0-0	0-0
2423	313	200003	20	Kg	12490	249800	0-0	0-0
2424	313	200008	6	Kg	14900	89400	0-0	0-0
2425	313	200038	6	Kg	9300	55800	0-0	0-0
2426	313	200001	8.19999999999999929	Kg	16.2199999999999989	133.003999999999991	0-0	0-0
2427	313	200029	3.79999999999999982	Kg	27.5700000000000003	104.765999999999991	0-0	0-0
2428	313	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2429	313	200058	0.400000000000000022	Kg	701315	280526	23-0011021	8-11021
2430	313	200064	180	Kg	9300	1674000	31-3035	31-3035
2431	313	200005	225	Kg	7980	1795500	32-3934	32-3934
2432	313	200039	5000	Uni	60	300000	0-0	0-0
2433	313	200013	600	Uni	922	553200	0-0	0-0
2434	314	200099	4345	Mts	400	1738000	85-58	85-58
2435	314	200068	9	Kg	64	576	0-0	0-0
2436	314	200069	1	Kg	2800	2800	0-0	0-0
2437	314	200007	4	Kg	2800	11200	7-3423	7-3423
2438	314	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2439	314	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2440	314	200003	2.5	Kg	12490	31225	0-0	0-0
2441	314	200008	1	Kg	18500	18500	35-4604	32-4604
2442	314	200038	1	Kg	9300	9300	0-0	0-0
2443	314	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2444	314	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2445	314	200028	0.25	Kg	90000	22500	0-0	0-0
2446	314	200060	0.25	Kg	647948	161987	0-0	0-0
2447	314	200057	0.25	Kg	565230	141307.5	3-15102	8-15102
2448	314	200056	0.0500000000000000028	Kg	166195	8309.75	0-0	0-0
2449	314	200059	0.149999999999999994	Kg	304618	45692.6999999999971	0-0	0-0
2450	314	200064	40	Kg	9300	372000	31-3035	31-3035
2451	314	200005	50	Kg	7980	399000	32-3934	32-3934
2452	315	200068	3	Kg	615	1845	49-8229	50-8229
2453	315	200069	1	Kg	2800	2800	0-0	0-0
2454	315	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2455	315	200064	10	Kg	9300	93000	31-3035	31-3035
2456	316	200099	4345	Mts	400	1738000	85-58	85-58
2457	316	200085	7040	Mts	360	2534400	12-23992	33-23992
2458	316	200068	72	Kg	615	44280	49-8229	50-8229
2459	316	200069	8	Kg	2800	22400	0-0	0-0
2460	316	200007	32	Kg	2800	89600	7-3423	7-3423
2461	316	200035	20	Kg	9687.5	193750	0-0	0-0
2462	316	200003	20	Kg	12490	249800	0-0	0-0
2463	316	200036	3.20000000000000018	Kg	14100	45120	0-0	0-0
2464	316	200008	8	Kg	14900	119200	0-0	0-0
2385	310	200085	7040	Mts	360	360	12-23992	33-23992
2465	316	200038	8	Kg	9300	74400	0-0	0-0
2466	316	200001	11.5	Kg	16.2199999999999989	186.529999999999973	0-0	0-0
2467	316	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2468	316	200028	0.25	Kg	90000	22500	0-0	0-0
2469	316	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
2470	316	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2471	316	200056	0.0400000000000000008	Kg	166195	6647.80000000000018	0-0	0-0
2472	316	200059	0.25	Kg	304618	76154.5	0-0	0-0
2473	316	200064	320	Kg	9300	2976000	31-3035	31-3035
2474	316	200005	400	Kg	7980	3192000	32-3934	32-3934
2475	316	200013	400	Uni	922	368800	0-0	0-0
2476	316	200010	9	Bulto	71662.5	644962.5	30-17276	53-17276
2477	317	200080	812.5	Metro	1680	1365000	0-0	0-0
2478	317	200068	44	Kg	64	2816	0-0	0-0
2479	317	200069	10	Kg	2800	28000	0-0	0-0
2480	317	200007	10	Kg	2800	28000	7-3423	7-3423
2481	317	200003	10	Kg	12490	124900	0-0	0-0
2482	317	200035	1.60000000000000009	Kg	9687.5	15500	0-0	0-0
2483	317	200036	4	Kg	14100	56400	0-0	0-0
2484	317	200008	4	Kg	14900	59600	0-0	0-0
2485	317	200038	5.59999999999999964	Kg	9300	52080	0-0	0-0
2486	317	200001	2.39999999999999991	Kg	16.2199999999999989	38.9279999999999973	0-0	0-0
2487	317	200029	0.0200000000000000004	Kg	27.5700000000000003	0.551400000000000001	0-0	0-0
2488	317	200028	0.400000000000000022	Kg	90000	36000	0-0	0-0
2489	317	200058	0.0400000000000000008	Kg	701315	28052.6000000000022	23-0011021	8-11021
2490	317	200005	0.149999999999999994	Kg	7980	1197	32-3934	32-3934
2491	317	200064	320	Kg	9300	2976000	31-3035	31-3035
2492	317	2000102	400	Kg	7940	3176000	42-3433	7-3433
2493	318	200007	1.5	Kg	2800	4200	7-3423	7-3423
2494	318	200068	4	Kg	615	2460	49-8229	50-8229
2495	318	200069	0.200000000000000011	Kg	2800	560	0-0	0-0
2496	319	100003	617	Kg	6000	3702000	77-1337	77-1337
2497	319	100036	248	Kg	4000	992000	77-2343	77-2343
2498	319	100001	20	Kg	6800	136000	71-1907	71-1907
2499	319	100007	256	Kg	7000	1792000	0-0	0-0
2500	319	100002	1366	Kg	6900	9425400	92-1707	92-1707
2501	319	100023	5.59999999999999964	Kg	1200	6720	0-0	0-0
2502	320	100025	157.5	Kg	4600	724500	0-0	0-0
2503	320	100029	301.5	Kg	6200	1869300	0-0	0-0
2504	320	100036	78.5	Kg	4000	314000	77-2343	77-2343
2505	320	100002	385.5	Kg	6900	2659950	92-1707	92-1707
2506	320	100002	1484	Kg	6900	10239600	79-14	79-14
2507	320	100035	188.5	Kg	4200	791700	0-0	0-0
2508	320	100003	850.5	Kg	6000	5103000	77-1337	77-1337
2509	320	100015	297.5	Kg	2500	743750	12-930	12-930
2510	320	100015	367	Kg	3000	1101000	77-771907	77-771907
2511	320	100014	101	Kg	7500	757500	0-0	0-0
2384	310	200099	8690	Mts	400	400	85-58	85-58
2512	321	200099	8690	Mts	400	3476000	85-58	85-58
2513	321	200085	7040	Mts	360	2534400	12-23992	33-23992
2514	321	200068	75	Kg	615	46125	49-8229	50-8229
2515	321	200069	8	Kg	2800	22400	0-0	0-0
2516	321	200036	3.20000000000000018	Kg	14100	45120	0-0	0-0
2517	321	200035	20	Kg	9687.5	193750	0-0	0-0
2518	321	200003	20	Kg	12490	249800	0-0	0-0
2519	321	200008	6	Kg	18500	111000	35-4604	32-4604
2520	321	200038	6	Kg	9300	55800	0-0	0-0
2521	321	200007	25	Kg	2800	70000	7-3423	7-3423
2522	321	200001	11.1999999999999993	Kg	16.2199999999999989	181.663999999999987	0-0	0-0
2523	321	200029	4.79999999999999982	Kg	27.5700000000000003	132.335999999999984	0-0	0-0
2524	321	200028	0.200000000000000011	Kg	90000	18000	0-0	0-0
2525	321	200060	0.200000000000000011	Kg	647948	129589.600000000006	0-0	0-0
2526	321	200057	0.200000000000000011	Kg	565230	113046	3-15102	8-15102
2527	321	200056	0.0400000000000000008	Kg	166195	6647.80000000000018	0-0	0-0
2528	321	200059	0.119999999999999996	Kg	304618	36554.1599999999962	0-0	0-0
2529	321	200064	320	Kg	9300	2976000	31-3035	31-3035
2530	321	200005	400	Kg	5500	2200000	89-4626	32-4626
2531	322	200068	15	Kg	615	9225	49-8229	50-8229
2532	322	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
2533	322	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2534	322	200003	6.5	Kg	12490	81185	0-0	0-0
2535	322	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
2536	322	200008	1	Kg	18500	18500	35-4604	32-4604
2537	322	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
2538	322	200007	7	Kg	2800	19600	7-3423	7-3423
2539	322	200065	15	Kg	34000	510000	34-488	34-488
2540	322	200004	50	Kg	14200	710000	87-4655	49-4655
2541	322	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2542	322	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2543	322	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2544	322	200051	4000	Unidad	40	160000	0-0	0-0
2545	323	200013	1200	Uni	922	1106400	0-0	0-0
2546	323	200010	1	Bulto	71662.5	71662.5	30-17276	53-17276
2547	323	200088	151.5	Metro	0	0	0-0	0-0
2548	324	200068	15	Kg	615	9225	49-8229	50-8229
2549	324	200069	1.80000000000000004	Kg	2800	5040	0-0	0-0
2550	324	200007	7	Kg	2800	19600	7-3423	7-3423
2551	324	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2552	324	200035	4.5	Kg	9687.5	43593.75	0-0	0-0
2553	324	200003	6.5	Kg	12490	81185	0-0	0-0
2554	324	200008	1.39999999999999991	Kg	18500	25900	35-4604	32-4604
2555	324	200038	1.60000000000000009	Kg	9300	14880	0-0	0-0
2556	324	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2557	324	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2558	324	200031	0.0500000000000000028	Kg	100352	5017.60000000000036	0-0	0-0
2559	324	200065	15	Kg	34000	510000	34-488	34-488
2560	324	200004	50	Kg	14200	710000	87-4655	49-4655
2561	325	100029	177.5	Kg	6200	1100500	0-0	0-0
2562	325	100041	494	Kg	10000	4940000	48-483	48-483
2563	325	100012	33.5	Kg	6200	207700	0-0	0-0
2564	325	100013	34.5	Kg	7500	258750	0-0	0-0
2565	325	100025	35	Kg	4600	161000	0-0	0-0
2566	325	100016	340.5	Kg	5500	1872750	76-43	76-43
2567	325	100016	434	Kg	5500	2387000	11-294	11-294
2568	325	100016	428	Kg	5500	2354000	11-298	11-298
2569	325	100003	605.5	Kg	6000	3633000	77-1337	77-1337
2571	325	100015	313	Kg	3000	939000	77-771907	77-771907
2572	326	200068	36	Kg	615	22140	49-8229	50-8229
2573	326	200069	4	Kg	2800	11200	0-0	0-0
2574	326	200007	16	Kg	2800	44800	7-3423	7-3423
2575	326	200035	6	Kg	9687.5	58125	0-0	0-0
2576	326	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
2577	326	200008	4	Kg	14900	59600	0-0	0-0
2578	326	200038	4	Kg	9300	37200	0-0	0-0
2579	326	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
2580	326	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
2581	326	200028	0.100000000000000006	Kg	90000	9000	0-0	0-0
2582	326	200060	0.100000000000000006	Kg	647948	64794.8000000000029	0-0	0-0
2583	326	200057	1	Kg	565230	565230	3-15102	8-15102
2584	326	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
2585	326	200059	0.0599999999999999978	Kg	304618	18277.0799999999981	0-0	0-0
2586	326	200064	160	Kg	9300	1488000	31-3035	31-3035
2587	326	200005	200	Kg	5500	1100000	89-4626	32-4626
2588	326	200003	10	Kg	12490	124900	0-0	0-0
2589	326	200099	8690	Mts	400	3476000	85-58	85-58
2590	326	200077	80	Metro	3200	256000	0-0	0-0
2591	326	200013	500	Uni	922	461000	0-0	0-0
2592	326	200053	1	Bulto	1404	1404	0-0	0-0
2593	327	200068	5	Kg	615	3075	49-8229	50-8229
2594	327	200035	1	Kg	9687.5	9687.5	0-0	0-0
2595	327	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2596	327	200064	10	Kg	9300	93000	31-3035	31-3035
2598	328	100015	253.5	Kg	3000	760500	77-771907	77-771907
2599	328	100016	59	Kg	5500	324500	11-298	11-298
2600	328	100036	22	Kg	4000	88000	77-2343	77-2343
2601	329	200068	125	Kg	64	8000	0-0	0-0
2602	330	200007	25	Kg	2800	70000	7-3423	7-3423
2603	331	200007	10	Kg	2800	28000	7-3423	7-3423
2604	332	200068	10	Kg	615	6150	49-8229	50-8229
2605	332	200069	1	Kg	2800	2800	0-0	0-0
2606	332	200036	0.5	Kg	14100	7050	0-0	0-0
2607	332	200007	2	Kg	2800	5600	7-3423	7-3423
2608	332	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2609	332	200003	2.5	Kg	12490	31225	0-0	0-0
2610	332	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2611	332	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2612	332	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
2613	332	200008	1	Kg	14900	14900	0-0	0-0
2614	332	200038	1	Kg	9300	9300	0-0	0-0
2615	332	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
2616	332	200062	0.100000000000000006	Kg	42000	4200	0-0	0-0
2617	332	200061	0.400000000000000022	Kg	9000	3600	0-0	0-0
2618	332	200064	20	Kg	9300	186000	31-3035	31-3035
2619	332	200005	25	Kg	4600	115000	0-0	0-0
2620	333	200068	11	Kg	615	6765	49-8229	50-8229
2621	333	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2622	333	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2623	333	200007	4.5	Kg	2800	12600	7-3423	7-3423
2624	333	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2625	333	200003	2.5	Kg	12490	31225	0-0	0-0
2626	333	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2627	333	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2628	333	200028	0.0299999999999999989	Kg	90000	2700	0-0	0-0
2629	333	200008	1	Kg	18500	18500	35-4604	32-4604
2630	333	200038	1	Kg	9300	9300	0-0	0-0
2631	333	200059	0.0299999999999999989	Kg	304618	9138.53999999999905	0-0	0-0
2632	333	200064	20	Kg	9300	186000	31-3035	31-3035
2633	333	200005	25	Kg	5500	137500	89-4626	32-4626
2634	334	200013	200	Uni	922	184400	0-0	0-0
2635	334	200074	125	Metro	1780.42000000000007	222552.5	0-0	0-0
2636	334	200068	11	Kg	615	6765	49-8229	50-8229
2637	334	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2638	334	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2639	334	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2640	334	200003	2.5	Kg	12490	31225	0-0	0-0
2641	334	200007	2	Kg	2800	5600	7-3423	7-3423
2642	334	200008	1	Kg	14900	14900	0-0	0-0
2643	334	200038	1	Kg	9300	9300	0-0	0-0
2644	334	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2645	334	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2646	334	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
2647	334	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
2648	334	200064	20	Kg	9300	186000	31-3035	31-3035
2649	334	200005	37.5	Kg	5500	206250	89-4626	32-4626
2650	335	200068	44	Kg	615	27060	49-8229	50-8229
2651	335	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
2652	335	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
2653	335	200035	10	Kg	9687.5	96875	0-0	0-0
2654	335	200003	14	Kg	12490	174860	0-0	0-0
2655	335	200007	5.59999999999999964	Kg	2800	15679.9999999999982	7-3423	7-3423
2656	335	200008	4	Kg	14900	59600	0-0	0-0
2657	335	200038	4	Kg	9300	37200	0-0	0-0
2658	335	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
2659	335	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
2660	335	200028	0.119999999999999996	Kg	90000	10800	0-0	0-0
2661	335	200055	0.400000000000000022	Kg	99825	39930	0-0	0-0
2662	335	200058	0.5	Kg	701315	350657.5	23-0011021	8-11021
2663	335	200005	150	Kg	7980	1197000	32-3934	32-3934
2664	335	200030	0.5	Kg	22000	11000	0-0	0-0
2665	335	200064	150	Kg	9300	1395000	31-3035	31-3035
2666	336	200007	16	Kg	2800	44800	7-3423	7-3423
2667	336	200068	75	Kg	615	46125	49-8229	50-8229
2668	336	200069	6.5	Kg	2800	18200	0-0	0-0
2669	336	200036	0.299999999999999989	Kg	14100	4230	0-0	0-0
2670	336	200008	1.5	Kg	14900	22350	0-0	0-0
2671	336	200035	10	Kg	9687.5	96875	0-0	0-0
2672	336	200065	10	Kg	34000	340000	34-488	34-488
2673	336	200049	1	Kg	61000	61000	0-0	0-0
2570	325	100002	1411	Kg	6900	9735900	80-476730	80-476730
2597	328	100002	952.5	Kg	6900	6572250	80-476730	80-476730
2675	337	200054	1	Rollo	50000	50000	0-0	0-0
2676	338	100002	1002	Kg	6900	6913800	80-476730	80-476730
2677	338	100002	828	Kg	6500	5382000	100-1727	100-1727
2678	338	100005	123.5	Kg	4200	518700	0-0	0-0
2679	338	100006	279	Kg	10200	2845800	11-112107	11-112107
2680	338	100006	180	Kg	10200	1836000	11-111907	11-111907
2681	338	100031	23.5	Kg	3800	89300	0-0	0-0
2682	338	100032	21	Kg	6000	126000	0-0	0-0
2683	338	100035	21	Kg	4200	88200	0-0	0-0
2674	337	200081	1000	Mts	3700	3700000	98-982507	98-982507
2684	339	200068	44	Kg	64	2816	0-0	0-0
2685	339	200069	5.20000000000000018	Kg	2800	14560	0-0	0-0
2686	339	200007	5.59999999999999964	Kg	2800	15679.9999999999982	7-3423	7-3423
2687	339	200036	1.60000000000000009	Kg	14100	22560	0-0	0-0
2688	339	200035	10	Kg	9687.5	96875	0-0	0-0
2689	339	200003	10	Kg	12490	124900	0-0	0-0
2690	339	200008	4	Kg	14900	59600	0-0	0-0
2691	339	200038	4	Kg	9300	37200	0-0	0-0
2692	339	200001	5.59999999999999964	Kg	16.2199999999999989	90.8319999999999936	0-0	0-0
2693	339	200029	2.39999999999999991	Kg	27.5700000000000003	66.1679999999999922	0-0	0-0
2694	339	200028	0.0200000000000000004	Kg	90000	1800	0-0	0-0
2695	339	200058	0.400000000000000022	Kg	701315	280526	23-0011021	8-11021
2696	339	200055	0.119999999999999996	Kg	99825	11979	0-0	0-0
2697	339	200030	0.400000000000000022	Kg	22000	8800	0-0	0-0
2698	339	200005	150	Kg	4600	690000	0-0	0-0
2699	339	200065	35	Kg	34000	1190000	34-488	34-488
2700	339	200065	125	Kg	31768.75	3971093.75	88-390	88-390
2701	340	200068	11	Kg	64	704	0-0	0-0
2702	340	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2703	340	200007	2	Kg	2800	5600	7-3423	7-3423
2704	340	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2705	340	200003	2.5	Kg	12490	31225	0-0	0-0
2706	340	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2707	340	200038	1	Kg	9300	9300	0-0	0-0
2708	340	200008	1	Kg	14900	14900	0-0	0-0
2709	340	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2710	340	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2711	340	200028	0.0500000000000000028	Kg	90000	4500	0-0	0-0
2712	340	200057	0.100000000000000006	Kg	565230	56523	3-15102	8-15102
2713	340	200065	30	Kg	31768.75	953062.5	88-390	88-390
2714	340	200005	37.5	Kg	4600	172500	0-0	0-0
2715	340	200010	1	Bulto	71662.5	71662.5	30-17276	53-17276
2716	340	200009	1	Bulto	64801.0590000000011	64801.0590000000011	53-17246	53-17246
2717	340	200041	5000	Uni	73.5	367500	0-0	0-0
2718	341	200068	9.5	Kg	64	608	0-0	0-0
2719	341	200069	1.30000000000000004	Kg	2800	3640	0-0	0-0
2720	341	200007	3	Kg	2800	8400	7-3423	7-3423
2721	341	200036	0.400000000000000022	Kg	14100	5640	0-0	0-0
2722	341	200003	2.5	Kg	12490	31225	0-0	0-0
2723	341	200035	2.5	Kg	9687.5	24218.75	0-0	0-0
2724	341	200008	1	Kg	14900	14900	0-0	0-0
2725	341	200038	1	Kg	9300	9300	0-0	0-0
2726	341	200001	1.39999999999999991	Kg	16.2199999999999989	22.7079999999999984	0-0	0-0
2727	341	200029	0.599999999999999978	Kg	27.5700000000000003	16.541999999999998	0-0	0-0
2728	341	200060	0.0100000000000000002	Kg	647948	6479.48000000000047	0-0	0-0
2729	341	200056	0.0200000000000000004	Kg	166195	3323.90000000000009	0-0	0-0
2730	341	200059	0.0400000000000000008	Kg	304618	12184.7199999999993	0-0	0-0
2731	341	200065	15	Kg	31768.75	476531.25	88-390	88-390
2732	341	200005	25	Kg	4600	115000	0-0	0-0
2733	342	100002	1401.5	Kg	6500	9109750	100-1727	100-1727
2734	342	100003	226.5	Kg	6000	1359000	77-1337	77-1337
2735	342	100003	116	Kg	6500	754000	77-772007	77-772007
2736	342	100030	377	Kg	10000	3770000	76-86	76-86
2737	342	100006	137.5	Kg	10200	1402500	11-111907	11-111907
2738	342	100025	145	Kg	4600	667000	0-0	0-0
\.


--
-- Data for Name: td_salidad; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY td_salidad (id, ccodsalida, ccantidad, cunidad, cdescripcion) FROM stdin;
\.


--
-- Data for Name: test_salida; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY test_salida (cant_ant, cant_new, cant_tot, codprod) FROM stdin;
378	2	376	100001
6918	2	6916	100002
1885.59999999999991	1	1884.59999999999991	200001
1885.59999999999991	1885.59999999999991	0	200001
378	370	8	100001
6918	6900	18	100002
378	2	376	100001
6918	2	6916	100002
1885.59999999999991	1	1884.59999999999991	200001
1885.59999999999991	1885.59999999999991	0	200001
378	370	8	100001
6918	6900	18	100002
378	2	376	100001
6918	2	6916	100002
1885.59999999999991	1	1884.59999999999991	200001
1885.59999999999991	1885.59999999999991	0	200001
378	370	8	100001
6918	6900	18	100002
\.


--
-- Data for Name: test_trigger; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY test_trigger (val1, val2, val3) FROM stdin;
1	123	1
1	123	1
1	123	1
1	123	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100003	CACHETE DE RES	1
1	si	1
1	si	1
1	si	1
1	si	1
1	si	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
1	123	1
1	123	1
1	123	1
1	123	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100003	CACHETE DE RES	1
1	si	1
1	si	1
1	si	1
1	si	1
1	si	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
1	123	1
1	123	1
1	123	1
1	123	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100003	CACHETE DE RES	1
1	si	1
1	si	1
1	si	1
1	si	1
1	si	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
100002	C.D.M DE POLLO	1
100001	AJO MOLIDO	1
\.


--
-- Data for Name: tm_controlpago; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_controlpago (id, ccodprov, crif, cproveedor, cfecha_emi, cfecha_lim, ccodfact, clote, ctotal, cstatus) FROM stdin;
2	7	J-40088423-3	INVERSIONES VILLAS DE ARAUCA, C.A	2017-06-01	2017-06-01	7-3455	2-3455	2100000	6
3	8	J-31028628-0	AGROSISTEMAS JPJ C.A.	2017-06-01	2017-06-09	8-15102	3-15102	4392110	6
4	9	J-29979062-1	DISTRIBUIDORA SAN JUDAS TADEO, C.A.	2017-06-01	2017-06-01	9-488	9-488	6000000	6
5	10	V-14319430-9	LEAL DELI	2017-06-01	2017-06-01	10-165	10-165	24216500	6
6	11	J-40555419-3	DINATIA GONZALEZ, C.A.	2017-06-01	2017-06-01	11-279	11-279	1049375	6
7	12	V-17496658-0	DISRAMIREZ J.C.	2017-06-01	2017-06-01	12-930	12-930	19000000	6
8	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-06-02	2017-06-02	18-10598	18-10598	33600	6
9	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-06-02	2017-06-02	14-38	14-38	550895.869999999995	6
10	17	J-31751963-9	EMPATEC ALIMENTARIA C.A	2017-06-02	2017-06-08	17-304	5-304	16.5760000000000005	6
11	16	J-31710098-0	FERRETERIA LOS CEDROS, C.A.	2017-06-02	2017-06-07	16-109555	4-109555	43948	6
14	23	J-30219675-2	SERVIPORK, C.A.	2017-06-02	2017-06-02	23-138	23-138	7140000	6
15	19	J-30403069-0	HUPECA, C.A.	2017-06-02	2017-06-02	19-37671	19-37671	41279.9700000000012	6
16	21	J-29833877-6	J.E.P. INVERSIONES, C.A.	2017-06-02	2017-06-02	21-10446	21-10446	39200	6
17	20	J-30554931-1	TECNO SEMARCA, C.A.	2017-06-02	2017-06-02	20-12134	20-12134	110000	6
18	26	J-00268847-5	DISTRIBUIDORA PABE 2011, C.A.	2017-06-06	2017-06-06	26-598	26-598	17625600	6
19	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-06-05	2017-06-05	24-28232	24-28232	259999.940000000002	6
20	31	J-29607862-9	DISTRIBUIDORA AROMA, C.A.	2017-06-05	2017-06-05	31-3025	31-3087	15427500	6
21	31	J-29607862-9	DISTRIBUIDORA AROMA, C.A.	2017-06-05	2017-06-05	31-3025	31-3025	15427500	6
22	28	J-30740411-6	UVFLEX, C.A.	2017-06-05	2017-06-05	28-21409	28-21409	10575102.7200000007	6
59	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-19	2017-06-15	11-1234	11-1234	3270000	6
60	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-19	2017-06-16	11-1235	11-1235	13027100	6
61	49	J-40364961-8	RUARP GROUP. C.A.	2017-06-19	2017-06-23	49-4312	49-4312	6272000	6
62	34	J-29998893-6	HALO TRADE, C.A.	2017-06-20	2017-06-23	34-481	34-481	13664000	6
63	40	J-29423529-8	DISTRIBUIDORA LA FE DE DIOS, C.A.	2017-06-20	2017-06-20	40-2017	40-2017	1063800	6
64	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-20	2017-06-20	11-2017	11-2017	4247100	6
12	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA, C.A.	2017-06-02	2017-06-02	24-28191	24-28191	477120	6
13	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA, C.A.	2017-06-02	2017-06-02	24-28187	24-28187	1168080.1399999999	6
23	12	V-17496658-0	DISRAMIREZ J.C.	2017-06-09	2017-06-08	12-931	12-931	10168800	6
24	10	V-14319430-9	LEAL DELI	2017-06-09	2017-06-07	10-168	10-168	27491750	6
25	34	J-29998893-6	HALO TRADE, C.A.	2017-06-09	2017-06-09	34-468	34-468	8030400	6
26	34	J-29998893-6	HALO TRADE, C.A.	2017-06-09	2017-06-09	34-470	34-470	5353600	6
27	35	J-07527700-7	QUINCALLERIA LA NUEVA, C.A.	2017-06-09	2017-06-06	35-13667	35-13667	14199.9899999999998	6
28	16	J-31710098-0	FERRETERIA LOS CEDROS, C.A.	2017-06-09	2017-06-10	16-109601	16-109601	202119.290000000008	6
29	37	J-30023658-7	RODAMIENTOS CARVAN, C.A.	2017-06-09	2017-06-05	37-234514	37-234514	19000.0200000000004	6
30	38	J-31043303-8	M.C.MARACAY, S.A.	2017-06-13	2017-06-14	38-19198	38-19198	342000	6
31	38	J-31043303-8	M.C.MARACAY, S.A.	2017-06-13	2017-06-14	38-19176	38-19176	3839559.5	6
32	39	J-31565447-4	REPRESENTACIONES RM MAMUT, C.A.	2017-06-13	2017-06-01	39-691	39-691	8848000	6
33	40	J-29423529-8	DISTRIBUIDORA LA FE DE DIOS, C.A.	2017-06-13	2017-06-15	40-2439	40-2439	3336300	6
34	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-06-13	2017-06-21	24-28449	24-28449	181115.239999999991	6
35	44	J-07509056-0	COMERCIAL LA FLORIDA C.A.	2017-06-13	2017-06-22	44-1585	44-1585	500000	6
36	32	J-40093098-7	DIAMENCA, C.A.	2017-06-13	2017-06-13	32-3934	32-3934	20231400	6
37	46	J-40340186-1	INVERSIONES ABEMAR 72, C.A.	2017-06-13	2017-06-29	46-627	46-627	38500	6
38	19	J-30403069-0	HUPECA, C.A.	2017-06-13	2017-06-22	19-37835	19-37835	343485.090000000026	6
39	34	J-29998893-6	HALO TRADE, C.A.	2017-06-13	2017-06-13	34-473	34-473	13384000	6
40	47	V-08816215-0	ERNESTO GONZALO CASTRO CASTILLO F.P.	2017-06-13	2017-06-22	47-127	47-127	594720	6
41	48	J-40739575-0	AGROPECUARIA KREAS C.A.	2017-06-14	2017-06-22	48-492	48-492	3885000	6
42	49	J-40364961-8	RUARP GROUP. C.A.	2017-06-14	2017-06-14	49-4243	49-4243	6272000	6
43	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-06-14	2017-06-21	24-28505	24-28505	230000	6
44	17	J-31751963-9	EMPATEC ALIMENTARIA C.A	2017-06-15	2017-06-16	17-277	11-277	42.3860000000000028	6
45	33	J-30774219-4	UNIKERT DE VENEZUELA, S.A.	2017-06-15	2017-06-21	33-23992	12-23992	28.3850000000000016	6
46	34	J-29998893-6	HALO TRADE, C.A.	2017-06-15	2017-06-22	34-479	34-479	535360	6
47	53	J-30121687-3	POLY BAG DE VENEZUELA, C.A.	2017-06-16	2017-06-15	53-17246	53-17246	1233812.15999999992	6
48	53	J-30121687-3	POLY BAG DE VENEZUELA, C.A.	2017-06-16	2017-06-15	53-17245	53-17245	2883081.60000000009	6
49	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-06-16	2017-06-23	14-42	17-42	910.378000000000043	6
50	25	J-31663568-6	TECHTROL SEGURIDAD INTEGRAL C.A.	2017-06-16	2017-06-16	25-2168	7-2168	7.82599999999999962	6
51	49	J-40364961-8	RUARP GROUP. C.A.	2017-06-19	2017-06-23	49-2329	49-2329	6272000	6
52	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-19	2017-06-07	11-283	11-283	8299200	6
53	48	J-40739575-0	AGROPECUARIA KREAS C.A.	2017-06-19	2017-06-07	48-442	48-442	3885000	6
54	40	J-29423529-8	DISTRIBUIDORA LA FE DE DIOS, C.A.	2017-06-19	2017-06-09	40-1230	40-1230	5206950	6
55	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-19	2017-06-09	11-283100	11-283100	1589200	6
56	45	J-31670131-0	COMERCIALIZADORA AVICOMAR C.A.	2017-06-19	2017-06-09	45-1231	45-1231	6500350	6
57	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-19	2017-06-13	11-1232	11-1232	1406000	6
58	51	J-40792303-0	PRODUCARNES C.A	2017-06-19	2017-06-15	51-1233	51-1233	11415600	6
65	46	J-40340186-1	INVERSIONES ABEMAR 72, C.A.	2017-06-21	2017-06-29	46-0634	46-0634	445088	6
66	57	J-31072763-5	VICSAN DISTRIBUCIONES, C.A.	2017-06-21	2017-06-09	57-27	57-27	12436740	6
67	61	J-30456458-9	REFRI-REPUESTOS NARVAEZ, C.A.	2017-06-23	2017-06-30	61-1691	61-1691	217056	6
68	34	J-29998893-6	HALO TRADE, C.A.	2017-06-23	2017-06-30	34-485	34-485	16800000	6
69	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-23	2017-06-23	11-2306004	11-2306004	7597825	6
70	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-06-23	2017-06-23	11-2306016	11-2306016	4350000	6
71	62	J-29443361-8	GOVICA MARACAY C.A.	2017-06-23	2017-06-23	62-27376	62-27376	1097600	6
72	63	J-30512681-0	MULTISERVICIOS RAISCA C.A.	2017-06-23	2017-06-30	63-1669	63-1669	1624000	6
73	47	V-08816215-0	ERNESTO GONZALO CASTRO CASTILLO F.P.	2017-06-26	2017-07-06	47-128	47-128	156800	6
74	67	J-30994346-4	COLORISIMA ARAGUA	2017-06-29	2017-07-03	67-5814	67-5814	664160	6
75	68	J-40412667-8	MULTISERVICIOS L.G.B. 2014, C.A.	2017-06-29	2017-06-29	68-995	68-995	1344000	6
76	49	J-40364961-8	RUARP GROUP. C.A.	2017-06-29	2017-07-06	49-4393	49-4393	6552000	6
77	34	J-29998893-6	HALO TRADE, C.A.	2017-06-29	2017-07-06	34-488	34-488	11424000	6
78	59	J-07519834-4	FRIGORIFICO BETTOLI C.A.	2017-06-26	2017-07-06	59-347041	25-347041	216269.312000000005	6
79	50	J-30979789-3	FAMELER DE VENEZUELA, C.A.	2017-06-29	2017-07-06	50-6958	16-6958	532.224000000000046	6
80	52	J-31202433-0	SUMINISTROS RAGDE C.A.	2017-06-26	2017-07-06	52-2757	18-2757	227.472000000000008	6
81	8	J-31028628-0	AGROSISTEMAS JPJ C.A.	2017-07-03	2017-07-23	8-11021	23-0011021	3927364	6
82	31	J-29607862-9	DISTRIBUIDORA AROMA, C.A.	2017-07-03	2017-07-31	31-2017220	31-2017220	9374400	6
83	32	J-40093098-7	DIAMENCA, C.A.	2017-07-03	2017-08-04	32-4582	24-004582	15000000	6
84	65	J-31295649-6	HYPER ELECTRICOS ARAGUA, C.A.	2017-07-03	2017-08-05	65-23554	32-0023554	1516623.3600000001	6
85	69	J-31158609-1	DISTRIBUIRA EURO QUALITE, C.A.	2017-07-03	2017-07-31	69-2095	34-2095	41851040	6
86	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-06-21	2017-06-28	18-10628	9-10628	14.952	6
87	70	J-31643385-4	LA GRANJA AVICOLA R.K.F, C.A.	2017-07-04	2017-07-07	70-37360	70-37360	13601970	6
88	71	J-40133493-8	CARNICA, C.A.	2017-07-04	2017-07-11	71-1907	71-1907	21677800	6
89	5	J-31156044-0	LA CASA DEL CHEF C.A.	2017-07-04	2017-07-05	5-123	5-123	15679800	6
90	31	J-29607862-9	DISTRIBUIDORA AROMA, C.A.	2017-07-04	2017-07-04	31-3035	31-3035	46593000	6
91	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-06	2017-07-13	24-28792	24-28792	377641.599999999977	6
92	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-06	2017-07-13	24-28790	24-28790	832832	6
93	72	J-29989780-9	AGROPECUARIA DISPROCARNE C.A.	2017-07-06	2017-07-11	72-2811	72-2811	22078560	6
94	73	J-30892045-2	NIVEAR, C.A.	2017-07-06	2017-07-06	73-947	73-947	896000	6
95	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-06	2017-07-13	24-287993	24-287993	35000	6
96	75	J-40119143-6	INDUSTRIA CARNICA C.A.	2017-07-06	2017-07-13	75-991	75-991	14553740	6
97	76	J-40917852-8	INVERSIONES CARNICOS MYS, C.A.	2017-07-06	2017-07-13	76-43	76-43	3852750	6
98	77	J-12345678-9	DISTRIBUIDORA C.B.II	2017-07-07	2017-07-14	77-770617	77-770617	23003500	6
99	78	J-87654321-9	DISTRIBUIDORES LA J, C.A.	2017-07-07	2017-07-14	78-780607	78-780607	18708500	6
100	79	J-12378954-8	ELIECER, C.A.	2017-07-07	2017-07-14	79-790607	79-790607	10394850	6
101	5	J-31156044-0	LA CASA DEL CHEF C.A.	2017-07-04	2017-07-05	77-123	5-123	15679800	6
102	5	J-31156044-0	LA CASA DEL CHEF C.A.	2017-07-04	2017-07-05	77-123	77-123	15679800	6
103	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-07	2017-07-14	11-294	11-294	8805500	6
104	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-07-07	2017-07-14	14-44	36-44	647486.109999999986	6
105	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-07-07	2017-07-14	14-45	14-45	107287.679999999993	6
106	66	J-07511771-9	CENTRO CONTROL CARABOBO, C.A.	2017-07-07	2017-07-13	66-39005	31-39005	4644640	6
107	64	J-31652664-0	CONTROL TECH	2017-07-07	2017-07-13	64-7969	33-7969	14134442.0299999993	6
108	63	J-30512681-0	MULTISERVICIOS RAISCA C.A.	2017-07-07	2017-07-13	63-1671	63-1671	1848000	6
109	38	J-31043303-8	M.C.MARACAY, S.A.	2017-07-07	2017-07-14	38-19318	38-19318	3960999.35000000009	6
110	7	J-40088423-3	INVERSIONES VILLAS DE ARAUCA, C.A	2017-07-07	2017-07-10	7-3423	7-3423	1568000	6
111	39	J-31565447-4	REPRESENTACIONES RM MAMUT, C.A.	2017-07-07	2017-07-07	39-780	37-780	6580000	6
112	59	J-07519834-4	FRIGORIFICO BETTOLI C.A.	2017-07-07	2017-07-14	59-347540	40-347540	21839.9700000000012	6
113	80	J-12345600-0	POLLO GIGANTES C.A.	2017-07-07	2017-07-14	80-800707	80-800707	19909950	6
114	81	V-12582545-8	INVERSIONES Y SERVICIOS MIGUEL ANGEL FALCON " EL AZABACHE " FP	2017-07-10	2017-07-11	81-212	81-212	255500	6
115	60	J-29467245-0	SHOMI.COM. C.A.	2017-07-10	2017-07-17	60-4458	60-4458	151188.799999999988	6
116	82	J-30835432-5	EXTINTORES MEDANOS C.A.	2017-07-10	2017-07-17	82-14398	82-14398	76160	6
117	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-10	2017-07-17	18-10696	18-10696	75600	6
118	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-10	2017-07-17	18-11703	18-11703	81984	6
119	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-11	2017-07-17	18-11702	18-11702	378560	6
120	19	J-30403069-0	HUPECA, C.A.	2017-07-11	2017-07-17	19-38296	19-38296	57779.989999999998	6
121	32	J-40093098-7	DIAMENCA, C.A.	2017-07-11	2017-07-17	32-4604	35-4604	10360000	6
122	16	J-31710098-0	FERRETERIA LOS CEDROS, C.A.	2017-07-11	2017-07-17	16-110798	16-110798	2077040	6
123	59	J-07519834-4	FRIGORIFICO BETTOLI C.A.	2017-07-11	2017-07-17	59-347725	44-347725	5559926.40000000037	6
124	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-04	2017-07-05	77-1335	77-123	15679800	6
125	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-04	2017-07-05	77-1335	77-1335	15679800	6
126	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-07	2017-07-14	77-1337	77-1337	23003500	6
127	7	J-40088423-3	INVERSIONES VILLAS DE ARAUCA, C.A	2017-07-12	2017-07-12	7-3433	42-3433	23820000	6
128	19	J-30403069-0	HUPECA, C.A.	2017-07-12	2017-07-18	19-38332	19-38332	124046.559999999998	6
129	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-12	2017-07-17	24-28944	24-28944	396592	6
130	84	J-07531485-9	GOMATEC, C.A	2017-07-12	2017-07-12	84-754	84-754	9479.96999999999935	6
131	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-12	2017-07-21	11-111207	11-111207	14524800	6
132	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-12	2017-07-21	77-771207	77-771207	29384000	6
133	53	J-30121687-3	POLY BAG DE VENEZUELA, C.A.	2017-07-12	2017-07-12	53-17276	30-17276	2568384	6
134	79	J-12378954-8	ELIECER, C.A.	2017-07-13	2017-07-21	79-790713	79-790713	20720700	6
135	10	V-14319430-9	LEAL DELI	2017-07-13	2017-07-21	10-100713	10-100713	10108800	6
136	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-17	18-10711	18-10711	250880	6
137	69	J-31158609-1	DISTRIBUIRA EURO QUALITE, C.A.	2017-07-13	2017-07-20	69-1423	45-1423	25660320	6
138	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-13	2017-07-21	11-111307	11-111307	6818700	6
139	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-18	18-10699	18-10699	747264	6
140	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-17	18-10700	18-10700	134400	6
141	85	E-82098831-3	ARTHUR GOLDSMIDT	2017-07-03	2017-07-31	85-58	34-2095	41851040	6
142	85	E-82098831-3	ARTHUR GOLDSMIDT	2017-07-03	2017-07-31	85-58	85-58	41851040	6
143	60	J-29467245-0	SHOMI.COM. C.A.	2017-07-13	2017-07-17	60-4471	60-4471	452368	6
144	60	J-29467245-0	SHOMI.COM. C.A.	2017-07-13	2017-07-04	60-4450	60-4450	146160	6
145	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-18	18-11711	50-11711	250880	6
146	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-14	18-11699	39-11699	747264	6
147	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-13	2017-07-14	18-11700	38-11700	134400	6
148	48	J-40739575-0	AGROPECUARIA KREAS C.A.	2017-07-13	2017-07-08	48-459	48-459	3885000	6
149	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-13	2017-07-21	24-28987	41-28987	2436448.5	6
150	50	J-30979789-3	FAMELER DE VENEZUELA, C.A.	2017-07-13	2017-07-27	50-8229	49-8229	688800	6
151	50	J-30979789-3	FAMELER DE VENEZUELA, C.A.	2017-07-13	2017-07-27	50-8230	46-8230	1913856	6
152	83	V-15364136-2	EDUARDO ARCINIEGAS NIÑO	2017-07-13	2017-07-21	83-40	83-40	912800	6
153	19	J-30403069-0	HUPECA, C.A.	2017-07-13	2017-07-13	19-38393	19-38393	9021.05999999999949	6
154	19	J-30403069-0	HUPECA, C.A.	2017-07-13	2017-07-13	19-38383	19-38383	8250	6
155	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-07-13	2017-07-14	14-53	14-53	663040	6
156	10	V-14319430-9	LEAL DELI	2017-07-13	2017-07-21	10-172	10-172	10108800	6
157	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-14	2017-07-21	11-111407	11-111407	6019750	6
158	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-12	2017-07-21	77-2343	77-771207	29382000	6
159	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-12	2017-07-21	77-2343	77-2343	29382000	6
160	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-14	2017-07-21	11-298	11-111407	6019750	6
161	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-14	2017-07-21	11-298	11-298	6019750	6
162	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-12	2017-07-21	11-0298	11-111207	14524800	6
163	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-12	2017-07-21	11-0298	11-0298	14524800	6
164	32	J-40093098-7	DIAMENCA, C.A.	2017-07-19	2017-07-21	32-4626	89-4626	16500000	6
165	49	J-40364961-8	RUARP GROUP. C.A.	2017-07-19	2017-07-20	49-4655	87-4655	7952000	6
166	49	J-40364961-8	RUARP GROUP. C.A.	2017-07-19	2017-07-21	49-4654	49-4654	7952000	6
167	58	J-40366413-7	PROYECTOS ARM 2013, C.A.	2017-07-19	2017-07-25	58-47	58-47	1634080	6
168	90	V-12063233-3	BRICEÑO CARLOS ALBERTO, F.P.	2017-07-19	2017-07-26	90-359	90-359	449388.799999999988	6
169	91	J-29866536-0	METALMECANICA LA GIOIA C.A.	2017-07-19	2017-07-26	91-2417	91-2417	5877200	6
170	79	J-12378954-8	ELIECER, C.A.	2017-07-19	2017-07-21	79-13	79-13	450800	6
171	79	J-12378954-8	ELIECER, C.A.	2017-07-19	2017-07-21	79-14	79-14	10239600	6
172	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-19	2017-07-26	18-10719	18-10719	513587.200000000012	6
173	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-19	2017-07-26	18-11721	18-11721	72352	6
174	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-19	2017-07-26	18-117709	18-117709	304640	6
175	93	J-31745773-0	CORMASTBAL C.A	2017-07-19	2017-08-02	93-1626	93-1626	627200	6
176	80	J-12345600-0	POLLO GIGANTES C.A.	2017-07-07	2017-07-14	80-476609	80-476609	19909950	6
177	76	J-40917852-8	INVERSIONES CARNICOS MYS, C.A.	2017-07-19	2017-07-21	76-86	76-86	1395000	6
178	48	J-40739575-0	AGROPECUARIA KREAS C.A.	2017-07-19	2017-08-03	48-483	48-483	12799500	6
179	92	J-19132888-0	MONTANO C.A.	2017-07-19	2017-07-17	92-1707	92-1707	12085350	6
180	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-19	2017-07-21	77-771907	77-771907	6457500	6
181	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-19	2017-07-21	11-111907	11-111907	4080000	6
182	77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	2017-07-20	2017-07-28	77-772007	77-772007	19704750	6
215	80	J-12345600-0	POLLO GIGANTES C.A.	2017-07-20	2017-07-21	80-802007	80-802007	13406700	6
216	14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	2017-07-21	2017-07-28	14-56	94-56	126000	6
217	24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	2017-07-21	2017-07-28	24-29107	24-29107	291005.409999999974	6
218	64	J-31652664-0	CONTROL TECH	2017-07-21	2017-07-21	64-7998	51-7998	1849851.3600000001	6
219	76	J-40917852-8	INVERSIONES CARNICOS MYS, C.A.	2017-07-21	2017-07-28	76-89	76-89	19720000	6
220	11	J-40555419-3	DINASTIA GONZALEZ, C.A.	2017-07-21	2017-07-28	11-112107	11-112107	2845800	6
221	89	J-07540453-0	RIMOCA INDUSTRIAL	2017-07-25	2017-07-26	89-2073	90-2073	7696080	6
222	89	J-07540453-0	RIMOCA INDUSTRIAL	2017-07-25	2017-07-26	89-2075	92-2075	376880	6
223	89	J-07540453-0	RIMOCA INDUSTRIAL	2017-07-25	2017-07-26	89-2074	91-2074	26820269.7300000004	6
224	47	V-08816215-0	ERNESTO GONZALO CASTRO CASTILLO F.P.	2017-07-25	2017-07-26	47-130	47-130	856576	6
225	89	J-07540453-0	RIMOCA INDUSTRIAL	2017-07-25	2017-07-26	89-2076	101-2076	7693840	6
257	7	J-40088423-3	INVERSIONES VILLAS DE ARAUCA, C.A	2017-07-25	2017-07-28	7-3538	7-3538	39000015	6
258	98	J-00000000-0	SUMINISTROS DANIMEX	2017-07-25	2017-07-28	98-982507	98-982507	6720000	6
259	80	J-12345600-0	POLLO GIGANTES C.A.	2017-07-20	2017-07-21	80-476730	80-476730	13406700	6
260	63	J-30512681-0	MULTISERVICIOS RAISCA C.A.	2017-07-25	2017-07-26	63-1676	63-1676	2635360	6
261	99	J-40345092-7	DONFI, C.A.	2017-07-25	2017-07-25	99-487	99-487	9641125	6
262	18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	2017-07-25	2017-07-27	18-11734	103-11734	995644.160000000033	6
263	8	J-31028628-0	AGROSISTEMAS JPJ C.A.	2017-07-25	2017-07-27	8-15232	43-15232	619505.599999999977	6
264	9	J-29979062-1	DISTRIBUIDORA SAN JUDAS TADEO, C.A.	2017-07-25	2017-07-28	9-92507	9-92507	10920000	6
265	80	J-12345600-0	POLLO GIGANTES C.A.	2017-07-25	2017-07-28	80-802507	80-802507	22766550	6
266	100	J-29966849-4	EL TRIFOLY, C.A.	2017-07-25	2017-07-28	100-1727	100-1727	21732750	6
267	8	J-31028628-0	AGROSISTEMAS JPJ C.A.	2017-07-26	2017-07-26	8-15262	102-15262	4323110.40000000037	6
268	12	V-17496658-0	DISRAMIREZ J.C.	2017-07-26	2017-07-28	12-943	12-943	30207000	6
269	88	J-40258624-8	AGROALIMENTARIA VENEZUELA	2017-07-26	2017-08-04	88-390	88-390	35581000	6
\.


--
-- Data for Name: tm_entrada_inv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_entrada_inv (id, cconcepto, ctipo_almacen, codprod, cpreparado, caprobado, ca_cant, ctot, cfecha, calmacenp, cncontrol, cobservacion, cncontrol_sal, cid_fact) FROM stdin;
1	entrada	1	900001	0	0	2	26233300	2017-05-23	0	100005		0	0
2	entrada	1	900001	0	0	1	10460000	2017-05-23	0	100007		0	0
3	entrada	2	900001	0	0	2	3880000	2017-05-24	0	100009		0	0
4	entrada	1	900001	0	0	1	5258210	2017-05-24	0	100011		0	0
5	entrada	1	900001	0	0	2	32438000	2017-05-24	0	100013		0	0
6	entrada	2	900001	0	0	1	3200000	2017-05-25	0	100016		0	0
7	entrada	1	900001	14183910	14183910	1	45987500	2017-05-28	14183910	100017		0	0
8	entrada	1	900001	14183910	14183910	1	4502400	2017-05-28	14183910	100020		0	0
9	entrada	1	900001	14183910	14183910	1	11384100	2017-05-28	14183910	100022		0	0
10	entrada	2	900001	14183910	14183910	4	31093750	2017-05-31	14183910	100025		0	0
11	entrada	1	900001	19132888	19132888	4	27386500	2017-05-31	19132888	100027		0	0
12	entrada	1	900001	19132888	19132888	1	3867500	2017-06-01	19132888	100030		0	0
13	entrada	1	900001	19132888	19132888	1	1218250	2017-06-02	19132888	100031		0	0
\.


--
-- Data for Name: tm_entradam; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_entradam (id, ccodfact, cfecha, crecepcion) FROM stdin;
\.


--
-- Data for Name: tm_factura; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_factura (id, cfecha, cfechap, cordencomp, cproveedor, ccodfact, clote, ccon_pago, crecib, caprob, ct_cantp, csubtot, ctot, cstatus, cf_dir, ct_servicio) FROM stdin;
0	2017-01-01	2017-01-01	1	0	0-0	0-0	1	0	0	0	0	0	4	f	f
1	2017-06-01	2017-06-01	2	7	7-3455	2-3455	1	1	1	750	2100000	2100000	4	f	f
2	2017-06-01	2017-06-09	3	8	8-15102	3-15102	2	1	1	25	4392110	4392110	4	f	f
3	2017-06-01	2017-06-01	1	9	9-488	9-488	1	1	1	400	6000000	6000000	4	f	f
4	2017-06-01	2017-06-01	1	10	10-165	10-165	1	1	1	4403	24216500	24216500	4	f	f
5	2017-06-01	2017-06-01	1	11	11-279	11-279	1	1	1	287.5	1049375	1049375	4	f	f
6	2017-06-01	2017-06-01	1	12	12-930	12-930	1	1	1	7600	19000000	19000000	4	f	f
10	2017-06-02	2017-06-02	1	18	18-10598	18-10598	2	1	1	5	30000	33600	4	f	f
9	2017-06-02	2017-06-02	1	14	14-38	14-38	2	1	1	14	491871.320000000007	550895.869999999995	4	f	f
8	2017-06-02	2017-06-08	5	17	17-304	5-304	2	1	1	10000	14.8000000000000007	16.5760000000000005	4	f	f
7	2017-06-02	2017-06-07	4	16	16-109555	4-109555	2	1	1	8	38674.239999999998	43948	4	f	f
19	2017-06-02	2017-06-02	0	23	23-138	23-138	1	1	1	1020	7140000	7140000	4	t	f
38	2017-06-13	2017-06-01	0	39	39-691	39-691	1	1	1	1000	7900000	8848000	4	t	f
39	2017-06-13	2017-06-15	0	40	40-2439	40-2439	2	1	1	1011	3336300	3336300	4	t	f
20	2017-06-02	2017-06-02	0	19	19-37671	19-37671	1	1	1	2	36857.1200000000026	41279.9700000000012	4	t	f
21	2017-06-02	2017-06-02	0	21	21-10446	21-10446	1	1	1	1	35000	39200	4	t	f
22	2017-06-02	2017-06-02	0	20	20-12134	20-12134	1	1	1	1	98214.2899999999936	110000	4	t	f
26	2017-06-05	2017-06-05	0	24	24-28232	24-28232	1	1	1	20	232142.799999999988	259999.940000000002	4	t	f
40	2017-06-13	2017-06-21	0	24	24-28449	24-28449	2	1	1	4	181115.239999999991	181115.239999999991	4	t	f
27	2017-06-05	2017-06-05	0	31	31-3025	31-3025	1	1	1	3015	15427500	15427500	4	t	f
55	2017-06-15	2017-06-22	0	34	34-479	34-479	2	1	1	20	478000	535360	4	t	f
28	2017-06-05	2017-06-05	0	28	28-21409	28-21409	1	1	1	70400	9442056	10575102.7200000007	4	t	f
42	2017-06-13	2017-06-13	0	32	32-3934	32-3934	2	1	1	3000	18795000	20231400	4	t	f
17	2017-06-02	2017-06-02	0	24	24-28191	24-28191	1	1	1	4	426000	477120	4	t	f
18	2017-06-02	2017-06-02	0	24	24-28187	24-28187	1	1	1	5	1042928.69999999995	1168080.1399999999	4	t	f
23	2017-06-06	2017-06-06	0	26	26-598	26-598	1	1	1	4896	17625600	17625600	4	t	f
29	2017-06-09	2017-06-08	0	12	12-931	12-931	1	1	1	3756	10168800	10168800	4	t	f
30	2017-06-09	2017-06-07	0	10	10-168	10-168	1	1	1	4998.5	27491750	27491750	4	t	f
31	2017-06-09	2017-06-09	0	34	34-468	34-468	1	1	1	300	7170000	8030400	4	t	f
32	2017-06-09	2017-06-09	0	34	34-470	34-470	1	1	1	200	4780000	5353600	4	t	f
33	2017-06-09	2017-06-06	0	35	35-13667	35-13667	1	1	1	8	12678.5599999999995	14199.9899999999998	4	t	f
34	2017-06-09	2017-06-10	0	16	16-109601	16-109601	2	1	1	9	180463.649999999994	202119.290000000008	4	t	f
35	2017-06-09	2017-06-05	0	37	37-234514	37-234514	1	1	1	10	16964.2999999999993	19000.0200000000004	4	t	f
56	2017-06-16	2017-06-15	0	53	53-17246	53-17246	1	1	1	17	1101618	1233812.15999999992	4	t	f
57	2017-06-16	2017-06-15	0	53	53-17245	53-17245	1	1	1	56	2574180	2883081.60000000009	4	t	f
46	2017-06-13	2017-06-22	0	47	47-127	47-127	2	1	1	2002	531000	594720	4	t	f
45	2017-06-13	2017-06-13	0	34	34-473	34-473	1	1	1	500	11950000	13384000	4	t	f
44	2017-06-13	2017-06-22	0	19	19-37835	19-37835	2	1	1	13	306683.119999999995	343485.090000000026	4	t	f
36	2017-06-13	2017-06-14	0	38	38-19198	38-19198	1	1	1	20	342000	383040	4	t	f
41	2017-06-13	2017-06-22	0	44	44-1585	44-1585	2	1	1	1	500000	560000	4	t	f
43	2017-06-13	2017-06-29	0	46	46-627	46-627	2	1	1	7	38500	43120	4	t	f
48	2017-06-14	2017-06-14	0	49	49-4243	49-4243	1	1	1	500	5600000	6272000	4	t	f
49	2017-06-14	2017-06-21	0	24	24-28505	24-28505	2	1	1	4	205357.140000000014	230000	4	t	f
58	2017-06-16	2017-06-23	17	14	14-42	17-42	2	1	1	19	812.837999999999965	910.378000000000043	4	f	f
53	2017-06-15	2017-06-16	11	17	17-277	11-277	2	1	1	87000	37845000	42386400	4	f	f
54	2017-06-15	2017-06-21	12	33	33-23992	12-23992	2	1	1	70400	25.3440000000000012	28.3850000000000016	4	f	f
59	2017-06-16	2017-06-16	7	25	25-2168	7-2168	1	1	1	51	6.9870000000000001	7.82599999999999962	4	f	f
63	2017-06-19	2017-06-07	0	11	11-283	11-283	1	1	1	1064	8299200	8299200	4	t	f
67	2017-06-19	2017-06-09	0	40	40-1230	40-1230	1	1	1	1795.5	5206950	5206950	4	t	f
69	2017-06-19	2017-06-09	0	11	11-283100	11-283100	1	1	1	548	1589200	1589200	4	t	f
70	2017-06-19	2017-06-09	0	45	45-1231	45-1231	1	1	1	2241.5	6500350	6500350	4	t	f
71	2017-06-19	2017-06-13	0	11	11-1232	11-1232	1	1	1	351.5	1406000	1406000	4	t	f
72	2017-06-19	2017-06-15	0	51	51-1233	51-1233	1	1	1	1585.5	11415600	11415600	4	t	f
73	2017-06-19	2017-06-15	0	11	11-1234	11-1234	1	1	1	817.5	3270000	3270000	4	t	f
74	2017-06-19	2017-06-16	0	11	11-1235	11-1235	1	1	1	3298	13027100	13027100	4	t	f
80	2017-06-21	2017-06-09	0	57	57-27	57-27	1	1	1	1706	11515500	12436740	4	t	f
60	2017-06-19	2017-06-23	0	49	49-4312	49-4312	2	1	1	1000	11200000	12544000	4	t	f
75	2017-06-20	2017-06-23	0	34	34-481	34-481	2	1	1	500	12200000	13664000	4	t	f
76	2017-06-20	2017-06-20	0	40	40-2017	40-2017	2	1	1	295.5	1063800	1063800	4	t	f
77	2017-06-20	2017-06-20	0	11	11-2017	11-2017	2	1	1	544.5	4247100	4247100	4	t	f
78	2017-06-21	2017-06-29	0	46	46-0634	46-0634	2	1	1	64	397400	445088	4	t	f
81	2017-06-23	2017-06-30	0	61	61-1691	61-1691	2	1	1	7	193800	217056	4	t	f
82	2017-06-23	2017-06-30	0	34	34-485	34-485	1	1	1	500	15000000	16800000	4	t	f
83	2017-06-23	2017-06-23	0	11	11-2306004	11-2306004	2	1	1	1923.5	7597825	7597825	4	t	f
84	2017-06-23	2017-06-23	0	11	11-2306016	11-2306016	2	1	1	1087.5	4350000	4350000	4	t	f
85	2017-06-23	2017-06-23	0	62	62-27376	62-27376	1	1	1	2	980000	1097600	4	t	f
86	2017-06-23	2017-06-30	0	63	63-1669	63-1669	2	1	1	1	1450000	1624000	4	t	f
90	2017-06-26	2017-07-06	0	47	47-128	47-128	2	1	1	4	140000	156800	4	t	f
91	2017-06-29	2017-07-03	0	67	67-5814	67-5814	2	1	1	11	593000	664160	4	t	f
92	2017-06-29	2017-07-06	16	50	50-6958	16-6958	2	1	1	240	475.199999999999989	532.224000000000046	4	f	f
87	2017-06-26	2017-07-06	25	59	59-347041	25-347041	2	1	1	22	193097.600000000006	216269.312000000005	4	f	f
89	2017-06-26	2017-07-06	18	52	52-2757	18-2757	2	1	1	22	203.099999999999994	227.472000000000008	4	f	f
79	2017-06-21	2017-06-28	9	18	18-10628	9-10628	2	1	1	15	13.3499999999999996	14.952	4	f	f
37	2017-06-13	2017-06-14	0	38	38-19176	38-19176	1	1	1	7	4324950.41999999993	4843944.46999999974	4	t	f
93	2017-06-29	2017-06-29	0	68	68-995	68-995	1	1	1	30	1200000	1344000	4	t	f
94	2017-06-29	2017-07-06	0	49	49-4393	49-4393	2	1	1	500	5850000	6552000	4	t	f
95	2017-06-29	2017-07-06	0	34	34-488	34-488	2	1	1	300	10200000	11424000	4	t	f
97	2017-07-03	2017-07-23	23	8	8-11021	23-0011021	1	1	1	5	3506575	3927364	4	f	f
128	2017-07-10	2017-07-11	0	81	81-212	81-212	1	1	1	35	255500	255500	4	t	f
96	2017-07-03	2017-08-04	24	32	32-4582	24-004582	2	1	1	3000	15000000	15000000	4	f	f
98	2017-07-03	2017-08-05	32	65	65-23554	32-0023554	1	1	1	116	1354128	1516623.3600000001	4	f	f
152	2017-07-13	2017-07-17	0	18	18-10700	18-10700	2	1	1	7	120000	134400	4	t	f
101	2017-07-04	2017-07-07	0	70	70-37360	70-37360	2	1	1	1971.29999999999995	13601970	13601970	4	t	f
102	2017-07-04	2017-07-11	0	71	71-1907	71-1907	2	1	1	3622	21677800	21677800	4	t	f
129	2017-07-10	2017-07-17	0	60	60-4458	60-4458	2	1	1	2	134990	151188.799999999988	4	t	f
104	2017-07-04	2017-07-04	0	31	31-3035	31-3035	1	1	1	5010	46593000	46593000	4	t	f
105	2017-07-06	2017-07-13	0	24	24-28792	24-28792	2	1	1	8	337180	377641.599999999977	4	t	f
106	2017-07-06	2017-07-13	0	24	24-28790	24-28790	1	1	1	1	743600	832832	4	t	f
107	2017-07-06	2017-07-11	0	72	72-2811	72-2811	2	1	1	3942.59999999999991	22078560	22078560	4	t	f
108	2017-07-06	2017-07-06	0	73	73-947	73-947	1	1	1	7	800000	896000	4	t	f
109	2017-07-06	2017-07-13	0	24	24-287993	24-287993	2	1	1	1	31250	35000	4	t	f
110	2017-07-06	2017-06-30	0	74	74-2628	74-2628	1	1	1	1	300000	336000	4	t	t
111	2017-07-06	2017-06-29	0	58	58-43	58-43	1	1	1	5	1425000	1596000	4	t	t
112	2017-07-06	2017-07-13	0	75	75-991	75-991	2	1	1	2172.19999999999982	14553740	14553740	4	t	f
113	2017-07-06	2017-07-13	0	76	76-43	76-43	2	1	1	700.5	3852750	3852750	4	t	f
144	2017-07-12	2017-07-21	0	77	77-2343	77-2343	2	1	1	3778.5	29382000	29382000	4	t	f
115	2017-07-07	2017-07-14	0	78	78-780607	78-780607	2	1	1	3017.5	18708500	18708500	4	t	f
116	2017-07-07	2017-07-14	0	79	79-790607	79-790607	2	1	1	1506.5	10394850	10394850	4	t	f
155	2017-07-13	2017-07-04	0	60	60-4450	60-4450	1	1	1	3	130500	146160	4	t	f
117	2017-07-07	2017-07-14	0	11	11-294	11-294	2	1	1	1601	8805500	8805500	4	t	f
118	2017-07-07	2017-07-14	36	14	14-44	36-44	2	1	1	42	578112.599999999977	647486.109999999986	4	f	f
119	2017-07-07	2017-07-14	0	14	14-45	14-45	2	1	1	16	95792.570000000007	107287.679999999993	4	t	f
120	2017-07-07	2017-07-13	31	66	66-39005	31-39005	1	1	1	10	4147000	4644640	4	f	f
121	2017-07-07	2017-07-13	33	64	64-7969	33-7969	1	1	1	19	12620037.5299999993	14134442.0299999993	4	f	f
122	2017-07-07	2017-07-13	0	63	63-1671	63-1671	2	1	1	1	1650000	1848000	4	t	f
123	2017-07-07	2017-07-14	0	38	38-19318	38-19318	2	1	1	68	3536606.56000000006	3960999.35000000009	4	t	f
124	2017-07-07	2017-07-10	0	7	7-3423	7-3423	2	1	1	10	1400000	1568000	4	t	f
125	2017-07-07	2017-07-07	37	39	39-780	37-780	1	1	1	500	5875000	6580000	4	f	f
126	2017-07-07	2017-07-14	40	59	59-347540	40-347540	1	1	1	6	19499.9700000000012	21839.9700000000012	4	f	f
130	2017-07-10	2017-07-17	0	82	82-14398	82-14398	2	1	1	1	68000	76160	4	t	f
131	2017-07-10	2017-07-17	0	18	18-10696	18-10696	2	1	1	96	67500	75600	4	t	f
132	2017-07-10	2017-07-17	0	18	18-11703	18-11703	2	1	1	3	73200	81984	4	t	f
133	2017-07-11	2017-07-17	0	18	18-11702	18-11702	2	1	1	18	338000	378560	4	t	f
134	2017-07-11	2017-07-17	0	19	19-38296	19-38296	2	1	1	3	51589.2799999999988	57779.989999999998	4	t	f
135	2017-07-11	2017-07-17	35	32	32-4604	35-4604	2	1	1	500	9250000	10360000	4	f	f
136	2017-07-11	2017-07-17	0	16	16-110798	16-110798	2	1	1	100	1854500	2077040	4	t	f
137	2017-07-11	2017-07-17	44	59	59-347725	44-347725	2	1	1	72	4964220	5559926.40000000037	4	f	f
103	2017-07-04	2017-07-05	0	77	77-1335	77-1335	1	1	1	3006.5	15679800	15679800	4	t	f
114	2017-07-07	2017-07-14	0	77	77-1337	77-1337	2	1	1	4592	23003500	23003500	4	t	f
138	2017-07-12	2017-07-12	42	7	7-3433	42-3433	1	1	1	3000	23820000	23820000	4	f	f
139	2017-07-12	2017-07-18	0	19	19-38332	19-38332	2	1	1	13	110755.860000000001	124046.559999999998	4	t	f
140	2017-07-12	2017-07-10	0	58	58-46	58-46	1	1	1	5	1625000	1820000	4	t	t
141	2017-07-12	2017-07-17	0	24	24-28944	24-28944	2	1	1	1	354100	396592	4	t	f
142	2017-07-12	2017-07-12	0	84	84-754	84-754	1	1	1	6	8464.26000000000022	9479.96999999999935	4	t	f
143	2017-07-12	2017-07-21	0	11	11-0298	11-0298	2	1	1	1424	14524800	14524800	4	t	f
145	2017-07-12	2017-07-12	30	53	53-17276	30-17276	1	1	1	32	2293200	2568384	4	f	f
146	2017-07-13	2017-07-21	0	79	79-790713	79-790713	2	1	1	3003	20720700	20720700	4	t	f
147	2017-07-13	2017-07-21	0	10	10-172	10-172	2	1	1	2839	18169600	18169600	4	t	f
148	2017-07-13	2017-07-17	0	18	18-10711	18-10711	2	1	1	50	224000	250880	4	t	f
149	2017-07-13	2017-07-20	45	69	69-1423	45-1423	2	1	1	10500	22911000	25660320	4	f	f
150	2017-07-13	2017-07-21	0	11	11-111307	11-111307	2	1	1	668.5	6818700	6818700	4	t	f
151	2017-07-13	2017-07-18	0	18	18-10699	18-10699	2	1	1	8	667200	747264	4	t	f
156	2017-07-13	2017-07-18	50	18	18-11711	50-11711	2	1	1	50	224000	250880	4	f	f
100	2017-07-03	2017-07-31	0	85	85-58	85-58	2	1	1	10	34760000	38931200	4	f	f
153	2017-07-13	2017-07-17	0	60	60-4471	60-4471	2	1	1	6	403900	452368	4	t	f
154	2017-07-13	2017-07-20	0	86	86-2549	86-2549	2	1	1	1	80000	89600	4	t	t
157	2017-07-13	2017-07-14	39	18	18-11699	39-11699	2	1	1	8	667200	747264	4	f	f
158	2017-07-13	2017-07-14	38	18	18-11700	38-11700	2	1	1	7	120000	134400	4	f	f
159	2017-07-13	2017-07-08	0	48	48-459	48-459	2	1	1	518	3885000	3885000	4	t	f
160	2017-07-13	2017-07-21	41	24	24-28987	41-28987	2	1	1	1	2175400.45000000019	2436448.5	4	f	f
161	2017-07-13	2017-07-27	49	50	50-8229	49-8229	2	1	1	1000	615000	688800	4	f	f
162	2017-07-13	2017-07-27	46	50	50-8230	46-8230	2	1	1	960	1708800	1913856	4	f	f
163	2017-07-13	2017-07-21	0	83	83-40	83-40	2	1	1	11	815000	912800	4	t	f
164	2017-07-13	2017-07-13	0	19	19-38393	19-38393	1	1	1	8	8054.52000000000044	9021.05999999999949	4	t	f
165	2017-07-13	2017-07-13	0	19	19-38383	19-38383	1	1	1	2	7366.06999999999971	8250	4	t	f
166	2017-07-13	2017-07-14	0	14	14-53	14-53	1	1	1	16	592000	663040	4	t	f
167	2017-07-14	2017-07-21	0	11	11-298	11-298	2	1	1	1094.5	6019750	6019750	4	t	f
127	2017-07-07	2017-07-14	0	80	80-476609	80-476609	2	1	1	2885.5	19909950	19909950	4	t	f
168	2017-07-19	2017-07-21	89	32	32-4626	89-4626	1	1	1	3000	16500000	16500000	4	f	f
169	2017-07-19	2017-07-20	87	49	49-4655	87-4655	1	1	1	500	7100000	7952000	4	f	f
170	2017-07-19	2017-07-21	0	49	49-4654	49-4654	2	1	1	500	7100000	7952000	4	t	f
171	2017-07-19	2017-07-25	0	58	58-47	58-47	2	1	1	15	1459000	1634080	4	t	f
172	2017-07-19	2017-07-26	0	90	90-359	90-359	2	1	1	10563	401240	449388.799999999988	4	t	f
173	2017-07-19	2017-07-26	0	91	91-2417	91-2417	2	1	1	26	5247500	5877200	4	t	f
174	2017-07-19	2017-07-21	0	79	79-13	79-13	2	1	1	5	402500	450800	4	t	f
175	2017-07-19	2017-07-21	0	79	79-14	79-14	2	1	1	1484	10239600	10239600	4	t	f
176	2017-07-19	2017-07-26	0	18	18-10719	18-10719	2	1	1	6	458560	513587.200000000012	4	t	f
177	2017-07-19	2017-07-26	0	18	18-11721	18-11721	2	1	1	3	64600	72352	4	t	f
178	2017-07-19	2017-07-26	0	18	18-117709	18-117709	2	1	1	1	272000	304640	4	t	f
179	2017-07-19	2017-08-02	0	93	93-1626	93-1626	2	1	1	2	560000	627200	4	t	f
182	2017-07-19	2017-07-21	0	94	94-50	94-50	2	1	1	1	563156	630734.719999999972	4	t	t
183	2017-07-19	2017-07-21	0	24	24-29026	24-29026	2	1	1	1	3150000	3528000	4	t	t
186	2017-07-19	2017-07-20	0	95	95-40733	95-40733	2	1	1	2	1650000	1848000	4	t	t
187	2017-07-19	2017-07-21	0	76	76-86	76-86	2	1	1	139.5	1395000	1395000	4	t	f
188	2017-07-19	2017-08-03	0	48	48-483	48-483	2	1	1	1321	12799500	12799500	4	t	f
189	2017-07-19	2017-07-17	0	92	92-1707	92-1707	1	1	1	1751.5	12085350	12085350	4	t	f
190	2017-07-19	2017-07-21	0	77	77-771907	77-771907	2	1	1	2152.5	6457500	6457500	4	t	f
191	2017-07-19	2017-07-21	0	11	11-111907	11-111907	2	1	1	400	4080000	4080000	4	t	f
192	2017-07-20	2017-07-28	0	77	77-772007	77-772007	2	1	1	3031.5	19704750	19704750	4	t	f
269	2017-07-25	2017-07-26	0	63	63-1676	63-1676	2	1	1	2	2353000	2635360	4	t	f
226	2017-07-21	2017-07-28	94	14	14-56	94-56	2	1	1	3	112500	126000	4	f	f
227	2017-07-21	2017-07-28	0	24	24-29107	24-29107	2	1	1	3	259826.260000000009	291005.409999999974	4	t	f
228	2017-07-21	2017-07-21	51	64	64-7998	51-7998	1	1	1	109	1651653	1849851.3600000001	4	f	f
229	2017-07-21	2017-07-28	0	76	76-89	76-89	2	1	1	1972	19720000	19720000	4	t	f
230	2017-07-21	2017-07-28	0	11	11-112107	11-112107	2	1	1	279	2845800	2845800	4	t	f
231	2017-07-25	2017-07-26	90	89	89-2073	90-2073	2	1	1	98	6871500	7696080	4	f	f
232	2017-07-25	2017-07-26	92	89	89-2075	92-2075	2	1	1	2	336500	376880	4	f	f
233	2017-07-25	2017-07-26	91	89	89-2074	91-2074	2	1	1	8	23946669.3999999985	26820269.7300000004	4	f	f
234	2017-07-25	2017-07-26	0	47	47-130	47-130	0	1	1	2012	764800	856576	4	t	f
235	2017-07-25	2017-07-26	101	89	89-2076	101-2076	1	1	1	1	6869500	7693840	4	f	f
267	2017-07-25	2017-07-28	0	7	7-3538	7-3538	2	1	1	4500	39000000	39000000	4	t	f
268	2017-07-25	2017-07-28	0	98	98-982507	98-982507	2	1	1	2000	6000000	6720000	4	t	f
225	2017-07-20	2017-07-21	0	80	80-476730	80-476730	2	1	1	1943	13406700	13406700	4	t	f
270	2017-07-25	2017-07-25	0	99	99-487	99-487	1	1	1	2268.5	9641125	9641125	4	t	f
271	2017-07-25	2017-07-27	103	18	18-11734	103-11734	2	1	1	209	888968	995644.160000000033	4	f	f
272	2017-07-25	2017-07-27	43	8	8-15232	43-15232	1	1	1	10	553130	619505.599999999977	4	f	f
273	2017-07-25	2017-07-28	0	9	9-92507	9-92507	2	1	1	150	9750000	10920000	4	t	f
274	2017-07-25	2017-07-28	0	80	80-802507	80-802507	0	1	1	3299.5	22766550	22766550	4	t	f
275	2017-07-25	2017-07-28	0	100	100-1727	100-1727	2	1	1	3343.5	21732750	21732750	4	t	f
276	2017-07-26	2017-07-26	102	8	8-15262	102-15262	1	1	1	5	3859920	4323110.40000000037	4	f	f
277	2017-07-26	2017-07-28	0	12	12-943	12-943	2	1	1	5034.5	30207000	30207000	4	t	f
278	2017-07-26	2017-08-04	0	88	88-390	88-390	2	1	1	1000	31768750	35581000	4	t	f
\.


--
-- Data for Name: tm_factura_dir; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_factura_dir (id, cfecha, cfechap, cproveedor, ccodfact, clote, ccon_pago, crecib, caprob, ct_cantp, csubtot, ctot, cstatus) FROM stdin;
\.


--
-- Data for Name: tm_inventario; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_inventario (id, cid_fact, ccodfact, clote, codprod, ct_unidad, ccant, cfechai, cfechaf, cpunit, cfecha_reg) FROM stdin;
390	0	0-0	0-0	100010	Kg	0	2017-01-01	2017-01-01	7700	2017-05-30
400	0	0-0	0-0	100020	Kg	0	2017-01-01	2017-01-01	5510	2017-05-30
401	0	0-0	0-0	100021	Unidad	0	2017-01-01	2017-01-01	30000	2017-05-30
402	0	0-0	0-0	100022	Kg	0	2017-01-01	2017-01-01	4550	2017-05-30
463	0	0-0	0-0	200049	Kg	47	2017-01-01	2017-01-01	61000	2017-05-30
406	0	0-0	0-0	100026	Kg	0	2017-01-01	2017-01-01	2250	2017-05-30
398	0	0-0	0-0	100018	Kg	259	2017-01-01	2017-01-01	2000	2017-05-30
422	0	0-0	0-0	200006	Kg	0	2017-01-01	2017-01-01	0	2017-05-30
430	0	0-0	0-0	200016	Uni	16440	2017-01-01	2017-01-01	5000	2017-05-30
434	0	0-0	0-0	200020	.	0	2017-01-01	2017-01-01	0	2017-05-30
435	0	0-0	0-0	200021	.	0	2017-01-01	2017-01-01	0	2017-05-30
436	0	0-0	0-0	200022	.	0	2017-01-01	2017-01-01	0	2017-05-30
437	0	0-0	0-0	200023	.	0	2017-01-01	2017-01-01	0	2017-05-30
439	0	0-0	0-0	200025	Unidad	0	2017-01-01	2017-01-01	0	2017-05-30
441	0	0-0	0-0	200027	.	0	2017-01-01	2017-01-01	0	2017-05-30
447	0	0-0	0-0	200033	Caja	3	2017-01-01	2017-01-01	540000	2017-05-30
448	0	0-0	0-0	200034	Kg	0	2017-01-01	2017-01-01	73133	2017-05-30
454	0	0-0	0-0	200040	Caja	0	2017-01-01	2017-01-01	61000	2017-05-30
456	0	0-0	0-0	200042	Caja	7	2017-01-01	2017-01-01	1440000	2017-05-30
458	0	0-0	0-0	200044	Caja	10	2017-01-01	2017-01-01	540000	2017-05-30
459	0	0-0	0-0	200045	Caja	3	2017-01-01	2017-01-01	540000	2017-05-30
462	0	0-0	0-0	200048	Litro	0	2017-01-01	2017-01-01	0	2017-05-30
464	0	0-0	0-0	200050	Kg	0	2017-01-01	2017-01-01	0	2017-05-30
466	0	0-0	0-0	200052	Unidad	0	2017-01-01	2017-01-01	0	2017-05-30
477	0	0-0	0-0	200063	.	0	2017-01-01	2017-01-01	0	2017-05-30
480	0	0-0	0-0	200066	Rollo	6	2017-01-01	2017-01-01	1000	2017-05-30
481	0	0-0	0-0	200067	Kg	60	2017-01-01	2017-01-01	70000	2017-05-30
483	0	0-0	0-0	200070	Kg	0	2017-01-01	2017-01-01	0	2017-05-30
484	0	0-0	0-0	200071	.	0	2017-01-01	2017-01-01	6500	2017-05-30
383	0	0-0	0-0	100003	Kg	0	2017-01-01	2017-01-01	3000	2017-05-30
389	0	0-0	0-0	100009	Kg	0	2017-01-01	2017-01-01	0	2017-05-30
438	0	0-0	0-0	200024	Caja	4	2017-01-01	2017-01-01	1118000	2017-05-30
399	0	0-0	0-0	100019	Kg	0	2017-01-01	2017-01-01	0	2017-05-30
468	0	0-0	0-0	200054	Rollo	8	2017-01-01	2017-01-01	50000	2017-05-30
560	36	38-19198	38-19198	300058	Unidad	20	2017-06-13	2017-06-14	17100	2017-06-13
497	0	0-0	0-0	200083	.	0	2017-01-01	2017-01-01	0	2017-05-30
498	0	0-0	0-0	200084	Caja	0	2017-01-01	2017-01-01	0	2017-05-30
501	0	0-0	0-0	200087	Metro	0	2017-01-01	2017-01-01	0	2017-05-30
503	0	0-0	0-0	200089	.	0	2017-01-01	2017-01-01	0	2017-05-30
504	0	0-0	0-0	200090	.	0	2017-01-01	2017-01-01	0	2017-05-30
505	0	0-0	0-0	200091	.	0	2017-01-01	2017-01-01	0	2017-05-30
460	0	0-0	0-0	200046	Caja	1	2017-01-01	2017-01-01	1350000	2017-05-30
514	0	0-0	0-0	302001	.	22000	\N	\N	120	2017-05-30
486	0	0-0	0-0	200073	Mts	55250	2017-01-01	2017-01-01	5000	2017-05-30
433	0	0-0	0-0	200019	Uni	9500	2017-01-01	2017-01-01	1956	2017-05-30
414	0	0-0	0-0	100034	Kg	0	2017-01-01	2017-01-01	7000	2017-05-30
491	0	0-0	0-0	200014	Uni	114000	2017-01-01	2017-01-01	922	2017-05-30
385	0	0-0	0-0	100005	Kg	3691.5	2017-01-01	2017-01-01	4200	2017-05-30
489	0	0-0	0-0	200076	Metro	48520	2017-01-01	2017-01-01	2770	2017-05-30
423	0	0-0	0-0	200007	Kg	0	2017-01-01	2017-01-01	3700	2017-05-30
427	0	0-0	0-0	200011	Bulto	37	2017-01-01	2017-01-01	62105	2017-05-30
502	0	0-0	0-0	200088	Metro	2018.5	2017-01-01	2017-01-01	0	2017-05-30
384	0	0-0	0-0	100004	Kg	0	2017-01-01	2017-01-01	2980	2017-05-30
413	0	0-0	0-0	100033	Kg	13.5	2017-01-01	2017-01-01	3500	2017-05-30
515	0	0-0	0-0	302002	.	6000	\N	\N	189	2017-05-30
410	0	0-0	0-0	100030	Kg	0	2017-01-01	2017-01-01	6000	2017-05-30
388	0	0-0	0-0	100008	Kg	14	2017-01-01	2017-01-01	7200	2017-05-30
403	0	0-0	0-0	100023	Kg	36	2017-01-01	2017-01-01	1200	2017-05-30
500	0	0-0	0-0	200086	Metro	15300	2017-01-01	2017-01-01	2480	2017-05-30
516	0	0-0	0-0	302003	.	20000	\N	\N	200	2017-05-30
425	0	0-0	0-0	200009	Bulto	0	2017-01-01	2017-01-01	62105	2017-05-30
416	0	0-0	0-0	100036	Kg	0	2017-01-01	2017-01-01	3000	2017-05-30
499	0	0-0	0-0	200085	Mts	0	2017-01-01	2017-01-01	360	2017-05-30
431	0	0-0	0-0	200017	Uni	15300	2017-01-01	2017-01-01	5000	2017-05-30
440	0	0-0	0-0	200026	Uni	8750	2017-01-01	2017-01-01	1008	2017-05-30
492	0	0-0	0-0	200078	Metro	2320	2017-01-01	2017-01-01	2620	2017-05-30
418	0	0-0	0-0	200002	Kg	60	2017-01-01	2017-01-01	32	2017-05-30
432	0	0-0	0-0	200018	Uni	36050	2017-01-01	2017-01-01	5000	2017-05-30
404	0	0-0	0-0	100024	Kg	1515	2017-01-01	2017-01-01	7700	2017-05-30
411	0	0-0	0-0	100031	Kg	0	2017-01-01	2017-01-01	3800	2017-05-30
391	0	0-0	0-0	100011	Kg	0	2017-01-01	2017-01-01	7500	2017-05-30
417	0	0-0	0-0	200001	Kg	1240.69999999999914	2017-01-01	2017-01-01	16.2199999999999989	2017-05-30
563	39	40-2439	40-2439	100004	Kg	0	2017-06-13	2017-06-15	3300	2017-06-13
396	0	0-0	0-0	100016	Kg	0	2017-01-01	2017-01-01	4000	2017-05-30
381	0	0-0	0-0	100001	Kg	0	2017-01-01	2017-01-01	6500	2017-05-30
408	0	0-0	0-0	100028	Kg	1846	2017-01-01	2017-01-01	8000	2017-05-30
397	0	0-0	0-0	100017	Kg	59	2017-01-01	2017-01-01	4000	2017-05-30
445	0	0-0	0-0	200031	Kg	4.30000000000000071	2017-01-01	2017-01-01	100352	2017-05-30
566	42	32-3934	32-3934	200094	Kg	0	2017-06-13	2017-06-13	4550	2017-06-13
387	0	0-0	0-0	100007	Kg	2854	2017-01-01	2017-01-01	9000	2017-05-30
476	0	0-0	0-0	200062	Kg	22.8999999999999986	2017-01-01	2017-01-01	42000	2017-05-30
409	0	0-0	0-0	100029	Kg	16.5	2017-01-01	2017-01-01	10000	2017-05-30
392	0	0-0	0-0	100012	Kg	0	2017-01-01	2017-01-01	6200	2017-05-30
393	0	0-0	0-0	100013	Kg	0	2017-01-01	2017-01-01	7500	2017-05-30
446	0	0-0	0-0	200032	Kg	69	2017-01-01	2017-01-01	12900	2017-05-30
451	0	0-0	0-0	200037	Mts	145	2017-01-01	2017-01-01	2677000	2017-05-30
485	0	0-0	0-0	200072	Mts	55250	2017-01-01	2017-01-01	5000	2017-05-30
467	0	0-0	0-0	200053	Bulto	9	2017-01-01	2017-01-01	1404	2017-05-30
394	0	0-0	0-0	100014	Kg	0	2017-01-01	2017-01-01	7500	2017-05-30
465	0	0-0	0-0	200051	Unidad	45700	2017-01-01	2017-01-01	40	2017-05-30
461	0	0-0	0-0	200047	Kg	0	2017-01-01	2017-01-01	3600	2017-05-30
495	0	0-0	0-0	200081	Metro	0	2017-01-01	2017-01-01	1800	2017-05-30
551	31	34-468	34-468	200065	Kg	0	2017-06-09	2017-06-09	23900	2017-06-09
380	0	0-0	0-0	200068	Kg	33383.5	2017-01-01	2017-01-01	64	2017-05-30
522	5	11-279	11-279	100004	Kg	0	2017-06-01	2017-06-01	3650	2017-06-01
493	0	0-0	0-0	200079	Metro	4200	2017-01-01	2017-01-01	867.740000000000009	2017-05-30
496	0	0-0	0-0	200082	.	500	2017-01-01	2017-01-01	2835	2017-05-30
537	20	19-37671	19-37671	300020	Rollo	2	2017-06-02	2017-06-02	13071.4200000000001	2017-06-05
530	7	16-109555	4-109555	300011	Unidad	4	2017-06-02	2017-06-07	4388	2017-06-02
405	0	0-0	0-0	100025	Kg	4742	2017-01-01	2017-01-01	4600	2017-05-30
538	20	19-37671	19-37671	300024	Unidad	1	2017-06-02	2017-06-02	9566.32999999999993	2017-06-05
539	21	21-10446	21-10446	300018	Unidad	1	2017-06-02	2017-06-02	35000	2017-06-05
540	22	20-12134	20-12134	300019	Unidad	1	2017-06-02	2017-06-02	98214.2899999999936	2017-06-05
412	0	0-0	0-0	100032	Kg	0	2017-01-01	2017-01-01	6000	2017-05-30
546	28	28-21409	28-21409	301004	.	54000	2017-06-05	2017-06-05	89.0900000000000034	2017-06-07
531	7	16-109555	4-109555	300012	Unidad	4	2017-06-02	2017-06-07	6599	2017-06-02
547	28	28-21409	28-21409	301007	.	16400	2017-06-05	2017-06-05	282.389999999999986	2017-06-07
536	19	23-138	23-138	100030	Kg	0	2017-06-02	2017-06-02	7000	2017-06-05
478	0	0-0	0-0	200064	Kg	0	2017-01-01	2017-01-01	3200	2017-05-30
382	0	0-0	0-0	100002	Kg	0	2017-01-01	2017-01-01	5500	2017-05-30
415	0	0-0	0-0	100035	Kg	2719	2017-01-01	2017-01-01	4200	2017-05-30
553	33	35-13667	35-13667	300051	Unidad	2	2017-06-09	2017-06-06	1741.06999999999994	2017-06-09
541	23	26-598	26-598	100003	Kg	0	2017-06-06	2017-06-06	3600	2017-06-07
554	33	35-13667	35-13667	300053	Unidad	4	2017-06-09	2017-06-06	1428.56999999999994	2017-06-09
564	40	24-28449	24-28449	300060	Unidad	4	2017-06-13	2017-06-21	45278.8099999999977	2017-06-13
561	37	38-19176	38-19176	300059	Unidad	7	2017-06-13	2017-06-14	548508.5	2017-06-13
482	0	0-0	0-0	200069	Kg	2447.99999999999955	2017-01-01	2017-01-01	2800	2017-05-30
568	43	46-627	46-627	300062	GALON	7	2017-06-13	2017-06-29	5500	2017-06-13
507	0	0-0	0-0	301001	.	11000	2017-01-01	\N	252	2017-05-30
508	0	0-0	0-0	301002	.	16500	2017-01-01	\N	252	2017-05-30
520	3	9-488	9-488	100021	Unidad	0	2017-06-01	2017-06-01	30000	2017-06-01
550	30	10-168	10-168	100002	Kg	0	2017-06-09	2017-06-07	5500	2017-06-09
488	0	0-0	0-0	200075	Caja	0	2017-01-01	2017-01-01	2950000	2017-05-30
549	29	12-931	12-931	100006	Kg	0	2017-06-09	2017-06-08	3600	2017-06-09
521	4	10-165	10-165	100002	Kg	0	2017-06-01	2017-06-01	5500	2017-06-01
529	8	17-304	5-304	200092	Metro	0	2017-06-02	2017-06-08	1480	2017-06-02
579	46	47-127	47-127	300072	Unidad	2000	2017-06-13	2017-06-22	245	2017-06-13
580	46	47-127	47-127	300073	Unidad	2	2017-06-13	2017-06-22	20500	2017-06-13
419	0	0-0	0-0	200003	Kg	1370.20000000000005	2017-01-01	2017-01-01	12490	2017-05-30
506	0	0-0	0-0	200013	Uni	181725	2017-01-01	2017-01-01	922	2017-05-30
555	33	35-13667	35-13667	300052	Unidad	2	2017-06-09	2017-06-06	1741.06999999999994	2017-06-09
494	0	0-0	0-0	200080	Mts	687.5	2017-01-01	2017-01-01	1680	2017-05-30
542	26	24-28232	24-28232	300030	Rollo	10	2017-06-05	2017-06-05	14285.7099999999991	2017-06-07
509	0	0-0	0-0	301003	.	6000	\N	\N	580	2017-05-30
510	0	0-0	0-0	301004	.	17000	\N	\N	88	2017-05-30
511	0	0-0	0-0	301005	.	14000	\N	\N	226	2017-05-30
512	0	0-0	0-0	301006	.	12000	\N	\N	200	2017-05-30
513	0	0-0	0-0	301007	.	3000	\N	\N	200	2017-05-30
548	29	12-931	12-931	100015	Kg	0	2017-06-09	2017-06-08	2500	2017-06-09
519	2	8-15102	3-15102	200034	Kg	20	2017-06-01	2017-06-09	78298	2017-06-01
407	0	0-0	0-0	100027	Kg	70	2017-01-01	2017-01-01	4000	2017-05-30
395	0	0-0	0-0	100015	Kg	0	2017-01-01	2017-01-01	1800	2017-05-30
534	18	24-28187	24-28187	300023	Unidad	5	2017-06-02	2017-06-02	208585.739999999991	2017-06-05
533	17	24-28191	24-28191	300022	Unidad	2	2017-06-02	2017-06-02	148500	2017-06-05
556	34	16-109601	16-109601	300054	Unidad	3	2017-06-09	2017-06-10	10199	2017-06-09
523	6	12-930	12-930	100015	Kg	0	2017-06-01	2017-06-01	2500	2017-06-01
524	10	18-10598	18-10598	300017	Unidad	5	2017-06-02	2017-06-02	6000	2017-06-02
532	17	24-28191	24-28191	300021	Unidad	2	2017-06-02	2017-06-02	64500	2017-06-05
386	0	0-0	0-0	100006	Kg	0	2017-01-01	2017-01-01	5700	2017-05-30
525	9	14-38	14-38	300013	Unidad	5	2017-06-02	2017-06-02	31846.5600000000013	2017-06-02
487	0	0-0	0-0	200074	Metro	6187	2017-01-01	2017-01-01	1780.42000000000007	2017-05-30
526	9	14-38	14-38	300015	Kilo	5	2017-06-02	2017-06-02	48160	2017-06-02
527	9	14-38	14-38	300014	Unidad	2	2017-06-02	2017-06-02	7939.26000000000022	2017-06-02
543	26	24-28232	24-28232	300029	Rollo	10	2017-06-05	2017-06-05	8928.56999999999971	2017-06-07
426	0	0-0	0-0	200010	Bulto	0	2017-01-01	2017-01-01	62105	2017-05-30
535	0	0-0	0-0	200093	Kg	825	\N	\N	16.2199999999999989	2017-06-05
528	9	14-38	14-38	300016	Bulto	2	2017-06-02	2017-06-02	37980	2017-06-02
442	0	0-0	0-0	200028	Kg	3.99999999999999911	2017-01-01	2017-01-01	90000	2017-05-30
557	34	16-109601	16-109601	300055	Unidad	3	2017-06-09	2017-06-10	38303.4300000000003	2017-06-09
449	0	0-0	0-0	200035	Kg	1284.00000000000023	2017-01-01	2017-01-01	9687.5	2017-05-30
558	34	16-109601	16-109601	300056	Unidad	3	2017-06-09	2017-06-10	11652.1200000000008	2017-06-09
424	0	0-0	0-0	200008	Kg	367.5	2017-01-01	2017-01-01	14900	2017-05-30
421	0	0-0	0-0	200005	Kg	617.5	2017-01-01	2017-01-01	4600	2017-05-30
429	0	0-0	0-0	200015	Uni	6300	2017-01-01	2017-01-01	5000	2017-05-30
545	27	31-3025	31-3025	200061	Kg	13.9000000000000004	2017-06-05	2017-06-05	8500	2017-06-07
559	35	37-234514	37-234514	300057	Unidad	10	2017-06-09	2017-06-05	1696.43000000000006	2017-06-09
518	2	8-15102	3-15102	200057	Kg	7.70000000000000284	2017-06-01	2017-06-09	565230	2017-06-01
475	0	0-0	0-0	200061	Kg	12.6999999999999993	2017-01-01	2017-01-01	9000	2017-05-30
472	0	0-0	0-0	200058	Kg	0	2017-01-01	2017-01-01	628647.040000000037	2017-05-30
469	0	0-0	0-0	200055	Kg	1.08000000000000007	2017-01-01	2017-01-01	99825	2017-05-30
455	0	0-0	0-0	200041	Uni	515000	2017-01-01	2017-01-01	73.5	2017-05-30
444	0	0-0	0-0	200030	Kg	11.4000000000000004	2017-01-01	2017-01-01	22000	2017-05-30
565	41	44-1585	44-1585	300061	Unidad	1	2017-06-13	2017-06-22	500000	2017-06-13
569	44	19-37835	19-37835	300063	Unidad	2	2017-06-13	2017-06-22	36642.8499999999985	2017-06-13
570	44	19-37835	19-37835	300064	Unidad	1	2017-06-13	2017-06-22	13392.8600000000006	2017-06-13
571	44	19-37835	19-37835	300066	Unidad	1	2017-06-13	2017-06-22	75000	2017-06-13
572	44	19-37835	19-37835	300065	Unidad	1	2017-06-13	2017-06-22	11785.7199999999993	2017-06-13
573	44	19-37835	19-37835	300071	Unidad	2	2017-06-13	2017-06-22	1470.84999999999991	2017-06-13
574	44	19-37835	19-37835	300067	Unidad	2	2017-06-13	2017-06-22	20892.8499999999985	2017-06-13
575	44	19-37835	19-37835	300070	Unidad	1	2017-06-13	2017-06-22	37714.3000000000029	2017-06-13
576	44	19-37835	19-37835	300068	Unidad	1	2017-06-13	2017-06-22	7920	2017-06-13
577	44	19-37835	19-37835	300069	Unidad	2	2017-06-13	2017-06-22	21428.5699999999997	2017-06-13
457	0	0-0	0-0	200043	Uni	105000	2017-01-01	2017-01-01	30	2017-05-30
592	58	14-42	17-42	300077	Uni	1	2017-06-16	2017-06-23	696428.569999999949	2017-06-16
593	58	14-42	17-42	300079	Uni	6	2017-06-16	2017-06-23	9598.20999999999913	2017-06-16
594	58	14-42	17-42	300078	Uni	12	2017-06-16	2017-06-23	4901.71000000000004	2017-06-16
595	59	25-2168	7-2168	300026	Uni	17	2017-06-16	2017-06-16	358200	2017-06-16
596	59	25-2168	7-2168	300027	Uni	17	2017-06-16	2017-06-16	34150	2017-06-16
552	32	34-470	34-470	200065	Kg	0	2017-06-09	2017-06-09	23900	2017-06-09
597	59	25-2168	7-2168	300028	Uni	17	2017-06-16	2017-06-16	18700	2017-06-16
602	69	11-283100	11-283100	100004	Kg	0	2017-06-19	2017-06-09	2900	2017-06-19
628	93	68-995	68-995	100021	Uni	0	2017-06-29	2017-06-29	40000	2017-06-29
603	70	45-1231	45-1231	100004	Kg	0	2017-06-19	2017-06-09	2900	2017-06-19
601	67	40-1230	40-1230	100004	Kg	0	2017-06-19	2017-06-09	2900	2017-06-19
631	87	59-347041	25-347041	300089	Caja	1	2017-06-26	2017-07-06	71735	2017-06-30
420	0	0-0	0-0	200004	Kg	0	2017-01-01	2017-01-01	10000	2017-05-30
605	72	51-1233	51-1233	100006	Kg	0	2017-06-19	2017-06-15	7200	2017-06-19
632	87	59-347041	25-347041	300090	Caja	1	2017-06-26	2017-07-06	74562	2017-06-30
633	87	59-347041	25-347041	300094	Bulto	20	2017-06-26	2017-07-06	2340.0300000000002	2017-06-30
634	92	50-6958	16-6958	200095	Litro	240	2017-06-29	2017-07-06	1980	2017-06-30
428	0	0-0	0-0	200012	Caja	5.5	2017-01-01	2017-01-01	2775000	2017-05-30
635	89	52-2757	18-2757	300080	Mts	10	2017-06-26	2017-07-06	12960	2017-06-30
607	74	11-1235	11-1235	100004	Kg	1923.5	2017-06-19	2017-06-16	3950	2017-06-19
479	0	0-0	0-0	200065	Kg	0	2017-01-01	2017-01-01	17798	2017-05-30
588	80	57-27	57-27	100037	Kg	0	2017-06-09	2017-06-09	6750	2017-06-09
583	49	24-28505	24-28505	300074	Unidad	2	2017-06-14	2017-06-21	87500	2017-06-14
584	49	24-28505	24-28505	300075	Unidad	1	2017-06-14	2017-06-21	15178.5699999999997	2017-06-14
562	38	39-691	39-691	200004	Kg	0	2017-06-13	2017-06-01	7900	2017-06-13
610	77	11-2017	11-2017	100006	Kg	0	2017-06-20	2017-06-20	7800	2017-06-20
598	60	49-4312	49-4312	200004	Kg	0	2017-06-19	2017-06-23	11200	2017-06-19
621	85	62-27376	62-27376	3000100	Uni	2	2017-06-23	2017-06-23	490000	2017-06-23
585	49	24-28505	24-28505	300076	Unidad	1	2017-06-14	2017-06-21	15178.5699999999997	2017-06-14
622	86	63-1669	63-1669	3000101	Uni	1	2017-06-23	2017-06-30	1450000	2017-06-23
452	0	0-0	0-0	200038	Kg	1730.20000000000027	2017-01-01	2017-01-01	9300	2017-05-30
623	90	47-128	47-128	300073	Uni	4	2017-06-26	2017-07-06	35000	2017-06-26
624	91	67-5814	67-5814	3000120	GALON	2	2017-06-29	2017-07-03	88000	2017-06-29
625	91	67-5814	67-5814	3000121	GALON	3	2017-06-29	2017-07-03	88000	2017-06-29
636	89	52-2757	18-2757	300081	Mts	10	2017-06-26	2017-07-06	7350	2017-06-30
626	91	67-5814	67-5814	3000122	Uni	3	2017-06-29	2017-07-03	8000	2017-06-29
471	0	0-0	0-0	200057	Kg	0	2017-01-01	2017-01-01	522453	2017-05-30
627	91	67-5814	67-5814	3000123	Uni	3	2017-06-29	2017-07-03	43000	2017-06-29
589	55	34-479	34-479	200065	Kg	0	2017-06-15	2017-06-22	23900	2017-06-15
599	63	11-283	11-283	100006	Kg	0	2017-06-19	2017-06-07	7800	2017-06-19
619	83	11-2306004	11-2306004	100004	Kg	0	2017-06-23	2017-06-23	3950	2017-06-23
615	0	40-2017	40-2017	100002	Kg	0	2017-06-20	2017-06-20	5500	2017-06-20
443	0	0-0	0-0	200029	Kg	1480.68000000000097	2017-01-01	2017-01-01	27.5700000000000003	2017-05-30
606	73	11-1234	11-1234	100016	Kg	0	2017-06-19	2017-06-15	4000	2017-06-19
609	76	40-2017	40-2017	100004	Kg	0	2017-06-20	2017-06-20	3600	2017-06-20
620	84	11-2306016	11-2306016	100016	Kg	0	2017-06-23	2017-06-23	4000	2017-06-23
474	0	0-0	0-0	200060	Kg	84.7899999999999778	2017-01-01	2017-01-01	647948	2017-05-30
587	54	33-23992	12-23992	200085	Mts	61600	2017-06-15	2017-06-21	360	2017-06-15
578	45	34-473	34-473	200065	Kg	0	2017-06-13	2017-06-13	23900	2017-06-13
608	75	34-481	34-481	200065	Kg	0	2017-06-20	2017-06-23	24400	2017-06-20
616	81	61-1691	61-1691	300098	Uni	6	2017-06-23	2017-06-30	19800	2017-06-23
517	1	7-3455	2-3455	200007	Kg	0	2017-06-01	2017-06-01	2800	2017-06-01
617	81	61-1691	61-1691	300099	Uni	1	2017-06-23	2017-06-30	75000	2017-06-23
611	78	46-0634	46-0634	300062	GALON	30	2017-06-21	2017-06-29	5500	2017-06-21
612	78	46-0634	46-0634	300083	GALON	32	2017-06-21	2017-06-29	5450	2017-06-21
613	78	46-0634	46-0634	300084	Litro	2	2017-06-21	2017-06-29	29000	2017-06-21
582	48	49-4243	49-4243	200004	Kg	0	2017-06-14	2017-06-14	11200	2017-06-14
591	57	53-17245	53-17245	200011	Bulto	0	2017-06-16	2017-06-15	45967.5	2017-06-16
604	71	11-1232	11-1232	100016	Kg	0	2017-06-19	2017-06-13	4000	2017-06-19
630	95	34-488	34-488	200065	Kg	0	2017-06-29	2017-07-06	34000	2017-06-29
590	56	53-17246	53-17246	200009	Bulto	15	2017-06-16	2017-06-15	64801.0590000000011	2017-06-16
453	0	0-0	0-0	200039	Uni	375800	2017-01-01	2017-01-01	60	2017-05-30
450	0	0-0	0-0	200036	Kg	309.600000000000193	2017-01-01	2017-01-01	14100	2017-05-30
473	0	0-0	0-0	200059	Kg	10.9000000000000039	2017-01-01	2017-01-01	304618	2017-05-30
490	0	0-0	0-0	200077	Metro	11080	2017-01-01	2017-01-01	3200	2017-05-30
693	121	64-7969	33-7969	3000105	Uni	1	2017-07-07	2017-07-13	376094.010000000009	2017-07-07
694	121	64-7969	33-7969	3000109	Uni	2	2017-07-07	2017-07-13	1995386.62000000011	2017-07-07
640	98	65-23554	32-0023554	3000111	Uni	8	2017-07-03	2017-08-05	64102	2017-07-03
641	98	65-23554	32-0023554	3000112	Uni	1	2017-07-03	2017-08-05	50700	2017-07-03
642	98	65-23554	32-0023554	3000113	Uni	1	2017-07-03	2017-08-05	4800	2017-07-03
643	98	65-23554	32-0023554	3000115	Uni	5	2017-07-03	2017-08-05	136610	2017-07-03
644	98	65-23554	32-0023554	3000110	Uni	1	2017-07-03	2017-08-05	102762	2017-07-03
695	121	64-7969	33-7969	3000106	Uni	2	2017-07-07	2017-07-13	1922257.21999999997	2017-07-07
696	121	64-7969	33-7969	3000107	Uni	2	2017-07-07	2017-07-13	1473034	2017-07-07
646	79	18-10628	9-10628	300032	Uni	5	2017-06-21	2017-06-28	1230	2017-07-03
647	79	18-10628	9-10628	300033	Uni	5	2017-06-21	2017-06-28	720	2017-07-03
648	79	18-10628	9-10628	300034	Uni	5	2017-06-21	2017-06-28	720	2017-07-03
697	121	64-7969	33-7969	3000108	Uni	12	2017-07-07	2017-07-13	121882.320000000007	2017-07-07
698	122	63-1671	63-1671	3000141	Uni	1	2017-07-07	2017-07-13	1650000	2017-07-07
699	123	38-19318	38-19318	3000142	Uni	68	2017-07-07	2017-07-14	52008.9199999999983	2017-07-07
702	126	59-347540	40-347540	3000133	Bulto	3	2017-07-07	2017-07-14	3574.98999999999978	2017-07-07
703	126	59-347540	40-347540	3000134	Bulto	3	2017-07-07	2017-07-14	2925	2017-07-07
716	134	19-38296	19-38296	300063	Uni	1	2017-07-11	2017-07-17	45803.5599999999977	2017-07-11
667	107	72-2811	72-2811	100022	Kg	0	2017-07-06	2017-07-11	5600	2017-07-06
645	100	69-2095	34-2095	200075	Caja	8	2017-07-03	2017-07-31	3736700	2017-07-03
704	127	80-476609	80-476609	100002	Kg	0	2017-07-07	2017-07-14	6900	2017-07-07
618	82	34-485	34-485	200065	Kg	0	2017-06-23	2017-06-30	30000	2017-06-23
650	102	71-1907	71-1907	100016	Kg	0	2017-07-04	2017-07-11	5500	2017-07-04
677	116	79-790607	79-790607	100002	Kg	0	2017-07-07	2017-07-14	6900	2017-07-07
673	113	76-43	76-43	100016	Kg	0	2017-07-06	2017-07-13	5500	2017-07-06
651	102	71-1907	71-1907	100034	Kg	0	2017-07-04	2017-07-11	6000	2017-07-04
709	130	82-14398	82-14398	3000150	Uni	1	2017-07-10	2017-07-17	68000	2017-07-10
567	42	32-3934	32-3934	200005	Kg	1855.84999999999991	2017-06-13	2017-06-13	7980	2017-06-13
629	94	49-4393	49-4393	200004	Kg	0	2017-06-29	2017-07-06	11700	2017-06-29
678	117	11-294	11-294	100016	Kg	0	2017-07-07	2017-07-14	5500	2017-07-07
705	128	81-212	81-212	100030	Kg	0	2017-07-10	2017-07-11	8300	2017-07-10
544	27	31-3025	31-3025	200047	Kg	480	2017-06-05	2017-06-05	5100	2017-06-07
639	96	32-4582	24-004582	200094	Kg	0	2017-07-03	2017-08-04	5000	2017-07-03
701	125	39-780	37-780	200004	Kg	0	2017-07-07	2017-07-07	11750	2017-07-07
710	131	18-10696	18-10696	3000151	Uni	90	2017-07-10	2017-07-17	350	2017-07-10
720	137	59-347725	44-347725	3000246	0	24	2017-07-11	2017-07-17	15574	2017-07-11
662	103	77-1335	77-1335	100003	Kg	0	2017-07-04	2017-07-05	5500	2017-07-04
586	53	17-277	11-277	200098	Mts	0	2017-06-15	2017-06-16	435	2017-06-15
649	101	70-37360	70-37360	100002	Kg	0	2017-07-04	2017-07-07	6900	2017-07-04
717	134	19-38296	19-38296	3000157	0	2	2017-07-11	2017-07-17	2892.86000000000013	2017-07-11
664	105	24-28792	24-28792	300021	Uni	4	2017-07-06	2017-07-13	68335	2017-07-06
665	105	24-28792	24-28792	3000102	Uni	4	2017-07-06	2017-07-13	15960	2017-07-06
666	106	24-28790	24-28790	3000124	Uni	1	2017-07-06	2017-07-13	743600	2017-07-06
668	108	73-947	73-947	3000125	Uni	2	2017-07-06	2017-07-06	100000	2017-07-06
669	108	73-947	73-947	3000126	Uni	4	2017-07-06	2017-07-06	120000	2017-07-06
670	108	73-947	73-947	3000127	Uni	1	2017-07-06	2017-07-06	120000	2017-07-06
671	109	24-287993	24-287993	3000128	Uni	1	2017-07-06	2017-07-13	31250	2017-07-06
672	112	75-991	75-991	100002	Kg	0	2017-07-06	2017-07-13	6700	2017-07-06
718	135	32-4604	35-4604	200008	Kg	483.600000000000023	2017-07-11	2017-07-17	18500	2017-07-11
675	114	77-1337	77-1337	100003	Kg	0	2017-07-07	2017-07-14	6000	2017-07-07
661	103	77-1335	77-1335	100036	Kg	0	2017-07-04	2017-07-05	3800	2017-07-04
679	118	14-44	36-44	300086	Uni	36	2017-07-07	2017-07-14	14142.8500000000004	2017-07-07
680	118	14-44	36-44	300093	Caja	3	2017-07-07	2017-07-14	4400	2017-07-07
681	118	14-44	36-44	300091	Uni	3	2017-07-07	2017-07-14	18590	2017-07-07
682	119	14-45	14-45	3000135	Uni	1	2017-07-07	2017-07-14	31428.5699999999997	2017-07-07
683	119	14-45	14-45	3000136	Uni	3	2017-07-07	2017-07-14	2970	2017-07-07
684	119	14-45	14-45	3000137	Uni	6	2017-07-07	2017-07-14	3980	2017-07-07
685	119	14-45	14-45	3000138	Uni	1	2017-07-07	2017-07-14	2380	2017-07-07
686	119	14-45	14-45	300078	Uni	1	2017-07-07	2017-07-14	7650	2017-07-07
687	119	14-45	14-45	3000139	Uni	2	2017-07-07	2017-07-14	2180	2017-07-07
688	119	14-45	14-45	3000140	Uni	2	2017-07-07	2017-07-14	8592	2017-07-07
689	120	66-39005	31-39005	3000116	Uni	2	2017-07-07	2017-07-13	1906000	2017-07-07
690	120	66-39005	31-39005	3000117	Uni	4	2017-07-07	2017-07-13	51000	2017-07-07
691	120	66-39005	31-39005	3000118	Uni	2	2017-07-07	2017-07-13	57000	2017-07-07
692	120	66-39005	31-39005	3000119	Uni	2	2017-07-07	2017-07-13	8500	2017-07-07
706	128	81-212	81-212	100038	Kg	17.5	2017-07-10	2017-07-11	6300	2017-07-10
719	136	16-110798	16-110798	3000158	Uni	100	2017-07-11	2017-07-17	18545	2017-07-11
728	139	19-38332	19-38332	3000247	Uni	3	2017-07-12	2017-07-18	5303.57999999999993	2017-07-12
711	131	18-10696	18-10696	3000152	Uni	6	2017-07-10	2017-07-17	6000	2017-07-10
707	129	60-4458	60-4458	3000148	Uni	1	2017-07-10	2017-07-17	19990	2017-07-10
712	132	18-11703	18-11703	3000153	Uni	3	2017-07-10	2017-07-17	24400	2017-07-10
713	133	18-11702	18-11702	3000154	Uni	10	2017-07-11	2017-07-17	24800	2017-07-11
708	129	60-4458	60-4458	3000149	Uni	1	2017-07-10	2017-07-17	115000	2017-07-10
714	133	18-11702	18-11702	3000156	Uni	6	2017-07-11	2017-07-17	4000	2017-07-11
715	133	18-11702	18-11702	3000155	Uni	2	2017-07-11	2017-07-17	33000	2017-07-11
652	102	71-1907	71-1907	100001	Kg	553	2017-07-04	2017-07-11	6800	2017-07-04
676	115	78-780607	78-780607	100002	Kg	0	2017-07-07	2017-07-14	6200	2017-07-07
721	137	59-347725	44-347725	3000144	Uni	12	2017-07-11	2017-07-17	255668	2017-07-11
722	137	59-347725	44-347725	3000145	Uni	12	2017-07-11	2017-07-17	113752	2017-07-11
723	137	59-347725	44-347725	3000146	Uni	12	2017-07-11	2017-07-17	2613	2017-07-11
724	137	59-347725	44-347725	3000147	Uni	12	2017-07-11	2017-07-17	10504	2017-07-11
470	0	0-0	0-0	200056	Kg	75.9599999999999795	2017-01-01	2017-01-01	166195	2017-05-30
726	139	19-38332	19-38332	3000168	Uni	1	2017-07-12	2017-07-18	2544.63999999999987	2017-07-12
727	139	19-38332	19-38332	300046	Uni	4	2017-07-12	2017-07-18	2232.13999999999987	2017-07-12
725	138	7-3433	42-3433	2000102	Kg	2540	2017-07-12	2017-07-12	7940	2017-07-12
729	139	19-38332	19-38332	3000170	Uni	3	2017-07-12	2017-07-18	10937.5	2017-07-12
730	139	19-38332	19-38332	300066	Uni	1	2017-07-12	2017-07-18	48214.2900000000009	2017-07-12
731	139	19-38332	19-38332	3000171	Uni	1	2017-07-12	2017-07-18	2345.13000000000011	2017-07-12
674	114	77-1337	77-1337	100036	Kg	1909	2017-07-07	2017-07-14	3800	2017-07-07
732	141	24-28944	24-28944	3000172	Uni	1	2017-07-12	2017-07-17	354100	2017-07-12
733	142	84-754	84-754	3000173	Uni	6	2017-07-12	2017-07-12	1410.71000000000004	2017-07-12
764	164	19-38393	19-38393	3000182	Uni	4	2017-07-13	2017-07-13	1031.49000000000001	2017-07-13
765	164	19-38393	19-38393	3000183	Uni	4	2017-07-13	2017-07-13	982.139999999999986	2017-07-13
766	165	19-38383	19-38383	3000191	Uni	1	2017-07-13	2017-07-13	4821.43000000000029	2017-07-13
767	165	19-38383	19-38383	3000192	Uni	1	2017-07-13	2017-07-13	2544.63999999999987	2017-07-13
768	166	14-53	14-53	3000193	Rollo	16	2017-07-13	2017-07-14	37000	2017-07-13
740	147	10-172	10-172	100002	Kg	0	2017-07-13	2017-07-21	6400	2017-07-13
788	174	79-13	79-13	3000230	Uni	5	2017-07-19	2017-07-21	80500	2017-07-19
790	176	18-10719	18-10719	3000228	Rollo	2	2017-07-19	2017-07-26	45280	2017-07-19
791	176	18-10719	18-10719	3000229	Uni	2	2017-07-19	2017-07-26	96000	2017-07-19
792	176	18-10719	18-10719	300050	Uni	2	2017-07-19	2017-07-26	88000	2017-07-19
793	177	18-11721	18-11721	3000231	Uni	1	2017-07-19	2017-07-26	26900	2017-07-19
794	177	18-11721	18-11721	3000233	Rollo	1	2017-07-19	2017-07-26	18700	2017-07-19
758	161	50-8229	49-8229	200068	Kg	624	2017-07-13	2017-07-27	615	2017-07-13
799	188	48-483	48-483	100041	Kg	0	2017-07-19	2017-08-03	10000	2017-07-19
795	177	18-11721	18-11721	3000232	Uni	1	2017-07-19	2017-07-26	19000	2017-07-19
839	226	14-56	94-56	3000237	Uni	3	2017-07-21	2017-07-28	37500	2017-07-21
796	178	18-117709	18-117709	3000234	Uni	1	2017-07-19	2017-07-26	272000	2017-07-19
734	143	11-0298	11-0298	100006	Kg	0	2017-07-12	2017-07-21	10200	2017-07-12
797	179	93-1626	93-1626	3000235	Uni	2	2017-07-19	2017-08-02	280000	2017-07-19
741	148	18-10711	18-10711	300048	Mts	50	2017-07-13	2017-07-17	4480	2017-07-13
744	151	18-10699	18-10699	3000131	Uni	6	2017-07-13	2017-07-18	72800	2017-07-13
745	151	18-10699	18-10699	3000132	Uni	2	2017-07-13	2017-07-18	115200	2017-07-13
746	152	18-10700	18-10700	3000177	Uni	2	2017-07-13	2017-07-17	45000	2017-07-13
747	152	18-10700	18-10700	3000178	Uni	5	2017-07-13	2017-07-17	6000	2017-07-13
754	158	18-11700	38-11700	3000245	Uni	5	2017-07-13	2017-07-14	6000	2017-07-13
838	225	80-476730	80-476730	100002	Kg	0	2017-07-20	2017-07-21	6900	2017-07-20
801	188	48-483	48-483	100040	Kg	202	2017-07-19	2017-08-03	9500	2017-07-19
840	227	24-29107	24-29107	3000241	Uni	2	2017-07-21	2017-07-28	64633.9300000000003	2017-07-21
772	170	49-4654	49-4654	200004	Kg	500	2017-07-19	2017-07-21	14200	2017-07-19
739	146	79-790713	79-790713	100002	Kg	0	2017-07-13	2017-07-21	6900	2017-07-13
743	150	11-111307	11-111307	100006	Kg	0	2017-07-13	2017-07-21	10200	2017-07-13
773	171	58-47	58-47	3000214	Uni	1	2017-07-19	2017-07-25	350000	2017-07-19
774	171	58-47	58-47	3000215	Uni	3	2017-07-19	2017-07-25	95000	2017-07-19
775	171	58-47	58-47	3000216	Uni	2	2017-07-19	2017-07-25	90000	2017-07-19
748	153	60-4471	60-4471	3000179	Rollo	5	2017-07-13	2017-07-17	59590	2017-07-13
749	153	60-4471	60-4471	3000180	Uni	1	2017-07-13	2017-07-17	105950	2017-07-13
750	155	60-4450	60-4450	3000181	Uni	3	2017-07-13	2017-07-04	43500	2017-07-13
751	156	18-11711	50-11711	300048	Mts	50	2017-07-13	2017-07-18	4480	2017-07-13
752	157	18-11699	39-11699	3000131	Uni	6	2017-07-13	2017-07-14	72800	2017-07-13
753	157	18-11699	39-11699	3000132	Uni	2	2017-07-13	2017-07-14	115200	2017-07-13
755	158	18-11700	38-11700	3000129	Uni	2	2017-07-13	2017-07-14	45000	2017-07-13
756	159	48-459	48-459	100030	Kg	0	2017-07-13	2017-07-08	7500	2017-07-13
805	192	77-772007	77-772007	100003	Kg	2915.5	2017-07-20	2017-07-28	6500	2017-07-20
742	149	69-1423	45-1423	200080	Mts	10562	2017-07-13	2017-07-20	2224.55000000000018	2017-07-13
802	189	92-1707	92-1707	100002	Kg	0	2017-07-19	2017-07-17	6900	2017-07-19
757	160	24-28987	41-28987	3000143	Uni	1	2017-07-13	2017-07-21	2175400.45000000019	2017-07-13
759	162	50-8230	46-8230	200095	Litro	960	2017-07-13	2017-07-27	1780	2017-07-13
760	163	83-40	83-40	3000187	Uni	3	2017-07-13	2017-07-21	200000	2017-07-13
761	163	83-40	83-40	3000188	Uni	3	2017-07-13	2017-07-21	35000	2017-07-13
762	163	83-40	83-40	3000189	Uni	1	2017-07-13	2017-07-21	90000	2017-07-13
763	163	83-40	83-40	3000190	Uni	4	2017-07-13	2017-07-21	5000	2017-07-13
776	171	58-47	58-47	3000217	Rollo	1	2017-07-19	2017-07-25	125000	2017-07-19
777	171	58-47	58-47	3000218	Litro	4	2017-07-19	2017-07-25	22500	2017-07-19
778	171	58-47	58-47	3000219	Litro	1	2017-07-19	2017-07-25	60000	2017-07-19
779	171	58-47	58-47	3000220	Litro	2	2017-07-19	2017-07-25	12000	2017-07-19
780	171	58-47	58-47	3000221	Uni	1	2017-07-19	2017-07-25	345000	2017-07-19
781	172	90-359	90-359	3000174	Uni	10562	2017-07-19	2017-07-26	20	2017-07-19
782	172	90-359	90-359	3000222	Uni	1	2017-07-19	2017-07-26	190000	2017-07-19
783	173	91-2417	91-2417	3000223	Uni	12	2017-07-19	2017-07-26	80000	2017-07-19
784	173	91-2417	91-2417	3000224	Uni	1	2017-07-19	2017-07-26	34500	2017-07-19
785	173	91-2417	91-2417	3000225	Rollo	1	2017-07-19	2017-07-26	2500000	2017-07-19
786	173	91-2417	91-2417	3000226	Uni	11	2017-07-19	2017-07-26	23000	2017-07-19
787	173	91-2417	91-2417	3000227	Rollo	1	2017-07-19	2017-07-26	1500000	2017-07-19
789	175	79-14	79-14	100002	Kg	0	2017-07-19	2017-07-21	6900	2017-07-19
738	145	53-17276	30-17276	200010	Bulto	18	2017-07-12	2017-07-12	71662.5	2017-07-12
803	190	77-771907	77-771907	100015	Kg	1219	2017-07-19	2017-07-21	3000	2017-07-19
771	169	49-4655	87-4655	200004	Kg	400	2017-07-19	2017-07-20	14200	2017-07-19
769	167	11-298	11-298	100016	Kg	1467.5	2017-07-14	2017-07-21	5500	2017-07-14
735	144	77-2343	77-2343	100036	Kg	508.5	2017-07-12	2017-07-21	4000	2017-07-12
736	144	77-2343	77-2343	100039	Kg	0	2017-07-12	2017-07-21	9000	2017-07-12
637	97	8-11021	23-0011021	200058	Kg	2.06000000000000005	2017-07-03	2017-07-23	701315	2017-07-03
798	187	76-86	76-86	100030	Kg	590.5	2017-07-19	2017-07-21	10000	2017-07-19
804	191	11-111907	11-111907	100006	Kg	195.5	2017-07-19	2017-07-21	10200	2017-07-19
800	188	48-483	48-483	100030	Kg	0	2017-07-19	2017-08-03	9500	2017-07-19
841	227	24-29107	24-29107	3000242	Uni	1	2017-07-21	2017-07-28	130558.399999999994	2017-07-21
842	228	64-7998	51-7998	3000160	Uni	2	2017-07-21	2017-07-21	340200	2017-07-21
843	228	64-7998	51-7998	3000161	Uni	2	2017-07-21	2017-07-21	235620	2017-07-21
844	228	64-7998	51-7998	3000162	Uni	5	2017-07-21	2017-07-21	71868.6000000000058	2017-07-21
845	228	64-7998	51-7998	3000163	Mts	100	2017-07-21	2017-07-21	1406.70000000000005	2017-07-21
737	100	85-58	85-58	200099	Mts	34760	2017-07-03	2017-07-31	400	2017-07-12
846	229	76-89	76-89	100030	Kg	1972	2017-07-21	2017-07-28	10000	2017-07-21
848	231	89-2073	90-2073	3000195	Uni	1	2017-07-25	2017-07-26	750000	2017-07-25
849	231	89-2073	90-2073	3000196	Rollo	1	2017-07-25	2017-07-26	750000	2017-07-25
850	231	89-2073	90-2073	3000197	Uni	1	2017-07-25	2017-07-26	250000	2017-07-25
851	231	89-2073	90-2073	3000198	Uni	8	2017-07-25	2017-07-26	175000	2017-07-25
852	231	89-2073	90-2073	3000199	Uni	60	2017-07-25	2017-07-26	11025	2017-07-25
853	231	89-2073	90-2073	3000200	Uni	16	2017-07-25	2017-07-26	175000	2017-07-25
854	231	89-2073	90-2073	3000201	Uni	1	2017-07-25	2017-07-26	60000	2017-07-25
855	231	89-2073	90-2073	3000202	Uni	10	2017-07-25	2017-07-26	20000	2017-07-25
856	232	89-2075	92-2075	3000212	GALON	1	2017-07-25	2017-07-26	136500	2017-07-25
857	232	89-2075	92-2075	3000213	Uni	1	2017-07-25	2017-07-26	200000	2017-07-25
858	233	89-2074	91-2074	3000203	Rollo	1	2017-07-25	2017-07-26	19435000	2017-07-25
859	233	89-2074	91-2074	3000204	Uni	1	2017-07-25	2017-07-26	90000	2017-07-25
860	233	89-2074	91-2074	3000205	Rollo	1	2017-07-25	2017-07-26	570000	2017-07-25
861	233	89-2074	91-2074	3000206	Uni	1	2017-07-25	2017-07-26	69000	2017-07-25
862	233	89-2074	91-2074	3000208	Uni	1	2017-07-25	2017-07-26	850000	2017-07-25
863	233	89-2074	91-2074	3000209	Rollo	1	2017-07-25	2017-07-26	120000	2017-07-25
864	233	89-2074	91-2074	3000210	Uni	1	2017-07-25	2017-07-26	1123309.39999999991	2017-07-25
865	233	89-2074	91-2074	3000211	Uni	1	2017-07-25	2017-07-26	1689360	2017-07-25
866	234	47-130	47-130	300072	Uni	2000	2017-07-25	2017-07-26	275	2017-07-25
867	234	47-130	47-130	3000244	Uni	12	2017-07-25	2017-07-26	17900	2017-07-25
868	235	89-2076	101-2076	3000243	Uni	1	2017-07-25	2017-07-26	6869500	2017-07-25
899	267	7-3538	7-3538	2000102	Kg	4500	2017-07-25	2017-07-28	8666.66666666666788	2017-07-25
770	168	32-4626	89-4626	200005	Kg	2337.5	2017-07-19	2017-07-21	5500	2017-07-19
663	104	31-3035	31-3035	200064	Kg	0	2017-07-04	2017-07-04	9300	2017-07-04
902	269	63-1676	63-1676	3000257	Uni	1	2017-07-25	2017-07-26	976000	2017-07-25
903	269	63-1676	63-1676	3000258	Uni	1	2017-07-25	2017-07-26	1377000	2017-07-25
904	270	99-487	99-487	100004	Kg	2268.5	2017-07-25	2017-07-25	4250	2017-07-25
905	271	18-11734	103-11734	3000250	Uni	3	2017-07-25	2017-07-27	58300	2017-07-25
906	271	18-11734	103-11734	3000251	Uni	1	2017-07-25	2017-07-27	307700	2017-07-25
907	271	18-11734	103-11734	3000252	Uni	100	2017-07-25	2017-07-27	296	2017-07-25
908	271	18-11734	103-11734	3000253	Uni	100	2017-07-25	2017-07-27	466	2017-07-25
909	271	18-11734	103-11734	3000254	Uni	2	2017-07-25	2017-07-27	23300	2017-07-25
910	271	18-11734	103-11734	3000255	Uni	1	2017-07-25	2017-07-27	261120	2017-07-25
911	271	18-11734	103-11734	3000256	Uni	2	2017-07-25	2017-07-27	11224	2017-07-25
912	272	8-15232	43-15232	200055	Kg	10	2017-07-25	2017-07-27	55313	2017-07-25
913	273	9-92507	9-92507	100021	Uni	150	2017-07-25	2017-07-28	65000	2017-07-25
914	274	80-802507	80-802507	100002	Kg	3299.5	2017-07-25	2017-07-28	6900	2017-07-25
847	230	11-112107	11-112107	100006	Kg	0	2017-07-21	2017-07-28	10200	2017-07-21
900	268	98-982507	98-982507	200081	Mts	0	2017-07-25	2017-07-28	3700	2017-07-25
901	268	98-982507	98-982507	200082	.	1000	2017-07-25	2017-07-28	5985	2017-07-25
916	276	8-15262	102-15262	200058	Kg	5	2017-07-26	2017-07-26	771984	2017-07-26
917	277	12-943	12-943	100003	Kg	5034.5	2017-07-26	2017-07-28	6000	2017-07-26
700	124	7-3423	7-3423	200007	Kg	14.2999999999999972	2017-07-07	2017-07-10	2800	2017-07-07
918	278	88-390	88-390	200065	Kg	830	2017-07-26	2017-08-04	31768.75	2017-07-26
915	275	100-1727	100-1727	100002	Kg	1114	2017-07-25	2017-07-28	6500	2017-07-25
\.


--
-- Data for Name: tm_invstock; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_invstock (id, ctipo_almacen, ccodprod, ctunidad, cstock_min, cstock_max, cstock_crit) FROM stdin;
1	1	100001		0	0	0
2	1	100002		60000	120000	30000
4	1	100004		70000	140000	35000
5	1	100005		1000	2000	500
6	1	100006		2260	4520	1130
7	1	100007		7080	14160	3540
9	1	100009		580	1160	290
11	1	100011		0	0	0
12	1	100012		0	0	0
13	1	100013		0	0	0
14	1	100014		0	0	0
15	1	100015		6000	12000	3000
16	1	100016		2400	4800	1200
17	1	100017		2400	4800	1200
18	1	100018		2400	4800	1200
19	1	100019		3000	6000	1500
20	1	100020		0	0	0
21	1	100021		400	800	200
22	1	100022		0	0	0
30	1	100030		480	960	240
31	1	100031		240	480	120
32	1	100032		2800	5600	1400
33	1	100033		80	160	40
34	1	100034		1140	2280	570
35	1	100035		4000	8000	2000
36	1	100036		1280	2560	640
38	2	200002		150	300	75
40	2	200006		0	0	0
41	2	200015		0	0	0
42	2	200016		0	0	0
43	2	200017		0	0	0
44	2	200018		0	0	0
46	2	200020		480	960	240
47	2	200021		2800	5600	1400
48	2	200022		0	0	0
49	2	200023		0	0	0
51	2	200025		0	0	0
52	2	200027		0	0	0
53	2	200030		1.80000000000000004	3.60000000000000009	0.900000000000000022
54	2	200031		1.39999999999999991	2.79999999999999982	0.699999999999999956
55	2	200032		140	280	70
56	2	200035		360	720	180
57	2	200036		68	136	34
58	2	200007		700	1400	350
59	2	200008		190	380	95
63	2	200012		0	0	0
65	2	200014		0	0	0
66	2	200026		0	0	0
67	2	200028		3	6	1.5
68	2	200029		84	168	42
69	2	200033		0	0	0
70	2	200034		0.200000000000000011	0.400000000000000022	0.100000000000000006
71	2	200037		0	0	0
72	2	200038		204	408	102
74	2	200040		20000	40000	10000
76	2	200042		0	0	0
77	2	200043		0	0	0
78	2	200044		0	0	0
79	2	200045		0	0	0
80	2	200046		0	0	0
81	2	200047		2850	5700	1425
82	2	200048		20	40	10
83	2	200049		12	24	6
84	2	200050		0	0	0
85	2	200051		43000	86000	21500
86	2	200052		43000	86000	21500
87	2	200053		8	16	4
89	2	200055		0.800000000000000044	1.60000000000000009	0.400000000000000022
90	2	200056		0.540000000000000036	1.08000000000000007	0.270000000000000018
91	2	200057		2.5	5	1.25
92	2	200058		7	14	3.5
93	2	200059		0.900000000000000022	1.80000000000000004	0.450000000000000011
94	2	200060		1.60000000000000009	3.20000000000000018	0.800000000000000044
95	2	200061		1.60000000000000009	3.20000000000000018	0.800000000000000044
96	2	200062		0.800000000000000044	1.60000000000000009	0.400000000000000022
97	2	200063		0	0	0
98	2	200064		4600	9200	2300
99	2	200065		360	720	180
100	2	200066		0	0	0
101	2	200067		0	0	0
102	2	200068		2200	4400	1100
103	2	200069		220	440	110
104	2	200070		0	0	0
105	2	200071		0	0	0
108	2	200074		592	1184	296
109	2	200075		20	40	10
111	2	200077		640	1280	320
112	2	200078		960	1920	480
113	2	200079		8000	16000	4000
114	2	200080		0	0	0
115	2	200081		1800	3600	900
116	2	200082		500	1000	250
120	2	200086		480	960	240
26	1	100026		1000	2000	4000
37	2	200001		440	220	110
39	2	200003		400	800	200
60	2	200009		4	8	2
62	2	200011		1	2	0.5
64	2	200013		5	10	2.5
50	2	200024		0.400000000000000022	0.800000000000000044	0.200000000000000011
88	2	200054		2	4	1
106	2	200072		2	4	1
107	2	200073		2	4	1
110	2	200076		320	640	160
117	2	200083		4	8	2
121	2	200087		0	0	0
122	2	200088		0	0	0
123	2	200089		0	0	0
24	1	100024		0	0	0
25	1	100025		0	0	0
27	1	100027		0	0	0
28	1	100028		0	0	0
29	1	100029		0	0	0
73	2	200039		0.0200000000000000004	0.0400000000000000008	0.0100000000000000002
75	2	200041		2	4	1
45	2	200019		0.400000000000000022	0.800000000000000044	0.200000000000000011
61	2	200010		14	21	7
124	2	200090		360	720	180
125	2	200091		0	0	0
10	1	100010		1000	2000	4000
118	2	200084		4	8	2
8	1	100008		0	0	0
23	1	100023		0	0	0
3	1	100003		40000	80000	20000
119	2	200085		28160	56320	14080
127	2	200099	Mts	43450	86900	21725
\.


--
-- Data for Name: tm_ordencompra; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_ordencompra (id, cfecha, cproveedor, cprovnombre, ctipo_pago, csolicitado, caprob1, caprob2, ctotal, cobservaciones, cdescripcion, cn_req, cstatus, caprob2st, caprob1st, cfecha_est1, cfecha_est2, cstotal, c_cotizacion, ct_servicio, ct_directa) FROM stdin;
1	2017-05-15	0	0	1	14183910	14183910	14183910	0			0	4	t	t	\N	\N	0	0	f	f
2	2017-06-01	7	INVERSIONES VILLAS DE ARAUCA, C.A	1	4	4	0	2100000		Registro Orden Compra	99	4	t	t	\N	\N	2100000	00601	f	f
3	2017-06-01	8	AGROSISTEMAS JPJ C.A.	2	4	4	0	4392110		Registro Orden Compra	114	4	t	t	\N	\N	4392110	17052317	f	f
6	2017-06-07	32	DIAMENCA, C.A.	2	4	3	14183910	21050400		Registro Orden Compra	145	4	t	t	\N	\N	18795000	752	f	f
5	2017-06-02	17	EMPATEC ALIMENTARIA C.A	2	4	3	14183910	16576000		Registro Orden Compra	120	4	t	t	\N	\N	14800000		f	f
8	2017-06-09	33	UNIKERT DE VENEZUELA, S.A.	1	14183910	3	14183910	120344000		Registro Orden Compra	100001	4	t	t	\N	\N	107450000	cotizacion tripa impresa	f	f
9	2017-06-12	18	COMERCIALIZADORA JARCHI C.A.	2	6	3	14183910	14952		Registro Orden Compra	146	4	t	t	\N	\N	13350	3674	f	f
4	2017-06-02	16	FERRETERIA LOS CEDROS, C.A.	2	6	6	0	43948		Registro Orden Compra	125	4	t	t	\N	\N	38674.239999999998	94550	f	f
11	2017-06-14	17	EMPATEC ALIMENTARIA C.A	2	4	3	14183910	42386400		Registro Orden Compra	100159	4	t	t	\N	\N	37845000		f	f
12	2017-06-14	33	UNIKERT DE VENEZUELA, S.A.	2	4	3	14183910	28385280		Registro Orden Compra	10159	4	t	t	\N	\N	25344000		f	f
17	2017-06-15	14	MULTI SUMINISTROS MAGNAM, C.A.	2	3	3	14183910	941939.430000000051		Registro Orden Compra	140	4	t	t	\N	\N	841017.349999999977	2069	f	f
7	2017-06-08	25	TECHTROL SEGURIDAD INTEGRAL C.A.	1	6	3	14183910	7826392		Registro Orden Compra	100000	4	t	t	\N	\N	6987850	4976	f	f
19	2017-06-21	56	SUPPLY STEEL C.A.	1	14183910	3	14183910	395136		Registro Orden Compra	172	4	f	f	\N	\N	352800		f	f
21	2017-06-22	58	PROYECTOS ARM 2013, C.A.	2	6	3	14183910	224000		Registro Orden Compra	168	4	f	f	\N	\N	200000		t	f
22	2017-06-22	58	PROYECTOS ARM 2013, C.A.	2	6	3	14183910	1780800		Registro Orden Compra	169	4	f	f	\N	\N	1590000	001	t	f
23	2017-06-23	8	AGROSISTEMAS JPJ C.A.	1	0	3	14183910	3927364		Registro Orden Compra	174	4	f	f	\N	\N	3506575		f	f
34	2017-06-29	69	DISTRIBUIRA EURO QUALITE, C.A.	2	4	3	14183910	41899200		Registro Orden Compra	176	4	f	f	\N	\N	37410000		f	f
24	2017-06-23	32	DIAMENCA, C.A.	2	0	3	14183910	15000000		Registro Orden Compra	174	4	f	f	\N	\N	15000000		f	f
25	2017-06-23	59	FRIGORIFICO BETTOLI C.A.	2	3	3	14183910	163852.640000000014		Registro Orden Compra	173	4	f	f	\N	\N	146297		f	f
26	2017-06-23	59	FRIGORIFICO BETTOLI C.A.	2	5	3	14183910	52416.6699999999983		Registro Orden Compra	171	4	f	f	\N	\N	46800.5999999999985		f	f
27	2017-06-23	60	SHOMI.COM. C.A.	2	3	3	14183910	154526.399999999994		Registro Orden Compra	173	4	f	f	\N	\N	137970		f	f
28	2017-06-23	60	SHOMI.COM. C.A.	2	6	3	14183910	22388.7999999999993		Registro Orden Compra	163	4	f	f	\N	\N	19990	130	f	f
29	2017-06-26	24	RODAMIENTOS MORALES ROMORCA C.A.	2	6	3	14183910	377641.599999999977		Registro Orden Compra	160	4	f	f	\N	\N	337180	9610	f	f
30	2017-06-26	53	POLY BAG DE VENEZUELA, C.A.	1	0	3	14183910	2407860		Registro Orden Compra	175	4	f	f	\N	\N	2149875	3618	f	f
31	2017-06-26	66	CENTRO CONTROL CARABOBO, C.A.	1	14183912	3	14183910	4644640		Registro Orden Compra	100771	4	f	f	\N	\N	4147000		f	f
32	2017-06-26	65	HYPER ELECTRICOS ARAGUA, C.A.	1	14183912	3	14183910	1667733.76000000001		Registro Orden Compra	1006804	4	f	f	\N	\N	1489048	6804	f	f
33	2017-06-26	64	CONTROL TECH	1	0	3	14183910	14680476.8200000003		Registro Orden Compra	1008023	4	f	f	\N	\N	13107568.5899999999	8023	f	f
18	2017-06-16	52	SUMINISTROS RAGDE C.A.	2	6	3	14183910	316830.080000000016		Registro Orden Compra	167	4	t	t	\N	\N	282884	62017-147	f	f
35	2017-07-06	32	DIAMENCA, C.A.	2	4	3	14183910	10360000		Registro Orden Compra	176	4	f	f	\N	\N	9250000		f	f
16	2017-06-15	50	FAMELER DE VENEZUELA, C.A.	2	5	3	14183910	475200		Registro Orden Compra	153	4	t	t	\N	\N	475200		f	f
36	2017-07-06	14	MULTI SUMINISTROS MAGNAM, C.A.	2	3	3	14183910	647486.109999999986		Registro Orden Compra	173	4	f	f	\N	\N	578112.599999999977	2985	f	f
37	2017-07-06	39	REPRESENTACIONES RM MAMUT, C.A.	1	4	3	14183910	13160000		Registro Orden Compra	176	4	f	f	\N	\N	11750000		f	f
38	2017-07-06	18	COMERCIALIZADORA JARCHI C.A.	2	5	3	14183910	134400		Registro Orden Compra	178	4	f	f	\N	\N	120000		f	f
39	2017-07-06	18	COMERCIALIZADORA JARCHI C.A.	2	6	3	14183910	747264		Registro Orden Compra	10101	4	f	f	\N	\N	667200	3719	f	f
40	2017-07-06	59	FRIGORIFICO BETTOLI C.A.	1	14183912	3	14183910	21839.9700000000012		Registro Orden Compra	10102	4	f	f	\N	\N	19499.9700000000012	4264	f	f
41	2017-07-07	24	RODAMIENTOS MORALES ROMORCA C.A.	2	6	3	14183910	2436448.5		Registro Orden Compra	187	4	f	f	\N	\N	2175400.45000000019		f	f
42	2017-07-10	7	INVERSIONES VILLAS DE ARAUCA, C.A	1	14183910	3	14183910	23400000		Registro Orden Compra	188	4	f	f	\N	\N	23400000		f	f
43	2017-07-10	8	AGROSISTEMAS JPJ C.A.	1	4	3	14183910	619505.599999999977		Registro Orden Compra	145	4	f	f	\N	\N	553130		f	f
44	2017-07-10	59	FRIGORIFICO BETTOLI C.A.	2	5	3	14183910	140749.059999999998		Registro Orden Compra	183	4	f	f	\N	\N	125668.800000000003		f	f
45	2017-07-11	69	DISTRIBUIRA EURO QUALITE, C.A.	2	4	3	14183910	24438400		Registro Orden Compra	189	4	f	f	\N	\N	21820000		f	f
47	2017-07-11	8	AGROSISTEMAS JPJ C.A.	1	4	3	14183910	20986560		Registro Orden Compra	189	4	f	f	\N	\N	18738000		f	f
48	2017-07-11	33	UNIKERT DE VENEZUELA, S.A.	2	4	3	14183910	32327680		Registro Orden Compra	189	4	f	f	\N	\N	28864000		f	f
49	2017-07-11	50	FAMELER DE VENEZUELA, C.A.	2	6	3	14183910	688800		Registro Orden Compra	1780	4	f	f	\N	\N	615000		f	f
50	2017-07-11	18	COMERCIALIZADORA JARCHI C.A.	2	5	3	14183910	250880		Registro Orden Compra	154	4	f	f	\N	\N	224000		f	f
51	2017-07-11	64	CONTROL TECH	1	6	3	14183910	1849851.3600000001		Registro Orden Compra	190	4	f	f	\N	\N	1651653	8060	f	f
84	2017-07-12	31	DISTRIBUIDORA AROMA, C.A.	2	4	3	14183910	52080000		Registro Orden Compra	189	4	f	f	\N	\N	46500000		f	f
46	2017-07-11	50	FAMELER DE VENEZUELA, C.A.	2	14183910	3	14183910	1913856		Registro Orden Compra	186	4	f	f	\N	\N	1708800		f	f
85	2017-07-12	32	DIAMENCA, C.A.	2	4	3	14183910	22400000		Registro Orden Compra	189	4	f	f	\N	\N	20000000		f	f
86	2017-07-13	66	CENTRO CONTROL CARABOBO, C.A.	1	6	3	14183910	999040		Registro Orden Compra	999111999	4	f	f	2017-07-17	2017-07-18	892000	15245	f	f
87	2017-07-17	49	RUARP GROUP. C.A.	1	14183910	3	14183910	28904000		Registro Orden Compra	198	4	f	f	\N	\N	27200000		f	f
13	2017-06-15	8	AGROSISTEMAS JPJ C.A.	6	4	3	14183910	3143235.20000000019		Registro Orden Compra	166	4	t	t	\N	\N	2806460		f	f
10	2017-06-14	8	AGROSISTEMAS JPJ C.A.	6	4	3	14183910	3143235.20000000019		Registro Orden Compra	159	4	t	t	\N	\N	2806460		f	f
15	2017-06-15	39	REPRESENTACIONES RM MAMUT, C.A.	1	4	3	14183910	10987200		Registro Orden Compra	166	4	t	t	\N	\N	9810000		f	f
14	2017-06-15	39	REPRESENTACIONES RM MAMUT, C.A.	1	4	3	14183910	10987200		Registro Orden Compra	166	4	t	t	\N	\N	9810000		f	f
88	2017-07-18	88	AGROALIMENTARIA VENEZUELA	1	4	3	14183910	35581000		Registro Orden Compra	189	4	f	f	\N	\N	31768750		f	f
89	2017-07-18	32	DIAMENCA, C.A.	1	4	3	14183910	18480000		Registro Orden Compra	189	4	f	f	\N	\N	16500000		f	f
90	2017-07-18	89	RIMOCA INDUSTRIAL	2	6	3	14183910	7696080		Registro Orden Compra	1980	4	f	f	\N	\N	6871500		f	f
91	2017-07-18	89	RIMOCA INDUSTRIAL	2	6	3	14183910	26820269.7300000004		Registro Orden Compra	1980	4	f	f	\N	\N	23946669.3999999985		f	f
92	2017-07-18	89	RIMOCA INDUSTRIAL	2	6	3	14183910	376880		Registro Orden Compra	199	4	f	f	\N	\N	336500	12584	f	f
93	2017-07-20	96	CALZADO FION C.A.	1	5	3	14183910	325248		Registro Orden Compra	155	4	f	f	\N	\N	290400	71854	f	f
94	2017-07-20	14	MULTI SUMINISTROS MAGNAM, C.A.	2	5	3	14183910	126000		Registro Orden Compra	191	4	f	f	\N	\N	112500	3557	f	f
100	2017-07-21	64	CONTROL TECH	1	6	3	14183910	263894.400000000023		Registro Orden Compra Directa	0	4	f	f	\N	\N	235620	8060	f	f
101	2017-07-21	89	RIMOCA INDUSTRIAL	1	14183910	3	14183910	7693840		Registro Orden Compra	206	4	f	f	\N	\N	6869500	12585	f	f
102	2017-07-25	8	AGROSISTEMAS JPJ C.A.	1	4	3	14183910	4323110.40000000037		Registro Orden Compra	201	4	f	f	\N	\N	3859920		f	f
103	2017-07-25	18	COMERCIALIZADORA JARCHI C.A.	2	6	3	14183910	995644.160000000033		Registro Orden Compra	205	4	f	f	\N	\N	888968	3754	f	f
95	2017-07-20	97	MANUFACTURAS WALITEX C.A.	1	5	3	14183910	547744.859999999986		Registro Orden Compra	151	4	f	f	\N	\N	489057.909999999974		f	f
104	2017-07-26	69	DISTRIBUIRA EURO QUALITE, C.A.	2	4	3	14183910	42147840		Registro Orden Compra	201	4	f	f	\N	\N	37632000		f	f
105	2017-07-26	101	CANER INDUSTRIAL C.A.	2	4	3	14183910	2504588800		Registro Orden Compra	201	4	f	f	\N	\N	2236240000		f	f
\.


--
-- Data for Name: tm_producto; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_producto (codprod, cdescripcion, ctipoprod, ctipoalmacen, ctipounidad, c_iva, ce_iva, cm_prima) FROM stdin;
100001	AJO MOLIDO	0	1	Kg	0	f	t
100002	C.D.M DE POLLO	0	1	Kg	0	f	t
100003	CACHETE DE RES	0	1	Kg	0	f	t
100004	CARAPACHO DE POLLO	0	1	Kg	0	f	t
100005	CARETA	0	1	Kg	0	f	t
100006	CARNE DE CABEZA	0	1	Kg	0	f	t
100007	CARNE DE RES	0	1	Kg	0	f	t
100008	CHULETA DE LECHON	0	1	Kg	0	f	t
100009	CHULETA DE MADRE	0	1	Kg	0	f	t
100010	COPA DE LECHON	0	1	Kg	0	f	t
100011	COSTILLA CARNICERA DE LECHON	0	1	Kg	0	f	t
100012	COSTILLA CARNICERA DE MADRE	0	1	Kg	0	f	t
100013	COSTILLA CHINA DE LECHON 	0	1	Kg	0	f	t
100014	COSTILLA CHINA DE MADRE	0	1	Kg	0	f	t
100016	CUERO PP	0	1	Kg	0	f	t
100017	CUERO TALLADO	0	1	Kg	0	f	t
100018	CUERO TRATADO	0	1	Kg	0	f	t
100019	HUESO Y CODILLO	0	1	Kg	0	f	t
100020	LECHONES	0	1	Kg	0	f	t
200018	BOLSAS MORTADELA SUPERIOR	0	2	Uni	12	f	t
100022	MADRES	0	1	Kg	0	f	t
100023	OREJAS	0	1	Kg	0	f	t
100024	PALETA DE LECHON	0	1	Kg	0	f	t
100025	PAPADA SIN CUERO	0	1	Kg	0	f	t
100026	PATA DE LECHON	0	1	Kg	0	f	t
100027	PATA DE MADRE	0	1	Kg	0	f	t
100028	PERNIL DE LECHON	0	1	Kg	0	f	t
100029	PERNIL Y PALETA DE MADRE	0	1	Kg	0	f	t
100030	RECORTE DE PRIMERA	0	1	Kg	0	f	t
100031	RECORTE DE TERCERA	0	1	Kg	0	f	t
100032	RECORTE DE TOCINETA	0	1	Kg	0	f	t
100033	RECORTE ROJO	0	1	Kg	0	f	t
100034	TOCINETA	0	1	Kg	0	f	t
100035	TOCINO	0	1	Kg	0	f	t
100036	TRASTE	0	1	Kg	0	f	t
200017	BOLSAS LIONNER BIERWURTS (PAVO AHUMADO)	0	2	Uni	12	f	t
200016	BOLSAS JAMON YORK	0	2	Uni	12	f	t
200015	BOLSAS JAMON COCIDO	0	2	Uni	12	f	t
300082	SILENCIADOR DE BRONCE 1"	0	3	Mts	12	t	t
300083	BENZADEX ( LIMPIADOR MULTIUSO )	0	3	GALON	12	t	t
300089	VASOS 7 OZ	0	3	Caja	12	t	t
200068	SAL	0	2	Kg	12	f	t
200001	A.T.T.	0	2	Kg	12	f	t
300029	RIGID BOLAS (62022RS-BRY)	0	3	Rollo	12	t	t
300030	RIGID BOLAS (62042RS-JAP)	0	3	Rollo	12	t	t
200002	ACIDO LACTICO	0	2	Kg	12	f	t
200003	AGROGEL	0	2	Kg	12	f	t
200004	ALMIDON DE PAPA	0	2	Kg	12	f	t
200005	ALMIDON DE YUCA	0	2	Kg	12	f	t
200006	ALMIDON TRIGO NATIVO	0	2	Kg	12	f	t
200007	AZUCAR	0	2	Kg	12	f	t
200008	B.Z.T.	0	2	Kg	12	f	t
200009	BOLSA 100X70	0	2	Bulto	12	f	t
200010	BOLSA 49X75	0	2	Bulto	12	f	t
200011	BOLSA 60X90	0	2	Bulto	12	f	t
900003	SALMUERA PARA REPOSO	0	4	.	0	f	f
100037	C.D.M. PAVO	0	1	Kg	8	f	t
300093	GANCHOS PARA CARPETAS	0	3	Caja	12	t	t
200019	BOLSAS MORTADELA TAPARA IMP 33X52 CM	0	2	Uni	12	f	t
100015	CRIADILLAS (TESTICULO)	0	1	Kg	0	f	t
900004	SALMUERA PARA INYECCION	0	4	.	0	f	f
300097	ARANDELA DE BRONCE 8 INTERNO Y 12 EXTERNO	0	3	Uni	12	t	t
300015	LIGAS	0	3	Kg	12	f	t
800002	UNIDAD DE REFRIGERACION 2	0	8	Uni	12	f	f
300062	DEGREASER MAX	0	3	GALON	12	f	t
300044	ARENA CERNIDA	0	3	Mts	12	t	t
200096	TRIPA VISCOFAN CERO MERMA CAL. 75	0	2	Mts	12	t	t
200097	TRIPA AREPERO FIBROSA CAL 4	0	2	Mts	12	t	t
200098	TRIPA CELULOSA 19X95	0	2	Mts	12	t	t
3000128	RODAMIEMTO RIGIDO60002RSC3-FAG	0	3	Uni	12	t	t
300033	LIJA 400 PLIEGOS	0	3	Uni	12	t	t
300036	ANGULO DE METAL DE 1 1/2 HIERRO	0	3	Uni	12	t	t
300041	RODILLOS PARA PINTAR	0	3	Uni	12	t	t
300047	PEGA OBTALIN PARA PAPEL TAPIZ	0	3	Uni	12	t	t
300050	SECCONES HEMBRA	0	3	Uni	12	t	t
300025	208855005 MODUL CPU A2 (CCP531)	0	3	Uni	12	t	t
300026	CAMARA BULLET HDCVI 1/3" CCD CMOS 1.3MP 2.7-12 MM IR 30M IP 67. DAHUA	0	3	Uni	12	t	t
300027	TRANSFORMADOR 12VDC 1.25A	0	3	Uni	12	t	t
300028	VIDEO BALUM PASIVO HDCVI 400 MTS (PAR)	0	3	Uni	12	t	t
300054	SELLADOR GRAFITI SILIPEX TRANSPARENTE 290 ML	0	3	Uni	12	t	t
300066	LLAVE PARA LAVAMANOS	0	3	Uni	12	t	t
300070	HERRAJE P / WC MOD. ECONOMAX	0	3	Uni	12	t	t
300058	VARILLA DE PLATA AL 5%	0	3	Uni	12	f	t
900006	CARAPACHO - CDM POLLO	0	4	.	0	f	f
3000101	GOMA REFRACTARIA PARA LOS HORNOS	0	3	Uni	12	t	t
3000102	ESTOPERA 17-30-5	0	3	Uni	12	t	t
3000106	GUARDAMOTOR MAGNETOTERMICO 37-50A, 50KA EN 440VCA, ACCIONADO POR MANDO GIRATORIO	0	3	Uni	12	t	t
3000110	RELE TEMPORIZADOR MULTIRANGO 0.05S-3H	0	3	Uni	12	t	t
3000114	CABLE THHW (TF) N° 18 ROJO AWG 90	0	3	Uni	12	t	t
3000118	ROLLO TEIPE 33	0	3	Uni	12	t	t
3000120	ESMALTE AZUL COLONIAL	0	3	GALON	12	t	t
100021	MADEJA	0	1	Uni	12	f	t
2000100	TRIPA TAPARA 18X51	0	2	Mts	12	t	t
3000124	CADENA DOBLE RC80/ 2-KAN	0	3	Uni	12	t	t
3000131	SELECTOR 3 POSICIONES 22MM	0	3	Uni	12	t	t
3000134	BOLSAS PLASTICAS 10KG C/ASA (10X100)	0	3	Bulto	12	t	t
3000137	ROLLOS PARA SUMADORA	0	3	Uni	12	t	t
3000140	HUELLEROS	0	3	Uni	12	t	t
3000143	RODAMIENTO DE/ RODILLOS BOWER MU1313V-BOW	0	3	Uni	12	t	t
3000144	COLETOS DE TELA	0	3	Uni	12	t	t
3000147	PALOS PARA ESCOBA	0	3	Uni	12	t	t
3000149	REGULADOR  DE VOLTAJE	0	3	Uni	12	t	t
3000152	TEIPE ELECTRICO VERDE 3/4 X 18 MTS COBRA	0	3	Uni	12	t	t
3000159	SAL EN GRANO	0	3	Uni	12	t	t
900005	EMULSION PARA M. ESPECIAL	0	4	.	0	f	f
3000175	SELECTORES 3 POSICIONES 22MM	0	3	Uni	12	t	t
3000177	CARBON DE TRONZADORA 14-2 BOSCH	0	3	Uni	12	t	t
300051	CUCHILLO CHEF 5	0	3	Uni	12	t	t
300055	LIMPIADOR ELECTRONICO PERMAFLEX E010-LL	0	3	Uni	12	t	t
300063	LLAVE BOLA 1/2	0	3	Uni	12	t	t
300067	HERRAJE	0	3	Uni	12	t	t
300071	CANILLA PVC 1/2 A 1/2	0	3	Uni	12	t	t
3000179	REGENERACION DE TONNER 85A	0	3	Rollo	12	t	t
300059	MOTOR PARA REFRIGERACION 1E 1/3 H	0	3	Uni	12	f	t
300074	SET RODAMIENTOS DELANTEROS SPARK	0	3	Uni	12	t	t
3000181	CINTA EPSON 1X 300	0	3	Uni	12	t	t
300031	CALZADO DE SEGURIDAD CON PUNTERA NEGRO	0	3	Uni	12	t	t
300034	LIJA 220 PLIEGOS	0	3	Uni	12	t	t
300039	RODAMIENTO 6202	0	3	Uni	12	t	t
300077	CALCULADORA DE 12 DIGITOS	0	3	Uni	12	t	t
300084	JABON LIQUIDO	0	3	Litro	12	t	t
3000183	ARANDELA PRESION 3/8"	0	3	Uni	12	t	t
300037	PINTURA VERDE EN ACEITE	0	3	GALON	12	t	t
300042	BROCHAS 6"	0	3	Rollo	12	t	t
3000187	GUARDAMOTOR TELEMECANIQUE 13-18AMP	0	3	Uni	12	t	t
3000189	TERMOSTATO	0	3	Uni	12	t	t
400001	MORTADELA ESPECIAL 1.0 Kgs	0	4	 	0	t	f
800003	SEGUN PRESUPUESTO 001 PARA CAVA DE EMPAQUE DE PROYECTOS ARM 2013 , C.A.	0	8	Uni	12	f	f
300086	CARPETA LOMO ANCHO TIPO CARTA	0	3	Uni	12	t	t
300090	VASOS V-2	0	3	Caja	12	t	t
300094	BOLSAS DE 5 KG	0	3	Bulto	12	t	t
300098	CAPACITOR DE 10 MDF	0	3	Uni	12	t	t
3000103	ARANDELA DE COBRE 8 INTERNO Y 12 EXTERNO	0	3	0	12	t	t
3000111	TERMINAL ZAPATO BRONCE P-400 P/CABLE 2/0 AL 500MCM	0	3	Uni	12	t	t
3000119	10 PAQUETE DE MARQUILLAS DEN NUMEROS DEL 0 AL 9	0	3	Uni	12	t	t
3000115	SUPERVISOR TRIF C/PROT VOLTFAS PERD E INVERT 208/220V	0	3	Uni	12	t	t
400002	MORTADELA ESPECIAL 2.5 Kgs	0	4	 	0	t	f
3000107	CONTACTOR 3 POLOS, CATEGORIA AC3, 65A 1NA+1NC, 220VCA. EVERLINK	0	3	Uni	12	t	t
3000121	ESMALTE  VERDE	0	3	GALON	12	t	t
3000125	RODAMIENTOS DE AGUJA PARA BOMBONAS DOSIFICADORA DE N1 TOWNSEN BR 283720	0	3	Uni	12	t	t
2000101	TEIPE NEGRO COBRA	0	2	Uni	12	t	t
3000132	TERMOSTATO PARA CAVA 0 A 24 GRADOS	0	3	Uni	12	t	t
3000135	LIBROS DE ACTAS DE 200 FOLIOS	0	3	Uni	12	t	t
3000138	PEGA EN BARRA 8  GR	0	3	Uni	12	t	t
3000141	LAMINA EMPACADURA NEOPRENE SL 1/8 X 1.20 MTS P/T 140-150 PSI 120°	0	3	Uni	12	t	t
2000102	HARINA DE TRIGO	0	2	Kg	0	f	t
3000145	LANILLAS	0	3	Uni	12	t	t
100038	RECORTE DE SEGUNDA	0	1	Kg	0	f	t
3000150	EXTINTOR 05 LBS PQS TIPO ABC	0	3	Uni	12	t	t
3000153	TUBO DE SILICON ROJO 70 C3 ALTA/ TEMP SILIPEX	0	3	Uni	12	t	t
3000155	PEGA DE SOLDADURA LIQUIDA P.V.C.  1/4 BAJA PRESION	0	3	Uni	12	t	t
3000157	DUPLICADO TIPO CISA	0	3	0	12	t	t
3000160	GUARDAMOTOR MAGNETOTERMICO 9-14A, 50 KA EN 440V CA. ACCIONADO POR PULSADORES	0	3	Uni	12	t	t
3000162	INTERRUPTOR TERMOMAGNETICO ACTI 9, IC6ON, 2 POLOS 10A	0	3	Uni	12	t	t
3000165	SELECTORES 3 POSICIONES TELEMECANIQUE	0	3	Uni	12	t	t
3000167	CABLE ST 3X14	0	3	Rollo	12	t	t
3000169	CAL LIQUIDO	0	3	Uni	12	t	t
3000170	PILA AAA	0	3	Uni	12	t	t
3000171	UÑA P/ LAVAMANO	0	3	Uni	12	t	t
3000172	CONTAC ANGULAR	0	3	Uni	12	t	t
100039	RECORTE DE RES	0	1	Kg	0	f	t
200099	CERO MERMA CAL 20X95	0	2	Mts	12	t	t
3000191	LENTE D/SEGURIDAD TRANSPARENTE	0	3	Uni	12	t	t
3000193	RESMA HOJAS CARTA REPROPAPER	0	3	Rollo	12	t	t
3000185	CONTACTO AUX GV3A08 TELEMECANIQUE	0	3	Uni	12	t	t
3000195	DESMONTAJE DEL EQUIPO DE BOMBEO SUMERGIBLE CON SUS ACCESORIOS PARA SU EVALUACION ELECTROMECANICA	0	3	Uni	12	t	t
3000197	SUMINISTRO Y APLICACION DE PRODUCTO DISPERSANTE DE ARCILLAS PARA LA LIMPIEZA DEL EMPAQUE DE GRAVA WL	0	3	Uni	12	t	t
3000198	APLICACION DE AGENTES QUIMICOS EN EL POZO MEDIANTE LA UTILIZACION DE COMPRESOR ALTA CAPACIDAD	0	3	Uni	12	t	t
3000199	SUMINISTRO Y APLICACION DE AGENTE QUIMICO (MN-500)	0	3	Uni	12	t	t
3000200	LIMPIEZA Y DESARROLLO DEL POZO CON AIRE UTILIZANDO COMPRESOR	0	3	Uni	12	t	t
3000201	REVISION ELECTROMECANICA DEL EQUIPO SUMERGIBLE Y SUS ACCESORIOS	0	3	Uni	12	t	t
400003	MORTADELA TAPARA	0	4	 	0	t	f
400004	MORTADELA EXTRA	0	4	 	0	t	f
400005	JAMON DE PIERNA	0	4	 	12	f	f
3000202	SUMINISTRO TRANSPORTE Y COLOCACION DE GRAVA SELECCIONADA	0	3	Uni	12	t	t
3000203	MOTOR SUMERGIBLE MARCA HITACHI 10 HP /230 VAC 6" TRIFASICO	0	3	Rollo	12	t	t
3000204	AJUSTE DE CUERPO DE BOMBA, ACOPLE A MOTOR Y PRUEBA EN BANCO.	0	3	Uni	12	t	t
3000206	MANOMETRO DE RANGO 0-200 PSIG	0	3	Uni	12	t	t
400006	JAMON DE ESPALDA	0	4	 	12	f	f
400007	JAMON DE PIERNA DON VICENZO	0	4	 	12	f	f
400008	PALETA AHUMADA	0	4	 	12	f	f
3000207	TRASLADO EQUIPO DE INSTALACIÓN. INCLUYE: MOVILIZACION Y DESMOVILIZACION	0	3	Rollo	12	t	t
3000208	INSTALACION DE EQUIPO DE BOMBEO SUMERGIBLE 6" MENOR DE 100 M PROFUND	0	3	Uni	12	t	t
3000209	ARRANQUE Y PUESTA EN MARCHA DEL EQUIPO DE BOMBEO	0	3	Rollo	12	t	t
3000210	RELE MINI- SUBTRONIC ESPECIAL PARA BOMBAS SUMERGIBLES MODELO 10-32 A 480V	0	3	Uni	12	t	t
3000211	BREAKER SOLO MAGNETICO TRIPOLAR DE 40 AMP MARCA WEG	0	3	Uni	12	t	t
3000212	PINTURA ANTICORROSCIVA FERROPROTECTOR	0	3	GALON	12	t	t
3000213	LIMPIEZA MECANICA DE COLUMNA DE DESCARGA, APLICACION DE FERROPROTECTOR Y VERIFICACION DE ROSCAS	0	3	Uni	12	t	t
3000214	GUARDAMOTOR TELEMECANIQUE GV3ME40 25-40 AMP	0	3	Uni	12	t	t
3000215	BOMBONAS DE NITROGENO	0	3	Uni	12	t	t
3000216	PRESOSTATOS DE ALTA Y BAJA	0	3	Uni	12	t	t
3000217	VALVULA DE SERVICIO PARA COMPRESOR	0	3	Rollo	12	t	t
3000218	SOLVENTE ELECTRICO	0	3	Litro	12	t	t
3000219	ACEITE SUNISO 68	0	3	Litro	12	t	t
900001	PRODUCCION	0	4	.	0	f	f
900002	DEPOSTE	0	4	.	0	f	f
300085	CANAL EN LAMINA GALVANIZADA CALIBRE 24 DESARROLLO 72 REMACHADA, SOLDADA A ESTAÑO LOS EMPATES, TAPAS	0	3	.	12	t	t
300087	CARPETA LOMO ANCHO TIPO CARTA	0	3	0	12	t	t
300016	BOLSAS 5Kg	0	3	Bulto	12	f	t
300091	CLIPS NEGROS GRANDES	0	3	Uni	12	t	t
300095	BOLSAS DE ASA DE 5 KG	0	3	Bulto	12	t	t
300048	MANGUERA DE 3/4	0	3	Mts	12	t	t
200080	TRIPA MORTADELA ESPECIAL 75 AP (mts)	0	2	Mts	12	f	t
300052	PILA CR2016	0	3	Uni	12	t	t
300056	SELLADOR GRAFITI SILIPEX ROJO 75ML	0	3	Uni	12	t	t
300064	LLAVE DE ARRESTO	0	3	Uni	12	t	t
300068	CODO PVC DE 6"	0	3	Uni	12	t	t
300072	HOJAS MEMBRETE A FULL COLOR EN PAPEL EXTRA BLANCO TAMAÑO CARTA	0	3	Uni	12	t	t
300013	CALCULADORA CASSIO BOLSILLO	0	3	Uni	12	f	t
300014	GRAPAS 5000 UNIDADES	0	3	Uni	12	f	t
300017	TEIPE ELECTRICO VERDE	0	3	Uni	12	f	t
300060	RODAMIENTO 6202	0	3	Uni	12	f	t
300075	ESTOPERA 46X62X7	0	3	Uni	12	t	t
300045	BOMBONA DE GAS PARA EL MONTACARGA	0	3	Uni	12	t	t
300011	DISCO DE CORTE DE ESMERIL PEQUEÑO DE 4"	0	3	Uni	12	t	t
300012	DISCO DE ESMERIL GRANDE DE CORTE DE 7"	0	3	Uni	12	t	t
300018	GRASA EP 3.5KG AZUL	0	3	Uni	12	t	t
300019	ORING MM	0	3	Uni	12	t	t
300021	RODAMIENTO RIGIDO (62062RSC3-SKF)	0	3	Uni	12	t	t
300022	RODAMIENTO RIGIDO (62102RS-FAG)	0	3	Uni	12	t	t
300023	GRASA GRADO ALIME	0	3	Uni	12	t	t
300024	PEGA PEGA-MIX BLANCA	0	3	Uni	12	t	t
300078	CAJA DE LAPICEROS NEGROS DE 12 UNIDADES	0	3	Uni	12	t	t
300080	MANGUERA DE POLIURETANO 8 MM	0	3	Mts	12	t	t
300099	CONTROL UNIVERSAL PARA A/A	0	3	Uni	12	t	t
3000182	TORNILLO HEXAGONAL G8 3/8-16	0	3	Uni	12	t	t
3000104	PEGA PARA TORNILLOS (ROJA)	0	3	Uni	12	t	t
3000108	INTERRUPTOR TERMOMAGNETICO ACTI 9, IC60N, 1 POLO, 6A	0	3	Uni	12	t	t
3000112	BARRA COPPERWELD 3/8 X 240MTS	0	3	Uni	12	t	t
3000116	CONECTOR DE 80 AMPERIOS 220 VOLTIOS 1NA+1NC MARCA TELEMECANQUE MODELO LC1D80M7. PARA CONGELADORA	0	3	Uni	12	t	t
3000122	CAMISA DE PELO LARGO 9" PARA RODILLO	0	3	Uni	12	t	t
3000126	RODAMIENTOS DE CONTACTO ANGULAR DE BOLA 7007	0	3	Uni	12	t	t
3000129	CARBONES PARA TRONZADORA	0	3	Uni	12	t	t
3000133	BOLSAS PLASTICAS 15KG C/ASA (10X100)	0	3	Bulto	12	t	t
3000136	MARCADOR ACRILICO NEGRO	0	3	Uni	12	t	t
3000139	CINTAS PLASTICAS	0	3	Uni	12	t	t
3000142	FREON 22	0	3	Uni	12	t	t
2000103	ESPONJAS DE ALAMBRE	0	2	0	12	t	t
400009	PALETA AHUMADA PEQ.	0	4	 	12	f	f
3000146	CEPILLOS DE CERDAS FINAS	0	3	Uni	12	t	t
3000148	MAUS USB	0	3	Uni	12	t	t
3000151	TERMINAL DE LATON HEMBRA FORRADO PLANO AMARILLO	0	3	Uni	12	t	t
3000154	SOCATE E27 NDE CERAMICA C/ PROTECTOR DE METAL	0	3	Uni	12	t	t
3000156	TEFLON PROFESIONAL DE 3/4 X 15 MTS	0	3	Uni	12	t	t
3000158	IMPERMEABLES PONCHO TALLA UNICA	0	3	Uni	12	t	t
3000161	CONTACTOR 3 POLOS, CATEGORIA AC3, 18 A 1NA + 1NC 220V CA	0	3	Uni	12	t	t
301001	ETIQUETA ESPALDA COCIDA (vicosa)	31	3	.	0	f	t
301002	ETIQUETA FIAMBRE DE CARNE DE CERDO (vicosa)	31	3	.	0	f	t
301004	ETIQUETA MORTADELA TIPO ESPECIAL (vicosa)	31	3	.	0	f	t
301005	ETIQUETA MORTADELA TIPO EXTRA (vicosa)	31	3	.	0	f	t
301006	ETIQUETA SALCHICA COCIDA TIPO VIENA (vicosa)	31	3	.	0	f	t
301007	ETIQUETA SALCHICA TIPO BOLOÑA DE POLLO (vicosa)	31	3	.	0	f	t
302001	ETIQUETA MORTADELA DE POLLO TIPO ESPECIAL (procarni)	32	3	.	0	f	t
302002	ETIQUETA PALETA DE CERDO AHUMADA (procarni)	32	3	.	0	f	t
302003	ETIQUETA SALCHICHA DE POLLO (procarni)	32	3	.	0	f	t
301003	ETIQUETA JAMON COCIDO ETIQUETA AZUL (vicosa)	31	3	.	0	f	t
300020	PEGA PEGATANKE EPOXI	0	3	Rollo	12	t	t
200034	CONDIMENTO POLACA	0	2	Kg	12	f	t
400010	FIAMBRE	0	4	 	12	f	f
400011	CHORIZO CARUPANERO	0	4	 	12	f	f
400012	CHORIZO DE AJO	0	4	 	12	f	f
400013	SALCHICHA DE CARNE	0	4	 	12	f	f
400014	SALCHICHA DE POLLO	0	4	 	12	f	f
400015	SALCHICHA ALEMANA	0	4	 	12	f	f
400016	SALCHICHA S/PELAR DE CARNE	0	4	 	12	f	f
400017	SALCHICA S/PELAR DE POLLO	0	4	 	12	f	f
400018	BOLOÑA DE POLLO 3 Kgs	0	4	 	12	f	f
3000163	CABLE MONOPOLAR HELUKABEL SERIE H05V-K 0.75MM2 (18AWG) COLOR ROJO, 80°C	0	3	Mts	12	t	t
3000164	GUARDAMOTOR  TELEMECANIQUE 13-18 AMP	0	3	Uni	12	t	t
3000166	TERMOSTATO	0	3	Uni	12	t	t
3000168	TEE PVC	0	3	Uni	12	t	t
2000104	PILA AA	0	2	Uni	12	t	t
2000105	LLAVE PARA LAVAMANOS	0	2	Uni	12	t	t
200095	HIPOCLORITO DE SODIO AL 12%	0	2	Litro	12	f	t
3000173	ARANDELAS DE COBRE 8 MM	0	3	Uni	12	t	t
3000174	CORRUGADO DE TRIPA 75 ROJA	0	3	Uni	12	t	t
3000176	TERMOSTATO PARA CAVA 0 A 24 GRADOS	0	3	Uni	12	t	t
3000178	TEIPE ELECTRICO 18 MTS USO PROFESIONAL COLOR NEGRO, RESISTENTE AL ACEITE COBRA.	0	3	Uni	12	t	t
3000180	REGENERACION CANNON 120	0	3	Uni	12	t	t
3000184	CONTACTO AUX GV3A01 TELEMECANIQUE	0	3	Uni	12	t	t
3000186	BRAKER CDB6L1C6	0	3	Uni	12	t	t
3000188	SELECTOR TELEMECANIQUE 3 PROSICIONES	0	3	Uni	12	t	t
3000190	CABLE ST 2X14	0	3	Uni	12	t	t
3000192	TEE A/N PVC 2" GENERICO	0	3	Uni	12	t	t
200037	FONDO DE MULTIVAC	0	2	Mts	12	f	t
200072	TAPA DE MULTIVAC (POLLO)	0	2	Mts	12	f	t
3000194	TRASLADO DE LOS EQUIPOS DE LIMPIEZA	0	3	Uni	12	t	t
3000196	INSTALACION DE LA TUBERIA DE LIMPIEZA Y AIRE PARA LIMPIEZA , DESARROLLO Y DESINFECCION DEL POZO	0	3	Rollo	12	t	t
3000205	EMPALME VULCANIZADO MODELO 82-A2DE 3M	0	3	Rollo	12	t	t
200020	BOLSAS PALETA AHUMADA GRANDE 23X46 CM	0	2	.	12	f	t
200021	BOLSAS PALETA AHUMADA PEQUEÑA 15X61 CM	0	2	.	12	f	t
200022	BOLSAS RECORTES S-IMP 33X56 CM	0	2	.	12	f	t
200023	BOLSAS SALCHICHA DE POLLO PC IMP 23X46 CM	0	2	.	12	f	t
200024	BOLSAS S-IMP 15X61 CM	0	2	Caja	12	f	t
200027	BOLSAS TOCINETA AHUMADA GRANDE 33X80 CM	0	2	.	12	f	t
200028	C.L.T. COLORANTE	0	2	Kg	12	f	t
200029	C.T.T. (CITRATO)	0	2	Kg	12	f	t
200030	CANELA EN POLVO	0	2	Kg	12	f	t
200031	CARMIN	0	2	Kg	12	f	t
200032	CARRAGENATO	0	2	Kg	12	f	t
200033	CODIMAT T 200	0	2	Caja	12	f	t
200082	TRIPA MORTADELA TAPARA 120 (moño)	0	2	.	12	f	t
200083	TRIPA POLIAMIDA CERO MERMA CARNE 24X84 (mts)	0	2	.	12	f	t
200035	CONFORT T34	0	2	Kg	12	f	t
200036	ERITORBATO	0	2	Kg	12	f	t
200038	G.M.S.	0	2	Kg	12	f	t
200040	GRAPA TIPPER TIE E 212	0	2	Caja	12	f	t
200042	GRAPAS E 232	0	2	Caja	12	f	t
200044	GRAPAS S 8740	0	2	Caja	12	f	t
200045	GRAPAS S 8744	0	2	Caja	12	f	t
200047	HARINA DE ARROZ	0	2	Kg	12	f	t
200048	HIPOCLORITO	0	2	Litro	12	f	t
200049	HUMO LIQUIDO	0	2	Kg	12	f	t
200050	JABON EN POLVO	0	2	Kg	12	f	t
200053	MADERA PARA AHUMAR (BULTOS)	0	2	Bulto	12	f	t
200054	MAYA ROJA CHULETA (ROLLOS)	0	2	Rollo	12	f	t
200055	OLEO ALMENDRA	0	2	Kg	12	f	t
200056	OLEO CAPSICUM	0	2	Kg	12	f	t
200058	OLEO MORTADELA	0	2	Kg	12	f	t
200061	OREGANO	0	2	Kg	12	f	t
200062	PIMIENTA NEGRA/BLANCA	0	2	Kg	12	f	t
200063	PRODUCTO DE LIMPIEZA	0	2	.	12	f	t
200064	PROTEINA DE CEREAL	0	2	Kg	12	f	t
200066	ROLLOS DE PABILO	0	2	Rollo	12	f	t
200067	SABOR DE JAMON	0	2	Kg	12	f	t
200069	SAL DE CURA	0	2	Kg	12	f	t
200070	SAL PARA CALDERA	0	2	Kg	12	f	t
200071	SODA CAUSTICA	0	2	.	12	f	t
200075	TRIPA DE CELULOSA VISKEY 20X95	0	2	Caja	12	f	t
200084	TRIPA POLIAMIDA CERO MERMA POLLO 24X84 (mts)	0	2	Caja	12	f	t
200089	TRIPOLIFOFATO	0	2	.	12	f	t
200090	ARCON S	0	2	.	12	f	t
200091	ARCON SM	0	2	.	12	f	t
200012	BOLSA SALCHICA ALEMANA	0	2	Caja	12	f	t
200093	DIFOSFATO	0	2	Kg	12	t	t
200094	ALMIDON DE YUCA (E)	0	2	Kg	0	f	t
300038	PINTURA AZUL EN ACEITE	0	3	GALON	12	t	t
300043	TINER	0	3	Litro	12	t	t
300079	BLOCK DE  RAYAS	0	3	Uni	12	t	t
200025	BOLSAS S-IMP 23X46 CM	0	2	Uni	12	f	t
200081	TRIPA MORTADELA EXTRA S/IMP 195 AP (mts)	0	2	Mts	12	f	t
200074	TRIPA BOLOÑA DE POLLO S/IMP K-F 105 CAL (mts)	0	2	Mts	12	f	t
200076	TRIPA DE PIERNA 280 CAL	0	2	Mts	12	f	t
200077	TRIPA ESPALDA IMPRESA 240 AP (mts)	0	2	Mts	12	f	t
200078	TRIPA FIAMBRE IMP 220 AP (mts)	0	2	Mts	12	f	t
200086	TRIPA VISKING GRANDE C/HUMO 10 CAL (mts)	0	2	Mts	12	f	t
200087	TRIPA VISKING PEQ FIBROSMOK SIN HUMO 280 AP (mts)	0	2	Mts	12	f	t
200088	TRIPA VISKING PEQ NOVATON CON HUMO 5 CAL (mts)	0	2	Mts	12	f	t
200079	TRIPA MORTADELA ESPECIAL 110 AP (mts)	0	2	Mts	12	f	t
200092	TRIPA PLASTICA F2 CALIBRE 72 COLOR CARMIN	0	2	Mts	12	t	t
200051	LOOPS CRUDO	0	2	Uni	12	f	t
200052	LOOPS TIPPER TIE	0	2	Uni	12	f	t
300032	LIJA 80 PLIEGOS	0	3	Uni	12	t	t
300035	ANGULO DE METAL DE 1 1/2 HIERRO	0	3	Uni	12	t	t
300040	RODAMIENTO 6204	0	3	Uni	12	t	t
300046	CAL LIQUIDO	0	3	Uni	12	t	t
300049	SECCONES MACHO	0	3	Uni	12	t	t
300053	CUCHILLO CHEF 4	0	3	Uni	12	t	t
300057	RETEN INTERNO 472-34	0	3	Uni	12	t	t
300065	SILICON TRANSPARENTE	0	3	Uni	12	t	t
300069	PAPELERA BLANCA SWING MANAPL	0	3	Uni	12	t	t
300073	RESMA DE HOJAS DE PAPEL BOND TAMAÑO CARTA	0	3	Uni	12	t	t
300061	DISPENSADOR DE AGUA RIDGO	0	3	Uni	12	f	t
300076	ESTOPERA MILIMETRICA 46X62X8/13	0	3	Uni	12	t	t
200060	OLEO SALCHICHA	0	2	Kg	12	f	t
200057	OLEO FRANKFOURT	0	2	Kg	12	f	t
300081	MANGUERA DE POLIURETANO DE 6 MM	0	3	Mts	12	t	t
200026	BOLSAS TOCINETA AHUMADA 33X68 CM	0	2	Uni	12	f	t
200014	BOLSAS COCTEL DE POLLO	0	2	Uni	12	f	t
200013	BOLSAS COCTEL DE CERDO	0	2	Uni	12	f	t
200039	GRAPA CODIMA HE 401 T	0	2	Uni	12	f	t
200041	GRAPAS 401 ZR	0	2	Uni	12	f	t
200043	GRAPAS S 744T	0	2	Uni	12	f	t
200046	GRAPAS XE 210T	0	2	Uni	12	f	t
200065	AISLADO DE SOYA (PROTEINA DE JAMON)	0	2	Kg	12	f	t
800001	UNIDAD DE REFRIGERACION 1	0	8	Uni	12	f	f
300088	HOJAS BLANCAS TAMAÑO CARTA	0	3	Uni	12	t	t
300092	CINTA IMPRESORA APSOM FX2190	0	3	Uni	12	t	t
300096	MOUSE USB	0	3	Rollo	12	t	t
3000100	CORREA MILIMETRICA 2450-14 M-36GT	0	3	Uni	12	t	t
200059	OLEO PAPRIKA	0	2	Kg	12	f	t
3000105	GUARDAMOTOR MAGNETOTERMICO 17-23A, 50KA EN 440VCA,  ACCIONADO POR PULSADORES	0	3	Uni	12	t	t
3000109	GUARDAMOTOR MAGNETOTERMICO 56-80A, 50KA EN 440VCA, ACCIONADO POR MANDO GIRATORIO	0	3	Uni	12	t	t
3000113	CONECTOR BARRA COPPERWELD 5/8	0	3	Uni	12	t	t
3000117	BLOQUE DE CONTACTO FRONTAL MODELO LAND11 1NA+1NC	0	3	Uni	12	t	t
3000123	BROCHA DE 6"	0	3	Uni	12	t	t
3000127	RODAMIENTO DE BOLA 6911 R5	0	3	Uni	12	t	t
200085	TRIPA POLIAMIDA CERO MERMA S/IMP CAL 22 (mts)	0	2	Mts	12	f	t
3000130	SOCATES E-27	0	3	Uni	12	t	t
200073	TAPA DE MULTIVAC (VIENA)	0	2	Mts	12	f	t
3000220	ACIDO PARA LIMPIEZA	0	3	Litro	12	t	t
3000221	MANTENIMIENTO GENERAL A UNIDAD CONDESADORA DE CAVA DE CDM	0	3	Uni	12	t	t
3000222	FLETE	0	3	Uni	12	t	t
3000223	LAMETAS NUEVAS	0	3	Uni	12	t	t
3000224	DISCOS 225 AFILADOS	0	3	Uni	12	t	t
3000225	DISCO DE MOLINO 220 NUEVAS	0	3	Rollo	12	t	t
3000226	CUCHILLAS DE MOLINO 180 AFILADAS	0	3	Uni	12	t	t
3000227	ADAPTACION DE SINFIN MICROCUTTER REPARADO	0	3	Rollo	12	t	t
3000228	ELECTRODOS 6013	0	3	Rollo	12	t	t
2000106	SECON 32 AMP	0	2	Rollo	12	t	t
3000229	SECON 32 AMP ENCHUFE	0	3	Uni	12	t	t
3000230	ALIMENTO DE PERRO	0	3	Uni	12	t	t
3000231	ALICATE DE PRESION MORDAZA CURVA 10"	0	3	Uni	12	t	t
3000232	LLAVEN ALLEN 10 PZA	0	3	Uni	12	t	t
3000233	ALICATE ELECTRICISTA 8"	0	3	Rollo	12	t	t
3000234	RELE DE 120 V 8 PINES	0	3	Uni	12	t	t
3000235	FORMAS CONTINUA 9 1/2 X 5 1/2 DE DOS PARTES EN PAPEL BOND	0	3	Uni	12	t	t
100040	LAGARTO	0	1	Kg	0	f	t
100041	PULPA DE MADRE	0	1	Kg	0	f	t
3000236	BOTA DE SEGURIDAD MARCA FION MODELO 70020	0	3	Uni	12	t	t
3000237	LIBROS DE ACTA DE 300 FOLIOS	0	3	Uni	12	t	t
3000238	CAMISA OXFORD TALLA S DE CABALLEROS COLOR BLANCO	0	3	Uni	12	t	t
3000240	CAMISA M 3/4 TALLA S DE DAMA COLOR BLANCO	0	3	Uni	12	t	t
3000239	CAMISA OXFORD M/C TALLA S COLOR GRIS	0	3	Rollo	12	t	t
3000241	ESTOPERA MILIMETRICA 50X100X10	0	3	Uni	12	t	t
3000242	ESTOPERA 110X145X13	0	3	Uni	12	t	t
3000243	BOMBA SUMERIGIBLE	0	3	Uni	12	t	t
3000244	BLOCK AUTORIZACION DE PERSONAL IMPRESOS A UN COLOR	0	3	Uni	12	t	t
3000245	TEIPE NEGRO COBRA	0	3	Uni	12	t	t
3000246	ESPONJAS DE ALAMBRE	0	3	0	12	t	t
3000247	PILA AA	0	3	Uni	12	t	t
3000248	LLAVE PARA LAVAMANOS	0	3	Uni	12	t	t
3000249	SECON 32 AMP	0	3	Rollo	12	t	t
3000250	REGLETA PARA 110 V CON PROTECTOR DE FASE	0	3	Uni	12	t	t
3000251	ESCALERA DE 4 PELDAÑOS	0	3	Uni	12	t	t
3000252	CINTA TIRRAJE DE 14"	0	3	Uni	12	t	t
3000253	CINTA TIRRAJE DE 18"	0	3	Uni	12	t	t
3000254	BROCHA DE 4"	0	3	Uni	12	t	t
3000255	PINTURA ALUMINIO	0	3	Uni	12	t	t
3000256	TIRRO BLANCO DE 1"	0	3	Uni	12	t	t
3000257	VALVULA DE SERVICIO DE BAJA PRESION (REFRIGERACION)	0	3	Uni	12	t	t
3000258	VALVULA DE SERVICIO DE ALTA PRESION  (REFRIGERACION)	0	3	Uni	12	t	t
\.


--
-- Data for Name: tm_producto_fin; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_producto_fin (codprodt, cdescripcion, tunidad, civa) FROM stdin;
\.


--
-- Data for Name: tm_proveedor; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_proveedor (id, crif, cnomb_fis, cnomb_com, ctlf1, ctlf2, cemail, cdireccion, cestado, ctipoprod) FROM stdin;
5	J-31156044-0	LA CASA DEL CHEF C.A.		0	0		CL. BERMUDEZ CASA N° 59 SECTOR CENTRO TURMERO		1
0	0	0	0	0	0	0	0	0	0
7	J-40088423-3	INVERSIONES VILLAS DE ARAUCA, C.A	INVERSIONES VILLAS DE ARAUCA, C.A	02432698142	04144490885	INVEARAUCA@HOTMAIL.OM	CALLE LAS INDUSTRIAS, CASA GALPON N°. 1., SECTOR EL TIERRAL SAN JOAQUIN DE TURMERO EDO ARAGUA		2
8	J-31028628-0	AGROSISTEMAS JPJ C.A.	AGROSISTEMAS JPJ C.A.	02418680690	02418687968	COORDINADORCOMERCIAL@AGROSISTEMASJPJ.COM.VE	CALLE EL REFUGIO, LOTE 1, PARCELAS 34 Y 35, NAGUANAGUA, SECTOR EL GUAYABAL. EDO. CARABOBO - VENEZUELA.		2
31	J-29607862-9	DISTRIBUIDORA AROMA, C.A.	DISTRIBUIDORA AROMA, C.A.	02124351921	04143343199	distaroma@gmail.com	CL. EDUARDO CALCANO, QTA BETHANI N 5, URB. SANTA MONICA		2
32	J-40093098-7	DIAMENCA, C.A.	DIAMENCA, C.A.	02432830497	0	DIAMENCAVENTAS@GMAIL.COM	CALLE PAEZ NO. 45, LOCAL 1 Y 3, SECTOR LA CANDELARIA,  CAÑA DE AZUCAR, ESTADO ARAGUA		2
9	J-29979062-1	DISTRIBUIDORA SAN JUDAS TADEO, C.A.	DISTRIBUIDORA SAN JUDAS TADEO, C.A.	02587271163	\N		CTRA. TRONCAL 005 EDIF. MATADERO BEDECA, PISO PB, OF. S/N SECTOR LA VILLEGUERA, SAN CARLOS - EDO. COJEDES, ZONA POSTAL 2206		2
10	V-14319430-9	LEAL DELI	FREDDY JOSE LEAL TRUJILLO	04243012373	\N		AV CIRCUNVALACION 2 MANZANA 29 CASA NRO 18 URB EL CASTAÑO, MARACAY EDO. ARAGUA ZONA POSTAL 2102		1
12	V-17496658-0	DISRAMIREZ J.C.	DISRAMIREZ J.C.	04247321597	04265755249		CARRETERA PANAMERICANA - CASA N° T-43 - SECTOR LA TERMOELECTRICA - LA FRIA ESTADO TACHIRA		1
13	J-40954263-7	SUMINISTROS INDUSTRIALES REMCA C.A.	SUMINISTROS INDUSTRIALES REMCA C.A.	04243358773	04263459227	SUMINISTROSINDUSTRIALESREMCA@GMAIL.COM	CALLE 1, CASA NRO 22-F, URB PALMA REAL, MARACAY - EDO ARAGUA. ZONA POSTAL 2103.		3
14	J-40853963-2	MULTI SUMINISTROS MAGNAM, C.A.	MULTI SUMINISTROS MAGNAM, C.A.	04163458236	0	SUMINISTROSMAGNAM@GMAIL.COM	CALLE COROMOTO- EDIF. RESIDENCIAS VILLA JARDIN - PISO 13- AOTO. N! 13-B- URB. CALICANTO 4TA TRANSVERSAL MARACAY-EDO - ARAGUA- ZONA POSTAL 2101		3
16	J-31710098-0	FERRETERIA LOS CEDROS, C.A.	FERRETERIA LOS CEDROS, C.A.	02444474845	02443955145	FERRETERIALOSCEDROS@GMAIL.COM	CALLE RONDON NORTE LOCAL N° 104-20-43 ZONA CENTRO CAGUA - EDO - ARAGUA ZONA POSTAL 2122		3
17	J-31751963-9	EMPATEC ALIMENTARIA C.A	EMPATEC ALIMENTARIA C.A	02129917675	02129917809		AV. VERACRUZ - EDIF. TORRE  ABA - PISO 5, OFIC.: 5-B URB. LAS MERCEDES - CARACAS ZP1061 - VENEZUELA		2
18	J-31649893-0	COMERCIALIZADORA JARCHI C.A.	COMERCIALIZADORA JARCHI C.A.	04167384056	04143473895	comercializadorajarchi@hotmail.com	AV. BERMUDEZ ESTE, N°. 104-66-04 SECTOR CENTRO CAGUA- ESTADO ARAGUA		3
19	J-30403069-0	HUPECA, C.A.	HUPECA, C.A.	0	0		AV. PRINCIPAL SAN VICENTE N° 2A		3
20	J-30554931-1	TECNO SEMARCA, C.A.	TECNO SEMARCA, C.A.	02432174921	02432479449	TECNO_SEMARCA@HOTMAIL.COM	AV. AYACUCHO, LOCAL N° 34 CENTRO MARACAY - EDO ARAGUA		3
21	J-29833877-6	J.E.P. INVERSIONES, C.A.	J.E.P. INVERSIONES, C.A.	02432183110	02435512761	RODAMIENTOSJEPINVERSIONESC.A@HOTMAIL.COM	AV. NUEVO BARRIO SANTA ROSA N° 25 SECTOR SANTA ROSA MARACAY EDO. ARAGUA		3
23	J-30219675-2	SERVIPORK, C.A.	SERVIPORK, C.A.	02432000600	0		AV. 6TA EDIF. LA CARIDAD PISO 1, OF. 1, URB. LA SOLEDAD MARACAY EDO. ARAGUA		1
24	J-30262340-5	RODAMIENTOS MORALES ROMORCA C.A.	RODAMIENTOS MORALES ROMORCA C.A.	02435530210	02435547613	romorca@movistar.net.ve	CALLE CARABOBO SUR LOCAL NRO 54 SECTOR SANTA ROSA, MARACAY ARAGUA. ZP 2101		3
25	J-31663568-6	TECHTROL SEGURIDAD INTEGRAL C.A.	TECHTROL SEGURIDAD INTEGRAL C.A.	02512325352	0	TECHTROLBARQUISIMETO@GMAIL.COM	AV VENEZUELA CON CALLE 32, C. PROFESIONAL DON MARTIN. BARQUISIMETO EDO LARA		3
44	J-07509056-0	COMERCIAL LA FLORIDA C.A.	COMERCIAL LA FLORIDA C.A.	02432462146	0		AV . SANTOS MICHELENA LOCAL NRO. 19 SECTOR CENTRO, MARACAY EDO ARAGUA		3
45	J-31670131-0	COMERCIALIZADORA AVICOMAR C.A.	COMERCIALIZADORA AVICOMAR C.A.	02123211180	02123219032	AVICOMAR@CANTV.NET	PARCELAMIENTO PARQUE INDUSTRIAL LA LOMITA, SECTOR LOS CERRITOS, GALPON N° 22, MEZZANINA.		1
26	J-00268847-5	DISTRIBUIDORA PABE 2011, C.A.	DISTRIBUIDORA PABE 2011, C.A.	0	0		MARACAY ARAGUA		1
28	J-30740411-6	UVFLEX, C.A.	UVFLEX, C.A.	02122518331	02122511556	UVFLEX@GMAIL.COM	AV. LA INDUSTRIA, EDIF. FELSINEA, PISO 1, LOCAL 1A, ZONA INDUSTRIAL DE PALO VERDE, CARACAS		3
33	J-30774219-4	UNIKERT DE VENEZUELA, S.A.	UNIKERT DE VENEZUELA, S.A.	02129750933	02129750543	ptablante@unikert.com	CENTRO EMPRESARIAL TORRE HUMBOLDT, MEZZANINA, OFICINA 4,5,6,7, PARQUE HUMBOLDT - PRADOS DEL ESTE, CARACAS		2
34	J-29998893-6	HALO TRADE, C.A.	HALO TRADE, C.A.	02446611852	04144606251	halotrade@hotmail.com	URBANIZACION VILLAS JUAN PABLO II, CALLE PRINCIPAL, ENTRANDO POR LA CALLE PRINCIPAL, ENTRANDO POR LA CALLE CENTRAL, CASA # 10-08. TURMERO, EDO ARAGUA		2
35	J-07527700-7	QUINCALLERIA LA NUEVA, C.A.	QUINCALLERIA LA NUEVA, C.A.	02435530561	0		CALLE CARABOBO SUR N° 107 SECTOR SANTA ROSA MARACAY EDO. ARAGUA		3
37	J-30023658-7	RODAMIENTOS CARVAN, C.A.	RODAMIENTOS CARVAN, C.A.	02435532549	0	rodamientoscarvan@hotmail.com	CALLE SAN MIGUEL LOCAL N° 49 URBANIZACION SANTA ROSA MARACAY EDO ARAGUA		3
38	J-31043303-8	M.C.MARACAY, S.A.	M.C.MARACAY, S.A.	02432463244	0	admonmcmaracay@hotmail.com	AV LOS CEDROS LOCAL NRO 57 SECTOR BARRIO LOURDES - MARACAY		3
39	J-31565447-4	REPRESENTACIONES RM MAMUT, C.A.	REPRESENTACIONES RM MAMUT, C.A.	02443956072	02443958992	ventasrep.mamut@gmail.com	CTRA NACIONAL SENTIDO CAGUA- LA VILLA LOCAL GALPON NRO 08 ZONA INDUSTRIAL MUNICIPAL ESTE CAGUA - ESTADO- ARAGUA. ZONA POSTAL 2122		2
40	J-29423529-8	DISTRIBUIDORA LA FE DE DIOS, C.A.	DISTRIBUIDORA LA FE DE DIOS, C.A.	04124717637	0		CALLE PASAJE SAN IGNACIO N° 11, ZONA BARRIO CAMPO ALEGRE		1
46	J-40340186-1	INVERSIONES ABEMAR 72, C.A.	INVERSIONES ABEMAR 72, C.A.	02432721550	0		CALLE 5, CASA N° 310, URB. LOS SAMANES I. MARACAY - EDO - ARAGUA		3
47	V-08816215-0	ERNESTO GONZALO CASTRO CASTILLO F.P.	ERNESTO GONZALO CASTRO CASTILLO F.P.	04164477592	0		AV. MIRANDA ESTE N° 69, EDIF. BOLIVAR , 1 ER PISO, APTO. 16-B MARACAY EDO ARAGUA		3
48	J-40739575-0	AGROPECUARIA KREAS C.A.	AGROPECUARIA KREAS C.A.	04140494633	04144511217	agropecuariakreas@hotmail.com	CTRA. VIA VENEGAS , CASA FUNDO SAN ANTONIO SECTOR PIRITU BECERRA CALABOZO - EDO GUARICO.		1
49	J-40364961-8	RUARP GROUP. C.A.	RUARP GROUP. C.A.	0	0		AV. TERCERA. LOTE G LOCAL G-15 URB SAN JACINTO ZONA INDUSTRIAL MARACAY		2
50	J-30979789-3	FAMELER DE VENEZUELA, C.A.	FAMELER DE VENEZUELA, C.A.	02418781722	0	FAMELER01@GMAIL.COM	AV. 76, EDIF. CONJUNTO GALINCA I, PISO N N/A , LOCAL GALPON N° 2, URB INDUSTRIAL EL RECREO, VALENCIA , EDO . CARABOBO, VENEZUELA		3
51	J-40792303-0	PRODUCARNES C.A	PRODUCARNES C.A	04243458853	04149457042	imdproducarnes@gmail.com	CALLE, 33 CASA NRO. 2-06, CONJUNTO RESIDENCIAL CIUDADELA, LOTE XXIV , CAGUA EDO. ARAGUA. ZP 2122		1
52	J-31202433-0	SUMINISTROS RAGDE C.A.	SUMINISTROS RAGDE C.A.	02432325894	0		CALLE BOYACA N° 130  CENTRO MARACAY EDO ARAGUA		3
53	J-30121687-3	POLY BAG DE VENEZUELA, C.A.	POLY BAG DE VENEZUELA, C.A.	02432690904	02432690927	polybagventas@gmail.com	AV. INTERCOMUNAL DE TURMERO MARACAY, LOCAL PARCELA N 31 SECTOR LA PROVIDENCIA, GALPON 11-A Y 7-D		2
11	J-40555419-3	DINASTIA GONZALEZ, C.A.	DINASTIA GONZALEZ, C.A.	04144607743	\N	dinastiasgonzalezca@gmail.com	AV. PRINCIPAL CALLE N, CASA GALPON N° 2, ZONA INDISTRIAL SAN VICENTE II, CONGLOMERADO MANUEL OLIVARES BETANCOURT, MARACAY, EDO. ARAGUA ZP 2103		1
56	J-30889150-9	SUPPLY STEEL C.A.	SUPPLY STEEL C.A.	02454159299	0	supplysteelca@gmail.com	URB. INDUSTRIAL PARAPARAL CALLE A1 - GALPON KING MASTER N° 02 Y 03 LOS GUAYOS EDO CARABOBO		3
57	J-31072763-5	VICSAN DISTRIBUCIONES, C.A.	VICSAN DISTRIBUCIONES, C.A.	04143952201	0	vicsandistribuciones@hotmail.com	AV. LA PROLONGACION DE LA AVENIDA ARAGUA, CC Y PROFESIONIAL CELTIC CENTER, NIVEL 3 }, OFIC 7, SECTOR ASENTAMIENTO CAMPESINO LA MORITA I TUERMERO EDO. ARAGUA		1
58	J-40366413-7	PROYECTOS ARM 2013, C.A.	PROYECTOS ARM 2013, C.A.	04123005048	04264414494	PROYECTOSARM2013@GMAIL.COM	CALLE 18, CASA NRO. 27 - B, URB. EL TOQUITO VILLA DE CURA. EDO . ARAGUA. ZONA POSTAL 2126.		3
59	J-07519834-4	FRIGORIFICO BETTOLI C.A.	FRIGORIFICO BETTOLI C.A.	0	0	FBETOLLI@HOTMAIL.COM	AV. BERMUDEZ EDIF. BETTOLI N° 74-A MARACAY EDO. ARAGUA		3
60	J-29467245-0	SHOMI.COM. C.A.	SHOMI.COM. C.A.	02436351965	0	SHOMI-JC@HOTMAIL.COM	CALLE SAN IGNASIO LOCAL N° 77-B SECTOR LOURDES MARACAY EDO. ARAGUA		3
61	J-30456458-9	REFRI-REPUESTOS NARVAEZ, C.A.	REFRI-REPUESTOS NARVAEZ, C.A.	02432363845	02432365172		AV. CONSTITUCION LOCAL N° 214 URB LA MARACAYA, MARACAY EDO. ARAGUA		3
62	J-29443361-8	GOVICA MARACAY C.A.	GOVICA MARACAY C.A.	02432358432	02432357589		AV ARAGUA NRO 60 SECTOR CENTRO , MARACAY EDO. ARAGUA		3
63	J-30512681-0	MULTISERVICIOS RAISCA C.A.	MULTISERVICIOS RAISCA C.A.	02432359015	04166183957		CALLE EL PROGRESO CASA N°. 6 URB. EL PIÑONAL MARACAY EDO. ARAGUA		3
64	J-31652664-0	CONTROL TECH	CONTROL TECH	04262383024	0	email@email.com	CARABOBO..		3
65	J-31295649-6	HYPER ELECTRICOS ARAGUA, C.A.	HYPER ELECTRICOS ARAGUA, C.A.	0	0		TURMERO ARAGUA		3
66	J-07511771-9	CENTRO CONTROL CARABOBO, C.A.	CENTRO CONTROL CARABOBO, C.A.	02418320594	02418325074	centrocontrolcarabobo@gmail.com	URB. INDUSTRIAL CARABOBO-PROLONGACION AV. MICHELENA (A 100 MTS DEL BCO. BICENTENARIO)		3
67	J-30994346-4	COLORISIMA ARAGUA	COLORISIMA ARAGUA	0	0		AV ARAGUA ESTE LOCAL N° 1 SECTOR SAN IGNACIO		3
68	J-40412667-8	MULTISERVICIOS L.G.B. 2014, C.A.	MULTISERVICIOS L.G.B. 2014, C.A.	04144506561	04243797002		AV. JOSE FELIX RIBAS, CASA N° 15-A- SECTOR LOS TELEGRAFISTAS - SAN JUAN DE LOS MORROS, EDO . GUARICO		1
69	J-31158609-1	DISTRIBUIRA EURO QUALITE, C.A.	DISTRIBUIRA EURO QUALITE, C.A.	02122380695	04142487990	EURO.QUALITET@GMAIL.COM	ESQ. PEDRO MANRIQUE, EDIF. CONJUNTO RESID. CENTRO ALOA, TORRE C, PISO 4, OFC. C-42		1
70	J-31643385-4	LA GRANJA AVICOLA R.K.F, C.A.	LA GRANJA AVICOLA R.K.F, C.A.	02392483535	02392488065		CARRETERA CHARALLAVE - CUA AV. A - PARCELA 191, URB. INSDUSTRIAL RIO TUY - EDO. MIRANDA		1
71	J-40133493-8	CARNICA, C.A.	CARNICA, C.A.	02435516438	02435515759	carnesindustriales@gmail.com	AV. ANTHON PHILIPS, LOCAL GALPON N° 38-A }, ZONA INDUSTRIAL LA HAMACA MARACAY EDO. ARAGUA		1
72	J-29989780-9	AGROPECUARIA DISPROCARNE C.A.	AGROPECUARIA DISPROCARNE C.A.	04144764929	04243192663		CARRETERA NACIONAL LOCAL- 61 SECTOR VISTA ALEGRE MARIARA EDO. CARABOBO - ZONAL POSTAL 2017		1
73	J-30892045-2	NIVEAR, C.A.	NIVEAR, C.A.	02432366914	0		CALLE 7 CASA N° 8 URB. PARAPARAL, PRIMERO SECTOR LOS GUAYOS- EDO. CARABOBO - ZONA POSTAL 2003		3
74	J-40440661-1	FUMIGACION UNIVERSAL, C.A.	FUMIGACION UNIVERSAL, C.A.	02432186608	02432150510	ventas@sisfu.com.ve	CALLE 8, LOCAL N° 4 23-A LA BARRACA MARACAY, EDO. ARAGUA		8
75	J-40119143-6	INDUSTRIA CARNICA C.A.	INDUSTRIA CARNICA C.A.	02128687743	02124613785		AV. SIMON BOMIVAR EDIF. EL ATLANTICO PARTE NORTE PISO PB LOCAL GALPON INDUSTRIAL URB. ARTIGAS CARACAS		1
76	J-40917852-8	INVERSIONES CARNICOS MYS, C.A.	INVERSIONES CARNICOS MYS, C.A.	02432712110	04242099777		CALLE VENEZUELA LOCAL 178 SECTOR LA MORITA SANTA RITA EDO ARAGUA		1
78	J-87654321-9	DISTRIBUIDORES LA J, C.A.	DISTRIBUIDORES LA J, C.A.	0	0		MARACAY EDO. ARAGUA		1
79	J-12378954-8	ELIECER, C.A.	ELIECER, C.A.	0	0		MARACAY EDO. ARAGUA		1
80	J-12345600-0	POLLO GIGANTES C.A.	POLLO GIGANTES C.A.	0	0		MARACAY EDO ARAGUA		1
81	V-12582545-8	INVERSIONES Y SERVICIOS MIGUEL ANGEL FALCON " EL AZABACHE " FP	INVERSIONES Y SERVICIOS MIGUEL ANGEL FALCON " EL AZABACHE " FP	02438720109	04160418726		AV. 2DA. CASA N°. 79- SECTOR CARMEN FLORES SAN VICENTE - MARACAY - EDO- ARAGUA		1
82	J-30835432-5	EXTINTORES MEDANOS C.A.	EXTINTORES MEDANOS C.A.	02432710241	02432717897		CALLE EL CARMEN CASA N° 58 SECTOR LOS PROCERES SANTA RITA		3
83	V-15364136-2	EDUARDO ARCINIEGAS NIÑO	EDUARDO ARCINIEGAS NIÑO	0	0		AV. 4TA., CASA NRO. 77-1, URB. LA MARACAYA, MARACAY - EDO. ARAGUA		3
84	J-07531485-9	GOMATEC, C.A	GOMATEC, C.A	02432344254	0		AV. ARAGUA ESTE N° 21 SECTOR SAN IGNACIO MARACAY EDO-ARAGUA		3
85	E-82098831-3	ARTHUR GOLDSMIDT	ARTHUR GOLDSMIDT	04142487990	0		AV. ROMULO GALLEGOS- EDIF . CONJUNTO RESIDENCIAL CENTRO ALOA PISO 4 - OFIC C-42- URB EL MARQUES - EDO -  MIRANDA		2
77	J-40007492-4	DISTRIBUIDORA C.B.II, C.A.	DISTRIBUIDORA C.B.II, C.A.	04144572436	02432170666		CALLE JUNIN LOCAL N° 56, BARRIO LOURDES MARACAY EDO. ARAGUA		1
86	J-29618251-5	SOLTEC, C.A	SOLTEC, C.A	04124119724	0		LA VICTORIA ARAGUA		3
88	J-40258624-8	AGROALIMENTARIA VENEZUELA	AGROALIMENTARIA VENEZUELA	0	0		AV CUATRICENTENARIA (4 4 AV PREBO)  EDIF TORRE EJECUTIVA PISO 8 OF 8-2 URB EL PARRAL VALENCIA CARABOBO		1
89	J-07540453-0	RIMOCA INDUSTRIAL	RIMOCA INDUSTRIAL	02435536645	02435538159		ZONA INDUSTRIAL SAN VICENTE II CALLE E GALPONES 68 Y 69 MARACAY		3
90	V-12063233-3	BRICEÑO CARLOS ALBERTO, F.P.	BRICEÑO CARLOS ALBERTO, F.P.	02124821419	04143074360		AV. JOSE ANGEL LAMAS- LOCAL BUCARE ALTO - N° PB -3 URB. PALO GRANDE, C.C. CARACAS		3
91	J-29866536-0	METALMECANICA LA GIOIA C.A.	METALMECANICA LA GIOIA C.A.	02127437545	02123722334		CALLE PRINCIPAL CASA CAMPOBASSO, NRO S/N URB. LA CANDELARIA, SAN ANTONIO DE LOS ALTOS, ESTADO MIRANDA		3
92	J-19132888-0	MONTANO C.A.	MONTANO C.A.	0	0		MARACAY ARAGUA		1
93	J-31745773-0	CORMASTBAL C.A	CORMASTBAL C.A	02436727564	02436711736		CALLE A CUARTA TRANSVERSAL NRO. 74 URB MATA REDONDA MARACAY		3
94	J-40395428-3	NETVEN SISTEMAS INTEGRADOS C.A.	NETVEN SISTEMAS INTEGRADOS C.A.	04124197106	02449896024	sistemasintegradosnet.ven@gmail.com	AV 97 QTA. N 316 ZONA BELEN MARACAY EDO. ARAGUA		8
95	J-07560049-5	TECNO REFRIGERACION Y REBOBINADOS MC. S.A	TECNO REFRIGERACION Y REBOBINADOS MC. S.A	02435516259	02435516652	mc_ventas@empresamc.com	CALLE C, LOCAL GALPON N 26 ZONA INDUSTRIAL II SAN VICENTE		8
96	J-00004960-2	CALZADO FION C.A.	CALZADO FION C.A.	02414871711	0		VALENCIA ZONA INDUSTRIAL CASTILLITO , CALLE 98 N° 68-240		3
97	J-30451794-7	MANUFACTURAS WALITEX C.A.	MANUFACTURAS WALITEX C.A.	02418714941	02418716237		AV 70 MULTICENTRO DYH NIVEL PB LOCAL 6 Y 7 ZONA INDUSTRIAL CASTILLITO VALENCIA CARABOBO		3
98	J-00000000-0	SUMINISTROS DANIMEX	SUMINISTROS DANIMEX	0	0		MARACAY ARAGUA		2
99	J-40345092-7	DONFI, C.A.	DONFI, C.A.	02449717178	0		AV. 2-A, LOCAL PARCELA F3-F4 N 13, URB INDUSTRIAL, SANTA CRUZ EDO. ARAGUA		1
100	J-29966849-4	EL TRIFOLY, C.A.	EL TRIFOLY, C.A.	02123213118	04149896365		CALLE EL PUENTE, MACARENA SUR, GALPON 2, LOS TEQUES EDO. ARAGUA		1
101	J-30638673-4	CANER INDUSTRIAL C.A.	CANER INDUSTRIAL C.A.	02127511002	0		CENTRO CARONI, OFC. A- 23, AV CAURIMARE COLINAS DE BELLO MONTE, CARACAS VENEZUELA		2
\.


--
-- Data for Name: tm_req; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_req (id, cn_req, cdate, ccc_cia, ccc_dimension, cped_comp, cgerencia, cuso, csolicitado, crev_almacenp, caprob, corden_comp, crecepcion, cnx, cobservacion, cstatus, ct_servicio) FROM stdin;
1	0	2017-05-15			procarni	1	0	14183910	14183910	14183910	0	0	0		4	f
2	99	2017-06-01			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
4	120	2017-06-02			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
5	125	2017-06-02			PROCARNI	8	MANTENIMIENTO MECANICO	6	6	6	0	0	0		4	f
6	148	2017-06-06			PROCARNI	8	LPG	6	6	6	0	0	0		4	f
7	147	2017-06-06			PROCARNI	2	PLANTA	14183910	14183910	14183910	0	0	0		4	f
12	144	2017-06-07			PROCARNI	8		6	6	6	0	0	0		1	f
9	145	2017-06-07			PROCARNI	4		4	4	4	0	0	0		4	f
13	100000	2017-06-08			procarni	8		6	6	6	0	0	0		4	f
14	100001	2017-06-09			procarni	2		14183910	14183910	14183910	0	0	0		4	f
11	146	2017-06-07			PROCARNI	8	ALCANTARILLA	6	6	6	0	0	0		4	f
15	159	2017-06-14			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
25	100159	2017-06-14			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
26	10159	2017-06-14				4	LABORATORIO	4	4	4	0	0	0		4	f
27	166	2017-06-15			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
10	153	2017-06-07			PROCARNI	5	PLANTA	5	5	5	0	0	0		4	f
28	140	2017-06-15			PROCARNI	3	OFICINAS	3	3	3	0	0	0		4	f
3	114	2017-06-01			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
29	167	2017-06-16			PROCARNI	8	TIPPER TIE	6	6	6	0	0	0		4	f
30	172	2017-06-21			PROCARNI	2	canal	14183910	14183910	14183910	0	0	0		4	f
31	168	2017-06-21			procarni	8	cava de empaque	6	6	6	0	0	0		4	t
32	169	2017-06-22			PROCARNI	8	CAVA DE EMPAQUE	6	0	6	0	0	0		4	t
33	174	2017-06-23			PROCARNI	4	LABORATORIO	0	0	4	0	0	0		4	f
34	173	2017-06-23			PROCARNI	3	OFICINA	3	3	3	0	0	0		4	f
35	171	2017-06-23			PROCARNI	5	PLANTA	5	5	5	0	0	0		4	f
36	163	2017-06-23			PROCARNI	8	TALLER	6	6	6	0	0	0		4	f
37	160	2017-06-26			PROCARNI	8		6	6	6	0	0	0		4	f
38	175	2017-06-26			PROCARNI	1	DESPACHO	0	14183912	14183912	0	0	0		4	f
39	1006804	2017-06-26			procarni	1	compras	14183912	14183912	14183912	0	0	0		4	f
40	100771	2017-06-26			procarni	1		14183912	14183912	14183912	0	0	0		4	f
41	1008023	2017-06-26				1		0	14183912	14183912	0	0	0		4	f
42	176	2017-06-29			PROCARNI	4	LABORATORIO	4	4	4	0	0	0		4	f
43	178	2017-07-06			procarni	5	taller	5	5	5	0	0	0		4	f
44	10101	2017-07-06			procarni	8	repuestos	6	6	6	0	0	0		4	f
45	10102	2017-07-06			procarni	1	surtir	14183912	14183912	14183912	0	0	0		4	f
46	186	2017-07-07			PRICARNI	2	LIMPIEZA	14183910	14183910	14183910	0	0	0		4	f
47	187	2017-07-07			procarni	8	planta	6	6	6	0	0	0		4	f
48	188	2017-07-10				2	produccion	14183910	14183910	14183910	0	0	0		4	f
49	183	2017-07-10			procarni	5	planta	5	5	5	0	0	0		4	f
50	189	2017-07-11			procarni	4	laboratorio	4	4	4	0	0	0		4	f
51	1780	2017-07-11				8	calderas	6	6	6	0	0	0		4	f
52	154	2017-07-11				5	planta	5	5	5	0	0	0		4	f
53	190	2017-07-11			procarni	8	otro galpon	6	6	6	0	0	0		4	f
54	999111999	2017-07-13			procarni	8	mantenimiento	6	6	6	0	0	0		4	f
55	198	2017-07-17			procarni	2	LABORATORIO	14183910	14183910	14183910	0	0	0		4	f
61	1980	2017-07-18			PROCARNI	8	BOMBA DE POZO	6	6	6	0	0	0		4	f
62	199	2017-07-18			PROCARNI	8	BOMBA DE POZO	6	6	6	0	0	0		4	f
63	155	2017-07-20				5	planta	5	5	5	0	0	0		4	f
64	191	2017-07-20			procarni	5	planta	5	5	5	0	0	0		4	f
65	151	2017-07-20			procarni	5	empleados	5	5	5	0	0	0		4	f
66	206	2017-07-21			PROCARNI	2	BOMBA DE AGUA (TANQUE SUBTERRANEO)	14183910	14183910	14183910	0	0	0		4	f
67	201	2017-07-25			procarni	4	laboratorio	4	4	4	0	0	0		4	f
68	205	2017-07-25				8	taller	6	6	6	0	0	0		4	f
\.


--
-- Data for Name: tm_salida_inv; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_salida_inv (id, cconcepto, ctipo_almacen, codprod, cpreparado, caprobado, ca_cant, ctot, cfecha, calmacenp, cncontrol, cobservacion) FROM stdin;
42	produccion	1	900001	0	0	2	36905000	2017-05-21	0	100000	
43	produccion	2	900001	0	0	26	10881783.9959999993	2017-05-21	0	100001	
45	produccion	1	900001	0	0	9	25768900	2017-05-21	0	100002	
46	produccion	2	900001	0	0	3	600400	2017-05-21	0	100003	
47	produccion	2	900001	0	0	22	6527604.19999999832	2017-05-22	0	100004	
49	produccion	1	900001	0	0	8	47656400	2017-05-23	0	100006	
50	produccion	1	900001	0	0	4	15205150	2017-05-23	0	100008	
51	produccion	2	900001	0	0	21	6972663.79999999981	2017-05-24	0	100010	
52	produccion	1	900001	0	0	1	5086860	2017-05-24	0	100012	
53	produccion	1	900001	0	0	3	13926300	2017-05-24	0	100014	
54	produccion	2	900001	0	0	23	9071930.46999999881	2017-05-25	0	100015	
55	produccion	1	900001	14183910	14183910	5	23033400	2017-05-28	14183912	100018	
56	produccion	1	900001	14183910	14183910	2	6320810	2017-05-28	14183910	100019	
57	produccion	1	900001	14183910	14183910	1	1257900	2017-05-28	14183910	100021	
58	produccion	1	900001	14183910	14183910	6	21562250	2017-05-28	14183910	100023	
59	produccion	2	900001	14183910	14183910	25	11985941.0300000012	2017-05-28	14183910	100024	
60	produccion	2	900001	14183910	14183910	19	20699264.9400000013	2017-05-31	14183910	100026	
61	produccion	1	900001	19132888	19132888	8	11190250	2017-05-31	19132888	100028	
62	produccion	1	900001	19132888	19132888	4	6295940	2017-05-31	19132888	100029	
63	produccion	2	400002	19132888	4	4	2004910	2017-06-01	19132888	2	
64	produccion	2	400004	19132888	4	11	1990256.69999999995	2017-06-01	19132888	3	
65	produccion	2	400008	19132888	4	1	1240000	2017-06-01	19132888	4	
66	produccion	1	400002	19132888	4	5	10652700	2017-06-01	19132888	6	
67	produccion	1	400004	19132888	4	3	3652300	2017-06-01	19132888	7	
68	produccion	2	400014	19132888	4	18	5605778.49000000022	2017-06-01	19132888	8	
69	produccion	1	400014	19132888	4	2	6280400	2017-06-01	19132888	9	
70	produccion	2	400009	19132888	4	1	496000	2017-06-01	19132888	5	
71	produccion	2	400014	19132888	4	17	5449203.58000000007	2017-06-02	19132888	11	
72	produccion	2	400004	19132888	4	15	1003187.32499999995	2017-06-02	19132888	12	
73	produccion	2	400012	19132888	4	14	584057.412000000011	2017-06-02	19132888	13	
74	produccion	2	400011	19132888	4	15	1143891.30000000005	2017-06-02	19132888	14	
75	produccion	2	400003	19132888	4	17	1277910.47799999989	2017-06-02	19132888	15	
76	produccion	2	900001	19132888	4	3	829924210	2017-06-02	19132888	16	
77	produccion	1	400012	19132888	4	3	2254200	2017-06-02	19132888	17	
78	produccion	1	400011	20384856	4	5	4145800	2017-06-02	19132888	18	
79	produccion	1	400013	19132888	4	5	1748050	2017-06-02	19132888	19	
80	produccion	1	400014	19132888	4	2	4733500	2017-06-02	19132888	20	
81	produccion	1	400004	19132888	4	3	1808350	2017-06-02	19132888	21	
82	produccion	1	400003	19132888	3	3	1806650	2017-06-02	19132888	22	
88	produccion	1	400004	19132888	3	3	3970850	2017-06-02	3	31	
83	produccion	2	400014	19132888	3	17	6467288.85000000056	2017-06-02	19132888	26	
84	produccion	2	400004	19132888	3	15	2105058.41399999987	2017-06-02	19132888	27	
85	produccion	2	900001	19132888	3	5	950000	2017-06-02	19132888	28	
86	produccion	1	400013	19132888	3	5	1787900	2017-06-02	19132888	29	
87	produccion	1	400014	19132888	3	2	8784000	2017-06-02	19132888	30	
89	produccion	1	400012	19132888	4	3	2224150	2017-06-05	19132888	32	
90	produccion	1	400011	19132888	4	4	2310600	2017-06-05	19132888	33	
91	produccion	1	400014	19132888	4	2	6990750	2017-06-05	19132888	34	
92	produccion	2	400014	19132888	4	18	5602644.6400000006	2017-06-05	19132888	37	
93	produccion	2	400011	19132888	4	18	1727883.69999999995	2017-06-05	19132888	38	
94	produccion	2	400003	19132888	4	18	611631.119999999879	2017-06-05	19132888	39	
95	produccion	2	400012	19132888	4	15	585415.540000000037	2017-06-05	19132888	40	
110	produccion	1	400003	19132888	4	3	1829350	2017-06-08	19132888	35	
121	produccion	1	400002	19132888	4	4	6080200	2017-06-09	19132888	74	
128	produccion	2	400005	19132888	4	14	2070235.19999999995	2017-06-09	19132888	71	
129	produccion	2	400010	19132888	4	13	1887235.19999999995	2017-06-09	19132888	72	
130	produccion	2	400005	19132888	4	13	1173591.64000000013	2017-06-09	19132888	73	
131	produccion	2	400002	19132888	4	18	4463778.90000000037	2017-06-09	19132888	75	
132	produccion	2	900005	19132888	4	3	13027.5	2017-06-09	19132888	76	
111	produccion	1	400011	19132888	4	4	2164600	2017-06-06	19132888	47	
102	produccion	1	400011	19132888	4	3	2282300	2017-06-06	19132888	48	
103	produccion	1	400014	19132888	4	1	2435000	2017-06-06	19132888	49	
104	produccion	1	400018	19132888	4	1	4060000	2017-06-06	19132888	50	
113	produccion	1	400002	19132888	4	4	286000	2017-06-06	19132888	57	
114	produccion	1	400002	19132888	4	5	314900	2017-06-06	4	58	
109	produccion	2	900003	19132888	4	5	125640	2017-06-07	19132888	56	
115	produccion	1	400014	19132888	4	3	10441750	2017-06-07	19132888	59	
116	produccion	1	400002	19132888	4	4	3044500	2017-06-07	19132888	60	
117	produccion	1	400012	19132888	4	3	2351500	2017-06-07	19132888	61	
118	produccion	1	400011	19132888	4	4	2215250	2017-06-07	19132888	62	
119	produccion	1	400014	19132888	4	2	5972750	2017-06-08	19132888	63	
120	produccion	1	400002	19132888	4	5	6084950	2017-06-08	19132888	64	
122	produccion	2	400006	19132888	4	13	884013.93200000003	2017-06-08	19132888	65	
124	produccion	2	400002	19132888	4	18	5497034.40000000037	2017-06-08	19132888	67	
125	produccion	2	900004	19132888	4	7	402242.5	2017-06-08	19132888	68	
126	produccion	2	900003	19132888	4	2	63800	2017-06-08	19132888	69	
123	produccion	2	400014	19132888	4	19	3577018.54000000004	2017-06-08	19132888	66	
127	produccion	2	900001	19132888	4	5	1826220	2017-06-08	19132888	70	
105	produccion	2	400013	19132888	4	19	5741157.08000000007	2017-06-07	19132888	51	
106	produccion	2	400011	19132888	4	16	574813.150000000023	2017-06-07	19132888	52	
107	produccion	2	400012	19132888	4	14	584785.540000000037	2017-06-07	19132888	53	
108	produccion	2	400002	19132888	4	16	1747657.19999999995	2017-06-07	19132888	54	
96	produccion	2	400013	19132888	4	19	2467403.54000000004	2017-06-06	19132888	41	
97	produccion	2	400018	19132888	4	15	2812541	2017-06-06	19132888	42	
98	produccion	2	400012	19132888	4	14	584785.540000000037	2017-06-06	19132888	43	
99	produccion	2	400011	19132888	4	15	574556.900000000023	2017-06-06	19132888	44	
101	produccion	2	900001	19132888	4	2	615305	2017-06-06	19132888	46	
100	produccion	2	400002	19132888	4	16	421319.040000000037	2017-06-06	19132888	45	
134	produccion	2	400002	4	4	15	2300886.5	2017-06-12	4	79	
155	produccion	1	400004	4	4	3	1864150	2017-06-14	4	103	
156	produccion	1	400014	4	4	2	1861750	2017-06-14	4	104	
157	produccion	1	400012	4	4	3	2314400	2017-06-14	4	106	
158	produccion	2	400014	4	4	20	5823729.88999999966	2017-06-14	4	107	
159	produccion	2	400004	4	4	13	1247509.85000000009	2017-06-14	4	108	
160	produccion	2	400012	4	4	14	740389.825100000016	2017-06-14	4	109	
161	produccion	2	400010	4	4	13	2241613.52000000002	2017-06-14	4	110	
162	produccion	2	400006	4	4	13	950379.599999999977	2017-06-14	4	111	
163	produccion	2	900005	4	4	3	14507.5	2017-06-14	4	112	
164	produccion	2	900001	4	4	4	970300	2017-06-14	4	113	
165	produccion	2	400004	4	4	15	3812785.79999999981	2017-06-15	4	116	
166	produccion	2	400003	4	4	21	4325626.20000000019	2017-06-15	4	117	
167	produccion	2	900004	4	4	7	766437.5	2017-06-15	4	118	
168	produccion	2	400003	4	4	2	191400	2017-06-15	4	119	
169	produccion	1	400004	4	4	3	6463125	2017-06-15	4	114	
170	produccion	1	400003	4	4	2	2364300	2017-06-15	4	115	
133	produccion	2	400004	4	4	15	633186.699999999953	2017-06-12	4	77	
135	produccion	2	400018	4	4	15	3208377.89999999991	2017-06-12	4	81	
136	produccion	2	400011	4	4	16	701357.150000000023	2017-06-12	4	88	
137	produccion	2	400007	4	4	12	752106.969999999972	2017-06-12	4	89	
138	produccion	2	400013	4	4	18	2473237.08000000007	2017-06-12	4	90	
139	produccion	2	900001	4	4	9	5026553.75	2017-06-12	4	92	
140	produccion	1	400011	4	4	4	2117000	2017-06-12	4	82	
141	produccion	1	400018	4	4	1	4400000	2017-06-12	4	83	
142	produccion	1	400013	4	4	4	1397600	2017-06-12	4	84	
143	produccion	1	400004	4	4	3	3984650	2017-06-12	4	85	
144	produccion	1	400014	4	4	2	1183500	2017-06-12	4	86	
145	produccion	1	400002	4	4	3	2827700	2017-06-12	4	87	
146	produccion	1	400018	4	4	1	1411200	2017-06-12	4	93	
147	produccion	1	400014	4	4	2	48500	2017-06-13	4	94	
148	produccion	1	400002	4	4	3	156500	2017-06-13	4	95	
149	produccion	2	400014	4	4	19	1936734.1399999999	2017-06-13	4	97	
150	produccion	2	400011	4	4	16	744882.986499999999	2017-06-13	4	99	
151	produccion	2	400002	4	4	18	3502675.79999999981	2017-06-13	4	98	
152	produccion	2	400005	4	4	12	971410.222000000067	2017-06-13	4	102	
153	produccion	2	400006	4	4	12	1881647.52000000002	2017-06-13	4	101	
154	produccion	1	400011	19132888	4	5	2174250	2017-06-13	19132888	96	
171	produccion	2	400013	4	4	19	7404165.18250000011	2017-06-16	4	120	
172	produccion	2	400004	4	4	16	2545746.70000000019	2017-06-16	4	121	
173	produccion	2	400018	4	4	15	1515823.93999999994	2017-06-16	4	122	
174	produccion	2	400012	4	4	13	698945.540000000037	2017-06-16	4	128	
175	produccion	2	400004	4	4	8	830237.5	2017-06-16	4	129	
176	produccion	2	900001	4	4	4	115181.029500000004	2017-06-16	4	130	
178	produccion	1	400004	4	4	3	3226800	2017-06-16	4	126	
179	produccion	1	400018	4	4	1	2200000	2017-06-16	4	127	
177	produccion	1	400014	4	4	3	53600	2017-06-16	4	125	
182	produccion	1	400014	19132888	4	3	7466500	2017-06-16	19132888	124	
183	produccion	2	400001	4	4	17	2977048.20000000019	2017-06-19	4	132	
184	produccion	2	400011	4	4	16	705046.900000000023	2017-06-19	4	133	
185	produccion	2	400012	4	4	14	872105.540000000037	2017-06-19	4	134	
186	produccion	2	900003	4	4	3	128400	2017-06-19	4	135	
187	produccion	1	400011	4	4	4	1764000	2017-06-19	4	136	
188	produccion	1	400012	4	4	3	1964900	2017-06-19	4	137	
189	produccion	1	900001	4	4	4	2865000	2017-06-19	4	138	
190	produccion	2	900001	4	4	3	985501.059000000008	2017-06-19	4	139	
191	produccion	1	400002	4	4	4	5738750	2017-06-20	4	140	
192	produccion	1	400014	4	4	2	8110000	2017-06-20	4	141	
193	produccion	2	400014	4	4	19	2405519.45000000019	2017-06-20	4	142	
194	produccion	2	400002	4	4	16	1978091.60000000009	2017-06-20	4	143	
195	produccion	2	400005	4	4	11	1146345	2017-06-20	4	144	
196	produccion	2	900001	4	4	5	35465	2017-06-20	4	145	
197	produccion	2	400003	4	4	15	1871949.85000000009	2017-06-21	4	150	
198	produccion	2	400018	4	4	12	1707806.85000000009	2017-06-21	4	151	
199	produccion	2	400014	4	4	19	3783035.39199999999	2017-06-21	4	152	
200	produccion	2	900001	4	4	7	3904481.5	2017-06-21	4	154	
201	produccion	2	400005	4	4	3	36879.5	2017-06-21	4	155	
203	produccion	2	400002	4	4	16	6053035.40000000037	2017-06-21	4	153	
208	produccion	1	400003	19132888	4	2	1790900	2017-06-21	19132888	149	
207	produccion	1	400002	19132888	4	4	7299500	2017-06-21	19132888	148	
206	produccion	1	400018	19132888	4	1	2000000	2017-06-21	19132888	147	
205	produccion	1	400014	19132888	4	2	5430000	2017-06-21	19132888	146	
209	produccion	2	900004	19132888	4	7	715180	2017-06-21	19132888	156	
210	produccion	2	400013	4	4	17	2565548.5	2017-06-22	4	157	
211	produccion	2	400002	4	4	14	1938927.69999999995	2017-06-22	4	158	
212	produccion	2	400002	4	4	14	1193288.85000000009	2017-06-22	4	159	
213	produccion	2	900001	4	4	3	402522	2017-06-22	4	160	
214	produccion	1	400013	4	4	4	4015600	2017-06-22	4	162	
215	produccion	1	400001	4	4	4	4058500	2017-06-22	4	161	
216	produccion	2	400013	4	4	19	5674409	2017-06-23	4	165	
217	produccion	2	900001	4	4	4	129207.5	2017-06-23	4	167	
218	produccion	1	400002	4	4	3	6511950	2017-06-23	4	163	
219	produccion	1	400015	4	4	2	5902000	2017-06-23	4	164	
220	produccion	2	400002	4	4	17	5752138	2017-06-23	4	166	
221	produccion	2	400014	4	4	19	1961306.29000000004	2017-06-26	4	169	
222	produccion	2	400003	4	4	18	2005911.35999999987	2017-06-26	4	170	
223	produccion	2	400002	4	4	17	5624065.40000000037	2017-06-26	4	172	
224	produccion	2	400011	4	4	16	960389.360499999952	2017-06-26	4	173	
225	produccion	2	400012	4	4	14	913605.540000000037	2017-06-26	4	174	
226	produccion	2	900001	4	4	2	493010	2017-06-26	4	175	
227	produccion	1	400012	4	4	4	2319450	2017-06-26	4	176	
231	produccion	1	400012	4	4	3	2539200	2017-06-26	4	178	
233	produccion	1	400003	4	4	2	2956500	2017-06-26	4	179	
234	produccion	1	400002	4	4	3	7576250	2017-06-26	4	180	
235	produccion	1	400001	4	4	3	3119500	2017-06-29	4	182	
236	produccion	2	400001	4	4	19	2799677.89999999991	2017-06-29	4	183	
237	produccion	2	400003	4	4	4	150400	2017-06-29	4	184	
238	produccion	2	900001	4	4	5	1033010	2017-06-29	4	185	
239	produccion	2	400013	4	4	20	10039712	2017-07-03	4	189	
240	produccion	2	400002	4	4	16	2394512.179	2017-07-03	4	190	
241	produccion	2	900005	4	4	3	12707.5	2017-07-03	4	191	
242	produccion	2	400013	4	4	21	7484600.70529999956	2017-07-04	4	201	
243	produccion	2	400014	4	4	20	6067777.34999999963	2017-07-04	4	202	
244	produccion	2	400005	4	4	14	1528606.19999999995	2017-07-04	4	203	
245	produccion	2	400003	4	4	19	2094500.80000000005	2017-07-04	4	204	
246	produccion	2	400012	4	4	14	587529.540000000037	2017-07-04	4	205	
247	produccion	2	400011	4	4	16	496896.900000000023	2017-07-04	4	206	
248	produccion	2	400002	4	4	16	4825062.0820000004	2017-07-04	4	207	
249	produccion	1	400012	4	4	3	2907300	2017-07-04	4	192	
250	produccion	1	400011	4	4	4	2799150	2017-07-04	4	193	
251	produccion	1	400002	4	4	6	13830250	2017-07-04	4	194	
252	produccion	1	400013	4	4	4	8319900	2017-07-04	4	195	
253	produccion	1	400014	4	4	3	5496500	2017-07-04	4	196	
254	produccion	1	400003	4	4	2	1031500	2017-07-04	4	197	
255	produccion	1	900001	4	4	2	2321200	2017-07-04	4	198	
256	produccion	2	900001	4	4	6	133462	2017-07-04	4	199	
257	produccion	2	900003	4	4	3	130800	2017-07-04	4	200	
258	produccion	2	400005	4	4	12	2900246.33999999985	2017-07-06	4	208	
259	produccion	2	400008	4	4	12	1407865.85000000009	2017-07-06	4	209	
260	produccion	2	400009	4	4	11	1934827.69999999995	2017-07-06	4	210	
261	produccion	2	400013	4	4	20	6792924.77999999933	2017-07-06	4	211	
262	produccion	2	900004	4	4	3	24800	2017-07-06	4	212	
263	produccion	2	900001	4	4	5	219509	2017-07-06	4	213	
264	produccion	2	400002	4	4	14	6540734.31599999964	2017-07-06	4	215	
265	produccion	2	400013	4	4	20	11649778.75	2017-07-06	4	216	
266	produccion	2	400018	4	4	16	2177280	2017-07-06	4	217	
267	produccion	2	900005	4	19132888	3	37007.5	2017-07-06	4	218	
268	produccion	1	400013	19132888	4	4	4142000	2017-07-07	19132888	219	
269	produccion	1	400014	19132888	4	4	14355060	2017-07-07	19132888	221	
270	produccion	1	400018	19132888	4	1	5396850	2017-07-07	19132888	222	
271	produccion	1	400002	19132888	4	4	12444150	2017-07-07	19132888	223	
272	produccion	2	400003	4	4	18	2310492.304	2017-07-07	4	226	
273	produccion	2	400002	4	4	17	8637729.41600000113	2017-07-07	4	225	
274	produccion	2	900003	4	4	2	63800	2017-07-07	4	227	
275	produccion	2	900001	4	4	7	1009829	2017-07-07	4	228	
276	produccion	1	400003	4	4	3	2673400	2017-07-07	4	229	
277	produccion	1	400002	4	4	5	11809200	2017-07-07	4	230	
280	produccion	2	400014	4	4	19	11901563.9199999999	2017-07-10	4	231	
281	produccion	2	400002	4	4	17	7405063.61199999973	2017-07-10	4	232	
282	produccion	2	400006	4	4	12	1282779.60000000009	2017-07-10	4	233	
283	produccion	2	400009	4	4	12	1268507.60000000009	2017-07-10	4	234	
284	produccion	2	400003	4	4	18	2209218.71999999974	2017-07-10	4	235	
285	produccion	2	900003	4	4	4	113400	2017-07-10	4	236	
286	produccion	2	900001	4	4	3	742834	2017-07-10	4	237	
287	produccion	2	900001	4	4	4	31447.25	2017-07-10	4	238	
288	produccion	2	900005	4	4	4	211415	2017-07-10	4	239	
289	produccion	1	900001	19132888	19132888	13	56055050	2017-07-10	19132888	244	
296	produccion	2	400014	4	4	19	12003357.5199999996	2017-07-12	4	257	
297	produccion	2	400002	4	4	16	4397394	2017-07-12	4	258	
298	produccion	2	400003	4	4	19	1772118.10000000009	2017-07-12	4	260	
299	produccion	2	400018	4	4	15	1784779.76000000001	2017-07-12	4	262	
300	produccion	2	900001	4	4	6	889931.059000000008	2017-07-12	4	263	
301	produccion	2	900001	4	4	5	35551.25	2017-07-12	4	264	
290	produccion	2	400002	19132888	19132888	15	6385564	2017-07-11	19132888	251	
291	produccion	1	900001	19132888	19132888	9	19316950	2017-07-11	19132888	249	
292	produccion	2	400014	19132888	19132888	19	10520299.8731999993	2017-07-11	19132888	252	
293	produccion	2	900001	19132888	19132888	4	1489100	2017-07-11	19132888	253	
294	produccion	2	900001	19132888	19132888	5	35551.25	2017-07-11	19132888	254	
295	produccion	2	900005	19132888	19132888	4	105707.5	2017-07-11	19132888	255	
302	produccion	1	900001	19132888	19132888	8	32945250	2017-07-13	19132888	250	
303	produccion	2	400003	19132888	19132888	21	2882393.71799999988	2017-07-13	19132888	266	
304	produccion	2	900001	19132888	19132888	4	105707.5	2017-07-13	19132888	267	
305	produccion	2	400014	19132888	19132888	19	15293699.5600000005	2017-07-13	19132888	265	
306	produccion	1	900001	19132888	19132888	9	22114350	2017-07-13	19132888	268	
307	produccion	2	400014	19132888	19132888	20	11021239.2919999994	2017-07-13	19132888	269	
308	produccion	1	900001	19132888	19132888	2	14524600	2017-07-13	19132888	270	
310	produccion	2	400013	4	4	19	4557332.16999999993	2017-07-17	4	272	
311	produccion	2	900001	4	4	8	1432058.75	2017-07-17	4	273	
312	produccion	1	900001	4	4	6	33456600	2017-07-17	4	274	
313	produccion	2	400001	4	4	17	6211516.26999999955	2017-07-18	4	275	
314	produccion	2	400013	4	4	18	2992295.95000000019	2017-07-18	4	276	
315	produccion	2	900001	4	4	4	100345	2017-07-18	4	277	
316	produccion	2	400013	4	4	21	12640969.2659999989	2017-07-19	4	278	
317	produccion	2	400002	4	4	16	7949585.07940000016	2017-07-19	4	280	
318	produccion	2	900001	4	4	3	7220	2017-07-19	4	281	
320	produccion	1	900001	19132888	19132888	10	24304300	2017-07-19	19132888	282	
319	produccion	1	900001	19132888	19132888	6	16054120	2017-07-18	19132888	283	
321	produccion	2	400014	4	4	19	12284546.5599999987	2017-07-20	4	284	
322	produccion	2	400006	4	4	14	1582720.60000000009	2017-07-20	4	285	
323	produccion	2	900001	4	4	3	1178062.5	2017-07-20	4	286	
279	produccion	1	900001	19132888	4	4	511450	2017-07-07	19132888	9003	
309	produccion	1	900001	19132888	19132888	1	14000000	2017-07-17	19132888	9004	
324	produccion	2	400008	4	4	13	1430120.60000000009	2017-07-20	4	288	
325	produccion	1	900001	19132888	19132888	11	27589600	2017-07-20	19132888	289	
326	produccion	2	400013	4	4	21	7823711.78000000026	2017-07-21	4	290	
327	produccion	2	900005	4	4	4	108462.5	2017-07-21	4	291	
328	produccion	1	900001	19132888	19132888	4	7745250	2017-07-21	19132888	292	
204	produccion	1	900006	19132888	4	1	1063800	2017-06-22	19132888	1	
278	produccion	1	900002	19132888	4	1	22078560	2017-07-07	19132888	9002	
329	produccion	2	900001	19132888	19132888	1	8000	2017-07-21	19132888	9005	SALIDA FINCA
330	produccion	2	900001	19132888	19132888	1	70000	2017-07-21	19132888	9006	RESTAURANTE - FRANKLIN
331	produccion	2	900001	19132888	19132888	1	28000	2017-07-25	19132888	9007	RESTAURANTE - FREDDY
332	produccion	2	400011	4	4	16	417906.900000000023	2017-07-25	4	293	
333	produccion	2	400012	4	4	14	447266.539999999979	2017-07-25	4	295	
334	produccion	2	400018	4	4	16	961553.5	2017-07-25	4	296	
336	produccion	2	900001	4	4	8	633580	2017-07-25	4	298	
337	produccion	2	900001	19132888	19132888	2	3050000	2017-07-25	19132888	9008	
338	produccion	1	900001	19132888	19132888	8	17799800	2017-07-25	19132888	300	
335	produccion	2	400004	4	4	16	3452939.5	2017-07-25	4	299	
339	produccion	2	400004	19132888	19132888	17	33214296.75	2017-07-26	19132888	301	
340	produccion	2	400018	19132888	19132888	17	1785816.05899999989	2017-07-26	19132888	303	
341	produccion	2	400015	19132888	19132888	15	711490.349999999977	2017-07-26	19132888	304	
342	produccion	1	900001	19132888	19132888	6	17062250	2017-07-26	19132888	305	
\.


--
-- Data for Name: tm_salidam; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY tm_salidam (id, ccodsalida, cfecha, corigen, cdestino, cfecha_ret, cconcepto, ctot_cant, ctot_uni, cdp_emp, cdp_ci, cdp_nombre, cdp_empresa, cdp_tel_contac, cdp_prep, cdp_aprob, cconcepto_desc) FROM stdin;
\.


--
-- Data for Name: ttipo_almacen; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY ttipo_almacen (ctipoalmacen, cdescripcion, cdesc_cort) FROM stdin;
1	Materia Prima (ALMP)	ALMP
2	Materia Seca (ALMS)	ALMS
3	Materiales y Repuestos (ALMR)	ALMR
4	Producto Terminado	ALPT
8	Servicios	SERV
\.


--
-- Data for Name: ttipo_producto; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY ttipo_producto (id, ctipoprod, cdescripcion) FROM stdin;
\.


--
-- Data for Name: ttipo_salida; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY ttipo_salida (cconcepto, cdescripcion) FROM stdin;
\.


--
-- Data for Name: usr_log; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY usr_log (cci, cpass, cd_upd, cd_change) FROM stdin;
20384856	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	2017-05-30	\N
19132888	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855	2017-05-28	\N
\.


--
-- Data for Name: usr_menu; Type: TABLE DATA; Schema: public; Owner: joec
--

COPY usr_menu (id, cusr, cid_m, cid_d) FROM stdin;
4	20384856	1	1
5	20384856	1	2
6	20384856	2	3
7	20384856	2	4
8	20384856	3	5
9	20384856	3	6
14	20384856	7	16
13	20384856	7	15
12	20384856	6	14
11	20384856	6	13
10	20384856	5	0
15	19132888	1	1
16	19132888	1	2
17	19132888	2	3
18	19132888	2	4
19	19132888	3	5
20	19132888	3	6
21	19132888	5	0
22	19132888	6	13
23	19132888	6	14
24	19132888	7	15
25	19132888	7	16
26	19132888	8	17
27	19132888	8	18
28	19132888	9	10
29	19132888	9	11
30	19132888	9	12
\.


--
-- Name: md_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY md_menu
    ADD CONSTRAINT md_menu_pkey PRIMARY KEY (id);


--
-- Name: mm_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY mm_menu
    ADD CONSTRAINT mm_menu_pkey PRIMARY KEY (id);


--
-- Name: t_banco_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_banco
    ADD CONSTRAINT t_banco_pkey PRIMARY KEY (id);


--
-- Name: t_cargo_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_cargo
    ADD CONSTRAINT t_cargo_pkey PRIMARY KEY (id);


--
-- Name: t_conceptopago_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_conceptopago
    ADD CONSTRAINT t_conceptopago_pkey PRIMARY KEY (id);


--
-- Name: t_empleados_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_empleados
    ADD CONSTRAINT t_empleados_pkey PRIMARY KEY (cci);


--
-- Name: t_group_cargo_cdescripcion_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_group_cargo
    ADD CONSTRAINT t_group_cargo_cdescripcion_key UNIQUE (cdescripcion);


--
-- Name: t_group_cargo_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_group_cargo
    ADD CONSTRAINT t_group_cargo_pkey PRIMARY KEY (id);


--
-- Name: t_observacion_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_pago
    ADD CONSTRAINT t_observacion_pkey PRIMARY KEY (id);


--
-- Name: t_status_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY t_status
    ADD CONSTRAINT t_status_pkey PRIMARY KEY (id);


--
-- Name: td_controlpago_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_controlpago
    ADD CONSTRAINT td_controlpago_pkey PRIMARY KEY (id);


--
-- Name: td_entrada_inv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_entrada_inv
    ADD CONSTRAINT td_entrada_inv_pkey PRIMARY KEY (id);


--
-- Name: td_factura_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_factura
    ADD CONSTRAINT td_factura_pkey PRIMARY KEY (id);


--
-- Name: td_factura_serv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_factura_serv
    ADD CONSTRAINT td_factura_serv_pkey PRIMARY KEY (id);


--
-- Name: td_ordencompra_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_ordencompra
    ADD CONSTRAINT td_ordencompra_pkey PRIMARY KEY (id);


--
-- Name: td_req_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_req
    ADD CONSTRAINT td_req_pkey PRIMARY KEY (id);


--
-- Name: td_req_serv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_req_serv
    ADD CONSTRAINT td_req_serv_pkey PRIMARY KEY (id);


--
-- Name: td_salida_inv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY td_salida_inv
    ADD CONSTRAINT td_salida_inv_pkey PRIMARY KEY (id);


--
-- Name: tm_controlpago_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_controlpago
    ADD CONSTRAINT tm_controlpago_pkey PRIMARY KEY (id);


--
-- Name: tm_entrada_inv_cncontrol_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_entrada_inv
    ADD CONSTRAINT tm_entrada_inv_cncontrol_key UNIQUE (cncontrol);


--
-- Name: tm_entrada_inv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_entrada_inv
    ADD CONSTRAINT tm_entrada_inv_pkey PRIMARY KEY (id);


--
-- Name: tm_factura_ccodfact_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_factura
    ADD CONSTRAINT tm_factura_ccodfact_key UNIQUE (ccodfact);


--
-- Name: tm_factura_dir_ccodfact_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_factura_dir
    ADD CONSTRAINT tm_factura_dir_ccodfact_key UNIQUE (ccodfact);


--
-- Name: tm_factura_dir_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_factura_dir
    ADD CONSTRAINT tm_factura_dir_pkey PRIMARY KEY (id);


--
-- Name: tm_factura_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_factura
    ADD CONSTRAINT tm_factura_pkey PRIMARY KEY (id);


--
-- Name: tm_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_inventario
    ADD CONSTRAINT tm_inventario_pkey PRIMARY KEY (id);


--
-- Name: tm_invstock_ccodprod_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_invstock
    ADD CONSTRAINT tm_invstock_ccodprod_key UNIQUE (ccodprod);


--
-- Name: tm_invstock_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_invstock
    ADD CONSTRAINT tm_invstock_pkey PRIMARY KEY (id);


--
-- Name: tm_ordencompra_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_ordencompra
    ADD CONSTRAINT tm_ordencompra_pkey PRIMARY KEY (id);


--
-- Name: tm_producto_fin_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_producto_fin
    ADD CONSTRAINT tm_producto_fin_pkey PRIMARY KEY (codprodt);


--
-- Name: tm_producto_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_producto
    ADD CONSTRAINT tm_producto_pkey PRIMARY KEY (codprod);


--
-- Name: tm_proveedor_crif_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_proveedor
    ADD CONSTRAINT tm_proveedor_crif_key UNIQUE (crif);


--
-- Name: tm_proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_proveedor
    ADD CONSTRAINT tm_proveedor_pkey PRIMARY KEY (id);


--
-- Name: tm_req_cn_req_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_cn_req_key UNIQUE (cn_req);


--
-- Name: tm_req_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_pkey PRIMARY KEY (id);


--
-- Name: tm_salida_inv_cncontrol_key; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_salida_inv
    ADD CONSTRAINT tm_salida_inv_cncontrol_key UNIQUE (cncontrol);


--
-- Name: tm_salida_inv_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY tm_salida_inv
    ADD CONSTRAINT tm_salida_inv_pkey PRIMARY KEY (id);


--
-- Name: ttipo_almacen_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY ttipo_almacen
    ADD CONSTRAINT ttipo_almacen_pkey PRIMARY KEY (ctipoalmacen);


--
-- Name: usr_log_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY usr_log
    ADD CONSTRAINT usr_log_pkey PRIMARY KEY (cci);


--
-- Name: usr_menu_pkey; Type: CONSTRAINT; Schema: public; Owner: joec; Tablespace: 
--

ALTER TABLE ONLY usr_menu
    ADD CONSTRAINT usr_menu_pkey PRIMARY KEY (id);


--
-- Name: _RETURN; Type: RULE; Schema: public; Owner: joec
--

CREATE RULE "_RETURN" AS
    ON SELECT TO dbv_sideb_men_mid DO INSTEAD  SELECT usr.cusr,
    m.id AS menid,
    m.cm_level,
    m.cm_sub,
    ((((((((((((((((((((('<li class="'::text || (m.cm_head_c)::text) || '">'::text) || '<a href="'::text) || (m.cm_head_p)::text) || '">'::text) || '<i class="'::text) || (m.cm_head_i)::text) || '"></i>'::text) || '<span>'::text) || (m.cm_title)::text) || '</span>'::text) || '<span class="'::text) || (m.cm_t_sc)::text) || '">'::text) || '<i class="'::text) || (m.cm_t_ic)::text) || '"></i></span></a><ul class="'::text) || (m.cm_op_c)::text) || '" id="op_'::text) || m.id) || '">'::text) AS head,
    '</ul></li>' AS fin
   FROM (usr_menu usr
     JOIN mm_menu m ON ((usr.cid_m = m.id)))
  GROUP BY usr.cusr, m.id
  ORDER BY m.id;


--
-- Name: entrada_inv_d; Type: TRIGGER; Schema: public; Owner: joec
--

CREATE TRIGGER entrada_inv_d AFTER INSERT ON td_entrada_inv FOR EACH ROW EXECUTE PROCEDURE td_entrada_inv_d();


--
-- Name: oc_after_upd_1; Type: TRIGGER; Schema: public; Owner: joec
--

CREATE TRIGGER oc_after_upd_1 AFTER UPDATE ON tm_ordencompra FOR EACH ROW EXECUTE PROCEDURE upd_status_oc();


--
-- Name: salida_inv_d; Type: TRIGGER; Schema: public; Owner: joec
--

CREATE TRIGGER salida_inv_d AFTER INSERT ON td_salida_inv FOR EACH ROW EXECUTE PROCEDURE td_salida_inv_d();


--
-- Name: test_trigger; Type: TRIGGER; Schema: public; Owner: joec
--

CREATE TRIGGER test_trigger AFTER INSERT ON td_factura FOR EACH ROW EXECUTE PROCEDURE test_fact();

ALTER TABLE td_factura DISABLE TRIGGER test_trigger;


--
-- Name: test_trigger; Type: TRIGGER; Schema: public; Owner: joec
--

CREATE TRIGGER test_trigger AFTER UPDATE ON tm_factura FOR EACH ROW EXECUTE PROCEDURE fnc_reg_factm_1();


--
-- Name: md_menu_cid_m_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY md_menu
    ADD CONSTRAINT md_menu_cid_m_fkey FOREIGN KEY (cid_m) REFERENCES mm_menu(id);


--
-- Name: td_controlpago_cbanco_des_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_controlpago
    ADD CONSTRAINT td_controlpago_cbanco_des_fkey FOREIGN KEY (cbanco_des) REFERENCES t_banco(id);


--
-- Name: td_controlpago_cbanco_emi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_controlpago
    ADD CONSTRAINT td_controlpago_cbanco_emi_fkey FOREIGN KEY (cbanco_emi) REFERENCES t_banco(id);


--
-- Name: td_controlpago_cconcepto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_controlpago
    ADD CONSTRAINT td_controlpago_cconcepto_fkey FOREIGN KEY (cconcepto) REFERENCES t_conceptopago(id);


--
-- Name: td_controlpago_codcpm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_controlpago
    ADD CONSTRAINT td_controlpago_codcpm_fkey FOREIGN KEY (codcpm) REFERENCES tm_controlpago(id);


--
-- Name: td_entrada_inv_cidm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_entrada_inv
    ADD CONSTRAINT td_entrada_inv_cidm_fkey FOREIGN KEY (cidm) REFERENCES tm_entrada_inv(id);


--
-- Name: td_factura_cstatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_factura
    ADD CONSTRAINT td_factura_cstatus_fkey FOREIGN KEY (cstatus) REFERENCES t_status(id);


--
-- Name: td_factura_serv_cstatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_factura_serv
    ADD CONSTRAINT td_factura_serv_cstatus_fkey FOREIGN KEY (cstatus) REFERENCES t_status(id);


--
-- Name: td_ordencompra_cnorden_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_ordencompra
    ADD CONSTRAINT td_ordencompra_cnorden_fkey FOREIGN KEY (cnorden) REFERENCES tm_ordencompra(id) ON DELETE CASCADE;


--
-- Name: td_req_ccodprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_req
    ADD CONSTRAINT td_req_ccodprod_fkey FOREIGN KEY (ccodprod) REFERENCES tm_producto(codprod);


--
-- Name: td_req_ccodprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_req_serv
    ADD CONSTRAINT td_req_ccodprod_fkey FOREIGN KEY (ccodprod) REFERENCES tm_producto(codprod);


--
-- Name: td_req_cn_req_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_req
    ADD CONSTRAINT td_req_cn_req_fkey FOREIGN KEY (cn_req) REFERENCES tm_req(cn_req) ON DELETE CASCADE;


--
-- Name: td_req_cn_req_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_req_serv
    ADD CONSTRAINT td_req_cn_req_fkey FOREIGN KEY (cn_req) REFERENCES tm_req(cn_req) ON DELETE CASCADE;


--
-- Name: td_salida_inv_cidm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY td_salida_inv
    ADD CONSTRAINT td_salida_inv_cidm_fkey FOREIGN KEY (cidm) REFERENCES tm_salida_inv(id);


--
-- Name: tm_controlpago_ccodprov_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_controlpago
    ADD CONSTRAINT tm_controlpago_ccodprov_fkey FOREIGN KEY (ccodprov) REFERENCES tm_proveedor(id);


--
-- Name: tm_entrada_inv_codprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_entrada_inv
    ADD CONSTRAINT tm_entrada_inv_codprod_fkey FOREIGN KEY (codprod) REFERENCES tm_producto(codprod);


--
-- Name: tm_entrada_inv_ctipo_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_entrada_inv
    ADD CONSTRAINT tm_entrada_inv_ctipo_almacen_fkey FOREIGN KEY (ctipo_almacen) REFERENCES ttipo_almacen(ctipoalmacen);


--
-- Name: tm_factura_cproveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_factura
    ADD CONSTRAINT tm_factura_cproveedor_fkey FOREIGN KEY (cproveedor) REFERENCES tm_proveedor(id);


--
-- Name: tm_factura_dir_cproveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_factura_dir
    ADD CONSTRAINT tm_factura_dir_cproveedor_fkey FOREIGN KEY (cproveedor) REFERENCES tm_proveedor(id);


--
-- Name: tm_inventario_cid_fact_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_inventario
    ADD CONSTRAINT tm_inventario_cid_fact_fkey FOREIGN KEY (cid_fact) REFERENCES tm_factura(id);


--
-- Name: tm_inventario_codprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_inventario
    ADD CONSTRAINT tm_inventario_codprod_fkey FOREIGN KEY (codprod) REFERENCES tm_producto(codprod);


--
-- Name: tm_invstock_ccodprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_invstock
    ADD CONSTRAINT tm_invstock_ccodprod_fkey FOREIGN KEY (ccodprod) REFERENCES tm_producto(codprod);


--
-- Name: tm_invstock_ctipo_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_invstock
    ADD CONSTRAINT tm_invstock_ctipo_almacen_fkey FOREIGN KEY (ctipo_almacen) REFERENCES ttipo_almacen(ctipoalmacen);


--
-- Name: tm_ordencompra_cn_req_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_ordencompra
    ADD CONSTRAINT tm_ordencompra_cn_req_fkey FOREIGN KEY (cn_req) REFERENCES tm_req(cn_req);


--
-- Name: tm_ordencompra_csolicitado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_ordencompra
    ADD CONSTRAINT tm_ordencompra_csolicitado_fkey FOREIGN KEY (csolicitado) REFERENCES t_empleados(cci) ON UPDATE CASCADE;


--
-- Name: tm_ordencompra_cstatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_ordencompra
    ADD CONSTRAINT tm_ordencompra_cstatus_fkey FOREIGN KEY (cstatus) REFERENCES t_status(id);


--
-- Name: tm_producto_ctipoalmacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_producto
    ADD CONSTRAINT tm_producto_ctipoalmacen_fkey FOREIGN KEY (ctipoalmacen) REFERENCES ttipo_almacen(ctipoalmacen);


--
-- Name: tm_req_caprob_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_caprob_fkey FOREIGN KEY (caprob) REFERENCES t_empleados(cci);


--
-- Name: tm_req_crev_almacenp_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_crev_almacenp_fkey FOREIGN KEY (crev_almacenp) REFERENCES t_empleados(cci);


--
-- Name: tm_req_csolicitado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_csolicitado_fkey FOREIGN KEY (csolicitado) REFERENCES t_empleados(cci);


--
-- Name: tm_req_cstatus_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_req
    ADD CONSTRAINT tm_req_cstatus_fkey FOREIGN KEY (cstatus) REFERENCES t_status(id);


--
-- Name: tm_salida_inv_codprod_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_salida_inv
    ADD CONSTRAINT tm_salida_inv_codprod_fkey FOREIGN KEY (codprod) REFERENCES tm_producto(codprod);


--
-- Name: tm_salida_inv_ctipo_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY tm_salida_inv
    ADD CONSTRAINT tm_salida_inv_ctipo_almacen_fkey FOREIGN KEY (ctipo_almacen) REFERENCES ttipo_almacen(ctipoalmacen);


--
-- Name: usr_menu_cid_d_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY usr_menu
    ADD CONSTRAINT usr_menu_cid_d_fkey FOREIGN KEY (cid_d) REFERENCES md_menu(id);


--
-- Name: usr_menu_cid_m_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY usr_menu
    ADD CONSTRAINT usr_menu_cid_m_fkey FOREIGN KEY (cid_m) REFERENCES mm_menu(id);


--
-- Name: usr_menu_cusr_fkey; Type: FK CONSTRAINT; Schema: public; Owner: joec
--

ALTER TABLE ONLY usr_menu
    ADD CONSTRAINT usr_menu_cusr_fkey FOREIGN KEY (cusr) REFERENCES t_empleados(cci);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

