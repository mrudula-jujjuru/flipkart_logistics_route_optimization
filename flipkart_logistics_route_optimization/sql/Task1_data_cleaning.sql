-- ============================================================
-- TASK 1: DATA CLEANING & PREPARATION 
-- Dataset: Orders (300 rows), Routes (20 rows), Warehouses (10 rows)
--          DeliveryAgents (50 rows), ShipmentTracking (1000 rows)
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: Identify and delete duplicate Order_ID records
-- ------------------------------------------------------------
-- First, identify any duplicates
SELECT
    Order_ID,
    COUNT(*) AS duplicate_count
FROM Orders
GROUP BY Order_ID
HAVING COUNT(*) > 1;
-- ✅ Result: 0 duplicates found — data is already clean skip to STEP 2

-- Delete duplicates keeping the first occurrence
SET SQL_SAFE_UPDATES = 0;

DELETE o1 
FROM Orders o1
INNER JOIN Orders o2 
  ON  o1.Order_ID = o2.Order_ID
  AND o1.Order_ID > o2.Order_ID ;

-- Turn safe mode back on
SET SQL_SAFE_UPDATES = 1; 
-- Verify result
SELECT COUNT(*) AS total_orders_after_dedup FROM Orders;

-- ------------------------------------------------------------
-- STEP 2: Replace NULL Traffic_Delay_Min with route average
-- ------------------------------------------------------------
-- Check for NULLs in Traffic_Delay_Min
SELECT
    COUNT(*) AS total_routes,
    SUM(CASE WHEN Traffic_Delay_Min IS NULL THEN 1 ELSE 0 END) AS null_count,
    ROUND(AVG(Traffic_Delay_Min), 2) AS current_avg
FROM Routes;
-- ✅ Result: No NULLs found in Traffic_Delay_Min column skip to STEP 3
-- Replace NULLs with the average of non-null values
SET SQL_SAFE_UPDATES = 0;
UPDATE Routes r1
JOIN (
    SELECT ROUND(AVG(Traffic_Delay_Min), 2) AS avg_delay
    FROM Routes
    WHERE Traffic_Delay_Min IS NOT NULL
) avg_tbl
SET r1.Traffic_Delay_Min = avg_tbl.avg_delay
WHERE r1.Traffic_Delay_Min IS NULL;
-- Turn safe mode back on
SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- STEP 3: Convert date columns to YYYY-MM-DD format
-- ------------------------------------------------------------
-- Verify date format and display standardised
SELECT
    Order_ID,
    Order_Date,
    Expected_Delivery_Date,
    Actual_Delivery_Date
FROM Orders;
-- ✅ Result: All dates already in YYYY-MM-DD format

-- If dates were stored as VARCHAR, convert using:
-- UPDATE Orders SET Order_Date = STR_TO_DATE(Order_Date, '%Y-%m-%d');
-- ALTER TABLE Orders MODIFY COLUMN Order_Date DATE;


-- ------------------------------------------------------------
-- STEP 4: Flag records where Actual_Delivery_Date < Order_Date
-- ------------------------------------------------------------

-- Detect invalid records
SELECT
    Order_ID,
    Order_Date,
    Actual_Delivery_Date,
    DATEDIFF(Actual_Delivery_Date, Order_Date) AS days_diff,
    'ANOMALY: Delivery before Order Date'       AS flag
FROM Orders
WHERE Actual_Delivery_Date < Order_Date;
-- ✅ Result: 0 anomalous records found skip 

-- Add flag column
ALTER TABLE Orders
ADD COLUMN date_anomaly_flag VARCHAR(50) DEFAULT NULL;

SET SQL_SAFE_UPDATES = 0;

UPDATE Orders
SET date_anomaly_flag = CASE
    WHEN Actual_Delivery_Date < Order_Date  THEN 'DELIVERY_BEFORE_ORDER'
    WHEN Actual_Delivery_Date >= Order_Date THEN 'NO_ANOMALY'
END;

SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- DATA QUALITY SUMMARY
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM routes) AS total_routes,
    (SELECT COUNT(*) FROM warehouses) AS total_warehouses,
    (SELECT COUNT(*) FROM agents) AS total_agents,
    (SELECT COUNT(*) FROM tracking) AS total_tracking_records,
    (SELECT COUNT(*) FROM orders WHERE date_anomaly_flag ='DELIVERY_BEFORE_ORDER') AS flagged_date_anomalies,
    (SELECT COUNT(*) FROM routes WHERE Traffic_Delay_Min IS NULL) AS null_traffic_delays;

-- RESULT:
-- total_orders | total_routes | total_warehouses | total_agents | total_tracking_records | flagged_date_anomalies | null_traffic_delays
--     300      |      20      |        10        |      50      |      1000              |    0                    |      0