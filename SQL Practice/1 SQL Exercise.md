# -- SQL Practice: 

## -- Working with CTE 

**-- Creating Order_Demo Table**

	CREATE TABLE `test_db`.`orders_demo` ( 
	`order_id` VARCHAR(12) NULL, 
	`amount` INT NULL, 
	`order_date` VARCHAR(12) NULL); 

**-- Viewing Table** 
``` For Code we can use triple backticks.
SELECT * FROM test_db.orders_demo; 
```
**-- Deleting if any record is present in table**

	Truncate table test_db.orders_demo; 

**-- Adding values in underling table**

	insert into test_db.orders_demo values  
	('1', 100, '1 Jan'), 
	('5', 120, '2 Jan'), 
	('4', 130, '3 Jan'), 
	('3', 205, '4 Jan'), 
	('6', 170, '5 Jan'), 
	('7', 165, '6 Jan'); 

**-- Viewing Table**

	Select * from test_db.orders_demo; 
 
**Output >>**
| order_id | amount	| order_date |
|-----|-----|-----|
| 1 | 100 | 1 Jan | 
| 5 |	120 | 2 Jan |	
| 4 |	130 |	3 Jan |	
| 3 |	205 |	4 Jan |	
| 6 |	170 |	5 Jan |	
| 7 |	165 |	6 Jan | 

### Question >> Provide Cumulative of Amount as table follow each row 
>> 
-- Getting Row No as table goes

	Select *, row_number() over(PARTITION BY (select 0)) as rn from test_db.orders_demo; 

-- Finding Cummlative of amount col 

-- In below query  select in overclause after partition by means we dont want to partition or order by any col just provide RowNumber as default structure of table 

	WITH CTE1 AS 
	( Select *, row_number() over(PARTITION BY (select 0)) as rn from test_db.orders_demo ) 
	SELECT order_id, amount, order_date, sum(amount) OVER( ORDER BY RN ) as cummulative FROM CTE1 
	GROUP BY order_id, amount, order_date; 

**Below is the Out put Table >** 
| order_id | amount	| order_date | cummulative|
|-----|-----|-----|-----|
| 1 | 100 | 1 Jan | 100 |
| 5 |	120 | 2 Jan |	220 |
| 4 |	130 |	3 Jan |	350 |
| 3 |	205 |	4 Jan |	555 |
| 6 |	170 |	5 Jan |	725 |
| 7 |	165 |	6 Jan | 890 |

 
