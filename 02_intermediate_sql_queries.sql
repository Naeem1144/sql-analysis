-- ============================================
-- INTERMEDIATE SQL QUERIES REFERENCE
-- ============================================

-- ==========================================
-- 1. ADVANCED JOINS AND COMPLEX QUERIES
-- ==========================================

-- Three-way join with aggregations
SELECT 
    p.Passenger_fname,
    p.Passenger_lname,
    t.Train_name,
    b.Total_amount,
    CASE 
        WHEN p.Passenger_age <= 12 THEN "Kids"
        WHEN p.Passenger_age >= 13 AND p.Passenger_age <= 21 THEN "Teenagers"
        WHEN p.Passenger_age >= 22 AND p.Passenger_age <= 64 THEN "Adults"
        WHEN p.Passenger_age >= 65 THEN "Elders"
    END AS age_category
FROM PASSENGERS p
INNER JOIN TRAINS t ON p.Train_id = t.Train_id
INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id;

-- Revenue analysis by age group
SELECT
    CONCAT(ROUND(SUM(b.Total_amount), 2), ' $') AS generated_amount,
    CASE 
        WHEN p.Passenger_age <= 12 THEN "Kids"
        WHEN p.Passenger_age >= 13 AND p.Passenger_age <= 21 THEN "Teenagers"
        WHEN p.Passenger_age >= 22 AND p.Passenger_age <= 64 THEN "Adults"
        WHEN p.Passenger_age >= 65 THEN "Elders"
    END AS age_category,
    COUNT(*) AS passenger_count,
    AVG(b.Total_amount) AS avg_amount_per_passenger
FROM PASSENGERS p
INNER JOIN TRAINS t ON p.Train_id = t.Train_id
INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
GROUP BY age_category
ORDER BY SUM(b.Total_amount) DESC;

-- ==========================================
-- 2. COMPLEX AGGREGATIONS AND ANALYTICS
-- ==========================================

-- Daily revenue analysis with running totals
SELECT 
    DATE(booking_date) AS booking_date,
    ROUND(SUM(total_amount), 2) AS daily_revenue,
    COUNT(*) AS bookings_count,
    AVG(total_amount) AS avg_booking_amount,
    MAX(total_amount) AS max_booking_amount,
    MIN(total_amount) AS min_booking_amount
FROM BOOKINGS
GROUP BY DATE(booking_date)
ORDER BY booking_date;

-- Monthly revenue trends
SELECT 
    YEAR(booking_date) AS booking_year,
    MONTH(booking_date) AS booking_month,
    MONTHNAME(booking_date) AS month_name,
    COUNT(*) AS total_bookings,
    SUM(total_amount) AS monthly_revenue,
    AVG(total_amount) AS avg_booking_value,
    SUM(total_amount) / COUNT(*) AS revenue_per_booking
FROM BOOKINGS
GROUP BY YEAR(booking_date), MONTH(booking_date)
ORDER BY booking_year, booking_month;

-- Train utilization analysis
SELECT 
    t.Train_name,
    t.Train_type,
    COUNT(p.Passenger_id) AS passenger_count,
    AVG(b.Total_amount) AS avg_revenue_per_passenger,
    SUM(b.Total_amount) AS total_revenue,
    t.Length_of_travel
FROM TRAINS t
LEFT JOIN PASSENGERS p ON t.Train_id = p.Train_id
LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
GROUP BY t.Train_id, t.Train_name, t.Train_type, t.Length_of_travel
ORDER BY total_revenue DESC;

-- ==========================================
-- 3. ADVANCED SUBQUERIES AND CORRELATED QUERIES
-- ==========================================

-- Find passengers who spent more than average
SELECT 
    p.Passenger_fname,
    p.Passenger_lname,
    b.Total_amount,
    (SELECT AVG(Total_amount) FROM BOOKINGS) AS system_avg
FROM PASSENGERS p
INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
WHERE b.Total_amount > (SELECT AVG(Total_amount) FROM BOOKINGS)
ORDER BY b.Total_amount DESC;

-- Correlated subquery: Find trains with above-average passengers
SELECT 
    t.Train_name,
    t.Train_type,
    (SELECT COUNT(*) FROM PASSENGERS p WHERE p.Train_id = t.Train_id) AS passenger_count
FROM TRAINS t
WHERE (SELECT COUNT(*) FROM PASSENGERS p WHERE p.Train_id = t.Train_id) > 
      (SELECT AVG(passenger_count) FROM 
       (SELECT COUNT(*) AS passenger_count FROM PASSENGERS GROUP BY Train_id) AS avg_calc);

-- Exists subquery example
SELECT p.Passenger_fname, p.Passenger_lname, p.Passenger_age
FROM PASSENGERS p
WHERE EXISTS (
    SELECT 1 FROM BOOKINGS b 
    WHERE b.Passenger_id = p.Passenger_id 
    AND b.Total_amount > 500
);

-- ==========================================
-- 4. WINDOW FUNCTIONS AND RANKING
-- ==========================================

-- Ranking bookings by amount
SELECT 
    b.Booking_no,
    p.Passenger_fname,
    p.Passenger_lname,
    b.Total_amount,
    RANK() OVER (ORDER BY b.Total_amount DESC) AS amount_rank,
    DENSE_RANK() OVER (ORDER BY b.Total_amount DESC) AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY b.Total_amount DESC) AS row_num
FROM BOOKINGS b
INNER JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id;

-- Running totals and moving averages
SELECT 
    DATE(booking_date) AS booking_date,
    SUM(total_amount) AS daily_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE(booking_date)) AS running_total,
    AVG(SUM(total_amount)) OVER (ORDER BY DATE(booking_date) ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7_days
FROM BOOKINGS
GROUP BY DATE(booking_date)
ORDER BY booking_date;

-- Percentile analysis
SELECT 
    p.Passenger_fname,
    p.Passenger_lname,
    b.Total_amount,
    NTILE(4) OVER (ORDER BY b.Total_amount) AS quartile,
    PERCENT_RANK() OVER (ORDER BY b.Total_amount) AS percent_rank,
    CUME_DIST() OVER (ORDER BY b.Total_amount) AS cumulative_dist
FROM BOOKINGS b
INNER JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id;

-- ==========================================
-- 5. COMPLEX CONDITIONAL LOGIC
-- ==========================================

-- Multi-level categorization
SELECT 
    p.Passenger_fname,
    p.Passenger_lname,
    p.Passenger_age,
    b.Total_amount,
    CASE 
        WHEN p.Passenger_age < 18 THEN 'Minor'
        WHEN p.Passenger_age >= 18 AND p.Passenger_age < 65 THEN 'Adult'
        ELSE 'Senior'
    END AS age_category,
    CASE 
        WHEN b.Total_amount < 100 THEN 'Budget'
        WHEN b.Total_amount >= 100 AND b.Total_amount < 300 THEN 'Standard'
        WHEN b.Total_amount >= 300 AND b.Total_amount < 500 THEN 'Premium'
        ELSE 'Luxury'
    END AS spending_category,
    CASE 
        WHEN p.Passenger_age < 18 AND b.Total_amount < 100 THEN 'Young Budget Traveler'
        WHEN p.Passenger_age >= 65 AND b.Total_amount > 300 THEN 'Senior Premium Traveler'
        WHEN p.Passenger_age BETWEEN 25 AND 40 AND b.Total_amount > 200 THEN 'Professional Traveler'
        ELSE 'Regular Traveler'
    END AS traveler_profile
FROM PASSENGERS p
INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id;

-- ==========================================
-- 6. DATE AND TIME ANALYSIS
-- ==========================================

-- Travel time analysis
SELECT 
    Train_name,
    Train_type,
    First_station,
    Last_station,
    LENGTH_OF_TRAVEL,
    CASE 
        WHEN LENGTH_OF_TRAVEL <= '02:00:00' THEN 'Short Journey'
        WHEN LENGTH_OF_TRAVEL <= '06:00:00' THEN 'Medium Journey'
        ELSE 'Long Journey'
    END AS journey_type,
    HOUR(LENGTH_OF_TRAVEL) AS hours,
    MINUTE(LENGTH_OF_TRAVEL) AS minutes
FROM TRAINS
WHERE LENGTH_OF_TRAVEL IS NOT NULL
ORDER BY LENGTH_OF_TRAVEL;

-- Peak booking times analysis
SELECT 
    HOUR(booking_date) AS booking_hour,
    COUNT(*) AS bookings_count,
    AVG(total_amount) AS avg_amount,
    SUM(total_amount) AS total_revenue
FROM BOOKINGS
GROUP BY HOUR(booking_date)
ORDER BY bookings_count DESC;

-- Day of week analysis
SELECT 
    DAYNAME(booking_date) AS day_name,
    WEEKDAY(booking_date) AS day_number,
    COUNT(*) AS bookings_count,
    AVG(total_amount) AS avg_booking_amount,
    SUM(total_amount) AS total_revenue
FROM BOOKINGS
GROUP BY DAYNAME(booking_date), WEEKDAY(booking_date)
ORDER BY WEEKDAY(booking_date);

-- ==========================================
-- 7. ADVANCED STRING MANIPULATION
-- ==========================================

-- Advanced name formatting
SELECT 
    Passenger_id,
    Passenger_fname,
    Passenger_lname,
    CONCAT(
        UPPER(LEFT(Passenger_fname, 1)),
        LOWER(SUBSTRING(Passenger_fname, 2)),
        ' ',
        UPPER(LEFT(Passenger_lname, 1)),
        LOWER(SUBSTRING(Passenger_lname, 2))
    ) AS formatted_name,
    CONCAT(
        LEFT(Passenger_fname, 1),
        '.',
        LEFT(Passenger_lname, 1),
        '.'
    ) AS initials,
    LENGTH(CONCAT(Passenger_fname, Passenger_lname)) AS name_length
FROM PASSENGERS;

-- Station name analysis
SELECT 
    Train_name,
    First_station,
    Last_station,
    CONCAT(First_station, ' → ', Last_station) AS route,
    CASE 
        WHEN First_station LIKE '%Central%' OR Last_station LIKE '%Central%' THEN 'Central Station Route'
        WHEN First_station LIKE '%Airport%' OR Last_station LIKE '%Airport%' THEN 'Airport Route'
        ELSE 'Regular Route'
    END AS route_type
FROM TRAINS;

-- ==========================================
-- 8. COMPLEX FILTERING AND SEARCH
-- ==========================================

-- Multi-criteria search
SELECT 
    p.Passenger_fname,
    p.Passenger_lname,
    p.Passenger_age,
    b.Total_amount,
    t.Train_name,
    b.Booking_date
FROM PASSENGERS p
INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
INNER JOIN TRAINS t ON p.Train_id = t.Train_id
WHERE p.Passenger_age BETWEEN 25 AND 45
  AND b.Total_amount > 200
  AND t.Train_type = 'Express'
  AND DATE(b.Booking_date) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY b.Total_amount DESC;

-- Pattern matching for passenger names
SELECT 
    Passenger_fname,
    Passenger_lname,
    CASE 
        WHEN Passenger_fname REGEXP '^[A-D]' THEN 'Group A-D'
        WHEN Passenger_fname REGEXP '^[E-H]' THEN 'Group E-H'
        WHEN Passenger_fname REGEXP '^[I-M]' THEN 'Group I-M'
        WHEN Passenger_fname REGEXP '^[N-R]' THEN 'Group N-R'
        WHEN Passenger_fname REGEXP '^[S-Z]' THEN 'Group S-Z'
        ELSE 'Other'
    END AS name_group
FROM PASSENGERS
WHERE Passenger_fname REGEXP '^[A-Za-z]'
ORDER BY name_group, Passenger_fname;

-- ==========================================
-- 9. BACKUP AND MAINTENANCE QUERIES
-- ==========================================

-- Create backup tables with data
CREATE TABLE passengers_backup AS SELECT * FROM PASSENGERS;
CREATE TABLE trains_backup AS SELECT * FROM TRAINS;
CREATE TABLE bookings_backup AS SELECT * FROM BOOKINGS;

-- Compare tables for data integrity
SELECT 'PASSENGERS' AS table_name, COUNT(*) AS record_count FROM PASSENGERS
UNION ALL
SELECT 'PASSENGERS_BACKUP' AS table_name, COUNT(*) AS record_count FROM passengers_backup
UNION ALL
SELECT 'TRAINS' AS table_name, COUNT(*) AS record_count FROM TRAINS
UNION ALL
SELECT 'TRAINS_BACKUP' AS table_name, COUNT(*) AS record_count FROM trains_backup;

-- Find orphaned records
SELECT 'Passengers without bookings' AS issue_type, COUNT(*) AS count
FROM PASSENGERS p
LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
WHERE b.Passenger_id IS NULL

UNION ALL

SELECT 'Bookings without passengers' AS issue_type, COUNT(*) AS count
FROM BOOKINGS b
LEFT JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id
WHERE p.Passenger_id IS NULL

UNION ALL

SELECT 'Passengers without trains' AS issue_type, COUNT(*) AS count
FROM PASSENGERS p
LEFT JOIN TRAINS t ON p.Train_id = t.Train_id
WHERE t.Train_id IS NULL;