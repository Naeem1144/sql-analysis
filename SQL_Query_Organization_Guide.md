# SQL Query Organization Guide

## Overview
This repository contains a comprehensive collection of SQL queries organized by complexity and functionality. The queries are built around a Train Booking System database and demonstrate various SQL techniques from basic to advanced levels.

## File Structure

### 📁 Core Files
```
├── 01_basic_sql_queries.sql              # Fundamental SQL concepts
├── 02_intermediate_sql_queries.sql       # Complex queries and analytics
├── 03_advanced_sql_queries.sql           # Advanced techniques and optimization
├── 04_triggers_and_stored_procedures.sql # Database automation and business logic
├── train_database_project.sql            # Original project file
├── Group_Project.sql                     # Retail analytics queries
└── README.md                             # Project documentation
```

## Query Categories

### 1. Basic SQL Queries (`01_basic_sql_queries.sql`)
**Level: Beginner**
- **Database Creation & Table Setup**
- **Basic SELECT Statements**
- **Filtering with WHERE**
- **Sorting and Limiting Results**
- **Basic Aggregations** (COUNT, SUM, AVG, MIN, MAX)
- **String Functions** (CONCAT, UPPER, LOWER, LEFT)
- **Date Functions** (DATE, YEAR, MONTH, DAY)
- **Conditional Logic** (CASE, IF)
- **Basic Joins** (INNER JOIN, LEFT JOIN)
- **Simple Subqueries**
- **Pattern Matching** (LIKE, IN, BETWEEN)

### 2. Intermediate SQL Queries (`02_intermediate_sql_queries.sql`)
**Level: Intermediate**
- **Advanced Joins** (Three-way joins, Complex conditions)
- **Complex Aggregations** (GROUP BY with multiple columns)
- **Advanced Subqueries** (Correlated subqueries, EXISTS)
- **Window Functions** (RANK, ROW_NUMBER, NTILE, LAG/LEAD)
- **Running Totals & Moving Averages**
- **Multi-level Conditional Logic**
- **Advanced Date/Time Analysis**
- **Complex String Manipulation**
- **Data Quality Checks**
- **Backup and Maintenance Operations**

### 3. Advanced SQL Queries (`03_advanced_sql_queries.sql`)
**Level: Advanced**
- **Common Table Expressions (CTEs)**
- **Recursive Queries** (Hierarchical data)
- **Advanced Analytics** (Cohort analysis, Time series)
- **Statistical Analysis** (Percentiles, Standard deviation)
- **Dynamic Pivoting**
- **Pattern Recognition**
- **Performance Optimization**
- **Data Quality Validation**
- **Advanced Stored Procedures**
- **Audit Trail Implementation**

### 4. Triggers and Stored Procedures (`04_triggers_and_stored_procedures.sql`)
**Level: Advanced**
- **Database Maintenance Procedures**
- **Automatic Data Management Triggers**
- **Business Logic Automation**
- **Data Validation and Constraints**
- **Comprehensive Audit Logging**
- **Dynamic Query Generation**
- **Reporting and Analytics Procedures**
- **Database Optimization Tools**

## Database Schema

### Core Tables
```sql
BOOKINGS
├── Booking_no (INT, AUTO_INCREMENT, PRIMARY KEY)
├── Passenger_id (VARCHAR(40), CHECK LENGTH = 5)
├── Booking_date (TIMESTAMP, DEFAULT NOW())
└── Total_amount (DECIMAL(10,2))

PASSENGERS
├── Passenger_id (VARCHAR(40), PRIMARY KEY)
├── Passenger_fname (VARCHAR(80))
├── Passenger_lname (VARCHAR(80))
├── Passenger_dob (DATE)
├── Passenger_age (INT)
└── Train_id (VARCHAR(40), FOREIGN KEY)

TRAINS
├── Train_id (VARCHAR(40), PRIMARY KEY)
├── Train_name (VARCHAR(80))
├── Train_type (VARCHAR(50))
├── First_station (VARCHAR(70))
├── Last_station (VARCHAR(70))
├── Departure_time (TIMESTAMP)
├── Arrival_time (TIMESTAMP)
└── Length_of_travel (TIME)
```

### Additional Tables
- **audit_log**: Comprehensive audit trail
- **route_hierarchy**: Hierarchical route data
- **Backup tables**: Data preservation

## Usage Instructions

### 1. Setting Up the Database
```sql
-- Create and use the database
CREATE DATABASE train_booking_system;
USE train_booking_system;

-- Run basic table creation from 01_basic_sql_queries.sql
-- Then run trigger setup from 04_triggers_and_stored_procedures.sql
```

### 2. Learning Path
1. **Start with Basic Queries**: Master fundamental concepts
2. **Progress to Intermediate**: Learn complex joins and analytics
3. **Advance to CTEs and Window Functions**: Understand advanced techniques
4. **Implement Automation**: Use triggers and stored procedures

### 3. Key Features by Category

#### Basic Level Features
- ✅ Table creation and management
- ✅ Data retrieval and filtering
- ✅ Basic calculations and aggregations
- ✅ Simple joins and relationships

#### Intermediate Level Features
- ✅ Complex multi-table analysis
- ✅ Window functions for rankings
- ✅ Advanced filtering and grouping
- ✅ Data quality assessments

#### Advanced Level Features
- ✅ Recursive queries for hierarchical data
- ✅ Statistical and cohort analysis
- ✅ Performance optimization techniques
- ✅ Dynamic query generation

#### Automation Features
- ✅ Automatic data validation
- ✅ Business rule enforcement
- ✅ Comprehensive audit logging
- ✅ Scheduled maintenance tasks

## Sample Queries by Use Case

### 📊 Revenue Analysis
```sql
-- Daily revenue trends (Intermediate)
SELECT 
    DATE(booking_date) AS date,
    SUM(total_amount) AS revenue,
    COUNT(*) AS bookings
FROM BOOKINGS
GROUP BY DATE(booking_date)
ORDER BY date;

-- Revenue by age group with percentages (Advanced)
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN p.Passenger_age < 18 THEN 'Minor'
            WHEN p.Passenger_age < 65 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group,
        SUM(b.Total_amount) AS total_revenue
    FROM PASSENGERS p
    JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    GROUP BY age_group
)
SELECT 
    age_group,
    total_revenue,
    ROUND((total_revenue / SUM(total_revenue) OVER()) * 100, 2) AS percentage
FROM age_groups;
```

### 🚂 Train Performance Analysis
```sql
-- Train utilization analysis (Intermediate)
SELECT 
    t.Train_name,
    t.Train_type,
    COUNT(p.Passenger_id) AS passenger_count,
    AVG(b.Total_amount) AS avg_revenue
FROM TRAINS t
LEFT JOIN PASSENGERS p ON t.Train_id = p.Train_id
LEFT JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
GROUP BY t.Train_id, t.Train_name, t.Train_type
ORDER BY passenger_count DESC;

-- Using stored procedure (Advanced)
CALL GetTrainPerformanceAnalysis('Express');
```

### 👥 Customer Segmentation
```sql
-- Customer lifetime value analysis (Advanced)
WITH customer_metrics AS (
    SELECT 
        p.Passenger_id,
        COUNT(b.Booking_no) AS total_bookings,
        SUM(b.Total_amount) AS lifetime_value,
        AVG(b.Total_amount) AS avg_booking_value
    FROM PASSENGERS p
    JOIN BOOKINGS b ON p.Passenger_id = b.Passenger_id
    GROUP BY p.Passenger_id
)
SELECT 
    CASE 
        WHEN total_bookings = 1 THEN 'One-time'
        WHEN total_bookings <= 5 THEN 'Occasional'
        WHEN total_bookings <= 10 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    AVG(lifetime_value) AS avg_lifetime_value
FROM customer_metrics
GROUP BY customer_segment;
```

## Best Practices

### 1. Query Optimization
- Use indexes on frequently queried columns
- Avoid SELECT * in production queries
- Use EXPLAIN to analyze query performance
- Consider using CTEs for complex queries

### 2. Data Integrity
- Implement proper constraints and validations
- Use triggers for automatic data management
- Regular data quality checks
- Maintain audit trails for critical operations

### 3. Security Considerations
- Use parameterized queries to prevent SQL injection
- Implement proper user access controls
- Regular security audits
- Encrypt sensitive data

### 4. Maintenance
- Regular database optimization
- Automated backup procedures
- Monitor query performance
- Clean up old audit logs

## Advanced Features

### 1. Recursive Queries
```sql
-- Organizational hierarchy traversal
WITH RECURSIVE route_tree AS (
    SELECT route_id, route_name, parent_route_id, 0 AS level
    FROM route_hierarchy
    WHERE parent_route_id IS NULL
    
    UNION ALL
    
    SELECT r.route_id, r.route_name, r.parent_route_id, rt.level + 1
    FROM route_hierarchy r
    JOIN route_tree rt ON r.parent_route_id = rt.route_id
)
SELECT * FROM route_tree ORDER BY level, route_name;
```

### 2. Window Functions
```sql
-- Running totals and rankings
SELECT 
    booking_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY booking_date) AS running_total,
    RANK() OVER (ORDER BY total_amount DESC) AS amount_rank
FROM BOOKINGS;
```

### 3. JSON Processing
```sql
-- Dynamic search with JSON parameters
CALL SearchPassengers('{
    "first_name": "John",
    "min_age": 25,
    "max_age": 45,
    "train_type": "Express"
}');
```

## Performance Tips

### 1. Index Usage
```sql
-- Create composite indexes for common queries
CREATE INDEX idx_bookings_date_amount ON BOOKINGS(Booking_date, Total_amount);
CREATE INDEX idx_passengers_age_train ON PASSENGERS(Passenger_age, Train_id);
```

### 2. Query Optimization
```sql
-- Use covering indexes when possible
SELECT DATE(booking_date), SUM(total_amount)
FROM BOOKINGS
WHERE booking_date >= '2024-01-01'
GROUP BY DATE(booking_date);
```

### 3. Stored Procedures
```sql
-- Use procedures for complex business logic
CALL GetCustomerSegmentation('2024-12-31', 2, 100.00);
```

## Testing and Validation

### 1. Data Quality Checks
```sql
-- Run comprehensive data validation
CALL CHECK_DATA_INTEGRITY();
```

### 2. Performance Testing
```sql
-- Analyze query performance
EXPLAIN SELECT * FROM BOOKINGS WHERE booking_date > '2024-01-01';
```

### 3. Backup and Recovery
```sql
-- Create timestamped backups
CALL CREATE_BACKUP_TABLES();
```

## Learning Resources

### 1. Progression Path
1. **Beginner**: Focus on basic CRUD operations
2. **Intermediate**: Learn joins, aggregations, and subqueries
3. **Advanced**: Master CTEs, window functions, and optimization
4. **Expert**: Implement complex business logic and automation

### 2. Practice Exercises
- Start with simple SELECT statements
- Progress to multi-table joins
- Practice window functions with real data
- Implement stored procedures for business logic

### 3. Real-world Applications
- Revenue analysis and reporting
- Customer behavior analysis
- Performance monitoring
- Data quality management

## Troubleshooting

### Common Issues
1. **Foreign Key Constraints**: Ensure referenced tables exist
2. **Data Type Mismatches**: Check column definitions
3. **Permission Errors**: Verify user privileges
4. **Performance Issues**: Add appropriate indexes

### Debugging Tips
1. Use EXPLAIN to analyze query plans
2. Check error logs for detailed messages
3. Test queries incrementally
4. Use SELECT statements to verify data

## Conclusion

This comprehensive SQL query collection provides a structured learning path from basic to advanced database operations. Each file builds upon previous concepts while introducing new techniques and best practices. The combination of theoretical knowledge and practical examples makes this an excellent resource for developing SQL expertise.

Whether you're a beginner learning fundamental concepts or an advanced practitioner looking to optimize complex queries, this collection offers valuable insights and practical solutions for real-world database challenges.