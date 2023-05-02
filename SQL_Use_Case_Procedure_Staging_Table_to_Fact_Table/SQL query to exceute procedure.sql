-- Selecting Dabase
USE test;

-- Creating Tables staging_table & Fact_table
CREATE TABLE staging_table (
    Start_Date VARCHAR(255),
    End_Date VARCHAR(255),
    Data_1 VARCHAR(255),
    Data_2 VARCHAR(255),
    Data_3 VARCHAR(255)
);

CREATE TABLE Fact_table (
    Start_Date DATE,
    End_Date DATE,
    Data_1 VARCHAR(255),
    Data_2 VARCHAR(255),
    Data_3 VARCHAR(255)
);

-- Inserting Data in our Tables
INSERT INTO staging_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
VALUES 
('2022-03-01', '2022-03-31', 'ABC', '123', 'xyz'),
('2022-04-01', '2022-04-30', 'DEF', '456', 'pqr'),
('2022-05-01', '2022-05-31', 'GHI', '789', 'lmn'),
('2022-03-02', '2022-03-12', 'jhdjhwb', '123', 'xyssdz'),
('2022-03-02', '2022-03-12', 'jhdjhwb', '123', 'xyssdz');

INSERT INTO Fact_table(Start_Date, End_Date, Data_1, Data_2, Data_3)
VALUES 
('2022-03-01', '2022-03-31', 'jhdjhwb', '123', 'xyssdz'),
('2022-04-01', '2022-04-30', 'DwdqwfwdEF', '456', 'pqwdcdcr'),
('2022-05-01', '2022-05-31', 'GvdHI', '785rew9', 'lmdfvn');

-- to view table
select * from fact_table;
select * from Staging_table;

/*
-- deleting entire rows from table
truncate table fact_table;
truncate table Staging_table;
*/

/*
-- deleting entire rows from table
drop table fact_table;
drop table Staging_table;
*/

-- Testing Queries 
-- insert data from fact table to staging table 
INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
SELECT s.Start_Date, s.End_Date, s.Data_1, s.Data_2, s.Data_3
FROM staging_table s
    LEFT JOIN fact_table f
    ON f.Start_Date = s.Start_Date
    AND f.End_Date = s.End_Date
    WHERE f.Start_Date IS NULL
    AND f.End_Date IS NULL;

-- Creating table using existing table
create table actor_v1 (select * from test.actor);
create table actor_v2 (select * from test.actor);
select * from ACTOR_V2;
call view_table('actor_v1');


/*  
-- Deleting rows from table
delete from staging_table; 
delete from Fact_table; 
*/

/* 
-- Deleting Column from Table
ALTER TABLE fact_table
DROP COLUMN id;	

ALTER TABLE staging_table
DROP COLUMN id;	
*/


-- dynamically calling table from one database
Delimiter //
Create Procedure view_table(in _name text)
Begin 
    set @query = concat('select * from ', _name);
    prepare stmt from @query;
    execute stmt;
end //
Delimiter ;
-- calling procedure
call view_table('actor_v1');


-- Creating some Test Procedures
-- Creating Procedure to Insert/ Update/ Delete by checking Start Date and End Date 

-- Insert Or Update FactTable from StagingTable
DELIMITER //

CREATE PROCEDURE InsertOrUpdateFactTable()
BEGIN
    -- Insert new rows from staging table into fact table
    INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
    SELECT Start_Date, End_Date, Data_1, Data_2, Data_3
    FROM test.staging_table;

    -- Update existing rows in fact table if the Start Date and End Date are the same but the other data is different
    UPDATE fact_table
    INNER JOIN test.staging_table
    ON fact_table.Start_Date = test.staging_table.Start_Date
    AND fact_table.End_Date = test.staging_table.End_Date
    SET fact_table.Data_1 = test.staging_table.Data_1,
        fact_table.Data_2 = test.staging_table.Data_2,
        fact_table.Data_3 = test.staging_table.Data_3
    WHERE fact_table.Data_1 != test.staging_table.Data_1
    OR fact_table.Data_2 != test.staging_table.Data_2
    OR fact_table.Data_3 != test.staging_table.Data_3;

    -- Delete duplicate rows from fact table
    
	ALTER TABLE fact_table ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;
	DELETE FROM fact_table
	WHERE id IN (
		SELECT id FROM (
			SELECT id, ROW_NUMBER() OVER (
				PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
				ORDER BY id
			) AS rn
			FROM fact_table
		) t
		WHERE rn > 1
	);
	ALTER TABLE fact_table
	DROP COLUMN id;
    
END //

DELIMITER ;

call InsertOrUpdateFactTable();

-- Update FactTable From Staging Table procedure
DELIMITER //

CREATE PROCEDURE UpdateFactTableFromStaging()
BEGIN
    -- Update existing rows in fact table if the Start Date and End Date are the same
    -- but the other data is different
    UPDATE fact_table
    INNER JOIN staging_table
    ON fact_table.Start_Date = staging_table.Start_Date
    AND fact_table.End_Date = staging_table.End_Date
    SET fact_table.Data_1 = staging_table.Data_1,
        fact_table.Data_2 = staging_table.Data_2,
        fact_table.Data_3 = staging_table.Data_3;

    -- Insert new rows from fact table into staging table if they don't exist
    INSERT INTO staging_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
    SELECT fact_table.Start_Date, fact_table.End_Date, fact_table.Data_1, fact_table.Data_2, fact_table.Data_3
    FROM fact_table
    LEFT JOIN staging_table
    ON fact_table.Start_Date = staging_table.Start_Date
    AND fact_table.End_Date = staging_table.End_Date
    WHERE staging_table.Start_Date IS NULL
    AND staging_table.End_Date IS NULL;

    -- Delete duplicate rows from fact table
	ALTER TABLE fact_table ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;
	DELETE FROM fact_table
	WHERE id IN (
		SELECT id FROM (
			SELECT id, ROW_NUMBER() OVER (
				PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
				ORDER BY id
			) AS rn
			FROM fact_table
		) t
		WHERE rn > 1
	);
	ALTER TABLE fact_table
	DROP COLUMN id;
    
END //

DELIMITER ;

call UpdateFactTableFromStaging();

DROP PROCEDURE IF EXISTS UpdateFactTableFromStaging;

-- to disable safe mode to update using procedure
SET SQL_SAFE_UPDATES = 0;

-- to enable safe mode 
SET SQL_SAFE_UPDATES = 1;

-- Procedure to update FactTable from StagingTable & StagingTable from FactTable
DELIMITER //

CREATE PROCEDURE UpsertFactTableFromStaging()
BEGIN
    -- Add id column to staging_table if it doesn't exist
    IF NOT EXISTS (
        SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'staging_table' 
        AND COLUMN_NAME = 'id'
    ) THEN
        ALTER TABLE staging_table ADD COLUMN id INT AUTO_INCREMENT KEY;
    END IF;

    -- Add id column to fact_table if it doesn't exist
    IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME = 'fact_table' 
		AND COLUMN_NAME = 'id'
	) 
	THEN 
		ALTER TABLE fact_table ADD COLUMN id INT AUTO_INCREMENT KEY;
	END IF;

    -- Update matching rows in fact table from staging table
    UPDATE fact_table
    INNER JOIN staging_table
    ON fact_table.Start_Date = staging_table.Start_Date
    AND fact_table.End_Date = staging_table.End_Date
    SET fact_table.Data_1 = staging_table.Data_1,
        fact_table.Data_2 = staging_table.Data_2,
        fact_table.Data_3 = staging_table.Data_3;

    -- Insert new rows from staging table into fact table if they don't exist
    INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
    SELECT s.Start_Date, s.End_Date, s.Data_1, s.Data_2, s.Data_3
    FROM staging_table AS s
    LEFT JOIN fact_table AS f
    ON s.Start_Date = f.Start_Date AND s.End_Date = f.End_Date
    WHERE f.Start_Date IS NULL AND f.End_Date IS NULL;

	-- Insert new rows from fact table into staging table if they don't exist
	INSERT INTO staging_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
	SELECT f.Start_Date, f.End_Date, f.Data_1, f.Data_2, f.Data_3
	FROM fact_table f
    LEFT JOIN staging_table s
    ON f.Start_Date = s.Start_Date
    AND f.End_Date = s.End_Date
    WHERE s.Start_Date IS NULL
    AND s.End_Date IS NULL;
	
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


-- Checking For Duplicate Values in Table
SELECT Start_Date, End_Date, Data_1, Data_2, Data_3, COUNT(*)
FROM fact_table
GROUP BY Start_Date, End_Date, Data_1, Data_2, Data_3
HAVING COUNT(*) > 1;

-- OR

/*
ALTER TABLE fact_table
ADD COLUMN  id INT AUTO_INCREMENT key;
SELECT t.*, ROW_NUMBER() OVER (
    PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
    ORDER BY id
) AS rn
FROM (SELECT * FROM fact_table) AS t;

-- OR

ALTER TABLE staging_table
ADD COLUMN  id INT AUTO_INCREMENT key;
SELECT t.*, ROW_NUMBER() OVER (
    PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
    ORDER BY id
) AS rn
FROM (SELECT * FROM staging_table) AS t;
*/

-- OR 

CREATE INDEX idx_fact_table_partition_order ON fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3, id);
SELECT *, COUNT(*) OVER (
    PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
) AS dup_count
FROM fact_table;

SELECT *, COUNT(*) OVER (
    PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
) AS dup_count
FROM staging_table;

-- OR
-- to only get id of duplicate rows and show it
SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER (
            PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
--             ORDER BY id
        ) AS rn
        FROM fact_table
    ) t
    WHERE rn > 1;

-- OR

WITH cte AS (
    SELECT Start_Date, End_Date, Data_1, Data_2, Data_3,
           ROW_NUMBER() OVER (PARTITION BY Start_Date, End_Date ORDER BY Start_Date) AS rn
    FROM fact_table
)
SELECT * FROM cte WHERE rn > 1;

-- deleting duplicate rows from the table if we are having only category then only write alter query to add id column for deletion
ALTER TABLE fact_table ADD COLUMN id INT AUTO_INCREMENT KEY;
DELETE FROM fact_table
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
            PARTITION BY Start_Date, End_Date, Data_1, Data_2, Data_3
            ORDER BY id
        ) AS rn
        FROM fact_table
    ) t
    WHERE rn > 1
);

-- OR

/*
-- Creating Temporary Tabld
CREATE TEMPORARY TABLE temp_table AS
SELECT Start_Date, End_Date, Data_1, Data_2, Data_3
FROM fact_table
GROUP BY Start_Date, End_Date, Data_1, Data_2, Data_3;

TRUNCATE TABLE fact_table;

INSERT INTO fact_table (Start_Date, End_Date, Data_1, Data_2, Data_3)
SELECT Start_Date, End_Date, Data_1, Data_2, Data_3
FROM temp_table;

DROP TEMPORARY TABLE IF EXISTS temp_table;

-- to drop id Column if not needed
ALTER TABLE fact_table
DROP COLUMN id;

-- to drop procedures 
DROP PROCEDURE IF EXISTS UpsertFactTableFromStaging;

-- Drop procedure
DROP PROCEDURE IF EXISTS UpsertFactTableFromStaging;
*/ 

-- exceuting procedure
call UpsertFactTableFromStaging;
