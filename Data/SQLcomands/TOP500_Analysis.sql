-- TOP500 TABLE - ELITE HOTEL RANKINGS
-- =====================================
-- Created: July 28, 2025
-- Contains the top 500 best-performing hotels from HotelsSorted

-- View the TOP 500 hotels
SELECT TOP 20
    Overall_Rank,
    Hotel_ID,
    City,
    Country,
    Quantity_Reservations,
    CAST(Total_Cost as DECIMAL(10,2)) as Total_Cost,
    L2B,
    Percent_of_availability,
    Bookings_Rank,
    Availability_Rank,
    L2B_Rank,
    Cost_Rank
FROM [dbo].[TOP500]
ORDER BY Overall_Rank;

-- UPDATED DEPENDENCY CHAIN (4 Tables):
-- =====================================
/*
📋 [InputApidata] 
    ↓ (TRIGGER: trg_InputApidata_Update)
📈 [InputApidata_Extended] 
    ↓ (TRIGGER: trg_InputApidata_Extended_Update)
🏆 [HotelsSorted]
    ↓ (TRIGGER: trg_HotelsSorted_Update_TOP500)
⭐ [TOP500]
*/

-- Table Statistics
SELECT 
    'InputApidata' as TableName, COUNT(*) as RecordCount, 'Source table' as Description
FROM [dbo].[InputApidata]
UNION ALL
SELECT 
    'InputApidata_Extended' as TableName, COUNT(*) as RecordCount, 'With calculations' as Description
FROM [dbo].[InputApidata_Extended]
UNION ALL
SELECT 
    'HotelsSorted' as TableName, COUNT(*) as RecordCount, 'All hotels ranked' as Description
FROM [dbo].[HotelsSorted]
UNION ALL
SELECT 
    'TOP500' as TableName, COUNT(*) as RecordCount, 'Best 500 hotels only' as Description
FROM [dbo].[TOP500];

-- View triggers for all tables
SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS SourceTable,
    CASE 
        WHEN t.name = 'trg_InputApidata_Update' THEN 'Updates → InputApidata_Extended'
        WHEN t.name = 'trg_InputApidata_Extended_Update' THEN 'Updates → HotelsSorted'
        WHEN t.name = 'trg_HotelsSorted_Update_TOP500' THEN 'Updates → TOP500'
        ELSE 'Unknown'
    END AS Dependency,
    CASE t.is_disabled WHEN 0 THEN 'Active' ELSE 'Disabled' END AS Status
FROM sys.triggers t
WHERE t.name LIKE 'trg_%'
ORDER BY t.name;

-- Performance Analysis of TOP500
-- ===============================

-- Top 10 countries in TOP500
SELECT TOP 10
    Country,
    COUNT(*) as Hotel_Count,
    AVG(CAST(Quantity_Reservations as FLOAT)) as Avg_Reservations,
    AVG(CAST(Total_Cost as FLOAT)) as Avg_Total_Cost,
    AVG(CAST(Percent_of_availability as FLOAT)) as Avg_Availability
FROM [dbo].[TOP500]
GROUP BY Country
ORDER BY Hotel_Count DESC;

-- Top 10 cities in TOP500
SELECT TOP 10
    City,
    Country,
    COUNT(*) as Hotel_Count,
    MIN(Overall_Rank) as Best_Rank_in_City
FROM [dbo].[TOP500]
GROUP BY City, Country
ORDER BY Hotel_Count DESC;
