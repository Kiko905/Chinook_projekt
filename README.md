﻿
# Dokumentácia ETL procesu pre dataset Chinook

## 1. Úvod a popis zdrojových dát

Cieľom tohto projektu je analyzovať dáta z datasetu Chinook, zameriavajúceho sa na predaj hudby, interpretov, žánrov a transakcií so zákazníkmi. Projekt mieri na identifikáciu predajných trendov a správania používateľov prostredníctvom ETL procesu implementovaného v nástroji Snowflake.

Zdrojové dáta obsahujú tieto tabuľky:

- **Artist**: Obsahuje informácie o interpretoch, vrátane ich jedinečného ID a mena.
- **Album**: Obsahuje informácie o albumoch, vrátane ich ID, názvov a prepojenia na interpreta.
- **Track**: Obsahuje informácie o skladbách, vrátane ich ID, mena, albumu, interpreta, mediálneho typu, žánru, ceny, dĺžky a počtu bajtov.
- **InvoiceLine** a **Invoice**: Obsahujú detaily jednotlivých predajov, faktúr, cien a počtu zakúpených jednotiek.
- **Customer** a **Employee**: Obsahujú informácie o zákazníkoch a zamestnancoch, vrátane ich kontaktných údajov.
- **Genre** a **MediaType**: Obsahujú kategorizácie skladieb podľa žánrov a typov médií.
- **Playlist** a **PlaylistTrack**: Informácie o playlistoch a ich skladbách.

ERD diagram znázorňujúci vzťahy medzi tabuľkami:

![ERD Diagram](ERD_diagram.png)

## 2. Návrh dimenzionálneho modelu

Navrhli sme multi-dimenzionálny model typu hviezda s nasledujúcimi tabuľkami:

### Faktová tabuľka
**TrackSale_fact**:
- **Kľúče**: `InvoiceLineId`, `TrackId`, `AlbumId`, `ArtistId`, `GenreId`, `MediaTypeId`
- **Metirky**: `UnitPrice`, `Quantity`, `TotalRevenue`
- Použitie: Meranie celkového príjmu z predaja, analýza počtu predaných jednotiek.

### Dimenzionálne tabuľky
1. **Track_dim**
   - **Údaje**: `TrackId`, `Name`, `Composer`, `Milliseconds`, `Bytes`, `UnitPrice`
   - **Typ dimenzie**: SCD Type 1

2. **Artist_dim**
   - **Údaje**: `ArtistId`, `Name`
   - **Typ dimenzie**: SCD Type 1

3. **Album_dim**
   - **Údaje**: `AlbumId`, `Title`
   - **Typ dimenzie**: SCD Type 1

4. **MediaType_dim**
   - **Údaje**: `MediaTypeId`, `Name`
   - **Typ dimenzie**: SCD Type 1

5. **Genre_dim**
   - **Údaje**: `GenreId`, `Name`
   - **Typ dimenzie**: SCD Type 1

![Dimenzionálny Model](Star_Diagram.png)


  

# ETL proces v Snowflake

  

ETL proces v Snowflake sa skladá z troch hlavných fáz: **extrakcia dát** (Extract), **transformácia dát** (Transform), a **načítanie dát** (Load). Tento proces bol implementovaný na spracovanie a analýzu údajov zo zdrojového datasetu, pričom výsledný model bol pripravený na analytické operácie.

  

## 3.1 Extract (Extrahovanie dát)

  

Dáta boli zo zdrojového datasetu vo formáte CSV nahrané do Snowflake pomocou interného stage úložiska s názvom `skunk_stage`. Stage slúži ako dočasné úložisko, ktoré umožňuje efektívne spracovanie a import dát.

  

Vytvorenie stage v Snowflake:

```sql
CREATE  OR  REPLACE STAGE skunk_stage;
```

  

Dáta boli nahrané do staging tabuliek pomocou príkazu `COPY INTO`:

```sql
COPY  INTO Artist
FROM  @skunk_stage/artist.csv
FILE_FORMAT  = (TYPE  =  'CSV' FIELD_OPTIONALLY_ENCLOSED_BY =  '"' SKIP_HEADER =  1);

```

  

Tento príkaz sa opakoval pre každú tabuľku (Artist, Album, Customer, Employee, atď.). Ak sa vyskytli nekonzistentné dáta, proces pokračoval aj pri chybách pomocou parametra `ON_ERROR = 'CONTINUE'`.

  

## 3.2 Transform (Transformácia dát)

  

V tejto fáze boli dáta z staging tabuliek spracované na vytvorenie dimenzií a faktovej tabuľky, ktoré sú optimalizované na analytické operácie.

  

### Vytvorenie faktovej tabuľky `TrackSale_fact`:

Faktová tabuľka obsahuje informácie o predaji skladieb, ako sú jednotkové ceny, množstvo a celkové príjmy. Spojením tabuliek `InvoiceLine`, `Track`, `Album`, a `Artist` sme získali všetky potrebné informácie:

```sql
CREATE  TABLE  TrackSale_fact  AS
SELECT
    il.InvoiceLineId  AS InvoiceLineId,
    il.UnitPrice  AS UnitPrice,
    il.Quantity  AS Quantity,
    (il.UnitPrice * il.Quantity) AS TotalRevenue,
    t.GenreId  AS GenreId,
    t.AlbumId  AS AlbumId,
    t.MediaTypeId  AS MediaTypeId,
    t.TrackId  AS TrackId,
    al.ArtistId  AS ArtistId
FROM
    InvoiceLine AS il
JOIN
    Track AS t ON  il.TrackId  =  t.TrackId
JOIN
    Album AS al ON  t.AlbumId  =  al.AlbumId;
```

  

### Vytvorenie dimenzií:

  

1.  **Track_dim:** Táto dimenzia obsahuje informácie o jednotlivých skladbách, ako sú názov, skladateľ, dĺžka a cena.

```sql
CREATE  TABLE  Track_dim  AS
SELECT
    TrackId AS TrackId,
    Name  AS TrackName,
    Composer AS Composer,
    Milliseconds AS Milliseconds,
    Bytes AS Bytes,
    UnitPrice AS UnitPrice
FROM
    Track;
```

  

2.  **Artist_dim:** Dimenzia pre umelcov obsahuje informácie o názve interpreta.

```sql
CREATE  TABLE  Artist_dim  AS
SELECT
    ArtistId AS ArtistId,
    Name  AS ArtistName
FROM
    Artist;
```

  

3.  **Album_dim:** Dimenzia pre albumy, ktorá uchováva názvy albumov.

```sql
CREATE  TABLE  Album_dim  AS
SELECT
    AlbumId AS AlbumId,
    Title AS AlbumTitle
FROM
    Album;

```

  

4.  **MediaType_dim:** Dimenzia pre typy médií, ktorá obsahuje názvy mediálnych formátov.

```sql
CREATE  TABLE  MediaType_dim  AS
SELECT
    MediaTypeId AS MediaTypeId,
    Name  AS MediaTypeName
FROM
    MediaType;
```

  

5.  **Genre_dim:** Dimenzia pre žánre, ktorá obsahuje názvy žánrov.

```sql
CREATE  TABLE  Genre_dim  AS
SELECT
    GenreId AS GenreId,
    Name  AS GenreName
FROM
    Genre;
```

  

## 3.3 Load (Načítanie dát)

  

Po úspešnej transformácii dát do požadovaných formátov boli všetky dimenzie a faktová tabuľka nahraté do finálnej štruktúry. Nakoniec boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

```sql
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
```

  

---

  

ETL proces umožnil spracovanie pôvodných dát z CSV formátu do viacdimenzionálneho modelu typu hviezda, ktorý je optimalizovaný na analytické operácie a vizualizácie. Tento model poskytuje robustnú základňu na analýzu a vizualizáciu používateľského správania a hudobných preferencií.

## 4. Vizualizácia dát

1. **Predaj podľa albumu**
   - Vizualizácia: Stĺpcový graf zobrazujúci celkový predaj (Quantity) podľa albumu.
   - SQL dotaz:
     ```sql
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
     ```

2. **Predaj podľa interpreta**
   - Vizualizácia: Stĺpcový graf zobrazujúci celkový predaj (Quantity) podľa interpreta.
   - SQL dotaz:
     ```sql
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
     ```

3. **Predaj podľa skladby**
   - Vizualizácia: Stĺpcový graf zobrazujúci celkový predaj (Quantity) podľa skladby.
   - SQL dotaz:
     ```sql
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
     ```

4. **Celkový príjem podľa albumu**
   - Vizualizácia: Stĺpcový graf zobrazujúci celkový príjem (TotalRevenue) podľa albumu.
   - SQL dotaz:
     ```sql
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
     ```

5. **Priemerný príjem na skladbu podľa interpreta**
   - Vizualizácia: Stĺpcový graf zobrazujúci priemerný príjem na skladbu (TotalRevenue / počet skladieb) podľa interpreta.
   - SQL dotaz:
     ```sql
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
     ```

Každá vizualizácia poskytuje hodnotné ľahko interpretovateľné pohľady na dáta a pomáha odpovedať na dôležité obchodné otázky.

Autor: Kristián Szabó

