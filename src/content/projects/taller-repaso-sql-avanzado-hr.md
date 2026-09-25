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

Lo que se filtre en la clausula **ON** se aplica durante la reunion (En este caso en el LEFT JOIN), lo que causa que se conserven algunas filas aunque no cumplan la condición, que en este caso, incluiria los departamentos aunque no tengan empleados con salario superior a 1000.

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

Lo que se filtre en la clausula **WHERE** se aplica después de la reunión, lo que significa que, en esta ocasión no se conservan las filas donde el empleado no cumpla con la condición, pudiendo eliminar departamentos que se habian obtenido por el LEFT JOIN. Esto basicamente hace que el LEFT JOIN se convierta en un INNER JOIN.

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

### Ejercicio 6.6: Agregación con filtrado de grupos

**Columnas obligatorias:** department_id, department_name, employee_count, avg_salary,
min_salary, max_salary, salary_mass, empleados_recientes

- Solo departamentos con más de cinco empleados y salario promedio superior a 6.000.
- empleados_recientes debe contar únicamente a los contratados después del 1 de enero de
2005, sin que ese criterio afecte a employee_count. Debe resolverse con agregación
condicional, no con WHERE.
- El comentario debe justificar por qué el criterio de más de cinco empleados no puede
escribirse en WHERE.

**ANÁLISIS DEL EJERCICIO**

Para el desarrollo de esta consulta, en primer lugar se debe obtener las 8 columnas obligatorias, de las cuales 6 tienen pautas importantes:

- **employee_count:** Esta columna nos pide contar el total de empleados que hay en un departamento, para lograrlo se utilizó la función **COUNT()**.
- **avg_salary:** Esta columna nos pide calcular el promedio de los salarios que obtienen los empleados en un departamento, para lograrlo se utilizó la función **AVG()**.
- **min_salary:** Esta columna nos pide obtener el salario más bajo que reciben los empleados en un departamento, para lograrlo se utilizó la función **MIN()**.
- **max_salary:** Esta columna nos pide obtener el salario más alto que reciben los empleados en un departamento, para lograrlo se utilizó la función **MAX()**.
- **salary_mass:** Esta columna nos pide obtener la masa salarial, es decir, la suma total de todos los salarios pagados a los empleados en un departamento, para lograrlo se utilizó la función **SUM()**.
- **empleados_recientes:** Esta columna a mi parecer es la más compleja, ya que nos pide contar los empleados que fueron contratados despúes del 1 de Enero de 2005, para lograrlo, a la función **SUM()** se le agregó la estructura **CASE ... END** la cual nos permitio hacer la condicion de que, si la fecha de contratación es mayor a 01/01/2005, entonces le asigna el valor de 1, sino, entonces su valor será 0. De esta manera se pueden contar los empleados recientes sin afectar employee_count.

**NOTA:** Este ejercicio tiene una pauta importante, dice que el resultado debe incluir _Solo departamentos con más de cinco empleados y salario promedio superior a 6.000_. Para lograr esto, la condición se debe poner en la clausula **HAVING()**, ya que es una condición que se debe validar despues de agrupar los datos.

**CONSULTA DEL EJERCICIO**

```sql
SELECT D.DEPARTMENT_ID,
       D.DEPARTMENT_NAME,
       COUNT(E.EMPLOYEE_ID) AS EMPLOYEE_COUNT,
       AVG(E.SALARY) AS AVG_SALARY,
       MIN(E.SALARY) AS MIN_SALARY,
       MAX(E.SALARY) AS MAX_SALARY,
       SUM(E.SALARY) AS SALARY_MASS,
       SUM(
           CASE
               WHEN E.HIRE_DATE > DATE '2005-01-01' THEN 1
               ELSE 0
           END
        ) AS EMPLEADOS_RECIENTES
FROM HR.DEPARTMENTS D
LEFT JOIN HR.EMPLOYEES E
ON D.DEPARTMENT_ID = E.DEPARTMENT_ID
GROUP BY D.DEPARTMENT_ID,
         D.DEPARTMENT_NAME
HAVING COUNT(E.EMPLOYEE_ID) > 5 AND AVG(E.SALARY) > 6000;
```

**PREGUNTAS DEL EJERCICIO**

- ¿Por qué el criterio de más de cinco empleados no puede escribirse en WHERE?

Esta condición no puede ir en el WHERE ya que esta clausula raliza el filtro fila por fila antes de realizar la agrupación. Teniendo en cuenta que el conteo de los empleados se hace por la funcion COUNT() que es agrupada en el GROUP BY, el sistema no sabe cuantos empleados hay en cada departamento hasta que se agrupen. Por esta razón, cualquier condición que dependa de estar agrupados para saber si se cumple o no, debe hacerse en la clausula HAVING.

### Ejercicio 6.7: Comparación de cada empleado contra el promedio de su departamento

**Columnas obligatorias:** employee_id, last_name, department_id, salary, dept_avg_salary,
diff_vs_avg, pct_vs_avg

- Deben entregar dos versiones equivalentes: una con subconsulta correlacionada y otra con
expresión común de tabla.
- El comentario debe señalar exactamente qué columna produce la correlación y comparar
ambos planes de ejecución obtenidos con EXPLAIN PLAN o AUTOTRACE.

**ANÁLISIS DEL EJERCICIO**

Este ejercicio es un poco diferente a los anteriores, ya que, al igual que en el Ejercicio 6.4, nos piden hacer la comparación de dos consultas que solucionan el ejercicio.

**Versión de la subconsulta correlacionada**

Para realizar la consulta utilizando subconsultas correlacionadas, se utilizo principalmente para obtener las siguientes columnas:

- **dept_avg_salary:** En esta columna nos piden calcular el salario promedio del departamento del empleado actual, para lograrlo, se hizo una subconsulta, la cual busca en la tabla EMPLOYEES todos los empleados con el mismo DEPARTMENT_ID, para asi encontrar a los empleados que pertenecen al mismo departamento, para luego calcular su promedio con la función **AVG()** y la función **ROUND()** para redondear el resultado a 2 decimales.
- **diff_vs_avg:** En esta columna nos piden calcular la diferencia entre el salario del empleado y el promedio de su departamento, para lograrlo, se restó el salario del departamento y el promedio, el cual se obtuvo por medio de una subconsulta que, nuevamente por medio de **AVG()** y **ROUND()** se obtiene el promedio por departamento.
- **pct_vs_avg:** En esta columna nos piden calcular la desviación procentual del salario del empleado respecto al promedio de su departamento, para lograrlo, se aplico la formula matematica ((Salario-Promedio) / Promedio). Al igual que en las dos columnas anteriores, se tuvo que hacer una subconsulta para encontrar el promedio del departamento para poder hacer el calculo. Adicionalmente, al resultado final se multiplicó por 100 para poder obtener el porcentaje final.

```sql
EXPLAIN PLAN FOR
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       E.DEPARTMENT_ID,
       E.SALARY,
       ROUND((SELECT AVG(E2.SALARY)
              FROM HR.EMPLOYEES E2
              WHERE E2.DEPARTMENT_ID = E.DEPARTMENT_ID),2) AS DEPT_AVG_SALARY,
        ROUND((E.SALARY - (SELECT AVG(E3.SALARY)
                           FROM HR.EMPLOYEES E3
                           WHERE E3.DEPARTMENT_ID = E.DEPARTMENT_ID)),2) AS DIFF_VS_AVG,
        ROUND((E.SALARY - (SELECT AVG(E3.SALARY)
                           FROM HR.EMPLOYEES E3
                           WHERE E3.DEPARTMENT_ID = E.DEPARTMENT_ID)) / (SELECT AVG(E3.SALARY)
                                                                         FROM HR.EMPLOYEES E3
                                                                         WHERE E3.DEPARTMENT_ID = E.DEPARTMENT_ID)*100, 2)  AS PCT_VS_AVG
FROM HR.EMPLOYEES E;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));
```

- **Resultado del plan de ejecución**

Plan hash value: 2475941632

<table>
  <thead>
    <tr>
      <th>Id</th>
      <th>Operation</th>
      <th>Name</th>
      <th>Rows</th>
      <th>Cost (%CPU)</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <td>0</td>
      <td>SELECT STATEMENT</td>
      <td></td>
      <td>1081</td>
      <td>441 (1)</td>
    </tr>
    <tr>
      <td>1</td>
      <td>PX COORDINATOR</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>2</td>
      <td>PX SEND QC (RANDOM)</td>
      <td>:TQ10004</td>
      <td>1081</td>
      <td>8 (25)</td>
    </tr>
    <tr>
      <td>3</td>
      <td>EXPRESSION EVALUATION</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>4</td>
      <td>HASH JOIN RIGHT OUTER BUFFERED</td>
      <td></td>
      <td>1081</td>
      <td>8 (25)</td>
    </tr>
    <tr>
      <td>5</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>6</td>
      <td>PX SEND BROADCAST</td>
      <td>:TQ10002</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>7</td>
      <td>VIEW</td>
      <td>VW_SSQ_1</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>8</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>9</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>10</td>
      <td>PX SEND HASH</td>
      <td>:TQ10000</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>11</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>12</td>
      <td>PX BLOCK ITERATOR</td>
      <td></td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>13</td>
      <td>TABLE ACCESS FULL</td>
      <td>EMPLOYEES</td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>14</td>
      <td>HASH JOIN OUTER</td>
      <td></td>
      <td>340</td>
      <td>5 (20)</td>
    </tr>
    <tr>
      <td>15</td>
      <td>PX BLOCK ITERATOR</td>
      <td></td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>16</td>
      <td>TABLE ACCESS FULL</td>
      <td>EMPLOYEES</td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>17</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>18</td>
      <td>PX SEND BROADCAST</td>
      <td>:TQ10003</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>19</td>
      <td>VIEW</td>
      <td>VW_SSQ_2</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>20</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>21</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>22</td>
      <td>PX SEND HASH</td>
      <td>:TQ10001</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>23</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>24</td>
      <td>PX BLOCK ITERATOR</td>
      <td></td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>25</td>
      <td>TABLE ACCESS FULL</td>
      <td>EMPLOYEES</td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>26</td>
      <td>SORT AGGREGATE</td>
      <td></td>
      <td>1</td>
      <td></td>
    </tr>
    <tr>
      <td>27</td>
      <td>TABLE ACCESS BY INDEX ROWID BATCHED</td>
      <td>EMPLOYEES</td>
      <td>10</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>28</td>
      <td>INDEX RANGE SCAN</td>
      <td>EMP_DEPARTMENT_IX</td>
      <td>10</td>
      <td>1 (0)</td>
    </tr>
    <tr>
      <td>29</td>
      <td>SORT AGGREGATE</td>
      <td></td>
      <td>1</td>
      <td></td>
    </tr>
    <tr>
      <td>30</td>
      <td>TABLE ACCESS BY INDEX ROWID BATCHED</td>
      <td>EMPLOYEES</td>
      <td>10</td>
      <td>2 (0)</td>
    </tr>
  </tbody>
</table>

**Versión con expresión común en tabla**

Para realizar la consulta con expresión común en tabla (Es decir, con un CTE), se utilizó de la siguiente manera:

- **CTE PROMEDIO:** En esta CTE, se calcula el salario promedio por departamento, utilizando la función **AVG()**.

Gracias a lo anterior, los calculos de las demás columnas fueron más simplificadas:

- **dept_avg_salary:** Para obtener el calculo del salario promedio por departamento, solo se tuvo que obtener el valor de la columa "prom_salario" de la tabla promedio y redondearlo con la función **ROUND()** a 2 decimales.
- **diff_vs_avg:** Para obtener la diferencia del empleado y el promedio del departamento, se tuvo que hacer la resta entre el salario del empleado y el valor de la columna "prom_salario" de la CTE, y redondearlo a 2 decimales.
- **pct_vs_avg:** Para obtener la desviación procentual del salario del empleado respecto al promedio de su departamento se utilizó la misma formula matemática del caso anterior, pero en esta ocasión para obtener el valor del promedio solo se llamó la columna "prom_salario" de la CTE.
```sql
EXPLAIN PLAN FOR
WITH PROMEDIO AS(
                 SELECT E.DEPARTMENT_ID,
                        AVG(E.SALARY) AS PROM_SALARIO
                 FROM HR.EMPLOYEES E
                 GROUP BY E.DEPARTMENT_ID
                )
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       E.DEPARTMENT_ID,
       E.SALARY,
       ROUND(P.PROM_SALARIO,2) AS DEPT_AVG_SALARY,
       ROUND(E.SALARY - P.PROM_SALARIO, 2) AS DIFF_VS_AVG,
       ROUND((E.SALARY - P.PROM_SALARIO) / P.PROM_SALARIO * 100,2) AS PCT_VS_AVG
FROM HR.EMPLOYEES E
JOIN PROMEDIO P
ON E.DEPARTMENT_ID = P.DEPARTMENT_ID;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));
```
- **Resultado del plan de ejecución**

Plan hash value: 3091987791

<table>
  <thead>
    <tr>
      <th>Id</th>
      <th>Operation</th>
      <th>Name</th>
      <th>Rows</th>
      <th>Cost (%CPU)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>0</td>
      <td>SELECT STATEMENT</td>
      <td></td>
      <td>339</td>
      <td>5 (20)</td>
    </tr>
    <tr>
      <td>1</td>
      <td>PX COORDINATOR</td>
      <td></td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>2</td>
      <td>PX SEND QC (RANDOM)</td>
      <td>:TQ10002</td>
      <td>339</td>
      <td>5 (20)</td>
    </tr>
    <tr>
      <td>3</td>
      <td>HASH JOIN</td>
      <td></td>
      <td>339</td>
      <td>5 (20)</td>
    </tr>
    <tr>
      <td>4</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>5</td>
      <td>PX SEND BROADCAST</td>
      <td>:TQ10001</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>6</td>
      <td>VIEW</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>7</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>8</td>
      <td>PX RECEIVE</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>9</td>
      <td>PX SEND HASH</td>
      <td>:TQ10000</td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>10</td>
      <td>HASH GROUP BY</td>
      <td></td>
      <td>11</td>
      <td>3 (34)</td>
    </tr>
    <tr>
      <td>11</td>
      <td>PX BLOCK ITERATOR</td>
      <td></td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>12</td>
      <td>TABLE ACCESS FULL</td>
      <td>EMPLOYEES</td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>13</td>
      <td>PX BLOCK ITERATOR</td>
      <td></td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
    <tr>
      <td>14</td>
      <td>TABLE ACCESS FULL</td>
      <td>EMPLOYEES</td>
      <td>107</td>
      <td>2 (0)</td>
    </tr>
  </tbody>
</table>
 
**PREGUNTAS DEL EJERCICIO**

- ¿Qué diferencia se observa entre la versión con expresión común y la versión con subconsulta correlacionada?

Como se puede ver en la columna de **COST (%CPU)** de ambas consultas, podemos notar que la versión con subconsulta relacionada tiene un costo estimado de **441**, mientras que en la versión con expresión común presenta un costo estimado de **5**. Esto se debe a que la primera versión requiere operaciones adicionales, como **SORT AGGREGATE**, accesos por el indice y transformaciones internas de las subconsultas, por lo tanto, Oracle estima que la versión con expresión común requiere menos trabajo para obtener el resultado.

### Ejercicio 6.8: Movilidad interna

**Columnas obligatorias:** employee_id, last_name, movilidad_status

- movilidad_status debe indicar CON HISTORIAL o SIN HISTORIAL.
- Deben resolverlo con INTERSECT y MINUS, y contrastar el resultado con la versión equivalente
escrita con NOT EXISTS.
- El comentario debe explicar cómo tratan los nulos las operaciones de conjuntos frente al
operador de igualdad.

**ANÁLISIS DEL EJERCICIO**

Para la consulta de este ejercicio nos están pidiendo utilizar las clausulas **INTERSECT**, **MINUS** y **NOT EXISTS**. Estas clausulas realizan las siguientes acciones: 

- **INTESECT:** Esta clausula nos permite tomar las columnas que tienen en común ambas tablas. En la consulta se utilizó en la CTE llamada **"CON_H"**, la cual, con ayuda de esta clausula, se pudo identificar la id de los empleados que tambien estan en la tabla "JOB_HISTORY", para asi encontrar los empleados que tienen historial.
- **MINUS:** Esta clausula nos permite tomar las columnas que tiene la primera tabla que no tiene la segunda. En la consulta se utilizó en la CTE llamada **"SIN_H**, la cual, con ayuda de esta clausula, se pudo identificar la id de los empleados que no estan en la tabla "JOB_HISTORY", para asi encontrar los empleados que no tienen historial.
- **NOT EXISTS:** Esta clausula nos permite comprobar que una subconsulta no devuelva ninguna fila. En la consulta se utilizó para comprobar si cada empleado tiene o no registros en la tabla "JOB_HISTORY", utilizando la CTE **CON_H**.

**CONSULTA DEL EJERCICIO**

```sql
WITH CON_H AS (
               SELECT E.EMPLOYEE_ID
               FROM HR.EMPLOYEES E
               INTERSECT 
               SELECT J.EMPLOYEE_ID
               FROM HR.JOB_HISTORY J
               ),
SIN_H AS (
          SELECT E.EMPLOYEE_ID
          FROM HR.EMPLOYEES E
          MINUS
          SELECT J.EMPLOYEE_ID
          FROM HR.JOB_HISTORY J
         )
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       (CASE
           WHEN NOT EXISTS (
               SELECT 1
               FROM CON_H C
               WHERE E.EMPLOYEE_ID = C.EMPLOYEE_ID
           )
           THEN 'SIN HISTORIAL'
           ELSE 'CON HISTORIAL'
        END
        ) AS MOVILIDAD_STATUS
FROM HR.EMPLOYEES E;

```

**PREGUNTAS DEL EJERCICIO**

- ¿Cómo tratan los nulos las operaciones de conjuntos frente al operador de igualdad?

Mientras que **NULL = NULL** nunca devuelve True, sino **UNKNOWN**, las operaciones de conjunto (como INTERSECT, UNION Y MINUS) **pueden considerar dos valores NULL como iguales** al comparar las filas. Por esto, para comprobar si un valor es nulo se debe utilizar **IS NULL** y no el operador de igualdad.

### Ejercicio 6.9: Jerarquía organizacional

**Columnas obligatorias:** employee_id, last_name, manager_id, nivel, ruta_jerarquica
- Debe construirse con una expresión común de tabla recursiva, con caso base en el empleado
sin jefe.
- ruta_jerarquica debe mostrar la cadena de apellidos desde la raíz hasta el empleado.
- El comentario debe identificar el caso base y el paso recursivo, explicar qué ocurre si UNION
ALL se reemplaza por UNION y cómo se controlaría un ciclo en los datos.

**ANÁLISIS DEL EJERCICIO**

Para realizar esta consulta, en primer lugar se tuvo que entender lo que es una **CTE Recursiva**, la cual es una expresión común de tabla que puede consultarse a si misma. En este ejercicio se utilizó para representar la jerarquia de los empleados, teniendo como **caso base** el empleado que no tenga un manager asociado **(MANAGER_ID IS NULL)** para que, apartir de ahi se recorran sus subordinados. En cada paso se aumenta el **nivel** y se construye la **ruta_jerarquica** agregando el apellido del empleado correspondiente.

**CONSULTA DEL EJERCICIO**

```sql
WITH JERARQUIA (
                EMPLOYEE_ID,
                LAST_NAME,
                MANAGER_ID,
                NIVEL,
                RUTA_JERARQUIA
                ) AS (
                       SELECT E.EMPLOYEE_ID,
                              E.LAST_NAME,
                              E.MANAGER_ID,
                              1 AS NIVEL,
                              E.LAST_NAME AS RUTA_JERARQUIA
                       FROM HR.EMPLOYEES E
                       WHERE E.MANAGER_ID IS NULL
                       
                       UNION ALL
                       
                       SELECT E.EMPLOYEE_ID,
                              E.LAST_NAME,
                              E.MANAGER_ID,
                              J.NIVEL + 1,
                              J.RUTA_JERARQUIA || ' ' || E.LAST_NAME
                       FROM HR.EMPLOYEES E
                       JOIN JERARQUIA J
                       ON E.MANAGER_ID = J.EMPLOYEE_ID
                       )
SELECT * FROM JERARQUIA;

```
**PREGUNTAS DEL EJERCICIO**

- Explicar qué ocurre si UNION ALL se reemplaza por UNION y cómo se controlaría un ciclo en los datos.

La clausula **UNION ALL** permite conservar todos los registros obtenidos durante la recursión, mientras que la clausula **UNION** elimina los resultados que sean iguales, lo que puede cambiar la cantidad de registros que se conservan en cada iteración y hacer que Oracle tenga un trabajo adicional de eliminar los duplicados.

### Ejercicio 6.10: Posicionamiento salarial por departamento

**Columnas obligatorias:** employee_id, last_name, department_id, salary, rn, rk, drk, prev_salary,
delta_prev, salary_running_total, dept_avg_salary, pct_vs_dept_avg

- rn, rk y drk corresponden a ROW_NUMBER, RANK y DENSE_RANK sobre la misma partición y el
mismo ordenamiento.
- prev_salary y delta_prev deben calcularse con LAG sobre la fecha de contratación, sin que la
primera fila de cada partición quede en nulo.
- salary_running_total es el acumulado por departamento en orden de contratación.
- El comentario debe señalar un departamento con salarios empatados y explicar sobre esas
filas concretas la diferencia entre las tres numeraciones, además de indicar qué marco de
ventana aplica Oracle por defecto cuando el OVER lleva ORDER BY sin ROWS ni RANGE.

**ANÁLISIS DEL EJERCICIO**

A mi parecer, este ejercicio tiene la consulta más amplia, pero no por esto, la más compleja. Para empezar, se tuvieron que obtener las 12 columnas obligatorias, de las cuales 6 tienen pautas importantes:

- **rn:** Esta columna representa a la función de ventana **"ROW_NUMBER()"**, la cual numera a los empleados de cada departamento del salario más alto al más bajo.
- **rk:** Esta columna representa a la función de ventana **"RANK()"**, la cual numera a los empleados de cada departamento del salario más alto al más bajo, asignando el mismo número dejando un hueco en el conteo si hay empates.
- **drk:** Esta columna representa a la función de ventana **"DENSE_RANK()"**, la cual numera a los empleados de cada departamento del salario más alto al más bajo, asignando el mismo número sin dejar un hueco en el conteo si hay empates.
- **prev_salary:** Esta columna nos pide mostrar el sueldo del empleado anterior del mismo departamento. En el ejercicio, se pide "_sin que la primera fila de cada partición quede en nulo_", para que esto se cumpla, se utilizó la función de ventana **LAG(salary, 1, salary)** la cual, ademas de obtener el valor de la fila anterior, el tercer parametro ayuda a decir que, si no existe una fila anterior, en lugar de devolver NULL, devolverá el salario de la fila actual.
- **delta_prev:** Esta columna nos pide calcular la diferencia entre el sueldo del empleado actual y el del empleado anterior. Para esto, se utilizó la expresion **salary - LAG(salary, 1, salary)** la cual realiza exactamente esa operación.
- **pct_vs_dept_avg:** Esta columna nos pide calcular que porcentaje representa el sueldo del empleado frente al promedio de su propio departamento. Para esto se utilizó la expresión **AVG()** junto con **ROUND()** multiplicandolo por 100 para obtener el procentaje.

**CONSULTA DEL EJERCICIO**

```sql
SELECT employee_id,
       last_name,
       department_id,
       salary,

       ROW_NUMBER() OVER (
           PARTITION BY department_id
           ORDER BY salary DESC
       ) AS rn,

       RANK() OVER (
           PARTITION BY department_id
           ORDER BY salary DESC
       ) AS rk,

       DENSE_RANK() OVER (
           PARTITION BY department_id
           ORDER BY salary DESC
       ) AS drk,

       LAG(salary, 1, salary) OVER (
           PARTITION BY department_id
           ORDER BY hire_date
       ) AS prev_salary,

       salary -
       LAG(salary, 1, salary) OVER (
           PARTITION BY department_id
           ORDER BY hire_date
       ) AS delta_prev,

       SUM(salary) OVER (
           PARTITION BY department_id
           ORDER BY hire_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS salary_running_total,

       AVG(salary) OVER (
           PARTITION BY department_id
       ) AS dept_avg_salary,

       ROUND(
           100 * salary /
           AVG(salary) OVER (
               PARTITION BY department_id
           ),
           2
       ) AS pct_vs_dept_avg

FROM HR.EMPLOYEES
ORDER BY department_id, 
         hire_date;

```
**PREGUNTAS DEL EJERCICIO**
- Señalar un departamento con salarios empatados y explicar sobre esas filas concretas la diferencia entre las tres numeraciones.

Esta el caso del **departamento con id 80**, con los empleados con apellido King, Tucker y Bloom.

-> En el caso de la columna **rn** se les asignó un número diferente a pesar de que estos esten empatados.

-> En el caso de la columna **rk** se les asignó el mismo número, pero al seguir con la cuenta de los empleados, hubo un salto en los números.

-> En el caso de la columna **drk** se les asignó el mismo número, pero al seguir con la cuenta de los demás empleados, no hubo un salto en los números.

- Indicar qué marco de ventana aplica Oracle por defecto cuando el OVER lleva ORDER BY sin ROWS ni RANGE.

Cuando se pone un ORDER BY solo, Oracle aplica por defecto **RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW**, lo cual significa que acumula los datos desde el inicio hasta la fila actual incluyendo todos los valores duplicados en orden.

### Ejercicio 6.11: Tres mejor pagados de cada departamento

**Columnas obligatorias:** department_id, department_name, employee_id, last_name, salary, drk

- No se acepta filtrar el alias de la función de ventana en el WHERE de la misma consulta.
- El comentario debe explicar en qué momento del orden lógico de evaluación se calculan las
funciones de ventana y por qué eso obliga a envolver la consulta.

**ANÁLISIS DEL EJERCICIO**

Para realizar esta consulta se tuvo que entender que, como las funciones de ventana se calculan despues del **WHERE**, no es posible filtrar usando el alias **DRK**, por lo cual se utilizó una subconsulta, donde primero se calcula el ranking con la función **DENSE_RANK()** y luego, en la consulta externa se le hace el filtro de **DRK <= 3**, de esta manera se puediron obtener los tres empleados mejor pagados de cada departamento.

**CONSULTA DEL EJERCICIO**

```sql
SELECT *
FROM ( SELECT D.DEPARTMENT_ID,
       D.DEPARTMENT_NAME,
       E.EMPLOYEE_ID,
       E.LAST_NAME,
       E.SALARY,
       DENSE_RANK() OVER (
                          PARTITION BY D.DEPARTMENT_ID
                          ORDER BY E.SALARY DESC
                          ) AS DRK 
FROM HR.EMPLOYEES E
LEFT JOIN HR.DEPARTMENTS D
ON E.DEPARTMENT_ID = D.DEPARTMENT_ID) 
WHERE DRK <= 3;

```
**PREGUNTAS DEL EJERCICIO**

- ¿En qué momento del orden lógico de evaluación se calculan las funciones de ventana y por qué eso obliga a envolver la consulta?

Las funciones de ventana se calculan despues del **WHERE** en el order lógico de evaluación en SQL, por esta razón es que el WHERE no puede utilizar el resultado de **DENSE_RANK()**. La solución que se aplicó en esta consulta es realizar una subconsulta con la expresión de ventana para que luego en la consulta externa se pueda filtrar este dato.

## PARTE 2. Depuración de consultas defectuosas
## Scripts de la solución del taller

- Aquí puedes descargar el script SQL con la solucion de los puntos de la primera parte del taller.

  [📥 Descargar primera parte](/downloads/Ejercicios_SQLAvanzado.sql)

- Aquí puedes descargar el script SQL con la solución de los puntos de la segunda parte del taller.