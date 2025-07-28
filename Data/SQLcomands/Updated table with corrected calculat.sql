-- AUTOMATED TABLE UPDATE SYSTEM
-- Created: July 28, 2025
-- ===================================================================

/*
SYSTEM OVERVIEW:
This automated system connects 3 tables using SQL Server triggers to ensure 
data consistency and automatic calculations when new data is inserted or updated.

TABLE FLOW:
[InputApidata] → [InputApidata_Extended] → [HotelsSorted]

TRIGGER CHAIN:
1. When data is INSERT/UPDATE in [InputApidata]
   → Automatically calculates L2B and % availability
   → Updates [InputApidata_Extended]

2. When [InputApidata_Extended] is modified
   → Automatically recalculates all rankings
   → Updates [HotelsSorted] with new rankings

CALCULATIONS:
- L2B = Search / Quantity_Reservations (rounded)
- % of availability = (Result / Search) * 100 (rounded)
- Overall Ranking = Weighted score combining all metrics
*/

-- ===================================================================
-- TRIGGER 1: Auto-update InputApidata_Extended when InputApidata changes
-- ===================================================================

CREATE OR ALTER TRIGGER trg_InputApidata_Update
ON [dbo].[InputApidata]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Delete existing records for updated/inserted Hotel_IDs
    DELETE FROM [dbo].[InputApidata_Extended] 
    WHERE Hotel_ID IN (SELECT Hotel_ID FROM inserted);
    
    -- Insert updated records with calculations
    INSERT INTO [dbo].[InputApidata_Extended] (
        Hotel_ID, Quantity_Reservations, Total_Cost, City, Country, 
        Search, Result, L2B, [Percent_of_availability]
    )
    SELECT 
        i.Hotel_ID, i.Quantity_Reservations, i.Total_Cost, i.City, i.Country,
        i.Search, i.Result,
        CASE 
            WHEN i.Quantity_Reservations > 0 THEN ROUND(CAST(i.Search AS FLOAT) / CAST(i.Quantity_Reservations AS FLOAT), 0)
            ELSE NULL 
        END AS L2B,
        CASE 
            WHEN i.Search > 0 THEN ROUND((CAST(i.Result AS FLOAT) / CAST(i.Search AS FLOAT)) * 100, 0)
            ELSE NULL 
        END AS [Percent_of_availability]
    FROM inserted i;
END;

-- ===================================================================
-- TRIGGER 2: Auto-update HotelsSorted when InputApidata_Extended changes
-- ===================================================================

CREATE OR ALTER TRIGGER trg_InputApidata_Extended_Update
ON [dbo].[InputApidata_Extended]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Clear and rebuild the entire HotelsSorted table
    DELETE FROM [dbo].[HotelsSorted];
    
    -- Rebuild with updated rankings
    WITH RankedHotels AS (
        SELECT 
            Hotel_ID, Quantity_Reservations, Total_Cost, City, Country,
            Search, Result, L2B, Percent_of_availability,
            ROW_NUMBER() OVER (ORDER BY Quantity_Reservations DESC) as Bookings_Rank,
            ROW_NUMBER() OVER (ORDER BY Percent_of_availability DESC) as Availability_Rank,
            ROW_NUMBER() OVER (ORDER BY L2B ASC) as L2B_Rank,
            ROW_NUMBER() OVER (ORDER BY Total_Cost DESC) as Cost_Rank
        FROM [dbo].[InputApidata_Extended]
        WHERE Quantity_Reservations > 0 AND Percent_of_availability IS NOT NULL AND L2B IS NOT NULL
    ),
    ScoredHotels AS (
        SELECT *,
            (Bookings_Rank * 0.4 + Availability_Rank * 0.3 + L2B_Rank * 0.2 + Cost_Rank * 0.1) as Overall_Score
        FROM RankedHotels
    )
    INSERT INTO [dbo].[HotelsSorted]
    SELECT 
        Hotel_ID, Quantity_Reservations, Total_Cost, City, Country,
        Search, Result, L2B, Percent_of_availability,
        ROW_NUMBER() OVER (ORDER BY Overall_Score ASC) as Overall_Rank,
        Bookings_Rank, Availability_Rank, L2B_Rank, Cost_Rank
    FROM ScoredHotels;
END;

-- ===================================================================
-- USAGE EXAMPLES:
-- ===================================================================

-- Example 1: Insert new hotel data (will automatically update all tables)
/*
INSERT INTO [dbo].[InputApidata] 
(Hotel_ID, Quantity_Reservations, Total_Cost, City, Country, Search, Result)
VALUES 
(12345678, 25, 15000.50, 'Paris', 'France', 2500, 1800);
*/

-- Example 2: Update existing hotel data (will automatically recalculate rankings)
/*
UPDATE [dbo].[InputApidata] 
SET Quantity_Reservations = 30, Total_Cost = 18000.00 
WHERE Hotel_ID = 12345678;
*/

-- Example 3: Check the automatically updated rankings
/*
SELECT TOP 10 Overall_Rank, Hotel_ID, City, Country, L2B, Percent_of_availability
FROM [dbo].[HotelsSorted]
ORDER BY Overall_Rank;
*/

-- ===================================================================
-- SYSTEM STATUS CHECK:
-- ===================================================================

-- Check if triggers exist
SELECT 
    name as TriggerName,
    OBJECT_NAME(parent_id) as TableName,
    is_disabled as IsDisabled
FROM sys.triggers 
WHERE name IN ('trg_InputApidata_Update', 'trg_InputApidata_Extended_Update');

-- Check table record counts
SELECT 
    'InputApidata' as TableName, COUNT(*) as RecordCount FROM [dbo].[InputApidata]
UNION ALL
SELECT 
    'InputApidata_Extended' as TableName, COUNT(*) as RecordCount FROM [dbo].[InputApidata_Extended]
UNION ALL
SELECT 
    'HotelsSorted' as TableName, COUNT(*) as RecordCount FROM [dbo].[HotelsSorted];
