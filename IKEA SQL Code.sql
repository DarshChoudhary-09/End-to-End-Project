   -- =============================
   -- PART 1: Ikea SQL Code
   -- =============================
describe online_retail_all;

ALTER TABLE online_retail_all
RENAME COLUMN `Customer ID` TO Customer_ID;

select * from online_retail_clean;

SHOW VARIABLES LIKE 'secure_file_priv';

   -- =============================
   -- PART 2: Upload Data Into SQL Workbench
   -- =============================
USE ecommerceproject;

CREATE TABLE online_retail (
  Invoice VARCHAR(20),
  StockCode VARCHAR(20),
  Description VARCHAR(255),
  Quantity INT,
  InvoiceDate DATETIME,
  Price DECIMAL(10,3),
  `Customer ID` INT NULL,
  Country VARCHAR(50)
);

CREATE TABLE online_retail_2 LIKE online_retail;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/Darsh/New Project/IKEA Gifting Dataset/IKEA Gifting Dataset/online_retail_II page 1.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Invoice, StockCode, Description, Quantity, @dt, Price, @cust, Country)
SET InvoiceDate = STR_TO_DATE(@dt, '%d-%m-%Y %H:%i'),
    `Customer ID` = NULLIF(@cust, '');

LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/Darsh/New Project/IKEA Gifting Dataset/IKEA Gifting Dataset/online_retail_II page 2.csv'
INTO TABLE online_retail_2
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Invoice, StockCode, Description, Quantity, @dt, Price, @cust, Country)
SET InvoiceDate = STR_TO_DATE(@dt, '%d-%m-%Y %H:%i'),
    `Customer ID` = NULLIF(@cust, '');

USE ecommerceproject;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Desktop/Darsh/New Project/IKEA Gifting Dataset/IKEA Gifting Dataset/online_retail_II page 2.csv'
INTO TABLE online_retail
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Invoice, StockCode, Description, Quantity, InvoiceDate, Price, @cust, Country)
SET `Customer ID` = NULLIF(@cust, '');

   -- =============================
   -- PART 3: Data Handling
   -- =============================
use ecommerceproject;

select 'page 1' as src, count(*) as total, sum(InvoiceDate is null) as null_dates,
min(InvoiceDate) as first_date, max(InvoiceDate) as last_date
from online_retail
union all
select 'page 2', count(*), sum(InvoiceDate is null), min(InvoiceDate), max(InvoiceDate)
from online_retail_2;

SELECT
  (SELECT COUNT(*) FROM online_retail
    WHERE InvoiceDate < '2010-12-10') AS page1_overlap_rows,
  (SELECT COUNT(*) FROM online_retail_2
    WHERE InvoiceDate >= '2010-12-01 08:26:00') AS page2_overlap_rows;
    
    
CREATE TABLE online_retail_all (
  RowID INT AUTO_INCREMENT PRIMARY KEY,
  Invoice VARCHAR(20),
  StockCode VARCHAR(20),
  Description VARCHAR(255),
  Quantity INT,
  InvoiceDate DATETIME,
  Price DECIMAL(10,3),
  `Customer ID` INT NULL,
  Country VARCHAR(50),
  SourcePage VARCHAR(10)
);

INSERT INTO online_retail_all
  (Invoice, StockCode, Description, Quantity, InvoiceDate, Price, `Customer ID`, Country, SourcePage)
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, `Customer ID`, Country, 'page 2'
FROM online_retail_2
WHERE InvoiceDate < (SELECT MIN(InvoiceDate) FROM online_retail)
UNION ALL
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, `Customer ID`, Country, 'page 1'
FROM online_retail;


SELECT COUNT(*) AS total_rows, MIN(InvoiceDate), MAX(InvoiceDate) FROM online_retail_all;

SELECT COUNT(*) AS duplicate_invoice_lines
FROM (
  SELECT Invoice, StockCode, Quantity, InvoiceDate, Price, `Customer ID`, COUNT(*) AS c
  FROM online_retail_all
  GROUP BY Invoice, StockCode, Quantity, InvoiceDate, Price, `Customer ID`
  HAVING c > 1
) d;


select count(*) as total_rows from online_retail_all where InvoiceDate is null;
select count(*) as total_rows from online_retail_all where Price is null;

-- Check 1- MISSING CUSTOMER ID 
select count(*) as missing_customerID
from online_retail_all 
where Customer_ID is null; 

-- CHECK 2- NEGATIVE OR ZERO QUANTITY
select count(*) as Negative_QT
from online_retail_all 
where Quantity <= 0;

-- CHECK 3- MISSING DESCRIPTION
select count(*) as Missing_Description
from online_retail_all
where Description is null;

-- CHECK 4- EXACT DUPLICATES ROWS
select
count(*) as duplicates_groups,
sum(Exact_Duplicates) as total_rows_invloved,
sum(Exact_Duplicates - 1) as total_rows_to_removed
from(
select Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country,
count(*) as Exact_Duplicates
from online_retail_all
group by Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
having count(*) > 1
)d;

CREATE TABLE online_retail_clean LIKE online_retail_all;

INSERT INTO online_retail_clean
  (RowID, Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourcePage)
SELECT RowID, Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourcePage
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
           ORDER BY RowID
         ) AS RowNum
  FROM online_retail_all
) AS Deduped
WHERE RowNum = 1;


SELECT (SELECT COUNT(*) FROM online_retail_all)   AS raw_rows,
       (SELECT COUNT(*) FROM online_retail_clean) AS clean_rows;


DROP TABLE IF EXISTS keep_ids;
CREATE TABLE keep_ids (RowID INT PRIMARY KEY);

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate < '2010-03-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2010-03-01' AND InvoiceDate < '2010-06-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2010-06-01' AND InvoiceDate < '2010-09-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2010-09-01' AND InvoiceDate < '2010-12-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2010-12-01' AND InvoiceDate < '2011-03-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2011-03-01' AND InvoiceDate < '2011-06-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2011-06-01' AND InvoiceDate < '2011-09-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2011-09-01' AND InvoiceDate < '2011-12-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO keep_ids SELECT MIN(RowID) FROM online_retail_all
WHERE InvoiceDate >= '2011-12-01'
GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country;

INSERT INTO online_retail_clean
SELECT a.*
FROM online_retail_all a
JOIN keep_ids k ON a.RowID = k.RowID;

SELECT (SELECT COUNT(*) FROM online_retail_all)   AS raw_rows,
       (SELECT COUNT(*) FROM online_retail_clean) AS clean_rows;

SELECT COUNT(*) AS remaining_duplicate_groups
FROM (
  SELECT 1
  FROM online_retail_clean
  GROUP BY Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
  HAVING COUNT(*) > 1
) d;

DROP TABLE keep_ids;

select * from online_retail_clean;   