use dannys_diner;
-- 1. What is the total amount each customer spent at the restaurant?
select customer_id,sum(price) spent 
	from sales inner join menu 
    on sales.product_id = menu.product_id 
    group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) 
	from sales group by customer_id;
    
-- 3. What was the first item from the menu purchased by each customer?
with cte as(
select customer_id,product_name, rank() over(partition by customer_id order by order_date) as rank_num
	from sales inner join menu 
    on sales.product_id = menu.product_id )
select customer_id,product_name from cte where rank_num = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as (
select product_name,count(*) as purchase_count, rank() over(order by count(*)  desc) as rank_num
	from sales inner join menu 
    on sales.product_id = menu.product_id group by product_name)
select product_name,purchase_count from cte where rank_num = 1;


-- 5. Which item was the most popular for each customer?
with cte as (
select customer_id,product_name,count(*) AS purchase_count,rank() over(partition by customer_id order by count(*) desc ) as rank_num
	from sales inner join menu 
    on sales.product_id = menu.product_id group by customer_id,product_name )
select customer_id,product_name, purchase_count FROM cte
WHERE rank_num = 1
ORDER BY customer_id;


-- 6. Which item was purchased first by the customer after they became a member?
with cte as (
select s.customer_id,m.product_name,s.order_date,rank() over(partition by s.customer_id order by s.order_date) as rank_num
	from sales s inner join menu m
    on s.product_id = m.product_id inner join 
    members mb on s.customer_id = mb.customer_id
    where order_date >= join_date)
select customer_id,product_name,order_date from cte where rank_num = 1;


-- 7. Which item was purchased just before the customer became a member?
select customer_id,product_name,order_date from (
select s.customer_id,m.product_name,s.order_date,rank() over(partition by s.customer_id order by s.order_date desc) as rank_num
	from sales s inner join menu m
    on s.product_id = m.product_id left join 
    members mb on s.customer_id = mb.customer_id
    where order_date < join_date or join_date is null) as ab
    where rank_num = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(m.product_name),sum(m.price)
	from sales s inner join menu m
    on s.product_id = m.product_id left join 
    members mb on s.customer_id = mb.customer_id
    where order_date < join_date or join_date is null
    group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,sum(case when product_name = "sushi" then price*20 else price*10 end) as points 
	from sales inner join menu 
    on sales.product_id = menu.product_id group by customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi  how many points do customer A and B have at the end of January?
select s.customer_id,sum(case when s.order_date between mb.join_date and date_add(mb.join_date,interval 6 day)
	then m.price*20
    else m.price*10
    end) as points
	from sales s inner join menu m
    on s.product_id = m.product_id left join 
    members mb on s.customer_id = mb.customer_id
    where s.order_date <= '2021-01-31'
    group by customer_id