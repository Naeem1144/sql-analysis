-- CREATING THE DATABASE
create database train_booking_system;

-- CREATING THE BOOKING TABLE
create table BOOKINGS	
(
Booking_no int auto_increment,
primary key(Booking_no),
Passenger_id varchar(40) check(length(passenger_id) = 5),
Booking_date timestamp default now(),
Total_amount decimal
);

-- CREATING THE PASSENGER'S TABLE
CREATE TABLE PASSENGERS (
    Passenger_id VARCHAR(40),
    primary key (passenger_id),
    Passenger_fname VARCHAR(80),
    Passenger_lname VARCHAR(80),
    Passenger_dob DATE,
    Passenger_age int,
    Train_id VARCHAR(40),
    FOREIGN KEY(Train_id) REFERENCES TRAINS(Train_id)
);

-- CREATING THE TRAIN'S TABLE
create table TRAINS
(
Train_id varchar(40),
primary key(train_id),
Train_name varchar(80),
Train_type varchar(50),
First_station varchar(70),
Last_statio varchar(70),
Departure_time timestamp,
arrival_time timestamp,
length_of_travel timestamp
);

-- TRIGGERS -- 
-- 1) FOR TRANSFERING PASSENGER_ID TO PASSENGER'S TABLE
delimiter // 
create trigger passenger_id_insert
after insert on bookings
for each row
begin
insert into passengers(passenger_id) values (new.passenger_id);
end //
delimiter ;

DROP TRIGGER TRAIN_ID_INSERT;
-- 2) FOR TRANSFERING TRAIN_ID TO TRAINS TABLE
delimiter // 
create trigger train_id_insert
after insert on passengers
for each row
begin
if new.train_id is not null then
insert into trains(train_id) values (new.train_id);
end if;
end //
delimiter ;

-- 3) IN CASE OF UPDATE IN TRAIN_ID TABLE
drop trigger train_id_update;
delimiter // 
create trigger train_id_update
after update on passengers
for each row
begin
update trains
set train_id = new.train_id
where ROW_NO = NEW.ROW_NO; 
end //
delimiter ;

-- 4) FOR COVERTING DATE OF BIRTH INTO AGE 
delimiter //
create trigger age_converter
before insert on passengers
for each row
begin
set new.Passenger_age = year(curdate())-year(new.passenger_dob);
end //
delimiter ;


-- X -- X -- X -- X -- X --
DROP TRIGGER AGE_CONVERTER;
-- X -- X -- X -- X -- X -- 
DROP TRIGGER AGE_UPDATER;
-- X -- X -- X -- X -- X -- 

-- 5) IN CASE OF DOB UPDATE
delimiter // 
create trigger age_updater
before update on passengers
for each row
begin
set new.Passenger_age = year(curdate())-year(new.passenger_dob);
end //
delimiter ;

-- AGE --

-- 6) FOR CALCULATING LENGTH OF TRAVEL
DROP TRIGGER LENGTH_OF_TRAVEL;
DROP TRIGGER IF EXISTS LENGTH_OF_TRAVEL
DELIMITER // 
CREATE TRIGGER LENGTH_OF_TRAVEL_update
BEFORE update ON TRAINS
FOR EACH ROW
BEGIN
SET NEW.LENGTH_OF_TRAVEL = TIMEDIFF(new.arrival_time,new.departure_time) ;
END //
DELIMITER ;

SELECT  TIMEDIFF(arrival_time,departure_time) FROM TRAINS;


-- AGE --
 
-- 7) WHEN TRAIN_ID GET UPDATED UPDATE 
delimiter //
create trigger passenger_id_update
after update on BOOKINGS
for each row
begin
update passengers
set passenger_id = new.passenger_id
where row_no = new.booking_no;
end //
delimiter ;

drop trigger PASSENNGER_id_update;
set foreign_key_checks = off;

-- STORED PROCEDURES -- 
-- TO CLEAR ENTIRE DATABASE WITH A CALL 'EMPTY_DATA()'
DELIMITER //
CREATE PROCEDURE EMPTY_DATA()
BEGIN
TRUNCATE TABLE BOOKINGS;
TRUNCATE TABLE PASSENGERS;
TRUNCATE TABLE TRAINS;
END //
DELIMITER ;

call empty_data;

-- FOR VIEWING TABLES --
SELECT * FROM BOOKINGS;
SELECT * FROM PASSENGERS;
SELECT * FROM TRAINS;

create table passengers_backup like passengers;
insert into  passengers_backup select * from passengers;

create table trains_backup like trains;
insert into trains_backup select * from trains;

select * from bookings
order by total_amount desc
limit 10;

select * from trains;

select count(train_id) ,train_name from trains
group by train_name;

-- view the customer data with amount from two different table using inner join
select bookings.booking_no, bookings.total_amount, passengers.passenger_fname, passengers.passenger_lname,
passengers.passenger_id from bookings
inner join passengers
on bookings.booking_no = passengers.row_no;

-- select all trains that are scheduled to be on 01-05
select * from trains
where date(arrival_time) like "%01-05";

-- change datetime into date
select date(arrival_time) from trains;

-- trains available in the cerain dates
select date(departure_time) as date,count(train_id) as trains_available from trains
group by date
order by date asc;

-- Total collection by date
select date(booking_date) as date, round(sum(total_amount),2) as total_collection from bookings
group by date;

-- sorting passeners into different age groups and group then by total generated amount(using case ,join and group by at once)
SELECT
    concat(round(sum(bookings.total_amount),2),' $') as generated_amount,
    CASE 
        WHEN passenger_age <= 12 THEN "Kids"
        WHEN passenger_age >= 13 AND passenger_age <= 21 THEN "Teenagers"
        WHEN passenger_age >= 22 AND passenger_age <= 64 THEN "Adults"
        WHEN passenger_age >= 65 AND passenger_age <= 150 THEN "Elders"
    END AS Age_catagory
FROM passengers
INNER JOIN trains
ON passengers.row_no = trains.row_no
INNER JOIN bookings
ON trains.row_no = bookings.booking_no
group by Age_catagory;

-- trains with travel time of 6 hours or less 
select train_Id, length_of_travel from trains
where length_of_travel <= '06:00:00'
order by length_of_travel desc;

-- extracting initials from the name
select left(passenger_fname, 2) as fname_inititals, left(passenger_lname, 2) as lname_inititals  from passengers;


	




