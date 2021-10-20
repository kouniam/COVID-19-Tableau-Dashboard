/*
Queries used for Tableau Project
*/


-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
From COVIDProject..covid_deaths
where continent is not null 
--Group By date
order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From COVIDProject..covid_deaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


-- 3.

Select location, Population, MAX(total_cases) as peak_infection_count,  Max((total_cases/population))*100 as percentage_population_infected
From COVIDProject..covid_deaths
--Where location like '%states%'
Group by location, Population
order by percentage_population_infected desc


-- 4.


Select location, Population,date, MAX(total_cases) as peak_infection_count,  Max((total_cases/population))*100 as percentage_population_infected
From COVIDProject..covid_deaths
--Where location like '%states%'
Group by location, Population, date
order by percentage_population_infected desc



-- Queries I originally had, but excluded some because it created too long of video
-- Here only in case you want to check them out


-- 1.

Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as commulative_vaccinations
--, (commulative_vaccinations/population)*100
From COVIDProject..covid_deaths dea
Join COVIDProject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
order by 1,2,3




-- took the above query and added population
Select location, date, population, total_cases, total_deaths
From COVIDProject..covid_deaths
--Where location like '%states%'
where continent is not null 
order by 1,2


-- 6. 


With PopvsVac (Continent, location, Date, Population, New_Vaccinations, commulative_vaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as commulative_vaccinations
--, (commulative_vaccinations/population)*100
From COVIDProject..covid_deaths dea
Join COVIDProject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (commulative_vaccinations/Population)*100 as PercentPeopleVaccinated
From PopvsVac
