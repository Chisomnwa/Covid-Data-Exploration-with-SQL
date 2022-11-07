/*Covid 19 Data Exploration 

Date Range: FROM 1st January, 2020 t0 5th November, 2022.

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- ANALYSIS OF COVID DATA FROM 1st January, 2020 t0 5th November, 2022.
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT *
FROM CovidVaccinations
ORDER BY 3, 4;

-- SELECT DATA WE ARE GOING TO BE STARTING WITH

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


--LOOKING AT THE TOTAL CASES VS TOTAL DEATHS
-- Shows Likelihood of dying if you contact covid in your country

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%states'
AND continent IS NOT NULL
ORDER BY 1, 2;

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%Nigeria%'
AND continent IS NOT NULL
ORDER BY 1, 2;


-- LOOKING AT THE TOTAL CASES VS POPULATION
-- Shows Percentage of Population infected with covid

SELECT Location, Date, population,  total_cases, (total_cases/population) * 100  AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
-- WHERE Location LIKE '%states'
ORDER  BY 1, 2;

SELECT Location, Date, population, total_cases, (total_cases/population) * 100  AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
AND Location LIKE '%Nigeria%'
ORDER  BY 1, 2;


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentPopulationInfected 
FROM CovidDeaths
WHERE continent IS NOT NULL
--WHERE Location LIKE '%states'
GROUP BY Location, population
ORDER BY  PercentPopulationInfected DESC;


-- SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- LET'S BREAK IT DOWN BY CONTINENT

--NB:
-- This method kind of gives you the accurate result if you want to break it down to continent
-- We use where continent is null because if you check in the excel sheet, the locations has the names of the continent in them, 
-- instead of the names of the countries.
SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
--WHERE Location LIKE '%states'
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- But we will use this for now for the sake of visualization purposes
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
--WHERE Location LIKE '%states'
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS
SELECT Date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1, 2;


SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- ASSESSING VACCINATION DATA

SELECT *
FROM CovidVaccinations;

-- JOINING THE TWO TABLES TOGETHER FOR VIEWING

SELECT * 
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date;


-- LOOKING AT THE TOTAL POPULATION VS VACCINATIONS
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;


-- Getting the percentage of RollingPeopleVaccinated for each location

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_vaccination, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 AS RollingPeopleVaccinatedPercentage
FROM PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS  #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
--WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population) * 100 AS PercentRollingPeopleVaccinated
FROM #PercentPopulationVaccinated;



-- CREATING VIEW TO STORE DATA FOR DATA VISUALIZATION
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated;