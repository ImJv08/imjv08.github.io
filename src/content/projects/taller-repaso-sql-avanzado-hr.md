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


## PARTE 2. Depuración de consultas defectuosas
## Script del taller solucionado

Aquí puedes descargar el script SQL con la solucion de los puntos explicados del taller.

[📥 Descargar script SQL](/downloads/Ejercicios_SQLAvanzado.sql)