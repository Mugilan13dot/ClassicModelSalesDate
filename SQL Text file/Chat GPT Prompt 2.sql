-- Sales by customer, showing their previous sale and the difference
SELECT 
    c.customerName,
    o.orderDate,
    current_order.sales_value,
    LAG(current_order.sales_value) OVER (PARTITION BY c.customerNumber ORDER BY o.orderDate) AS previous_sale,
    current_order.sales_value - 
        LAG(current_order.sales_value) OVER (PARTITION BY c.customerNumber ORDER BY o.orderDate) AS difference_from_previous

FROM customers c
JOIN orders o 
    ON c.customerNumber = o.customerNumber
JOIN (
    -- Subquery to calculate total sales value for each order
    SELECT 
        od.orderNumber,
        SUM(od.quantityOrdered * od.priceEach) AS sales_value
    FROM orderdetails od
    GROUP BY od.orderNumber
) AS current_order 
    ON o.orderNumber = current_order.orderNumber

ORDER BY c.customerName, o.orderDate;
