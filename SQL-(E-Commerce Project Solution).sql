

/*
Introduction

-	You can benefit from the ERD diagram given to you during your work.
-	You have to create a database and import into the given csv files. 
-	During the import process, you will need to adjust the date columns. You need to carefully observe the data types and how they should be.In our database, a star model will be created with one fact table and four dimention tables.
-	The data are not very clean and fully normalized. However, they don't prevent you from performing the given tasks. In some cases you may need to use the string, window, system or date functions.
-	There may be situations where you need to update the tables.
-	Manually verify the accuracy of your analysis.



Analyze the data by finding the answers to the questions below:

1.	Join all the tables and create a new table with all of the columns, called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
2.	Find the top 3 customers who have the maximum count of orders.
3.	Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
4.	Find the customer whose order took the maximum time to get delivered.
5.	Retrieve total sales made by each product from the data (use Window function)
6.	Retrieve total profit made from each product from the data (use windows function)
7.	Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

*/




-- DATA ANALYSIS

--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)


select * 
INTO combined_table
FROM
(
select 
cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, mf.Ord_id, 
mf.Prod_id, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Profit, mf.Shipping_Cost, mf.Product_Base_Margin,
od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category,
sd.Ship_id, sd.Ship_Mode, sd.Ship_Date
from market_fact mf 
inner join cust_dimen cd on mf.Cust_id = cd.Cust_id
inner join orders_dimen od on od.Ord_id = mf.Ord_id
inner join prod_dimen pd on pd.Prod_id = mf.Prod_id
inner join shipping_dimen sd on sd.Ship_id = mf.Ship_id
) a









select * from [dbo].[cust_dimen];


select * from [dbo].[shipping_dimen];



select * from [dbo].[orders_dimen];


select * from [dbo].[prod_dimen]




update  [dbo].[prod_dimen]
set prod_id='Prod_16' where Prod_id= ' RULERS AND TRIMMERS,Prod_16'

---------------------------------- DATA TYPE FÝXÝNG 
	exec sp_help Customer_test1
	alter table Customer_test1 alter column Order_Quantity int
	alter table Customer_test1 alter column Profit Money
	
	alter table Customer_test1 alter column Shipping_Cost Decimal(10,2)
	alter table Customer_test1 alter column Discount decimal(2,2)
	alter table Customer_test1 alter column Product_Base_Margin decimal
	alter table Customer_test1 alter column Sales decimal(10,2)

	

	UPDATE Customer_test1 SET Product_Base_Margin = REPLACE(Product_Base_Margin,'NA','0.00') 
	----- order_date
	UPDATE Customer_test1 SET Order_Date = CONVERT(DATETIME,Order_Date ,105)

    alter table Customer_test1 alter column Order_Date DATETIME
	
-- ship_date
	
	UPDATE Customer_test1 SET Ship_Date = CONVERT(DATETIME,Ship_Date ,105) 
	alter table Customer_test1  alter column Ship_Date  DATETIME


--2. Find the top 3 customers who have the maximum count of orders.

select top(3) c.cust_id, c.customer_name, count(distinct Ord_id) as number_of_orders 
from 
cust_dimen c 
inner join market_fact mf 
on c.cust_id = mf.cust_id
group by c.cust_id, c.customer_name 
order by number_of_orders desc; 



select top(3) cust_id, customer_name, count (distinct ord_id) num
from
[dbo].[Customer_test1] 
group by
cust_id, customer_name
order by num desc



--3.3.	Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

alter table  [dbo].[Customer_test1]
add  DaysTakenForDelivery int;

update Customer_test1
set DaysTakenForDelivery =  datediff(day,  order_date,  ship_date)  ;


SELECT *
FROM [dbo].[Customer_test1]




--4. Find the customer whose order took the maximum time to get delivered.

select Cust_id, Customer_Name, Order_Date, Ship_Date, DaysTakenForDelivery 
from [dbo].[Customer_test1]
where DaysTakenForDelivery in
							(
							select max(DaysTakenForDelivery) 
							from [dbo].[Customer_test1]
							);




--5. Retrieve total sales made by each product from the data (use Window function)


select distinct Prod_id,  sum(Sales) over (partition by prod_id)
from
market_fact;


select distinct  convert(tinyint ,replace(Prod_id,'Prod_','')) as prod_id,  sum(Sales) over (partition by prod_id)
from
[dbo].[Customer_test1]
order by prod_id
	




--6. Retrieve total profit made from each product from the data (use windows function)

select distinct Prod_id, sum(convert(money,Profit)) over (partition by Prod_id) as total_profit 
from market_fact
order by
total_profit desc







--7. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

select count(distinct Cust_id) as unique_customers
from [dbo].[Customer_test1] where year(Order_Date) = 2011 AND month(Order_Date) = 01;


SELECT distinct
Year(Order_date) AS [YEAR], 
Month(Order_date) AS [MONTH], 
count( Cust_id) OVER (PARTITION BY month(Order_date) order by month(Order_date)) ASTotal_Unique_Customers 
FROM [dbo].[Customer_test1]
WHERE year(Order_Date)=2011 
AND Cust_id IN 
			(
			SELECT DISTINCT Cust_id 
			FROM [dbo].[Customer_test1]
			WHERE  month(Order_Date) = 01 and year(Order_Date) = 2011
			);



--CUSTOMER RETENTION ANALYSIS



/*
Find month-by-month customer retention rate  since the start of the business (using views).

1.	Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple years since whenever business started operations.
2.	Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
3.	Calculate the time gaps between visits.
4.	Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.
5.	Calculate the retention month wise
*/




--1. Create a view where each user’s visits are logged by month, 
--	allowing for the possibility that these will have occurred over multiple years since whenever business started operations.


create view user_visit as
select cust_id, Count_in_month, convert (date , month + '-01') Month_date
from
(
select  cust_id, SUBSTRING(cast(order_date as varchar), 1,7) as [Month], COUNT(*) as Count_in_month 
from Customer_test1 
group by cust_id, SUBSTRING(cast(order_date as varchar), 1,7)
) a;



select *
from [dbo].[user_visit] ;


select  [Cust_id] , count(month(Order_Date)) order_quantity,month(Order_Date) [month],year(Order_Date) [year],Order_Date
from [dbo].[Customer_test1]
--where [Customer_Name] = 'AARON BERGMAN'
group by [Cust_id] ,month(Order_Date), year(Order_Date) ,Order_Date
order by Cust_id, 4

----	Q1 SOLUTÝON WÝTH LAG
select  [Cust_id],count(month(Order_Date)) order_quantity,month(Order_Date) [month],year(Order_Date) [year], 
  lag(Order_Date) over (partition by Cust_id order by Order_Date) [current_date], Order_Date [next_date],
  datediff (day  , lag(Order_Date) over (partition by Cust_id order by Order_Date),Order_Date) difference_each_visit
from [dbo].[Customer_test1]
group by [Cust_id] ,month(Order_Date), year(Order_Date) ,Order_Date


----- Q1 SOLUTÝON WÝTH LEAD
-- identify time lapse each visit
create view gap_between_order 
as(
select  [Cust_id],count(month(Order_Date)) order_quantity,month(Order_Date) [month],Order_Date [previous_date], 
  lead(Order_Date) over (partition by Cust_id order by Order_Date) [next_date]
  from [dbo].[Customer_test1]
  group by [Cust_id] ,month(Order_Date),Order_Date)

  select * from gap_between_order

  select * from gap_between_order


--3. Calculate the time gaps between visits.

create view  time_gap_vw as 
select *, datediff ( month, previous_date, next_date) as Time_gap 
from gap_between_order;



  select * from time_gap_vw














select * from time_lapse_vw;
    



--3. Calculate the time gaps between visits.

create view  time_gap_vw as 
select *, datediff ( month, Month_date, Next_month_Visit) as Time_gap 
from time_lapse_vw;







--4. Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

create view Customer_value_vw as 

select distinct cust_id, Average_time_gap,
case 
	when Average_time_gap<=1 then 'Retained'
    when Average_time_gap>1 then 'Irregular'
    when Average_time_gap is null then 'Churned'
    else 'Unknown data'
end  as  Customer_Value
from 
(
select cust_id, avg(time_gap) over(partition by cust_id) as Average_time_gap
from time_gap_vw
)a;



select * from customer_value_vw;



select * from time_gap_vw
where
cust_id='Cust_1288';


select next_date , sum(Time_gap) from time_gap_vw
group by next_date
order by next_date

select next_date , Time_gap from time_gap_vw
where next_date = '2009-01-07 00:00:00'
--5. Calculate the retention month wise.




select distinct next_date as Retention_month,

sum(time_gap) over (partition by next_date) as Retention_Sum_monthly

from time_gap_vw 
order by Retention_month
--------------------------------

select distinct next_date as Retention_month,
sum(time_gap) over (partition by next_date) as Retention_Sum_monthly
from time_gap_vw 
where time_gap<=1
order by Retention_Sum_monthly desc





select * from retention_vw;



---1. Find the customers who placed at least two orders per year.

select Cust_id,Customer_Name,count(Order_Date) as order_quantity,year(Order_Date) [year]
from Customer_test1
group by year(Order_Date),Cust_id,Customer_Name
having count(Order_Date) >=2


