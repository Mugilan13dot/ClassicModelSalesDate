-- Show customer sales, payments, money owed, and whether they exceeded their credit limit
SELECT 
    c.customerName,
    IFNULL(s.total_sales, 0) AS total_sales,
    IFNULL(p.total_payments, 0) AS total_payments,
    IFNULL(s.total_sales, 0) - IFNULL(p.total_payments, 0) AS money_owed,
    c.creditLimit,
    CASE 
        WHEN (IFNULL(s.total_sales, 0) - IFNULL(p.total_payments, 0)) > c.creditLimit THEN 'Yes'
        ELSE 'No'
    END AS over_credit_limit

FROM customers c

-- Total sales per customer
LEFT JOIN (
    SELECT 
        o.customerNumber,
        SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY o.customerNumber
) s ON c.customerNumber = s.customerNumber

-- Total payments per customer
LEFT JOIN (
    SELECT 
        customerNumber,
        SUM(amount) AS total_payments
    FROM payments
    GROUP BY customerNumber
) p ON c.customerNumber = p.customerNumber

ORDER BY money_owed DESC;
