SELECT * FROM nashville_data
LIMIT 30;

--Total row count-- 
SELECT COUNT(*) FROM nashville_data;

-- Check for missing data across colums--

SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT (sale_price) AS missing_price,
    COUNT(*) - COUNT (sale_date) AS missing_date,
    COUNT(*) - COUNT (land_use) AS missing_landuse,
    COUNT(*) - COUNT (property_city) AS missing_city
    FROM nashville_data;

--Sales by property type-- 

SELECT land_use, COUNT(*) AS total_sales
FROM nashville_data
GROUP BY land_use
ORDER BY total_sales DESC;

-- CHECK THE sale_price column for messy data--

SELECT DISTINCT sale_price
FROM nashville_data
WHERE sale_price !~ '^[0-9]+$'
LIMIT 30;

--CONVERT sale_price to a real number--

ALTER TABLE nashville_data
ALTER COLUMN sale_price TYPE NUMERIC
USING sale_price::NUMERIC;

-- Real price statistics --

SELECT
    MIN(sale_price) AS lowest_price,
    MAX(sale_price) AS highest_price,
    ROUND(AVG(sale_price), 2) AS average_price,
    SUM(sale_price) AS total_sale_value
    FROM nashville_data;

-- Find these outliers --
SELECT property_address, land_use, sale_price, sale_date
FROM nashville_data
ORDER BY sale_price DESC
LIMIT 15;

-- Group rows with same data and count how many times it repeats --

SELECT property_address, sale_date, sale_price, COUNT(*) AS num_records
FROM nashville_data
GROUP BY property_address, sale_date, sale_price
HAVING COUNT(*) > 1
ORDER BY num_records DESC
LIMIT 20;

-- Total the comparison --

SELECT 
    SUM(sale_price) AS total_with_duplicates,
    ROUND (SUM(sale_price) / COUNT(*),2) AS naive_avg
FROM nashville_data;

-- Create temporary duplicate view --

SELECT SUM(unique_price) AS total_without_duplicates
FROM (
    SELECT DISTINCT property_address, sale_date, sale_price AS unique_price
    FROM nashville_data
) AS deduped;

-- Create a VIEW -- 

CREATE OR REPLACE VIEW nashville_unique_sales AS
SELECT DISTINCT property_address, sale_date, sale_price, land_use, property_city
FROM nashville_data;

-- Re-run the price stats on the duplicated VIEW --

SELECT
    MIN(sale_price) AS lowest_price,
    MAX(sale_price) AS highest_price,
    ROUND(AVG(sale_price), 2) AS average_price,
    SUM(sale_price) AS total_sale_value,
    COUNT(*) AS total_unique_sales
    FROM nashville_data

--Check the VIEW's row count -- 

SELECT COUNT(*) FROM nashville_unique_sales;

-- Flag multiple parcel sales instead of removing them --

SELECT sale_date, sale_price, COUNT(*) AS parcels_in_sale
FROM nashville_data
GROUP BY sale_date, sale_price
HAVING COUNT(*) > 1
ORDER BY parcels_in_sale DESC
LIMIT 10;

-- Flag bundled sales columns --
ALTER TABLE nashville_data
ADD COLUMN is_bundled_sale BOOLEAN DEFAULT FALSE;

UPDATE nashville_data n
SET is_bundled_sale = TRUE
WHERE (n.sale_date, n.sale_price) IN (
    SELECT sale_date, sale_price
    FROM nashville_data
    GROUP BY sale_date, sale_price
    HAVING COUNT(*) > 1
);

UPDATE nashville_data n
SET is_bundled_sale = TRUE
WHERE (n.sale_date, n.sale_price) IN (
    SELECT sale_date, sale_price
    FROM nashville_data
    GROUP BY sale_date, sale_price
    HAVING COUNT(*) > 1
);

-- Get price stats --
SELECT
    MIN(sale_price) AS lowest_price,
    MAX(sale_price) AS highest_price,
    ROUND(AVG(sale_price), 2) AS average_price,
    SUM(sale_price) AS total_sale_value
FROM nashville_data
WHERE is_bundled_sale = FALSE;

--fix the land_use inconsistency--
SELECT DISTINCT land_use
FROM nashville_data
WHERE land_use IN ('VACANT RES LAND', 'VACANT RESIDENTIAL LAND');

UPDATE nashville_data
SET land_use = 'VACANT RESIDENTIAL LAND'
WHERE land_use = 'VACANT RES LAND';

SELECT land_use, COUNT(*) AS total
FROM nashville_data
WHERE land_use = 'VACANT RESIDENTIAL LAND'
GROUP BY land_use;

-- Check property_city for similar inconsistencies--
SELECT DISTINCT property_city
FROM nashville_data
ORDER BY property_city

--ANALYSIS-- Sales trend by year-- 
SELECT 
    EXTRACT(YEAR FROM sale_date::DATE) AS sale_year,
    COUNT(*) AS total_sales,
    ROUND(AVG(sale_price), 2) AS avg_price
FROM nashville_data
WHERE is_bundled_sale = FALSE
GROUP BY sale_year
ORDER BY sale_year;

-- Most valueable property types--
SELECT 
    land_use, 
    COUNT(*) AS total_sales, 
    ROUND(AVG(sale_price), 2) AS avg_price
FROM nashville_data
WHERE is_bundled_sale = FALSE
GROUP BY land_use
ORDER BY avg_price DESC
LIMIT 10;

--filter out tiny category--

SELECT 
    land_use, 
    COUNT(*) AS total_sales, 
    ROUND(AVG(sale_price), 2) AS avg_price
FROM nashville_data
WHERE is_bundled_sale = FALSE
GROUP BY land_use
HAVING COUNT(*) >=50
ORDER BY avg_price DESC
LIMIT 10;

--FIX TYPO--
UPDATE nashville_data
SET land_use = 'VACANT RESIDENTIAL LAND'
WHERE land_use = 'VACANT RESIENTIAL LAND';

SELECT 
     property_city,
    COUNT(*) AS total_sales,
    ROUND(AVG(sale_price), 2) AS avg_price
    FROM nashville_data
    WHERE is_bundled_sale = FALSE
    GROUP BY property_city
    HAVING COUNT(*) >=50
    ORDER BY avg_price DESC;

--convert sale date to proper date type--

ALTER TABLE nashville_data
ALTER COLUMN sale_date TYPE DATE 
USING sale_date::DATE;

DROP VIEW IF EXISTS nashville_unique_sales;

CREATE OR REPLACE VIEW nashville_unique_sales AS
SELECT DISTINCT property_address, sale_date, sale_price, land_use, property_city
FROM nashville_data;

ALTER TABLE nashville_data
ALTER COLUMN year_built TYPE INTEGER
USING year_built::INTEGER;

ALTER TABLE nashville_data
ALTER COLUMN bedrooms TYPE INTEGER
USING bedrooms::INTEGER;

ALTER TABLE nashville_data
ALTER COLUMN full_bath TYPE INTEGER
USING full_bath::INTEGER;

ALTER TABLE nashville_data
ALTER COLUMN half_bath TYPE INTEGER
USING half_bath::INTEGER;

ALTER TABLE nashville_data
ALTER COLUMN acreage TYPE NUMERIC
USING half_bath::NUMERIC;

ALTER TABLE nashville_data
ALTER COLUMN land_value TYPE NUMERIC
USING land_value::NUMERIC;

ALTER TABLE nashville_data
ALTER COLUMN building_value TYPE NUMERIC
USING building_value::NUMERIC;

ALTER TABLE nashville_data
ALTER COLUMN total_value TYPE NUMERIC
USING total_value::NUMERIC;

ALTER TABLE nashville_data
ADD COLUMN is_outlier BOOLEAN DEFAULT FALSE;

UPDATE nashville_data
SET is_outlier = TRUE
WHERE sale_price < 1000;