-- ============================================================
-- TASK 2: DELIVERY DELAY ANALYSIS 
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: Calculate delivery delay (in days) for each order
-- ------------------------------------------------------------
SELECT
    o.Order_ID,
    o.Warehouse_ID,
    o.Route_ID,
    o.Agent_ID,
    o.Order_Date,
    o.Expected_Delivery_Date,
    o.Actual_Delivery_Date,
    DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) AS delay_days,
    CASE
        WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0 THEN 'Delayed'
        WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) = 0 THEN 'On-Time'
        ELSE 'Early'
    END AS delivery_status,
    o.Order_Value
FROM Orders o
ORDER BY delay_days DESC;

SELECT
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) > 0 THEN 1 ELSE 0 END)     AS Delay,
    SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) = 0 THEN 1 ELSE 0 END)     AS On_Time,
    MAX(DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)) AS Max_Delay_Days,
    ROUND(AVG(CASE 
        WHEN DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) > 0 
        THEN DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date) 
    END), 2)  AS Avg_Delay_Delayed_Only
FROM Orders;

-- RESULT SUMMARY:
-- Total Orders: 300 | Delayed: 82 | On-Time: 218
-- Max_Delay_Days: 3 days | Avg Delay (delayed only): 1.66 days

-- ------------------------------------------------------------
-- STEP 2: Top 10 delayed routes based on average delay days
-- ------------------------------------------------------------

SELECT
    r.Route_ID,
    r.Start_Location,
    r.End_Location,
    r.Distance_KM,
    COUNT(o.Order_ID) AS total_orders,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0 THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date)), 2) AS avg_delay_days,
    ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(o.Order_ID), 1) 
    AS delay_pct
FROM Routes r
JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location, r.Distance_KM
ORDER BY avg_delay_days DESC, delay_pct DESC
LIMIT 10;


-- TOP 10 RESULT:
-- Route_ID | Start_Location | End_Location | Total | Delayed | Avg Delay | Delay%
-- RT_13    | Hyderabad      | Jaipur       |  11   |    6    |   1.09    | 54.5%
-- RT_05    | Pune           | Pune         |  20   |    8    |   0.65    | 40.0%
-- RT_14    | Mumbai         | Mumbai       |  17   |    6    |   0.65    | 35.3%
-- RT_09    | Ahmedabad      | Mumbai       |  16   |    5    |   0.63    | 31.3%
-- RT_02    | Ahmedabad      | Mumbai       |  17   |    5    |   0.59    | 29.4%
-- RT_18    | Hyderabad      | Lucknow      |  14   |    4    |   0.57    | 28.6%
-- RT_01    | Lucknow        | Bengaluru    |  13   |    4    |   0.54    | 30.8%
-- RT_06    | Bengaluru      | Bengaluru    |  12   |    4    |   0.50    | 33.3%
-- RT_16    | Mumbai         | Mumbai       |  10   |    3    |   0.50    | 30.0%
-- RT_12    | Hyderabad      | Lucknow      |  18   |    5    |   0.50    | 27.8%


-- --------------------------------------------------------------------------
-- STEP 3: Window functions — rank all orders by delay within each warehouse
-- --------------------------------------------------------------------------
SELECT
    o.Order_ID,
    w.Warehouse_ID,
    w.City,
    o.Expected_Delivery_Date,
    o.Actual_Delivery_Date,
    DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) AS delay_days,
    RANK() OVER (
        PARTITION BY o.Warehouse_ID
        ORDER BY DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) DESC
    ) AS delay_rank,
    DENSE_RANK() OVER (
        PARTITION BY o.Warehouse_ID
        ORDER BY DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) DESC
    ) AS dense_ranking,
    ROW_NUMBER() OVER (
        PARTITION BY o.Warehouse_ID
        ORDER BY DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) DESC
    ) AS row_num
FROM Orders o
JOIN Warehouses w ON o.Warehouse_ID = w.Warehouse_ID
ORDER BY w.City, delay_rank;
-- Partial RESULT set:
-- Order_ID     |Warehouse_ID|City	     |Expected_Delivery_Date|Actual_Delivery_Date|delay_days|delay_rank|dense_ranking|row_num|
-- FLP-ORD-0179 	WH_04	  Ahmedabad		2025-09-05	           2025-09-08	            3	        1	    1	        2
-- FLP-ORD-0010	    WH_04	  Ahmedabad		2025-07-06				2025-07-0			    3	        1	    1	        1
-- FLP-ORD-0021		WH_04	  Ahmedabad		2025-09-02				2025-09-04				2			3		2			3
-- FLP-ORD-0256		WH_04	  Ahmedabad		2025-07-23				2025-07-25				2			3		2			4
-- FLP-ORD-0224		WH_04	  Ahmedabad		2025-08-31				2025-09-01				1			5		3			8
-- FLP-ORD-0137		WH_04	  Ahmedabad		2025-08-03				2025-08-04				1			5		3			7
-- FLP-ORD-0200		WH_04	  Ahmedabad		2025-08-27				2025-08-28				1			5		3			6
-- FLP-ORD-0233		WH_04	  Ahmedabad		2025-07-23				2025-07-23				0			9		4			13
-- FLP-ORD-0059		WH_04	  Ahmedabad		2025-08-14				2025-08-14				0			9		4			17

