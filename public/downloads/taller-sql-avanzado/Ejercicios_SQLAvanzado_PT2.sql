--DEPURACIÓN DE CONSULTAS DEFECTUOSAS

--Consulta I.1

/* Se tiene que cambiar el COUNT(*) a COUNT(e.employee_id) porque al utilizar un
   LEFT JOIN puede traer departamentos que no tienen empleados, marcandolos como NULL.
   Para obtener cero en los departamentos sin empleados, se debe utilizar especificamente
   la columna de empleados, utilizando la segunda versión, ya que este no toma
   los NULL como uno.
   
   Adicionalmente se le agrego el alias "cantidad_empleados" a la columna
   del conteo de empleados para mejor entendimiento.
*/   
SELECT d.department_name, 
       COUNT(e.employee_id) AS cantidad_empleados
FROM hr.departments d 
LEFT JOIN hr.employees e
ON d.department_id = e.department_id
GROUP BY d.department_name;

--Consulta I.2

/* En esta ocasión se le tuvo que agregar la clausula IS NOT NULL, debido a que.
  si NOT IN incluye nulos, puede devolver UNKNOWN y causar errores en la salida,
  con esta nueva clausula se puede decir que solo se quiere tomar en cuenta
  a los departamentos que tengan empleados.
*/

SELECT last_name 
FROM hr.employees 
WHERE department_id NOT IN (10, 20, 30) 
  AND department_id IS NOT NULL;

--Consulta I.3

/* Aqui igualmente al utilizar el COUNT(*) genera un error con respecto a los
   departamentos que no tengan empleados. Tambien hay un punto importante, y es
   el LEFT JOIN de departamentos y ubicaciones. Esta clausula se cambió por un
   JOIN debido a que no tiene sentido obtener todos los departamentos si en la
   clausula WHERE se esta filtrando esta ubicación.
   
    Adicionalmente se le agrego el alias "cantidad_empleados" a la columna
   del conteo de empleados para mejor entendimiento.
*/

SELECT d.department_name, 
       COUNT(e.employee_id) AS cantidad_empleados
FROM hr.departments d
LEFT JOIN hr.employees e 
ON d.department_id = e.department_id
JOIN hr.locations l 
ON d.location_id = l.location_id
WHERE l.country_id = 'US'
GROUP BY d.department_name;

--Consulta I.4

/* Esta consulta estaba dando un resultado incorrecto debido a que se estaba
   incluyendo la columna "last_name" en el GROUP BY, lo que causaba que el
   MAX(salary) no se calcule solo para cada departamento sino que tambien por cada
   apellido de cada departamento, lo que terminaba dando como respuesta practicamente
   el salario propio de cada empleado. 
*/
SELECT department_id,
       MAX(salary) AS mejor_pagado
FROM hr.employees
GROUP BY department_id;

--Consulta I.5

/* El problema con esta consulta era que, al hacer el promedio, no se estaba
   tomando como 0 a quienes no reciben comision, lo que estaba causando que
   el resultado fuera incorrecto.
*/

SELECT AVG(NVL(commission_pct, 0)) AS prom_commission
FROM hr.employees;