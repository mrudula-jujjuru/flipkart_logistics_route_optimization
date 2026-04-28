-- ============================================================
-- TASK 3: ROUTE OPTIMIZATION INSIGHTS 
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: For each route calculate:
--   a) Average delivery time (in days)
--   b) Average traffic delay
--   c) Efficiency ratio: Distance_KM / Average_Travel_Time_Min
-- ------------------------------------------------------------

SELECT
    r.Route_ID,
    CONCAT(r.Start_Location, ' →', r.End_Location)             AS route,
    r.Distance_KM,
    r.Average_Travel_Time_Min,
    r.Traffic_Delay_Min                                         AS avg_traffic_delay_min,
    ROUND(AVG(DATEDIFF(o.Actual_Delivery_Date, o.Order_Date)), 2) AS avg_delivery_time_days,
    ROUND(r.Distance_KM / r.Average_Travel_Time_Min, 2)         AS efficiency_ratio
FROM Routes r
LEFT JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location
ORDER BY efficiency_ratio DESC;

-- RESULT (all 20 routes):
-- Route_ID	|route				|Distance_KM|Average_Travel_Time_Min|avg_traffic_delay_min|avg_delivery_time_days	|efficiency_ratio
-- RT_19	|Hyderabad →Lucknow	|1833		|245					|50					|4.07						|7.48
-- RT_12	|Hyderabad →Lucknow	|1924		|386					|58					|4.61						|4.98
-- RT_10	|Hyderabad →Lucknow	|1592		|322					|15					|4.42						|4.94
-- RT_15	|Hyderabad →Jaipur	|1587		|326					|87					|5.06						|4.87
-- RT_02	|Ahmedabad →Mumbai	|719		|193					|30					|5.12						|3.73
-- RT_07	|Mumbai →Lucknow	|1248		|435					|58					|4.33						|2.87
-- RT_05	|Pune →Pune			|928		|378					|55					|4.90						|2.46
-- RT_11	|Hyderabad →Lucknow	|1733		|772					|20					|4.00						|2.24
-- RT_20	|Hyderabad →Mumbai	|698		|315					|37					|4.80						|2.22
-- RT_09	|Ahmedabad →Mumbai	|1963		|920					|83					|4.31						|2.13
-- RT_04	|Hyderabad →Lucknow	|1713		|869					|23					|4.06						|1.97
-- RT_06	|Bengaluru →Bengaluru|1386		|721					|15					|4.42						|1.92
-- RT_18	|Hyderabad →Lucknow	|1552		|844					|17					|4.57						|1.84
-- RT_16	|Mumbai →Mumbai		|1243		|681					|30					|5.00						|1.83
-- RT_08	|Pune →Pune			|1280		|780					|90					|4.50						|1.64
-- RT_01	|Lucknow →Bengaluru	|1009		|631					|67					|4.23						|1.60
-- RT_17	|Mumbai →Lucknow	|927		|732					|81					|3.80						|1.27
-- RT_03	|Hyderabad →Mumbai	|846		|749					|29					|4.30						|1.13
-- RT_14	|Mumbai →Mumbai		|908		|907					|36					|4.88						|1.00
-- RT_13	|Hyderabad →Jaipur	|1078		|1481					|56					|4.73						|0.73


-- ------------------------------------------------------------
-- STEP 2: 3 routes with the WORST efficiency ratio
-- ------------------------------------------------------------
SELECT
    r.Route_ID,
    CONCAT(r.Start_Location, ' → ', r.End_Location)             AS route,
    COUNT(o.Order_ID)                                           AS total_orders_in_route,
    r.Distance_KM,
    r.Average_Travel_Time_Min,
    ROUND(r.Distance_KM / r.Average_Travel_Time_Min, 2)         AS efficiency_ratio,
    'WORST Efficiency - Need Attention'            AS recommendation
FROM Routes r
LEFT JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location
ORDER BY efficiency_ratio ASC
LIMIT 3;

-- RESULT:
-- Route_ID | Route                 |Total_orders_in_route 	| Distance_KM 	| Average_Travel_Times_ Min | efficiency_ratio 	| recommendation
-- RT_13    | Hyderabad → Jaipur    |  	11					| 1078   		|   1481     				|   0.7278   		|   WORST Efficiency - Need Attention
-- RT_14    | Mumbai → Mumbai       |   17 					| 908   		|    907     				|   1.0011   		|   WORST Efficiency - Need Attention
-- RT_03    | Hyderabad → Mumbai    |   20 					| 846   		|    749     				|   1.1295   		|   WORST Efficiency - Need Attention

-- ------------------------------------------------------------
-- STEP 3: Routes with >20% delayed shipments
-- ------------------------------------------------------------
SELECT
    r.Route_ID,
    CONCAT(r.Start_Location, ' → ', r.End_Location)             AS route,
    COUNT(o.Order_ID)                                           AS total_shipments,
    SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
             THEN 1 ELSE 0 END)                                 AS delayed_shipments,
    ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
                   THEN 1 ELSE 0 END) * 100.0 / COUNT(o.Order_ID), 1) AS delay_pct
FROM Routes r
JOIN Orders o ON r.Route_ID = o.Route_ID
GROUP BY r.Route_ID, r.Start_Location, r.End_Location
HAVING delay_pct > 20
ORDER BY delay_pct DESC;

-- RESULT (routes with >20% delay):
-- Route_ID	|route					|total_shipments|delayed_shipments	|delay_pct
-- RT_13	|Hyderabad → Jaipur		|11				|6					|54.5
-- RT_05	|Pune → Pune			|20				|8					|40.0
-- RT_14	|Mumbai → Mumbai		|17				|6					|35.3
-- RT_06	|Bengaluru → Bengaluru	|12				|4					|33.3
-- RT_17	|Mumbai → Lucknow		|15				|5					|33.3
-- RT_09	|Ahmedabad → Mumbai		|16				|5					|31.3
-- RT_01	|Lucknow → Bengaluru	|13				|4					|30.8
-- RT_16	|Mumbai → Mumbai		|10				|3					|30.0
-- RT_02	|Ahmedabad → Mumbai		|17				|5					|29.4
-- RT_18	|Hyderabad → Lucknow	|14				|4					|28.6
-- RT_12	|Hyderabad → Lucknow	|18				|5					|27.8
-- RT_15	|Hyderabad → Jaipur		|17				|4					|23.5
-- RT_07	|Mumbai → Lucknow		|9				|2					|22.2
-- RT_10	|Hyderabad → Lucknow	|19				|4					|21.1


-- ------------------------------------------------------------
-- STEP 4: Recommend routes for optimization (CTE-based)
-- ------------------------------------------------------------
WITH route_metrics AS (
    SELECT
        r.Route_ID,
        r.Start_Location,
        r.End_Location,
        r.Distance_KM,
        r.Average_Travel_Time_Min,
        r.Traffic_Delay_Min,
        ROUND(r.Distance_KM / r.Average_Travel_Time_Min, 2)       AS efficiency_ratio,
        COUNT(o.Order_ID)                                         AS total_orders,
        SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
                 THEN 1 ELSE 0 END)                               AS delayed_orders,
        ROUND(SUM(CASE WHEN DATEDIFF(o.Actual_Delivery_Date, o.Expected_Delivery_Date) > 0
                       THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(o.Order_ID), 0), 1) AS delay_pct
    FROM Routes r
    LEFT JOIN Orders o ON r.Route_ID = o.Route_ID
    GROUP BY r.Route_ID, r.Start_Location, r.End_Location
    ),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY efficiency_ratio ASC) AS eff_rank
    FROM route_metrics
)
SELECT
    Route_ID,
    CONCAT(Start_Location, ' → ', End_Location)  AS route,
    efficiency_ratio,
    delay_pct,
    Traffic_Delay_Min,
    CASE
        WHEN eff_rank <= 3 AND delay_pct > 20
            THEN '🔴 HIGH PRIORITY: Poor efficiency + high delay rate — reroute or allocate more resources'
        WHEN eff_rank <= 3
            THEN '🟠 MEDIUM: Poor efficiency — review travel time, consider alternate roads'
        WHEN delay_pct > 40
            THEN '🔴 HIGH PRIORITY: Very high delay rate — investigate agents and traffic windows'
        WHEN delay_pct > 20
            THEN '🟡 MONITOR: Above 20% delay — assign experienced agents, add checkpoints'
        ELSE '🟢 ACCEPTABLE: Performing within limits'
    END AS recommendation
FROM ranked
WHERE eff_rank <= 3 OR delay_pct > 20
ORDER BY eff_rank, delay_pct DESC;
-- RESULT : (15 rows)
-- Route_ID	|route				|efficiency_ratio	|delay_pct	|Traffic_Delay_Min	|recommendation
-- RT_13	|Hyderabad → Jaipur	|0.73				|54.5		|56					|🔴 HIGH PRIORITY: Poor efficiency + high delay rate — reroute or allocate more resources
-- RT_14	|Mumbai → Mumbai	|1.00				|35.3		|36					|🔴 HIGH PRIORITY: Poor efficiency + high delay rate — reroute or allocate more resources
-- RT_03	|Hyderabad → Mumbai	|1.13				|15.0		|29					|🟠 MEDIUM: Poor efficiency — review travel time| consider alternate roads
-- RT_17	|Mumbai → Lucknow	|1.27				|33.3		|81					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_01	|Lucknow → Bengaluru|1.60				|30.8		|67					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_16	|Mumbai → Mumbai	|1.83				|30.0		|30					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_18	|Hyderabad → Lucknow|1.84				|28.6		|17					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_06	|Bengaluru → Bengaluru|1.92 			|33.3		|15					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_09	|Ahmedabad → Mumbai	|2.13				|31.3		|83					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_05	|Pune → Pune		|2.46				|40.0		|55					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_07	|Mumbai → Lucknow	|2.87				|22.2		|58					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_02	|Ahmedabad → Mumbai	|3.73				|29.4		|30					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_15	|Hyderabad → Jaipur	|4.87				|23.5		|87					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_10	|Hyderabad → Lucknow|4.94				|21.1		|15					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
-- RT_12	|Hyderabad → Lucknow|4.98				|27.8		|58					|🟡 MONITOR: Above 20% delay — assign experienced agents| add checkpoints
