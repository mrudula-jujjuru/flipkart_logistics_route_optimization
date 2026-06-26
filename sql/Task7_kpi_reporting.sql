-- ============================================================
-- TASK 7: ADVANCED KPI REPORTING 
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- KPI 1: Average Delivery Delay per Region (Start_Location)
-- ------------------------------------------------------------

SELECT
    r.Start_Location                                              AS region,
    COUNT(o.Order_ID)                                             AS total_orders,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,
                            o.Expected_Delivery_Date) > 0
             THEN 1 ELSE 0 END)                                   AS delayed_orders,
    ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date,
                       o.Expected_Delivery_Date)), 2)             AS avg_delay_days
                       
FROM Routes r
JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Start_Location
ORDER BY avg_delay_days DESC;

-- RESULT:
-- region 	 |total_orders	|delayed_orders	|avg_delay_days	
-- Ahmedabad |  33   		|   10    		|   0.61    	
-- Pune      |  36  		|   11    		|   0.56    	
-- Lucknow   |  13   		|    4    		|   0.54    	
-- Bengaluru |  12   		|    4    		|   0.50    	
-- Mumbai    |  51   		|   16    		|   0.47    	
-- Hyderabad | 155   		|   37    		|   0.38    	

-- ------------------------------------------------------------
-- KPI 2: On-Time Delivery % = (On-Time / Total) * 100
-- ------------------------------------------------------------

-- Overall On-Time Delivery %
SELECT
    'OVERALL'                                                     AS scope,
    COUNT(*)                                                      AS total_deliveries,
    SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,
                            Expected_Delivery_Date) <= 0
             THEN 1 ELSE 0 END)                                   AS on_time_deliveries,
    SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,
                            Expected_Delivery_Date) > 0
             THEN 1 ELSE 0 END)                                   AS delayed_deliveries,
    ROUND(
        SUM(CASE WHEN DATEDIFF(Actual_Delivery_Date,
                                Expected_Delivery_Date) <= 0
                 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    )                                                             AS on_time_pct
FROM Orders;

-- RESULT: 
-- scope	| total_deliveries	|on_time_deliveries	| delayed_deliveries| on_time_pct
-- OVERALL	| 300 				| 218 				| 82 				|  72.67

-- Per Region On-Time Delivery %
SELECT
    r.Start_Location                                              AS region,
    COUNT(o.Order_ID)                                             AS total_deliveries,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,
                            o.Expected_Delivery_Date) <= 0
             THEN 1 ELSE 0 END)                                   AS on_time_deliveries,
    ROUND(
        SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,
                                o.Expected_Delivery_Date) <= 0
                 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(o.Order_ID), 0), 1
    )                                                             AS on_time_pct
FROM Routes r
JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Start_Location
ORDER BY on_time_pct DESC;

-- RESULT by region:
-- region		|total_deliveries	|on_time_deliveries	|on_time_pct
-- Hyderabad 	| 155 				| 118 				| 76.1%  ← best on-time rate
-- Ahmedabad 	|  33 				|  23 				| 69.7%
-- Pune      	|  36 				|  25 				| 69.4%
-- Lucknow   	|  13 				|   9 				| 69.2%
-- Mumbai    	|  51 				|  35 				| 68.6%
-- Bengaluru 	|  12 				|   8 				| 66.7%



-- ------------------------------------------------------------
-- KPI 3: Average Traffic Delay per Route
-- ------------------------------------------------------------

SELECT
    r.Route_ID,
    CONCAT(r.Start_Location, ' → ', r.End_Location)              AS route,
    r.Distance_KM,
    r.Traffic_Delay_Min                                           AS traffic_delay_min,
    ROUND(r.Traffic_Delay_Min / 60.0, 2)                         AS traffic_delay_hr,
    CASE
        WHEN r.Traffic_Delay_Min >= 80 THEN 'HIGH'
        WHEN r.Traffic_Delay_Min >= 40 THEN 'MODERATE'
        ELSE 'LOW'
    END                                                           AS traffic_category,
    COUNT(o.Order_ID)                                             AS total_orders
FROM Routes r
LEFT JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location,
         r.Distance_KM, r.Traffic_Delay_Min
ORDER BY r.Traffic_Delay_Min DESC;

-- RESULT Sample (first 5 rows):
-- Route_ID	|route				|Distance_KM|traffic_delay_min	|traffic_delay_hr	|traffic_category	|total_orders
-- RT_08	|Pune → Pune		|1280		|90					|1.50				|HIGH				|16
-- RT_15	|Hyderabad → Jaipur	|1587		|87					|1.45				|HIGH				|17
-- RT_09	|Ahmedabad → Mumbai	|1963		|83					|1.38				|HIGH				|16
-- RT_17	|Mumbai → Lucknow	|927		|81					|1.35				|HIGH				|15
-- RT_01	|Lucknow → Bengaluru|1009		|67					|1.12				|MODERATE			|13


-- ------------------------------------------------------------
-- KPI SUMMARY DASHBOARD (all 3 KPIs combined via CTEs)
-- ------------------------------------------------------------

WITH kpi_delay AS (
    SELECT r.Start_Location AS region,
           ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date,
                              o.Expected_Delivery_Date)), 2)     AS avg_delay_days
    FROM Routes r JOIN Orders o ON r.Route_ID = o.Route_ID
    GROUP BY r.Start_Location
),
kpi_ontime AS (
    SELECT r.Start_Location AS region,
           ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date,
                                         o.Expected_Delivery_Date) <= 0
                          THEN 1 ELSE 0 END) * 100.0
                 / COUNT(*), 1)                                  AS on_time_pct
    FROM Routes r JOIN Orders o ON r.Route_ID = o.Route_ID
    GROUP BY r.Start_Location
),
kpi_traffic AS (
    SELECT Start_Location AS region,
           ROUND(AVG(Traffic_Delay_Min), 1)                      AS avg_traffic_delay_min
    FROM Routes
    GROUP BY Start_Location
)
SELECT
    d.region,
    d.avg_delay_days,
    t.on_time_pct,
    k.avg_traffic_delay_min,
    CASE
        WHEN t.on_time_pct < 68
             THEN 'CRITICAL — Urgent intervention needed'
        WHEN t.on_time_pct < 73
             THEN 'NEEDS ATTENTION — Below 73% on-time'
        ELSE 'ACCEPTABLE — Continue monitoring'
    END                                                          AS region_status
FROM kpi_delay d
JOIN kpi_ontime t  ON d.region = t.region
JOIN kpi_traffic k ON d.region = k.region
ORDER BY t.on_time_pct DESC;

-- Result Set
-- region	|avg_delay_days	|on_time_pct|avg_traffic_delay_min	|region_status
-- Hyderabad|0.38			|76.1		|39.2					|ACCEPTABLE — Continue monitoring
-- Ahmedabad|0.61			|69.7		|56.5					|NEEDS ATTENTION — Below 73% on-time
-- Pune		|0.56			|69.4		|72.5					|NEEDS ATTENTION — Below 73% on-time
-- Lucknow	|0.54			|69.2		|67.0					|NEEDS ATTENTION — Below 73% on-time
-- Mumbai	|0.47			|68.6		|51.3					|NEEDS ATTENTION — Below 73% on-time
-- Bengaluru|0.50			|66.7		|15.0					|CRITICAL — Urgent intervention needed
