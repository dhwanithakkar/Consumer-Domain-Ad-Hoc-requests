-- 1) Prepare a report for top market, products, customers by net sales for given FY to have a holistic view of 
-- financial performance.

select fsm.date, fsm.product_code, 
dp.product, dp.variant, 
fsm.sold_quantity, fgp.gross_price,
round((fgp.gross_price * fsm.sold_quantity),2) as "total_gross_price"
from fact_sales_monthly fsm
join dim_product dp
on fsm.product_code = dp.product_code
join fact_gross_price fgp
on fgp.product_code = fsm.product_code
   and fgp.fiscal_year = get_fiscal_year(fsm.date)
where fsm.customer_code = "90002002" 
and get_fiscal_year (fsm.date)= 2021
order by date 
limit 1000000;

-- =============================
-- 2) Generate a report with month, product name, variant, sold quantity, gross price per item, gross price total for Croma

select fsm.date, sum((fgp.gross_price * fsm.sold_quantity)) as "total_gross_price"
from fact_sales_monthly fsm
join fact_gross_price fgp
on fgp.product_code = fsm.product_code
   and fgp.fiscal_year = get_fiscal_year(fsm.date)
where customer_code = "90002002"
group by fsm.date
order by fsm.date asc;

-- =============================
-- 3) Generate a yearly report for Croma India where there are two columns 
-- a. Fiscal Year b. Total Gross Sales amount In that year from Croma

select get_fiscal_year(fsm.date) as fiscal_year, sum((fgp.gross_price * fsm.sold_quantity)) as yearly_sales
from fact_sales_monthly fsm
join fact_gross_price fgp
on fgp.product_code = fsm.product_code
   and fgp.fiscal_year = get_fiscal_year(fsm.date)
where customer_code = "90002002"
group by get_fiscal_year(date)
order by fiscal_year;

-- =============================
-- 4) Get top n products per division by quantity sold

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_products_per_division_by_qtysold`(
	in_fiscal_year INT,
    in_top_n INT
    )
BEGIN
	with cte1 as(
		select dp.division as divi, dp.product, sum(fsm.sold_quantity) as total_sold_quantity
		from dim_product dp
		join fact_sales_monthly fsm
		on dp.product_code = fsm.product_code 
		where fsm.fiscal_year = in_fiscal_year
		group by dp.product),
	cte2 as (
		select *,
		dense_rank() over(partition by divi order by total_sold_quantity desc) as drnk
		from cte1)
	select * from cte2 where drnk<=in_top_n;
END

-- =============================
-- 5) Determine market badge based on the total sold quantity based on fiscal year and country. 
-- If sold quantity > 5million  gold, Else Silver

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_market_badge`(
	IN in_market varchar(45),
    IN in_fiscal_year YEAR,
    OUT out_badge varchar(45)
    )
BEGIN
	declare qty int default 0;
    
    # retreving total sold quantity based on fiscal year and market (country)
	select sum(sold_quantity) into qty
	from fact_sales_monthly s
	join dim_customer c
	on s.customer_code = c.customer_code
	where get_fiscal_year(s.date) = in_fiscal_year 
    and market = in_market
	group by market;
    
    # determining market badge
    if qty > 5000000 then
		set out_badge = "Gold";
    else
		set out_badge = "Silver";
	end if;
END