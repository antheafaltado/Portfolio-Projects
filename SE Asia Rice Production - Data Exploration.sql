
/*
Rice Production Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Rice Production

SELECT *
FROM RiceSECountries..RiceProduction
ORDER BY 1,2

-- Looking at Crop Yield (t/ha) Actual Value

Select Country, Year, [production__tonnes__per_capita], [area_harvested__ha__per_capita], [Yield (t/ha)], 
	([production__tonnes__per_capita]/[area_harvested__ha__per_capita]) as 'Yield Actual Value'
FROM RiceSECountries..RiceProduction
ORDER BY 'Yield Actual Value' DESC

Select Country, Year, [production__tonnes__per_capita], [area_harvested__ha__per_capita], [Yield (t/ha)], 
	([production__tonnes__per_capita]/[area_harvested__ha__per_capita]) as 'Yield Actual Value'
FROM RiceSECountries..RiceProduction
WHERE Country = 'Philippines'
ORDER BY 'Yield Actual Value' DESC

-- Looking at Country with the Highest Production per capita (t) per Year

SELECT Country, Year, [Production (t)], [production__tonnes__per_capita]
FROM RiceSECountries..RiceProduction
ORDER BY Year, [production__tonnes__per_capita] DESC

--Looking at Country Specification by Population

SELECT Country, Year, Population,
CASE
	WHEN Population > 2000000 THEN 'Large'
	WHEN Population < 2000000 THEN 'Small'
	ELSE 'Average'
END AS 'Country Specification'
FROM RiceSECountries..RiceProduction
WHERE Population is not null
ORDER BY Population

-- Looking at Total Production per capita (t) vs Population

SELECT Country, Year, Population, [Production (t)], Population ,	
		([Production (t)]/Population)*100 as 'Percent Population per Production' 
FROM RiceSECountries..RiceProduction

-- Looking at Countries with Highest Production compared to Population

Select Country, Population, MAX([Production (t)]) as 'Highest Production',  Max(([Production (t)]/population))*100 as 'Percent Population'
FROM RiceSECountries..RiceProduction
GROUP BY Country, Population
ORDER BY 'Percent Population' DESC

-- Looking at Physiological Population Density

SELECT Country, Year, Population, [Land Use (ha)],[Production (t)],	
		AVG (Population/[Land Use (ha)]) OVER (Partition BY Year) as 'Physiological Density' 
FROM RiceSECountries..RiceProduction
ORDER BY  'Physiological Density'  ASC

SELECT Country, Year, Population, [Land Use (ha)],[Production (t)],	
		AVG (Population/[Land Use (ha)]) OVER (Partition BY Year) as 'Physiological Density' 
FROM RiceSECountries..RiceProduction
WHERE COUNTRY = 'Philippines'
ORDER BY 'Physiological Density'  ASC

-- Countries with Highest Production (t) and Yield (t/ha) per Population

SELECT Country, MAX(cast([Production (t)] as int)) as 'Total Production (t)',
	MAX(cast([Yield (t/ha)] as int)) as 'Total Yield (t/ha)'
FROM RiceSECountries..RiceProduction
GROUP BY COUNTRY
ORDER BY 'Total Production (t)' DESC


-- SouthEast Asian Numbers

SELECT Country, SUM([production__tonnes__per_capita]) as 'Total Production (t)', SUM([area_harvested__ha__per_capita]) as 'Area Harvested (ha)',
	SUM ([production__tonnes__per_capita])/SUM([area_harvested__ha__per_capita]) as 'Crop Yield (t/ha)'
FROM RiceSECountries..RiceProduction
GROUP BY Country
ORDER BY 1,2

SELECT SUM([production__tonnes__per_capita]) as 'Total Production (t)', SUM([area_harvested__ha__per_capita]) as 'Area Harvested (ha)',
	SUM ([production__tonnes__per_capita])/SUM([area_harvested__ha__per_capita]) as 'Crop Yield (t/ha)'
FROM RiceSECountries..RiceProduction
ORDER BY 1,2

-- Rice Import and Export

SELECT *
FROM RiceSECountries..RiceImportExport
ORDER BY 1,2

-- Country with the Imports and Exports per capita (t) per Year

SELECT Country, Year, [imports__tonnes__per_capita], [exports__tonnes__per_capita]
FROM RiceSECountries..RiceImportExport
ORDER BY Year, [imports__tonnes__per_capita], [exports__tonnes__per_capita] DESC

SELECT Country, Year, [imports__tonnes__per_capita], [exports__tonnes__per_capita]
FROM RiceSECountries..RiceImportExport
WHERE YEAR = 2020
ORDER BY [imports__tonnes__per_capita], [exports__tonnes__per_capita] ASC

-- Combining Rows from Rice Production and Rice Import and Export

SELECT Prod.Country, Prod.Year, Prod.[production__tonnes__per_capita], ImpExp.imports__tonnes__per_capita, ImpExp.exports__tonnes__per_capita
FROM RiceSECountries..RiceProduction AS Prod
INNER JOIN RiceSECountries..RiceImportExport AS ImpExp 
	ON Prod.Country = ImpExp.Country
	and Prod.Year = ImpExp.Year

-- Looking at Total Imports and Exports vs Production

SELECT Prod.Country, Prod.Year, Prod.Population, Prod.[Production (t)], ImpExp.[Imports (t)], ImpExp.[Exports (t)],
	SUM(CONVERT(int,ImpExp.[Imports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Imports',
	SUM(CONVERT(int,ImpExp.[Exports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Exports'
FROM RiceSECountries..RiceProduction AS Prod
JOIN RiceSECountries..RiceImportExport AS ImpExp 
	ON Prod.Country = ImpExp.Country
	and Prod.Year = ImpExp.Year
ORDER BY Country

-- Using CTE to perform Calculation on Partition By in previous query

WITH ProdvsImpExp (Country,Year, Population, [Production (t)], [Imports (t)], [Exports (t)], ['Rolling Imports'], ['Rolling Exports'])
AS
(
SELECT Prod.Country, Prod.Year, Prod.Population, Prod.[Production (t)], ImpExp.[Imports (t)], ImpExp.[Exports (t)],
	SUM(CONVERT(int,ImpExp.[Imports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Imports',
	SUM(CONVERT(int,ImpExp.[Exports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Exports'
FROM RiceSECountries..RiceProduction AS Prod
JOIN RiceSECountries..RiceImportExport AS ImpExp 
	ON Prod.Country = ImpExp.Country
	and Prod.Year = ImpExp.Year
)
Select *, (['Rolling Imports']/[Production (t)])*100 as 'Percentage of Imports per Production',
		  (['Rolling Exports']/[Production (t)])*100 as 'Percentage of Exports per Production'
From ProdvsImpExp 


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #ProdvsImpExp 
Create Table #ProdvsImpExp 
(
Country nvarchar(255),
Year numeric,
Population numeric,
[Production (t)] numeric,
[Imports (t)] numeric,
[Exports (t)] numeric,
['Rolling Imports'] numeric,
['Rolling Exports'] numeric,
)

Insert into #ProdvsImpExp 
SELECT Prod.Country, Prod.Year, Prod.Population, Prod.[Production (t)], ImpExp.[Imports (t)], ImpExp.[Exports (t)],
	SUM(CONVERT(int,ImpExp.[Imports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Imports',
	SUM(CONVERT(int,ImpExp.[Exports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Exports'
FROM RiceSECountries..RiceProduction AS Prod
JOIN RiceSECountries..RiceImportExport AS ImpExp 
	ON Prod.Country = ImpExp.Country
	and Prod.Year = ImpExp.Year

Select *, (['Rolling Imports']/[Production (t)])*100 as 'Percentage of Imports per Production',
		  (['Rolling Exports']/[Production (t)])*100 as 'Percentage of Exports per Production'
From #ProdvsImpExp 

-- Creating View to store data for later visualizations

CREATE VIEW ProdvsImpExp as
SELECT Prod.Country, Prod.Year, Prod.Population, Prod.[Production (t)], ImpExp.[Imports (t)], ImpExp.[Exports (t)],
	SUM(CONVERT(int,ImpExp.[Imports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Imports',
	SUM(CONVERT(int,ImpExp.[Exports (t)])) OVER (Partition by Prod.Country Order by Prod.Country, Prod.Year) as 'Rolling Exports'
FROM RiceSECountries..RiceProduction AS Prod
JOIN RiceSECountries..RiceImportExport AS ImpExp 
	ON Prod.Country = ImpExp.Country
	and Prod.Year = ImpExp.Year


SELECT*
FROM ProdvsImpExp
