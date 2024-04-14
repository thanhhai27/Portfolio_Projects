-- Covid 19 Data Exploration
SELECT *
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4
GO

--Total Cases vs Total Deaths
--Show the death possibility if you contact Covid-19 in your country
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,3) AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
-- AND location like 'Viet%
ORDER BY 1,2
GO

--Total Cases vs Population
--Show the percentage of people infected by Covid-19
SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,3) AS PercentPeopleInfected
FROM dbo.CovidDeaths
-- WHERE location like 'Viet%'
ORDER BY 1,2
GO

--Countries with Highest Infecion Rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCounted, ROUND(MAX((total_cases/population)*100),3) AS PercentagePopulationInfected
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
-- AND location like 'Viet%'
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC
GO

--Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS HighestTotalDeathCounted_l
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestTotalDeathCounted_l DESC
GO

--CONTINENT NUMBERS
--Continents with Highest Death Count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS HighestTotalDeathCounted_c
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HighestTotalDeathCounted_c DESC
GO

--GLOBAL NUMBERS
SELECT SUM(new_cases) AS NewCases, SUM(total_deaths) AS TotalDeaths, ROUND((SUM(total_deaths)/SUM(total_cases))*100,3) AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent is NOT NULL
-- AND location LIKE 'Viet%'
ORDER BY 1,2
GO

--Total Population vs Total Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS PeopleVaccinatedByDay
FROM dbo.CovidDeaths dea
    JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3
GO

--Use CTE to perform Calculation on Partition By in previous query
--Percentage of Population received at least one Covid_19 Vaccine
WITH
    POPVACC(continent, location, date, population, new_vaccinations, PeopleVaccinatedByDay)
    AS
    (
        SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
        , SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS PeopleVaccinatedByDay
        FROM dbo.CovidDeaths dea
            JOIN dbo.CovidVaccinations vac
            ON dea.location = vac.location
                AND dea.date = vac.date
        WHERE dea.continent is NOT NULL
    )
SELECT *, ROUND((PeopleVaccinatedByDay/population)*100,3) AS PercentagePopulationVaccinated
FROM POPVACC
ORDER BY 2,3
GO

--TEMP TABLE
--Use Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF exists #PopulationVaccinatedFigure
CREATE TABLE #PopulationVaccinatedFigure
(
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    PeopleVaccinatedByDay NUMERIC
)

INSERT INTO #PopulationVaccinatedFigure
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS PeopleVaccinatedByDay
FROM dbo.CovidDeaths dea
    JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT * 
FROM #PopulationVaccinatedFigure
ORDER BY 2,3
GO

-- Create View to store data for later visualizations
CREATE VIEW PopulationVaccinatedFigure AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(VAC.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS PeopleVaccinatedByDay
FROM dbo.CovidDeaths dea
    JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is NOT NULL
