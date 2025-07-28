-- HOTELS BY LOCATION - COUNTRY & CITY RANKINGS
-- ==============================================
-- Created: July 28, 2025
-- Contains all hotels ranked by country and city performance

-- UPDATED 5-TABLE DEPENDENCY CHAIN:
-- =================================
/*
📋 [InputApidata] 
    ↓ (TRIGGER: trg_InputApidata_Update)
📈 [InputApidata_Extended] 
    ↓ (TRIGGER: trg_InputApidata_Extended_Update)
🏆 [HotelsSorted]
    ↓ ┌─ (TRIGGER: trg_HotelsSorted_Update_TOP500)
      │ ⭐ [TOP500]
      └─ (TRIGGER: trg_HotelsSorted_Update_ByLocation)
        🌍 [HotelsByLocation]
*/

-- ==============================================
-- TOP SELLERS BY COUNTRY (Best Hotel per Country)
-- ==============================================
SELECT 
    Country,
    City,
    Hotel_ID,
    Overall_Rank,
    Country_Rank,
    Quantity_Reservations,
    CAST(Total_Cost as DECIMAL(10,2)) as Total_Cost,
    L2B,
    Percent_of_availability
FROM [dbo].[HotelsByLocation]
WHERE Country_Rank = 1  -- Only #1 hotel in each country
ORDER BY Overall_Rank;

-- ==============================================
-- TOP SELLERS BY CITY (Best 3 Hotels per City)
-- ==============================================
SELECT 
    City,
    Country,
    Hotel_ID,
    City_Rank,
    Overall_Rank,
    Quantity_Reservations,
    CAST(Total_Cost as DECIMAL(10,2)) as Total_Cost,
    L2B,
    Percent_of_availability
FROM [dbo].[HotelsByLocation]
WHERE City_Rank <= 3  -- Top 3 in each city
ORDER BY City, City_Rank;

-- ==============================================
-- COUNTRY PERFORMANCE ANALYSIS
-- ==============================================
SELECT 
    Country,
    COUNT(*) as Total_Hotels,
    AVG(CAST(Overall_Rank as FLOAT)) as Avg_Overall_Rank,
    MIN(Overall_Rank) as Best_Hotel_Rank,
    AVG(CAST(Quantity_Reservations as FLOAT)) as Avg_Reservations,
    SUM(Quantity_Reservations) as Total_Reservations,
    AVG(CAST(Total_Cost as FLOAT)) as Avg_Revenue,
    SUM(CAST(Total_Cost as FLOAT)) as Total_Revenue
FROM [dbo].[HotelsByLocation]
GROUP BY Country
ORDER BY Total_Revenue DESC;

-- ==============================================
-- CITY PERFORMANCE ANALYSIS  
-- ==============================================
SELECT 
    City,
    Country,
    COUNT(*) as Hotels_in_City,
    MIN(Overall_Rank) as Best_Hotel_Rank,
    AVG(CAST(Quantity_Reservations as FLOAT)) as Avg_Reservations,
    SUM(Quantity_Reservations) as Total_City_Reservations,
    AVG(CAST(Total_Cost as FLOAT)) as Avg_Revenue,
    SUM(CAST(Total_Cost as FLOAT)) as Total_City_Revenue
FROM [dbo].[HotelsByLocation]
GROUP BY City, Country
HAVING COUNT(*) >= 5  -- Only cities with 5+ hotels
ORDER BY Total_City_Revenue DESC;

-- ==============================================
-- LOCATION BASED RANKINGS - EXAMPLES
-- ==============================================

-- Best hotels in major tourist cities
SELECT 
    City,
    Country,
    Hotel_ID,
    City_Rank,
    Overall_Rank,
    Quantity_Reservations,
    CAST(Total_Cost as DECIMAL(10,2)) as Total_Cost
FROM [dbo].[HotelsByLocation]
WHERE City IN ('Dubai', 'London', 'New York, NY', 'Paris', 'Istanbul', 'Barcelona', 'Rome', 'Amsterdam')
  AND City_Rank <= 5
ORDER BY City, City_Rank;

-- Countries with most hotels in TOP 100 globally
SELECT 
    Country,
    COUNT(*) as Hotels_in_Top100
FROM [dbo].[HotelsByLocation]
WHERE Overall_Rank <= 100
GROUP BY Country
ORDER BY Hotels_in_Top100 DESC;

-- ==============================================
-- SYSTEM STATUS CHECK
-- ==============================================
SELECT 
    'HotelsByLocation' AS TableName, 
    COUNT(*) as RecordCount,
    'Location-based rankings' as Description
FROM [dbo].[HotelsByLocation]

UNION ALL

SELECT 
    'Unique Countries' AS TableName,
    COUNT(DISTINCT Country) as RecordCount,
    'Total countries represented' as Description
FROM [dbo].[HotelsByLocation]

UNION ALL

SELECT 
    'Unique Cities' AS TableName,
    COUNT(DISTINCT City + ', ' + Country) as RecordCount,
    'Total unique city-country combinations' as Description
FROM [dbo].[HotelsByLocation];
