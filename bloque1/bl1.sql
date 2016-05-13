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

CREATE or REPLACE FUNCTION ConvertirFecha (p_fecha VARCHAR2)
return DATE
is
    v_fecha DATE;
    v_formato varchar2(20);
    pragma_exception_init(formato_fecha_invalido, -20001);
begin
    case
        when regexp_like (p_fecha, '\d{1,2}/\d{1,2}/\d{2}') then
            v_formato = 'DD/MM/YY';
        when regexp_like (p_fecha, '\d{1,2}/\d{1,2}/\d{4}') then
            v_formato = 'DD/MM/YYYY';
        when regexp_like (p_fecha, '\d{1,2}-\d{1,2}-\d{4}') then
            v_formato = 'DD-MM-YYYY';
        when regexp_like (p_fecha, '\d{1,2}-\d{1,2}-\d{2}') then
            v_formato = 'DD-MM-YY';
        else
            raise formato_fecha_invalido;
        end case;
    to_date(p_fecha, v_formato);
    return v_fecha;
exception
    when formato_fecha_invalido then
        DBMS_OUTPUT.put_line('Fecha introducida incorrecta.')
end ConvertirFecha;

CREATE OR REPLACE PROCEDURE MostrarRuta (p_origen rutas.origen%TYPE, p_destino rutas.destino%TYPE, p_fechasalida VARCHAR2)
IS
   CURSOR
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
        AND     r.origen = 'Sevilla'
        AND     r.destino = 'Madrid'
        AND     to_char(v.fechahorasalida,'D') = v_fechaformateada;
    
    v_fechaformateada date;
BEGIN
    v_fechaformateada := ConvertirFecha(p_fechasalida);
exceptions
    when
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
