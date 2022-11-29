-- Inspecting Data
SELECT *
FROM covid_deaths

SELECT *
FROM covid_vaccinations


-- Selecting the data that will will be used
SELECT location, date, population, new_cases, total_cases, total_deaths
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date


-- Analysis 1 - Total Cases, Total Deaths & Death Rate by Country and Date
-- Shows the likelihood of dying if you contract Covid-19 in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date


-- Analysis 2 - Infection Rate per Population by Country & Date
-- Shows the percentage of population is infected with Covid
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS infection_rate
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date


-- Analysis 3 - Countries with Highest Infection Rate compared to Population
SELECT location, date, population, MAX(total_cases) AS total_cases,  MAX((total_cases/population)) * 100 AS infection_rate
FROM covid_deaths
GROUP BY location, date, population
ORDER BY infection_rate DESC


-- Analysis 4 - Countries with Highest Death Count per Population & Death Rate
SELECT location, date, population, MAX(total_deaths) AS total_deaths, (MAX(total_deaths)/population) * 100 AS death_rate_by_population
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, date, population
ORDER BY death_rate_by_population DESC



-- ANALYSIS BY CONTINENT --
-- Analysis 5 - Showing continents with the highest death count per population
SELECT dea.location, dea.population, 
	MAX(total_cases) AS total_cases, 
	MAX(total_deaths) AS total_deaths,
	(MAX(total_cases)/dea.population) * 100 AS infection_rate, 
	(MAX(total_deaths)/MAX(total_cases)) * 100 AS death_perc
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.date = vac.date
WHERE dea.continent IS NULL
	AND dea.location != 'World'
	AND dea.location != 'International'
	AND dea.location != 'European Union'
	AND dea.location != 'Low income'
	AND dea.location != 'Lower middle income'
	AND dea.location != 'Upper middle income'
	AND dea.location != 'High income'
GROUP BY dea.location, dea.population
ORDER BY infection_rate DESC


-- GLOBAL NUMBERS --
-- Analysis 6 - Shows the highest death percentage by date
SELECT date, SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS int)) AS total_new_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY death_perc DESC


-- Analysis 7 - Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY dea.location, dea.date


-- Using CTE to perform calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS vaccination_perc
FROM PopvsVac


-- Using Temp Table to perform calculation on Partition By in previous query
DROP TABLE IF EXISTS #perc_population_vaccinated
CREATE TABLE #perc_population_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #perc_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL

SELECT *, (Rolling_People_Vaccinated/Population)*100 AS vaccination_perc
FROM #perc_population_vaccinated
