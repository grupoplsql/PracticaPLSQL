create or replace package PaqueteRutas as
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
        FROM    modelos m, viajes v, rutas r, autobuses a
        WHERE   v.codruta = r.codigo
        AND     v.matricula = a.matricula
        AND     a.codmodelo = m.codigo
        AND     r.origen = v_origen
        AND     r.destino = v_destino
        AND     TO_CHAR(v.fechahorasalida,'D') = TO_CHAR(v_fechaformateada, 'D');
    r_viajes c_viajes%rowtype;
-- MÉTODOS A PARTIR DE AQUÍ
-- Declaro la función para que sea visible desde fuera        
    PROCEDURE MostrarPlazas (   p_origen rutas.origen%TYPE,
                                p_destino rutas.destino%TYPE,
                                p_fechasalida VARCHAR2);
end PaqueteRutas;
/

-- Metodos del paquete aqui
create or replace package body PaqueteRutas as
    PROCEDURE MostrarPlazas (   p_origen rutas.origen%TYPE,
                                p_destino rutas.destino%TYPE,
                                p_fechasalida VARCHAR2)
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
/

CREATE OR REPLACE PROCEDURE Pruebas
is
    fecha date;
begin
    fecha := to_date('10/5/2016','DD/MM/YYYY');
    PaqueteRutas.MostrarPlazas ('Sevilla', 'Madrid', fecha);
end;
/
