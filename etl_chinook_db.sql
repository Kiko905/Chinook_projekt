-- Tabuľka Artist
CREATE TABLE Artist (
    ArtistId INTEGER PRIMARY KEY,
    Name VARCHAR(120)
);

-- Tabuľka Album
CREATE TABLE Album (
    AlbumId INTEGER PRIMARY KEY,
    Title VARCHAR(160),
    ArtistId INTEGER,
    FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId)
);

-- Tabuľka MediaType
CREATE TABLE MediaType (
    MediaTypeId INTEGER PRIMARY KEY,
    Name VARCHAR(120)
);

-- Tabuľka Genre
CREATE TABLE Genre (
    GenreId INTEGER PRIMARY KEY,
    Name VARCHAR(120)
);

-- Tabuľka Track
CREATE TABLE Track (
    TrackId INTEGER PRIMARY KEY,
    Name VARCHAR(200),
    AlbumId INTEGER,
    MediaTypeId INTEGER,
    GenreId INTEGER,
    Composer VARCHAR(220),
    Milliseconds INTEGER,
    Bytes INTEGER,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (AlbumId) REFERENCES Album(AlbumId),
    FOREIGN KEY (MediaTypeId) REFERENCES MediaType(MediaTypeId),
    FOREIGN KEY (GenreId) REFERENCES Genre(GenreId)
);

-- Tabuľka Playlist
CREATE TABLE Playlist (
    PlaylistId INTEGER PRIMARY KEY,
    Name VARCHAR(120)
);

-- Tabuľka PlaylistTrack (spojovacia tabuľka pre vzťah M:N medzi Playlist a Track)
CREATE TABLE PlaylistTrack (
    PlaylistId INTEGER,
    TrackId INTEGER,
    PRIMARY KEY (PlaylistId, TrackId), -- Zložený primárny kľúč
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId),
    FOREIGN KEY (TrackId) REFERENCES Track(TrackId)
);

-- Tabuľka Employee
CREATE TABLE Employee (
    EmployeeId INTEGER PRIMARY KEY,
    LastName VARCHAR(20),
    FirstName VARCHAR(20),
    Title VARCHAR(30),
    ReportsTo INTEGER,
    BirthDate DATETIME,
    HireDate DATETIME,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    FOREIGN KEY (ReportsTo) REFERENCES Employee(EmployeeId) 
);

-- Tabuľka Customer
CREATE TABLE Customer (
    CustomerId INTEGER PRIMARY KEY,
    FirstName VARCHAR(40),
    LastName VARCHAR(20),
    Company VARCHAR(80),
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    SupportRepId INTEGER,
    FOREIGN KEY (SupportRepId) REFERENCES Employee(EmployeeId)
);

-- Tabuľka Invoice
CREATE TABLE Invoice (
    InvoiceId INTEGER PRIMARY KEY,
    CustomerId INTEGER,
    InvoiceDate DATETIME,
    BillingAddress VARCHAR(70),
    BillingCity VARCHAR(40),
    BillingState VARCHAR(40),
    BillingCountry VARCHAR(40),
    BillingPostalCode VARCHAR(10),
    Total DECIMAL(10,2),
    FOREIGN KEY (CustomerId) REFERENCES Customer(CustomerId)
);

-- Tabuľka InvoiceLine
CREATE TABLE InvoiceLine (
    InvoiceLineId INTEGER PRIMARY KEY,
    InvoiceId INTEGER,
    TrackId INTEGER,
    UnitPrice DECIMAL(10,2),
    Quantity INTEGER,
    FOREIGN KEY (InvoiceId) REFERENCES Invoice(InvoiceId),
    FOREIGN KEY (TrackId) REFERENCES Track(TrackId)
);


COPY INTO Album
FROM @skunk_stage/album.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Artist
FROM @skunk_stage/artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Customer
FROM @skunk_stage/customer.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Employee
FROM @skunk_stage/employee.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
on_Error="continue";
COPY INTO Genre
FROM @skunk_stage/genre.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Invoice
FROM @skunk_stage/invoice.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO InvoiceLine
FROM @skunk_stage/invoiceline.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO MediaType
FROM @skunk_stage/mediatype.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Playlist
FROM @skunk_stage/playlist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO PlaylistTrack
FROM @skunk_stage/playlisttrack.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
COPY INTO Track
FROM @skunk_stage/track.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Faktová tabuľka TrackSale_fact
CREATE OR REPLACE TABLE TrackSale_fact AS
SELECT
    il.InvoiceLineId AS InvoiceLineId,
    il.InvoiceId AS InvoiceID, 
    il.UnitPrice AS UnitPrice,
    il.Quantity AS Quantity,
    (il.UnitPrice * il.Quantity) AS TotalRevenue, 
    t.GenreId AS GenreId,
    t.AlbumId AS AlbumId,
    t.MediaTypeId AS MediaTypeId,
    t.TrackId AS TrackId,
    al.ArtistId AS ArtistId, 
    i.CustomerId AS CustomerID, 
    i.InvoiceDate AS InvoiceDate, 
    c.SupportRepId AS EmployeeID 
FROM
    InvoiceLine AS il
JOIN
    Track AS t ON il.TrackId = t.TrackId
JOIN
    Album AS al ON t.AlbumId = al.AlbumId
JOIN
    Invoice AS i ON il.InvoiceId = i.InvoiceId
JOIN
    Customer AS c ON i.CustomerId = c.CustomerId; 


-- Dimenzionálne tabuľky

-- Track_dim
CREATE OR REPLACE TABLE Track_dim AS
SELECT
    TrackId AS TrackId,
    Name AS TrackName,
    Composer AS Composer,
    Milliseconds AS Milliseconds,
    Bytes AS Bytes,
    UnitPrice AS UnitPrice
FROM
    Track;

-- Artist_dim
CREATE OR REPLACE TABLE Artist_dim AS
SELECT
    ArtistId AS ArtistId,
    Name AS ArtistName
FROM
    Artist;

-- Album_dim
CREATE OR REPLACE TABLE Album_dim AS
SELECT
    AlbumId AS AlbumId,
    Title AS AlbumTitle
FROM
    Album;

-- MediaType_dim
CREATE OR REPLACE TABLE MediaType_dim AS
SELECT
    MediaTypeId AS MediaTypeId,
    Name AS MediaTypeName
FROM
    MediaType;

-- Genre_dim
CREATE OR REPLACE TABLE Genre_dim AS
SELECT
    GenreId AS GenreId,
    Name AS GenreName
FROM
    Genre;

-- Customer_dim
CREATE OR REPLACE TABLE Customer_dim AS
SELECT
    CustomerId AS CustomerID,
    FirstName AS FirstName,
    LastName AS LastName,
    Address AS Address,
    City AS City,
    State AS State,
    Country AS Country,
    PostalCode AS PostalCode,
    Phone AS Phone,
    Email AS Email,
    SupportRepId AS SupportRepID
FROM
    Customer;

-- Employee_dim
CREATE OR REPLACE TABLE Employee_dim AS
SELECT
    EmployeeId AS EmployeeID,
    LastName AS LastName,
    FirstName AS FirstName,
    Title AS Title,
    BirthDate AS BirthDate,
    HireDate AS HireDate,
    Address AS Address,
    City AS City,
    State AS State,
    Country AS Country,
    PostalCode AS PostalCode,
    Phone AS Phone,
    Fax AS Fax,
    Email AS Email
FROM
    Employee;

-- Date_dim
CREATE OR REPLACE TABLE Date_dim AS
SELECT
    DISTINCT
    InvoiceDate AS timestamp,
    DAY(InvoiceDate) AS day,
    TO_CHAR(InvoiceDate, 'D') AS dayOfWeek, 
    TO_CHAR(InvoiceDate, 'Day') AS DayOfWeekAsString, 
    MONTH(InvoiceDate) AS month,
    TO_CHAR(InvoiceDate, 'Month') AS monthAsString, 
    YEAR(InvoiceDate) AS year,
    WEEK(InvoiceDate) AS week,
    QUARTER(InvoiceDate) AS quarter
FROM
    Invoice;


-- Invoice_dim
CREATE OR REPLACE TABLE Invoice_dim AS
SELECT
    InvoiceId AS InvoiceID,
    CustomerId AS CustomerID,
    InvoiceDate AS InvoiceDate,
    BillingAddress AS BillingAddress,
    BillingCity AS BillingCity,
    BillingState AS BillingState,
    BillingCountry AS BillingCountry,
    BillingPostalCode AS BillingPostalCode,
    Total AS Total
FROM
    Invoice;


DROP  TABLE  IF  EXISTS Artist;
DROP  TABLE  IF  EXISTS Album;
DROP  TABLE  IF  EXISTS Genre;
DROP  TABLE  IF  EXISTS MediaType;
DROP  TABLE  IF  EXISTS Track;
DROP  TABLE  IF  EXISTS Playlist;
DROP  TABLE  IF  EXISTS PlaylistTrack;
DROP  TABLE  IF  EXISTS InvoiceLine;
DROP  TABLE  IF  EXISTS Invoice;
DROP  TABLE  IF  EXISTS Customer;
DROP  TABLE  IF  EXISTS Employee;
