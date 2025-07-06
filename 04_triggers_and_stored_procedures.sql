-- ============================================
-- TRIGGERS AND STORED PROCEDURES
-- ============================================

-- ==========================================
-- 1. DATABASE SETUP AND MAINTENANCE
-- ==========================================

-- Stored procedure to clear entire database
DELIMITER //
CREATE PROCEDURE EMPTY_DATA()
BEGIN
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE BOOKINGS;
    TRUNCATE TABLE PASSENGERS;
    TRUNCATE TABLE TRAINS;
    SET FOREIGN_KEY_CHECKS = 1;
END //
DELIMITER ;

-- Stored procedure for database backup
DELIMITER //
CREATE PROCEDURE CREATE_BACKUP_TABLES()
BEGIN
    -- Create backup tables with current timestamp
    SET @timestamp = DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s');
    
    SET @sql = CONCAT('CREATE TABLE bookings_backup_', @timestamp, ' AS SELECT * FROM BOOKINGS');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SET @sql = CONCAT('CREATE TABLE passengers_backup_', @timestamp, ' AS SELECT * FROM PASSENGERS');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SET @sql = CONCAT('CREATE TABLE trains_backup_', @timestamp, ' AS SELECT * FROM TRAINS');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SELECT CONCAT('Backup tables created with timestamp: ', @timestamp) AS message;
END //
DELIMITER ;

-- Stored procedure for data integrity check
DELIMITER //
CREATE PROCEDURE CHECK_DATA_INTEGRITY()
BEGIN
    DECLARE orphaned_bookings INT DEFAULT 0;
    DECLARE orphaned_passengers INT DEFAULT 0;
    DECLARE invalid_ages INT DEFAULT 0;
    DECLARE future_bookings INT DEFAULT 0;
    DECLARE negative_amounts INT DEFAULT 0;
    
    -- Check for orphaned bookings
    SELECT COUNT(*) INTO orphaned_bookings
    FROM BOOKINGS b
    LEFT JOIN PASSENGERS p ON b.Passenger_id = p.Passenger_id
    WHERE p.Passenger_id IS NULL;
    
    -- Check for orphaned passengers
    SELECT COUNT(*) INTO orphaned_passengers
    FROM PASSENGERS p
    LEFT JOIN TRAINS t ON p.Train_id = t.Train_id
    WHERE t.Train_id IS NULL;
    
    -- Check for invalid ages
    SELECT COUNT(*) INTO invalid_ages
    FROM PASSENGERS
    WHERE Passenger_age < 0 OR Passenger_age > 150;
    
    -- Check for future bookings
    SELECT COUNT(*) INTO future_bookings
    FROM BOOKINGS
    WHERE Booking_date > NOW();
    
    -- Check for negative amounts
    SELECT COUNT(*) INTO negative_amounts
    FROM BOOKINGS
    WHERE Total_amount < 0;
    
    -- Return results
    SELECT 
        'Orphaned Bookings' AS issue_type, orphaned_bookings AS count
    UNION ALL
    SELECT 'Orphaned Passengers' AS issue_type, orphaned_passengers AS count
    UNION ALL
    SELECT 'Invalid Ages' AS issue_type, invalid_ages AS count
    UNION ALL
    SELECT 'Future Bookings' AS issue_type, future_bookings AS count
    UNION ALL
    SELECT 'Negative Amounts' AS issue_type, negative_amounts AS count;
END //
DELIMITER ;

-- ==========================================
-- 2. AUTOMATIC DATA MANAGEMENT TRIGGERS
-- ==========================================

-- Trigger for inserting passenger_id into PASSENGERS table
DELIMITER // 
CREATE TRIGGER passenger_id_insert
AFTER INSERT ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT IGNORE INTO PASSENGERS(Passenger_id) VALUES (NEW.Passenger_id);
END //
DELIMITER ;

-- Trigger for inserting train_id into TRAINS table
DELIMITER // 
CREATE TRIGGER train_id_insert
AFTER INSERT ON PASSENGERS
FOR EACH ROW
BEGIN
    IF NEW.Train_id IS NOT NULL THEN
        INSERT IGNORE INTO TRAINS(Train_id) VALUES (NEW.Train_id);
    END IF;
END //
DELIMITER ;

-- Trigger for updating train_id in TRAINS table
DELIMITER // 
CREATE TRIGGER train_id_update
AFTER UPDATE ON PASSENGERS
FOR EACH ROW
BEGIN
    IF NEW.Train_id != OLD.Train_id AND NEW.Train_id IS NOT NULL THEN
        INSERT IGNORE INTO TRAINS(Train_id) VALUES (NEW.Train_id);
    END IF;
END //
DELIMITER ;

-- Trigger for updating passenger_id when booking is updated
DELIMITER //
CREATE TRIGGER passenger_id_update
AFTER UPDATE ON BOOKINGS
FOR EACH ROW
BEGIN
    IF NEW.Passenger_id != OLD.Passenger_id THEN
        INSERT IGNORE INTO PASSENGERS(Passenger_id) VALUES (NEW.Passenger_id);
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 3. AUTOMATIC CALCULATIONS TRIGGERS
-- ==========================================

-- Trigger for converting date of birth to age (INSERT)
DELIMITER //
CREATE TRIGGER age_converter
BEFORE INSERT ON PASSENGERS
FOR EACH ROW
BEGIN
    IF NEW.Passenger_dob IS NOT NULL THEN
        SET NEW.Passenger_age = YEAR(CURDATE()) - YEAR(NEW.Passenger_dob);
    END IF;
END //
DELIMITER ;

-- Trigger for updating age when DOB is updated
DELIMITER // 
CREATE TRIGGER age_updater
BEFORE UPDATE ON PASSENGERS
FOR EACH ROW
BEGIN
    IF NEW.Passenger_dob IS NOT NULL AND (OLD.Passenger_dob != NEW.Passenger_dob OR OLD.Passenger_dob IS NULL) THEN
        SET NEW.Passenger_age = YEAR(CURDATE()) - YEAR(NEW.Passenger_dob);
    END IF;
END //
DELIMITER ;

-- Trigger for calculating length of travel on INSERT
DELIMITER // 
CREATE TRIGGER length_of_travel_insert
BEFORE INSERT ON TRAINS
FOR EACH ROW
BEGIN
    IF NEW.Departure_time IS NOT NULL AND NEW.Arrival_time IS NOT NULL THEN
        SET NEW.Length_of_travel = TIMEDIFF(NEW.Arrival_time, NEW.Departure_time);
    END IF;
END //
DELIMITER ;

-- Trigger for calculating length of travel on UPDATE
DELIMITER // 
CREATE TRIGGER length_of_travel_update
BEFORE UPDATE ON TRAINS
FOR EACH ROW
BEGIN
    IF NEW.Departure_time IS NOT NULL AND NEW.Arrival_time IS NOT NULL THEN
        SET NEW.Length_of_travel = TIMEDIFF(NEW.Arrival_time, NEW.Departure_time);
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 4. VALIDATION AND BUSINESS RULES TRIGGERS
-- ==========================================

-- Trigger to validate booking amounts
DELIMITER //
CREATE TRIGGER validate_booking_amount
BEFORE INSERT ON BOOKINGS
FOR EACH ROW
BEGIN
    IF NEW.Total_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking amount must be positive';
    END IF;
    
    IF NEW.Total_amount > 10000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking amount exceeds maximum limit of 10000';
    END IF;
END //
DELIMITER ;

-- Trigger to validate passenger ages
DELIMITER //
CREATE TRIGGER validate_passenger_age
BEFORE INSERT ON PASSENGERS
FOR EACH ROW
BEGIN
    IF NEW.Passenger_age < 0 OR NEW.Passenger_age > 150 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger age must be between 0 and 150';
    END IF;
    
    IF NEW.Passenger_dob > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger date of birth cannot be in the future';
    END IF;
END //
DELIMITER ;

-- Trigger to validate train schedules
DELIMITER //
CREATE TRIGGER validate_train_schedule
BEFORE INSERT ON TRAINS
FOR EACH ROW
BEGIN
    IF NEW.Departure_time IS NOT NULL AND NEW.Arrival_time IS NOT NULL THEN
        IF NEW.Arrival_time <= NEW.Departure_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Arrival time must be after departure time';
        END IF;
    END IF;
END //
DELIMITER ;

-- ==========================================
-- 5. AUDIT AND LOGGING TRIGGERS
-- ==========================================

-- Create comprehensive audit log table
CREATE TABLE IF NOT EXISTS audit_log (
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

-- Audit trigger for BOOKINGS table
DELIMITER //
CREATE TRIGGER bookings_audit_insert
AFTER INSERT ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation_type,
        record_id,
        new_values,
        changed_by
    ) VALUES (
        'BOOKINGS',
        'INSERT',
        NEW.Booking_no,
        JSON_OBJECT(
            'Passenger_id', NEW.Passenger_id,
            'Booking_date', NEW.Booking_date,
            'Total_amount', NEW.Total_amount
        ),
        USER()
    );
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER bookings_audit_update
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

DELIMITER //
CREATE TRIGGER bookings_audit_delete
AFTER DELETE ON BOOKINGS
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation_type,
        record_id,
        old_values,
        changed_by
    ) VALUES (
        'BOOKINGS',
        'DELETE',
        OLD.Booking_no,
        JSON_OBJECT(
            'Passenger_id', OLD.Passenger_id,
            'Booking_date', OLD.Booking_date,
            'Total_amount', OLD.Total_amount
        ),
        USER()
    );
END //
DELIMITER ;

-- ==========================================
-- 6. ADVANCED BUSINESS LOGIC PROCEDURES
-- ==========================================

-- Procedure to calculate customer lifetime value
DELIMITER //
CREATE PROCEDURE GetCustomerLifetimeValue(
    IN passenger_id_param VARCHAR(40),
    OUT total_bookings INT,
    OUT total_revenue DECIMAL(10,2),
    OUT avg_booking_value DECIMAL(10,2),
    OUT first_booking_date DATE,
    OUT last_booking_date DATE,
    OUT customer_lifespan_days INT
)
BEGIN
    SELECT 
        COUNT(b.Booking_no),
        SUM(b.Total_amount),
        AVG(b.Total_amount),
        MIN(DATE(b.Booking_date)),
        MAX(DATE(b.Booking_date)),
        DATEDIFF(MAX(DATE(b.Booking_date)), MIN(DATE(b.Booking_date)))
    INTO 
        total_bookings,
        total_revenue,
        avg_booking_value,
        first_booking_date,
        last_booking_date,
        customer_lifespan_days
    FROM BOOKINGS b
    WHERE b.Passenger_id = passenger_id_param;
END //
DELIMITER ;

-- Procedure for revenue analysis by time period
DELIMITER //
CREATE PROCEDURE GetRevenueAnalysis(
    IN start_date DATE,
    IN end_date DATE,
    IN group_by_param VARCHAR(20) -- 'day', 'week', 'month', 'year'
)
BEGIN
    CASE group_by_param
        WHEN 'day' THEN
            SELECT 
                DATE(Booking_date) AS period,
                COUNT(*) AS bookings_count,
                SUM(Total_amount) AS total_revenue,
                AVG(Total_amount) AS avg_booking_value,
                MIN(Total_amount) AS min_booking,
                MAX(Total_amount) AS max_booking
            FROM BOOKINGS
            WHERE DATE(Booking_date) BETWEEN start_date AND end_date
            GROUP BY DATE(Booking_date)
            ORDER BY DATE(Booking_date);
            
        WHEN 'week' THEN
            SELECT 
                CONCAT(YEAR(Booking_date), '-W', LPAD(WEEK(Booking_date), 2, '0')) AS period,
                COUNT(*) AS bookings_count,
                SUM(Total_amount) AS total_revenue,
                AVG(Total_amount) AS avg_booking_value,
                MIN(Total_amount) AS min_booking,
                MAX(Total_amount) AS max_booking
            FROM BOOKINGS
            WHERE DATE(Booking_date) BETWEEN start_date AND end_date
            GROUP BY YEAR(Booking_date), WEEK(Booking_date)
            ORDER BY YEAR(Booking_date), WEEK(Booking_date);
            
        WHEN 'month' THEN
            SELECT 
                CONCAT(YEAR(Booking_date), '-', LPAD(MONTH(Booking_date), 2, '0')) AS period,
                COUNT(*) AS bookings_count,
                SUM(Total_amount) AS total_revenue,
                AVG(Total_amount) AS avg_booking_value,
                MIN(Total_amount) AS min_booking,
                MAX(Total_amount) AS max_booking
            FROM BOOKINGS
            WHERE DATE(Booking_date) BETWEEN start_date AND end_date
            GROUP BY YEAR(Booking_date), MONTH(Booking_date)
            ORDER BY YEAR(Booking_date), MONTH(Booking_date);
            
        WHEN 'year' THEN
            SELECT 
                YEAR(Booking_date) AS period,
                COUNT(*) AS bookings_count,
                SUM(Total_amount) AS total_revenue,
                AVG(Total_amount) AS avg_booking_value,
                MIN(Total_amount) AS min_booking,
                MAX(Total_amount) AS max_booking
            FROM BOOKINGS
            WHERE DATE(Booking_date) BETWEEN start_date AND end_date
            GROUP BY YEAR(Booking_date)
            ORDER BY YEAR(Booking_date);
    END CASE;
END //
DELIMITER ;

-- Procedure for train performance analysis
DELIMITER //
CREATE PROCEDURE GetTrainPerformanceAnalysis(
    IN train_type_param VARCHAR(50)
)
BEGIN
    SELECT 
        t.Train_id,
        t.Train_name,
        t.Train_type,
        t.First_station,
        t.Last_station,
        t.Length_of_travel,
        COUNT(p.Passenger_id) AS total_passengers,
        COUNT(DISTINCT p.Passenger_id) AS unique_passengers,
        COALESCE(SUM(b.Total_amount), 0) AS total_revenue,
        COALESCE(AVG(b.Total_amount), 0) AS avg_revenue_per_booking,
        CASE 
            WHEN COUNT(p.Passenger_id) = 0 THEN 'No Bookings'
            WHEN COUNT(p.Passenger_id) < 10 THEN 'Low Demand'
            WHEN COUNT(p.Passenger_id) < 50 THEN 'Medium Demand'
            WHEN COUNT(p.Passenger_id) < 100 THEN 'High Demand'
            ELSE 'Very High Demand'
        END AS demand_level,
        CASE 
            WHEN t.Length_of_travel <= '02:00:00' THEN 'Short Journey'
            WHEN t.Length_of_travel <= '06:00:00' THEN 'Medium Journey'
            ELSE 'Long Journey'
        END AS journey_type
    FROM TRAINS t
    LEFT JOIN PASSENGERS p ON t.Train_id = p.Train_id
    LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    WHERE train_type_param IS NULL OR t.Train_type = train_type_param
    GROUP BY t.Train_id, t.Train_name, t.Train_type, t.First_station, t.Last_station, t.Length_of_travel
    ORDER BY total_revenue DESC;
END //
DELIMITER ;

-- ==========================================
-- 7. DYNAMIC QUERY PROCEDURES
-- ==========================================

-- Procedure for dynamic passenger search
DELIMITER //
CREATE PROCEDURE SearchPassengers(
    IN search_criteria JSON
)
BEGIN
    DECLARE sql_query TEXT DEFAULT 'SELECT p.*, b.Total_amount, b.Booking_date, t.Train_name FROM PASSENGERS p LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id LEFT JOIN TRAINS t ON p.Train_id = t.Train_id WHERE 1=1';
    DECLARE fname VARCHAR(100);
    DECLARE lname VARCHAR(100);
    DECLARE min_age INT;
    DECLARE max_age INT;
    DECLARE train_type VARCHAR(50);
    
    -- Extract search criteria from JSON
    SET fname = JSON_UNQUOTE(JSON_EXTRACT(search_criteria, '$.first_name'));
    SET lname = JSON_UNQUOTE(JSON_EXTRACT(search_criteria, '$.last_name'));
    SET min_age = JSON_EXTRACT(search_criteria, '$.min_age');
    SET max_age = JSON_EXTRACT(search_criteria, '$.max_age');
    SET train_type = JSON_UNQUOTE(JSON_EXTRACT(search_criteria, '$.train_type'));
    
    -- Build dynamic WHERE clause
    IF fname IS NOT NULL AND fname != 'null' THEN
        SET sql_query = CONCAT(sql_query, ' AND p.Passenger_fname LIKE ''%', fname, '%''');
    END IF;
    
    IF lname IS NOT NULL AND lname != 'null' THEN
        SET sql_query = CONCAT(sql_query, ' AND p.Passenger_lname LIKE ''%', lname, '%''');
    END IF;
    
    IF min_age IS NOT NULL THEN
        SET sql_query = CONCAT(sql_query, ' AND p.Passenger_age >= ', min_age);
    END IF;
    
    IF max_age IS NOT NULL THEN
        SET sql_query = CONCAT(sql_query, ' AND p.Passenger_age <= ', max_age);
    END IF;
    
    IF train_type IS NOT NULL AND train_type != 'null' THEN
        SET sql_query = CONCAT(sql_query, ' AND t.Train_type = ''', train_type, '''');
    END IF;
    
    SET sql_query = CONCAT(sql_query, ' ORDER BY p.Passenger_lname, p.Passenger_fname');
    
    -- Execute dynamic query
    SET @sql = sql_query;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- ==========================================
-- 8. REPORTING AND ANALYTICS PROCEDURES
-- ==========================================

-- Procedure for comprehensive dashboard data
DELIMITER //
CREATE PROCEDURE GetDashboardData()
BEGIN
    -- Total statistics
    SELECT 
        'Total Bookings' AS metric,
        COUNT(*) AS value,
        'count' AS type
    FROM BOOKINGS
    UNION ALL
    SELECT 
        'Total Revenue' AS metric,
        SUM(Total_amount) AS value,
        'currency' AS type
    FROM BOOKINGS
    UNION ALL
    SELECT 
        'Average Booking Value' AS metric,
        AVG(Total_amount) AS value,
        'currency' AS type
    FROM BOOKINGS
    UNION ALL
    SELECT 
        'Total Passengers' AS metric,
        COUNT(DISTINCT Passenger_id) AS value,
        'count' AS type
    FROM PASSENGERS
    UNION ALL
    SELECT 
        'Active Trains' AS metric,
        COUNT(DISTINCT Train_id) AS value,
        'count' AS type
    FROM TRAINS;
    
    -- Revenue by month (last 12 months)
    SELECT 
        CONCAT(YEAR(Booking_date), '-', LPAD(MONTH(Booking_date), 2, '0')) AS month,
        SUM(Total_amount) AS revenue,
        COUNT(*) AS bookings
    FROM BOOKINGS
    WHERE Booking_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY YEAR(Booking_date), MONTH(Booking_date)
    ORDER BY YEAR(Booking_date), MONTH(Booking_date);
    
    -- Top performing trains
    SELECT 
        t.Train_name,
        t.Train_type,
        COUNT(p.Passenger_id) AS passenger_count,
        COALESCE(SUM(b.Total_amount), 0) AS total_revenue
    FROM TRAINS t
    LEFT JOIN PASSENGERS p ON t.Train_id = p.Train_id
    LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    GROUP BY t.Train_id, t.Train_name, t.Train_type
    ORDER BY total_revenue DESC
    LIMIT 10;
END //
DELIMITER ;

-- ==========================================
-- 9. CLEANUP AND UTILITY PROCEDURES
-- ==========================================

-- Procedure to clean up old audit logs
DELIMITER //
CREATE PROCEDURE CleanupAuditLogs(
    IN retention_days INT DEFAULT 90
)
BEGIN
    DECLARE rows_deleted INT DEFAULT 0;
    
    DELETE FROM audit_log 
    WHERE changed_at < DATE_SUB(CURDATE(), INTERVAL retention_days DAY);
    
    SET rows_deleted = ROW_COUNT();
    
    SELECT CONCAT('Deleted ', rows_deleted, ' old audit log records') AS message;
END //
DELIMITER ;

-- Procedure to optimize database tables
DELIMITER //
CREATE PROCEDURE OptimizeTables()
BEGIN
    OPTIMIZE TABLE BOOKINGS;
    OPTIMIZE TABLE PASSENGERS;
    OPTIMIZE TABLE TRAINS;
    OPTIMIZE TABLE audit_log;
    
    SELECT 'Database optimization completed' AS message;
END //
DELIMITER ;

-- ==========================================
-- 10. EXAMPLE USAGE AND TESTING
-- ==========================================

-- Example calls for testing procedures
-- CALL EMPTY_DATA();
-- CALL CREATE_BACKUP_TABLES();
-- CALL CHECK_DATA_INTEGRITY();
-- CALL GetRevenueAnalysis('2024-01-01', '2024-12-31', 'month');
-- CALL GetTrainPerformanceAnalysis('Express');
-- CALL GetDashboardData();
-- CALL CleanupAuditLogs(30);
-- CALL OptimizeTables();

-- Example of using SearchPassengers with JSON criteria
-- CALL SearchPassengers('{"first_name": "John", "min_age": 25, "max_age": 45, "train_type": "Express"}');

-- Example of using GetCustomerLifetimeValue
-- CALL GetCustomerLifetimeValue('P001', @bookings, @revenue, @avg_value, @first_date, @last_date, @lifespan);
-- SELECT @bookings, @revenue, @avg_value, @first_date, @last_date, @lifespan;