-- ============================================================
-- TASK 4: WAREHOUSE PERFORMANCE
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: Top 3 warehouses with highest average processing time
---------------------------------------------------------------
SELECT
    w.Warehouse_ID,
    w.Warehouse_Name,
    w.City,
    w.Average_Processing_Time_Min,
    COUNT(o.Order_ID)     AS total_orders_handled
FROM Warehouses w
LEFT JOIN Orders o ON w.Warehouse_ID = o.Warehouse_ID
GROUP BY w.Warehouse_ID
ORDER BY w.Average_Processing_Time_Min DESC
LIMIT 3;

-- RESULT:
-- Warehouse_ID | Name                              | City      | Average_Processing_Time_Min	| total_orders_handled
-- WH_10        | Flipkart FC Chennai               | Chennai   | 117 		   					|  26
-- WH_09        | Flipkart FC Hyderabad             | Hyderabad | 110 		   					|  31
-- WH_01        | Flipkart FC Lucknow               | Lucknow   | 101 		   					|  26

-- ------------------------------------------------------------
-- STEP 2: Total vs delayed shipments per warehouse
-- ------------------------------------------------------------

SELECT
    w.Warehouse_ID,
    w.Warehouse_Name,
    w.City,
    w.Average_Processing_Time_Min, COUNT(o.Order_ID) AS total_shipments,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
             THEN 1 ELSE 0 END)                      AS delayed_shipments,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) <= 0
             THEN 1 ELSE 0 END)                      AS on_time_shipments,
    ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
                   THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(o.Order_ID), 0), 1) AS delay_pct,
    ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) <= 0
                   THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(o.Order_ID), 0), 1) AS on_time_pct
FROM Warehouses w
LEFT JOIN Orders o ON w.Warehouse_ID = o.Warehouse_ID
GROUP BY w.Warehouse_ID
ORDER BY delayed_shipments DESC;

-- Result set
-- Warehouse_ID	|Warehouse_Name			|City		|Average_Processing_Time_Min|total_shipments|delayed_shipments	|on_time_shipments	|delay_pct	|on_time_pct
-- WH_10		|Flipkart FC Chennai	|Chennai	|117						|30				|11					|19					|36.7		|63.3
-- WH_08		|Flipkart FC Bengaluru	|Bengaluru	|44							|38				|10					|28					|26.3		|73.7
-- WH_02		|Flipkart FC Delhi		|Delhi		|63							|27				|9					|18					|33.3		|66.7
-- WH_03		|Flipkart FC Mumbai		|Mumbai		|84							|25				|9					|16					|36.0		|64.0
-- WH_04		|Flipkart FC Ahmedabad	|Ahmedabad	|81							|31				|8					|23					|25.8		|74.2
-- WH_05		|Flipkart FC Jaipur		|Jaipur		|58							|29				|8					|21					|27.6		|72.4
-- WH_07		|Flipkart FC Pune		|Pune		|41							|26				|8					|18					|30.8		|69.2
-- WH_09		|Flipkart FC Hyderabad	|Hyderabad	|110						|43				|7					|36					|16.3		|83.7
-- WH_01		|Flipkart FC Lucknow	|Lucknow	|101						|24				|6					|18					|25.0		|75.0
-- WH_06		|Flipkart FC Kolkata	|Kolkata	|95							|27				|6					|21					|22.2		|77.8



-- ------------------------------------------------------------
-- STEP 3: CTE — find bottleneck warehouses
--         (processing time > global average of 79.4 min)
-- ------------------------------------------------------------

WITH global_avg AS (
    SELECT ROUND(AVG(Average_Processing_Time_Min), 2) AS global_avg_proc_time
    FROM Warehouses
),
warehouse_summary AS (
    SELECT
        w.Warehouse_ID,
        w.City,
        w.Average_Processing_Time_Min,
        COUNT(o.Order_ID)                                        AS total_orders,
        SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0 
                 THEN 1 ELSE 0 END)                              AS delayed_orders
    FROM Warehouses w
    LEFT JOIN Orders o ON w.Warehouse_ID = o.Warehouse_ID
    GROUP BY w.Warehouse_ID
)
SELECT
    ws.Warehouse_ID,
    ws.City,
    ws.Average_Processing_Time_Min                               AS proc_time_min,
    ROUND(ga.global_avg_proc_time, 2)                            AS global_avg_min,
    ROUND(ws.Average_Processing_Time_Min
          - ga.global_avg_proc_time, 2)                          AS excess_min,
    ws.total_orders,
    ws.delayed_orders,
    'BOTTLENECK'                                                 AS warehouse_status
FROM warehouse_summary ws
CROSS JOIN global_avg ga
WHERE ws.Average_Processing_Time_Min > ga.global_avg_proc_time
ORDER BY ws.Average_Processing_Time_Min DESC;

-- RESULT (bottleneck warehouses = processing time > 79.4 min):
-- Warehouse_ID	|City		|proc_time_min	|global_avg_min	|excess_min	|total_orders	|delayed_orders	|warehouse_status
-- WH_10		|Chennai	|117			|79.40			|37.60		|30				|11				|BOTTLENECK
-- WH_09		|Hyderabad	|110			|79.40			|30.60		|43				|7				|BOTTLENECK
-- WH_01		|Lucknow	|101			|79.40			|21.60		|24				|6				|BOTTLENECK
-- WH_06		|Kolkata	|95				|79.40			|15.60		|27				|6				|BOTTLENECK
-- WH_03		|Mumbai		|84				|79.40			|4.60		|25				|9				|BOTTLENECK
-- WH_04		|Ahmedabad	|81				|79.40			|1.60		|31				|8				|BOTTLENECK


-- ------------------------------------------------------------
-- STEP 4: Rank warehouses by on-time delivery percentage
-- ------------------------------------------------------------

SELECT
    w.Warehouse_ID,
    w.City,
    COUNT(o.Order_ID)                                            AS total_shipments,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) <= 0
             THEN 1 ELSE 0 END)                                  AS on_time_count,
    ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) <= 0
                   THEN 1 ELSE 0 END) * 100.0
          / NULLIF(COUNT(o.Order_ID), 0), 1)                     AS on_time_pct,
    RANK() OVER (
        ORDER BY
            SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) <= 0
                     THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(o.Order_ID), 0) DESC ) AS performance_rank
FROM Warehouses w
LEFT JOIN Orders o ON w.Warehouse_ID = o.Warehouse_ID
GROUP BY w.Warehouse_ID
ORDER BY performance_rank;

-- RESULT ( 10 warehouse data) :
-- Warehouse_ID	|City		|total_shipments|on_time_count	|on_time_pct|performance_rank
-- WH_09		|Hyderabad	|43				|36				|83.7		|1
-- WH_06		|Kolkata	|27				|21				|77.8		|2
-- WH_01		|Lucknow	|24				|18				|75.0		|3
-- WH_04		|Ahmedabad	|31				|23				|74.2		|4
-- WH_08		|Bengaluru	|38				|28				|73.7		|5
-- WH_05		|Jaipur		|29				|21				|72.4		|6
-- WH_07		|Pune		|26				|18				|69.2		|7
-- WH_02		|Delhi		|27				|18				|66.7		|8
-- WH_03		|Mumbai		|25				|16				|64.0		|9
-- WH_10		|Chennai	|30				|19				|63.3		|10
