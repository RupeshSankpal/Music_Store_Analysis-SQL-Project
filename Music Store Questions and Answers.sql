/* QI: Who is the senior most employee based on job title? */

SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1

/* Q2: Which countries have the most Invoices? */

SELECT count(*) as Count, -*billing_country
FROM invoice
GROUP BY billing_country
ORDER BY  count DESC

/* Q3: What are top 3 values of total invoice.  (FROM highest to lowest. here total is a column) */

SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3

/* Q4: Which city has the best customers? We would like to throw a
promotional Music Festival in the city we made the most money. Write a
query that returns one city that has the highest SUM of invoice totals.
Return both the city name & SUM of all invoice totals. */


SELECT billing_city,
	SUM(total) as SUM
FROM invoice
GROUP BY billing_city
ORDER BY SUM DESC

/* Q5: Who is the best customer? The customer who has spent the most
money will be declared the best customer. Write a query that return
the person who has spent the most money. */


SELECT c.customer_id,c.first_name, c.last_name,
	SUM(i.total) as total_amt_spend ,
	count(i.total) as count_of_spend
FROM invoice i
JOIN customer c on i.customer_id=c.customer_id
GROUP BY c.customer_id
ORDER BY total_amt_spend DESC
LIMIT 1


/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


-- using multiple JOINs.

SELECT  distinct c.first_name,c.last_name, c.email
FROM customer c
JOIN invoice i on c.customer_id = i.customer_id
JOIN  invoice_line il on i.invoice_id = il.invoice_id
JOIN track as t on t.track_id = il.track_id
JOIN genre g on g.genre_id = t.genre_id
WHERE g.name like 'Rock'
ORDER BY email

-- using SubQuery Method

SELECT  distinct first_name,last_name, email
FROM customer c
JOIN invoice i
on c.customer_id =i.customer_id
JOIN  invoice_line il
on i.invoice_id= il.invoice_id
WHERE track_id in ( SELECT track_id FROM track t
				    JOIN genre g
				    on g.genre_id=t.genre_id
				    WHERE g.name='Rock')
ORDER BY email 



/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. 
*/


--album tables has no of times artist have sung the song.


SELECT  a.artist_id,a.name, count(a.artist_id) as no_of_songs
FROM artist a
JOIN album ab on a.artist_id = ab.artist_id
JOIN track tk on tk.album_id=ab.album_id
JOIN genre gr on gr.genre_id=tk.genre_id
WHERE gr.name='Rock'
GROUP BY a.artist_id
ORDER BY no_of_songs DESC
LIMIT 10



/* Q3: Return all the track names that have a song length longer
than the average song length. 
Return the Name and Milliseconds for each track.
ORDER BY the song length with the longest songs listed first. */


SELECT name , milliseconds 
FROM track
WHERE milliseconds > (
		SELECT avg(milliseconds)
		FROM track )
ORDER BY milliseconds DESC


-- using CTE 
with avg as
(	
	SELECT avg(milliseconds) as av
		FROM track
)		
SELECT name , milliseconds 
FROM track,avg
WHERE milliseconds > av
ORDER BY milliseconds DESC


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */



-- make sure to do the product of unit_price and the quantity.

SELECT i.customer_id,c.first_name,c.last_name,
		a.name as Artist_name ,
		SUM(il.unit_price*il.quantity) as total_spend
	FROM customer c
	JOIN invoice i on c.customer_id =i.customer_id 
	JOIN  invoice_line il on i.invoice_id= il.invoice_id
	JOIN track as t on t.track_id=il.track_id
	JOIN album al on t.album_id=t.album_id
	JOIN artist a on a.artist_id=al.artist_id
	GROUP BY 1,2,3,4
	ORDER BY 1 



/*How does the spending behavior of customers correlate with the top-selling artists albums?
Who is the biggest spender (by total amount spent) among the customers
who purchased music by the best-selling artist, and how much did they spend? */



-- this will give the best selling artist
with best_selling_artist 
as (
    SELECT a.artist_id,a.name as Artist_name ,
	SUM(il.unit_price*il.quantity) as total_sales
	FROM artist a
	JOIN album al on a.artist_id=al.artist_id
	JOIN track t on al.album_id=t.album_id
	JOIN invoice_line as il on il.track_id=t.track_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
	)
SELECT c.customer_id,c.first_name,c.last_name,
	bsa.Artist_name,
	SUM(il.unit_price*il.quantity) as total_sales,
	bsa.artist_id
	FROM customer c 
	JOIN invoice i on c.customer_id=i.customer_id
	JOIN invoice_line il on i.invoice_id=il.invoice_id
	JOIN track t on t.track_id=il.track_id
	JOIN album al on al.album_id=t.album_id
	JOIN best_selling_artist bsa on bsa.artist_id=al.artist_id
	GROUP BY 1,2,3,4,6
	ORDER BY 5 DESC;

-- for understanding cte concpet

with sample as
   (
    SELECT artist_id, name as Artist_name
    FROM artist
	)
	
SELECT  count(a.artist_id) as cnt,
	a.artist_id,
	s.Artist_name
FROM album a
JOIN sample s on s.artist_id=a.artist_id
GROUP BY a.artist_id,s.Artist_name
ORDER BY cnt DESC



/* Q2: We want to find out the most popular music Genre for each country.
We determine the most popular genre as the genre 
with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. For countries WHERE 
the maximum number of purchases is shared return all Genres. */

-- sub query method
/* as total/max amount is not asked so count based on  quantites or genre name can be considered*/

SELECT * FROM 
 	(
	SELECT billing_country as Country,
	g.name as Genre_Name,
	count(il.quantity),
	count(g.name)as cnt_of_purchases,
	g.genre_id,
	row_number() over(partition by billing_country ORDER BY count(g.name) DESC) as rn
	FROM invoice i
	JOIN  invoice_line il on i.invoice_id = il.invoice_id
	JOIN track as t on t.track_id = il.track_id
	JOIN genre g on g.genre_id = t.genre_id
	GROUP BY 1,2,5 
	) as a
WHERE rn<=1  -- for the most popular genre

-- using cte
/* here count of quantity FROM invoice_line table 
is taken to calculate the highest amount of purchases  */

with popular_genre as 
	(
	SELECT c.country as Country,
	g.name as Genre_Name,
	count(il.quantity) as cnt_of_quantities,
	g.genre_id,
	row_number() over(partition by c.country ORDER BY count(il.quantity) DESC) as rn
	FROM invoice i
	JOIN  invoice_line il on i.invoice_id = il.invoice_id
	JOIN track as t on t.track_id = il.track_id
	JOIN genre g on g.genre_id = t.genre_id
	JOIN customer c on c.customer_id=i.customer_id
	GROUP BY 1,2,4
	) 

SELECT * FROM popular_genre
	WHERE rn<=1


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries WHERE the top amount spent is shared, provide all customers who spent this amount. */


SELECT  * FROM
 	(
	SELECT c.country as Country, c.customer_id,c.first_name,c.last_name,
	SUM(total) as Total_spend,
	row_number() over(partition by c.country ORDER BY SUM(total) DESC) as rn
	FROM invoice i
	JOIN customer c on c.customer_id=i.customer_id
	GROUP BY 1,2,3,4 
	) as x
	WHERE rn=1
	ORDER BY 1
	






