-- Graf 1.Predaj podľa albumu
SELECT 
    al.Title, 
    SUM(ts.Quantity) AS TotalQuantitySold
FROM 
    TrackSale_fact ts
JOIN 
    Album_dim al ON ts.AlbumId = al.AlbumId
GROUP BY 
    al.Title
ORDER BY 
    TotalQuantitySold DESC;

-- Graf 2. Predaj podľa interpreta
SELECT 
    ar.Name, 
    SUM(ts.Quantity) AS TotalQuantitySold
FROM 
    TrackSale_fact ts
JOIN 
    Artist_dim ar ON ts.ArtistId = ar.ArtistId
GROUP BY 
    ar.Name
ORDER BY 
    TotalQuantitySold DESC;

--Graf 3. Predaj podľa skladby
SELECT 
    tr.Name, 
    SUM(ts.Quantity) AS TotalQuantitySold
FROM 
    TrackSale_fact ts
JOIN 
    Track_dim tr ON ts.TrackId = tr.TrackId
GROUP BY 
    tr.Name
ORDER BY 
    TotalQuantitySold DESC;

--Graf 4.Celkový príjem podľa albumu
SELECT 
    al.Title, 
    SUM(ts.TotalRevenue) AS TotalRevenue
FROM 
    TrackSale_fact ts
JOIN 
    Album_dim al ON ts.AlbumId = al.AlbumId
GROUP BY 
    al.Title
ORDER BY 
    TotalRevenue DESC;

--Graf 5.Priemerný príjem na skladbu podľa interpreta
SELECT 
    ar.Name, 
    AVG(ts.TotalRevenue) AS AvgRevenuePerTrack
FROM 
    TrackSale_fact ts
JOIN 
    Artist_dim ar ON ts.ArtistId = ar.ArtistId
GROUP BY 
    ar.Name
ORDER BY 
    AvgRevenuePerTrack DESC;