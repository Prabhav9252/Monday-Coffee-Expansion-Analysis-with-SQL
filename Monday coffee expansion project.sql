
-- Monday Coffee Expansion Analysis

-- Objective
/* The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling
its products online since January 2023, and to recommend the top three major cities in India for opening
new coffee shop locations based on consumer demand and sales performance. */
select * from city;


/* QUESTION 1
Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does? */

select city_name,round((population*0.25),3) as consumers_in_millions,city_rank
from city
order by population desc;

/* Question 2
Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
*/
-- we also get each city's revenue
select city_name, sum(total) as total_revenue from sales as s inner join customers as cs on s.customer_id=cs.customer_id
join city as c on c.city_id=cs.city_id
where DATEPART(quarter,sale_date) = 4 and DATEPART(year,sale_date)=2023
group by city_name
order by total_revenue desc;

/* Question 3
Sales Count for Each Product
How many units of each coffee product have been sold? */
-- here we do left join from products to sales to get all product names
select product_name,count(s.product_id) as no_of_units_sold from products p left join sales s on s.product_id=p.product_id
group by product_name;

/* Question 4
Average Sales Amount per City
What is the average sales amount per customer in each city? */
with cte as (
select city_name,
sum(total) as total_sales
,count(distinct cs.customer_id) as no_of_customers
from city c left join customers cs 
on c.city_id=cs.city_id
left join sales s on
s.customer_id=cs.customer_id
group by city_name)
select city_name,total_sales,
round(total_sales*1.0/no_of_customers,2) as avg_sales_per_cx
from cte
order by avg_sales_per_cx desc

-- here we first find total sales for each city and then we get a count of distinct customers for that city
-- then we divide that total sales by count to get the desired for each city

/* Question 5
City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers. */
-- return city name, current cx,estimated coffee consumers(25%)

select city_name,round(population*0.25/1000000,2) as coffee_consumers,count(distinct c.customer_id) as current_cx
from city ci
left join customers c on ci.city_id=c.city_id
group by city_name,population
order by coffee_consumers desc;

/* Question 6
Top Selling Products by City
What are the top 3 selling products in each city based on sales volume? */
with cte as (
select 
ci.city_name,
p.product_name,
count(s.sale_id) as total_orders,
dense_rank() over (partition by city_name order by count(s.sale_id) desc) as rn
from sales as s join products p
on s.product_id=p.product_id
join customers cs on cs.customer_id=s.customer_id
join city ci on cs.city_id=ci.city_id
group by ci.city_name,p.product_name
)
select city_name,product_name,total_orders
from cte
where rn <=3

/* Question 7
Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products? */
--- who purchased

select city_name,count(distinct cs.customer_id) as unique_customers from city ci
left join customers cs on ci.city_id=cs.city_id
join sales s on s.customer_id=cs.customer_id
join products p on p.product_id=s.product_id
where s.product_id <=14
group by city_name;

/* Question 8
Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer */
-- conclusions

with city_summary as (
    select 
        c.city_name,
        sum(s.total) as total_sales,
        count(distinct cs.customer_id) as no_of_customers,
        sum(s.total) * 1.0 / count(distinct cs.customer_id) as avg_sales_per_cx,
        c.estimated_rent
    from city c
    left join customers cs on c.city_id = cs.city_id
    join sales s on s.customer_id = cs.customer_id
    group by c.city_name, c.estimated_rent, c.population
)
select 
    city_name,
    total_sales as total_revenue,
    estimated_rent as total_rent,
    no_of_customers,
    avg_sales_per_cx,
    estimated_rent * 1.0 / no_of_customers as avg_rent_per_cx
from city_summary
order by total_sales desc

/* Question 9
Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly). */
-- by each city,each month sales
with monthly_sales as (
    select 
        ci.city_name,
        year(s.sale_date) as year,
        datepart(month, s.sale_date) as month_name,
        sum(s.total) as total_sales,
        lag(sum(s.total)) over (partition by ci.city_name order by year(s.sale_date), datepart(month, s.sale_date)) as last_month_sales
    from sales s
    join customers cs on s.customer_id = cs.customer_id
    join city ci on ci.city_id = cs.city_id
    group by ci.city_name, year(s.sale_date), datepart(month, s.sale_date)
)
select 
    city_name,
    year,
    month_name,
    total_sales,
    last_month_sales,
    (total_sales - last_month_sales) * 100.0 / last_month_sales as growth_ratio
from monthly_sales
where last_month_sales is not null
order by city_name, year, month_name;

/* Question 10
Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer */

with city_summary as (
    select 
        c.city_name,
        sum(s.total) as total_sales,
        count(distinct cs.customer_id) as no_of_customers,
        sum(s.total) * 1.0 / count(distinct cs.customer_id) as avg_sales_per_cx,
        c.estimated_rent,
        c.population * 0.25 / 1000000 as est_coffee_consumer
    from city c
    left join customers cs on c.city_id = cs.city_id
    join sales s on s.customer_id = cs.customer_id
    group by c.city_name, c.estimated_rent, c.population
)
select 
    city_name,
    total_sales as total_revenue,
    estimated_rent as total_rent,
    no_of_customers,
    est_coffee_consumer,
    avg_sales_per_cx,
    estimated_rent * 1.0 / no_of_customers as avg_rent_per_cx
from city_summary
order by total_sales desc

/* 
After analyzing the data, the recommended top three cities for new store openings are:

City 1: Pune

Average rent per customer is very low.
Highest total revenue.
Average sales per customer is also high.

City 2: Delhi

Highest estimated coffee consumers at 7.7 million.
Highest total number of customers, which is 68.
Average rent per customer is 330 (still under 500).

City 3: Jaipur

Highest number of customers, which is 69.
Average rent per customer is very low at 156.
Average sales per customer is better at 11.6k. */
