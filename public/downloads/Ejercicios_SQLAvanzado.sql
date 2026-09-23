SELECT *
FROM HR.EMPLOYEES;
--Ejercicio 6.2--

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

--Ejercicio 6.3--
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

--Ejercicio 6.5--
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       D.DEPARTMENT_ID,
       E.SALARY,
       E.COMMISSION_PCT,
       E.SALARY + (E.SALARY * NVL(E.COMMISSION_PCT,0)) AS TOTAL_COMPENSARTION,
       CASE
          WHEN NOT EXISTS (
             SELECT 1
             FROM HR.EMPLOYEES M
             WHERE M.MANAGER_ID = E.EMPLOYEE_ID
          )
          THEN 'NO'
          ELSE 'SI'
          END AS ES_JEFE
FROM HR.EMPLOYEES E
LEFT JOIN HR.DEPARTMENTS D
ON E.DEPARTMENT_ID = D.DEPARTMENT_ID;

--Ejercicio 6.6--
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

--Ejercicio 6.7--
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

-- Ejercico 6.8 --

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
            WHEN E.EMPLOYEE_ID IN (SELECT EMPLOYEE_ID
                                   FROM CON_H)
            THEN 'CON HISTORIAL'
            ELSE 'SIN HISTORIAL'
        END
        ) AS MOVILIDAD_STATUS
FROM HR.EMPLOYEES E;

SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       (CASE
           WHEN NOT EXISTS (
                            SELECT 1
                            FROM HR.JOB_HISTORY J
                            WHERE E.EMPLOYEE_ID = J.EMPLOYEE_ID
                            )
           THEN 'SIN HISTORIAL'
           ELSE 'CON HISTORIAL'
        END
        ) AS MOVILIDAD_STATUS
FROM HR.EMPLOYEES E;

-- Ejercicio 6.9 --

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

-- Ejercicio 6.10 --            
                                          
SELECT E.EMPLOYEE_ID,
       E.LAST_NAME,
       E.DEPARTMENT_ID,
       E.SALARY,
       ROW_NUMBER() OVER (
                          PARTITION BY E.DEPARTMENT_ID
                          ORDER BY E.SALARY DESC
                          ) AS RN,
       RANK() OVER (
                   PARTITION BY E.DEPARTMENT_ID
                   ORDER BY E.SALARY DESC
                   ) AS RK,
       DENSE_RANK() OVER (
                         PARTITION BY E.DEPARTMENT_ID
                         ORDER BY E.SALARY DESC
                         ) AS DRK,
      LAG(E.SALARY,1,0) OVER (
                          PARTITION BY E.DEPARTMENT_ID
                          ORDER BY E.HIRE_DATE
                          ) AS PREV_SALARY,
      E.SALARY - (LAG(E.SALARY,1,0) OVER (
                                          PARTITION BY E.DEPARTMENT_ID
                                          ORDER BY E.HIRE_DATE
                                          )
                  ) AS DELTA_PREV,
      SUM(E.SALARY) OVER (
                          PARTITION BY E.DEPARTMENT_ID
                          ORDER BY E.HIRE_DATE
                          ) AS SALARY_RUNNING_TOTAL,
      AVG(E.SALARY) OVER (
                          PARTITION BY E.DEPARTMENT_ID
                          ) AS DEPT_AVG_SALARY,
      (E.SALARY - AVG(E.SALARY) OVER (
                                      PARTITION BY E.DEPARTMENT_ID
                                      )) / AVG(E.SALARY) OVER (
                                                               PARTITION BY E.DEPARTMENT_ID
                                                               ) * 100 AS PCT_VS_AVG
                          
                        
FROM HR.EMPLOYEES E;

-- Ejercico 6.11 --

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