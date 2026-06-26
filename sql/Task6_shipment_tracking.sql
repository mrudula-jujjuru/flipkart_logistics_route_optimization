-- ============================================================
-- TASK 6: SHIPMENT TRACKING ANALYTICS
-- ============================================================

USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- STEP 1: For each order, list the LAST checkpoint and time
-- ------------------------------------------------------------
SELECT
    ranked.Order_ID,
    ranked.Checkpoint          AS last_checkpoint,
    ranked.Checkpoint_Time     AS last_checkpoint_time,
    ranked.Delay_Reason        AS last_delay_reason,
    ranked.Delay_Minutes
FROM (
    SELECT
        st.Order_ID,
        st.Checkpoint,
        st.Checkpoint_Time,
        st.Delay_Reason,
        st.Delay_Minutes,
        ROW_NUMBER() OVER (
            PARTITION BY st.Order_ID
            ORDER BY st.Checkpoint_Time DESC
        ) AS rn
    FROM tracking st
) ranked
WHERE rn = 1
ORDER BY ranked.Order_ID;

-- SAMPLE RESULT (first 5):
-- Order_ID	   |last_checkpoint|last_checkpoint_time|last_delay_reason|Delay_Minutes
-- FLP-ORD-0002|Hub_4_Bengaluru|2025-08-24 10:27:00 |None 			  |0
-- FLP-ORD-0003|Hub_1_Mumbai   |2025-08-28 16:54:00 |None			  |0
-- FLP-ORD-0004|Hub_5_Jaipur   |2025-08-24 23:15:00 |None			  |0
-- FLP-ORD-0005|Hub_3_Pune     |2025-08-22 11:50:00 |None			  |0
-- FLP-ORD-0006|Hub_2_Lucknow  |2025-08-13 05:48:00 |Weather		  |67


-- ------------------------------------------------------------
-- STEP 2: Most common delay reasons (excluding None)
-- ------------------------------------------------------------

SELECT
    Delay_Reason,
    COUNT(*)                                                     AS occurrence_count,
    ROUND(AVG(Delay_Minutes), 1)                                 AS avg_delay_minutes,
    MAX(Delay_Minutes)                                           AS max_delay_minutes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)          AS pct_of_all_delays
FROM tracking
WHERE Delay_Reason != 'None'
  AND Delay_Reason IS NOT NULL
GROUP BY Delay_Reason
ORDER BY occurrence_count DESC;

-- RESULT:
-- Delay_Reason   | occurrence_count| avg_delay_minutes | max_delay_minutes | pct_of_all_delays
-- Traffic        |  387  			|    68.7       	| 120 				| 56.4%
-- Weather        |  192  			|    63.7       	| 120 				| 28.0%
-- Technical Issue|  107  			|    64.1      		| 120 				| 15.6%

-- ------------------------------------------------------------
-- STEP 3: Identify orders with more than 2 delayed checkpoints
-- ------------------------------------------------------------

SELECT
    st.Order_ID,
    COUNT(CASE WHEN st.Delay_Reason != 'None'
                AND st.Delay_Minutes > 0
               THEN 1 END) AS delayed_checkpoint_count,
    ROUND(AVG(CASE WHEN st.Delay_Reason != 'None'
              THEN st.Delay_Minutes END), 1) AS avg_delay_min_per_checkpoint,
    SUM(st.Delay_Minutes) AS total_delay_minutes,
    GROUP_CONCAT(
        DISTINCT st.Delay_Reason
        ORDER BY st.Delay_Reason
        SEPARATOR ' | '
    ) AS delay_reasons_seen
FROM tracking st
WHERE st.Delay_Reason != 'None' AND st.Delay_Minutes > 0
GROUP BY st.Order_ID
HAVING delayed_checkpoint_count > 2
ORDER BY delayed_checkpoint_count DESC, total_delay_minutes DESC;

-- TOP RESULTS (most delayed orders):
-- Order_ID		  | delayed_checkpoint_count|avg_delay_min_per_checkpoint| total_delay_minutes| delay_reasons_seen       
-- FLP-ORD-0202   |      8      			|   59.6    				 |    477 min  		  | Technical Issue | Traffic | Weather
-- FLP-ORD-0128   |      7      			|   85.6    				 |    599 min  		  | Traffic | Weather
-- FLP-ORD-0114   |      7      			|   80.1     				 |    561 min  		  | Technical Issue | Traffic | Weather
-- FLP-ORD-0061   |      7      			|   65.4    				 |    458 min  		  | Technical Issue | Traffic | Weather
-- FLP-ORD-0229   |      7      			|   59.0    				 |    413 min  		  | Technical Issue | Traffic | Weather

-- Total orders with >2 delayed checkpoints:
SELECT COUNT(DISTINCT Order_ID) AS orders_with_multiple_delays
FROM (
    SELECT Order_ID,
           COUNT(CASE WHEN Delay_Reason != 'None' AND Delay_Minutes > 0 THEN 1 END) AS cnt
    FROM tracking
    WHERE Delay_Reason != 'None' AND Delay_Minutes > 0
    GROUP BY Order_ID
    HAVING cnt > 2
) sub;

-- Result Set 
-- orders_with_multiple_delays
-- 119