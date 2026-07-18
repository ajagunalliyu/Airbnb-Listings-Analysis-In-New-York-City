USE nyc_airbnb;

		--- DATA PREPROCESSING ---		

-- To confirm the number empty rows in the columns that have null values

SELECT		COUNT(*) AS total_entries,
			COUNT(name) AS non_null_name,
			COUNT(host_name) AS non_null_host_name,
			COUNT(last_review) AS non_null_last_review,
			COUNT(reviews_per_month) AS non_null_reviews_per_month
FROM		airbnb_listings;

-- To check for duplicates in the id column which is the primary key 

SELECT		id, 
			COUNT(*) AS non_unique_id 
FROM		airbnb_listings
GROUP BY	id 
HAVING		COUNT(*) > 1;

-- To preview Data 

SELECT		TOP 10 * 
FROM		airbnb_listings;

-- To view a few of the missing rows

SELECT		id, 
			name, 
			host_name, 
			last_review, 
			reviews_per_month
FROM		airbnb_listings
WHERE		name IS NULL OR host_name IS NULL OR last_review IS NULL OR reviews_per_month IS NULL;

-- To check for outliers in price and minimum_nights

SELECT		TOP 10 price 
FROM		airbnb_listings
ORDER BY	price DESC;

SELECT		TOP 10 minimum_nights 
FROM		airbnb_listings
ORDER BY	minimum_nights DESC;

		--- DATA CLEANING ---
/*		Handling NULL values
-- To replace NULL 'name' and 'host_name' with unknown.
(only a few entries are missing, dropping them would lose data unnecessarily.*/

UPDATE		airbnb_listings
SET			name = 'Unknown'
WHERE		name IS NULL;

UPDATE		airbnb_listings
SET			host_name = 'Unknown'
WHERE		host_name IS NULL;

/* -- To fix NULL values for last_review and reviews_per_month
(dropping 10K+ plus entries is not ideal, and there is no way to impute accurately without guesswork)

for last_review (Date), missing values means NO REVIEW SO I will keep NULL as it is, 
but create a helper column for analysis*/

ALTER TABLE	airbnb_listings
ADD			review_exists BIT;

UPDATE		airbnb_listings
SET			review_exists = CASE WHEN last_review IS NULL THEN 0 ELSE 1 END;

/* decided to change the new column name from review_exists to review_status */

EXEC		sp_rename 'airbnb_listings.review_exists', 'review_status', 'COLUMN';

/* for reviews_per_month (Numeric), if there is no review then monthly average should be 0. 
So all NULL are replaced with 0.*/

UPDATE		airbnb_listings
SET			reviews_per_month = 0 
WHERE		reviews_per_month IS NULL;

/* -- To handle outliers 
prices as high as 1000, there is clearly an extreme value, possibly typo or luxury/rare listings
minimum_nights values like 1250, 1000, 999, 500 are likely unrealistic for short-term rentals

I will remove the entries where price > 1000  to avoid skewing results and will also remove the entries 
where minimun_nights > 365 */

DELETE FROM	airbnb_listings
WHERE		minimum_nights > 365;

DELETE FROM airbnb_listings
WHERE		price > 1000;

/* -- To confirm Standadised text for columns; neighbourhood_group, neighbourhood, room_type
(its appears the three columns are in order)*/

SELECT		DISTINCT neighbourhood_group FROM airbnb_listings;
SELECT		DISTINCT neighbourhood FROM airbnb_listings;
SELECT		DISTINCT room_type FROM airbnb_listings;

/* -- To check for duplicates in the id column which is the primary key */

SELECT		id, 
			COUNT(*) AS non_unique_id 
FROM		airbnb_listings
GROUP BY	id HAVING COUNT(*) > 1;

/* To also confirm duplicates in other critical column */

SELECT		host_id, 
			name, 
			neighbourhood, 
			room_type, 
			price, 
			COUNT(*) AS count 
FROM		airbnb_listings
GROUP BY	host_id, 
			name, 
			neighbourhood, 
			room_type, 
			price 
HAVING		COUNT(*) > 1;

/* after running the code, it looks like there are duplicates, but they are not duplicates
several listings share key features like host_id, name, room_type and pricing but differ in id and geolocation,
this is likely indicatibg that some hosts have several and/or similar properties, hence these are retained.*/

/* -- To verify and remove unused columns
(This is to help reduce noise and improve performance)*/

SELECT		COUNT(DISTINCT name) AS distinct_name_count 
FROM		airbnb_listings;
SELECT		COUNT(name) AS name_count 
FROM		airbnb_listings;

SELECT		COUNT(DISTINCT host_name) AS distinct_host_name_count 
FROM		airbnb_listings;
SELECT		COUNT(host_name) AS host_name_count 
FROM		airbnb_listings;

/* the name column is not needed, so much inconsistency and not useful for aggregated analysis 
 but I will rather create a view with only the useful columns for analysis, thereby keeping full table intact */

CREATE VIEW cleaned_listings AS
			SELECT id,
					host_id,
					neighbourhood_group,
					neighbourhood,
					latitude,
					longitude,
					room_type,
					price,
					minimum_nights,
					number_of_reviews,
					last_review,
					reviews_per_month,
					calculated_host_listings_count,
					availability_365,
					review_exists
			FROM	airbnb_listings;

/* -- To fix suspicious or invalid Values
(these values are not missing but they make no logical sense or fall outside of NYC/airbnb norms.

first, check for invalid latitude and longitude*/

SELECT		* 
FROM		cleaned_listings
WHERE		latitude NOT BETWEEN 40.5 AND 40.9
			OR longitude NOT BETWEEN -74.25 AND -73.7;

/* the above code returned 18 entries i.e there are 18 listings outside of NYC
(this could be a typo error or delibrate mislocation)
Thus, I will flag them rather than dropping them.*/

ALTER TABLE airbnb_listings
ADD			valid_location BIT;

UPDATE		airbnb_listings
SET			valid_location = CASE	WHEN latitude NOT BETWEEN 40.5 AND 40.9
									OR longitude NOT BETWEEN -74.25 AND -73.7
									THEN 0 ELSE 1 
									END;


/* second, check for any availability_365 > 365 
(this returned an empty table, thus satisfied) */

SELECT		* 
FROM		cleaned_listings
WHERE		availability_365 > 365;

/* third, check for negative or zero price 
(this returned 11 entries with price 0, I will not drop this entries so as not to loose data 
but will always filter when necessary during analysis) */

SELECT		* 
FROM		cleaned_listings
WHERE		price <= 0;



/* to remodify the VIEW created (cleaned_listings) */

ALTER VIEW	cleaned_listings AS
			SELECT	id,
					host_id,
					host_name,
					neighbourhood_group,
					neighbourhood,
					latitude,
					longitude,
					valid_location,
					room_type,
					price,
					minimum_nights,
					number_of_reviews,
					last_review,
					review_status,
					reviews_per_month,
					calculated_host_listings_count,
					availability_365
FROM				airbnb_listings;



		 ---- EXPLORATORY DATA ANALYSIS EDA --- 
/* -- The goal is to analyze short-term rental activity in New York City for one of these stakeholders:
A real estate investor (vital question; Where should I buy a property for high rental returns?)
A short-let property management firm (vital question; How do my listings compare to others in my area?)
A data team inside Airbnb itself (vital question; Which hosts/areas should we target for onboarding or support?)*/
---

						--KPIs--

-- 1. Total Listings (Total supply of listings in the market)

SELECT		COUNT(id) AS Total_Listings 
FROM		cleaned_listings
WHERE		valid_location = 1;

-- 2. Active Listings (Listings with review, gauges market engagement)

SELECT		COUNT(id) AS Active_Listings 
FROM		cleaned_listings 
WHERE		valid_location = 1 AND  review_status = 1;

-- 3. Average Price (Understand market pricing level)

SELECT		FORMAT(AVG(price), 'C', 'en-US') AS Average_Price 
FROM		cleaned_listings
WHERE		valid_location = 1;

-- 4. Total Hosts (Unique hosts)

SELECT		COUNT(DISTINCT host_id) AS Total_Hosts 
FROM		cleaned_listings
WHERE		valid_location = 1;

-- 5. Average  Availability (See average number of available days per listing)

SELECT		AVG(availability_365) AS Average_Availability 
FROM		cleaned_listings
WHERE		valid_location = 1;

-- 6. Average Review per month (Demand and popularity measure)

SELECT		ROUND(AVG(reviews_per_month), 2) AS Avg_review_per_month 
FROM		cleaned_listings
WHERE		valid_location = 1;

/* Business Problems and Data Questions
1. Market Landscape (Understand the current state of Airbnb across NYC neighborhoods.)
Questions

How are listings distributed across neighborhoods?	
What types of rooms are most common in each neighborhood_group?	
Which areas have the highest average listing prices?		

2. Pricing and Profitability (Explore what drives prices and identify high-earning areas.)
Questions

What is the average price per neighborhood group, neighborhood, room type?
Are high prices tied to availability (e.g., high price + 365 available days)?
Which neighbourhood_group is likely generating the most income overall from Airbnb listings?
What minimum night values are common and how do they impact revenue potential?

3. Host Behavior & Market Control (Identify hosts with large portfolios and their strategies.)
Questions

Do commercial hosts (10+ listings) charge higher or lower than average?
How does average price per listing differ between commercial and non-commercial hosts?

4. Demand & Reviews (Use reviews as a proxy for demand/popularity.)
Questions

Which neighborhoods or listings have the most reviews?	
How does reviews_per_month differ by room type neighborhoods?
When was the last review in each listing? Are some inactive? */


-- How are listings distributed across neighborhoods_group?	

SELECT		neighbourhood_group, 
			COUNT(*) AS total_listings 
FROM		cleaned_listings
WHERE		valid_location = 1
GROUP BY	neighbourhood_group
ORDER BY	COUNT(*) DESC;


-- How are listings distributed across neighborhoods in each neighbourhood_group?

WITH		Ranked_neighbourhood AS (
			SELECT		neighbourhood_group,
						neighbourhood,
						COUNT(*) AS listing_count,
						RANK () OVER(PARTITION BY neighbourhood_group ORDER BY COUNT(*) DESC) AS group_rank
			FROM		cleaned_listings
			WHERE		valid_location = 1
			GROUP BY	neighbourhood_group, neighbourhood
			)

SELECT		neighbourhood_group,
			neighbourhood,
			listing_count
FROM		Ranked_neighbourhood
WHERE		group_rank <= 5
ORDER BY	neighbourhood_group, group_rank


-- What types of rooms are most common in each neighborhood_group (in percentage)?

SELECT		neighbourhood_group, 
			room_type, 
			COUNT(*) AS listings_count,
			CAST(ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) 
			OVER (PARTITION BY neighbourhood_group), 1) AS DECIMAL(3,1)) AS percentage
FROM		cleaned_listings
WHERE		valid_location = 1
GROUP BY	neighbourhood_group, room_type
ORDER BY	neighbourhood_group, listings_count DESC;


--  Which areas have the highest average listing prices?

SELECT		TOP 15	neighbourhood_group, 
					neighbourhood,  
					COUNT(*)  AS listings_count, 
					FORMAT(ROUND(AVG(price) , 0), 'C', 'en-US') AS Avg_price
FROM		cleaned_listings
GROUP BY	neighbourhood_group, neighbourhood
HAVING		COUNT(*) >= 10
ORDER BY	AVG(price) DESC;

/*	here, it is understood that some neighbourhoods have only 1 or 2 listings but have high prices.
	this will mislead our interpretation if we dont filter the volume. 
	That why I filter by neighbourhood with atleast 10 listings
	A threshold I got by finding the first quatile of listings by neighbourhood */

	WITH	listings_count	AS (
			SELECT		neighbourhood, 
						COUNT(*) AS listingscount 
			FROM		cleaned_listings
			WHERE		valid_location = 1
			GROUP BY	neighbourhood
			),
			CountQuartile AS (
			SELECT		percentile_cont(0.25) WITHIN GROUP (ORDER BY listingscount) 
						OVER () AS first_quartile
			FROM		listings_count
			)
	SELECT	DISTINCT first_quartile 
	FROM	CountQuartile;

/*	the query above, made it clear that the first quartile is 10, 
	this means 75% of neighbourhood have more than 10 listings */


-- What is the average price per neighborhood group, neighborhood, room type?

SELECT		neighbourhood_group, 
			neighbourhood, 
			room_type,
			COUNT(*) AS listing_count,
			FORMAT(ROUND(AVG(price), 0), 'C', 'en-US') AS Avg_Price,
			FORMAT(ROUND(MIN(price), 0), 'C', 'en-US') AS Min_Price,
			FORMAT(ROUND(MAX(price), 0), 'C', 'en-US') AS Max_Price
FROM		cleaned_listings
WHERE		price > 0 AND valid_location = 1
GROUP BY	neighbourhood_group, neighbourhood, room_type
HAVING		COUNT(*) >= 10
ORDER BY	AVG(Price) DESC;


-- Are high prices tied to availability (e.g., high price + 365 available days)?

SELECT		TOP 1000	id, 
						FORMAT(price, 'C', 'en-US') AS price,
						availability_365 
FROM		cleaned_listings
WHERE		price > 0 AND valid_location = 1
ORDER BY	price DESC;


-- Which neighbourhood_group is likely generating the most income overall from Airbnb listings?

SELECT		neighbourhood_group, 
			FORMAT(ROUND(SUM(price * availability_365), 0), 'C', 'en-US') AS Potential_Revenue,
			COUNT(*) Total_listings
FROM		cleaned_listings
WHERE		price > 0 AND valid_location = 1
GROUP BY	neighbourhood_group
ORDER BY	Potential_Revenue DESC;


-- What minimum night values are common and how do they impact revenue potential?

/* in the dataset, there quite numerous distinct minimum nights (100),
thus it becomes necessary to group the data for better analysis using a CASE STATEMENT as in the query */

SELECT		CASE 
			WHEN minimum_nights = 1 THEN '1 night'
			WHEN minimum_nights BETWEEN 2 AND 3 THEN '2-3 nights'
			WHEN minimum_nights BETWEEN 4 AND 6 THEN '4-6 nights'
			WHEN minimum_nights BETWEEN 7 AND 13 THEN '1-2 weeks'
			WHEN minimum_nights BETWEEN 14 AND 29 THEN '2-4 weeks'
			WHEN minimum_nights BETWEEN 30 AND 89 THEN '1-3 months'
			WHEN minimum_nights >= 90 THEN 'Over 3 months'
			ELSE 'Other'	
			END AS min_nights_groups, 
		COUNT(*) AS Total_listings,
		FORMAT(ROUND(SUM(price * availability_365), 0), 'C', 'en-US') AS Potential_Revenue,
		FORMAT(ROUND(AVG(price), 0), 'C', 'en-US') AS Avg_Price,
		ROUND(AVG(availability_365), 0) AS Avg_availability
FROM		cleaned_listings
WHERE		valid_location = 1
GROUP BY	CASE 
			WHEN minimum_nights = 1 THEN '1 night'
			WHEN minimum_nights BETWEEN 2 AND 3 THEN '2-3 nights'
			WHEN minimum_nights BETWEEN 4 AND 6 THEN '4-6 nights'
			WHEN minimum_nights BETWEEN 7 AND 13 THEN '1-2 weeks'
			WHEN minimum_nights BETWEEN 14 AND 29 THEN '2-4 weeks'
			WHEN minimum_nights BETWEEN 30 AND 89 THEN '1-3 months'
			WHEN minimum_nights >= 90 THEN 'Over 3 months'
			ELSE 'Other'	
			END
ORDER BY	Total_listings DESC;

-- How does average price per listing differ between commercial and non-commercial hosts?
/* and do commercial hosts (10+ listings) charge higher or lower than average? */

WITH		hosts_listing_count AS (
			SELECT		host_id,
						COUNT(*) AS listings_count
			FROM		cleaned_listings
			GROUP BY	host_id
			),
			hosts_class AS (
			SELECT		cl.host_id,
						cl.price,
						CASE	WHEN hlc.listings_count >= 10 THEN 'commercial_host'
								ELSE 'non_commercial_host'
								END AS host_type
			FROM		cleaned_listings cl
			JOIN		hosts_listing_count hlc
						ON cl.host_id = hlc.host_id
			WHERE		valid_location = 1
			)
SELECT		host_type,
			COUNT(*) AS total_listings,
			FORMAT(SUM(price), 'C', 'en-US') AS total_price,
			FORMAT(AVG(price), 'C', 'en-US') AS avg_price
FROM		hosts_class
GROUP BY	host_type

-- to get the average price of all listing, so as to compare with average price of commercial hosts

SELECT		FORMAT(AVG(price), 'C', 'en-US') AS avg_price_of_all_hosts
FROM		cleaned_listings
WHERE		valid_location = 1

/* from the query above, the avg_price for all listings is $141 and the avg_price for commercial host is $188
	this signifies that big/commercial hosts are probably charging premium, 
	possibly offering better property and location or might be branding trust. */


-- Which neighborhoods or listings have the most reviews?	

/* by neighbourhood */
SELECT		neighbourhood_group,
			neighbourhood,
			SUM(number_of_reviews) AS total_reviews
FROM		cleaned_listings
WHERE		review_status = 1 AND valid_location = 1
GROUP BY	neighbourhood_group, neighbourhood
ORDER BY	total_reviews DESC

/* by listings */
SELECT		id,
			host_id,
			neighbourhood_group,
			neighbourhood,
			number_of_reviews
FROM		cleaned_listings
WHERE		review_status = 1 AND valid_location = 1
ORDER BY	number_of_reviews DESC;


-- How does reviews_per_month differ by room type in neighborhoods_group?

SELECT		neighbourhood_group,
			room_type,
			ROUND(AVG(reviews_per_month), 2) AS avg_reviews_per_month
FROM		cleaned_listings
WHERE		valid_location = 1 AND review_status = 1 
GROUP BY	neighbourhood_group, room_type
ORDER BY	neighbourhood_group, AVG(reviews_per_month) DESC;

