-- HOW TO VIEW TABLE DEPENDENCIES AND TRIGGERS
-- =============================================

/*
WHERE TO FIND DEPENDENCIES IN SQL SERVER:

1. IN SQL SERVER MANAGEMENT STUDIO (SSMS):
   a) Connect to your database server: upgradeserverdb-akb.database.windows.net
   b) Navigate to: Databases → AutTemplate → Tables
   c) Right-click on any table → "View Dependencies"
   d) You'll see incoming and outgoing dependencies

2. TO VIEW TRIGGERS IN SSMS:
   a) Navigate to: Databases → AutTemplate → Tables
   b) Expand any table (e.g., InputApidata)
   c) Expand "Triggers" folder
   d) You'll see: trg_InputApidata_Update
   e) Right-click trigger → "Script Trigger as" → "CREATE To" to see code

3. ALTERNATIVE SSMS METHOD:
   a) Navigate to: Databases → AutTemplate → Programmability → Database Triggers
   b) You'll see all database triggers listed

4. USING SQL QUERIES (run these in SSMS or VS Code):
*/

-- View all triggers and their target tables
SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS SourceTable,
    'Automatically updates when data changes' AS Purpose,
    CASE t.is_disabled WHEN 0 THEN 'Active' ELSE 'Disabled' END AS Status
FROM sys.triggers t
WHERE t.name LIKE 'trg_%'
ORDER BY t.name;

-- View dependency chain
SELECT 
    '1. InputApidata' AS Step,
    'Source table - insert/update data here' AS Description,
    'Manual input' AS UpdateMethod
UNION ALL
SELECT 
    '2. InputApidata_Extended' AS Step,
    'Calculated table - L2B and % availability' AS Description,
    'Auto-updated by trg_InputApidata_Update' AS UpdateMethod
UNION ALL
SELECT 
    '3. HotelsSorted' AS Step,
    'Ranked table - sorted by performance' AS Description,
    'Auto-updated by trg_InputApidata_Extended_Update' AS UpdateMethod;

-- Check if triggers are working (test with this query after making changes)
SELECT 
    'Test Status' AS CheckType,
    CASE 
        WHEN (SELECT COUNT(*) FROM [dbo].[InputApidata]) = 
             (SELECT COUNT(*) FROM [dbo].[InputApidata_Extended]) 
        THEN 'Tables synchronized ✓'
        ELSE 'Tables NOT synchronized ✗'
    END AS Result;

-- If tables are NOT synchronized, use this query to find the issue:
-- SELECT 'Missing in InputApidata' as Issue, Hotel_ID, City, Country
-- FROM [dbo].[InputApidata_Extended] e
-- WHERE NOT EXISTS (SELECT 1 FROM [dbo].[InputApidata] i WHERE i.Hotel_ID = e.Hotel_ID)
-- UNION ALL
-- SELECT 'Missing in InputApidata_Extended' as Issue, Hotel_ID, City, Country  
-- FROM [dbo].[InputApidata] i
-- WHERE NOT EXISTS (SELECT 1 FROM [dbo].[InputApidata_Extended] e WHERE e.Hotel_ID = i.Hotel_ID);

/*
5. IN AZURE DATA STUDIO:
   a) Connect to your database
   b) Expand database → Tables
   c) Right-click table → "Generate Script" to see dependencies

6. DEPENDENCY VISUALIZATION:
   
   [InputApidata] 
        ↓ (trg_InputApidata_Update)
   [InputApidata_Extended]
        ↓ (trg_InputApidata_Extended_Update)  
   [HotelsSorted]

7. TO DISABLE/ENABLE TRIGGERS:
*/

-- Disable triggers (if needed for bulk operations)
-- DISABLE TRIGGER trg_InputApidata_Update ON [dbo].[InputApidata];
-- DISABLE TRIGGER trg_InputApidata_Extended_Update ON [dbo].[InputApidata_Extended];

-- Enable triggers
-- ENABLE TRIGGER trg_InputApidata_Update ON [dbo].[InputApidata];
-- ENABLE TRIGGER trg_InputApidata_Extended_Update ON [dbo].[InputApidata_Extended];

/*
8. TO DROP TRIGGERS (if you want to remove automation):
*/
-- DROP TRIGGER IF EXISTS trg_InputApidata_Update;
-- DROP TRIGGER IF EXISTS trg_InputApidata_Extended_Update;
