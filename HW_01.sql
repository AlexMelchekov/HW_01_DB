create table customers_HW01 (
	customer_id text,
	first_name text,
	last_name text,
	gender text,
	DOB varchar(20),
	job_title text,
	job_industry_category text,
	wealth_segment text,
	deceased_indicator text,
	owns_car text,
	address text,
	postcode varchar(20),
	state text,
	country text,
	property_valuation varchar(20)
)

create table order_items_HW01 (
	order_item_id varchar(20),
	order_id varchar(20),
	product_id varchar(20),
	quantity varchar(20),
	item_list_price_at_sale varchar(20),
	item_standard_cost_at_sale varchar(20)
)

create  table orders_HW01 (
	order_id text,
	customer_id text,
	order_date text,
	online_order text,
	order_status text
)

ALTER TABLE customers_hw01
ADD CONSTRAINT pk_customers_hw01_customer_id PRIMARY KEY (customer_id);

SELECT COUNT(*) AS total_rows
FROM orders_hw01;

--

SELECT COUNT(DISTINCT customer_id) AS count_customers
FROM customers_hw01; -- 5000

SELECT COUNT(DISTINCT product_id) AS count_products
FROM products_hw01; -- 300

SELECT COUNT(DISTINCT order_id) AS count_orders
FROM orders_hw01; -- 25000

SELECT COUNT(DISTINCT order_item_id) AS count_order_items_id
FROM order_items_hw01; -- 50000

SELECT COUNT(DISTINCT order_id) AS count_orders
FROM orders_hw01; -- 50000

SELECT COUNT(DISTINCT brand) AS count_brands
FROM products_hw01; -- 18 брендов



------ Задача 3.1

select product_id, AVG(item_list_price_at_sale) as avg_item_list_price_at_sale
FROM order_items_hw01
group by product_id
ORDER BY avg_item_list_price_at_sale desc
LIMIT 5;

select product_id, AVG(item_list_price_at_sale) as avg_item_list_price_at_sale
FROM order_items_hw01
where product_id = '102'
group by product_id



------ Задача 3.2

select t1.quantity, t1.item_list_price_at_sale, t2.brand
from order_items_hw01 as t1
left join products_hw01 as t2
on t1.product_id=t2.product_id



select t2.brand, sum(t1.quantity * t1.item_list_price_at_sale) as p_brand
from order_items_hw01 as t1
left join products_hw01 as t2
on t1.product_id=t2.product_id
group by t2.brand
order by p_brand
desc 

------ Задача 3.3 Подсчитайте количество заказов за каждый месяц для каждого года. То есть необходимо вывести год, месяц и количество заказов.

SELECT
    EXTRACT(YEAR  FROM order_date::date) AS year_date,
    EXTRACT(MONTH FROM order_date::date) AS month_date,
    COUNT(order_id) AS order_count
FROM orders_hw01
GROUP BY 1, 2
ORDER BY 1, 2


------ Задача 3.4 Для каждой продуктовой линейки (product_line) найдите продукт с самой высокой стандартной стоимостью (standard_cost). Выведите id продукта, линейку продукта и стандартную стоимость.
-- также можно сделать через оконную функцию или специальную постгре команду distinct on

SELECT t1.product_id, t1.product_line, t1.standard_cost
FROM products_hw01 as t1
WHERE t1.standard_cost = (
    SELECT MAX(t2.standard_cost)
    FROM products_hw01 t2
    WHERE t2.product_line = t1.product_line
)

SELECT DISTINCT ON (product_line)
    product_id,
    product_line,
    standard_cost
FROM products_hw01
ORDER BY product_line, standard_cost DESC;


-- проверка сколько линий
select distinct product_line
FROM products_hw01



------ Задача 3.5 Подсчитайте количество заказов и общую стоимость заказов для каждого статуса заказа (order_status). Общую стоимость заказа необходимо рассчитать как цену продукта на момент продажи, умноженную на количество единиц продукта в заказе.

--SELECT DISTINCT order_status
--FROM orders_hw01; 


select t1.order_status, count(distinct t1.order_id) as count_orders, sum(t2.quantity * t2.item_list_price_at_sale) as total_cost
from orders_hw01 as t1
left join order_items_hw01 as t2
on t1.order_id=t2.order_id
group by t1.order_status


------ Задача 3.6 Найдите клиентов, у которых нет ни одного заказа. Выведите id клиента, фамилию и имя.

select c.customer_id, c.last_name, c.first_name
from customers_hw01 c
left join orders_hw01 orders on c.customer_id=orders.customer_id
WHERE orders.order_id IS NULL

------ Задача 3.7 Для каждого штата найдите клиента с самой высокой и самой низкой оценкой стоимости имущества (property_valuation). Выведите штат, оценку стоимости имущества, фамилию и имя клиента.

select state, property_valuation, last_name, first_name
from customers_hw01
group by state

SELECT t.state, t.property_valuation, t.last_name, t.first_name
FROM (
    SELECT
        state,
        property_valuation,
        last_name,
        first_name,
        RANK() OVER (PARTITION BY state ORDER BY property_valuation DESC) AS rn_max,
        RANK() OVER (PARTITION BY state ORDER BY property_valuation ASC)  AS rn_min
    FROM customers_hw01
) t
WHERE t.rn_max = 1 OR t.rn_min = 1
ORDER BY t.state, t.property_valuation desc

------ Задача 3.8 Найдите клиентов, которые покупали продукты только из одной продуктовой линейки (product_line). Выведите id клиента, линейку продукта и количество заказов.


WITH cust_lines AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t3.product_line) AS lines_cnt
    FROM orders_hw01 t1
    JOIN order_items_hw01 t2 ON t2.order_id = t1.order_id
    JOIN products_hw01 t3 ON t3.product_id = t2.product_id
    GROUP BY t1.customer_id
)
SELECT
    cl.customer_id,
    products.product_line,
    COUNT(DISTINCT orders.order_id) AS orders_count
FROM cust_lines cl
JOIN orders_hw01 orders ON orders.customer_id = cl.customer_id
JOIN order_items_hw01 oi ON oi.order_id = orders.order_id
JOIN products_hw01 products ON products.product_id = oi.product_id
WHERE cl.lines_cnt = 1
GROUP BY cl.customer_id, products.product_line
ORDER BY cl.customer_id

------ Задача 3.9 Для каждой категории продуктов рассчитайте процент отмененных заказов (order_status = 'Cancelled').

select products.product_class, 
	ROUND(100.0 * COUNT(DISTINCT CASE WHEN orders.order_status = 'Cancelled' THEN orders.order_id END) / COUNT(DISTINCT orders.order_id), 2) AS percent_cancelled
from products_hw01 products 
join order_items_hw01 oi on products.product_id = oi.product_id
join orders_hw01 orders on orders.order_id = oi.order_id
group by products.product_class

--check
SELECT COUNT(DISTINCT o.order_id) AS total,
       COUNT(DISTINCT CASE WHEN o.order_status = 'Cancelled' THEN o.order_id END) AS cancelled
FROM products_hw01 p
JOIN order_items_hw01 oi ON oi.product_id = p.product_id
JOIN orders_hw01 o       ON o.order_id = oi.order_id
WHERE p.product_class = 'value';

------ Задача 3.10 Разделите клиентов на сегменты на основе количества заказов и подсчитайте количество клиентов в каждом сегменте:
-- сегмент High, если количество заказов больше 10;
-- сегмент Medium, если количество заказов от 5 до 10;
-- иначе сегмент Low.


WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_hw01
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_orders > 10 THEN 'High'
        WHEN total_orders BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS segment,
    COUNT(*) AS customers_count
FROM customer_orders
GROUP BY segment

------ Задача 3.11 Для всех клиентов выведите имена, фамилии, профессии, а также длительность максимального интервала (в днях) между двумя последовательными заказами. Необходимо исключить клиентов, у которых только один заказ или меньше.

-- «последовательные заказы» — это соседние по дате, нужен LAG(). сначала считает количество дней между заказами, потом выбираем из них максимальный
with order_lags as (
    select
        orders.customer_id,
        orders.order_date::date - LAG(orders.order_date::date) OVER (
            PARTITION BY orders.customer_id
            ORDER BY orders.order_date::date
        ) as lag_days
    from orders_hw01 orders
)
select
	cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.job_title,
    MAX(lags.lag_days) AS max_lag_days
from order_lags lags
join customers_hw01 cl ON cl.customer_id = lags.customer_id
group by cl.customer_id, cl.first_name, cl.last_name, cl.job_title
having COUNT(lags.lag_days) >= 1 -- потому что первая строка лаг выведет null , так как предыдущего нет
order by cl.customer_id


--check
SELECT order_date 
FROM orders_hw01
WHERE customer_id = 4205
ORDER BY order_date;

SELECT order_date 
FROM orders_hw01
WHERE customer_id = 8
ORDER BY order_date;