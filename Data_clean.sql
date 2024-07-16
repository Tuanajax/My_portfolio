/****** Script for SelectTopNRows command from SSMS  ******/
-----standardize Data format---------
-----add @issuedateconverted as date
------update financial_loan$
------set @issue_date_converted = CONVERT(date, issue_date)

Select * from dbo.financial_loan$
alter table financial_loan$
alter column issue_date date last_payment_date date

alter table financial_loan$
alter column dti float

/*Handling missing data*/


with CTE as (select a.address_state, a.emp_length, avg(a.annual_income) avg_income from dbo.financial_loan$ a
group by a.address_state, a.emp_length)
select * from dbo.financial_loan$ a
join CTE b on a.address_state = b.address_state and a.emp_length = b.emp_length and a.annual_income is null

select sum(case when a.annual_income is null then 1 else 0 end) from dbo.financial_loan$ a
select * from dbo.financial_loan$ a
where a.annual_income is null

select distinct(a.address_state) from dbo.financial_loan$ a
join dbo.financial_loan$ b on a.id = b.id


----Dealing duplicated record------
select distinct* from dbo.financial_loan$
---------Dealing missing value--------

select address_state, len(address_state)from dbo.financial_loan$
group by address_state
having len(address_state) > 2

select home_ownership, count(home_ownership)from dbo.financial_loan$ 
group by home_ownership
select * from dbo.financial_loan$
update financial_loan$
set home_ownership = REPLACE(home_ownership,'none','other')


alter table dbo.financial_loan$
add annual_icome float

update financial_loan$
set annual_icome = annual_income 

 


