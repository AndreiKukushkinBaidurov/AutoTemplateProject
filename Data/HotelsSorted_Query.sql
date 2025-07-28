-- HotelsSorted table with comprehensive ranking
-- Ranking criteria: Bookings (40%) + Availability (30%) + L2B efficiency (20%) + Total Cost (10%)

-- Top 20 Best Performing Hotels
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
FROM [dbo].[HotelsSorted]
ORDER BY Overall_Rank;

-- Ranking Explanation:
-- Overall_Rank: 1 = Best performing hotel overall
-- Bookings_Rank: 1 = Most reservations 
-- Availability_Rank: 1 = Highest availability percentage
-- L2B_Rank: 1 = Most efficient (lowest L2B ratio)
-- Cost_Rank: 1 = Highest total cost (most revenue)
