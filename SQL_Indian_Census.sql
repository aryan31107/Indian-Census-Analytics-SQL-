select * from project.dbo.Dataset1;
select * from project.dbo.Dataset2;
--------------------------------------------------------------------------------------------
-- Number or rows into our dataset
select count(*) from project..Dataset1;
select count(*) from project..Dataset2;
-------------------------------------------------------------------------------------------
-- dataset for Jharkhand and Bihar
select * from project..Dataset1 where State in ('Jharkhand' , 'Bihar');
---------------------------------------------------------------------------------------------
-- Population of India
select sum(Population) Population from project..Dataset2;
---------------------------------------------------------------------------------------------
-- Average growth in %
-- select avg(Growth)*100 Avg_Growth from project..Dataset1;
SELECT 
  AVG(CAST(REPLACE(Growth, '%', '') AS FLOAT)) AS Avg_Growth
FROM project..Dataset1;
---------------------------------------------------------------------------------------------
--Average growth % by state
select State, AVG(CAST(REPLACE(Growth, '%', '') AS FLOAT)) AS Avg_Growth from project..Dataset1 group by State;
------------------------------------------------------------------------------------------------------------------------------
-- Average sex ratio by state
select State, round(avg(Sex_Ratio),0) avg_sex_ratio from project..Dataset1 group by state order by avg_sex_ratio desc;
------------------------------------------------------------------------------------------------------------------------------
-- avg Literacy rate by state 
select state, round(avg(literacy),0) avg_literacy_ratio from project..Dataset1 
group by state order by avg_literacy_ratio desc ;
----------------------------------------------------------------------------------------------
-- States having average literacy ratio > 90
select state, round(avg(literacy),0) avg_literacy_ratio from project..Dataset1 
group by state  having round(avg(literacy),0)>90 order by avg_literacy_ratio desc ;
-------------------------------------------------------------------------------------------------
-- Top 3 states showing highest growth ratio
select top 3 state, AVG(CAST(REPLACE(Growth, '%', '') AS FLOAT)) AS Avg_Growth from project..Dataset1 group by state order by Avg_Growth desc;

--OR
--select state, AVG(CAST(REPLACE(Growth, '%', '') AS FLOAT)) AS Avg_Growth from project..Dataset1 group by state order by Avg_Growth desc limit 3;
---------------------------------------------------------------------------------------------------------------------------------------------------------
--bottom 3 state showing lowest sex ratio
select top 3 state,round(avg(sex_ratio),0) avg_sex_ratio from project..Dataset1 group by state order by avg_sex_ratio asc;

-- top and bottom 3 states in literacy state
drop table if exists #topstates;
create table #topstates
( state nvarchar(50),
  topstate float

  )

insert into #topstates
select state,round(avg(literacy),0) avg_literacy_ratio from project..Dataset1
group by state order by avg_literacy_ratio desc;

select top 3 * from #topstates order by #topstates.topstate desc;

drop table if exists #bottomstates;
create table #bottomstates
( state nvarchar(50),
  bottomstate float

  )

insert into #bottomstates
select state,round(avg(literacy),0) avg_literacy_ratio from project..Dataset1
group by state order by avg_literacy_ratio desc;

select top 3 * from #bottomstates order by #bottomstates.bottomstate asc;

--union opertor

select * from (
select top 3 * from #topstates order by #topstates.topstate desc) a

union

select * from (
select top 3 * from #bottomstates order by #bottomstates.bottomstate asc) b;
---------------------------------------------------------------------------------------------
-- States starting with letter a or b
select distinct state from project..Dataset1 where lower(state) like 'a%' or lower(state) like 'b%'
----------------------------------------------------------------------------------------------------------
-- States starting with letter a or ending with letter d
select distinct state from project..Dataset1 where lower(state) like 'a%' or lower(state) like '%d'
----------------------------------------------------------------------------------------------------------
-- States starting with letter a and ending with letter m
select distinct state from project..Dataset1 where lower(state) like 'a%' and lower(state) like '%m'
-----------------------------------------------------------------------------------------------------------
-- Joining both table
--select a.district, a.state, a.sex_ratio, b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district;

ALTER TABLE project..Dataset1
ALTER COLUMN Sex_Ratio FLOAT;

-- Total males and females

--female/males=sex_ratio -------------- 1
--female + males = population --------- 2
--female = population - males --------- 3
--female ->
--(population-males)=(sex_ratio)*males
--population=males(sex_ratio+1)
--males=population/(sex_ratio+1) ------------------- males
--females=population-population/(sex_ratio+1)------- females from 3
--       =population(1-1/(sex_ratio+1))
--       =(population*(sex_ratio))/(sex_ratio+1)

select d.state,sum(d.males) total_males,sum(d.females) total_females from
(select c.district,c.state state,round(c.population/(c.sex_ratio+1),0) males, round((c.population*c.sex_ratio)/(c.sex_ratio+1),0) females from
(select a.district,a.state,a.sex_ratio/1000 sex_ratio, b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district ) c) d
group by d.state;
--------------------------------------------------------------------------------------
--Literacy rate = % of population which can either read or write

--total literte people/population = literacy_ratio ------- 1
--total literte people = literacy_ratio*population 
--total ill-literte people = (1-literacy_ratio)*population 

select c.state,sum(literate_people) total_literate_pop,sum(illiterate_people) total_lliterate_pop from 
(select d.district,d.state,round(d.literacy_ratio*d.population,0) literate_people, round((1-d.literacy_ratio)* d.population,0) illiterate_people from
(select a.district,a.state,a.literacy/100 literacy_ratio,b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district) d) c
group by c.state
------------------------------------------------------------------------------------
--Population in previous census

--previous_census + growth*previous_census = population
--previous_census = population / (1+growth)

select e.state,sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,d.population current_census_population from
(select a.district,a.state,CAST(REPLACE(a.Growth, '%', '') AS FLOAT) growth,b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district) d) e
group by e.state

--Total population of india in previous census and current census
select sum(m.previous_census_population) previous_census_population,sum(m.current_census_population) current_census_population from(
select e.state,sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,d.population current_census_population from
(select a.district,a.state,CAST(REPLACE(a.Growth, '%', '') AS FLOAT) growth,b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district) d) e
group by e.state)m
----------------------------------------------------------------------------------------
--How much area per population has been reduced? (because population is increasing but area is same) So we would need area and population from previous census and current census

-- population vs area

SELECT *
FROM project..Dataset2
WHERE TRY_CAST(Area_km2 AS FLOAT) IS NULL AND Area_km2 IS NOT NULL;

UPDATE project..Dataset2
SET Area_km2 = REPLACE(Area_km2, ',', '');

ALTER TABLE project..Dataset2
ALTER COLUMN Area_km2 FLOAT;




select (g.total_area/g.previous_census_population)  as previous_census_population_vs_area, (g.total_area/g.current_census_population) as 
current_census_population_vs_area from
(select q.*,r.total_area from (

select '1' as keyy,n.* from
(select sum(m.previous_census_population) previous_census_population,sum(m.current_census_population) current_census_population from(
select e.state,sum(e.previous_census_population) previous_census_population,sum(e.current_census_population) current_census_population from
(select d.district,d.state,round(d.population/(1+d.growth),0) previous_census_population,d.population current_census_population from
(select a.district,a.state,CAST(REPLACE(a.Growth, '%', '') AS FLOAT) growth,b.population from project..Dataset1 a inner join project..Dataset2 b on a.district=b.district) d) e
group by e.state)m) n) q inner join (

select '1' as keyy,z.* from (
select sum(area_km2) total_area from project..Dataset2)z) r on q.keyy=r.keyy)g
------------------------------------------------------------------------------------------------
--window function

--output top 3 districts from each state with highest literacy rate


select a.* from
(select district,state,literacy,rank() over(partition by state order by literacy desc) rnk from project..Dataset1) a

where a.rnk in (1,2,3) order by state







