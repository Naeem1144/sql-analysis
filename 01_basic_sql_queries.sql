-- ============================================
-- BASIC SQL QUERIES REFERENCE
-- ============================================

-- ==========================================
-- 1. DATABASE AND TABLE CREATION
-- ==========================================

-- Create database
CREATE DATABASE train_booking_system;
USE train_booking_system;

-- Create basic tables
CREATE TABLE BOOKINGS (
    Booking_no INT AUTO_INCREMENT,
    PRIMARY KEY(Booking_no),
    Passenger_id VARCHAR(40) CHECK(LENGTH(passenger_id) = 5),
    Booking_date TIMESTAMP DEFAULT NOW(),
    Total_amount DECIMAL(10,2)
);

CREATE TABLE PASSENGERS (
    Passenger_id VARCHAR(40),
    PRIMARY KEY (passenger_id),
    Passenger_fname VARCHAR(80),
    Passenger_lname VARCHAR(80),
    Passenger_dob DATE,
    Passenger_age INT,
    Train_id VARCHAR(40),
    FOREIGN KEY(Train_id) REFERENCES TRAINS(Train_id)
);

CREATE TABLE TRAINS (
    Train_id VARCHAR(40),
    PRIMARY KEY(train_id),
    Train_name VARCHAR(80),
    Train_type VARCHAR(50),
    First_station VARCHAR(70),
    Last_station VARCHAR(70),
    Departure_time TIMESTAMP,
    Arrival_time TIMESTAMP,
    Length_of_travel TIME
);

-- ==========================================
-- 2. BASIC SELECT QUERIES
-- ==========================================

-- View all records
SELECT * FROM BOOKINGS;
SELECT * FROM PASSENGERS;
SELECT * FROM TRAINS;

-- Select specific columns
SELECT Passenger_fname, Passenger_lname, Passenger_age FROM PASSENGERS;
SELECT Train_name, Train_type, First_station, Last_station FROM TRAINS;

-- Basic filtering with WHERE
SELECT * FROM PASSENGERS WHERE Passenger_age > 18;
SELECT * FROM TRAINS WHERE Train_type = 'Express';
SELECT * FROM BOOKINGS WHERE Total_amount > 100;

-- ==========================================
-- 3. BASIC SORTING AND LIMITING
-- ==========================================

-- Order by single column
SELECT * FROM BOOKINGS ORDER BY Total_amount DESC;
SELECT * FROM PASSENGERS ORDER BY Passenger_age ASC;

-- Order by multiple columns
SELECT * FROM PASSENGERS ORDER BY Passenger_age DESC, Passenger_fname ASC;

-- Limit results
SELECT * FROM BOOKINGS ORDER BY Total_amount DESC LIMIT 10;
SELECT * FROM PASSENGERS ORDER BY Passenger_age DESC LIMIT 5;

-- ==========================================
-- 4. BASIC AGGREGATIONS
-- ==========================================

-- Count records
SELECT COUNT(*) FROM BOOKINGS;
SELECT COUNT(*) FROM PASSENGERS;
SELECT COUNT(DISTINCT Train_id) FROM TRAINS;

-- Sum, Average, Min, Max
SELECT SUM(Total_amount) FROM BOOKINGS;
SELECT AVG(Total_amount) FROM BOOKINGS;
SELECT MIN(Total_amount) FROM BOOKINGS;
SELECT MAX(Total_amount) FROM BOOKINGS;

-- Basic GROUP BY
SELECT Train_name, COUNT(*) FROM TRAINS GROUP BY Train_name;
SELECT DATE(Booking_date) AS booking_date, COUNT(*) AS bookings_count 
FROM BOOKINGS GROUP BY DATE(Booking_date);

-- ==========================================
-- 5. BASIC STRING FUNCTIONS
-- ==========================================

-- String manipulation
SELECT LEFT(Passenger_fname, 2) AS fname_initials, 
       LEFT(Passenger_lname, 2) AS lname_initials  
FROM PASSENGERS;

SELECT CONCAT(Passenger_fname, ' ', Passenger_lname) AS full_name 
FROM PASSENGERS;

SELECT UPPER(Passenger_fname) AS fname_upper, 
       LOWER(Passenger_lname) AS lname_lower 
FROM PASSENGERS;

-- ==========================================
-- 6. BASIC DATE FUNCTIONS
-- ==========================================

-- Date formatting and extraction
SELECT DATE(Booking_date) AS booking_date FROM BOOKINGS;
SELECT YEAR(Passenger_dob) AS birth_year FROM PASSENGERS;
SELECT MONTH(Booking_date) AS booking_month FROM BOOKINGS;
SELECT DAY(Booking_date) AS booking_day FROM BOOKINGS;

-- Current date/time
SELECT NOW() AS current_datetime;
SELECT CURDATE() AS current_date;
SELECT CURTIME() AS current_time;

-- ==========================================
-- 7. BASIC CONDITIONAL LOGIC
-- ==========================================

-- Simple CASE statement
SELECT 
    Passenger_fname,
    Passenger_age,
    CASE 
        WHEN Passenger_age < 18 THEN 'Minor'
        WHEN Passenger_age >= 18 AND Passenger_age < 65 THEN 'Adult'
        ELSE 'Senior'
    END AS age_category
FROM PASSENGERS;

-- Using IF function
SELECT 
    Passenger_fname,
    IF(Passenger_age >= 18, 'Adult', 'Minor') AS age_status
FROM PASSENGERS;

-- ==========================================
-- 8. BASIC JOINS
-- ==========================================

-- INNER JOIN (basic)
SELECT b.Booking_no, b.Total_amount, p.Passenger_fname, p.Passenger_lname
FROM BOOKINGS b
INNER JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id;

-- LEFT JOIN (basic)
SELECT p.Passenger_fname, p.Passenger_lname, t.Train_name
FROM PASSENGERS p
LEFT JOIN TRAINS t ON p.Train_id = t.Train_id;

-- ==========================================
-- 9. BASIC SUBQUERIES
-- ==========================================

-- Subquery in WHERE clause
SELECT * FROM BOOKINGS 
WHERE Total_amount > (SELECT AVG(Total_amount) FROM BOOKINGS);

-- Subquery in SELECT clause
SELECT 
    Passenger_fname,
    Passenger_age,
    (SELECT AVG(Passenger_age) FROM PASSENGERS) AS avg_age
FROM PASSENGERS;

-- ==========================================
-- 10. BASIC PATTERN MATCHING
-- ==========================================

-- LIKE operator
SELECT * FROM PASSENGERS WHERE Passenger_fname LIKE 'A%';
SELECT * FROM PASSENGERS WHERE Passenger_lname LIKE '%son';
SELECT * FROM TRAINS WHERE Train_name LIKE '%Express%';

-- IN operator
SELECT * FROM PASSENGERS WHERE Passenger_age IN (25, 30, 35);
SELECT * FROM TRAINS WHERE Train_type IN ('Express', 'Local');

-- BETWEEN operator
SELECT * FROM PASSENGERS WHERE Passenger_age BETWEEN 25 AND 35;
SELECT * FROM BOOKINGS WHERE Total_amount BETWEEN 50 AND 200;