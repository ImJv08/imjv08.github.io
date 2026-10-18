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
