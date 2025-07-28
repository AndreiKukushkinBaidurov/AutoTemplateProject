-- Updated table with corrected calculations:
-- L2B = Search / Quantity_Reservations (rounded)
-- % of availability = (Result / Search) * 100 (rounded)
-- If Search = 100%, then Result shows the availability percentage

SELECT TOP (1000) [Hotel_ID]
      ,[Quantity_Reservations]
      ,[Total_Cost]
      ,[City]
      ,[Country]
      ,[Search]
      ,[Result]
      ,[L2B]
      ,[Percent_of_availability]
  FROM [dbo].[InputApidata_Extended]