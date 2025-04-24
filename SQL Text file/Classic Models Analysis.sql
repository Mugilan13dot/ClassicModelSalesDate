select t1.orderDate, t1.orderNumber, quantityOrdered, priceeach, productName, productLine, buyprice, city, country 
from orders t1 
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join products t3
on t2.productCode = t3.productCode
inner join customers t4
on t1.customerNumber = t4.customerNumber 
where year(orderDate) = 2004 ;

with prod_sales as
(select orderNumber, t1.productCode, productLine
from orderdetails t1
inner join products t2
on t1.productCode = t2.productCode
)

select distinct t1.orderNumber, t1.productLine as product_one, t2.productLine as product_two 
from prod_sales t1
left join prod_sales t2
on t1.orderNumber = t2.orderNumber and t1.productLine <> t2.productLine ;

with sales as
(select t1.orderNumber, t1.customerNumber, productCode, quantityOrdered, priceEach, priceEach*quantityOrdered as sales_value,
creditLimit
from orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join customers t3
on t1.customerNumber = t3.customerNumber
)

select orderNumber, customerNumber,
case when creditLimit < 75000 then 'a: Less than $75k'
when creditLimit between 75000 and 100000 then "b: $75k - $100k"
when creditLimit between 100000 and 150000 then "c: $100k - $150k"
when creditLimit > 150000 then 'd: Over $150k'
else 'Other'
end as creditlimit_group,
sum(sales_value) as sales_value
from sales
group by orderNumber, customerNumber, creditlimit_group ;


with main_cte as
(
select orderNumber, orderDate, customerNumber, sum(sales_value) as sales_value
from
(select t1.orderNumber, orderDate, customerNumber, productCode, quantityOrdered * priceEach as sales_value
from orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber) main
group by orderNumber, orderDate, customerNumber
),
sales_query as
(
select t1.*, customerName, row_number() over ( partition by customername order by orderdate) as purchase_number,
lag(sales_value) over ( partition by customername order by orderdate) as prev_sales_value
from main_cte t1
inner join customers t2 
on t1.customerNumber = t2.customerNumber)

select *, sales_value - prev_sales_value as purchase_value_change
from sales_query
where prev_sales_value is not null ;

with main_cte as

(select t1.orderNumber, t2.productCode, t2.quantityOrdered, t2.priceEach, quantityOrdered * priceEach as sales_value,
t3.city as customer_city, t3.country as customer_country, t4.productLine, t6.city as office_city, t6.country as office_country
from orders t1
inner join orderdetails t2 
on t1.orderNumber = t2.orderNumber 
inner join customers t3
on t1.customerNumber = t3.customerNumber 
inner join products t4
on t2.productCode = t4.productCode
inner join employees t5 
on t3.salesRepEmployeeNumber = t5.employeeNumber
inner join offices t6
on t5.officeCode = t6.officeCode
)

select orderNumber, customer_city, customer_country, productLine, office_city, office_country, sum(sales_value) as sales_value
from main_cte
group by orderNumber, customer_city, customer_country, productLine, office_city, office_country ;

select * ,
date_add(shippedDate, interval 3 day) as latest_arrival, 
case when date_add(shippedDate, interval 3 day) > requiredDate then 1 else 0 end as late_flag
from orders 
where (case when date_add(shippedDate, interval 3 day) > requiredDate then 1 else 0 end) = 1 ;

WITH cte_sales AS (
    SELECT  
        orderDate, 
        t1.customerNumber, 
        t1.orderNumber, 
        customerName, 
        productCode, 
        creditLimit, 
        quantityOrdered * priceEach AS sales_value
    FROM orders t1 
    INNER JOIN orderdetails t2 ON t1.orderNumber = t2.orderNumber 
    INNER JOIN customers t3 ON t1.customerNumber = t3.customerNumber 
),

running_total_sales_cte AS (
    SELECT 
        orderDate, 
        orderNumber, 
        customerNumber, 
        customerName, 
        creditLimit, 
        SUM(sales_value) AS sales_value,
        LEAD(orderDate) OVER (PARTITION BY customerNumber ORDER BY orderDate) AS next_order_date
    FROM cte_sales
    GROUP BY orderDate, orderNumber, customerNumber, customerName, creditLimit
),

payment_cte AS (
    SELECT customerNumber, paymentDate, amount
    FROM payments
),

main_cte AS (
    SELECT 
        t1.orderDate,
        t1.orderNumber,
        t1.customerNumber,
        t1.customerName,
        t1.creditLimit,
        t1.sales_value,
        t1.next_order_date,
        t2.paymentDate,
        t2.amount,
        SUM(t1.sales_value) OVER (PARTITION BY t1.customerNumber ORDER BY t1.orderDate) AS running_total_sales,
        SUM(t2.amount) OVER (PARTITION BY t1.customerNumber ORDER BY t1.orderDate) AS running_total_payments
    FROM running_total_sales_cte t1 
    LEFT JOIN payment_cte t2 
        ON t1.customerNumber = t2.customerNumber 
        AND t2.paymentDate BETWEEN t1.orderDate AND 
            CASE 
                WHEN t1.next_order_date IS NULL THEN CURRENT_DATE 
                ELSE t1.next_order_date 
            END
)

SELECT 
    *,
    running_total_sales - running_total_payments AS money_owned,
    creditLimit - (running_total_sales - running_total_payments) AS difference
FROM main_cte;
