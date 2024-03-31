-- Create Database
IF NOT EXISTS (SELECT name from master.sys.databases where name = 'HR_db')
create database HR_db;

use HR_db;
select * from HR;

-- Fixing column termdate format
update hr
	set termdate = FORMAT(CONVERT(DATETIME, left(termdate, 19), 120), 'yyyy-MM-dd');

alter table hr
	add new_termdate date;


update hr
	set new_termdate = case 
		when termdate is not null and isdate(termdate)=1 
		then cast(termdate as date)
		else null end;

alter table hr
drop column termdate;

EXEC sp_rename 'hr.new_termdate', 'termdate', 'COLUMN';

select termdate from hr;

-- create age column
alter table hr
add age nvarchar(50);

update hr
	set age = DATEDIFF(year, birthdate, getdate());

SELECT  
	age
FROM hr
ORDER BY age desc;

------------------------ Data's  Questions ------------------------

-- Age distribution of the company
select 
	ages, 
	count(*) as count 
from(
	select 
		case
			when age between 21 and 30 then '21-30'
			when age between 31 and 40 then '31-40'
			when age between 41 and 50 then '41-50'
			else '50+' end as ages
	from hr
	where termdate is null) as groups
group by ages
order by ages;

-- Age distribution by gender
select 
	gender,
	ages, 
	count(gender) as count 
from(
	select
		gender,
		case
			when age between 21 and 30 then '21-30'
			when age between 31 and 40 then '31-40'
			when age between 41 and 50 then '41-50'
			else '50+' end as ages
	from hr
	where termdate is null) as groups
group by ages, gender
order by ages;

-- Company distribution by gender 
select 
	gender,
	count(1) as total
from hr
where termdate is null
group by gender
order by total desc;

-- Gender variation across departments and job titles
select 
	department,
	jobtitle,
	gender,
	count(*) as total
from hr
where termdate is null
group by gender, department, jobtitle
order by total desc;

--Company distribution by race
select race,
 count(*) as total
from hr
Where termdate is null
group by race
order by total desc;

--Average length of employment in the company
select 
	avg(datediff(year,hire_date,termdate)) as average
from hr
where termdate is not null and termdate <= getdate();

-- Turn over rate 
SELECT
	department,
	total_count,
	terminated_count,
	round(CAST(terminated_count as float)/total_count, 2) as turn_over_rate
from 
   (SELECT
	   department,
	   count(*) as total_count,
	   sum(case
			when termdate is not null and termdate <= getdate() then 1 else 0 end) as terminated_count
   from hr
   group by department) as Subquery
order by turn_over_rate desc;

--Tenure distribution for each department
select 
	department,
	avg(datediff(year,hire_date,termdate)) as avg_distribution
from hr 
where termdate is not null and termdate <= getdate()
group by department;


--Employees that work remotely for each department
select 
	department,
	count(1) as count_remote_wokers
from hr
where location like 'remote' 
group by department
order by 2 desc


-- Distribution of employees across different states
select
	location_state,
	count(*) as total
from hr
where termdate is null
group by location_state
order by total desc;


-- Job titles distributed in the company
select
	jobtitle,
	count(*) as total
from hr
where termdate is null
group by jobtitle
order by total desc;


-- Employee hire counts varied over time
select
    hire_yr,
    hires,
    terminations,
    hires - terminations as net_change,
    (round(CAST(hires - terminations as float) / NULLIF(hires, 0), 2))*100 as percent_hire_change
from 
    (select
        year(hire_date) as hire_yr,
        count(*) as hires,
        sum(case when termdate is not null and termdate <= GETDATE() then 1 else 0 end) terminations
    from hr
    group by YEAR(hire_date)) as subquery
order by hire_yr asc;

