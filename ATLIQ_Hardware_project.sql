/* Q1: List of markets in which customer "Atliq Exclusive" operates in "APAC Region".*/

select market
from dim_customer
where customer = 'Atliq Exclusive'
and region = 'APAC'
order by 1;

/* Q2: Percentage of unique product increase in 2020 vs 2021.*/

with cte1 as(
select(select count(distinct p.product) 
from dim_product p join fact_act_est f
using(product_code) 
where f.fiscal_year = '2020')as unique_products_2020,
(select count(distinct p.product) 
from dim_product p join fact_act_est f
using(product_code) 
where f.fiscal_year = '2021')as unique_products_2021)
select unique_products_2020,unique_products_2021,
concat(round((unique_products_2021- unique_products_2020)*100.0/(unique_products_2020),2),'%')
AS percentage_change
from cte1;

/* Q3: How many unique products does each segment have?*/

select segment,count(distinct product_code) as num_products
from dim_product 
group by segment 
order by num_products desc;

/* Q4:Which segment has the highest increase in count of unique products 2021 vs 2020? */

with product_2020 as 
(select p.segment,count(distinct p.product_code) AS unique_product_2020
from dim_product p join fact_act_est f 
using(product_code)
where f.fiscal_year = '2020'
group by 1),
product_2021 as
(select p.segment,count(distinct p.product_code)as unique_product_2021
from dim_product p join fact_act_est f 
using(product_code)
where f.fiscal_year = '2021'
group by 1)
select u1.segment,u1.unique_product_2020,u2.unique_product_2021,
(u2.unique_product_2021 - u1.unique_product_2020) as difference
from product_2020 u1 join product_2021 u2 
on u1.segment = u2.segment
group by 1,2,3
order by difference desc;

/*Q5: Find products with highest and lowest manufacturing cost.*/
(
select m.product_code,p.product,m.manufacturing_cost
from dim_product p join fact_manufacturing_cost m 
using(product_code)
group by 1,2,3
having m.manufacturing_cost = (select MAX(manufacturing_cost) 
                               from fact_manufacturing_cost)
)
UNION
(
select m.product_code,p.product,m.manufacturing_cost
from dim_product p join fact_manufacturing_cost m 
using(product_code)
group by 1,2,3
having m.manufacturing_cost = (select MIN(manufacturing_cost) 
                               from fact_manufacturing_cost)
);

/* Q6: Return TOP 5 customers who received discounts greater than avg_high_pre_invoice_dict_pct
 in year 2021 in Indian market. */
 
 with top_discounts as
 (select pi.customer_code,c.customer,
 pi.pre_invoice_discount_pct,
 avg(pi.pre_invoice_discount_pct) 
 over(order by customer_code rows between unbounded preceding
      and unbounded following) as avg_discount
from dim_customer c join fact_pre_invoice_deductions pi 
using(customer_code)
group by 1,2,3)
select customer_code,customer,pre_invoice_discount_pct
from top_discounts
where pre_invoice_discount_pct>avg_discount
group by 1,2,3
order by 3 desc
limit 5;

/* Q7:   Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month */

SELECT MONTH(s.date) as month, s.fiscal_year as year ,
sum(s.sold_quantity) as gross_sales_amount,
dense_rank() over(partition by s.fiscal_year order by sum(s.sold_quantity) desc) as rnk
from fact_sales_monthly s join dim_customer c 
using(customer_code)
where c.customer = 'Atliq Exclusive'
group by 1,2
order by 2;

/* Q8: Which quarter of 2020, got the maximum total_sold_quantity? */

SELECT quarter(date) as Qtr, 
round(sum(sold_quantity)/1000000 ,2)as total_sold_qty_in_mln
from fact_sales_monthly
where fiscal_year = '2020'
group by 1
order by 2 desc;

/* Q9:  Which channel helped to bring most gross sales in the fiscal year 2021 
and the percentage of contribution?  */

with channel_sales as 
(select c.channel,
round(sum(s.sold_quantity)/1000000,2) as gross_sales_mln
from fact_sales_monthly s join dim_customer c 
using(customer_code)
where s.fiscal_year = 2021
group by 1),
total_sales as
(select round(sum(sold_quantity)/1000000,2) as total_sales_mln
from fact_sales_monthly
where fiscal_year = 2021)
select t1.channel,t1.gross_sales_mln,
concat(round(100.0*(t1.gross_sales_mln)/t2.total_sales_mln,2),'%') as percentage 
from channel_sales t1,total_sales t2
group by 1,2,3
order by 2 desc;

/* Q10:  Get the Top 3 products in each division in terms of
total_sold_quantity in the fiscal_year 2021?   */
 
 with top_products as 
 (SELECT p.division,p.product_code,p.product,
 round(sum(s.sold_quantity)/1000000,2) as sales_mln,
 dense_rank() over(partition by p.division order by sum(s.sold_quantity)desc)as rank_order
 from dim_product p join fact_sales_monthly s 
 using(product_code)
 group by 1,2,3)
 select division,product_code,product,sales_mln,rank_order
 from top_products
 where rank_order<=3
 order by 4 desc;





