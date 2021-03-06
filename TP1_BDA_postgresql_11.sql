PGDMP                         w            TP1_BDA    11.2    11.2 i    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    24576    TP1_BDA    DATABASE     �   CREATE DATABASE "TP1_BDA" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Spain.1252' LC_CTYPE = 'Spanish_Spain.1252';
    DROP DATABASE "TP1_BDA";
             postgres    false            �            1255    25013    fx_adherente_disjunto()    FUNCTION     �   CREATE FUNCTION public.fx_adherente_disjunto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if exists(select DNI from Titular where DNI = new.DNI) then
		raise exception 'ya existe un Socio Titular con dicho DNI';
	end if;
	return NEW;
end
$$;
 .   DROP FUNCTION public.fx_adherente_disjunto();
       public       postgres    false            �            1255    24980 +   fx_cantidad_adherentes_cuota(integer, date)    FUNCTION     6  CREATE FUNCTION public.fx_cantidad_adherentes_cuota(p_dni integer, p_mesanio date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		adherentes integer;
	BEGIN
		SELECT INTO adherentes count(*) FROM CuotaDetalle CD WHERE CD.dnititular = p_dni AND CD.mesanio = p_mesanio;
		RETURN adherentes;
	END;
$$;
 R   DROP FUNCTION public.fx_cantidad_adherentes_cuota(p_dni integer, p_mesanio date);
       public       postgres    false            �            1255    24744 &   fx_convierte_importe_a_cadena(numeric)    FUNCTION       CREATE FUNCTION public.fx_convierte_importe_a_cadena(num numeric) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
-- Función que devuelve la cadena de texto en castellano que corresponde a un número.
-- Parámetros: número con 2 decimales, máximo 999.999.999,99.
 
DECLARE	
	d VARCHAR[];
	f VARCHAR[];
	g VARCHAR[];
	numt VARCHAR;
	txt VARCHAR;
	a INTEGER;
	a1 INTEGER;
	a2 INTEGER;
	n INTEGER;
	p INTEGER;
	negativo BOOLEAN;
BEGIN
	-- Máximo 999.999.999,99
	IF num > 999999999.99 THEN
		RETURN '---';
	END IF;
	
	--convertimos a positivo y dejamos en true la bandera de negativo
	IF num < 0 THEN
		num = num * (-1);
		negativo = TRUE;
	END IF;
	
	txt = '';
	d = ARRAY[' un',' dos',' tres',' cuatro',' cinco',' seis',' siete',' ocho',' nueve',' diez',' once',' doce',' trece',' catorce',' quince',
		' dieciseis',' diecisiete',' dieciocho',' diecinueve',' veinte',' veintiun',' veintidos', ' veintitres', ' veinticuatro', ' veinticinco',
		' veintiseis',' veintisiete',' veintiocho',' veintinueve'];
	f = ARRAY ['','',' treinta',' cuarenta',' cincuenta',' sesenta',' setenta',' ochenta', ' noventa'];
	g= ARRAY [' ciento',' doscientos',' trescientos',' cuatrocientos',' quinientos',' seiscientos',' setecientos',' ochocientos',' novecientos'];
	numt = LPAD((num::numeric(12,2))::text,12,'0');
	
	/*IF strpos(numt,'-') > 0 THEN
	   negativo = TRUE;
	ELSE
	   negativo = FALSE;
	END IF;*/
	
	numt = TRANSLATE(numt,'-','0');
	numt = TRANSLATE(numt,'.,','');
	-- Trato 4 grupos: millones, miles, unidades y decimales
	p = 1;
	FOR i IN 1..4 LOOP
		IF i < 4 THEN
			n = substring(numt::text FROM p FOR 3);
		ELSE
			n = substring(numt::text FROM p FOR 2);
		END IF;
		p = p + 3;
		IF i = 4 THEN
			IF txt = '' THEN
				txt = ' cero';
			END IF;
			IF n > 0 THEN
			-- Empieza con los decimales
				txt = txt || ' con';
			END IF;
		END IF;
		-- Centenas 
		IF n > 99 THEN
			a = substring(n::text FROM 1 FOR 1);
			a1 = substring(n::text FROM 2 FOR 2);
			IF a = 1 THEN
				IF a1 = 0 THEN
					txt = txt || ' cien';
				ELSE
					txt = txt || ' ciento';
				END IF;
			ELSE
				txt = txt || g[a];
			END IF;
		ELSE
			a1 = n;
		END IF;
		-- Decenas
		a = a1;
		IF a > 0 THEN
			IF a < 30 THEN
				IF a = 21 AND (i = 3 OR i = 4) THEN
					txt = txt || ' veintiuno';
				ELSIF n = 1 AND i = 2 THEN
					txt = txt; 
				ELSIF a = 1 AND (i = 3 OR i = 4)THEN
					txt = txt || ' uno';
				ELSE
					txt = txt || d[a];
				END IF;
			ELSE
				a1 = substring(a::text FROM 1 FOR 1);
				a2 = substring(a::text FROM 2 FOR 1);
				IF a2 = 1 AND (i = 3 OR i = 4) THEN
						txt = txt || f[a1] || ' y' || ' uno';
				ELSE
					IF a2 <> 0 THEN
						txt = txt || f[a1] || ' y' || d[a2];
					ELSE
						txt = txt || f[a1];
					END IF;
				END IF;
			END IF;
		END IF;
		IF n > 0 THEN
			IF i = 1 THEN
				IF n = 1 THEN
					txt = txt || ' millón';
				ELSE
					txt = txt || ' millones';
				END IF;
			ELSIF i = 2 THEN
				txt = txt || ' mil';
			END IF;		
		END IF;
	END LOOP;
	txt = LTRIM(txt);
	IF negativo = TRUE THEN
	   txt= 'Menos ' || txt;
	END IF;
    RETURN txt;
END;
$$;
 A   DROP FUNCTION public.fx_convierte_importe_a_cadena(num numeric);
       public       postgres    false            �            1255    24991 0   fx_devuelve_porcentaje_beca_cuota(integer, date)    FUNCTION     �  CREATE FUNCTION public.fx_devuelve_porcentaje_beca_cuota(p_dni integer, p_mesanio date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
	DECLARE
		porcentaje_beca numeric = 0;
	BEGIN
		SELECT INTO porcentaje_beca Beca.porcentaje FROM Beca 
			WHERE Beca.dni = p_dni 
				AND p_mesanio BETWEEN Beca.fechadesde AND Beca.fechahasta;
		
		IF porcentaje_beca IS NULL THEN
			porcentaje_beca = 0;
		END IF;
		
		RETURN porcentaje_beca;
	END;
$$;
 W   DROP FUNCTION public.fx_devuelve_porcentaje_beca_cuota(p_dni integer, p_mesanio date);
       public       postgres    false            �            1255    25022    fx_direccion_versiones()    FUNCTION     P  CREATE FUNCTION public.fx_direccion_versiones() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into DireccionVersiones(provincia,localidad,calle,numero,departamento,piso,codigoPostal,DNI)
		values (old.provincia,old.localidad,old.calle,old.numero,old.departamento,old.piso,old.codigoPostal,old.DNI);
	return null;
end
$$;
 /   DROP FUNCTION public.fx_direccion_versiones();
       public       postgres    false            �            1255    24766    fx_genera_cuotas(date)    FUNCTION     �  CREATE FUNCTION public.fx_genera_cuotas(p_mesanio date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	declare
		estado integer;
		informacion varchar(150);
		iterador1 record;
		iterador2 record;
		cantSociosGrupo integer;
		contador integer = 0;
	begin
		--si no coincide el mes ingresado al actual genera la info de error
		if extract(month from p_mesAnio) <> extract(month from current_date)
			then estado = -1;
				 informacion = estado || '@' || extract(month from p_mesAnio) || ' Error en el mes a facturar';
		else --si el mes es igual al ingresado
			estado = 0;-- estado de exito
			-- foreach para insertar registros de Cuota
			for iterador1 in
				select * from vsocios inner join Socio on Socio.numero = vsocios.numero
			loop
			
				if iterador1.titular_adherente = 'T' then
					select into cantSociosGrupo count(*) from vsocios where numero = iterador1.numero;--cantidad de socios en un mismo grupo
					--inserto la fila en Cuota
					insert into Cuota (dni,mesanio,importe,fechavencimiento) values (iterador1.dni,current_date, cantSociosGrupo*200,current_date+60);
					
					--inserto el registro de pago de la cuota en CuotaPago
					insert into CuotaPago (dni,mesanio,montorecargo,fechapago) values (iterador1.dni,current_date,0,null);
					
					--contador de filas insertadas
					contador = contador + 1;
					
					--foreach para insertar filas en CuotaDetalle
					for iterador2 in
						/*select * from vsocios inner join Socio on Socio.numero = vsocios.numero
							where vsocios.numero = iterador1.numero and vsocios.titular_nombre is not null*/
						select * from adherente Ad
							where Ad.dnititular = iterador1.dni
					loop
						--inserto cada detalle
						insert into cuotadetalle (dnititular,mesanio,dniadherente,monto) values (iterador1.dni,current_date,iterador2.dni,200);
						contador = contador + 1;
						
					end loop;
				end if;
				
			end loop;
			
			--generamos la info de exito con filas insertadas
			informacion = estado || '@' || extract(month from p_mesAnio) || ' Facturado en ' || current_date || '. ' || contador || ' filas insertadas.';
		
		end if;
		
		--devolvemos la info (error o exito)
		return informacion;
		
	end;
$$;
 7   DROP FUNCTION public.fx_genera_cuotas(p_mesanio date);
       public       postgres    false            �            1255    24773 #   fx_genera_pago_cuota(integer, date)    FUNCTION     �  CREATE FUNCTION public.fx_genera_pago_cuota(p_dni integer, p_mesanio date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	DECLARE
		cuota_completa record;
		informacion varchar(150);
		estado integer = -1;
	BEGIN
		SELECT INTO cuota_completa * FROM vHistorialCuotas vHC
			WHERE vHC.dni = p_dni AND vHC.mesanio = p_mesanio;
			
		CASE WHEN cuota_completa.estado_cuota = 'Pagada' THEN
				RAISE EXCEPTION 'Cuota ya pagada';
			 WHEN cuota_completa.estado_cuota = 'Activa' THEN
			 	estado = 0;
				informacion = estado || '@' || extract(month from p_mesanio) || ' Cuota pagada el ' || current_date;
				--INSERT INTO CuotaPago (dni, mesanio, montorecargo, fechapago) VALUES (p_dni, p_mesanio, 0, current_date);
				UPDATE CuotaPago
					SET fechapago = current_date
					WHERE dni = p_dni AND mesanio = p_mesanio;
			 WHEN cuota_completa.estado_cuota = 'Vencida' THEN
			 	informacion = estado || '@' || extract(month from p_mesanio) || ' Cuota vencida y pagada el ' || current_date;
				--INSERT INTO CuotaPago (dni, mesanio, montorecargo, fechapago) VALUES (p_dni, p_mesanio, (cuota_completa.importe * 0.01) * (current_date - cuota_completa.fechavencimiento), current_date);
				UPDATE CuotaPago
					SET fechapago = current_date,
						montorecargo = (cuota_completa.importe * 0.01) * (current_date - cuota_completa.fechavencimiento)
					WHERE dni = p_dni AND mesanio = p_mesanio;
			ELSE 
				informacion = 'Error WTF'; 
		END CASE;
		
		RETURN informacion;
	END;	
$$;
 J   DROP FUNCTION public.fx_genera_pago_cuota(p_dni integer, p_mesanio date);
       public       postgres    false            �            1255    24968 (   fx_modifica_nombre_socio_desde_vsocios()    FUNCTION     �   CREATE FUNCTION public.fx_modifica_nombre_socio_desde_vsocios() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	DECLARE
		
	BEGIN
		UPDATE socio
			SET nombre = new.nombre
			WHERE numero = new.numero;
	
	RETURN NULL;
	END;
$$;
 ?   DROP FUNCTION public.fx_modifica_nombre_socio_desde_vsocios();
       public       postgres    false            �            1255    24966    fx_resta_saldo_deudor()    FUNCTION     e  CREATE FUNCTION public.fx_resta_saldo_deudor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	DECLARE
		reg_cuota record;
	BEGIN
		SELECT INTO reg_cuota Cu.importe FROM Cuota Cu WHERE Cu.dni = new.dni AND Cu.mesanio = new.mesanio;
		
		UPDATE titular
			SET saldodeudor = saldodeudor - reg_cuota.importe
			WHERE dni = new.dni;
		
		RETURN NULL;
	END;
$$;
 .   DROP FUNCTION public.fx_resta_saldo_deudor();
       public       postgres    false            �            1255    25024    fx_socio_periodo()    FUNCTION     [  CREATE FUNCTION public.fx_socio_periodo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if tg_op = 'INSERT' then
			insert into Periodo(DNI,fechaDesde,fechaHasta,motivoBaja)
				values(new.DNI,current_date,null,null);
	elsif old.estado <> new.estado then
		if old.estado = 'activo' and new.estado <> 'activo' then --cuando se camiba de activo a otro estado
			update Periodo
			set fechaHasta = current_date, motivoBaja = new.estado
			where DNI = old.DNI and fechaDesde = (select fechaDesde from Periodo
												  where DNI = old.DNI
												 order by fechaDesde desc
												 limit 1);
		elsif old.estado <> 'activo' and new.estado = 'activo' then --cuando se cambia de otro estado a activo
			insert into Periodo(DNI,fechaDesde,fechaHasta,motivoBaja)
				values(old.DNI,current_date,null,null);
		end if;
	end if;
	return null;
end
$$;
 )   DROP FUNCTION public.fx_socio_periodo();
       public       postgres    false            �            1255    25050 *   fx_subarbol_organigrama(character varying)    FUNCTION     �  CREATE FUNCTION public.fx_subarbol_organigrama(pcuil character varying) RETURNS TABLE(cuil character varying, apellido character varying, cuilsuperior character varying)
    LANGUAGE plpgsql
    AS $$
declare
	iter record; --variable para iterar
begin
	
	--borro los datos anteriores
	delete from colaEmpleado;
	delete from colaEmpleadoRetornada;
	
	--inserto la raiz del subarbol
	insert into colaEmpleado(cuil, apellido, cuilsuperior) select E.cuil, E.apellido, E.cuilsuperior from empleado E where E.cuil = pcuil;
	
	--le asigno a iter el empleado raiz
	select into iter E.cuil, E.apellido, E.cuilsuperior from Empleado E where E.cuil = pcuil limit 1;
	
	--itero con en colaEmpleado
	loop
		--inserto el empleado en la cola a retornar
		insert into colaEmpleadoRetornada (cuil, apellido, cuilsuperior) values (iter.cuil, iter.apellido, iter.cuilsuperior);
		
		--agrego los subordinados directos del actual empleado a la cola
		insert into colaEmpleado (cuil,apellido,cuilsuperior) select DS.cuilsubordinado, DS.apellido, DS.cuilsuperior from vDatosSubordinado DS where DS.cuilsuperior = iter.cuil;
		
		--borro de la cola al empleado que estaba analizando
		delete from colaEmpleado cEmp where cEmp.cuil = iter.cuil;
		
		--le asigno el siguiente empleado de la cola a la variable. la tabla esta ordenada por el campo orden que es tipo SERIAL
		select into iter cEmp.cuil, cEmp.apellido, cEmp.cuilsuperior from colaEmpleado cEmp limit 1;
		
		--salgo del loop cuando la cola esté vacia
		exit when (select count(*) from colaEmpleado) = 0;
	end loop;
	
	--retorno la tabla con el "subarbol"
	return query select cER.cuil, cER.apellido, cER.cuilsuperior from colaEmpleadoRetornada cER;

	
end;
$$;
 G   DROP FUNCTION public.fx_subarbol_organigrama(pcuil character varying);
       public       postgres    false            �            1255    24964    fx_suma_saldo_deudor()    FUNCTION     �   CREATE FUNCTION public.fx_suma_saldo_deudor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	DECLARE
	
	BEGIN
		UPDATE titular
			SET saldodeudor = saldodeudor + new.importe
			WHERE dni = new.dni;
		
		RETURN NULL;
	END;
$$;
 -   DROP FUNCTION public.fx_suma_saldo_deudor();
       public       postgres    false            �            1255    25015    fx_titular_disjunto()    FUNCTION     �   CREATE FUNCTION public.fx_titular_disjunto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if exists(select DNI from Adherente where DNI = new.DNI) then
		raise exception 'ya existe un Socio Adherente con dicho DNI';
	end if;
	return NEW;
end
$$;
 ,   DROP FUNCTION public.fx_titular_disjunto();
       public       postgres    false            �            1255    24745 '   fx_valor_cuota_en_cadena(integer, date)    FUNCTION     m  CREATE FUNCTION public.fx_valor_cuota_en_cadena(p_dni integer, p_mesanio date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	DECLARE
		importeCuota money;
	BEGIN
		SELECT INTO importeCuota Cuota.importe FROM Cuota WHERE Cuota.dni = p_dni AND Cuota.mesanio = p_mesanio;
		
		RETURN 	fx_convierte_importe_a_cadena(cast(importeCuota as numeric));
END;
$$;
 N   DROP FUNCTION public.fx_valor_cuota_en_cadena(p_dni integer, p_mesanio date);
       public       postgres    false            �            1255    25004    fx_vmathistorialcuotas()    FUNCTION     �   CREATE FUNCTION public.fx_vmathistorialcuotas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	REFRESH MATERIALIZED VIEW vmathistorialcuotas;
	return null;
end
$$;
 /   DROP FUNCTION public.fx_vmathistorialcuotas();
       public       postgres    false            �            1259    24614 	   adherente    TABLE     �   CREATE TABLE public.adherente (
    dni integer NOT NULL,
    gradoparentesco character varying(30),
    dnititular integer NOT NULL
);
    DROP TABLE public.adherente;
       public         postgres    false            �            1259    24584    beca    TABLE     �   CREATE TABLE public.beca (
    dni integer NOT NULL,
    fechadesde date NOT NULL,
    fechahasta date,
    porcentaje double precision
);
    DROP TABLE public.beca;
       public         postgres    false            �            1259    25040    colaempleado    TABLE     �   CREATE TABLE public.colaempleado (
    orden integer NOT NULL,
    cuil character varying(20),
    apellido character varying(50),
    cuilsuperior character varying(20)
);
     DROP TABLE public.colaempleado;
       public         postgres    false            �            1259    25038    colaempleado_orden_seq    SEQUENCE     �   CREATE SEQUENCE public.colaempleado_orden_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.colaempleado_orden_seq;
       public       postgres    false    224            �           0    0    colaempleado_orden_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.colaempleado_orden_seq OWNED BY public.colaempleado.orden;
            public       postgres    false    223            �            1259    25046    colaempleadoretornada    TABLE     �   CREATE TABLE public.colaempleadoretornada (
    orden integer NOT NULL,
    cuil character varying(20),
    apellido character varying(50),
    cuilsuperior character varying(20)
);
 )   DROP TABLE public.colaempleadoretornada;
       public         postgres    false            �            1259    25044    colaempleadoretornada_orden_seq    SEQUENCE     �   CREATE SEQUENCE public.colaempleadoretornada_orden_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.colaempleadoretornada_orden_seq;
       public       postgres    false    226            �           0    0    colaempleadoretornada_orden_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.colaempleadoretornada_orden_seq OWNED BY public.colaempleadoretornada.orden;
            public       postgres    false    225            �            1259    24654    cuota    TABLE     �   CREATE TABLE public.cuota (
    dni integer NOT NULL,
    mesanio date NOT NULL,
    importe money,
    fechavencimiento date
);
    DROP TABLE public.cuota;
       public         postgres    false            �            1259    24674    cuotadetalle    TABLE     �   CREATE TABLE public.cuotadetalle (
    dnititular integer NOT NULL,
    mesanio date NOT NULL,
    dniadherente integer NOT NULL,
    monto money
);
     DROP TABLE public.cuotadetalle;
       public         postgres    false            �            1259    24664 	   cuotapago    TABLE     �   CREATE TABLE public.cuotapago (
    dni integer NOT NULL,
    mesanio date NOT NULL,
    montorecargo money,
    fechapago date
);
    DROP TABLE public.cuotapago;
       public         postgres    false            �            1259    24594    deporte    TABLE     �   CREATE TABLE public.deporte (
    codigo integer NOT NULL,
    nombre character varying(50),
    nombrefedereacion character varying(75)
);
    DROP TABLE public.deporte;
       public         postgres    false            �            1259    24644 	   direccion    TABLE     E  CREATE TABLE public.direccion (
    provincia character varying(75) NOT NULL,
    localidad character varying(75) NOT NULL,
    calle character varying(75) NOT NULL,
    numero integer NOT NULL,
    departamento character varying(75) NOT NULL,
    piso integer NOT NULL,
    codigopostal integer NOT NULL,
    dni integer
);
    DROP TABLE public.direccion;
       public         postgres    false            �            1259    25017    direccionversiones    TABLE     �  CREATE TABLE public.direccionversiones (
    provincia character varying(75),
    localidad character varying(75),
    calle character varying(75),
    numero integer,
    departamento character varying(75),
    piso integer,
    codigopostal integer,
    dni integer,
    fechaactualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario character varying(75) DEFAULT USER
);
 &   DROP TABLE public.direccionversiones;
       public         postgres    false            �            1259    24694    empleado    TABLE     �   CREATE TABLE public.empleado (
    cuil character varying(20) NOT NULL,
    apellido character varying(50),
    nombres character varying(50),
    fechaingreso date,
    cargo character varying(100),
    cuilsuperior character varying(20)
);
    DROP TABLE public.empleado;
       public         postgres    false            �            1259    24733    grupofamiliar    TABLE     �   CREATE TABLE public.grupofamiliar (
    numero integer,
    nombre character varying(75),
    titular_adherente text,
    titular_nombre character varying
);
 !   DROP TABLE public.grupofamiliar;
       public         postgres    false            �            1259    24954    periodo    TABLE     �   CREATE TABLE public.periodo (
    dni integer NOT NULL,
    fechadesde date NOT NULL,
    fechahasta date,
    motivobaja character varying(100)
);
    DROP TABLE public.periodo;
       public         postgres    false            �            1259    24577    socio    TABLE     *  CREATE TABLE public.socio (
    dni integer NOT NULL,
    numero integer,
    tipo character varying(20),
    estado character varying(50),
    nombre character varying(75),
    sexo character(1),
    fechanac date,
    individual_familiar character(1),
    estatura integer,
    fechainsc date
);
    DROP TABLE public.socio;
       public         postgres    false            �            1259    24599    socio_deporte    TABLE     �   CREATE TABLE public.socio_deporte (
    dni integer NOT NULL,
    codigo integer NOT NULL,
    esfederado boolean,
    nroinscripcion integer
);
 !   DROP TABLE public.socio_deporte;
       public         postgres    false            �            1259    24704    subordinado    TABLE     �   CREATE TABLE public.subordinado (
    cuilsuperior character varying(20) NOT NULL,
    cuilsubordinado character varying(20) NOT NULL
);
    DROP TABLE public.subordinado;
       public         postgres    false            �            1259    24624    titular    TABLE     Q   CREATE TABLE public.titular (
    dni integer NOT NULL,
    saldodeudor money
);
    DROP TABLE public.titular;
       public         postgres    false            �            1259    24755 
   vcuotabeca    VIEW     �   CREATE VIEW public.vcuotabeca AS
 SELECT b.dni,
    b.porcentaje
   FROM (public.beca b
     JOIN public.cuota cu ON ((cu.dni = b.dni)))
  WHERE ((cu.mesanio >= b.fechadesde) AND (cu.mesanio <= b.fechahasta));
    DROP VIEW public.vcuotabeca;
       public       postgres    false    201    201    201    201    207    207            �            1259    24981    vcuotacompleta    VIEW     �  CREATE VIEW public.vcuotacompleta AS
 SELECT cu.dni,
    cu.mesanio,
    cu.importe,
    cu.fechavencimiento,
    cp.fechapago,
    cp.montorecargo,
    public.fx_cantidad_adherentes_cuota(cu.dni, cu.mesanio) AS adherentes
   FROM ((public.cuota cu
     JOIN public.cuotapago cp ON (((cp.dni = cu.dni) AND (cp.mesanio = cu.mesanio))))
     JOIN public.cuotadetalle cd ON (((cd.dnititular = cu.dni) AND (cd.mesanio = cu.mesanio))));
 !   DROP VIEW public.vcuotacompleta;
       public       postgres    false    208    207    207    207    251    209    209    208    208    208    207            �            1259    24782    vdatossubordinado    VIEW     �   CREATE VIEW public.vdatossubordinado AS
 SELECT s.cuilsubordinado,
    e.apellido,
    s.cuilsuperior
   FROM (public.subordinado s
     JOIN public.empleado e ON (((e.cuil)::text = (s.cuilsubordinado)::text)));
 $   DROP VIEW public.vdatossubordinado;
       public       postgres    false    212    212    211    211            �            1259    24746    vsociotitular    VIEW     :  CREATE VIEW public.vsociotitular AS
 SELECT titular.dni,
    socio.numero,
    socio.tipo,
    socio.estado,
    socio.nombre,
    socio.sexo,
    socio.fechanac,
    socio.individual_familiar,
    socio.estatura,
    socio.fechainsc
   FROM (public.socio
     JOIN public.titular ON ((titular.dni = socio.dni)));
     DROP VIEW public.vsociotitular;
       public       postgres    false    200    205    200    200    200    200    200    200    200    200    200            �            1259    24992    vhistorialcuotas    VIEW     3  CREATE VIEW public.vhistorialcuotas AS
 SELECT st.dni,
    st.nombre,
    st.sexo,
    st.fechanac,
    cc.adherentes AS cantadherentes,
    cc.mesanio,
    cc.importe,
    cc.fechavencimiento,
    cc.fechapago,
    cc.montorecargo,
    public.fx_convierte_importe_a_cadena((cc.importe)::numeric) AS monto_cuota,
    (cc.importe - (cc.importe * (public.fx_devuelve_porcentaje_beca_cuota(st.dni, cc.mesanio))::double precision)) AS monto_becado,
        CASE
            WHEN ((cc.fechapago IS NULL) AND (CURRENT_DATE <= cc.fechavencimiento)) THEN 'Activa'::text
            WHEN ((cc.fechapago IS NULL) AND (CURRENT_DATE > cc.fechavencimiento)) THEN 'Vencida'::text
            ELSE 'Pagada'::text
        END AS estado_cuota
   FROM (public.vsociotitular st
     JOIN public.vcuotacompleta cc ON ((cc.dni = st.dni)));
 #   DROP VIEW public.vhistorialcuotas;
       public       postgres    false    219    215    215    219    215    219    215    219    227    247    219    219    219            �            1259    25005    vmathistorialcuotas    MATERIALIZED VIEW       CREATE MATERIALIZED VIEW public.vmathistorialcuotas AS
 SELECT vhistorialcuotas.dni,
    vhistorialcuotas.nombre,
    vhistorialcuotas.sexo,
    vhistorialcuotas.fechanac,
    vhistorialcuotas.cantadherentes,
    vhistorialcuotas.mesanio,
    vhistorialcuotas.importe,
    vhistorialcuotas.fechavencimiento,
    vhistorialcuotas.fechapago,
    vhistorialcuotas.montorecargo,
    vhistorialcuotas.monto_cuota,
    vhistorialcuotas.monto_becado,
    vhistorialcuotas.estado_cuota
   FROM public.vhistorialcuotas
  WITH NO DATA;
 3   DROP MATERIALIZED VIEW public.vmathistorialcuotas;
       public         postgres    false    220    220    220    220    220    220    220    220    220    220    220    220    220            �            1259    24689    vsocios    VIEW     �  CREATE VIEW public.vsocios AS
 SELECT socio.numero,
    socio.nombre,
    'T'::text AS titular_adherente,
    NULL::character varying AS titular_nombre
   FROM (public.titular
     JOIN public.socio ON ((titular.dni = socio.dni)))
UNION
 SELECT socio.numero,
    socio.nombre,
    'A'::text AS titular_adherente,
    socio_titular.nombre AS titular_nombre
   FROM ((public.adherente
     JOIN public.socio ON ((adherente.dni = socio.dni)))
     JOIN ( SELECT socio_1.dni,
            socio_1.nombre
           FROM (public.titular
             JOIN public.socio socio_1 ON ((titular.dni = socio_1.dni)))) socio_titular ON ((adherente.dnititular = socio_titular.dni)));
    DROP VIEW public.vsocios;
       public       postgres    false    205    200    200    200    204    204            �            1259    24719    vsubordinados    VIEW     �   CREATE VIEW public.vsubordinados AS
 SELECT s.cuilsubordinado,
    e.apellido,
    s.cuilsuperior
   FROM (public.subordinado s
     JOIN public.empleado e ON (((e.cuil)::text = (s.cuilsubordinado)::text)));
     DROP VIEW public.vsubordinados;
       public       postgres    false    212    211    211    212            �
           2604    25043    colaempleado orden    DEFAULT     x   ALTER TABLE ONLY public.colaempleado ALTER COLUMN orden SET DEFAULT nextval('public.colaempleado_orden_seq'::regclass);
 A   ALTER TABLE public.colaempleado ALTER COLUMN orden DROP DEFAULT;
       public       postgres    false    223    224    224            �
           2604    25049    colaempleadoretornada orden    DEFAULT     �   ALTER TABLE ONLY public.colaempleadoretornada ALTER COLUMN orden SET DEFAULT nextval('public.colaempleadoretornada_orden_seq'::regclass);
 J   ALTER TABLE public.colaempleadoretornada ALTER COLUMN orden DROP DEFAULT;
       public       postgres    false    225    226    226            �          0    24614 	   adherente 
   TABLE DATA               E   COPY public.adherente (dni, gradoparentesco, dnititular) FROM stdin;
    public       postgres    false    204   ��       �          0    24584    beca 
   TABLE DATA               G   COPY public.beca (dni, fechadesde, fechahasta, porcentaje) FROM stdin;
    public       postgres    false    201   ֶ       �          0    25040    colaempleado 
   TABLE DATA               K   COPY public.colaempleado (orden, cuil, apellido, cuilsuperior) FROM stdin;
    public       postgres    false    224   �       �          0    25046    colaempleadoretornada 
   TABLE DATA               T   COPY public.colaempleadoretornada (orden, cuil, apellido, cuilsuperior) FROM stdin;
    public       postgres    false    226   �       �          0    24654    cuota 
   TABLE DATA               H   COPY public.cuota (dni, mesanio, importe, fechavencimiento) FROM stdin;
    public       postgres    false    207   y�       �          0    24674    cuotadetalle 
   TABLE DATA               P   COPY public.cuotadetalle (dnititular, mesanio, dniadherente, monto) FROM stdin;
    public       postgres    false    209   ��       �          0    24664 	   cuotapago 
   TABLE DATA               J   COPY public.cuotapago (dni, mesanio, montorecargo, fechapago) FROM stdin;
    public       postgres    false    208   ��       �          0    24594    deporte 
   TABLE DATA               D   COPY public.deporte (codigo, nombre, nombrefedereacion) FROM stdin;
    public       postgres    false    202   6�       �          0    24644 	   direccion 
   TABLE DATA               o   COPY public.direccion (provincia, localidad, calle, numero, departamento, piso, codigopostal, dni) FROM stdin;
    public       postgres    false    206   S�       �          0    25017    direccionversiones 
   TABLE DATA               �   COPY public.direccionversiones (provincia, localidad, calle, numero, departamento, piso, codigopostal, dni, fechaactualizacion, usuario) FROM stdin;
    public       postgres    false    222   p�       �          0    24694    empleado 
   TABLE DATA               ^   COPY public.empleado (cuil, apellido, nombres, fechaingreso, cargo, cuilsuperior) FROM stdin;
    public       postgres    false    211   ��       �          0    24733    grupofamiliar 
   TABLE DATA               Z   COPY public.grupofamiliar (numero, nombre, titular_adherente, titular_nombre) FROM stdin;
    public       postgres    false    214   ,�       �          0    24954    periodo 
   TABLE DATA               J   COPY public.periodo (dni, fechadesde, fechahasta, motivobaja) FROM stdin;
    public       postgres    false    218   I�       �          0    24577    socio 
   TABLE DATA               |   COPY public.socio (dni, numero, tipo, estado, nombre, sexo, fechanac, individual_familiar, estatura, fechainsc) FROM stdin;
    public       postgres    false    200   f�       �          0    24599    socio_deporte 
   TABLE DATA               P   COPY public.socio_deporte (dni, codigo, esfederado, nroinscripcion) FROM stdin;
    public       postgres    false    203   �       �          0    24704    subordinado 
   TABLE DATA               D   COPY public.subordinado (cuilsuperior, cuilsubordinado) FROM stdin;
    public       postgres    false    212   *�       �          0    24624    titular 
   TABLE DATA               3   COPY public.titular (dni, saldodeudor) FROM stdin;
    public       postgres    false    205   \�       �           0    0    colaempleado_orden_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.colaempleado_orden_seq', 7, true);
            public       postgres    false    223            �           0    0    colaempleadoretornada_orden_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.colaempleadoretornada_orden_seq', 7, true);
            public       postgres    false    225                       2606    24618    adherente adherente_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.adherente
    ADD CONSTRAINT adherente_pkey PRIMARY KEY (dni);
 B   ALTER TABLE ONLY public.adherente DROP CONSTRAINT adherente_pkey;
       public         postgres    false    204            �
           2606    24588    beca beca_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.beca
    ADD CONSTRAINT beca_pkey PRIMARY KEY (dni, fechadesde);
 8   ALTER TABLE ONLY public.beca DROP CONSTRAINT beca_pkey;
       public         postgres    false    201    201            	           2606    24658    cuota cuota_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.cuota
    ADD CONSTRAINT cuota_pkey PRIMARY KEY (dni, mesanio);
 :   ALTER TABLE ONLY public.cuota DROP CONSTRAINT cuota_pkey;
       public         postgres    false    207    207                       2606    24678    cuotadetalle cuotadetalle_pkey 
   CONSTRAINT     {   ALTER TABLE ONLY public.cuotadetalle
    ADD CONSTRAINT cuotadetalle_pkey PRIMARY KEY (dnititular, mesanio, dniadherente);
 H   ALTER TABLE ONLY public.cuotadetalle DROP CONSTRAINT cuotadetalle_pkey;
       public         postgres    false    209    209    209            �
           2606    24598    deporte deporte_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.deporte
    ADD CONSTRAINT deporte_pkey PRIMARY KEY (codigo);
 >   ALTER TABLE ONLY public.deporte DROP CONSTRAINT deporte_pkey;
       public         postgres    false    202                       2606    24648    direccion direccion_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_pkey PRIMARY KEY (provincia, localidad, calle, numero, departamento, piso, codigopostal);
 B   ALTER TABLE ONLY public.direccion DROP CONSTRAINT direccion_pkey;
       public         postgres    false    206    206    206    206    206    206    206                       2606    24698    empleado empleado_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_pkey PRIMARY KEY (cuil);
 @   ALTER TABLE ONLY public.empleado DROP CONSTRAINT empleado_pkey;
       public         postgres    false    211                       2606    24958    periodo periodo_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.periodo
    ADD CONSTRAINT periodo_pkey PRIMARY KEY (dni, fechadesde);
 >   ALTER TABLE ONLY public.periodo DROP CONSTRAINT periodo_pkey;
       public         postgres    false    218    218                       2606    24603     socio_deporte socio_deporte_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.socio_deporte
    ADD CONSTRAINT socio_deporte_pkey PRIMARY KEY (dni, codigo);
 J   ALTER TABLE ONLY public.socio_deporte DROP CONSTRAINT socio_deporte_pkey;
       public         postgres    false    203    203            �
           2606    24583    socio socio_numero_key 
   CONSTRAINT     S   ALTER TABLE ONLY public.socio
    ADD CONSTRAINT socio_numero_key UNIQUE (numero);
 @   ALTER TABLE ONLY public.socio DROP CONSTRAINT socio_numero_key;
       public         postgres    false    200            �
           2606    24581    socio socio_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.socio
    ADD CONSTRAINT socio_pkey PRIMARY KEY (dni);
 :   ALTER TABLE ONLY public.socio DROP CONSTRAINT socio_pkey;
       public         postgres    false    200                       2606    24708    subordinado subordinado_pkey 
   CONSTRAINT     u   ALTER TABLE ONLY public.subordinado
    ADD CONSTRAINT subordinado_pkey PRIMARY KEY (cuilsuperior, cuilsubordinado);
 F   ALTER TABLE ONLY public.subordinado DROP CONSTRAINT subordinado_pkey;
       public         postgres    false    212    212                       2606    24628    titular titular_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.titular
    ADD CONSTRAINT titular_pkey PRIMARY KEY (dni);
 >   ALTER TABLE ONLY public.titular DROP CONSTRAINT titular_pkey;
       public         postgres    false    205            !           2620    25014    adherente tr_adherente_disjunto    TRIGGER     �   CREATE TRIGGER tr_adherente_disjunto BEFORE INSERT OR UPDATE ON public.adherente FOR EACH ROW EXECUTE PROCEDURE public.fx_adherente_disjunto();
 8   DROP TRIGGER tr_adherente_disjunto ON public.adherente;
       public       postgres    false    229    204            #           2620    25023     direccion tr_direccion_versiones    TRIGGER     �   CREATE TRIGGER tr_direccion_versiones AFTER UPDATE ON public.direccion FOR EACH ROW EXECUTE PROCEDURE public.fx_direccion_versiones();
 9   DROP TRIGGER tr_direccion_versiones ON public.direccion;
       public       postgres    false    231    206            &           2620    24969 .   vsocios tr_modifica_nombre_socio_desde_vsocios    TRIGGER     �   CREATE TRIGGER tr_modifica_nombre_socio_desde_vsocios INSTEAD OF UPDATE ON public.vsocios FOR EACH ROW EXECUTE PROCEDURE public.fx_modifica_nombre_socio_desde_vsocios();
 G   DROP TRIGGER tr_modifica_nombre_socio_desde_vsocios ON public.vsocios;
       public       postgres    false    210    249            %           2620    24967    cuotapago tr_resta_saldo_deudor    TRIGGER     �   CREATE TRIGGER tr_resta_saldo_deudor AFTER UPDATE ON public.cuotapago FOR EACH ROW EXECUTE PROCEDURE public.fx_resta_saldo_deudor();
 8   DROP TRIGGER tr_resta_saldo_deudor ON public.cuotapago;
       public       postgres    false    208    246                        2620    25025    socio tr_socio_periodo    TRIGGER     �   CREATE TRIGGER tr_socio_periodo AFTER INSERT OR UPDATE ON public.socio FOR EACH ROW EXECUTE PROCEDURE public.fx_socio_periodo();
 /   DROP TRIGGER tr_socio_periodo ON public.socio;
       public       postgres    false    232    200            $           2620    24965    cuota tr_suma_saldo_deudor    TRIGGER        CREATE TRIGGER tr_suma_saldo_deudor AFTER INSERT ON public.cuota FOR EACH ROW EXECUTE PROCEDURE public.fx_suma_saldo_deudor();
 3   DROP TRIGGER tr_suma_saldo_deudor ON public.cuota;
       public       postgres    false    245    207            "           2620    25016    titular tr_titular_disjunto    TRIGGER     �   CREATE TRIGGER tr_titular_disjunto BEFORE INSERT OR UPDATE ON public.titular FOR EACH ROW EXECUTE PROCEDURE public.fx_titular_disjunto();
 4   DROP TRIGGER tr_titular_disjunto ON public.titular;
       public       postgres    false    230    205            '           2620    25012 '   vhistorialcuotas tr_vmathistorialcuotas    TRIGGER     �   CREATE TRIGGER tr_vmathistorialcuotas INSTEAD OF INSERT OR DELETE OR UPDATE ON public.vhistorialcuotas FOR EACH ROW EXECUTE PROCEDURE public.fx_vmathistorialcuotas();
 @   DROP TRIGGER tr_vmathistorialcuotas ON public.vhistorialcuotas;
       public       postgres    false    228    220                       2606    24619 #   adherente adherente_dnititular_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.adherente
    ADD CONSTRAINT adherente_dnititular_fkey FOREIGN KEY (dnititular) REFERENCES public.socio(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.adherente DROP CONSTRAINT adherente_dnititular_fkey;
       public       postgres    false    200    2811    204                       2606    24589    beca beca_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.beca
    ADD CONSTRAINT beca_dni_fkey FOREIGN KEY (dni) REFERENCES public.socio(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 <   ALTER TABLE ONLY public.beca DROP CONSTRAINT beca_dni_fkey;
       public       postgres    false    200    2811    201                       2606    24659    cuota cuota_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuota
    ADD CONSTRAINT cuota_dni_fkey FOREIGN KEY (dni) REFERENCES public.titular(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 >   ALTER TABLE ONLY public.cuota DROP CONSTRAINT cuota_dni_fkey;
       public       postgres    false    207    2821    205                       2606    24684 +   cuotadetalle cuotadetalle_dniadherente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotadetalle
    ADD CONSTRAINT cuotadetalle_dniadherente_fkey FOREIGN KEY (dniadherente) REFERENCES public.adherente(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.cuotadetalle DROP CONSTRAINT cuotadetalle_dniadherente_fkey;
       public       postgres    false    204    2819    209                       2606    24679 )   cuotadetalle cuotadetalle_dnititular_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotadetalle
    ADD CONSTRAINT cuotadetalle_dnititular_fkey FOREIGN KEY (dnititular, mesanio) REFERENCES public.cuota(dni, mesanio) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.cuotadetalle DROP CONSTRAINT cuotadetalle_dnititular_fkey;
       public       postgres    false    207    207    2825    209    209                       2606    24669    cuotapago cuotapago_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuotapago
    ADD CONSTRAINT cuotapago_dni_fkey FOREIGN KEY (dni, mesanio) REFERENCES public.cuota(dni, mesanio) ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.cuotapago DROP CONSTRAINT cuotapago_dni_fkey;
       public       postgres    false    208    207    208    2825    207                       2606    24649    direccion direccion_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.direccion
    ADD CONSTRAINT direccion_dni_fkey FOREIGN KEY (dni) REFERENCES public.titular(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.direccion DROP CONSTRAINT direccion_dni_fkey;
       public       postgres    false    205    206    2821                       2606    24699 #   empleado empleado_cuilsuperior_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT empleado_cuilsuperior_fkey FOREIGN KEY (cuilsuperior) REFERENCES public.empleado(cuil) ON UPDATE CASCADE ON DELETE CASCADE;
 M   ALTER TABLE ONLY public.empleado DROP CONSTRAINT empleado_cuilsuperior_fkey;
       public       postgres    false    211    211    2829                       2606    24959    periodo periodo_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.periodo
    ADD CONSTRAINT periodo_dni_fkey FOREIGN KEY (dni) REFERENCES public.socio(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.periodo DROP CONSTRAINT periodo_dni_fkey;
       public       postgres    false    200    218    2811                       2606    24609 '   socio_deporte socio_deporte_codigo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.socio_deporte
    ADD CONSTRAINT socio_deporte_codigo_fkey FOREIGN KEY (codigo) REFERENCES public.deporte(codigo) ON UPDATE CASCADE ON DELETE CASCADE;
 Q   ALTER TABLE ONLY public.socio_deporte DROP CONSTRAINT socio_deporte_codigo_fkey;
       public       postgres    false    2815    203    202                       2606    24604 $   socio_deporte socio_deporte_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.socio_deporte
    ADD CONSTRAINT socio_deporte_dni_fkey FOREIGN KEY (dni) REFERENCES public.socio(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.socio_deporte DROP CONSTRAINT socio_deporte_dni_fkey;
       public       postgres    false    203    2811    200                       2606    24714 ,   subordinado subordinado_cuilsubordinado_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.subordinado
    ADD CONSTRAINT subordinado_cuilsubordinado_fkey FOREIGN KEY (cuilsubordinado) REFERENCES public.empleado(cuil) ON UPDATE CASCADE ON DELETE CASCADE;
 V   ALTER TABLE ONLY public.subordinado DROP CONSTRAINT subordinado_cuilsubordinado_fkey;
       public       postgres    false    2829    212    211                       2606    24709 )   subordinado subordinado_cuilsuperior_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.subordinado
    ADD CONSTRAINT subordinado_cuilsuperior_fkey FOREIGN KEY (cuilsuperior) REFERENCES public.empleado(cuil) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.subordinado DROP CONSTRAINT subordinado_cuilsuperior_fkey;
       public       postgres    false    211    212    2829                       2606    24629    titular titular_dni_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.titular
    ADD CONSTRAINT titular_dni_fkey FOREIGN KEY (dni) REFERENCES public.socio(dni) ON UPDATE CASCADE ON DELETE CASCADE;
 B   ALTER TABLE ONLY public.titular DROP CONSTRAINT titular_dni_fkey;
       public       postgres    false    200    2811    205            �           0    25005    vmathistorialcuotas    MATERIALIZED VIEW DATA     6   REFRESH MATERIALIZED VIEW public.vmathistorialcuotas;
            public       postgres    false    221    3006            �   #   x�3��01033��H-�M���4�Xp��qqq x_�      �      x������ � �      �      x������ � �      �   Y   x��K
�0����0B���'�&`��q�����0�j�(+9��
�<<��lb
�ה��("���o}L	�n��x��2�eY���X�      �   1   x�3��0103��420��50�542t5�����r��qqq �9	�      �   0   x�3��0103��420��50�54�4����t5������ �	a      �   ,   x�3��0103��420��50�54�4�10PxԴI�+F��� ٬	B      �      x������ � �      �      x������ � �      �      x������ � �      �   �   x�e�Q�0�g8�.0����Kx�����+������>i�	��@��E�5	����a�����jn��G�Ew^�{�A^6]�����G�C��O��Pd	��l��/�a��Zc��T�}�O)J-�1����I)A�      �      x������ � �      �      x������ � �      �   �   x�]�K
�0 ������̴M�e���M��h]xz��E��������KLw7@�_�;B��-��Mn���G8[�����*A�2���7��&<bZ�=Յa�!"���㬘E�H�\��ߦ)|����m�uL�Bf�]J�/�u6�      �      x������ � �      �   "   x�3�4�2�4�2�4bS.cN3 6����� 52�      �      x�3��0103��4�10PxԴ�+F��� ?QT     