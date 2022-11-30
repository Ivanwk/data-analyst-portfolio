# Sales Data Exploration using SQL and Tableau

## Table of Content
- [Business Task](#business-task)
- [SQL](#sql)
- [Tableau](#tableau)


## Business Task
Analyze sales dataset and generate various analytics and insights from customers' past purchase behavior.


## SQL
Inspecting Data
```sql
SELECT *
FROM sales_data_sample
```


Checking for unique values
```sql
SELECT DISTINCT STATUS FROM sales_data_sample
SELECT DISTINCT YEAR_ID FROM sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample
SELECT DISTINCT COUNTRY FROM sales_data_sample
SELECT DISTINCT DEALSIZE FROM sales_data_sample
SELECT DISTINCT TERRITORY FROM sales_data_sample
```


Analysis 1 - Sales by Product Line
```sql
SELECT PRODUCTLINE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC
```
![analysis1](https://user-images.githubusercontent.com/32184014/204180782-a061baa2-2eb2-4377-8b69-4312f6097fbb.png)

Classis Cars has made the most sales followed by Vintage Cars


Analysis 2 - Sales by Year
```sql
SELECT YEAR_ID, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY REVENUE DESC
```
![analysis2_1](https://user-images.githubusercontent.com/32184014/204180858-839122b7-1a43-4d83-8d8b-ecb7d7e2f907.png)

The year 2004 has made the most sales followed by 2003, and sales have dropped significantly in 2005

```sql
SELECT DISTINCT YEAR_ID, MONTH_ID
FROM sales_data_sample
ORDER BY YEAR_ID, MONTH_ID
```
![analysis2_2](https://user-images.githubusercontent.com/32184014/204180864-edf7499a-f99e-4ce7-aaf7-6216db87951e.png)

Here we can see that the year 2005 has only made sales in only 5 months, whereas 2003 and 2004 has made sales in a full year


Analysis 3 - Sales by Deal Size
```sql
SELECT DEALSIZE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY REVENUE DESC
```
![analysis3](https://user-images.githubusercontent.com/32184014/204180935-0e171005-dc0c-484f-b8f9-c85386314b3f.png)

The Medium deal size has made the most sales followed by the Small deal size


Analysis 4 - Best Month for Sales per Year
```sql
SELECT YEAR_ID, MONTH_ID, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
GROUP BY  YEAR_ID, MONTH_ID
ORDER BY REVENUE DESC
```
![analysis4](https://user-images.githubusercontent.com/32184014/204180947-ef7e9473-5904-4735-ae77-c7bd64e7a3b3.png)

November made the most sales followed by October


Analysis 5 - What Product Line Sells the Most in November?
```sql
SELECT  YEAR_ID, MONTH_ID, PRODUCTLINE, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE MONTH_ID = 11
GROUP BY  YEAR_ID, MONTH_ID, PRODUCTLINE
ORDER BY REVENUE DESC
```
![analysis5](https://user-images.githubusercontent.com/32184014/204180953-758fe952-53dc-4e24-84b3-f07bf159494f.png)

Classic Cars has the most sales in November, almost double the number of Vintage Cars sold


Analysis 6 - What city has the highest number of sales in a specific country?
```sql
SELECT COUNTRY, CITY, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY COUNTRY, CITY
ORDER BY REVENUE DESC
```
![analysis6](https://user-images.githubusercontent.com/32184014/204180969-deba0b24-843d-4afb-89fe-983137daa095.png)

Madrid in Spain has the made the most sales followed by San Rafael in the USA


Analysis 7 - What is the best product in a specific country?
```sql
SELECT Country, City, SUM(Sales) AS Revenue
SELECT COUNTRY, YEAR_ID, PRODUCTLINE, SUM(SALES) AS REVENUE
FROM sales_data_sample
GROUP BY  COUNTRY, YEAR_ID, PRODUCTLINE
ORDER BY REVENUE DESC
```
![analysis7](https://user-images.githubusercontent.com/32184014/204180976-61c16bab-29f2-4eaf-828e-3035f1577c0b.png)

Seems like the best product in almost any country is Classic Cars


Analysis 8 - Who is the Best Customer?
Recency-Frequency-Monetary (RFM) - An indexing technique that uses past purchase behavior to segment customers 
Recency - last order date, Frequency - count of total orders, Monetary Value - total spend
```sql
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
```
![analysis8](https://user-images.githubusercontent.com/32184014/204180986-a444f773-a7eb-4784-b885-8c91a10f5727.png)


Analysis 9 - What Products are most often sold together?
```sql
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
		WHERE rn = 3
	)
	AND p.ORDERNUMBER = s.ORDERNUMBER
	FOR XML PATH ('')), 1, 1, '') AS product_codes
FROM sales_data_sample s
ORDER BY product_codes DESC
```
![analysis9](https://user-images.githubusercontent.com/32184014/204180989-f9f70731-d15e-4306-9cb5-913415e37362.png)


## Tableau
[Tableau Dashboard 1](https://public.tableau.com/app/profile/ivan.wei.ket.yap/viz/Sales_Dashboard_1_16695980836810/SalesDashboard1)

![Sales Dashboard 1](https://user-images.githubusercontent.com/32184014/204191982-337642cf-bc40-412b-a2d4-ff811c03ce6f.png)

[Tableau Dashboard 2](https://public.tableau.com/app/profile/ivan.wei.ket.yap/viz/Sales_Dashboard_2_16695981453170/SalesDashboard2)

![Sales Dashboard 2](https://user-images.githubusercontent.com/32184014/204191986-e6832df0-36b9-46d0-a13b-a572e666b238.png)
