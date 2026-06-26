-- ============================================================
-- TASK 5: DELIVERY AGENT PERFORMANCE 
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: Rank agents (per route) by on-time delivery percentage
-- ------------------------------------------------------------

SELECT
    da.Agent_ID,
    da.Agent_Name,
    da.Route_ID,
    CONCAT(r.Start_Location, ' → ', r.End_Location)              AS Route,
    da.Avg_Speed_KMPH,
    da.On_Time_Delivery_Percentage,
    da.Experience_Years,
    RANK() OVER (
        PARTITION BY da.Route_ID
        ORDER BY da.On_Time_Delivery_Percentage DESC
    )                                                            AS Rank_in_Route
FROM agents da
JOIN Routes r ON da.Route_ID = r.Route_ID
ORDER BY da.Route_ID, rank_in_route;

-- TOP PERFORMERS (On-Time % by route):
-- Agent_ID| Agent_Name |Route_ID|Route              |Avg_Speed_KMPH|On_Time_Delivery_Percentage|Experience_Years|Rank_in_Route
-- AG_049  |Kiran Reddy |RT_01   |Lucknow → Bengaluru|37.30         |97.20                      |2.60            |1
-- AG_047  |Pooja Patel |RT_01   |Lucknow → Bengaluru|48.20         |81.20                      |3.50            |2
-- AG_002  |Vikram Nair |RT_01   |Lucknow → Bengaluru|48.60         |73.20                      |9.00            |3
-- AG_038  |Arun Reddy  |RT_02   |Ahmedabad → Mumbai |35.10         |91.60                      |6.70            |1
-- AG_007  |Vikram Patel|RT_02   |Ahmedabad → Mumbai |39.80         |85.90                      |1.70            |2

-- ------------------------------------------------------------
-- STEP 2: Find agents with on-time delivery % < 80%
-- ------------------------------------------------------------

SELECT
    da.Agent_ID,
    da.Agent_Name,
    da.Route_ID,
    CONCAT(r.Start_Location, ' → ', r.End_Location)              AS Assigned_Route,
    da.Avg_Speed_KMPH,
    da.On_Time_Delivery_Percentage,
    da.Experience_Years,
    'NEEDS IMPROVEMENT'                                           AS Performance_Flag
FROM agents da
JOIN Routes r ON da.Route_ID = r.Route_ID
WHERE da.On_Time_Delivery_Percentage < 80
ORDER BY da.On_Time_Delivery_Percentage ASC;

-- RESULT (13 agents with on-time % < 80%):
-- AG_006 Kiran Kumar    RT_20  70.5% ← lowest
-- AG_019 Vikram Sharma  RT_08  72.1%
-- AG_026 Kiran Patel    RT_02  72.2%
-- AG_004 Vikram Nair    RT_06  73.0%
-- AG_035 Anita Patel    RT_09  73.0%
-- AG_002 Vikram Nair    RT_01  73.2%
-- AG_014 Pooja Reddy    RT_16  73.7%
-- AG_008 Meena Kumar    RT_18  73.6%
-- AG_012 Rajesh Nair    RT_18  76.2%
-- AG_011 Sneha Sharma   RT_17  76.9%
-- AG_036 Vikram Reddy   RT_20  79.6%
-- AG_050 Vikram Kumar   RT_04  79.7%
-- AG_032 Pooja Nair     RT_09  79.8%

-- ----------------------------------------------------------------------------
-- STEP 3: Compare average speed of top 5 vs bottom 5 agents using subqueries
-- ----------------------------------------------------------------------------

-- Top 5 agents by speed
SELECT
    'TOP 5 (Fastest)'                                             AS group_label,
    ROUND(AVG(Avg_Speed_KMPH), 2)                                 AS avg_speed_kmph,
    MIN(Avg_Speed_KMPH)                                           AS min_speed,
    MAX(Avg_Speed_KMPH)                                           AS max_speed,
    ROUND(AVG(On_Time_Delivery_Percentage), 1)                    AS avg_on_time_pct
FROM (
    SELECT Agent_ID, Agent_Name, Avg_Speed_KMPH, On_Time_Delivery_Percentage
    FROM agents
    ORDER BY Avg_Speed_KMPH DESC
    LIMIT 5
) top5

UNION ALL

-- Bottom 5 agents by speed
SELECT
    'BOTTOM 5 (Slowest)'                                          AS Group_Label,
    ROUND(AVG(Avg_Speed_KMPH), 2)                                 AS Avg_Speed,
    MIN(Avg_Speed_KMPH)                                           AS Min,
    MAX(Avg_Speed_KMPH)                                           AS Max,
    ROUND(AVG(On_Time_Delivery_Percentage), 1)                    AS Avg_ON_Time_pct
FROM (
    SELECT Agent_ID, Agent_Name, Avg_Speed_KMPH, On_Time_Delivery_Percentage
    FROM agents
    ORDER BY Avg_Speed_KMPH ASC
    LIMIT 5
) bot5;

-- RESULT:
-- Group_Label              | Avg_Speed | Min  | Max  | Avg_ON_Time_pct
-- TOP 5 (Fastest)    		| 53.02     | 50.3 | 55.0 | 82.0%
-- BOTTOM 5 (Slowest) 		| 35.32     | 35.0 | 35.8 | 87.2%

-- ------------------------------------------------------------
-- STEP 4: Training & workload balancing recommendations
-- ------------------------------------------------------------

SELECT
    da.Agent_ID,
    da.Agent_Name,
    da.Avg_Speed_KMPH,
    da.On_Time_Delivery_Percentage,
    da.Experience_Years,
    CASE
        WHEN da.On_Time_Delivery_Percentage < 75
             THEN 'URGENT TRAINING: On-time delivery critical — mandatory retraining + route reassignment'
        WHEN da.On_Time_Delivery_Percentage < 80
             THEN 'TRAINING NEEDED: Below 80% on-time — coaching sessions + workload review'
        WHEN da.Avg_Speed_KMPH < 38 AND da.On_Time_Delivery_Percentage >= 80
             THEN 'WORKLOAD BALANCE: Low speed but acceptable on-time — avoid long-distance routes'
        WHEN da.On_Time_Delivery_Percentage >= 90
             THEN 'HIGH PERFORMER: Consider for mentorship, complex routes, or senior roles'
        ELSE 'STABLE: Performing adequately — continue monitoring'
    END AS recommendation
FROM agents da
ORDER BY da.On_Time_Delivery_Percentage ASC;
-- Result (50 rows):
-- Showing Only bottom 3 as per ON TIME Delivery Percentage
-- Agent_ID|Agent_Name   |Avg_Speed_KMPH|On_Time_Delivery_Percentage|Experience_Years|recommendation
-- AG_006  |Kiran Kumar  |41.50         |70.50						|9.40			 |URGENT TRAINING: On-time delivery critical — mandatory retraining + route reassignment
-- AG_019  |Vikram Sharma|52.50         |72.10						|8.30			 |URGENT TRAINING: On-time delivery critical — mandatory retraining + route reassignment
-- AG_026  |Kiran Patel  |54.20			|72.20						|2.70			 |URGENT TRAINING: On-time delivery critical — mandatory retraining + route reassignment
