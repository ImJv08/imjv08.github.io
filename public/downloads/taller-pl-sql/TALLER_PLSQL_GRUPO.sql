--------------------------------------------------------------------------------
-- UNIVERSIDAD EL BOSQUE — INGENIERIA DE SISTEMAS
-- Asignatura: Bases de Datos 2
-- Docente: Ing., Esp., M.Ed. Christian Felipe Duarte
--
-- TALLER PL/SQL — PLANTILLA DE ENTREGA
--
-- GRUPO No.: ____
-- INTEGRANTES: 1) Juana Valentina Aldana Rueda
--              2) Isabela Gómez Tobar
--              3) Santiago Ramos Trejos
-- FECHA DE ENTREGA: 03/10/2026
--------------------------------------------------------------------------------
--
-- COMO TRABAJAR
--   1. Ejecute primero, completo, el script 01_esquema_inventario.sql
--   2. Desarrolle cada punto en la seccion correspondiente de este archivo
--   3. No borre los encabezados de cada ejercicio ni cambie los nombres de los
--      objetos solicitados. La revision los busca por nombre: un objeto correcto
--      con otro nombre se califica como no entregado.
--   4. Los esqueletos de la Parte 5 no incluyen la clausula de disparo. Definirla
--      hace parte del ejercicio, de modo que esos bloques no compilan tal como se
--      entregan.
--
-- DISTRIBUCION DEL PUNTAJE                                     Total: 50 puntos
--   Parte 1  Procedimientos almacenados .................  8 puntos
--   Parte 2  Funciones ...................................  8 puntos
--   Parte 3  Cursores .................................... 10 puntos
--   Parte 4  Manejo de excepciones .......................  9 puntos
--   Parte 5  Disparadores ................................ 10 puntos
--   Parte 6  Caso integrador .............................  5 puntos
--
-- CRITERIOS DE EVALUACION
--   Correccion tecnica ....... 40%   El objeto compila y cumple el enunciado
--   Justificacion ............ 40%   Las decisiones de diseno estan argumentadas
--   Analisis operacional ..... 20%   Se anticipa el comportamiento ante
--                                    concurrencia, volumen y error
--
--   Cada objeto debe incluir su justificacion en el espacio marcado. Un ejercicio
--   sin justificacion obtiene como maximo el 40% de su puntaje aunque funcione.
--   Una justificacion que confunde la causa con el efecto no obtiene puntaje.
--   Describir lo que hace el codigo, sin argumentar por que se eligio esa
--   construccion y no otra, equivale a no justificar.
--
-- ENTREGA
--   Este archivo renombrado como TALLER_PLSQL_GRUPO_<n>.sql, junto con un
--   documento que contenga las salidas de DBMS_OUTPUT de cada bloque ejecutado.
--   Ambos archivos deben incluir los nombres de los tres integrantes.
--
-- SUSTENTACION
--   20 minutos por grupo. Los tres integrantes deben poder explicar cualquier
--   parte del codigo, no solamente la que desarrollaron.
--------------------------------------------------------------------------------


SET SERVEROUTPUT ON SIZE UNLIMITED

--==============================================================================
-- PARTE 1 — PROCEDIMIENTOS ALMACENADOS                        (8 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 1.1 (2 pts)
-- SP_REGISTRAR_PRODUCTO
-- Registra un producto nuevo. Debe asignar el identificador desde SEQ_PRODUCTO,
-- validar que el precio de venta supere el costo unitario, verificar que la
-- categoria exista y manejar el caso de codigo duplicado. Devuelve el
-- identificador generado.
-------------------------------------------------------------------------------
-- JUSTIFICACION: 
/*
 En este bloque se valida que el precio de venta sea mayor al costo y que la
 categoria exista antes del INSERT (asi se evita añadir datos erroneos a la base
 de datos. 
 
 Para manejar el caso del codigo duplicado, se utilizo "DUP_VAL_ON_INDEX" en la
 seccion EXCEPTION del bloque ya que la restricción UNIQUE del codigo nos
 previene de añadir codigos repetidos, lanzando este error.
 
 Para generar el id del nuevo producto, se utilizó "SEQ_PRODUCTO.NEXTVAL" y se 
 almacenó en el parametro "p_id_producto", el cual fue el retorno de este 
 procedimiento.
 
 Nota: Al hacer las pruebas de este procedimiento, nos dimos cuenta que el valor
 de SEQ_PRODUCTO no esta sincronizada con los ids cargados en el esquema (1001 -
 1015), asi que al generar id puede saltar al EXCEPTION de DUP_VAL_INDEX.
 
*/
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_PRODUCTO (
    p_codigo        IN  VARCHAR2,
    p_nombre        IN  VARCHAR2,
    p_id_categoria  IN  NUMBER,
    p_precio        IN  NUMBER,
    p_costo         IN  NUMBER,
    p_stock_minimo  IN  NUMBER DEFAULT 0,
    p_id_producto   OUT NUMBER
) IS
    vn_existe NUMBER;   
BEGIN
    
    IF p_precio <= p_costo THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El precio de venta (' || p_precio ||
            ') debe ser mayor al costo unitario (' || p_costo || ')');
    END IF;

    SELECT COUNT(*)
    INTO   vn_existe
    FROM   CATEGORIA
    WHERE  id_categoria = p_id_categoria;

    IF vn_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'La categoria ' || p_id_categoria || ' no existe');
    END IF;

    INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria,
                          precio_unitario, costo_unitario, stock_minimo)
    VALUES (SEQ_PRODUCTO.NEXTVAL, p_codigo, p_nombre, p_id_categoria,
            p_precio, p_costo, NVL(p_stock_minimo, 0))
    RETURNING id_producto INTO p_id_producto;
    

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Ya existe un producto con el codigo ' || p_codigo);
END SP_REGISTRAR_PRODUCTO;
/

-- BLOQUE ANÓNIMO PARA PROBAR EL PROCEDIMIENTO
-- valido
DECLARE
    vn_id NUMBER;
BEGIN
    SP_REGISTRAR_PRODUCTO('TS-0100', 'Prueba', 1, 50000, 30000, 5, vn_id);
    DBMS_OUTPUT.PUT_LINE('ID generado: ' || vn_id);
END;
/

-- precio <= costo 
DECLARE
    vn_id NUMBER;
BEGIN
    SP_REGISTRAR_PRODUCTO('TS-0002', 'Prueba', 1, 20000, 30000, 5, vn_id);
END;
/

-- la categoria no existe
DECLARE
    vn_id NUMBER;
BEGIN
    SP_REGISTRAR_PRODUCTO('TS-0003', 'Prueba', 99, 50000, 30000, 5, vn_id);
END;
/

-- codigo duplicado
DECLARE
    vn_id NUMBER;
BEGIN
    SP_REGISTRAR_PRODUCTO('HM-0001', 'Prueba', 1, 50000, 30000, 5, vn_id);
END;
/

ROLLBACK;

------------------------------------------------------------------- 1.2 (3 pts)
-- SP_AJUSTAR_STOCK
-- Registra una ENTRADA, SALIDA o AJUSTE de inventario sobre una bodega.
-- Debe actualizar EXISTENCIA e insertar el registro en MOVIMIENTO_INVENTARIO,
-- devolviendo el saldo resultante.
--   * Si la combinacion bodega-producto no existe y el tipo es ENTRADA, crearla
--   * Si el tipo es SALIDA y no existe la combinacion, rechazar la operacion
--   * Una SALIDA nunca puede dejar la existencia en negativo
-- Proteja la lectura de la existencia frente a modificaciones concurrentes.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este procedimiento se valido que la combinacion bodega-producto no existe
utilizando una consulta que cuenta el total de productos con el id especificada
estan en la bodega con el id especificada, este dato se guarda en la variable
"vn_existe" la cual luego la utilizamos en un IF para verificar si el numero dio
un numero mayor a 0 (si da 0, significa que no existe), luego se ve si el tipo
es ENTRADA con otro IF para poder definir si se crea la existencia o no.

Luego se selecciona la cantidad total del producto que se le va a ajustar el stock.
En esta ocasión, decidimos agregar la clausula SELECT ... FOR UPDATE para bloquear
la fila hasta que se haga el COMMIT o el ROLLBACK, asi evitamos que otra sesión la
modifique entre la lectura de los datos y el UPDATE.

La salida se valida verificando que la cantidad que se esta solicitando sea
mayor al stock total del producto antes de hacer la resta, evitando resultados
negativos.

El ajuste sirve para corregir el inventario cuando lo que dice el sistema no
es lo que realmente hay en la bodega. Se envia la cantidad que se conto y el
sistema queda con ese numero. Se anota cuanto se corrigio. Si lo contado es
igual a lo que ya decia el sistema, se rechaza porque no hay nada que corregir.
*/

CREATE OR REPLACE PROCEDURE SP_AJUSTAR_STOCK (
    p_id_producto  IN  NUMBER,
    p_id_bodega    IN  NUMBER,
    p_tipo         IN  VARCHAR2,
    p_cantidad     IN  NUMBER,
    p_observacion  IN  VARCHAR2 DEFAULT NULL,
    p_saldo_final  OUT NUMBER
) IS
    vn_existe  NUMBER;
    vn_actual  NUMBER;
    vn_mov     NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO   vn_existe
    FROM   EXISTENCIA
    WHERE  id_bodega = p_id_bodega
    AND    id_producto = p_id_producto;
    
    IF vn_existe = 0 THEN
        IF p_tipo = 'ENTRADA' THEN
            INSERT INTO EXISTENCIA (id_bodega, id_producto, cantidad)
            VALUES (p_id_bodega, p_id_producto, 0);

        ELSE
            RAISE_APPLICATION_ERROR(-20014,
                'No existe la combinacion bodega-producto');
        END IF;
    END IF;
    
    SELECT cantidad
    INTO   vn_actual
    FROM   EXISTENCIA
    WHERE  id_bodega = p_id_bodega
    AND    id_producto = p_id_producto
    FOR UPDATE;

    IF p_tipo = 'ENTRADA' THEN
        p_saldo_final := vn_actual + p_cantidad;
        vn_mov := p_cantidad;

    ELSIF p_tipo = 'SALIDA' THEN

        IF p_cantidad > vn_actual THEN
            RAISE_APPLICATION_ERROR(-20015,
                'Stock insuficiente: hay ' || vn_actual ||
                ' y se piden ' || p_cantidad);
        END IF;
        p_saldo_final := vn_actual - p_cantidad;
        vn_mov := p_cantidad;

    ELSE
        IF p_cantidad = vn_actual THEN
            RAISE_APPLICATION_ERROR(-20016,
                'El conteo coincide con la existencia');
        END IF;
        
        p_saldo_final := p_cantidad;
        vn_mov := ABS(p_cantidad - vn_actual);
        
    END IF;

    UPDATE EXISTENCIA
    SET    cantidad = p_saldo_final
    WHERE  id_bodega = p_id_bodega
    AND    id_producto = p_id_producto;

    INSERT INTO MOVIMIENTO_INVENTARIO
           (id_movimiento, id_producto, id_bodega, tipo, cantidad, observacion)
    VALUES (SEQ_MOVIMIENTO.NEXTVAL, p_id_producto, p_id_bodega, p_tipo,
            vn_mov, p_observacion);
            
END SP_AJUSTAR_STOCK;
/

-- BLOQUES ANÓNIMOS PARA VERIFICAR

-- entrada
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 1, 'ENTRADA', 10, 'Prueba', vn_saldo);
    DBMS_OUTPUT.PUT_LINE('Saldo resultante = ' || vn_saldo);
END;
/

-- salida
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 1, 'SALIDA', 30, 'Prueba', vn_saldo);
    DBMS_OUTPUT.PUT_LINE('Saldo resultante = ' || vn_saldo);
END;
/

-- salida no valida
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 1, 'SALIDA', 500, 'Prueba', vn_saldo);
END;
/

-- salida sin combinacion bodega-producto (ORA-20014)
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 3, 'SALIDA', 1, 'Prueba', vn_saldo);
END;
/

-- entrada que crea la combinacion
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 3, 'ENTRADA', 20, 'Prueba', vn_saldo);
    DBMS_OUTPUT.PUT_LINE('Saldo resultante = ' || vn_saldo);
END;
/

-- ajuste
DECLARE
    vn_saldo NUMBER;
BEGIN
    SP_AJUSTAR_STOCK(1001, 1, 'AJUSTE', 95, 'Prueba', vn_saldo);
    DBMS_OUTPUT.PUT_LINE('Saldo resultante = ' || vn_saldo);
END;
/

ROLLBACK;

------------------------------------------------------------------- 1.3 (3 pts)
-- SP_CREAR_PEDIDO
-- Crea la cabecera de un pedido en estado BORRADOR y devuelve el identificador
-- generado. Debe rechazar clientes inactivos y clientes sin cupo de credito
-- disponible, con mensajes distinguibles entre si.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este procedimiento, se hizo una consulta para obtener si el cliente que esta
haciendo el pedido esta activo o inactivo, y si su saldo disponible le alcanza
para la compra. 

Para validar que el cliente esta inactivo se utilizo la variable "vc_activo" y
se verifico su valor. Para validar si el cliente no tiene cupo disponible, se utilizo 
la variable vn_disponible, si esta daba negativo, significa que no tiene saldo
disponible.

Para dejarel mensaje distinguible se utilizó RAISE_APPLICATION_ERROR en lugar
de imprimir el mensaje debido a que DBMS_OUTPUT.PUT_LINE solo mostraria el mensaje
sin detener el procedimiento, por lo que igualmente llegaria al INSERT con los
datos incorrectos.

*/
CREATE OR REPLACE PROCEDURE SP_CREAR_PEDIDO (
    p_id_cliente  IN  NUMBER,
    p_id_pedido   OUT NUMBER
) IS
    vc_activo      CHAR(1);
    vn_disponible  NUMBER;
BEGIN

    SELECT activo, cupo_credito - saldo_pendiente
    INTO   vc_activo, vn_disponible
    FROM   CLIENTE
    WHERE  id_cliente = p_id_cliente;

    IF vc_activo = 'N' THEN
        RAISE_APPLICATION_ERROR(-20020,
            'El cliente ' || p_id_cliente || ' esta inactivo');
    END IF;

    IF vn_disponible <= 0 THEN
        RAISE_APPLICATION_ERROR(-20021,
            'El cliente ' || p_id_cliente || ' no tiene cupo de credito disponible');
    END IF;

    INSERT INTO PEDIDO (id_pedido, id_cliente, estado)
    VALUES (SEQ_PEDIDO.NEXTVAL, p_id_cliente, 'BORRADOR')
    RETURNING id_pedido INTO p_id_pedido;
    
END SP_CREAR_PEDIDO;
/

-- BLOQUE ANÓNIMO PARA VERIFICAR
DECLARE 
    vn_id_pedido NUMBER;
    
BEGIN

sp_crear_pedido(501, vn_id_pedido); 
DBMS_OUTPUT.PUT_LINE('ID obtenido: ' || vn_id_pedido);
sp_crear_pedido(506, vn_id_pedido); -- inactivo
    
END;
/
ROLLBACK;

DECLARE
    vn_id_pedido NUMBER;
BEGIN

sp_crear_pedido(505, vn_id_pedido); -- sin cupo

END;
/

--==============================================================================
-- PARTE 2 — FUNCIONES                                         (8 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 2.1 (2 pts)
-- FN_STOCK_DISPONIBLE
-- Retorna la cantidad disponible de un producto. Si se indica bodega, devuelve
-- el saldo de esa bodega; si p_id_bodega llega nulo, el consolidado de todas.
-- Un producto inexistente debe retornar cero y no una excepcion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--se realizo una sentencia de control(IF/ELSE), primero se verifica si el id de bodega 
--estaba en null, si es el caso, se calcula el consolidado de todas las bodegas, 
--en caso contrario, se mostrara el saldo de la bodega indicada. Se utilizo NVL(sum(E.cantidad), 0)  
--que permitio sumar todos  la cantidad de todas las filas que cumplen la condición. 
--ya que SUM sin GROUP BY siempre devuelve una sola fila, por lo que no se lanza TOO_MANY_ROWS; 
--ya que si solo se utilizara e.cantidad la consulta podría traer más de una fila (una por bodega) y se
-- lanzaría ese error. Si el producto no existe o no tiene registro en la bodega indicada,
--SUM devuelve NULL y NVL lo convierte en 0. De esta forma no se lanza NO_DATA_FOUND 
--y la función retorna cero, como lo exige el enunciado. Tanto en el IF como en el ELSE, 
--se realizo un where que permitio comparar los parametros recibidos con los valores guardado 
--en la tabla EXISTENCIA, para sumar unicamente las filas del producto (y de la bodega, en el caso del ELSE).

CREATE OR REPLACE FUNCTION FN_STOCK_DISPONIBLE (
    p_id_producto IN NUMBER,
    p_id_bodega   IN NUMBER DEFAULT NULL
) RETURN NUMBER IS

    VN_stock NUMBER := 0;
BEGIN
    IF p_id_bodega IS NULL THEN
        SELECT NVL(SUM(e.cantidad), 0)
          INTO VN_stock
          FROM EXISTENCIA e
         WHERE e.id_producto = p_id_producto;
    ELSE
        SELECT NVL(SUM(e.cantidad), 0)
          INTO VN_stock
          FROM EXISTENCIA e
         WHERE e.id_producto = p_id_producto
           AND e.id_bodega   = p_id_bodega;
    END IF;

    RETURN VN_stock;
END FN_STOCK_DISPONIBLE;
/


------------------------------------------------------------------- 2.2 (2 pts)
-- FN_CUPO_DISPONIBLE
-- Retorna el cupo de credito disponible del cliente, entendido como cupo menos
-- saldo pendiente. Un cliente inactivo retorna cero y el resultado nunca puede
-- ser negativo.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Para realizar el ejercicio se creo cuatro variables tales como vn_cupo, vn_saldo,vn_disponible y vc_activo 
--para guardar los datos del cliente que trae la consulta, ya que el alias de la tabla solo existe dentro del 
--SELECT y el IF necesita leer esos valores despues. Primero se verifica con IF si el cliente esta inactivo se 
--retorna 0, aunque tenga cupo libre no podra ser usarlo. Luego se calcula cupo menos saldo pendiente y se 
--verifica con otro IF si el resultado es negativo, para retornar 0 y el cupo disponible nunca baje de cero.
--Si el cliente no existe, el SELECT INTO lanza NO_DATA_FOUND. Se captura en el bloque EXCEPTION y se retorna 0 
--para que la funcion capture el error no se propague a quien llama la función


CREATE OR REPLACE FUNCTION FN_CUPO_DISPONIBLE (
    p_id_cliente IN NUMBER
) RETURN NUMBER IS
    vn_cupo       NUMBER;
    vn_saldo      NUMBER;
    vn_disponible NUMBER;
    vc_activo     CHAR(1);
BEGIN
    SELECT c.cupo_credito, c.saldo_pendiente, c.activo
      INTO vn_cupo, vn_saldo, vc_activo
      FROM CLIENTE c
     WHERE c.id_cliente = p_id_cliente;

    IF vc_activo = 'N' THEN
        RETURN 0;
    END IF;

    vn_disponible := vn_cupo - vn_saldo;

    IF vn_disponible < 0 THEN
        RETURN 0;
    END IF;

    RETURN vn_disponible;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END FN_CUPO_DISPONIBLE;
/


------------------------------------------------------------------- 2.3 (3 pts)
-- FN_CALCULAR_DESCUENTO
-- Retorna el VALOR en pesos del descuento aplicable, segun estas reglas
-- acumulables:
--     Monto mayor o igual a 2.000.000 ................. 8%
--     Monto entre 800.000 y 1.999.999 ................. 5%
--     Monto menor a 800.000 ........................... 0%
--     Adicional si el cliente no tiene saldo pendiente . 2%
--     Tope maximo acumulado ........................... 10%
-- La funcion retorna el valor del descuento, no el porcentaje.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Segun como se indica en el enunciado estas reglas son acumulables, es por ello que se creo 
--la variable vn_pct que se almacena la suma de los porcentajes,y se calcula el valor del pesos 
--al final; Al aplicar cada descuento sobre el monto ya descontado daria un resultado distinto.
--El porcentaje por monto se resuleve con IF/ELSIF ordenado de mayor a menor, se utiliza 
-->= 2000000 y >= 800000 porque cada monto pertenece a un solo rango (8%, 5% o 0%).
--El 2% adicional depende de que el cliente no tenga saldo pendiente, dato que no llega por 
--parámetro, se consulta CLIENTE por su clave primaria. Se aplica aunque el monto sea menor a 800000, 
--porque el enunciado lo define como adicional.
--LEAST(vn_pct, 10) aplica el tope. Con las reglas actuales el maximo posible es 8 + 2 = 10, asi que 
--hoy el tope no recorta nada; se deja explicito para que siga siendo correcto si se agregan rango nuevos.
--Un cliente inexistente (NO_DATA_FOUND) o un monto nulo o no positivo retornan 0, para no propagar errores, 
--igual que las otras funciones.
--La funcion retorna el VALOR en pesos (monto * porcentaje / 100), redondeado a 2 decimales, 
--que es la precision de las columnas de dinero del esquema.

CREATE OR REPLACE FUNCTION FN_CALCULAR_DESCUENTO (
    p_id_cliente IN NUMBER,
    p_monto      IN NUMBER
) RETURN NUMBER IS
vn_pct    NUMBER := 0;
    vn_saldo  NUMBER;
BEGIN
    IF p_monto IS NULL OR p_monto <= 0 THEN
        RETURN 0;
    END IF;

    IF p_monto >= 2000000 THEN
        vn_pct := 8;
    ELSIF p_monto >= 800000 THEN
        vn_pct := 5;
    ELSE
        vn_pct := 0;
    END IF;

    SELECT c.saldo_pendiente
      INTO vn_saldo
      FROM CLIENTE c
     WHERE c.id_cliente = p_id_cliente;

    IF vn_saldo = 0 THEN
        vn_pct := vn_pct + 2;
    END IF;

    vn_pct := LEAST(vn_pct, 10);

    RETURN ROUND(p_monto * vn_pct / 100, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END FN_CALCULAR_DESCUENTO;
/

------------------------------------------------------------------- 2.4 (1 pt)
-- Escriba una consulta que liste los clientes activos con su cupo disponible,
-- usando la funcion del punto 2.2, ordenados de mayor a menor.
-- Explique por que una funcion definida por el usuario puede invocarse desde
-- una sentencia SQL y que restriccion debe cumplir para poder hacerlo.
-------------------------------------------------------------------------------
-- RESPUESTA:
--
-- SELECT ...
SELECT c.id_cliente,
       c.nombre,
       FN_CUPO_DISPONIBLE(c.id_cliente) AS cupo_disponible
  FROM CLIENTE c
 WHERE c.activo = 'S'
 ORDER BY cupo_disponible DESC;

--Una funcion puede llamarse desde SQL por que el motor lo trata como una expresion 
--mas; por cada fila que procesa, evalua la funcion con los valores de esa fila, 
--por tal motivo se utilizo (c.id_cliente) para el parametro de la funcion, y usa 
--el valor retornado como si fuera una columna por eso puede ir en el SELECT, WHERE o ORDER BY

--Restricciones: la funcion no puede modificar la base de datos cuando se llama 
--desde una sentencia SELECT. No puede ejecutar INSERT, UPDATE, DELETE ni DDL. 
--Si lo hace, Oracle lanza un error (ORA-14551). Ademas, solo debe tener parametros IN 
--y retornar un tipo de dato SQL (NUMBER, VARCHAR2, DATE...), no tipos exclusivos de 
--PL/SQL como BOOLEAN. FN_CUPO_DISPONIBLE cumple todo esto porque solo lee CLIENTE, 
--no modifica nada y retorna NUMBER.
--==============================================================================
-- PARTE 3 — CURSORES                                         (10 puntos / 90 min)
--==============================================================================

------------------------------------------------------------------- 3.1 (2 pts)
-- Bloque anonimo que recorra, con un CURSOR EXPLICITO, los productos cuyo stock
-- consolidado este por debajo del stock minimo, e imprima un reporte con codigo,
-- nombre, stock actual, stock minimo y unidades faltantes, mas el total de
-- productos en esa condicion.
-- Debe usar OPEN, FETCH y CLOSE de forma explicita. El ciclo FOR implicito no se
-- acepta en este punto.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Se usa cursor explicito porque el ejercicio pide controlar open, fetch y close.
-- Esto permite contar las filas una por una y saber cuando se agota el cursor
-- con %notfound, algo que el for implicito esconde. La vista v_stock_consolidado
-- ya trae el stock sumado de todas las bodegas, asi que el filtro es directo.


DECLARE
   cursor c_bajo_stock is
        select codigo, producto, stock_total, stock_minimo,
               stock_minimo - stock_total as faltante
        from   v_stock_consolidado
        where  stock_total < stock_minimo
        order by faltante desc;

    vv_codigo    varchar2(20);
    vv_nombre    varchar2(100);
    vn_actual    number;
    vn_minimo    number;
    vn_faltante  number;
    vn_total     number := 0;
BEGIN
    dbms_output.put_line('reporte de productos bajo stock minimo');
    dbms_output.put_line('--------------------------------------');

    open c_bajo_stock;
    loop
        fetch c_bajo_stock into vv_codigo, vv_nombre, vn_actual, vn_minimo, vn_faltante;
        exit when c_bajo_stock%notfound;

        dbms_output.put_line(vv_codigo || ' | ' || vv_nombre ||
                             ' | actual: ' || vn_actual ||
                             ' | minimo: ' || vn_minimo ||
                             ' | faltan: ' || vn_faltante);
        vn_total := vn_total + 1;
    end loop;
    close c_bajo_stock;

    dbms_output.put_line('--------------------------------------');
    dbms_output.put_line('total productos en condicion: ' || vn_total);
END;
/

------------------------------------------------------------------- 3.2 (2 pts)
-- Bloque anonimo con un CURSOR PARAMETRIZADO que reciba identificador de cliente
-- y un rango de fechas, y muestre los pedidos CONFIRMADOS de ese cliente en ese
-- rango, con su total y la cantidad de lineas de cada pedido.
-- Pruebelo con el cliente 501 entre 2026-01-01 y 2026-12-31.
-- Los parametros deben declararse en el cursor, no tomarse del alcance del bloque.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El cursor recibe cliente y rango de fechas como parametros propios, no los
-- toma del bloque. Asi el mismo cursor se puede reabrir con otros valores sin
-- recompilarlo. El left join con detalle_pedido permite contar las lineas de
-- cada pedido aunque no tenga detalle.

DECLARE
   cursor c_pedidos (p_cliente in number, p_ini in date, p_fin in date) is
        select p.id_pedido, p.fecha_pedido, p.total,
               count(d.linea) as lineas
        from   pedido p
               left join detalle_pedido d on d.id_pedido = p.id_pedido
        where  p.id_cliente = p_cliente
        and    p.estado = 'CONFIRMADO'
        and    p.fecha_pedido between p_ini and p_fin
        group by p.id_pedido, p.fecha_pedido, p.total
        order by p.fecha_pedido;

    vn_id      number;
    vd_fecha   date;
    vn_total   number;
    vn_lineas  number;
    vn_suma    number := 0;
BEGIN
    dbms_output.put_line('pedidos confirmados cliente 501 - 2026');

    open c_pedidos(501, to_date('2026-01-01','yyyy-mm-dd'),
                        to_date('2026-12-31','yyyy-mm-dd'));
    loop
        fetch c_pedidos into vn_id, vd_fecha, vn_total, vn_lineas;
        exit when c_pedidos%notfound;

        dbms_output.put_line('pedido ' || vn_id ||
                             ' | ' || to_char(vd_fecha,'yyyy-mm-dd') ||
                             ' | lineas: ' || vn_lineas ||
                             ' | total: ' || vn_total);
        vn_suma := vn_suma + vn_total;
    end loop;
    close c_pedidos;

    dbms_output.put_line('suma total: ' || vn_suma);
END;
/

------------------------------------------------------------------- 3.3 (3 pts)
-- Bloque anonimo con un CURSOR FOR UPDATE que recorra los productos de una
-- categoria y ajuste su precio un porcentaje dado, usando WHERE CURRENT OF.
--   * No debe modificar productos inactivos
--   * El precio resultante no puede quedar por debajo del costo mas el margen
--     minimo de la categoria
-- Explique que bloqueo genera FOR UPDATE, cuanto dura, y por que WHERE CURRENT OF
-- es preferible a un UPDATE por clave primaria.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El for update bloquea cada fila leida con un lock exclusivo de fila, y ese
-- bloqueo dura hasta el commit o rollback, no hasta el close. Por eso se usa
-- where current of: actualiza exactamente la fila que el cursor tiene
-- posicionada y ya bloqueada. Un update por llave primaria obligaria a buscar
-- la fila otra vez y abriria una ventana para que otra sesion la modifique
-- entre el fetch y el update.

DECLARE
    vn_categoria  number := 2;
    vn_pct        number := 10;

    cursor c_productos is
        select p.id_producto, p.codigo, p.nombre, p.precio_unitario,
               p.costo_unitario, p.activo, c.margen_minimo
        from   producto p
               join categoria c on c.id_categoria = p.id_categoria
        where  p.id_categoria = vn_categoria
        for update of p.precio_unitario nowait;

    vn_id       number;
    vv_codigo   varchar2(20);
    vv_nombre   varchar2(100);
    vn_precio   number(12,2);
    vn_costo    number(12,2);
    vc_activo   char(1);
    vn_margen   number(5,2);
    vn_nuevo    number(12,2);
    vn_piso     number(12,2);
    vn_ok       number := 0;
    vn_omitidos number := 0;
BEGIN
    open c_productos;
    loop
        fetch c_productos into vn_id, vv_codigo, vv_nombre, vn_precio,
                               vn_costo, vc_activo, vn_margen;
        exit when c_productos%notfound;

        if vc_activo = 'N' then
            vn_omitidos := vn_omitidos + 1;
            continue;
        end if;

        vn_nuevo := round(vn_precio * (1 + vn_pct/100), 2);
        vn_piso  := round(vn_costo * (1 + vn_margen/100), 2);

        if vn_nuevo < vn_piso then
            dbms_output.put_line('omitido ' || vv_codigo ||
                                 ': nuevo ' || vn_nuevo ||
                                 ' < piso ' || vn_piso);
            vn_omitidos := vn_omitidos + 1;
        else
            update producto
            set    precio_unitario = vn_nuevo
            where  current of c_productos;

            dbms_output.put_line('ok ' || vv_codigo ||
                                 ': ' || vn_precio || ' -> ' || vn_nuevo);
            vn_ok := vn_ok + 1;
        end if;
    end loop;
    close c_productos;

    dbms_output.put_line('actualizados: ' || vn_ok ||
                         ' | omitidos: ' || vn_omitidos);
    commit;
exception
    when others then
        if c_productos%isopen then close c_productos; end if;
        rollback;
        dbms_output.put_line('error: ' || sqlerrm);
        raise;
END;
/

------------------------------------------------------------------- 3.4 (2 pts)
-- SP_LISTAR_MOVIMIENTOS
-- Procedimiento que reciba un identificador de producto y devuelva un
-- SYS_REFCURSOR con los movimientos de inventario de ese producto, ordenados
-- por fecha. Incluya un bloque anonimo que consuma el cursor devuelto y lo cierre.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El procedimiento necesita devolver un conjunto de filas al llamador, y un
-- cursor explicito normal solo vive dentro de su bloque. El sys_refcursor es
-- un puntero que se puede pasar como parametro out y consumir afuera. Ademas
-- permite encapsular la consulta en una capa de negocio sin exponer la tabla.

CREATE OR REPLACE PROCEDURE SP_LISTAR_MOVIMIENTOS (
    p_id_producto IN  NUMBER,
    p_cursor      OUT SYS_REFCURSOR
) IS
BEGIN
    open p_cursor for
        select m.id_movimiento, m.fecha_mov, m.tipo, m.cantidad,
               b.nombre as bodega, m.id_pedido, m.observacion
        from   movimiento_inventario m
               join bodega b on b.id_bodega = m.id_bodega
        where  m.id_producto = p_id_producto
        order by m.fecha_mov, m.id_movimiento;

END SP_LISTAR_MOVIMIENTOS;
/
-- Bloque consumidor:
DECLARE
   v_cursor   sys_refcursor;
    vn_id       number;
    vd_fecha    date;
    vv_tipo     varchar2(10);
    vn_cant     number;
    vv_bodega   varchar2(60);
    vn_pedido   number;
    vv_obs      varchar2(200);
    vn_total    number := 0;
BEGIN
   sp_listar_movimientos(1001, v_cursor);

    loop
        fetch v_cursor into vn_id, vd_fecha, vv_tipo, vn_cant,
                            vv_bodega, vn_pedido, vv_obs;
        exit when v_cursor%notfound;

        dbms_output.put_line(vn_id || ' | ' || to_char(vd_fecha,'yyyy-mm-dd') ||
                             ' | ' || vv_tipo || ' | ' || vn_cant ||
                             ' | ' || vv_bodega || ' | ' || nvl(vv_obs,'-'));
        vn_total := vn_total + 1;
    end loop;
    close v_cursor;

    dbms_output.put_line('total movimientos: ' || vn_total);
END;
/

------------------------------------------------------------------- 3.5 (1 pt)
-- Bloque anonimo que cargue con BULK COLLECT los productos de una categoria en
-- una coleccion y use FORALL para actualizar su stock minimo.
-- Explique que costo concreto elimina esta tecnica y a partir de que volumen
-- empieza a notarse.
-------------------------------------------------------------------------------
-- JUSTIFICACION: 
-- bulk collect y forall eliminan el cambio de contexto entre sql y pl/sql.
-- Sin esto, cada fila del ciclo implica un viaje de ida y vuelta entre los dos
-- motores. Con bulk collect todas las filas vienen en un solo viaje, y con
-- forall todos los update salen en un solo viaje. La ganancia se nota a partir
-- de unos cientos de filas; con miles la diferencia es grande. Aqui se usa
-- limit en el bulk collect por buena practica, aunque la categoria tenga pocos
-- productos.

DECLARE
     vn_categoria  number := 1;
    vn_minimo     number := 30;

    type t_ids is table of producto.id_producto%type index by pls_integer;
    type t_min is table of producto.stock_minimo%type index by pls_integer;

    v_ids    t_ids;
    v_mins   t_min;
    v_filas  number := 0;
BEGIN
     select id_producto, stock_minimo
    bulk collect into v_ids, v_mins
    from producto
    where id_categoria = vn_categoria
    and   activo = 'S';

    dbms_output.put_line('productos cargados: ' || v_ids.count);

    if v_ids.count > 0 then
        forall i in 1 .. v_ids.count
            update producto
            set    stock_minimo = vn_minimo
            where  id_producto = v_ids(i);

        v_filas := sql%rowcount;
        dbms_output.put_line('filas actualizadas: ' || v_filas);
    end if;

    commit;
exception
    when others then
        rollback;
        dbms_output.put_line('error: ' || sqlerrm);
        raise;
END;
/

--==============================================================================
-- PARTE 4 — MANEJO DE EXCEPCIONES                             (9 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 4.1 (2 pts)
-- FN_PRECIO_PRODUCTO
-- Funcion que reciba el CODIGO de un producto y retorne su precio, manejando
-- explicitamente NO_DATA_FOUND y TOO_MANY_ROWS, con retorno de -1 y -2
-- respectivamente, e imprimiendo un mensaje descriptivo en cada caso.
-- Explique en que situacion real se produciria TOO_MANY_ROWS sobre esta tabla,
-- considerando las restricciones que hoy tiene.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
En esta funcion se pude manejar dos excepciones, ambas se manejaron con una
consulta, de la cual guardamos el precio en la variable "vn_precio", para que esto
sea posible, el SELECT debe devolver exactamente una fila, si no devuelve ninguna
obtendriamos el error NO_DATA_FOUND, y si devuelve mas de una fila, obtendriamos
el error TOO_MANY_ROWS.

Para manejarlos y devolver el respectivo valor de vn_precio, en la clausula 
EXCEPTION se validaron ambos errores, cambiandole el valor del precio e imprimiendo
un mensaje explicando lo que sucedió

NOTA: Para que salga el error TOO_MANY_ROWS ocurriria si la restriccion del
UNIQUE en la columna "uk_producto_codigo" en la tabla PRODUCTOS se deshabilitara,
lo que permitiria que hubieran codigos repetidos.
*/
CREATE OR REPLACE FUNCTION FN_PRECIO_PRODUCTO (
    p_codigo IN VARCHAR2
) RETURN NUMBER IS
    vn_precio NUMBER;
BEGIN
    SELECT p.precio_unitario
    INTO vn_precio
    FROM producto p
    WHERE p.codigo = p_codigo;
    
    RETURN vn_precio;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        vn_precio := -1;
        DBMS_OUTPUT.PUT_LINE('No se ha encontrado el producto con codigo ' || p_codigo);
        RETURN vn_precio;
    WHEN TOO_MANY_ROWS THEN
        vn_precio := -2;
        DBMS_OUTPUT.PUT_LINE('Se han encontrado muchos productos con el codigo ' || p_codigo);
        RETURN vn_precio;
        
    
END FN_PRECIO_PRODUCTO;
/

-- BLOQUE ANÓNIMO PARA VERIFICAR

DECLARE
    vn_precio NUMBER;
BEGIN

vn_precio := fn_precio_producto('HM-0004'); -- existe
DBMS_OUTPUT.PUT_LINE('El precio total: ' || vn_precio);

vn_precio := fn_precio_producto('HM-0005'); -- No existe
DBMS_OUTPUT.PUT_LINE('El precio total: ' || vn_precio);
    
END;
/


------------------------------------------------------------------- 4.2 (2 pts)
-- SP_VALIDAR_DESPACHO
-- Procedimiento que verifique si puede despacharse una cantidad de un producto
-- desde una bodega. Debe declarar una EXCEPCION PROPIA, levantarla con RAISE
-- cuando la cantidad solicitada supere el disponible, y capturarla en el bloque
-- EXCEPTION.
-- Argumente por que conviene nombrar esa condicion en lugar de resolverla con un
-- condicional.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este procedimiento se pedia utilizar una excepcion propia, lo cual se hizo
declarando "e_stock_bajo EXCEPTION", donde más adelante se levantó con un RAISE 
cuando se descubre que la cantidad que se esta solicitando es mayor a la cantidad
disponible. De igual forma esta excepcion se manejo en la seccion EXCEPTION,
en donde, con el nombre definiido, se puso el mensaje explicando lo que paso.

Por otro lado, en la consulta se utilizó NVL() para asi poder controlar el hecho de
que una combinación no tenga existencias disponibles (lo cual devolveria una cantidad
de NULL) tenga como valor 0, logrando entrar a la misma excepion de que no hay
stock suficiente.

En esta ocasión nos conviene nombrar la condicion porque nos ayuda a tener un
error mas "personalizado", ya que en teoria que la cantidad sea mayor a la
cantidad disponible no es un error que Oracle reportaria, pero nosotros si
lo necesitamos.
*/
CREATE OR REPLACE PROCEDURE SP_VALIDAR_DESPACHO (
    p_id_producto IN NUMBER,
    p_id_bodega   IN NUMBER,
    p_cantidad    IN NUMBER
) IS
    
    e_stock_bajo EXCEPTION;
    vn_cant_disponible NUMBER;
    
BEGIN
    
    SELECT NVL(SUM(cantidad), 0)
    INTO vn_cant_disponible
    FROM existencia
    WHERE id_producto = p_id_producto
    AND id_bodega = p_id_bodega;
    
    IF p_cantidad > vn_cant_disponible THEN
        RAISE e_stock_bajo;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('El despacho es posible. Se piden ' || p_cantidad || ' de ' || vn_cant_disponible);
    
EXCEPTION

    WHEN e_stock_bajo THEN
    DBMS_OUTPUT.PUT_LINE('El despacho no es posible. Se piden ' || p_cantidad || ' de ' || vn_cant_disponible);
    
END SP_VALIDAR_DESPACHO;
/

-- BLOQUE ANÓNIMO PARA VERIFICAR

BEGIN 
    sp_validar_despacho(1001, 1, 90);
    sp_validar_despacho(1002, 1, 90);
    sp_validar_despacho(1002, 2, 90); -- No existe
END;
/
------------------------------------------------------------------- 4.3 (2 pts)
-- SP_ANULAR_PEDIDO
-- Procedimiento que anule un pedido, usando RAISE_APPLICATION_ERROR con estos
-- codigos:
--     -20010  el pedido no existe
--     -20011  el pedido ya esta anulado
--     -20012  el pedido tiene mas de 30 dias
-- Explique la diferencia entre RAISE y RAISE_APPLICATION_ERROR, y en que caso el
-- cliente de la base de datos puede distinguirlos.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este procedimiento se piden 3 validaciones antes de poder anular un pedido:

- EL PEDIDO NO EXISTE: Para manejar esto, nos apoyamos del error "NO_DATA_FOUND"
  que saldria como consecuencia de que en la primera consulta no se obtuviera
  ninguna fila para asignarle valores a las dos variables definidas.

- EL PEDIDO YA ESTA ANULADO: Para manejar esto, se hizo uso de la variable
  "vn_estado". Si este estado aparece con el valor de "ANULADO", sabemos que
  este pedido ya fue anulado anteriormente.
  
- EL PEDIDO TIENE MAS DE 30 DIAS: Para manejar esto, se utilizo la variable
    "vn_hace_cuanto" la cual es una variable que almacena el resultado de dias
    que han pasado desde la fecha actual (SYSDATE) hasta la fecha en la que fue
    realizado el pedido, si este da más de 30 dias, saldra el mensaje correspondiente.

Para el manejor de errores con los codigos que se especifican en el ejercicio,
se utilizo RAISE_APPLICATION_ERROR, donde se pudo especificar el codigo -20011
para un pedido anulado, -20012 para un pedido que fue realizado hace mas de 30
dias y -20010 para un pedido que no existe.

La diferencia entre RAISE Y RAISE_APPLICATION_ERROR es que RAISE levanta una
excepción que ya existe (ya sea de Oracle o una propia), y no permite poner mensajes
por si solo. En cambio, RAISE_APPLICATION_ERROR crea un error nuevo con un
codigo entre -2000 y -20999 y un mensaje "propio". Por eso, una expecion propia
con RAISE llega al cliente como un ORA-06510 generico, mientras que con
RAISE_APPLICATION_ERROR el cliente recibe el codigo y el texto.
*/
CREATE OR REPLACE PROCEDURE SP_ANULAR_PEDIDO (
    p_id_pedido IN NUMBER
) IS
    vd_fecha DATE;
    vv_estado VARCHAR2(15);
    vn_hace_cuanto NUMBER;
    
BEGIN
    SELECT fecha_pedido,
           estado
    INTO vd_fecha,
         vv_estado
    FROM pedido
    WHERE id_pedido = p_id_pedido;
    
    vn_hace_cuanto := TRUNC(SYSDATE - vd_fecha);
    
    IF vv_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20011, 'El pedido ya esta anulado');
    
    ELSIF vn_hace_cuanto > 30 THEN
        RAISE_APPLICATION_ERROR(-20012, 'El pedido tiene más de 30 dias');
    END IF;
    
    UPDATE pedido
    SET estado = 'ANULADO'
    WHERE id_pedido = p_id_pedido;
    DBMS_OUTPUT.PUT_LINE('Pedido anulado');

EXCEPTION
    
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'El pedido no existe');
        
END SP_ANULAR_PEDIDO;
/

-- BLOQUES ANONIMOS PARA VERIFICAR

BEGIN
    sp_anular_pedido(1); -- Mas de 30 dias

END;
/

BEGIN
    sp_anular_pedido(6); -- Menos de 30 dias
END;
/
ROLLBACK;

BEGIN
    sp_anular_pedido(7); -- Ya esta anulado
    
END;
/

BEGIN
    sp_anular_pedido(8); -- No extiste
END;
/
------------------------------------------------------------------- 4.4 (2 pts)
-- Bloque anonimo que intente insertar un producto con una categoria inexistente
-- y capture el error de integridad referencial asociando ORA-02291 a una
-- excepcion con nombre.
-- Explique que aporta esa asociacion frente a atrapar el error en un manejador
-- generico.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este bloque anonimo se utilizó nuevamente una excepcion propia llamada
"e_categoria_no_encontrada", que, como dice el nombre, sirve para no permitir
que se inserte un producto a una categoria que no existe.

En esta ocasión se añadio "PRAGMA EXCEPTION_INIT", el cual esta diciendole a
Oracle que cuando se lance el error -2291 (el cual corresponde a cuando se
intenta insertar un registro en una tabla hija utilizando la llave foranea
que no existe en la tabla padre), active la excepcion "e_categoria_no_encintrada".

Al utilizar un manejador generico como WHEN OTHERS se controlan errores pero no
se identifica exactamente cual, en cambio al usar una excepcion propia para
darle nombre a una excepcion ya existente, ayuda a poder agregar esto de manera
especifica en el EXCEPTION y poder dar un mensaje mas exacto de lo que realmente
sucedio.
*/
DECLARE
    e_categoria_no_encontrada EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_categoria_no_encontrada, -2291);
BEGIN
    
    INSERT INTO PRODUCTO VALUES (2000, 'TS-0100', 'Arroz', 15, 75000, 80000, 6, 'S');
    
EXCEPTION
        WHEN e_categoria_no_encontrada THEN
            DBMS_OUTPUT.PUT_LINE('La categoria no existe');
END;
/

ROLLBACK;

------------------------------------------------------------------- 4.5 (1 pt)
-- SP_REGISTRAR_ERROR
-- Procedimiento que reciba el origen y registre en LOG_ERRORES el SQLCODE y el
-- SQLERRM actuales. El registro debe persistir aunque la transaccion principal
-- termine en ROLLBACK.
-- Explique por que se requiere esa independencia transaccional y describa un
-- escenario en el que esa misma independencia oculte informacion en lugar de
-- preservarla.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
/*
Para este procedimiento se utilizó "PRAGMA AUTNOMOUS_TRANSACTION", esto hace que
el INSERT en la tabla LOG_ERRORES se confirme aparte con su propio commit, siendo
independiente de la transacción que llama.

En este ejercicio se requiere la independencia transaccional debido a que un
error suele hacer un ROLLBACK "automatico", y si el log fuera parte de la transacción,
el registro no persistira.

Por otro lado, SQLCODE y SQLERRM se almacenan en las variables "vn_codigo" y
"vv_mensaje" respectivamente antes del INSERT para que asi, ellos tambien se puedan
agregar al registro.

Un escenario en el que la independencia ocultaria la informacion seria se registra 
un error, se hace ROLLBACK y luego el proceso se reintenta y termina bien; el log 
conserva un fallo que no dejo cambios y quien lo lea puede creer que hay datos 
inconsistentes.
*/
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_ERROR (
    p_origen  IN VARCHAR2,
    p_detalle IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    vn_codigo  NUMBER;
    vv_mensaje VARCHAR2(500);
BEGIN
    vn_codigo  := SQLCODE;
    vv_mensaje := SUBSTR(SQLERRM, 1, 500);

    INSERT INTO LOG_ERRORES (id_log, origen, codigo_error, mensaje, detalle)
    VALUES (SEQ_LOG.NEXTVAL, p_origen, vn_codigo, vv_mensaje,
            SUBSTR(p_detalle, 1, 500));

    COMMIT;
END SP_REGISTRAR_ERROR;
/

-- BLOQUE PARA VERIFICAR

SET SERVEROUTPUT ON SIZE UNLIMITED

BEGIN
    INSERT INTO PRODUCTO VALUES (2000, 'TS-9999', 'Prueba', 99, 50000, 30000, 5, 'S');
EXCEPTION
    WHEN OTHERS THEN
        SP_REGISTRAR_ERROR('PRUEBA_4_5', 'Categoria 99 inexistente');
        ROLLBACK;
END;
/

-- Verificar que el registro persiste a pesar del ROLLBACK
SELECT id_log, origen, codigo_error, mensaje, detalle
FROM   LOG_ERRORES
WHERE  origen = 'PRUEBA_4_5';


--==============================================================================
-- PARTE 5 — DISPARADORES                                     (10 puntos / 90 min)
--==============================================================================
-- Los esqueletos de esta parte no incluyen la clausula de disparo. Definirla
-- hace parte del ejercicio.
--==============================================================================

------------------------------------------------------------------- 5.1 (2 pts)
-- TRG_CLIENTE_BI
-- Al insertar un cliente debe asignar el identificador desde SEQ_CLIENTE si
-- llega nulo, convertir el nombre a mayusculas sin espacios sobrantes y forzar
-- el estado activo a 'S' si no se indica.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Según el enunciado se identificó que se debía trabajar con un evento BEFORE INSERT. 
--Esto Se debe a que necesitamos evaluar y modificar los valores de la fila en tránsito 
--antes de que se guarden permanentemente en la base de datos.

--para lograrlo, se utiliza :NEW, siendo este una palabra clave reservada en el lenguaje 
--PL/SQL de Oracle, esto funciona como una "tabla virtual" temporal que contiene los datos 
--que están a punto de entrar a la base de datos; también debe tener ":" al inicio del new, 
--esto es para modificar o leer sus variables;  si se coloca el "new" sin los dos puntos(":") 
--Oracle lanzará un error

--Si al momento de insertar el cliente el usuario no especifica un identificador, 
--el trigger lo genera dinámicamente.  Para esto, la secuencia SEQ_CLIENTE debe estar 
--previamente creada en la base de datos, ya que los triggers solo permiten ejecutar 
--lógica de programación y manipulación de datos (DML), no permite DDL dentro de este.
--Se utiliza el condicional IF con :NEW.id_cliente IS NULL, esto invoca la propiedad .NEXTVAL
--que significa "Siguiente Valor"  al hacer eso se está dando una orden directa a la secuencia, 
--generando el proximo numero; ese numero generado se va almacenar y guardar en :NEW.id_cliente 
--y de tal manera genera el identificador del nuevo cliente.

--Se aplica las funciones anidadas UPPER(TRIM(:NEW.nombre)) de manera obligatoria en cada inserción
--para estandarizar el formato del texto en la base de datos, eliminando los espacios en blanco 
--basura al inicio o final del texto y previniendo problemas en futuras búsquedas por diferencias 
--entre mayúsculas y minúsculas.

--Finalmente, se evalúa :NEW.activo IS NULL para establecer un estado por defecto ('S') en la lógica 
--del negocio, asegurando que todo nuevo cliente nazca habilitado en el sistema a menos que se 
--especifique lo contrario de forma explícita en el comando de inserción .



CREATE OR REPLACE TRIGGER TRG_CLIENTE_BI
BEFORE INSERT ON CLIENTE 
FOR EACH ROW 
BEGIN
    
    IF :NEW.id_cliente IS NULL THEN
        :NEW.id_cliente := SEQ_CLIENTE.NEXTVAL;
       
    END IF;
    :NEW.nombre := UPPER(TRIM(:NEW.nombre));
    IF :NEW.ACTIVO IS NULL THEN 
        :NEW.ACTIVO := 'S';
    END IF;
END;
/
    
 DROP SEQUENCE SEQ_CLIENTE;
CREATE SEQUENCE SEQ_CLIENTE START WITH 508 INCREMENT BY 1 NOCACHE;   

INSERT INTO CLIENTE VALUES (NULL, '900890123', '   ingenieria del pacifico sas   ', 'Cali', 4000000, 0, NULL);

SELECT * FROM CLIENTE WHERE documento = '900890123';
------------------------------------------------------------------- 5.2 (2 pts)
-- TRG_PRODUCTO_AU_PRECIO
-- Debe registrar en AUDITORIA_PRECIO todo cambio de precio, calculando la
-- variacion porcentual, y dispararse unicamente cuando el precio efectivamente
-- cambie, resolviendo esa condicion con la clausula WHEN y no dentro del cuerpo.
-- Explique la diferencia entre ambas formas.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Como se menciona en el enunciado,  el trigger se debe disparar únicamente si el valor 
--del precio cambia efectivamente y tal como se menciona se debe usar la cláusula WHEN. 
--Esto permite validar desde la estructura si los valores son diferentes, para que así 
--pueda ejecutar la lógica del cuerpo.
-- Luego, dentro del bloque BEGIN, se valida si el valor del precio anterior es mayor a 0. 
--Esto es indispensable debido a que la fórmula de variación porcentual requiere dividir 
--entre el precio antiguo; sie este llega a ser 0, Oracle lanzará un error crítico de 
--división por cero (ORA-01476). Si este cumple la condición se inserta en la tabla 
--AUDITOIA_PRICE para agregar los valores con el cálculo de la variación porcentual. 
--En caso contrario, si este llega a ser 0 solo se añade los valores del precio antiguo 
--y nuevo, añadiendo 0 en el cálculo de la variación porcentual para evitar el error anteriormente mencionado.

--Diferencia entre ambas formas: 
--Cláusula WHEN: válida la condición antes de activar el trigger, si los precios son iguales,
--el trigger ni siquiera se ejecuta. De esta manera no gasta memoria, recursos, ni tiempo 
--de procesamiento, siendo la forma más rápida y óptima para el servidor. 
--Con la sentencia IF interna: El motor de la base de datos se ve obligado a activar el trigger,  
--por lo que reserva memoria en el servidor, carga las variables, y una vez dentro del BEGIN, 
--lee el if para validar si es que los precios son iguales o no debería hacer nada. 
--Esto genera un consumo innecesario de recursos (overhead) en el servidor ante actualizaciones masivas.

CREATE SEQUENCE SEQ_AUDITORIA_PRECIO START WITH 1 INCREMENT BY 1;
 
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_AU_PRECIO
BEFORE UPDATE ON PRODUCTO
FOR EACH ROW
WHEN (OLD.precio_unitario <> NEW.precio_unitario)
BEGIN
   IF :OLD.precio_unitario > 0 THEN
        INSERT INTO AUDITORIA_PRECIO (id_auditoria, id_producto, precio_anterior, precio_nuevo, variacion_pct)
        VALUES (SEQ_AUDITORIA_PRECIO.NEXTVAL, :OLD.id_producto, :OLD.precio_unitario, :NEW.precio_unitario,
                ((:NEW.precio_unitario - :OLD.precio_unitario) / :OLD.precio_unitario) * 100);
    ELSE
        INSERT INTO AUDITORIA_PRECIO (id_auditoria, id_producto, precio_anterior, precio_nuevo, variacion_pct)
        VALUES (SEQ_AUDITORIA_PRECIO.NEXTVAL, :OLD.id_producto, :OLD.precio_unitario, :NEW.precio_unitario, 0);
    END IF;
END;
/
SELECT id_producto, nombre, precio_unitario FROM PRODUCTO; 
--Se realizo el cambio del precio para verificar el trigger--
UPDATE PRODUCTO
SET precio_unitario = precio_unitario * 1.10   
WHERE id_producto = 1001;
--Se actualizo otro producto dejando el mismo precio que tenia para verificar que el trigger no se haya ejecutado
UPDATE PRODUCTO
SET precio_unitario = precio_unitario  
WHERE id_producto = 1002;

SELECT * FROM AUDITORIA_PRECIO ORDER BY id_auditoria DESC;
------------------------------------------------------------------- 5.3 (2 pts)
-- TRG_PRODUCTO_BIU_MARGEN
-- Debe impedir que se guarde un producto cuyo precio no alcance el margen minimo
-- de su categoria, segun la formula precio >= costo * (1 + margen/100),
-- rechazando la operacion con el error -20020.
-- Considere que debe ocurrir cuando la categoria indicada no existe, y justifique
-- su decision.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--El trigger se define bajo los eventos de INSERT y UPDATE para garantizar la 
--consistencia de los precios, tanto al registar un producto nuevo como al modificar uno exietente.

-- Se detemina que si la categoria indicada no existe en el sistema, el trigger capturara 
--la excepcion obligatoria NO_DATA_FOUND propia del motor de Oracle. Se tomo la desicion 
--de asignarle dinamicamente un margen de contigencia de 10, basándonos en que este valor 
--fue el considerado en la creación de la tabla CATEGORIA como valor por defecto, es por ello, 
--que se hizo de esta manera para aseguarar que el sistema no se detenga por un error.

--Finalmente, al tener que comparar tanto un campo de la fila actual con un campo de otra tabla, 
--se creo una varible que permitia traer el valor de la tabla CATEGORIA, para luego compararla 
--con la condicion usando la formula del enunciado. De esta manera, requerido, la operación 
--será rechazada lanzando el error personalizado -20020).

--Se evidencia el uso de bloques anidados debido a que se debia controlar especificamente 
--el error del NO_DATA_FOUND. Como las excepciones en PL/SQL siempre deben ir al final 
--de un bloque, si no aisláramos la consulta en su propio subbloque, la excepción 
--anularía o no capturaría correctamente la lógica de validación del precio. 
--Al crear un bloque interno para el SELECT, atrapamos el error ahí mismo, le asignamos 
--el valor de contingencia y permitimos que el trigger continúe hacia abajo con total normalidad.
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_BIU_MARGEN
BEFORE INSERT OR UPDATE ON PRODUCTO 
FOR EACH ROW
DECLARE 
VN_MargeMinimo NUMBER(5,2);
BEGIN
    BEGIN
        SELECT margen_minimo
        INTO VN_MargeMinimo
        FROM CATEGORIA
        WHERE id_categoria = :NEW.id_categoria;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            VN_MargeMinimo := 10;
    END;

    IF :NEW.precio_unitario < :NEW.costo_unitario * (1 + VN_MargeMinimo / 100) THEN
        RAISE_APPLICATION_ERROR(-20020, 'El precio del producto no alcanza el margen minimo de su categoria');
    END IF;
END;
/

DROP TRIGGER TRG_PRODUCTO_BIU_MARGEN;

SELECT id_categoria, nombre, margen_minimo FROM CATEGORIA; 
SELECT ID_PRODUCTO FROM PRODUCTO;
    
INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria, precio_unitario, costo_unitario, stock_minimo, activo)
VALUES (1016, 'TEST-001', 'Producto prueba margen', 1, 1300, 1000, 5, 'S');


INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria, precio_unitario, costo_unitario, stock_minimo, activo)
VALUES (1017, 'TEST-002', 'Producto limite', 1, 1250, 1000, 5, 'S');


INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria, precio_unitario, costo_unitario, stock_minimo, activo)
VALUES (1018, 'TEST-003', 'Producto bajo margen', 1, 1249, 1000, 5, 'S');

SELECT id_producto, codigo, precio_unitario, costo_unitario
FROM PRODUCTO
WHERE id_producto IN (1016, 1017, 1018);
------------------------------------------------------------------- 5.4 (2 pts)
-- TRG_DETALLE_AI_STOCK
-- Al insertar una linea de pedido debe descontar el stock de la bodega indicada
-- y registrar el movimiento de SALIDA correspondiente. Si no hay stock suficiente
-- debe abortar la operacion con el error -20030.
-- Explique por que el momento de disparo que eligio es el correcto y que dejaria
-- de funcionar con el contrario.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- En el trigger se definió el evento AFTER INSERT porque la lógica del negocio 
--exige que el stock solo se descuente una vez que la línea del pedido ha sido 
--guardada y confirmada de forma exitosa en la tabla DETALLE_PEDIDO.

--Primero, se utiliza un SELECT...INTO sobre la tabla EXISTENCIA para verificar
--la cantidad disponible del producto de la bodega indicada. Si esta cantidad es menor a 
--la que se solicita al cliente, el programa lanza la excepción personalizada (-20030),
--Si hay suficiente stock, el programa continua para actualizar la tabla existencia 
--restando el producto y genera automáticamente un registro histórico en la tabla 
--MOVIMIENTO_INVENTARIO bajo el tipo 'SALIDA'.

--La diferencia del momento contrario es que si hubiéramos elegido usar BEFORE INSERT, estaríamos 
--desconectando el inventario a ciegas. Si la inserción del pedido fallara un milisegundo después 
--por culpa de cualquier otra restricción de la base de datos, el stock ya se habría restado de manera inconsistente.
--Lo cual, sería un problema grave en el inventario real de las bodegas, registrando salidas de mercancía que jamás se llegaron a vender.

CREATE OR REPLACE TRIGGER TRG_DETALLE_AI_STOCK
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
DECLARE
    vn_stock_actual NUMBER(10);
BEGIN

    SELECT cantidad
    INTO vn_stock_actual
    FROM EXISTENCIA
    WHERE id_bodega = :NEW.id_bodega 
      AND id_producto = :NEW.id_producto;

    IF vn_stock_actual < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20030, 'No hay stock suficiente en la bodega para cubrir este pedido.');
    END IF;

    UPDATE EXISTENCIA
    SET cantidad = cantidad - :NEW.cantidad
    WHERE id_bodega = :NEW.id_bodega 
      AND id_producto = :NEW.id_producto;
      
    INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
    VALUES (NVL((SELECT MAX(id_movimiento) FROM MOVIMIENTO_INVENTARIO), 0) + 1, :NEW.id_producto, :NEW.id_bodega, 'SALIDA', :NEW.cantidad, SYSDATE, :NEW.id_pedido, 'Salida automatica por pedido');

EXCEPTION
   
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'El producto no tiene registro de existencias en la bodega seleccionada.');
END;
/

------------------------------------------------------------------- 5.5 (1 pt)
-- TRG_DETALLE_TOTAL
-- Debe recalcular el total de la cabecera del pedido despues de cualquier
-- insercion, actualizacion o borrado de sus lineas.
-- Documente el error que obtiene en su primer intento, en que momento aparece,
-- y como lo resuelve la construccion que finalmente utilizo.
-- Este punto no se califica sin esa explicacion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Al intentar resolver este requerimiento con un trigger tradicional de nivel de 
--fila (FOR EACH ROW), el sistema arroja el error critico ORA-04091 en el momento 
--exacto en que se ejecutauna inserion, modificacion o borrado de una linea. 
--Esto ocurre porque el motor de Oracle prohibe que un trigger consulte con un 
--SELECT la misma tabla que lo activo mientras que la operacion aun se encuentra en un proceso de cambio.

--Para resolver este problema, se utilizo la estructura avnzada de un COMPOUND TRIGGER (Trigger Compuesto). 
--Esta construccion nos permite segmentar la logica en dos moemntos distintos dentro del mismo objeto.

--En la seccion AFTER EACH ROW (fila por fila), el programa se limita a capturar en memoria 
--el numero del pedido afectado utilizando :NEW.id_pedido o :OLD.id_pedido según corresponda, 
--evitando hacer consultas prohibidas. Luego, en la sección AFTER STATEMENT (al terminar la sentencia), 
--cuando la tabla ya se encuentra estable y ha dejado de mutar, el trigger ejecuta de forma 
--segura el cálculo SELECT SUM(subtotal) y actualiza el campo total de la cabecera en la tabla PEDIDO. 
--De esta manera se esquiva el error de mutación, manteniendo el inventario y las cuentas del negocio 
--al día tras cualquier cambio.

CREATE OR REPLACE TRIGGER TRG_DETALLE_TOTAL
FOR INSERT OR UPDATE OR DELETE ON DETALLE_PEDIDO
COMPOUND TRIGGER

    vn_id_pedido NUMBER(10);

    AFTER EACH ROW IS
    BEGIN
        IF c OR UPDATING THEN
            vn_id_pedido := :NEW.id_pedido;
        ELSIF DELETING THEN
            vn_id_pedido := :OLD.id_pedido;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF vn_id_pedido IS NOT NULL THEN
            UPDATE PEDIDO
            SET total = NVL((SELECT SUM(subtotal) FROM DETALLE_PEDIDO WHERE id_pedido = vn_id_pedido), 0)
            WHERE id_pedido = vn_id_pedido;
        END IF;
    END AFTER STATEMENT;
END TRG_DETALLE_TOTAL;
/

SELECT p.total,
       (SELECT NVL(SUM(subtotal), 0) FROM DETALLE_PEDIDO WHERE id_pedido = 6) AS suma_real
FROM PEDIDO p
WHERE p.id_pedido = 6;


INSERT INTO DETALLE_PEDIDO (id_pedido, linea, id_producto, id_bodega, cantidad, precio_unitario, subtotal)
VALUES (6, 2, 1002, 1, 2, 62000, 124000);

UPDATE DETALLE_PEDIDO
SET cantidad = 4, subtotal = 248000
WHERE id_pedido = 6 AND linea = 2;

DELETE FROM DETALLE_PEDIDO WHERE id_pedido = 6 AND linea = 2;

SELECT * from PEDIDO WHERE ID_PEDIDO = 6;
------------------------------------------------------------------- 5.6 (1 pt)
-- TRG_V_STOCK_IO
-- Debe permitir actualizar el precio y el stock minimo del producto a traves de
-- la vista V_STOCK_CONSOLIDADO.
-- Explique por que esa vista no es actualizable de forma directa.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--Un trigger INSTEAD OF intercepta el UPDATE y lo redirige a la tabla PRODUCTO,
-- que es donde se encuntran el precio y el stock minimo. Se rechaza el
-- cambio del stock consolidado, debido a que el stock total es un valor calculado y no se 
--sabe en que bodega almacenar ese valor si llegara a ser modificado.

-- 
CREATE OR REPLACE TRIGGER TRG_V_STOCK_IO
INSTEAD OF UPDATE ON V_STOCK_CONSOLIDADO
FOR EACH ROW
BEGIN
    IF :NEW.stock_total <> :OLD.stock_total THEN
        RAISE_APPLICATION_ERROR(-20040,
            'No se puede modificar el stock desde la vista.');
    END IF;

    UPDATE PRODUCTO
    SET precio_unitario = :NEW.precio_unitario,
        stock_minimo    = :NEW.stock_minimo
    WHERE id_producto = :OLD.id_producto;
END;
/

UPDATE V_STOCK_CONSOLIDADO
SET precio_unitario = 20000, stock_minimo = 35          
WHERE id_producto = 1001;

SELECT id_producto, precio_unitario, stock_minimo FROM PRODUCTO WHERE id_producto = 1001;

UPDATE V_STOCK_CONSOLIDADO SET stock_total = 999 WHERE id_producto = 1001;

--==============================================================================
-- PARTE 6 — CASO INTEGRADOR                                   (5 puntos / 45 min)
--==============================================================================

-------------------------------------------------------------------------------
-- PKG_VENTAS
-- Construya un PAQUETE que exponga el procedimiento SP_FACTURAR_PEDIDO, el cual,
-- para un pedido en estado BORRADOR, debe:
--
--   1. Validar que el pedido exista y este en BORRADOR
--   2. Recorrer sus lineas con un cursor y acumular el subtotal
--   3. Calcular el descuento con FN_CALCULAR_DESCUENTO
--   4. Validar contra FN_CUPO_DISPONIBLE que el cliente tenga cupo suficiente
--   5. Actualizar el total del pedido y cambiar su estado a CONFIRMADO
--   6. Incrementar el saldo pendiente del cliente
--   7. Usar SAVEPOINT y revertir parcialmente ante cualquier fallo, registrando
--      el error con SP_REGISTRAR_ERROR
--   8. Devolver por parametros OUT el total facturado y el descuento aplicado
--
-- Firma esperada:
--   PKG_VENTAS.SP_FACTURAR_PEDIDO(p_id_pedido IN NUMBER,
--                                 p_total     OUT NUMBER,
--                                 p_descuento OUT NUMBER)
--
-- Se evalua la integracion. El procedimiento debe apoyarse en los objetos de las
-- partes 1 a 5 y no reimplementar su logica: uno que vuelva a codificar el
-- calculo del descuento pierde la mitad del puntaje de esta parte.
-- Defina explicitamente el alcance transaccional y justifique donde decidio
-- ubicar la confirmacion de la transaccion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El paquete expone un solo procedimiento porque la facturacion es una unica
-- unidad de negocio: o se confirma el pedido y se incrementa el saldo, o no
-- se hace nada. Se usa paquete y no procedimiento suelto porque agrupa la
-- especificacion y el cuerpo, y deja la puerta abierta para agregar mas
-- procedimientos de ventas despues sin tocar la firma.
--
-- El procedimiento se apoya en los objetos ya construidos y no reimplementa
-- nada: llama a fn_calcular_descuento para el descuento, a fn_cupo_disponible
-- para el cupo, y a sp_registrar_error para dejar rastro del fallo. Volver a
-- codificar esas reglas aqui romperia la integracion que pide el ejercicio y
-- duplicaria logica que ya existe.
--
-- El savepoint se declara despues de validar que el pedido existe y esta en
-- borrador, y antes de la primera modificacion. Asi el rollback to sp_facturar
-- deshace solo lo que hizo este procedimiento y no arrastra operaciones que el
-- llamador tuviera abiertas antes.
--
-- El commit va al final del bloque begin, justo antes del exception. Es el
-- unico punto donde ya pasaron todas las validaciones y todas las
-- actualizaciones, entonces confirmar ahi garantiza que no se confirme nada a
-- medias. En el camino de error no se hace commit, solo rollback al savepoint.
--
-- El procedimiento no decide por el llamador: si algo falla, registra el error
-- con sp_registrar_error y vuelve a lanzarlo con raise. Asi el llamador se
-- entera y decide si reintenta, ignora o aborta.


CREATE OR REPLACE PACKAGE PKG_VENTAS IS
    PROCEDURE SP_FACTURAR_PEDIDO (
        p_id_pedido  IN  NUMBER,
        p_total      OUT NUMBER,
        p_descuento  OUT NUMBER
    );
END PKG_VENTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_VENTAS IS

    PROCEDURE SP_FACTURAR_PEDIDO (
        p_id_pedido  IN  NUMBER,
        p_total      OUT NUMBER,
        p_descuento  OUT NUMBER
    ) IS
        v_estado        pedido.estado%type;
        v_id_cliente    pedido.id_cliente%type;
        vn_subtotal      number := 0;
        vn_total         number := 0;
        v_cupo          number := 0;
        v_cant_linea    detalle_pedido.cantidad%type;
        v_precio_linea  detalle_pedido.precio_unitario%type;

        cursor c_lineas is
            select cantidad, precio_unitario
            from   detalle_pedido
            where  id_pedido = p_id_pedido;
    begin
        p_total     := 0;
        p_descuento := 0;

        savepoint sp_facturar;

        -- 1. validar que el pedido exista y este en borrador
        begin
            select estado, id_cliente
            into   v_estado, v_id_cliente
            from   pedido
            where  id_pedido = p_id_pedido;
        exception
            when no_data_found then
                raise_application_error(-20001, 'el pedido ' || p_id_pedido || ' no existe');
        end;

        if v_estado <> 'BORRADOR' then
            raise_application_error(-20002, 'el pedido ' || p_id_pedido ||
                                            ' no esta en borrador, esta en ' || v_estado);
        end if;

        -- 2. recorrer lineas con cursor y acumular subtotal
        open c_lineas;
        loop
            fetch c_lineas into v_cant_linea, v_precio_linea;
            exit when c_lineas%notfound;
            vn_subtotal := vn_subtotal + (v_cant_linea * v_precio_linea);
        end loop;
        close c_lineas;

        if vn_subtotal = 0 then
            raise_application_error(-20003, 'el pedido no tiene lineas');
        end if;

        -- 3. calcular descuento
        p_descuento := fn_calcular_descuento(v_id_cliente, vn_subtotal);
        vn_total     := vn_subtotal - p_descuento;

        -- 4. validar cupo
        v_cupo := fn_cupo_disponible(v_id_cliente);
        if v_cupo < vn_total then
            raise_application_error(-20004, 'cupo insuficiente. disponible: ' ||
                                            v_cupo || ', requerido: ' || vn_total);
        end if;

        -- 5. actualizar pedido
        update pedido
        set    total  = vn_total,
               estado = 'CONFIRMADO'
        where  id_pedido = p_id_pedido;

        -- 6. incrementar saldo del cliente
        update cliente
        set    saldo_pendiente = saldo_pendiente + vn_total
        where  id_cliente = v_id_cliente;

        -- 7. devolver parametros out
        p_total := vn_total;

        commit;

    exception
        when others then
            rollback to sp_facturar;
            sp_registrar_error('PKG_VENTAS.SP_FACTURAR_PEDIDO', sqlerrm);
            raise;
    end SP_FACTURAR_PEDIDO;

END PKG_VENTAS;
/

--==============================================================================
-- FIN DE LA PLANTILLA
--==============================================================================
