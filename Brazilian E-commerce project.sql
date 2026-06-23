
--1.) REVENUE ANALYSIS

--a.) Revenue by State 
--> Identifies states generating the highest revenue

select customer_state, round(sum(price),2) as State_Revenue 
from customers c 
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id 
group by customer_state 
order by State_Revenue desc

--b.) Revenue by Product Category 
--> Identifies Product Category generating the highest revenue

select product_category_name,round(sum(price), 2) as Revenue
from products p
join order_items oi on p.product_id = oi.product_id
group by product_category_name
order by Revenue desc

--c.) Monthly Revenue Trend
--> Data from the year 2017 and 2018 is used due to lack of suffiecient data from the year 2016.

select distinct month(order_purchase_timestamp) as Months, round(sum(price), 2) as Monthly_Revenue 
from orders o 
join order_items oi on o.order_id = oi.order_id
where order_status = 'delivered'
group by month(order_purchase_timestamp)
order by Months 

--2.) CUSTOMER ANALYSIS

--a.) Customer Retention
--> A customer is only considered a Repeat customer when they've order more than once and on different dates

with customer_retention as (
select customer_unique_id, 
count(distinct cast(order_purchase_timestamp as date)) as purchase_days
from customers c
join orders o on c.customer_id = o.customer_id 
where order_status = 'delivered'
group by customer_unique_id)
select 
sum(case when purchase_days = 1 then 1 else 0 end) as One_time_customer,
sum(case when purchase_days > 1 then 1 else 0 end) as Repeat_customer,
round(sum(case when purchase_days > 1 then 1 else 0 end)*100.0/count(*), 2) as Retention_rate
from customer_retention

--b.) Repeat vs One-Time Customers

with cte as (
select customer_unique_id, 
count(distinct cast(order_purchase_timestamp as date)) purchase_count
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on oi.order_id = o.order_id
where order_status = 'delivered'
group by customer_unique_id)
select 
case when purchase_count = 1 then 'One-time customer' else 'Repeat Customer' end as Customer_type,
count(*) as total_customers,
round(count(*) * 100.0 / (select count(*) from cte), 2) as percentage
from cte
group by 
case 
when purchase_count = 1 then 'One-time customer' else 'Repeat Customer' end

--c.) Top Customers
--> Identifies customers generating the highest revenue 

select customer_unique_id, round(sum(price),2) as Revenue
from customers c 
join orders o on c.customer_id = o.customer_id 
join order_items oi on o.order_id = oi.order_id
where order_status = 'delivered'
group by customer_unique_id order by Revenue desc

--3.) PRODUCT ANALYSIS

--a.) Category Popularity vs Profitability 
--> Compares the number of orders (popularity) and revenue generated (profitability) across product categories

select product_category_name, count(oi.order_id) as Popularity, round(sum(price),2) as Profitability
from products p 
join order_items oi on p.product_id = oi.product_id
join orders o on o.order_id = oi.order_id
where order_status = 'delivered' and product_category_name is not null
group by product_category_name order by profitability desc

--b.) Pareto Analysis 
--> Identifies the categories responsible for the majority of total revenue using the Pareto principle

with category_analysis as (
select product_category_name, round(sum(price),2) as revenue
from products p 
join order_items oi on p.product_id = oi.product_id
join orders o on o.order_id = oi.order_id
where order_status = 'delivered' and product_category_name is not null
group by product_category_name
)
select product_category_name, revenue, sum(revenue) over(order by revenue desc) as cumulative_revenue,
sum(revenue) over(order by revenue desc) * 100.0 / sum(revenue) over() as cumulative_percentage 
from category_analysis order by revenue desc

--4.) OPERATIONS ANALYSIS
   
--a.)  Order Status Analysis
--> Identifies the distribution of orders from different order statuses

select order_status, count(*) as total, round(count(*)*100.0/(select count(*) from orders),2) as percentage 
from orders
group by order_status order by total desc

--b.) Delivery Performance Analysis
--> Identifies the number and percentage of deliveries which were on time and late

select
case when order_delivered_customer_date <= order_estimated_delivery_date then 'on-time deliveries'
else 'late deliveries' end as delivery_status,
count(*) as total_orders,
round(count(*) * 100.0 / (select count(*) from orders where order_status = 'delivered'),2) as percentage
from orders
where order_status = 'delivered'
group by
case when order_delivered_customer_date <= order_estimated_delivery_date then 'on-time deliveries'
else 'late deliveries' end
order by percentage desc;

