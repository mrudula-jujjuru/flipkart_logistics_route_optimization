


USE flipkart_logistics_route_optimization;
-- Enable local file loading
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
-- Should show: ON


-- Load warehouse data on success loads 10 rows
LOAD DATA LOCAL INFILE 'C:/your_path/Warehouses.csv'
INTO TABLE Warehouses
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Warehouse_ID, Warehouse_Name, City, Processing_Capacity, Average_Processing_Time_Min);

-- Load Routes data on success loads 20 rows
LOAD DATA LOCAL INFILE 'C:/your_path/Routes.csv'
INTO TABLE Routes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Route_ID, Start_Location, End_Location, Distance_KM, Average_Travel_Time_Min, Traffic_Delay_Min);

-- Load DeliveryAgents data on success loads 50 rows
LOAD DATA LOCAL INFILE 'C:/your_path/DeliveryAgents.csv'
INTO TABLE Agents
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Agent_ID, Agent_Name, Route_ID, Avg_Speed_KMPH, On_Time_Delivery_Percentage, Experience_Years);

-- Load Orders Data on success loads 300 rows
LOAD DATA LOCAL INFILE 'C:/your_path/Orders.csv'
INTO TABLE Orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Order_ID, Warehouse_ID, Route_ID, Agent_ID, Order_Date, Expected_Delivery_Date, Actual_Delivery_Date, Status, Order_Value);

-- Loads Shipement tracking data on success loads 1000 rows
LOAD DATA LOCAL INFILE 'C:/your_path/ShipmentTracking.csv'
INTO TABLE Tracking
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Tracking_ID, Order_ID, Checkpoint, Checkpoint_Time, Delay_Reason, Delay_Minutes);
