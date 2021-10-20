/* #-----------------------------------------------------------------------------#

SQL Data Exploration

Dataset: COVID-19 Deaths [source: https://ourworldindata.org/covid-deaths]
(owid-covid-data.csv trimmed in Excel to make two datasets: covid_deaths.csv and covid_vaccinations.csv)

[Showcasing: Window Functions, Aggregate Functions, Joins, CTE's, Temp Tables, Converting Data Types, Creating Views]

#-----------------------------------------------------------------------------# */

-- Basic data display

SELECT * 
FROM COVIDProject..covid_deaths 
ORDER BY 3,4

SELECT *
FROM COVIDProject..covid_vaccinations
ORDER BY 3,4



-- Selecting data that we are going to be using (by country)

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVIDProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Total Cases vs Total Deaths
-- Likelyhood of dying if one contracts COVID-19 in a given country (e.g.: Netherlands)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM COVIDProject..covid_deaths
WHERE location LIKE 'Netherlands'
AND continent IS NOT NULL
ORDER BY 1,2



-- Total Cases vs Population
-- Percentage of population that tested positive for COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentage_population_infected
FROM COVIDProject..covid_deaths
ORDER BY 1,2



-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS peak_infection_count, MAX((total_cases/population)*100) AS percentage_population_infected
FROM COVIDProject..covid_deaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC



-- Countries with Highest Death Count per Population
-- requires a cast of total_deaths to integers due to the imported data type
-- (showing only countries and no continent groupings)

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM COVIDProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- (as before, but now grouping by continent)

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM COVIDProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC



-- Global Breakdown of New Cases and Total Deaths
-- (if the 'date' column is included, it display the numbers on a per day basis)

SELECT /*date,*/ SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM COVIDProject..covid_deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations
-- New column with commulative vaccinations will allow us to calculate the percentage of the population that has been vaccinated
-- (percentage can be higher than 100% due to some individulas receiving more than one dose)

-- (displaying a simple JOIN of both tables)

SELECT *
FROM COVIDProject..covid_deaths dea
JOIN COVIDProject..covid_vaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date

-- (joining both tables and displaying partitioning for the purposes of obtaining a column for commulative vaccinations)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS commulative_vaccinations
FROM COVIDProject..covid_deaths dea
JOIN COVIDProject..covid_vaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--(using a CTE to display commulative vaccinations as a percentage of population)

WITH PopvsVac (continent, location, date, population, new_vaccinations, commulative_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS commulative_vaccinations
FROM COVIDProject..covid_deaths dea
JOIN COVIDProject..covid_vaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (commulative_vaccinations/population)*100 AS percentage_vaccinated
FROM PopvsVac


--(using a TEMP TABLE for the same effect)

DROP TABLE IF EXISTS #percentage_vaccinated		-- (ensures the query can run in case the temp table already exists)
CREATE TABLE #percentage_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
commulative_vaccinations numeric
)

INSERT INTO #percentage_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS commulative_vaccinations
FROM COVIDProject..covid_deaths dea
JOIN COVIDProject..covid_vaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (commulative_vaccinations/population)*100 AS percentage_vaccinated
FROM #percentage_vaccinated



-- Creating View for later use in a visualization

CREATE VIEW percentage_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS commulative_vaccinations
FROM COVIDProject..covid_deaths dea
JOIN COVIDProject..covid_vaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL



/*
The following queries were used to trim data for the Tableau dashboard example.
[URL: https://public.tableau.com/views/Covid-19Dashboard_16318778822460/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link]
*/


-- Global Count display

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
FROM COVIDProject..covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2



-- Total Deaths by Continent display 

SELECT location, SUM(cast(new_deaths as int)) as total_death_count
FROM COVIDProject..covid_deaths
WHERE continent IS NULL 
AND location not IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC



-- Percentage of Population Infected per Country (world map display)

SELECT location, population, MAX(total_cases) as peak_infection_count, MAX((total_cases/population))*100 as percentage_population_infected
FROM COVIDProject..covid_deaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC


-- Percentage of Population Infected per Country (including date column to show time evolution)

SELECT location, population, date, MAX(total_cases) as peak_infection_count, MAX((total_cases/population))*100 as percentage_population_infected
FROM COVIDProject..covid_deaths
GROUP BY location, population, date
GROUP BY percentage_population_infected DESC