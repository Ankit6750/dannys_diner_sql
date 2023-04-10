CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

select * from sales;
select * from menu;
select * from members;

--What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price)
from sales s
join menu m on m.product_id=s.product_id
group by s.customer_id
order by 1;
-- 


--How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) as no_of_visit
from sales
group by customer_id
order by 1;


--What was the first item from the menu purchased by each customer?
select customer_id,product_name,order_date 
from(select s.customer_id,s.order_date,m.product_name,
	rank() over(partition by customer_id order by s.order_date) as rnk
	from sales s
	join menu m on m.product_id=s.product_id) as rank1
where rank1.rnk=1
group by rank1.customer_id,rank1.product_name,rank1.order_date
order by 1;


--What is the most purchased item on the menu and how many times was
--it purchased by all customers?
select product_name, count(s.product_id) as most_order
from menu m
join sales s on m.product_id=s.product_id
group by  product_name
order by 2 desc
limit 1;


--Which item was the most popular for each customer?
select customer_id,product_name from(select customer_id,product_name,
count(s.product_id) as most_purchase,
dense_rank() over (partition by customer_id order by count(customer_id) desc) as fav_item
from sales s
join menu m on m.product_id=s.product_id
group by s.customer_id,product_name
order by 1) as fav_food
where fav_food.fav_item=1;


-- Which item was purchased first by the customer after they became a member?
select customer_id,product_name 
from(select s.customer_id,s.order_date,mn.product_name,
	dense_rank() over(partition by s.customer_id order by s.order_date) as f_purchase
	from sales s 
	join members m on m.customer_id=s.customer_id
	join menu mn on mn.product_id=s.product_id
	where s.order_date>=m.join_date
	order by 1) as rnk
where rnk.f_purchase=1;


--Which item was purchased just before the customer became a member?
select customer_id,product_name 
from(select s.customer_id,s.order_date,mn.product_name,
	dense_rank() over(partition by s.customer_id order by s.order_date) as f_purchase
	from sales s 
	join members m on m.customer_id=s.customer_id
	join menu mn on mn.product_id=s.product_id
	where s.order_date<m.join_date
	order by 1) as rnk
where rnk.f_purchase=1;


--If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--how many points would each customer have?
select pt.customer_id,sum(pt.points) as t_points 
from(select customer_id,product_name,
		case when m.product_id =1 then price*20
	 	else price*10
	 	end as points
		from menu m
		join sales s on s.product_id=m.product_id order by 1) as pt
group by pt.customer_id
order by 1;	 


--In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi 
--how many points do customer A and B have at the end of January?
select ab.customer_id,sum(ab.point) 
from(with date as (select *,
					(join_date+ INTERVAL '6 DAY')::date as d1,
					(date_trunc('month',join_date)+interval ' 1 month - 1day')::date as d2
					from members)
	select s.customer_id,m.product_name,m.price,s.order_date,d.join_date,d.d1,d.d2,
	case when s.order_date between d.join_date and d.d1 then m.price *20
	else m.price *10
	end as point 
	from date as d
	join sales s on s.customer_id=d.customer_id	
	join menu m on m.product_id=s.product_id) ab
group by ab.customer_id
order by 1;


--Join All The Things
select s.customer_id,s.order_date,m.product_name,
m.price,
case when s.order_date<mm.join_date then 'N'
	when s.order_date>=mm.join_date then 'Y'
	else 'N'
	end as member
from sales s 
left join menu m on s.product_id=m.product_id
left join members mm on mm.customer_id=s.customer_id


-- rank all 
select *,
case when al.member = 'N' then NULL
else
rank() over(partition by al.customer_id,al.member order by al.order_date)
end as ranking
from (select s.customer_id,s.order_date,m.product_name,
				m.price,
				case when s.order_date<mm.join_date then 'N'
				when s.order_date>=mm.join_date then 'Y'
				else 'N'
				end as member
				from sales s 
				join menu m on s.product_id=m.product_id
				left join members mm on mm.customer_id=s.customer_id) as al
				




