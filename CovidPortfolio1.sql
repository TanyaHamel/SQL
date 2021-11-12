--Basic Analysis
--AlexTheAnalyst on YouTube

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Total Deaths in the world, ordered by location and date
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_ercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Total Cases vs Total Deaths in Australia, ordered by date
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location = 'Australia'
ORDER BY 2

-- Total Cases vs Population in the world, ordered by location and date
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_pop_percentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Total Cases vs Population in Australia, ordered by date
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_pop_percentage
FROM CovidDeaths
WHERE location = 'Australia'
ORDER BY 2

--Countries with highest infection count compared to populatio
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS infected_pop_percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY infected_pop_percentage DESC

--Countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY tOtal_death_count DESC

--Continents with highest death count per population

--this is the right answer, but the way to get it is wrong (data is pooched a bit)
--SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
--FROM CovidDeaths
--WHERE continent is null
--GROUP BY location
--ORDER BY TotalDeathCount DESC

--this is the right answer to get the death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC


--Global numbers
SELECT date, SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths as int)) AS total_new_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

--Total population vs Vaccinations per day
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations
From CovidDeaths AS Death
Join CovidVaccinations AS Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent is not null
ORDER BY 2,3

--Total population vs Vaccinations rolling totals
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations,
SUM(CONVERT(bigint, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinated
From CovidDeaths AS Death
Join CovidVaccinations AS Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent is not null
ORDER BY 2,3


--Rolling people vaccinated ratio
DROP TABLE if exists #PercentagePopVaxxed
CREATE Table #PerecentPopVaxxed
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinated numeric)

Insert into #PerecentPopVaxxed
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations,
SUM(CONVERT(bigint, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rolling_vaccinated
From CovidDeaths AS Death
Join CovidVaccinations AS Vax
ON Death.location = Vax.location
and Death.date = Vax.date
WHERE Death.continent is not null

SELECT *, (rolling_vaccinated/population)*100 AS percent_pop_vaxxed
From #PerecentPopVaxxed
