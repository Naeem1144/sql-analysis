-- ============================================
-- ADVANCED SQL QUERIES AND TECHNIQUES
-- ============================================

-- ==========================================
-- 1. COMMON TABLE EXPRESSIONS (CTEs)
-- ==========================================

-- Basic CTE for readable complex queries
WITH passenger_revenue AS (
    SELECT 
        p.Passenger_id,
        p.Passenger_fname,
        p.Passenger_lname,
        p.Passenger_age,
        b.Total_amount,
        t.Train_name,
        t.Train_type,
        ROW_NUMBER() OVER (PARTITION BY p.Passenger_id ORDER BY b.Total_amount DESC) as booking_rank
    FROM PASSENGERS p
    INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    INNER JOIN TRAINS t ON p.Train_id = t.Train_id
),
age_groups AS (
    SELECT 
        CASE 
            WHEN Passenger_age < 18 THEN 'Minor'
            WHEN Passenger_age BETWEEN 18 AND 25 THEN 'Young Adult'
            WHEN Passenger_age BETWEEN 26 AND 40 THEN 'Adult'
            WHEN Passenger_age BETWEEN 41 AND 60 THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_group,
        COUNT(*) AS group_count,
        AVG(Total_amount) AS avg_spending,
        SUM(Total_amount) AS total_revenue
    FROM passenger_revenue
    GROUP BY age_group
)
SELECT 
    ag.age_group,
    ag.group_count,
    ag.avg_spending,
    ag.total_revenue,
    ROUND((ag.total_revenue / SUM(ag.total_revenue) OVER()) * 100, 2) AS revenue_percentage
FROM age_groups ag
ORDER BY ag.total_revenue DESC;

-- Multiple CTEs for complex analysis
WITH monthly_stats AS (
    SELECT 
        YEAR(booking_date) AS booking_year,
        MONTH(booking_date) AS booking_month,
        COUNT(*) AS monthly_bookings,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS avg_booking_value
    FROM BOOKINGS
    GROUP BY YEAR(booking_date), MONTH(booking_date)
),
growth_analysis AS (
    SELECT 
        booking_year,
        booking_month,
        monthly_bookings,
        monthly_revenue,
        avg_booking_value,
        LAG(monthly_revenue) OVER (ORDER BY booking_year, booking_month) AS prev_month_revenue,
        LAG(monthly_bookings) OVER (ORDER BY booking_year, booking_month) AS prev_month_bookings
    FROM monthly_stats
),
performance_metrics AS (
    SELECT 
        booking_year,
        booking_month,
        monthly_bookings,
        monthly_revenue,
        avg_booking_value,
        CASE 
            WHEN prev_month_revenue IS NULL THEN 0
            ELSE ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2)
        END AS revenue_growth_pct,
        CASE 
            WHEN prev_month_bookings IS NULL THEN 0
            ELSE ROUND(((monthly_bookings - prev_month_bookings) / prev_month_bookings) * 100, 2)
        END AS booking_growth_pct
    FROM growth_analysis
)
SELECT 
    booking_year,
    booking_month,
    monthly_bookings,
    monthly_revenue,
    avg_booking_value,
    revenue_growth_pct,
    booking_growth_pct,
    CASE 
        WHEN revenue_growth_pct > 10 THEN 'High Growth'
        WHEN revenue_growth_pct > 0 THEN 'Positive Growth'
        WHEN revenue_growth_pct = 0 THEN 'No Growth'
        ELSE 'Negative Growth'
    END AS growth_category
FROM performance_metrics
ORDER BY booking_year, booking_month;

-- ==========================================
-- 2. RECURSIVE QUERIES (HIERARCHICAL DATA)
-- ==========================================

-- Create a route hierarchy table for demonstration
CREATE TABLE route_hierarchy (
    route_id INT PRIMARY KEY,
    route_name VARCHAR(100),
    parent_route_id INT,
    route_level INT,
    FOREIGN KEY (parent_route_id) REFERENCES route_hierarchy(route_id)
);

-- Insert sample hierarchical data
INSERT INTO route_hierarchy VALUES 
(1, 'Main Network', NULL, 1),
(2, 'Northern Region', 1, 2),
(3, 'Southern Region', 1, 2),
(4, 'Express Lines', 2, 3),
(5, 'Local Lines', 2, 3),
(6, 'Intercity Routes', 3, 3),
(7, 'Suburban Routes', 3, 3),
(8, 'High Speed Express', 4, 4),
(9, 'Regular Express', 4, 4);

-- Recursive CTE to traverse route hierarchy
WITH RECURSIVE route_tree AS (
    -- Base case: start with top-level routes
    SELECT 
        route_id,
        route_name,
        parent_route_id,
        route_level,
        CAST(route_name AS CHAR(1000)) AS route_path,
        0 AS depth
    FROM route_hierarchy
    WHERE parent_route_id IS NULL
    
    UNION ALL
    
    -- Recursive case: find child routes
    SELECT 
        rh.route_id,
        rh.route_name,
        rh.parent_route_id,
        rh.route_level,
        CONCAT(rt.route_path, ' > ', rh.route_name) AS route_path,
        rt.depth + 1 AS depth
    FROM route_hierarchy rh
    INNER JOIN route_tree rt ON rh.parent_route_id = rt.route_id
)
SELECT 
    route_id,
    route_name,
    parent_route_id,
    route_level,
    route_path,
    depth,
    REPEAT('  ', depth) AS indentation
FROM route_tree
ORDER BY route_path;

-- ==========================================
-- 3. ADVANCED ANALYTICAL FUNCTIONS
-- ==========================================

-- Cohort analysis for passenger booking behavior
WITH passenger_cohorts AS (
    SELECT 
        p.Passenger_id,
        p.Passenger_fname,
        p.Passenger_lname,
        MIN(DATE(b.Booking_date)) AS first_booking_date,
        COUNT(b.Booking_no) AS total_bookings,
        SUM(b.Total_amount) AS lifetime_value,
        MAX(DATE(b.Booking_date)) AS last_booking_date,
        DATEDIFF(MAX(DATE(b.Booking_date)), MIN(DATE(b.Booking_date))) AS customer_lifespan_days
    FROM PASSENGERS p
    INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    GROUP BY p.Passenger_id, p.Passenger_fname, p.Passenger_lname
),
cohort_metrics AS (
    SELECT 
        *,
        CASE 
            WHEN total_bookings = 1 THEN 'One-time Customer'
            WHEN total_bookings BETWEEN 2 AND 5 THEN 'Occasional Customer'
            WHEN total_bookings BETWEEN 6 AND 10 THEN 'Regular Customer'
            ELSE 'Loyal Customer'
        END AS customer_segment,
        CASE 
            WHEN lifetime_value < 200 THEN 'Low Value'
            WHEN lifetime_value BETWEEN 200 AND 500 THEN 'Medium Value'
            WHEN lifetime_value BETWEEN 500 AND 1000 THEN 'High Value'
            ELSE 'Premium Value'
        END AS value_segment
    FROM passenger_cohorts
)
SELECT 
    customer_segment,
    value_segment,
    COUNT(*) AS customer_count,
    AVG(lifetime_value) AS avg_lifetime_value,
    AVG(total_bookings) AS avg_bookings_per_customer,
    AVG(customer_lifespan_days) AS avg_customer_lifespan,
    SUM(lifetime_value) AS total_segment_value,
    ROUND((SUM(lifetime_value) / SUM(SUM(lifetime_value)) OVER()) * 100, 2) AS segment_revenue_percentage
FROM cohort_metrics
GROUP BY customer_segment, value_segment
ORDER BY total_segment_value DESC;

-- Advanced time series analysis with seasonality
WITH daily_metrics AS (
    SELECT 
        DATE(booking_date) AS booking_date,
        DAYNAME(booking_date) AS day_name,
        WEEK(booking_date) AS week_number,
        MONTH(booking_date) AS month_number,
        QUARTER(booking_date) AS quarter_number,
        COUNT(*) AS daily_bookings,
        SUM(total_amount) AS daily_revenue,
        AVG(total_amount) AS avg_booking_value
    FROM BOOKINGS
    GROUP BY DATE(booking_date)
),
time_series_analysis AS (
    SELECT 
        *,
        -- Moving averages
        AVG(daily_revenue) OVER (ORDER BY booking_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7_day,
        AVG(daily_revenue) OVER (ORDER BY booking_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30_day,
        
        -- Lag functions for period comparisons
        LAG(daily_revenue, 7) OVER (ORDER BY booking_date) AS revenue_7_days_ago,
        LAG(daily_revenue, 30) OVER (ORDER BY booking_date) AS revenue_30_days_ago,
        
        -- Percentile rankings
        PERCENT_RANK() OVER (ORDER BY daily_revenue) AS revenue_percentile,
        NTILE(10) OVER (ORDER BY daily_revenue) AS revenue_decile,
        
        -- Standard deviation for volatility analysis
        STDDEV(daily_revenue) OVER (ORDER BY booking_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS revenue_volatility_30_day
    FROM daily_metrics
)
SELECT 
    booking_date,
    day_name,
    daily_bookings,
    daily_revenue,
    avg_booking_value,
    ma_7_day,
    ma_30_day,
    CASE 
        WHEN revenue_7_days_ago IS NULL THEN 0
        ELSE ROUND(((daily_revenue - revenue_7_days_ago) / revenue_7_days_ago) * 100, 2)
    END AS wow_growth_pct,
    CASE 
        WHEN revenue_30_days_ago IS NULL THEN 0
        ELSE ROUND(((daily_revenue - revenue_30_days_ago) / revenue_30_days_ago) * 100, 2)
    END AS mom_growth_pct,
    revenue_percentile,
    revenue_decile,
    revenue_volatility_30_day,
    CASE 
        WHEN revenue_decile >= 9 THEN 'Peak Performance'
        WHEN revenue_decile >= 7 THEN 'High Performance'
        WHEN revenue_decile >= 4 THEN 'Average Performance'
        WHEN revenue_decile >= 2 THEN 'Below Average'
        ELSE 'Low Performance'
    END AS performance_category
FROM time_series_analysis
ORDER BY booking_date;

-- ==========================================
-- 4. ADVANCED PIVOTING AND UNPIVOTING
-- ==========================================

-- Dynamic pivot for train type performance by month
SELECT 
    MONTHNAME(b.Booking_date) AS month_name,
    SUM(CASE WHEN t.Train_type = 'Express' THEN b.Total_amount ELSE 0 END) AS express_revenue,
    SUM(CASE WHEN t.Train_type = 'Local' THEN b.Total_amount ELSE 0 END) AS local_revenue,
    SUM(CASE WHEN t.Train_type = 'Intercity' THEN b.Total_amount ELSE 0 END) AS intercity_revenue,
    SUM(CASE WHEN t.Train_type = 'High Speed' THEN b.Total_amount ELSE 0 END) AS high_speed_revenue,
    
    COUNT(CASE WHEN t.Train_type = 'Express' THEN 1 END) AS express_bookings,
    COUNT(CASE WHEN t.Train_type = 'Local' THEN 1 END) AS local_bookings,
    COUNT(CASE WHEN t.Train_type = 'Intercity' THEN 1 END) AS intercity_bookings,
    COUNT(CASE WHEN t.Train_type = 'High Speed' THEN 1 END) AS high_speed_bookings,
    
    AVG(CASE WHEN t.Train_type = 'Express' THEN b.Total_amount END) AS express_avg_booking,
    AVG(CASE WHEN t.Train_type = 'Local' THEN b.Total_amount END) AS local_avg_booking,
    AVG(CASE WHEN t.Train_type = 'Intercity' THEN b.Total_amount END) AS intercity_avg_booking,
    AVG(CASE WHEN t.Train_type = 'High Speed' THEN b.Total_amount END) AS high_speed_avg_booking
FROM BOOKINGS b
INNER JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id
INNER JOIN TRAINS t ON p.Train_id = t.Train_id
GROUP BY MONTH(b.Booking_date), MONTHNAME(b.Booking_date)
ORDER BY MONTH(b.Booking_date);

-- ==========================================
-- 5. ADVANCED PATTERN MATCHING AND ANALYTICS
-- ==========================================

-- Sequence analysis for booking patterns
WITH booking_sequences AS (
    SELECT 
        b.Passenger_id,
        b.Booking_date,
        b.Total_amount,
        t.Train_type,
        LAG(t.Train_type) OVER (PARTITION BY b.Passenger_id ORDER BY b.Booking_date) AS prev_train_type,
        LAG(b.Total_amount) OVER (PARTITION BY b.Passenger_id ORDER BY b.Booking_date) AS prev_amount,
        LEAD(t.Train_type) OVER (PARTITION BY b.Passenger_id ORDER BY b.Booking_date) AS next_train_type,
        LEAD(b.Total_amount) OVER (PARTITION BY b.Passenger_id ORDER BY b.Booking_date) AS next_amount,
        ROW_NUMBER() OVER (PARTITION BY b.Passenger_id ORDER BY b.Booking_date) AS booking_sequence
    FROM BOOKINGS b
    INNER JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id
    INNER JOIN TRAINS t ON p.Train_id = t.Train_id
),
pattern_analysis AS (
    SELECT 
        Passenger_id,
        Train_type,
        prev_train_type,
        next_train_type,
        Total_amount,
        prev_amount,
        next_amount,
        booking_sequence,
        CASE 
            WHEN prev_train_type IS NULL THEN 'First Booking'
            WHEN prev_train_type = Train_type THEN 'Repeat Same Type'
            WHEN prev_train_type != Train_type THEN 'Type Switch'
            ELSE 'Other'
        END AS booking_pattern,
        CASE 
            WHEN prev_amount IS NULL THEN 'First Booking'
            WHEN Total_amount > prev_amount THEN 'Spending Increase'
            WHEN Total_amount < prev_amount THEN 'Spending Decrease'
            ELSE 'Same Spending'
        END AS spending_pattern
    FROM booking_sequences
)
SELECT 
    booking_pattern,
    spending_pattern,
    COUNT(*) AS occurrence_count,
    AVG(Total_amount) AS avg_booking_amount,
    ROUND((COUNT(*) / SUM(COUNT(*)) OVER()) * 100, 2) AS percentage_of_bookings
FROM pattern_analysis
WHERE booking_pattern != 'First Booking'
GROUP BY booking_pattern, spending_pattern
ORDER BY occurrence_count DESC;

-- ==========================================
-- 6. ADVANCED STATISTICAL ANALYSIS
-- ==========================================

-- Statistical distribution analysis
WITH statistical_metrics AS (
    SELECT 
        b.Total_amount,
        (b.Total_amount - AVG(b.Total_amount) OVER()) AS deviation_from_mean,
        POWER(b.Total_amount - AVG(b.Total_amount) OVER(), 2) AS squared_deviation,
        RANK() OVER (ORDER BY b.Total_amount) AS amount_rank,
        COUNT(*) OVER() AS total_records
    FROM BOOKINGS b
),
distribution_stats AS (
    SELECT 
        COUNT(*) AS total_bookings,
        AVG(Total_amount) AS mean_amount,
        STDDEV(Total_amount) AS std_dev,
        MIN(Total_amount) AS min_amount,
        MAX(Total_amount) AS max_amount,
        
        -- Percentiles
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.25)) AS p25,
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.50)) AS median,
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.75)) AS p75,
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.90)) AS p90,
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.95)) AS p95,
        (SELECT Total_amount FROM statistical_metrics WHERE amount_rank = ROUND(total_records * 0.99)) AS p99,
        
        -- Variance and coefficient of variation
        VARIANCE(Total_amount) AS variance_amount,
        (STDDEV(Total_amount) / AVG(Total_amount)) * 100 AS coefficient_of_variation
    FROM BOOKINGS
)
SELECT 
    'Total Bookings' AS metric, CAST(total_bookings AS DECIMAL(10,2)) AS value FROM distribution_stats
UNION ALL
SELECT 'Mean Amount' AS metric, mean_amount AS value FROM distribution_stats
UNION ALL
SELECT 'Standard Deviation' AS metric, std_dev AS value FROM distribution_stats
UNION ALL
SELECT 'Minimum Amount' AS metric, min_amount AS value FROM distribution_stats
UNION ALL
SELECT 'Maximum Amount' AS metric, max_amount AS value FROM distribution_stats
UNION ALL
SELECT '25th Percentile' AS metric, p25 AS value FROM distribution_stats
UNION ALL
SELECT 'Median (50th Percentile)' AS metric, median AS value FROM distribution_stats
UNION ALL
SELECT '75th Percentile' AS metric, p75 AS value FROM distribution_stats
UNION ALL
SELECT '90th Percentile' AS metric, p90 AS value FROM distribution_stats
UNION ALL
SELECT '95th Percentile' AS metric, p95 AS value FROM distribution_stats
UNION ALL
SELECT '99th Percentile' AS metric, p99 AS value FROM distribution_stats
UNION ALL
SELECT 'Variance' AS metric, variance_amount AS value FROM distribution_stats
UNION ALL
SELECT 'Coefficient of Variation (%)' AS metric, coefficient_of_variation AS value FROM distribution_stats;

-- ==========================================
-- 7. ADVANCED OPTIMIZATION TECHNIQUES
-- ==========================================

-- Query optimization with proper indexing suggestions
-- Create indexes for better performance
CREATE INDEX idx_bookings_date_amount ON BOOKINGS(Booking_date, Total_amount);
CREATE INDEX idx_passengers_age_train ON PASSENGERS(Passenger_age, Train_id);
CREATE INDEX idx_trains_type_name ON TRAINS(Train_type, Train_name);

-- Optimized query using covering indexes
SELECT 
    DATE(b.Booking_date) AS booking_date,
    COUNT(*) AS daily_bookings,
    SUM(b.Total_amount) AS daily_revenue,
    AVG(b.Total_amount) AS avg_booking_value
FROM BOOKINGS b
WHERE b.Booking_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY DATE(b.Booking_date)
ORDER BY DATE(b.Booking_date);

-- ==========================================
-- 8. ADVANCED DATA QUALITY AND VALIDATION
-- ==========================================

-- Comprehensive data quality assessment
WITH data_quality_checks AS (
    SELECT 
        'BOOKINGS' AS table_name,
        'Total Records' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM BOOKINGS
    
    UNION ALL
    
    SELECT 
        'BOOKINGS' AS table_name,
        'NULL Passenger_id' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM BOOKINGS
    WHERE Passenger_id IS NULL
    
    UNION ALL
    
    SELECT 
        'BOOKINGS' AS table_name,
        'Invalid Total_amount (negative)' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM BOOKINGS
    WHERE Total_amount < 0
    
    UNION ALL
    
    SELECT 
        'BOOKINGS' AS table_name,
        'Future Booking Dates' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM BOOKINGS
    WHERE Booking_date > NOW()
    
    UNION ALL
    
    SELECT 
        'PASSENGERS' AS table_name,
        'Total Records' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM PASSENGERS
    
    UNION ALL
    
    SELECT 
        'PASSENGERS' AS table_name,
        'Invalid Age (negative or > 150)' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM PASSENGERS
    WHERE Passenger_age < 0 OR Passenger_age > 150
    
    UNION ALL
    
    SELECT 
        'PASSENGERS' AS table_name,
        'Future Birth Dates' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM PASSENGERS
    WHERE Passenger_dob > CURDATE()
    
    UNION ALL
    
    SELECT 
        'TRAINS' AS table_name,
        'Total Records' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM TRAINS
    
    UNION ALL
    
    SELECT 
        'TRAINS' AS table_name,
        'Invalid Travel Times (arrival before departure)' AS check_type,
        COUNT(*) AS check_result,
        'Count' AS result_type
    FROM TRAINS
    WHERE Arrival_time < Departure_time
)
SELECT 
    table_name,
    check_type,
    check_result,
    CASE 
        WHEN check_type LIKE '%Total Records%' THEN 'INFO'
        WHEN check_result = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM data_quality_checks
ORDER BY table_name, check_type;

-- ==========================================
-- 9. ADVANCED STORED PROCEDURES AND FUNCTIONS
-- ==========================================

-- Advanced stored procedure for customer segmentation
DELIMITER //
CREATE PROCEDURE GetCustomerSegmentation(
    IN segment_date DATE,
    IN min_bookings INT DEFAULT 1,
    IN min_revenue DECIMAL(10,2) DEFAULT 0.00
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Create temporary table for analysis
    CREATE TEMPORARY TABLE temp_customer_segments AS
    WITH customer_metrics AS (
        SELECT 
            p.Passenger_id,
            p.Passenger_fname,
            p.Passenger_lname,
            p.Passenger_age,
            COUNT(b.Booking_no) AS total_bookings,
            SUM(b.Total_amount) AS total_revenue,
            AVG(b.Total_amount) AS avg_booking_value,
            MIN(b.Booking_date) AS first_booking_date,
            MAX(b.Booking_date) AS last_booking_date,
            DATEDIFF(segment_date, MAX(b.Booking_date)) AS days_since_last_booking
        FROM PASSENGERS p
        INNER JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
        WHERE DATE(b.Booking_date) <= segment_date
        GROUP BY p.Passenger_id, p.Passenger_fname, p.Passenger_lname, p.Passenger_age
        HAVING COUNT(b.Booking_no) >= min_bookings 
        AND SUM(b.Total_amount) >= min_revenue
    ),
    rfm_analysis AS (
        SELECT 
            *,
            NTILE(5) OVER (ORDER BY days_since_last_booking) AS recency_score,
            NTILE(5) OVER (ORDER BY total_bookings DESC) AS frequency_score,
            NTILE(5) OVER (ORDER BY total_revenue DESC) AS monetary_score
        FROM customer_metrics
    )
    SELECT 
        *,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score >= 3 THEN 'Potential Loyalists'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Promising'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Need Attention'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'About to Sleep'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_analysis;
    
    -- Return results
    SELECT 
        customer_segment,
        COUNT(*) AS customer_count,
        AVG(total_revenue) AS avg_revenue,
        AVG(total_bookings) AS avg_bookings,
        AVG(days_since_last_booking) AS avg_days_since_last_booking,
        SUM(total_revenue) AS segment_total_revenue
    FROM temp_customer_segments
    GROUP BY customer_segment
    ORDER BY segment_total_revenue DESC;
    
    -- Cleanup
    DROP TEMPORARY TABLE temp_customer_segments;
    
    COMMIT;
END //
DELIMITER ;

-- ==========================================
-- 10. ADVANCED TRIGGERS AND AUTOMATION
-- ==========================================

-- Advanced trigger for comprehensive audit trail
CREATE TABLE audit_log (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    operation_type VARCHAR(10),
    record_id VARCHAR(100),
    old_values JSON,
    new_values JSON,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

DELIMITER //
CREATE TRIGGER bookings_audit_trigger
AFTER UPDATE ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation_type,
        record_id,
        old_values,
        new_values,
        changed_by
    ) VALUES (
        'BOOKINGS',
        'UPDATE',
        NEW.Booking_no,
        JSON_OBJECT(
            'Passenger_id', OLD.Passenger_id,
            'Booking_date', OLD.Booking_date,
            'Total_amount', OLD.Total_amount
        ),
        JSON_OBJECT(
            'Passenger_id', NEW.Passenger_id,
            'Booking_date', NEW.Booking_date,
            'Total_amount', NEW.Total_amount
        ),
        USER()
    );
END //
DELIMITER ;