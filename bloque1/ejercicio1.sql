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
        FROM     viajes v, rutas r
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
                DBMS_OUTPUT.put_line(   v_salida.anden || ' ' || 
                                        v_salida.destino || ' ' || 
                                        v_salida.Hora_Salida || '    ' || 
                                        v_salida.Llegada_Estimada || '    ' ||
                                        v_salida.Matricula);
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
        SELECT  RPAD(v.andensalida, 6, ' ') AS anden,
                RPAD(r.origen, 10, ' ') AS origen,
                TO_CHAR(v.fechahorasalida, 'DD/MM/YYYY HH24:MI') AS Hora_Salida,
                -- Usando fracciones podemos adelantar los minutos que queramos.
                TO_CHAR(v.fechahorasalida + r.duracionenminutos / 1440, 'DD/MM/YYYY HH24:MI') AS Llegada_Estimada,
                v.matricula AS matricula
        FROM    viajes v, rutas r
        WHERE   v.codruta = r.codigo
        AND     r.destino = p_ciudad
        AND     TO_NUMBER(TO_CHAR(SYSDATE, 'D'), '9') <= TO_NUMBER(TO_CHAR(v.fechahorasalida, 'D'), '9')
        AND     TO_NUMBER(TO_CHAR(SYSDATE, 'HH24MI'), '9999') < 
                        TO_NUMBER(TO_CHAR(v.fechahorasalida, 'HH24MI'), '9999')
        ORDER BY Hora_Salida ASC;
    v_llegada c_llegadas%ROWTYPE;
BEGIN
        OPEN c_llegadas;
        FETCH c_llegadas INTO v_llegada;
        DBMS_OUTPUT.put_line('Anden  Origen        HoraSalida          Llegada Est.     MatrículaBus');
        WHILE c_llegadas%FOUND AND c_llegadas%ROWCOUNT <= p_cantidad LOOP
            DBMS_OUTPUT.put_line(   v_llegada.anden || ' ' || 
                                    v_llegada.origen || ' ' || 
                                    v_llegada.Hora_Salida || '    ' || 
                                    v_llegada.Llegada_Estimada || '    ' ||
                                    v_llegada.Matricula);
            FETCH c_llegadas INTO v_llegada;
        END LOOP;
        CLOSE c_llegadas;
END MostrarLlegadas;
/

CREATE OR REPLACE PROCEDURE PanelInformacion(   p_ciudad_salida VARCHAR2, 
                                                p_cantidad_salidas NUMBER,
                                                p_ciudad_llegada VARCHAR2,
                                                p_cantidad_llegadas NUMBER)
IS
BEGIN
        MostrarSalidas(p_ciudad_salida, p_cantidad_salidas);
        DBMS_OUTPUT.put_line(CHR(10));
        Mostrarllegadas(p_ciudad_llegada, p_cantidad_llegadas);
END PanelInformacion;
/
