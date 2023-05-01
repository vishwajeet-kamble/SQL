# SQL Use Case

## Create a Store Procedure to Update Data from Staging Table to Fact Table by Checking Specified conditions:
## Conditions – 
1.	Check Staging Table data and add rows in Fact Table if it not exist in Fact Table.
2.	Check Staging Table & Fact Table data and if Keys matches for rows then update other column rows data with Staging Table rows data
For eg – In our table Keys are start_time , end_time.
3.	Check Fact Table data and add rows in Staging Table if it not exist in Fact Table.
4.	Remove duplicates from Staging Table and Fact Table

## Concept of Staging Table and Fact Table in Data Warehousing
The concept of a staging table and a fact table is commonly used in data warehousing and ETL (Extract, Transform, Load) processes.
A staging table is a temporary table that holds data before it is loaded into the final destination table, which is typically the fact table. The staging table is used to hold data from different sources, and it may contain duplicates, inconsistent data, or data that needs to be transformed or validated before it is loaded into the fact table.
The fact table, on the other hand, is the main table in a star or snowflake schema that holds the data that has been transformed and cleaned from the staging table. The fact table typically contains the measures or metrics that are used to analyze and report the data, and it is joined to dimension tables that provide the context or metadata for the measures.
In the ETL process, data is extracted from the source systems, transformed or cleaned in the staging table, and then loaded into the fact table for reporting and analysis. The staging table is often used to simplify the ETL process, as it allows for data to be validated and transformed before it is loaded into the fact table.

## In This Usecase we are Upserting Data - 
Upsert is a database operation that combines the actions of inserting a new row in a table with updating an existing row, depending on whether the row already exists or not. In other words, if a row already exists in the table, the upsert operation updates it with new data, otherwise, it inserts a new row with the given data. The upsert operation is often used to efficiently synchronize data between different sources, such as between a staging table and a fact table, as seen in the example provided. Upsert is also known as merge, insert or update, and put or post depending on the context in which it is used.

## Summary of Procedure –
This is a stored procedure called "UpsertFactTableFromStaging" that performs an "upsert" operation on a fact table using data from a staging table. An "upsert" operation means that the procedure updates existing rows if they match certain criteria, and inserts new rows if they do not exist in the fact table.
The procedure first checks if the "id" column exists in both the staging and fact tables. If it does not exist, it adds an "id" column with an auto-incrementing primary key constraint to both tables.
Next, it updates matching rows in the fact table using data from the staging table. If a row with the same values for "Start_Date", "End_Date", "Data_1", "Data_2", and "Data_3" already exists in the fact table, the procedure updates that row with the corresponding values from the staging table.
Then, it deletes any duplicate rows from the fact table. Duplicate rows are defined as those with the same values for "Start_Date", "End_Date", "Data_1", "Data_2", and "Data_3", but with different "id" values.
After that, it inserts any new rows from the staging table into the fact table if they don't already exist in the fact table. This is done by performing a left join between the staging and fact tables and selecting only the rows where the join condition fails.
Finally, it deletes any duplicate rows from the staging table. Duplicate rows are defined as those with the same values for "Start_Date", "End_Date", "Data_1", "Data_2", and "Data_3", but with different "id" values.
At the end of the procedure, it drops the "id" column from both the staging and fact tables.
The delimiter statement is used to separate the procedure definition from other SQL statements in the same script. In this case, it sets the delimiter to "//" so that the semicolon can be used within the stored procedure without causing errors. The delimiter is then set back to ";" using the DELIMITER statement at the end of the procedure.

## Code for Procedure –
	
	DELIMITER //

	CREATE PROCEDURE UpsertFactTableFromStaging()
	BEGIN
	    -- Add id column to staging_table if it doesn't exist
	    IF NOT EXISTS (
		SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME = 'staging_table' 
		AND COLUMN_NAME = 'id'
	    ) THEN
		ALTER TABLE staging_table ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;
	    END IF;

	    -- Add id column to fact_table if it doesn't exist
	    IF NOT EXISTS (
		SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME = 'fact_table' 
		AND COLUMN_NAME = 'id'
	    ) THEN
		ALTER TABLE fact_table ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;
	    END IF;

	    -- Update matching rows in fact table from staging table
	    INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
	    SELECT s.Start_Date, s.End_Date, s.Data_1, s.Data_2, s.Data_3
	    FROM staging_table AS s
	    ON DUPLICATE KEY UPDATE 
		Data_1 = VALUES(Data_1),
		Data_2 = VALUES(Data_2),
		Data_3 = VALUES(Data_3);

	    -- Delete duplicate rows from fact table
	    DELETE f1
	    FROM fact_table f1
	    JOIN fact_table f2
	    ON f1.Start_Date = f2.Start_Date 
	    AND f1.End_Date = f2.End_Date 
	    AND f1.Data_1 = f2.Data_1 
	    AND f1.Data_2 = f2.Data_2 
	    AND f1.Data_3 = f2.Data_3 
	    AND f1.id > f2.id;

	    -- Insert new rows from staging table into fact table if they don't exist
	    INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
	    SELECT s.Start_Date, s.End_Date, s.Data_1, s.Data_2, s.Data_3
	    FROM staging_table AS s
	    LEFT JOIN fact_table AS f
	    ON s.Start_Date = f.Start_Date AND s.End_Date = f.End_Date
	    WHERE f.Start_Date IS NULL AND f.End_Date IS NULL;

	    -- Delete duplicate rows from staging table
	    DELETE s1
	    FROM staging_table s1
	    JOIN staging_table s2
	    ON s1.Start_Date = s2.Start_Date 
	    AND s1.End_Date = s2.End_Date 
	    AND s1.Data_1 = s2.Data_1 
	    AND s1.Data_2 = s2.Data_2 
	    AND s1.Data_3 = s2.Data_3 
	    AND s1.id > s2.id;

	    ALTER TABLE fact_table
		DROP COLUMN id;	

	    ALTER TABLE staging_table
		DROP COLUMN id;	
	END //

	DELIMITER ;
	

Sample Table – 

Fact_Table - <br>

![alt text](https://github.com/vishwajeet-kamble/SQL/blob/main/SQL_Use_Case_Procedure_Staging_Table_to_Fact_Table/images/FACT_TABLE.png?raw=true)


Staging_Table - <br>

![alt text](https://github.com/vishwajeet-kamble/SQL/blob/main/SQL_Use_Case_Procedure_Staging_Table_to_Fact_Table/images/STAGING_TABLE.png?raw=true)


After Execution of Query – 

Fact_Table - <br>

![alt text](https://github.com/vishwajeet-kamble/SQL/blob/main/SQL_Use_Case_Procedure_Staging_Table_to_Fact_Table/images/FACT_TABLE_V1.png?raw=true)


Staging_Table - <br>

![alt text](https://github.com/vishwajeet-kamble/SQL/blob/main/SQL_Use_Case_Procedure_Staging_Table_to_Fact_Table/images/STAGING_TABLE_V1.png?raw=true)






