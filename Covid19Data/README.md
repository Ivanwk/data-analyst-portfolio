# Covid-19 Data Exploration using SQL and Tableau

## Table of Content
- [Business Task](#business-task)
- [Data Set](#data-set)
- [SQL](#sql)
- [Tableau](#tableau)

***

## Business Task
Analyze Covid-19 dataset in SQL to generate various insights and visualization the data using Tableau.

## Data Set
Covid-19 data from Feb 4 2020 to Nov 18 2022 from [Our World in Data](https://ourworldindata.org/covid-deaths).

Separate the data set into two sets with corresponding information: covid_deaths and covid_vaccinations (file is too large to be uploaded to GitHub).

## SQL
Inspecting Data
```sql
SELECT *
FROM covid_deaths

SELECT *
FROM covid_vaccinations
```
![inspecting_data](https://user-images.githubusercontent.com/32184014/204600902-fe279309-3426-4461-b334-47fcffe592c6.png)


Selecting the data that will will be used
```sql
SELECT location, date, population, new_cases, total_cases, total_deaths
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date
```
![selected_data](https://user-images.githubusercontent.com/32184014/204601339-057cbb89-1a93-46aa-b25f-4f8a0b8b9632.png)


Analysis 1 - Total Cases, Total Deaths & Death Rate by Country and Date

Shows the likelihood of dying if you contract Covid-19 in your country
```sql
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date
```
![Analysis1](https://user-images.githubusercontent.com/32184014/204601661-4d128337-0396-4f1c-a53d-a38912c02a48.png)


Analysis 2 - Infection Rate per Population by Country & Date

Shows the percentage of population is infected with Covid
```sql
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS infection_rate
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY location, date
```
![Analysis2](https://user-images.githubusercontent.com/32184014/204602163-2545b7d6-8a35-4f48-b8f0-8dfe0facdcd1.png)


Analysis 3 - Countries with Highest Infection Rate compared to Population
```sql
SELECT location, date, population, MAX(total_cases) AS total_cases,  MAX((total_cases/population)) * 100 AS infection_rate
FROM covid_deaths
GROUP BY location, date, population
ORDER BY infection_rate DESC
```
![Analysis3](https://user-images.githubusercontent.com/32184014/204602940-09c7038f-4eb9-4893-916d-961eb2c6cabc.png)



Analysis 4 - Countries with Highest Death Count per Population & Death Rate
```sql
SELECT location, date, population, MAX(total_cases) AS total_cases,  MAX((total_cases/population)) * 100 AS infection_rate
FROM covid_deaths
GROUP BY location, date, population
ORDER BY infection_rate DESC
```
![Analysis4](https://user-images.githubusercontent.com/32184014/204603202-3fb1c5f0-09ae-434e-a952-12604dcc8112.png)


Analysis 5 - Showing continents with the highest death count per population
```sql
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
```
![Analysis5](https://user-images.githubusercontent.com/32184014/204603649-2c0e9621-3cb5-427f-8f74-fe9354cdd142.png)


Analysis 6 - Shows the highest death percentage by date
```sql
SELECT date, SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS int)) AS total_new_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS death_perc
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY death_perc DESC
```
![Analysis6](https://user-images.githubusercontent.com/32184014/204604918-0221e3d3-d721-416e-93ab-5b40873a3091.png)


Analysis 7 - Total Population vs Vaccinations

Shows Percentage of Population that has recieved at least one Covid Vaccine
```sql
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY dea.location, dea.date
```
![Analysis7](https://user-images.githubusercontent.com/32184014/204606265-df22f14b-7e5e-4f7b-92c1-61613a7ddca5.png)


Using CTE to perform calculation on Partition By in previous query
```sql
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
```
![Analysis7_CTE](https://user-images.githubusercontent.com/32184014/204606745-68eff4a4-fb96-4fde-81e8-7388e71f6353.png)


Using Temp Table to perform calculation on Partition By in previous query
```sql
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
```
![Analysis7_temp_table](https://user-images.githubusercontent.com/32184014/204607063-00798d4c-4a77-4b93-ae08-6f81d701f727.png)


## Tableau
[Covid-19 Dashboard](https://public.tableau.com/app/profile/ivan.wei.ket.yap/viz/CovidDashboard2019-2022_16690006558760/Dashboard1)

![Covid-19 Dashboard](https://user-images.githubusercontent.com/32184014/204609180-24f6c751-39ee-4ace-9bed-851c4b24947d.png)

***
