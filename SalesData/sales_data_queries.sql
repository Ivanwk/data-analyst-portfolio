-- Inspecting Data
SELECT *
FROM sales_data_sample


-- Checking for unique values
SELECT DISTINCT STATUS FROM sales_data_sample
SELECT DISTINCT YEAR_ID FROM sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample
SELECT DISTINCT COUNTRY FROM sales_data_sample
SELECT DISTINCT DEALSIZE FROM sales_data_sample
SELECT DISTINCT TERRITORY FROM sales_data_sample


--- ANALYSIS
-- Analysis 1 - Sales by Product Line
-- Here we can see that Classis Cars has made the most sales followed by Vintage Cars
SELECT PRODUCTLINE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC


-- Analysis 2 - Sales by Year
-- Here we can see that 2004 has made the most sales followed by 2003, and sales have dropped significantly in 2005
SELECT YEAR_ID, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY REVENUE DESC

-- Here we can see that the year 2005 has only made sales in only 5 months, whereas 2003 and 2004 has made sales in a full year
SELECT DISTINCT YEAR_ID, MONTH_ID
FROM sales_data_sample
ORDER BY YEAR_ID, MONTH_ID


-- Analysis 3 - Sales by Deal Size
-- Here we can see that the Medium deal size has made the most sales followed by the Small deal size
SELECT DEALSIZE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY REVENUE DESC


-- Analysis 4 - Best Month for Sales per Year
-- What was the best month for sales in a specific year? How much was earned that month? 
-- Here we can see that November made the most sales followed by October
SELECT YEAR_ID, MONTH_ID, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
GROUP BY  YEAR_ID, MONTH_ID
ORDER BY REVENUE DESC


-- Analysis 5 - What Product Line Sells the Most in November?
-- It seems that Classic Cars has the most sales in November, almost double the number of Vintage Cars sold
SELECT  YEAR_ID, MONTH_ID, PRODUCTLINE, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE MONTH_ID = 11
GROUP BY  YEAR_ID, MONTH_ID, PRODUCTLINE
ORDER BY REVENUE DESC


-- Analysis 6 - What city has the highest number of sales in a specific country?
-- Madrid in Spain has the made the most sales followed by San Rafael in the USA
SELECT COUNTRY, CITY, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY COUNTRY, CITY
ORDER BY REVENUE DESC


-- Analysis 7 - What is the best product in a specific country?
-- Seems like the best product in almost any country is Classic Cars
SELECT COUNTRY, YEAR_ID, PRODUCTLINE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY  COUNTRY, YEAR_ID, PRODUCTLINE
ORDER BY REVENUE DESC


-- Analysis 8 - Who is the Best Customer?
-- Recency-Frequency-Monetary (RFM) - An indexing technique that uses past purchase behavior to segment customers 
-- Recency - last order date, Frequency - count of total orders, Monetary Value - total spend
DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
SELECT 
	CUSTOMERNAME,
	SUM(sales) AS MonetaryValue,
	AVG(sales) AS AvgMonetaryValue,
	COUNT(ORDERNUMBER) AS Frequency,
	MAX(ORDERDATE) AS last_order_date,
	(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
	DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) Recency
FROM sales_data_sample
GROUP BY CUSTOMERNAME
),
rfm_calc AS
(
SELECT *, 
	NTILE(4) OVER(ORDER BY Recency) AS rfm_recency,
	NTILE(4) OVER(ORDER BY Frequency) AS rfm_frequency,
	NTILE(4) OVER(ORDER BY MonetaryValue) AS rfm_monetary
FROM rfm
)
SELECT *, 
	rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) AS rfm_cell_string
	INTO #rfm
FROM rfm_calc

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  -- lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential customer'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'active' -- Customers who buy often & recently, but at low price points
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment
FROM #rfm


-- Analysis 9 - What products are most often sold together?
SELECT DISTINCT ORDERNUMBER, STUFF(
	(SELECT ',' + PRODUCTCODE
	FROM sales_data_sample p
	WHERE ORDERNUMBER IN (

		SELECT ORDERNUMBER
		FROM (
			SELECT ORDERNUMBER, COUNT(*) AS rn
			FROM sales_data_sample
			WHERE STATUS = 'Shipped'
			GROUP BY ORDERNUMBER
		) m
		WHERE rn = 2	-- Change this value to get different number of products sold together
	)
	AND p.ORDERNUMBER = s.ORDERNUMBER
	FOR XML PATH ('')), 1, 1, '') AS product_codes
FROM sales_data_sample s
ORDER BY product_codes DESC
