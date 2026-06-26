-- ===================================================================
-- flipkart_logistics_route_optimization Project  - DATABASE SCHEMA
-- ===================================================================
 
CREATE DATABASE IF NOT EXISTS flipkart_logistics_route_optimization;
USE flipkart_logistics_route_optimization;

-- ------------------------------------------------------------
-- Table: Warehouses
-- ------------------------------------------------------------
CREATE TABLE Warehouses (
    Warehouse_ID        VARCHAR(10) PRIMARY KEY,
    Warehouse_Name      VARCHAR(100) NOT NULL,
    City            VARCHAR(50) NOT NULL,
    Processing_Capacity  INT,
    Average_Processing_Time_Min INT
);

Select * from Warehouses;
-- ------------------------------------------------------------
-- Table: Routes
-- ------------------------------------------------------------
CREATE TABLE Routes (
    Route_ID VARCHAR(10) PRIMARY KEY,
    Start_Location VARCHAR(50),
    End_Location VARCHAR(50),
    Distance_KM INT,
    Average_Travel_Time_Min INT,
    Traffic_Delay_Min INT
);
SELECT * from Routes;
-- ------------------------------------------------------------
-- Table: DeliveryAgents
-- ------------------------------------------------------------
CREATE TABLE Agents (
    Agent_ID VARCHAR(10) PRIMARY KEY,
    Agent_Name VARCHAR(100),
    Route_ID VARCHAR(10),
    Avg_Speed_KMPH DECIMAL(6, 2),
    On_Time_Delivery_Percentage DECIMAL(5, 2),
    Experience_Years DECIMAL(4, 2),
    FOREIGN KEY (Route_ID) REFERENCES Routes(Route_ID)
);
select * from Agents;
-- ------------------------------------------------------------
-- Table: Orders
-- ------------------------------------------------------------
CREATE TABLE Orders (
    Order_ID VARCHAR(20) PRIMARY KEY,
    Warehouse_ID VARCHAR(10),
    Route_ID VARCHAR(10),
    Agent_ID VARCHAR(10),
    Order_Date DATE,
    Expected_Delivery_Date DATE,
    Actual_Delivery_Date DATE,
    Status VARCHAR(20),
    Order_Value DECIMAL(10, 2),
    FOREIGN KEY (Warehouse_ID) REFERENCES Warehouses(Warehouse_ID),
    FOREIGN KEY (Route_ID) REFERENCES Routes(Route_ID)
);
select * from Orders;

-- ------------------------------------------------------------
-- Table: ShipmentTracking
-- ------------------------------------------------------------
CREATE TABLE Tracking (
    Tracking_ID VARCHAR(10) PRIMARY KEY,
    Order_ID VARCHAR(20),
    Checkpoint VARCHAR(50),
    Checkpoint_Time DATETIME,
    Delay_Reason VARCHAR(50),
    Delay_Minutes INT,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);
SELECT * from Tracking;