select  * from [DeathsPerCapita(1)] order by validctrys DESC
select * from [SDamerican_deaths_abroad] order by country asc
select  * from [TravelAfterWarning] order by travelcountries DESC
select * from [WarningsRanking]

-- At first to answer the questions they were asking, we thought we would exclude the Suicide death motive because in our view it was an invalid cause for our analysis.
-- Because we cannot say that a country is risky for tourists because of the number of suicides.

-- Step 1:
-- Recalculation of precapite after removing suicide and recalculating the number of travelers per state with data from the BTS Origin table.

with ctea
as
(
select country, count(cause_of_death) as N_deaths from [SDamerican_deaths_abroad]
where cause_of_death != 'Suicide'
group by 
country
)
,
cteb as
(
select sum(PASSENGERS)as N_Travelers, Description  from BTSOriginUS a
inner join BTSCountryCodes b
on b.Code = a.DEST_COUNTRY
group by Description
)
select country, N_deaths, N_Travelers
, (convert(decimal(10,2),(cast(N_deaths as decimal)/N_Travelers)*100000)) as Percapite
INTO Percapite
from ctea a
inner join cteb b
on a.country = b.Description
where N_Travelers != 0 and N_Travelers > 1000
order by Percapite DESC

select * from Percapite
order by Percapite DESC

----------------------------------------------------------------------------------------------

-- Step 2:

--alter table [WarningsRanking] drop column column1
-- integration of the tables to then compare the number of reports with actual deaths and the per capita death per 100k people.

select a.Country, a.Region, b.N_Travelers, a.N_Warnings, b.N_deaths, b.Percapite from [WarningsRanking] a
inner join Percapite b
on a.country = b.Country
order by a.N_Warnings desc

--Using this table thanks to the order by N_Warnings, we can see that the reports do not necessarily depend on the per capita
--Given this, it can be seen that reports do not depend only on the number of deaths

------------------------------------------------------------------------------------------------

--Here we report total deaths by filtering out only unambiguous causes of killings so as to see which country is actually at risk of homicide.
--Note: Although we can see the most dangerous countries only some of them have a consistent number of reports while others have 0.


with ctec
as
(
select country, count(cause_of_death) as N_kills from [SDamerican_deaths_abroad]
where cause_of_death = 'Execution' or cause_of_death = 'Homicide' or cause_of_death = 'Hostage-related' or cause_of_death = 'Terrorist Action'
group by country 
),
cted as
(
select country, N_Travelers, N_deaths from Percapite
)
select a.country, a.N_kills, (convert(decimal(10,2),(cast(a.N_kills as decimal)/N_Travelers)*100000)) as Killings_Percapite, b.N_Travelers, d.N_Warnings
INTO dangerous_countries
from ctec a
inner join cted b
on a.country = b.country
inner join [WarningsRanking] d
on d.Country = b.country
order by N_kills desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

select * from dangerous_countries
where N_Warnings >= 7
order by N_kills desc

-- In conclusion, it is clear that, excluding countries with an excessive number of mortalities compared to the average, the majority of reports do not depend on deaths but on other external factors.