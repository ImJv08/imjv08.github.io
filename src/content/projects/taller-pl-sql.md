---
title: PL/SQL - Taller
description: >-
 En el taller se realizaron los ejercicios del taller sobre PL/SQL, donde entraron ejercicios sobre procedimientos, funciones,
 cursores, triggers y de mas
image: '@assets/projects/pl-sql/image.png'
startDate: 2026-09-30
endDate: 2026-10-04
skills:
  - PL/SQL
  - SQL Developer
featured: true
category: pl-sql
---

## SCRIPT COMPLETO DEL TALLER

- Aquí puedes descargar el script SQL con la solución de los puntos desarrollados del taller.

  [📥 Descargar](/downloads/taller-pl-sql/TALLER_PLSQL_GRUPOsql)

## Parte 1 -  Procedimientos Almacenados

### 1.1 SP_REGISTRAR_PRODUCTO

En este ejercicio nos pedian realizar un procedimiento que nos permita registrar un producto nuevo, teniendo en cuenta las siguientes pautas:

- Se debe asignar el identificador desde `SEQ_PRODUCTO`
- Validar que el precio de venta supere el costo unitario
- Verificar que la categoria exista
- Manejar el caso de codigo duplicado

Si pasa todas estas validaciones correctamente, el procedimiento debe devolver el identificador generado.

**RESPUESTA**

```sql
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
```

**EXPLICACIÓN**

- En primer lugar, se hizo la validacion de que el precio de venta y el costo por medio de este bloque:

```sql
IF p_precio <= p_costo THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El precio de venta (' || p_precio ||
            ') debe ser mayor al costo unitario (' || p_costo || ')');
    END IF;
```
![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/registrar-producto/venta-costo.png)

- Luego se verifico que la categoria existirera por medio de este bloque:

```sql
SELECT COUNT(*)
    INTO   vn_existe
    FROM   CATEGORIA
    WHERE  id_categoria = p_id_categoria;

    IF vn_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'La categoria ' || p_id_categoria || ' no existe');
    END IF;
```
![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/registrar-producto/categoria.png)

- Para terminar, se tuvo en cuenta el error del codigo duplicado aprovechando lal excepcion de Oracle `DUP_VAL_ON_INDEX`, de la siguiente manera:

```sql
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Ya existe un producto con el codigo ' || p_codigo);
END SP_REGISTRAR_PRODUCTO;
```
![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/registrar-producto/cod-dup.png)

Se utilizo `RAISE_APPLICATION_ERROR` en lugar de un mensaje normal con `DBMS_OUTPUT.PUT_LINE` debido a que la primera nos permite ademas de crear un codigo para un error que no detecta Oracle, detiene la ejecución y revierte la sentencia, mientras que las segunda solo imprime y el procedimiento seguiria corriendo hasta llegar al INSERT con datos invalidos.

### 1.2 SP_AJUSTAR STOCK

En este ejercicio se nos pide poder registrar una **ENTRADA**, **SALIDA** o **AJUSTE** d e inventario siguiendo estas pautas:

- Si la combinacion bodega-producto no existe y el tipo es **ENTRADA**, crearla.
- Si el tipo es **SALIDA** y no existe la combinacion, rechazar la operación.
- Tener en cuenta que una **SALIDA** nunca puede dejar la existencia en negativo.

Si todas estas validaciones pasan con exito, el procedimiento debe actualizar la tabla **EXISTENCIA** e insertar el registro en **MOVIMIENTO_INVENTARIO**. Al final debe devolver el saldo resultante.

**RESPUESTA**

```sql
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
```

**EXPLICACION**

- Primero se valida que la combinacion bodega-producto exista con el siguiente bloque:

```sql
SELECT COUNT(*)
    INTO   vn_existe
    FROM   EXISTENCIA
    WHERE  id_bodega = p_id_bodega
    AND    id_producto = p_id_producto;
```

- Luego se valida que sea de tipo "ENTRADA" para crear la combinación, si no, se rechaza la operacion. Esto se hace de la siguiente manera:

```sql
IF vn_existe = 0 THEN
        IF p_tipo = 'ENTRADA' THEN
            INSERT INTO EXISTENCIA (id_bodega, id_producto, cantidad)
            VALUES (p_id_bodega, p_id_producto, 0);

        ELSE
            RAISE_APPLICATION_ERROR(-20014,
                'No existe la combinacion bodega-producto');
        END IF;
    END IF;
```
![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/ajustar-stock/bodega-producto.png)

- Luego de estas verificaciones, se proteje la lectura de la existencia por medio de un `FOR UPDATE`, de la siguiente manera:

```sql
SELECT cantidad
    INTO   vn_actual
    FROM   EXISTENCIA
    WHERE  id_bodega = p_id_bodega
    AND    id_producto = p_id_producto
    FOR UPDATE;
```

- Luego para cada tipo de modificacion, se le realiza un calculo diferente. 

Si es **ENTRADA** al saldo final sera igual a la cantidad actual mas la cantidad:

```sql
IF p_tipo = 'ENTRADA' THEN
        p_saldo_final := vn_actual + p_cantidad;
        vn_mov := p_cantidad;
```

Si es **SALIDA** se verifica que la cantidad que se pide sea mayor a la cantidad actual en stock antes de realizar el ajuste:

```sql
ELSIF p_tipo = 'SALIDA' THEN

        IF p_cantidad > vn_actual THEN
            RAISE_APPLICATION_ERROR(-20015,
                'Stock insuficiente: hay ' || vn_actual ||
                ' y se piden ' || p_cantidad);
        END IF;
        p_saldo_final := vn_actual - p_cantidad;
        vn_mov := p_cantidad;
```
Si la cantidad solicitada es mayor, la respuesta sera:

![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/ajustar-stock/stock-insuficiente.png)

Si por el contrario es de tipo **AJUSTE**, la cantidad pasara a ser la que el usuario especifique.

```sql
ELSE
        IF p_cantidad = vn_actual THEN
            RAISE_APPLICATION_ERROR(-20016,
                'El conteo coincide con la existencia');
        END IF;
        
        p_saldo_final := p_cantidad;
        vn_mov := ABS(p_cantidad - vn_actual);
        
    END IF;
```

Si la cantidad que se quiere agregar y el stock actual son iguales, la respuesta sera, debido a que no hay nada que modificar:

![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/ajustar-stock/mismo-valor.png)

### 1.3 SP_CREAR_PEDIDO

En este ejercicio nos piden crear un procedimiento que cree la cabecera de un pedido teniendo en cuenta las siguientes pautas:

- Debe rechazar clientes inactivos 
- Debe rechazar cliente sin cupo de credito disponible

**RESPUESTA**

```sql
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
        RAISE_APPLIssCATION_ERROR(-20021,
            'El cliente ' || p_id_cliente || ' no tiene cupo de credito disponible');
    END IF;

    INSERT INTO PEDIDO (id_pedido, id_cliente, estado)
    VALUES (SEQ_PEDIDO.NEXTVAL, p_id_cliente, 'BORRADOR')
    RETURNING id_pedido INTO p_id_pedido;
    
END SP_CREAR_PEDIDO;
/
```

**EXPLICACIÓN**

Aqui no hay mucho que explicar, simplemente se verifica que el cliente este activo, en caso de que no, la respuesta sera:

![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/crear-pedido/cliente-inactivo.png)

De igual manera, se verifica si el cliente tiene cupo disponible, en caso de que no, la respuesta sera:

![Resultado del ejercicio](src/assets/projects/pl-sql/procedimientos/crear-pedido/sin-cupo.png)

## Parte 2 - Funciones

### 2.1 FN_STOCK_DISPONIBLE

Nos piden crear una funcion que retorne el stock disponible de un producto, teniendo en cuenta las siguientes pautas:

- Si se indica la bodega, devuelve el saldo de esa bodega
- Si la id de la bodega llega nulo, devuelve el saldo consolidado de todas las bodegas.
- Un producto inexistente debe retornar cero y no una excepcion.

**RESPUESTA**

```sql
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
```

**EXPLICACIÓN**

En esta ocasión, la idea central esta en `NVL(SUM(e.cantidad),0)`, ¿Por que?

- Una consulta con una funcion agregada y sin `GROUP BY` siempre devuelve exactamente una fila, por eso nunca ocurre `NO_DATA_FOUND` ni `TOO_MANY_ROWS`.
- Si no hay filas, devolvera 0, cumpliendo la condicion de _"Un producto inexistente debe retornar cero y no una excepcion."_
- El `IF p_id_bodega IS NULL` elige entre dos consultas, pudiendo decidir si se hace la consolidacion de todas las bodegas o solo la especificada.

### 2.2 FN_CUPO_DISPONIBLE

Se pide hacer una funcion que retorne el cupo de credito disponible (`cupo - saldo pendiente`) de un cliente, teniendo las siguientes pautas:

- Un cliente inactivo retorna cero
- El resultado nunca puede ser negativo.

**RESPUESTA**

```sql
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
```

**EXPLICACION**

Aqui no hay mucho que explicar; Basicamente obtiene el cupo, el saldo y el estado del cleinte que se esta pidiendo para poder si el cliente esta inactivo y poder validar que el cupo disponible no sea negativo.

En caso de que estas validaciones pasen correctamente, se retornara el cupo disponible. De lo contrario, retornara 0.

### 2.3 FN_CALCULAR_DESCUENTO

Nos piden hacer una funcion que retorne el valor del descuento aplicable, segun estas reglas:

- Monto mayor o igual a 2.000.000 = 8%
- Monto entre 800.000 y 1.999.999 = 5%
- Monto menor a 800.000 = 0%
- Adicional si el cliente no tiene saldo pendiente = 2%
- Tope maximo acumulado = 10%

**RESPUESTA**

```sql
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
```

**EXPLICACIONES**

Lo "complejo" de este ejercicio son las diferentes condiciones que hay para tener el porcentaje segun el monto, sin embargo, se pudo hacer la primera parte sin problema.

En segundo lugar, se tuvo en cuenta lo que son los "acumulables" segun el saldo, los cuales se suman despues de agregarles el valor inicial.

Por ultimo, se utliza `LEAST` para poder proteger la regla de que lo maximo que debe dar este descuento es del 10%.

**Importante**

Debido a que se especifico el valor del porcentaje como 0 desde la declaracion de variables, un monto nulo devolvera ese mismo 0, asi mismo con un monto negativo.

### 2.4 Consulta con funcion

Se pide una consulta que liste los clientes activos con su cupo disponible, utilizando la funcion del punto 2.2

**RESPUESTA**

```sql
SELECT c.id_cliente,
       c.nombre,
       FN_CUPO_DISPONIBLE(c.id_cliente) AS cupo_disponible
  FROM CLIENTE c
 WHERE c.activo = 'S'
 ORDER BY cupo_disponible DESC;
 ```
![Resultado del ejercicio](src/assets/projects/pl-sql/funciones/consulta/cliente-cupo.png)

**EXPLICACION**

**¿Por que una funcion puede invocarse desde una sentencia SQL?** Debido a que el motor la trata como una expresion mas. Para cada fila evalua la funcion con los valores de esa fila y usa el resultado como si fuera una columna. Por esta razon, puede ir en las clausulas `SELECT`, `WHERE` u `ORDER BY`.

## Parte 3 - Cursores

### 3.1 Cursor explicito

Se pide utilizar un cursor explicito para recorrer los productos cuyo stock consolidado este por debajo del stock minimo, e imprima un reporte con:
- Codigo
- Nombre
- Stock actual
- Stock minimo
- Unidades faltantes
- Total de productos

**RESPUESTA**

```sql
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
```
![Resultado del ejercicio](src/assets/projects/pl-sql/cursores/cursor-explicito.png)

**EXPLICACION**

El utilizar un cursor explicito nos permite tener control sobre cada paso, ademas del atributo `%NOTFOUND`, el cual nos permite identificar el final del cursor.

**¿Por que se utilizo la vista `v_stock_consolidado`?**ss

Esta vista ya trae el stock sumado de todas las bodegas (es decir, el stock consolidado), asi que el filtro stock_total < stock_minimo es directo.

### 3.2 Cursor parametrizado

En este ejercicio nos piden hacer un bloque anonimo en donde un cursor parametrizado reciba el identificador del cliente y un rango de fechas, y muestre los pedidos **CONFIRMADOS** de ese cliente en ese rango, con:
- Su total
- Cantidad de lineas de cada pedido.

**RESPUESTA**

```sql
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
```
![Resultado del ejercicio](src/assets/projects/pl-sql/cursores/cursor-parametrizado.png)

**EXPLICACION**

Al ser un cursor parametrizado, este cursos tiene los parametros (p_cliente, p_ini, p_fin), a los cuales se les pasa la informacion en el `OPEN c_pedidos(501, to_date('2026-01-01','yyyy-mm-dd'), to_date('2026-12-31','yyyy-mm-dd'));`

### 3.3 Cursor `FOR UPDATE` con `WHERE CURRENT OF`

Nos piden hacer un bloque anonimo que contenga un **CURSOR FOR UPDATE** que recorra los productos de una categoria y ajuste su precio un porcentaje dado. Adicionalmente, se debe utilizar **WHERE CURRENT OF**.

Se deben seguir las siguientes pautas:
- No debe poder modificar productos inactivos
- El precio resultante no puede quedar por debajo del costo mas el margen minimo de la categoria

**RESPUESTA**

```sql
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
```
![Resultado del ejercicio](src/assets/projects/pl-sql/cursores/cursor-forupdate.png)

**EXPLICACION**

- Se utilizó `FOR UPDATE ... NOWAIT` debido a que hace que el cursor falle de inmediato si alguna de las filas que quiere bloquear ya esta bloqueada por otra sesion, en lugar de quedarse esperando/bloqueado.

- **¿Que bloqueo genera?** Bloquea cada fila leida con un lock exclusivo, y ese bloqueo dura hasta el commit o rollback.

- **¿Por que `CURRENT OF`?** Ya que esta clausula hace que se actualicen exactamente la fila que el cursor tiene posicionada, que ya esta bloqueada. Un `UPDATE ... WHERE` comun, obligaria a buscar de nuevo el id que el cursor ya tiene seleccioando.

### 3.4 SP_LISTAR_MOVIMIENTOS

Se pude crear un procedimiento que reciba un identificador de producto y devuelva un `SYS_REFCURSOR` con los movimientos de inventario de ese producto. Deben estar ordenados por fecha.

**RESPUESTA**

```sql
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
        fetch v_cursor into vn_id, vd_fecha, vv_tipo, vn_cant, vv_bodega, vn_pedido, vv_obs;

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
```
![Resultado del ejercicio](src/assets/projects/pl-sql/cursores/listar-movimientos.png)

**EXPLICACION**

- **¿Por que `SYS_REF_CURSOR`?** Es un puntero a un conjunto de resultados que puede pasarse como parametro `OUT`. Es la forma estandar de devolver conjuntos de filas a aplicaciones.

_**Nota:** La responsabilidad de cerrar el cursor es del consumidor, y olvidar genera `ORA-01000`_

### 3.5 BULK COLLECT + FORALL

Nos piden hacer un bloque anonimo que cargue (Con `BULK COLLECT`) los productos de una categoria en una coleccion . Ademas se debe usar `FORALL`para actualizar su stock minimo.

**RESPUESTA**

```sql
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
```
![Resultado del ejercicio](src/assets/projects/pl-sql/cursores/bulk-collect.png)

**EXPLICACION**

Este bloque carga en dos colecciones (v_ids, v_mins) los productos activos de la categoría con un solo `SELECT ... BULK COLLECT INTO`. Luego `FORALL i IN 1..v_ids.COUNT` ejecuta el UPDATE de todas las filas como una sola operación por lotes, y cuenta con `SQL%ROWCOUNT`.

- **¿Que costo elimina?** Elimina el cambio de contexto entre el motor SQL y el motor PL/SQL. Un `FOR con un UPDATE` por iteración envía N sentencias al motor SQL. `FORALL` envía el lote completo en una sola llamada.


- **¿Desde que volumen se empieza a notar?** Con unos cientos de filas empieza a ser medible, y con miles o más la diferencia es grande.s