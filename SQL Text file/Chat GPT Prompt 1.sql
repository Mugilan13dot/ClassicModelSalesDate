-- Overview of sales for 2004 broken down by product, country, and city
SELECT 
    p.productName,                          -- Product name
    c.country,                              -- Customer country
    c.city,                                 -- Customer city
    
    SUM(od.quantityOrdered * od.priceEach) AS sales_value,        -- Total sales amount
    SUM(od.quantityOrdered * p.buyPrice) AS cost_of_sales,        -- Total cost of the sales
    SUM(od.quantityOrdered * od.priceEach) - 
    SUM(od.quantityOrdered * p.buyPrice) AS net_profit            -- Net profit

FROM orders o
JOIN orderdetails od 
    ON o.orderNumber = od.orderNumber       -- Join orders with order details
JOIN customers c 
    ON o.customerNumber = c.customerNumber  -- Join orders with customers
JOIN products p 
    ON od.productCode = p.productCode       -- Join order details with products

WHERE YEAR(o.orderDate) = 2004              -- Filter only orders from year 2004

GROUP BY 
    p.productName, 
    c.country, 
    c.city                                  -- Group by product, country and city

ORDER BY 
    c.country, 
    c.city, 
    p.productName;                          -- Optional: sort the results for readability
