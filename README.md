# 🚚 Delivery Analytics SQL Project - Flipkart

A comprehensive SQL-based data analytics project analyzing delivery operations, route optimization, warehouse performance, and agent efficiency for a logistics company.

---

## 📁 Project Structure

```
flipkart-logisitics-route-optimization-sql/
├── README.md
├── sql/
│   ├── schema.sql
|   ├── loaddata.sql
|   ├── task1_data_cleaning.sql
│   ├── task2_delivery_delay_analysis.sql
│   ├── task3_route_optimization.sql
│   ├── task4_warehouse_performance.sql
│   ├── task5_agent_performance.sql
│   ├── task6_shipment_tracking.sql
│   └── task7_kpi_reporting.sql
├── data/
│   └── files(Orders,Routes,ShipmentTracking,Warehouses,DeliveryAgent).csv
└── presentation/
    └── Flipkart_Logistics_Optimization_Presentation.pptx
```

---

## 🗃️ Database Schema

The project uses the following key tables:

| Table | Description |
|-------|-------------|
| `Orders` | Order details with dates, locations, status |
| `Routes` | Route info — distance, travel time, traffic delay |
| `Warehouses` | Warehouse processing times and locations |
| `Agents` | Agent details and assigned routes |
| `Tracking` | Checkpoint data for each shipment |

---

## 📋 Tasks Overview

| Task | Topic |
|------|-------|
| Task 1 | Data Cleaning & Preparation | 
| Task 2 | Delivery Delay Analysis | 
| Task 3 | Route Optimization Insights | 
| Task 4 | Warehouse Performance |
| Task 5 | Delivery Agent Performance |
| Task 6 | Shipment Tracking Analytics |
| Task 7 | Advanced KPI Reporting | 

---

## 🛠️ Tools Used

- **Database**: MySQL
- **SQL Features Used**: CTEs, Window Functions, Subqueries, Aggregate Functions, Date Functions
- **Presentation**: Microsoft PowerPoint

---

## 🚀 How to Run

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/delivery-analytics-sql.git
   cd delivery-analytics-sql
   ```

2. Set up the database schema:
   ```bash
   mysql -u root -p < data/schema.sql
   ```

3. Run tasks in order:
   ```bash
   mysql -u root -p your_database < sql/task1_data_cleaning.sql
   # Repeat for tasks 2–7
   ```

---

## 📊 Key Findings

- Identified top 10 delayed routes using aggregated delay analysis
- Used window functions to rank orders within each warehouse
- Found 3 worst-efficiency routes using Distance/Time ratio
- Ranked agents by on-time delivery % and highlighted underperformers
- Computed KPIs: Avg Delivery Delay by Region, On-Time %, Avg Traffic Delay per Route

---

## 👤 Author

**Mrudula Jujjuru**  
Data Analytics Project - Flipkart_logistics_route_optimization
