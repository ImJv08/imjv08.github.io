---
title: SQL Avanzado aplicado sobre el esquema HR
description: >-
 En el taller se realizaron algunos puntos sobre el esquema HR de Oracle los cuales están pensados para practicar los mecanismos de SQL avanzado, de esta manera se pudo reforzar los conceptos y aprender otras herramientas para realizar consultas en SQL.
image: '@assets/projects/sql-avanzado/image.png'
startDate: 2026-12-07
endDate: 2026-01-17
skills:
  - Oracle SQL
  - SQL Avanzado
  - SQL Developer
featured: true
category: sql-avanzado
---
## Taller en formato PDF

Aquí puedes descargar el taller que fue solucionado en esta sección.

[📥 Descargar Taller](/downloads/taller_repaso_SQL_Avanzado_HR.pdf)


## PARTE 1. Consultas y columnas mínimas que se deben mostrar 

### Ejercicio 6.2: Inventario completo de departamentos
**Columnas obligatorias:** department_id, department_name, city, country_name,
employee_count, avg_salary

- Deben aparecer todos los departamentos, incluidos los que no tienen ningún empleado.
- employee_count debe mostrar 0 para los departamentos vacíos, no una fila ausente ni el valor 1
- El comentario debe explicar por qué COUNT(*) produce el valor incorrecto en este caso y qué
función lo corrige.

**ANALISIS DEL EJERCICIO**

Para el desarrollo de esta consulta, en primer lugar habia que obtener las 6 columnas obligatorias, de las cuales 2 tienen pautas importantes:
- **employee_count:** Debe hacerse con la función COUNT () ya que se nos pide contar el total de empleados.
- **avg_salary:** Debe hacerse con la funcion AVG() ya que se nos pide calcular el promedio en el salario de los empleados.

Tambien se tenía que tener en cuenta que en el ejercicio nos piden "_todos los departamentos_", por esta razón se utiliza un **LEFT JOIN** para obtener todos los departamentos sin importar si tienen empleados o no.

Por último se tiene la clausula **GROUP BY** la cual me permitió agrupar la consultar por departamento.

**CONSULTA DEL EJERCICIO**

```sql
SELECT D.DEPARTMENT_ID,
       D.DEPARTMENT_NAME,
       L.CITY,
       C.COUNTRY_NAME,
       COUNT(E.EMPLOYEE_ID) AS EMPLOYEE_COUNT,
       AVG(E.SALARY) AS AVG_SALARY
FROM HR.DEPARTMENTS D
LEFT JOIN HR.LOCATIONS L
ON D.LOCATION_ID = L.LOCATION_ID
LEFT JOIN HR.COUNTRIES C
ON L.COUNTRY_ID = C.COUNTRY_ID
LEFT JOIN HR.EMPLOYEES E
ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
GROUP BY D.DEPARTMENT_ID,
         D.DEPARTMENT_NAME,
         L.CITY,
         C.COUNTRY_NAME;
```

**PREGUNTAS DEL EJERCICIO**

- ¿Por qué COUNT(*) produce un valor incorrecto en este caso?

Porque el LEFT JOIN genera una fila con valores NULL para un departamento que no tiene empleados asociados, por lo que COUNT(*) contaría esa fila como 1, mientras que COUNT(E.EMPLOYEE_ID) ignora el NULL y devuelve 0 sin alterar el resultado.

### Ejercicio 6.3: Cadena de mando

**Columnas obligatorias:** employee_id, employee_name, job_title, manager_id, manager_name,
department_name

- El empleado 100 debe aparecer en el resultado con manager_name en nulo.
- El comentario debe indicar qué tipo de reunión se usó y qué ocurre con ese empleado si se usa
INNER JOIN.

**ANÁLISIS DEL EJERCICIO**

Para el desarrollo de esta consulta, en primer lugar se tuvieron que obtener las 6 columanas obligatorias, de las cuales 2 tienen pautas importantes:

- **employee_name:** Por interpretación mía, entendí que esta columna representa el nombre completo del empleado, es decir, nombre y apellido, por lo que se utilizo **|| ' ' ||** para contatenar ambas y poder tener el nombre completo del empleado.

- **manager_name:** La descripción del ejercucicio nos dice que "_El empleado 100 debe aparecer con managername en nulo_". Para que esto sea posible, se tuvo que agregar la expresion **CASE .... END** para poder especificar que si el id del empleado es nulo, le asigne el valor nulo en la salida de la consulta.

**CONSULTA DEL EJERCICIO**

```sql
SELECT E.EMPLOYEE_ID,
       E.FIRST_NAME || ' ' || E.LAST_NAME AS EMPLOYEE_NAME,
       J.JOB_TITLE,
       E.MANAGER_ID,
       CASE
           WHEN M.EMPLOYEE_ID IS NULL THEN NULL
           ELSE M.FIRST_NAME || ' ' || M.LAST_NAME
       END AS MANAGER_NAME,
       D.DEPARTMENT_NAME
FROM HR.EMPLOYEES E
LEFT JOIN HR.EMPLOYEES M
ON E.MANAGER_ID = M.EMPLOYEE_ID
LEFT JOIN HR.JOBS J
ON E.JOB_ID = J.JOB_ID
LEFT JOIN HR.DEPARTMENTS D
ON E.DEPARTMENT_ID = D.DEPARTMENT_ID;
```
**PREGUNTAS DEL EJERCICIO**

- ¿Qué tipo de reunión se usó?

En esta consulta se utilizó la clausula **LEFT JOIN** ya que esta al combinar los registros de la tabla incluye a todos los registros de la tabla izquierda sin importar que tenga o no coincidencia. En el caso de que no se encuentre una coincidencia, en el resultado se vera "NULL".

- ¿Qué ocurre con el empleado con id = 100 si se utiliza un INNER JOIN?

Lo que sucede con **INNER JOIN** es que al combinar los registros de la tabla, devuelve únicamente las filas que tienen una coincidencia en ambas, si no encuentra una coincidencia se descarta y no aparece en el resultado, por lo que, en este caso, descartaria al empleado con id = 100.

### Ejercicio 6.4: Contraste entre la condición en ON y la condición WHERE

**Columnas obligatorias:** variante, filas_devueltas, explicacion

- Deben ejecutar la misma reunión externa filtrando por salario superior a 10.000, primero en la
cláusula ON y luego en la cláusula WHERE.
- Deben registrar el conteo de filas de cada variante y enunciar en una sola frase la regla general
que se deriva de la diferencia.

**ANÁLISIS DEL EJERCICIO**

Este ejercicio es diferente a los anteriores, ya que en esta ocasión se piden analizar dos situaciones diferentes, con las columnas "variante", "filas_devueltas" y explicacion:

- **Filtro del salario en la clausula ON**

Lo que se filtre en la clausula ON se aplica durante la reunion (En este caso en el LEFT JOIN), lo que causa que se conserven algunas filas aunque no cumplan la condición, que en este caso, incluiria los departamentos aunque no tengan empleados con salario superior a 1000.

```sql
SELECT 'CONDICIÓN EN ON' AS variante,
       COUNT(*) AS filas_devueltas,
       'El filtro de salario se aplica durante la reunión, por lo que el LEFT JOIN conserva los departamentos aunque no tengan empleados con salario superior a 10000.' AS explicacion
FROM HR.DEPARTMENTS D
LEFT JOIN HR.EMPLOYEES E
       ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
      AND E.SALARY > 10000;
```

En este caso, el numero de filas que se obtuvieron al hacer esta consulta es de **36**.

- **Filtro del salario en la clausula WHERE**

Lo que se filtre en la clausula WHERE se aplica después de la reunión, lo que significa que, en esta ocasión no se conservan las filas donde el empleado no cumpla con la condición, pudiendo eliminar departamentos que se habian obtenido por el LEFT JOIN. Esto basicamente hace que el LEFT JOIN se convierta en un INNER JOIN.

```sql
SELECT 'CONDICIÓN EN WHERE' AS variante,
       COUNT(*) AS filas_devueltas,
       'El filtro de salario se aplica después de la reunión, por lo que elimina las filas donde el empleado no cumple la condición y puede eliminar departamentos conservados por el LEFT JOIN.' AS explicacion
FROM HR.DEPARTMENTS D
LEFT JOIN HR.EMPLOYEES E
       ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
WHERE E.SALARY > 10000;
```
En este caso, el número de filas que se obtuvieron al hacer esta consulta es de **15**.

### Ejercicio 6.5: Diagnóstico de nulos y compensación total

**Columnas obligatorias:** employee_id, last_name, department_id, salary, commission_pct,
total_compensation, es_jefe

- total_compensation no puede ser nulo para ningún empleado.
- es_jefe debe indicar explícitamente SI o NO y resolverse con NOT EXISTS.
- El comentario debe explicar por qué la versión con NOT IN sobre la subconsulta de manager_id
devuelve el conjunto vacío, y por qué NOT EXISTS no presenta ese comportamiento.

**ANÁLISIS DEL EJERCICIO**

Para el desarrollo de esta consulta, en primer lugar habia que obtener las 7 columnas obligatorias, de las cuales 2 tienen pautas importantes:
- **total_compensation:** En esta columna se pide calcular la compensación total de un empleado, para lo cual se necesita sumar su salario base más su comición. Para hacerlo se tuvo que utilizar la funcion **NVL()** la cual me ayudó a tener un control con las comiciones nulas de algunos empleados.
- **es_jefe:** En esta columna se pide identificar si el empleado es jefe o no. Para esto utilicé la estructura **CASE ... END**, la cual ya había utilizado en uno de los ejercicios anteriores; pero en esta ocasión agregué la cláusula **WHEN NOT EXISTS**, la cual me ayudó a identificar mediante una subconsulta a aquellos empleados que no tienen a nadie a su cargo (marcándolos como 'NO') y a los que sí (marcándolos como 'SI').

**CONSULTA DEL EJERCICIO**

```sql
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       D.DEPARTMENT_ID,
       E.SALARY,
       E.COMMISSION_PCT,
       E.SALARY + (E.SALARY * NVL(E.COMMISSION_PCT,0)) AS TOTAL_COMPENSATION,
       CASE
          WHEN NOT EXISTS (
             SELECT 1
             FROM HR.EMPLOYEES M
             WHERE M.MANAGER_ID = E.EMPLOYEE_ID
          ) THEN 'NO'
          ELSE 'SI'
          END AS ES_JEFE
FROM HR.EMPLOYEES E
LEFT JOIN HR.DEPARTMENTS D
ON E.DEPARTMENT_ID = D.DEPARTMENT_ID;
```

**PREGUNTAS DEL EJERCICIO**

- ¿Por qué NOT IN devuelve el conjunto vacio?

Porque en la lista de jefes que devuelve la subconsulta hay un valor NULL. Si se intenta comparar algo con un valor vacío en SQL usando NOT IN, el sistema se "confunde", anula esa condición (la deja vacía) y salta directamente al ELSE, marcando a todos los empleados como 'SI'.

- ¿Por qué NOT EXISTS no presenta ese comportamiento?

Porque NOT EXISTS no se fija en los valores, sino si la subconsulta encuentra o no empleados que cumplan con la condición, lo que significa que si el valor es NULL no sucede la confución, ya que lo tomara como que no cumple la condición.

## PARTE 2. Depuración de consultas defectuosas
## Scripts del taller solucionado

- Aquí puedes descargar el script SQL con la solucion de los puntos de la primera parte del taller.

  [📥 Descargar primera parte](/downloads/Ejercicios_SQLAvanzado.sql)

- Aquí puedes descargar el script SQL con la solución de los puntos de la segunda parte del taller.