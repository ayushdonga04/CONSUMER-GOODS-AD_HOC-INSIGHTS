use atliQ;
/*1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
 business in the  APAC  region. */
select distinct(market) from dim_customer where customer="Atliq Exclusive"
and region="APAC" order by market; 

 /*2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
 final output contains these fields, 
 unique_products_2020 
 unique_products_2021 
 percentage_chg */
with mct1 as(
	select count(case when fiscal_year=2020 then product_code end) as unique_products_2020,
    count(case when fiscal_year=2021 then product_code end) as unique_products_2021
	from fact_gross_price
)
select unique_products_2020,unique_products_2021,
round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) 
as percentage_chg from mct1;

/*3.Provide a report with all the unique product counts for each  segment  and 
 sort them in descending order of product counts. The final output contains 
 2 fields, 
 segment 
 product_count*/
select distinct(segment),count(product_code) as product_count from dim_product 
group by segment order by product_count desc;

/* 4.Follow-up: Which segment had the most increase in unique products in 
 2021 vs 2020? The final output contains these fields, 
 segment 
 product_count_2020 
 product_count_2021 
 difference */
with cte1 as(
		select dp.segment as segment,
        count(distinct(fs.product_code)) as product_count_2020 
        from fact_sales_monthly fs 
        inner join dim_product dp on fs.product_code=dp.product_code 
        group by dp.segment,fs.fiscal_year 
        having fs.fiscal_year=2020 
),
cte2 as(
		select dp.segment as segment,
        count(distinct(fs.product_code)) as product_count_2021 
        from fact_sales_monthly fs 
        inner join dim_product dp on fs.product_code=dp.product_code 
        group by dp.segment,fs.fiscal_year 
        having fs.fiscal_year=2021
)
select cte1.segment,cte1.product_count_2020,cte2.product_count_2021,
(cte2.product_count_2021-cte1.product_count_2020) 
as difference from cte1,cte2 where cte1.segment=cte2.segment;


/*5.Get the products that have the highest and lowest manufacturing costs. 
 The final output should contain these fields, 
 product_code 
 product 
 manufacturing_cost */
with max_cost as(
				select mc.product_code,dp.product,mc.manufacturing_cost 
                from fact_manufacturing_cost mc 
				join dim_product dp on mc.product_code=dp.product_code 
                order by mc.manufacturing_cost desc limit 1
),
min_cost as(
				select mc.product_code,dp.product,mc.manufacturing_cost 
                from fact_manufacturing_cost mc 
				join dim_product dp on mc.product_code=dp.product_code 
                order by mc.manufacturing_cost limit 1
) 
select * from max_cost
union all
select * from min_cost;

/*6.Generate a report which contains the top 5 customers who received an 
 average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
 Indian  market. The final output contains these fields, 
 customer_code 
 customer 
 average_discount_percentag */
select MAX(dc.customer_code) as customer_code,dc.customer,
		avg(fpi.pre_invoice_discount_pct*100) as 
		average_discount_percentage  from dim_customer dc
		join fact_pre_invoice_deduction fpi 
        on dc.customer_code=fpi.customer_code where
		fpi.fiscal_year=2021 and dc.market="india" 
        group by dc.customer 
        order by average_discount_percentage desc limit 5;

/*7.Get the complete report of the Gross sales amount for the customer  “Atliq 
 Exclusive”  for each month 
 .  This analysis helps to  get an idea of low and 
 high-performing months and take strategic decisions. 
 The final report contains these columns: 
 Month 
 Year 
 Gross sales Amount */
with cte1 as (
	select 
		monthname(s.date) as A,
        year(s.date) as B,
        s.fiscal_year,
        (g.gross_price*s.sold_quantity) as C
	from fact_sales_monthly s 
    join fact_gross_price g on s.product_code = g.product_code
    join dim_customer c on s.customer_code = c.customer_code
    where c.customer = 'Atliq Exclusive')

select 
	A as month,
    B as Year,
    round(sum(C),2) as Gross_sales_amt
from cte1
group by month, Year 
order by year;

/*8.In which quarter of 2020, got the maximum total_sold_quantity? The final 
 output contains these fields sorted by the total_sold_quantity, 
 Quarter 
 total_sold_quantity */
select case 
			when month(date) in (9, 10, 11) then 'Quarter 1'
			when month(date) in (12, 1, 2) then 'Quarter 2' 
			when month(date) in (3, 4, 5) then 'Quarter 3' 
			when month(date) in (6, 7, 8) then 'Quarter 4' END AS quarter 
			,round(sum(sold_quantity)/ 1000000,2) as total_sold_quantity 
            from fact_sales_monthly where fiscal_year=2020 
            group by quarter order by total_sold_quantity;


/*9.Which channel helped to bring more gross sales in the fiscal year 2021 
 and the percentage of contribution?  The final output  contains these fields, 
 channel 
 gross_sales_mln 
 percentage */
with cte1 as (
				select channel,
                round(sum(fgp.gross_price*fs.sold_quantity)/1000000,0) as gross_sales_mln 
                from fact_sales_monthly fs 
                join fact_gross_price fgp
				on fs.product_code=fgp.product_code
                join dim_customer dc 
                on dc.customer_code=fs.customer_code
				where fs.fiscal_year=2021 group by channel
)
select *,round(gross_sales_mln*100/(select sum(gross_sales_mln) from cte1),2) 
as percentage from cte1  order by percentage;

/*10.Get the Top 3 products in each division that have a high 
 total_sold_quantity in the fiscal_year 2021? The final output contains these 
 fields, 
 division 
 product_code 
 product 
 total_sold_quantity 
 rank_order */
with cte1 as(
select dp.division,dp.product_code,dp.product,sum(fs.sold_quantity) as total_sold_quantity,
rank() over(partition by dp.division order by sum(fs.sold_quantity)) as rank_order 
from dim_product dp join fact_sales_monthly fs 
on dp.product_code=fs.product_code where fs.fiscal_year=2021
group by dp.division,dp.product_code,dp.product
)
select * from cte1 where rank_order in(1,2,3);

   