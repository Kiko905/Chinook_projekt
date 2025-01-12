-- Graf 1.Predaj podľa zanru
SELECT
    g.GenreName,
    SUM(ts.TotalRevenue) AS TotalRevenue
FROM
    TrackSale_fact ts
JOIN
    Genre_dim g ON ts.GenreId = g.GenreId
GROUP BY
    g.GenreName
ORDER BY
    TotalRevenue DESC;


-- Graf 2. Top 10 skladieb podla prijmu
SELECT
    t.TrackName,
    SUM(ts.TotalRevenue) AS TotalRevenue
FROM
    TrackSale_fact ts
JOIN
    Track_dim t ON ts.TrackId = t.TrackId
GROUP BY
    t.TrackName
ORDER BY
    TotalRevenue DESC
LIMIT 10;


--Graf 3. Predaj podľa interpreta
SELECT
    a.ArtistName,
    SUM(ts.TotalRevenue) AS TotalRevenue
FROM
    TrackSale_fact ts
JOIN
    Artist_dim a ON ts.ArtistId = a.ArtistId
GROUP BY
    a.ArtistName
ORDER BY
    TotalRevenue DESC;


--Graf 4.Predaj podla medii
SELECT
    mt.MediaTypeName,
    SUM(ts.TotalRevenue) AS TotalRevenue
FROM
    TrackSale_fact ts
JOIN
    MediaType_dim mt ON ts.MediaTypeId = mt.MediaTypeId
GROUP BY
    mt.MediaTypeName;


--Graf 5.Predaj podla zamestanca
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    COUNT(ts.InvoiceLineId) AS NumberOfSales
FROM
    TrackSale_fact ts
JOIN
    Customer_dim c ON ts.CustomerID = c.CustomerID
JOIN
    Employee_dim e ON c.SupportRepId = e.EmployeeID
GROUP BY
    e.EmployeeId, e.FirstName, e.LastName
ORDER BY
    NumberOfSales DESC;
