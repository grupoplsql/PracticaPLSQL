/*
Ejercicio 1

Realiza los módulos de programación necesarios para mostrar el panel de información de salidas y llegadas de una 
estación de autobuses. La aplicación recibirá como parámetro el nombre de la ciudad donde se ubica la estación y 
mostrará un listado con las cuatro últimas salidas y las cuatro últimas llegadas desde o hacia esa ciudad.

En caso de que no hayan llegadas a esa ciudad no se mostrará el listado de llegadas. En caso de que no hayan salidas 
desde esa ciudad no se mostrará el listado de salidas. Si hay menos de cuatro salidas o llegadas, se mostrarán las 
que hayan. Si la ciudad no existe se levantará una excepción informando del hecho.

El formato será el siguiente:

Salidas

Anden		Destino	HoraSalida	HoraEstimadaLlegada MatrículaBus
…
...
…

Llegadas

Anden		Origen		HoraEstimadaLlegada	 	MatrículaBus
…
...
…

*/

CREATE OR REPLACE PROCEDURE MostrarSalidas(p_ciudad rutas.origen%TYPE, p_cantidad NUMBER)
IS
    CURSOR c_salidas
    IS
        SELECT   RPAD(v.andensalida, 6, ' ') AS anden,
                 RPAD(r.destino, 10, ' ') AS destino,
                 TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS Hora_Salida,
                 -- Usando fracciones podemos adelantar los minutos que queramos.
                 TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS Llegada_Estimada,
                 v.matricula AS matricula
        FROM     viajes v,
                 rutas r
        WHERE    v.codruta = r.codigo
        AND      r.origen = p_ciudad
        AND      TO_NUMBER(TO_CHAR(v.fechahorasalida, 'DHH24MI'), '99999') >= 
                        to_NUMBER(to_char(sysdate, 'DHH24MI'), '99999')
        ORDER BY Hora_Salida ASC;
    v_salida     c_salidas%ROWTYPE;
BEGIN
        DBMS_OUTPUT.put_line('Anden  Destino       HoraSalida          Llegada Est.     MatrículaBus'); 
        OPEN c_salidas;
        FOR i IN 1..p_cantidad LOOP
            FETCH c_salidas INTO v_salida;
            IF c_salidas%found THEN
                DBMS_OUTPUT.put_line(
                                      v_salida.anden || ' ' || 
                                      v_salida.destino || ' ' || 
                                      v_salida.Hora_Salida || '    ' || 
                                      v_salida.Llegada_Estimada || '    ' ||
                                      v_salida.Matricula
                                        );
                FETCH c_salidas INTO v_salida;
            ELSE
                DBMS_OUTPUT.put_line('---');
            END IF;
        END LOOP;
        CLOSE c_salidas;
END MostrarSalidas;
/

CREATE OR REPLACE PROCEDURE MostrarLlegadas(p_ciudad rutas.destino%TYPE, p_cantidad NUMBER)
IS
    CURSOR c_llegadas
    IS
        SELECT   RPAD(v.andensalida, 6, ' ') AS anden,
                 RPAD(r.origen, 10, ' ') AS origen,
                 TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS Hora_Salida,
                 -- Usando fracciones podemos adelantar los minutos que queramos.
                 TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS Llegada_Estimada,
                 v.matricula AS matricula
        FROM     viajes v,
                 rutas r
        WHERE    v.codruta = r.codigo
        AND      r.destino = p_ciudad
        AND      TO_NUMBER(TO_CHAR(SYSDATE, 'D'), '9') <= TO_NUMBER(TO_CHAR(v.fechahorasalida, 'D'), '9')
        AND      TO_NUMBER(TO_CHAR(SYSDATE, 'HH24MI'), '9999') < 
                            TO_NUMBER(TO_CHAR(v.fechahorasalida, 'HH24MI'), '9999')
        ORDER BY Hora_Salida ASC;

    v_llegada     c_llegadas%ROWTYPE;
BEGIN
        OPEN c_llegadas;
        FETCH c_llegadas INTO v_llegada;
        DBMS_OUTPUT.put_line('Anden  Origen        HoraSalida          Llegada Est.     MatrículaBus');
        WHILE c_llegadas%FOUND AND c_llegadas%ROWCOUNT <= p_cantidad LOOP
            DBMS_OUTPUT.put_line(
                                  v_llegada.anden || ' ' || 
                                  v_llegada.origen || ' ' || 
                                  v_llegada.Hora_Salida || '    ' || 
                                  v_llegada.Llegada_Estimada || '    ' ||
                                  v_llegada.Matricula
                                        );
            FETCH c_llegadas INTO v_llegada;
        END LOOP;
        CLOSE c_llegadas;
END MostrarLlegadas;
/

CREATE OR REPLACE PROCEDURE PanelInformacion(
                                              p_ciudad_salida VARCHAR2, 
                                              p_cantidad_salidas NUMBER,
                                              p_ciudad_llegada VARCHAR2,
                                              p_cantidad_llegadas NUMBER
                                                   )
IS
BEGIN
        MostrarSalidas(p_ciudad_salida, p_cantidad_salidas);
        DBMS_OUTPUT.put_line(CHR(10));
        Mostrarllegadas(p_ciudad_llegada, p_cantidad_llegadas);
END PanelInformacion;
/

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

-- Paquete desde aquí
create or replace package PaqueteRutas as
-- Aquí se define el tipo de columnas que tendrá la tabla
    TYPE tRegDetalleRuta is RECORD
    (
        plazasDisponibles   number,
        fechahorasalida     date,
        fechahorallegada    date,
        preciobillete       rutas.preciobillete%TYPE
    );

-- Aquí se define el tipo de registros que tendrá la tabla.
    type tTablaRutas is table of tRegDetalleRuta
    index by binary_integer;

-- Aquí se declara la tabla
    InfoRutas   tTablaRutas;

    v_fechaformateada   date;
    v_destino           rutas.destino%TYPE;
    v_origen            rutas.origen%TYPE;

-- Declaro el cursor para que sea visible desde fuera
    CURSOR c_viajes
    IS
        SELECT  m.numeroasientos - v.numbilletesvendidos AS disponibles,
                TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS salida,
                TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS llegada,
                r.preciobillete AS precio_billete
        FROM    modelos m,
                viajes v,
                rutas r,
                autobuses a
        WHERE   v.codruta = r.codigo
        AND     v.matricula = a.matricula
        AND     a.codmodelo = m.codigo
        AND     r.origen = v_origen
        AND     r.destino = v_destino
        AND     TO_CHAR(v.fechahorasalida,'D') = TO_CHAR(v_fechaformateada, 'D');
    r_viajes c_viajes%rowtype;
-- MÉTODOS A PARTIR DE AQUÍ
-- Declaro la función para que sea visible desde fuera        
    PROCEDURE MostrarPlazas (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE, p_fechasalida VARCHAR2);
end PaqueteRutas;

-- Metodos del paquete aqui
create or replace package body PaqueteRutas as
    PROCEDURE MostrarPlazas (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE, p_fechasalida VARCHAR2)
    is
        -- ¿Aquí variables locales de la función?
        r_viajes c_viajes%ROWTYPE;
    begin
        v_destino := p_destino;
        v_origen := p_origen;
        v_fechaformateada := to_date('10/5/2016','DD/MM/YYYY');
        FOR r_viajes in c_viajes LOOP
            IF c_viajes%ROWCOUNT = 1 THEN
                DBMS_OUTPUT.put_line('Cabecera');
            END IF;
            DBMS_OUTPUT.put_line(   r_viajes.disponibles || ' ' ||
                                    r_viajes.salida || ' ' || 
                                    r_viajes.llegada || ' ' ||
                                    r_viajes.precio_billete);
        END LOOP;
    end MostrarPlazas;
end PaqueteRutas;

CREATE OR REPLACE PROCEDURE MostrarRuta
is
    fecha date;
begin
    fecha := to_date('10/5/2016','DD/MM/YYYY');
    PaqueteRutas.MostrarPlazas ('Sevilla', 'Madrid', fecha);
end;
/
-- Paquete Rutas hasta aqui

CREATE OR REPLACE PROCEDURE MostrarRuta (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE, p_fechasalida VARCHAR2)
IS
   v_fechaformateada DATE;
   CURSOR c_viajes
   IS
        SELECT  m.numeroasientos - v.numbilletesvendidos AS disponibles,
                TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS salida,
                TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS llegada,
                r.preciobillete AS precio_billete
        FROM    modelos m,
                viajes v,
                rutas r,
                autobuses a
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
