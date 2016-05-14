 
/*
Realiza los módulos de programación necesarios para que desde el servicio de atención telefónica de la compañía, 
cuando un cliente quiera reservar un billete para ir de un origen a un destino en un día determinado, la telefonista 
pueda informarle de todos los posibles viajes que la compañía le ofrece (descartando los que no tengan ya plazas 
disponibles), incluyendo hora de salida, hora de llegada estimada y precio del billete.

Deben contemplarse las siguientes excepciones: Ciudad Origen Inexistente, Ciudad Destino Inexistente, Ruta no 
Operada ese día, Ruta sin billetes disponibles ese día, ruta inexistente.

Nota: Se considera fundamental la división adecuada en subprogramas cuando resulte procedente y la correcta 
legibilidad del código, así como la minimización del número de consultas realizadas al servidor.
*/
CREATE or REPLACE FUNCTION ComprobarRuta (p_origen rutas.origen%type, p_destino rutas.destino%type)
RETURN NUMBER
IS
    v_cantidad NUMBER;
BEGIN
    SELECT COUNT(*) AS cantidad INTO v_cantidad
    FROM rutas
    WHERE LOWER(origen) = LOWER(p_origen)
    AND LOWER(destino) = LOWER(p_destino);

    RETURN v_cantidad;
END ComprobarRuta;
/

CREATE or REPLACE FUNCTION ConvertirFecha (p_fecha VARCHAR2)
RETURN DATE
IS
    v_fecha DATE;
    v_formato VARCHAR2(20);
    /*
        e_formato_fecha_invalido exception;
        pragma exception_init(e_formato_fecha_invalido, -20001);
    */
BEGIN
    CASE
        WHEN regexp_like (p_fecha, '\d{1,2}/\d{1,2}/\d{2}') THEN
            v_formato := 'DD/MM/YY';
        WHEN regexp_like (p_fecha, '\d{1,2}/\d{1,2}/\d{4}') THEN
            v_formato := 'DD/MM/YYYY';
        WHEN regexp_like (p_fecha, '\d{1,2}-\d{1,2}-\d{4}') THEN
            v_formato := 'DD-MM-YYYY';
        WHEN regexp_like (p_fecha, '\d{1,2}-\d{1,2}-\d{2}') THEN
            v_formato := 'DD-MM-YY';
        ELSE
            RAISE_APPLICATION_ERROR (-20001, 'Formato de fecha incorrecto');
        END CASE;
    v_fecha := to_date(p_fecha, v_formato);
    RETURN v_fecha;
/*
exception
    when e_formato_fecha_invalido then
        DBMS_OUTPUT.put_line('Fecha introducida incorrecta.');
*/
END ConvertirFecha;
/

CREATE OR REPLACE PROCEDURE MostrarRuta (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE, p_fechasalida VARCHAR2)
IS
   v_fechaformateada DATE;
   CURSOR c_viajes
   IS
        SELECT  m.numeroasientos - v.numbilletesvendidos AS disponibles,
                TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS salida,
                TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS llegada,
                r.preciobillete AS precio_billete
        FROM    modelos m, viajes v, rutas r, autobuses a
        WHERE   v.codruta = r.codigo
        AND     v.matricula = a.matricula
        AND     a.codmodelo = m.codigo
        AND     r.origen = p_origen
        AND     r.destino = p_destino
        AND     TO_CHAR(v.fechahorasalida,'D') = TO_CHAR(v_fechaformateada, 'D');
BEGIN
    v_fechaformateada := ConvertirFecha(p_fechasalida);
    v_numrutas := ComprobarRuta(p_origen, p_destino);
    if v_numrutas = 0 then
        RAISE_APPLICATION_ERROR (-20002, 'No existe esa ruta');
    end if;
    open c_viajes;
    fetch c_viajes into v_check;
    if not c_viajes%FOUND then
        RAISE_APPLICATION_ERROR (-20003, 'No hay viajes ese dia');
    end if;
    close c_viajes;
    FOR v_viajes in c_viajes LOOP
        IF c_viajes%ROWCOUNT = 1 THEN
            DBMS_OUTPUT.put_line('Cabecera');
        END IF;
        DBMS_OUTPUT.put_line(   v_viajes.disponibles || ' ' ||
                                v_viajes.salida || ' ' || 
                                v_viajes.llegada || ' ' ||
                                v_viajes.precio_billete);
    END LOOP;
END MostrarRuta;
/

CREATE or REPLACE FUNCTION ComprobarCiudad (p_ciudad rutas.origen%TYPE, p_tipo VARCHAR2)
RETURN NUMBER
IS
    v_existe NUMBER;
    dsbl_peticionsql VARCHAR2(500);
BEGIN
    dsbl_peticionsql := 'SELECT COUNT(*) ' ||
                        'FROM rutas '      ||
                        'WHERE ' || p_tipo || ' = :a';
/*
    Se pueden usar más de una variable, contando con que el paso de variables es posicional.
    El nombre de las variables es indiferente, y se pueden repetir.
    Las variables que son sobre la estructura de las tablas hay que concatenarlas en la cadena
    de dsbl, no pueden pasarse como variable.
*/
    EXECUTE IMMEDIATE dsbl_peticionsql INTO v_existe
    USING   p_ciudad;
    RETURN  v_existe;
END ComprobarCiudad;
/

CREATE OR REPLACE PROCEDURE ReservarViaje (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE)
IS
    v_existe NUMBER;
BEGIN
    v_existe := ComprobarCiudad(p_origen, 'origen');
    IF v_existe <= 0 THEN
        -- raise_exception_error();
        DBMS_OUTPUT.put_line('Error');
    END IF;
    
    v_existe := ComprobarCiudad(p_destino, 'destino');
    IF v_existe <= 0 THEN
        -- raise_exception_error();
        DBMS_OUTPUT.put_line('Error');
    END IF;
    -- MostrarRuta(p_origen, p_destino, p_fechasalida);
END ReservarViaje;
/
