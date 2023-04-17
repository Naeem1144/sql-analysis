USE PROJECTS;

SELECT * FROM STORES_DATA;

----------------------------------------------------------------------------------------------------
-- List the three stores with the highest number of customer transaction

SELECT 
    STORE_ID,
    STORE_NAME AS TOP_THREE_STORES,
    total_monthly_transaction
FROM
    STORES_DATA
ORDER BY total_monthly_transaction DESC
LIMIT 3;
------------------------------------------------------------------------------------------------------
-- Extract employee IDs for all employees who earned a three or high on their last performance review

SELECT * FROM EMPLOYEE_DATA;

SELECT EMPLOYEE_ID AS `EMPLOYEES WITH 3 OR MORE IN REVIEW SCORE`FROM EMPLOYEE_DATA 
WHERE performance_review > 3
ORDER BY performance_review DESC;

-------------------------------------------------------------------------------------------------------------
--  Calculate the average monthly sales by product displayed in descending order

SELECT 
    *
FROM
    SALES_DATA;

SELECT 
    PRODUCT, ROUND(AVG(TOTAL_AMOUNT)) AS AVERAGE
FROM
    SALES_DATA
GROUP BY PRODUCT;

----------------------------------------------------------------------------------------
-- Find and remove duplicate in the table without creating another table.

SELECT 
    *
FROM
    NEW_EMPLOYEES;


DELETE t1 FROM new_employees AS t1
        INNER JOIN
    new_employees AS t2 
WHERE
    t1.indx < t2.indx
    AND t1.fname = t2.fname
    AND t1.lname = t2.lname;

---------------------------------------------------------------------------------------------
-- Identify the common record between two tables

SELECT 
    *
FROM
    NEW_EMPLOYEES1;

SELECT DISTINCT
    new_employees.fname, new_employees.lname
FROM
    new_employees
        INNER JOIN
    NEW_EMPLOYEES1 ON NEW_EMPLOYEES.fname = NEW_EMPLOYEES1.fname;

------------------------------------------------------------------------------------------------







