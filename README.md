# Train Booking System & Retail Store Analytics SQL Projects

This repository showcases two SQL projects demonstrating advanced database design, querying, and optimization skills: **Train Booking System** and **Retail Store Analytics**. These projects highlight my proficiency in relational database management, complex SQL queries, triggers, stored procedures, and data analysis for real-world applications. Below is a detailed overview of each project, including objectives, technical implementations, and key skills demonstrated.

## Table of Contents
1. [Project 1: Train Booking System](#project-1-train-booking-system)
   - [Overview](#overview)
   - [Database Schema](#database-schema)
   - [Key Features](#key-features)
   - [Technical Highlights](#technical-highlights)
2. [Project 2: Retail Store Analytics](#project-2-retail-store-analytics)
   - [Overview](#overview-1)
   - [Database Schema](#database-schema-1)
   - [Key Features](#key-features-1)
   - [Technical Highlights](#technical-highlights-1)
3. [Skills Demonstrated](#skills-demonstrated)
4. [Setup Instructions](#setup-instructions)
5. [Usage](#usage)
6. [Future Improvements](#future-improvements)

---

## Project 1: Train Booking System

### Overview
The **Train Booking System** is a relational database designed to manage train bookings, passenger details, and train schedules. It automates key processes like calculating passenger age, travel duration, and maintaining data consistency across tables using triggers and stored procedures. The project also includes analytical queries to derive insights such as total revenue by date and passenger demographics.

### Database Schema
The database (`train_booking_system`) consists of three main tables:
- **BOOKINGS**: Stores booking details (Booking_no, Passenger_id, Booking_date, Total_amount).
- **PASSENGERS**: Contains passenger information (Passenger_id, Passenger_fname, Passenger_lname, Passenger_dob, Passenger_age, Train_id).
- **TRAINS**: Holds train details (Train_id, Train_name, Train_type, First_station, Last_station, Departure_time, Arrival_time, Length_of_travel).

### Key Features
- **Data Automation**:
  - Automatically calculates passenger age from date of birth using triggers.
  - Computes travel duration (`Length_of_travel`) based on departure and arrival times.
  - Propagates `Passenger_id` and `Train_id` across related tables using triggers.
- **Data Integrity**:
  - Enforces constraints like unique `Passenger_id` (5-character length) and foreign key relationships.
  - Updates related tables when `Passenger_id` or `Train_id` changes.
- **Analytical Queries**:
  - Groups passengers by age categories (Kids, Teenagers, Adults, Elders) and calculates total revenue per group.
  - Retrieves trains with travel durations of 6 hours or less.
  - Summarizes total collections by booking date.
  - Lists trains available on specific dates and counts trains by departure date.
- **Backup and Maintenance**:
  - Creates backup tables for `PASSENGERS` and `TRAINS`.
  - Includes a stored procedure (`EMPTY_DATA()`) to clear all tables for testing or resetting.

### Technical Highlights
- **Triggers**:
  - `passenger_id_insert`: Inserts `Passenger_id` into `PASSENGERS` after a new booking.
  - `train_id_insert`: Inserts `Train_id` into `TRAINS` after a passenger record is added.
  - `age_converter` and `age_updater`: Calculate and update passenger age based on `Passenger_dob`.
  - `length_of_travel_update`: Computes travel duration using `TIMEDIFF`.
  - `passenger_id_update` and `train_id_update`: Synchronize ID updates across tables.
- **Stored Procedures**:
  - `EMPTY_DATA()`: Truncates all tables to reset the database.
- **Complex Queries**:
  - Uses `INNER JOIN` to combine `BOOKINGS`, `PASSENGERS`, and `TRAINS` for customer revenue analysis.
  - Employs `CASE` statements to categorize passengers by age.
  - Aggregates data with `GROUP BY` and `SUM` for financial and scheduling insights.
- **Data Manipulation**:
  - Extracts initials from passenger names using `LEFT`.
  - Filters trains by date and travel duration using `WHERE` and `LIKE`.
  - Orders results with `ORDER BY` and limits output with `LIMIT`.

---

## Project 2: Retail Store Analytics

### Overview
The **Retail Store Analytics** project focuses on analyzing store performance, employee data, and sales metrics for a retail chain. It includes queries to identify top-performing stores, high-performing employees, average sales by product, and common records between tables, as well as deduplication of employee data.

### Database Schema
The database (`PROJECTS`) includes the following tables:
- **STORES_DATA**: Stores store information (STORE_ID, STORE_NAME, total_monthly_transaction).
- **EMPLOYEE_DATA**: Contains employee details (EMPLOYEE_ID, performance_review).
- **SALES_DATA**: Tracks sales records (PRODUCT, TOTAL_AMOUNT).
- **NEW_EMPLOYEES** and **NEW_EMPLOYEES1**: Store employee data (fname, lname, indx).

### Key Features
- **Store Performance**:
  - Identifies the top three stores by total monthly transactions.
- **Employee Performance**:
  - Extracts employee IDs with performance review scores of 3 or higher.
- **Sales Analysis**:
  - Calculates average monthly sales per product, rounded to the nearest integer.
- **Data Cleaning**:
  - Removes duplicate employee records based on first and last names without creating a new table.
- **Record Matching**:
  - Finds common employee records between `NEW_EMPLOYEES` and `NEW_EMPLOYEES1` using `INNER JOIN`.

### Technical Highlights
- **Ranking and Filtering**:
  - Uses `ORDER BY` and `LIMIT` to rank stores by transaction volume.
  - Filters employees with `WHERE` clause for performance reviews.
- **Aggregation**:
  - Computes average sales with `AVG` and `ROUND` for readability.
  - Groups sales data by product using `GROUP BY`.
- **Deduplication**:
  - Deletes duplicate employee records using self-join (`INNER JOIN`) and comparison of `indx` and name fields.
- **Record Comparison**:
  - Uses `INNER JOIN` and `DISTINCT` to identify matching employee names across tables.

---

## Skills Demonstrated
- **Database Design**:
  - Created normalized relational schemas with primary keys, foreign keys, and constraints.
  - Ensured data integrity with check constraints and referential integrity.
- **SQL Querying**:
  - Wrote complex queries using `JOIN`, `GROUP BY`, `CASE`, `LIMIT`, and `ORDER BY`.
  - Performed aggregations (`SUM`, `AVG`, `COUNT`) and string manipulations (`LEFT`).
  - Handled date/time operations (`TIMEDIFF`, `DATE`, `YEAR`).
- **Automation**:
  - Implemented triggers for automatic data propagation and calculations.
  - Developed stored procedures for database maintenance.
- **Data Analysis**:
  - Derived business insights like revenue by age group, store performance, and sales averages.
  - Filtered and sorted data for actionable reports.
- **Data Cleaning**:
  - Removed duplicates and synchronized data across tables.
- **Performance Optimization**:
  - Used efficient joins and indexing strategies (implied through primary keys).
- **MySQL Expertise**:
  - Utilized MySQL-specific features like `DELIMITER`, `TRUNCATE`, and trigger syntax.

---

## Setup Instructions
1. **Prerequisites**:
   - MySQL Server (version 8.0 or later).
   - MySQL Workbench or any SQL client.
2. **Installation**:
   - Clone this repository: `git clone https://github.com/Naeem1144/SQL-Project/edit/main/README.md`.
   - Navigate to the project directory: `cd https://github.com/Naeem1144/SQL-Project/edit/main/README.md`.
3. **Database Setup**:
   - Run `train_database_project.sql` to create and populate the Train Booking System database.
   - Run `Group_Project.sql` to execute queries for the Retail Store Analytics project (ensure the `PROJECTS` database exists).
4. **Execution**:
   - Open MySQL Workbench or your SQL client.
   - Execute the SQL files in order or run individual queries as needed.

---

## Usage
- **Train Booking System**:
  - Create bookings, passengers, and trains using `INSERT` statements.
  - Run analytical queries to generate reports (e.g., revenue by age group, trains by date).
  - Use `CALL EMPTY_DATA()` to reset the database.
  - View backups in `passengers_backup` and `trains_backup`.
- **Retail Store Analytics**:
  - Execute queries to analyze store transactions, employee performance, and sales data.
  - Run deduplication query to clean `NEW_EMPLOYEES`.
  - Compare employee records between `NEW_EMPLOYEES` and `NEW_EMPLOYEES1`.

---

## Future Improvements
- **Train Booking System**:
  - Add user authentication and role-based access control.
  - Implement views for commonly accessed reports.
  - Optimize triggers for performance on large datasets.
- **Retail Store Analytics**:
  - Add time-based sales analysis (e.g., monthly trends).
  - Include stored procedures for automated reporting.
  - Enhance deduplication with additional criteria (e.g., email or employee ID).
- **General**:
  - Integrate with a frontend (e.g., Python Flask or React) for a complete application.
  - Add error handling for edge cases in triggers and procedures.
  - Deploy databases to a cloud platform like AWS RDS for scalability.

---


This repository is a testament to my ability to design robust databases, automate processes, and derive meaningful insights using SQL. Explore the code, run the queries, and let me know how I can contribute to your next project!
