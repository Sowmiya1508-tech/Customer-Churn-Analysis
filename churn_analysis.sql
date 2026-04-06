-- ================================================
-- CUSTOMER CHURN ANALYSIS - SQL SCRIPT
-- Author: Sowmiya Devi
-- Tool: MySQL Workbench
-- Date: April 2026
-- ================================================

USE churn_project;

-- ================================================
-- PHASE 1: DATA EXPLORATION
-- ================================================

DESCRIBE churn_raw;

SELECT COUNT(*) AS total_customers 
FROM churn_raw;

SELECT churn, COUNT(*) AS total, ROUND(COUNT(*) * 100.0/SUM(COUNT(*)) OVER(),2) AS percentage
FROM churn_raw
GROUP BY churn;

-- ================================================
-- PHASE 2: DATA CLEANING
-- ================================================

ALTER TABLE churn_raw
MODIFY COLUMN TotalCharges DOUBLE;

SELECT SUM(case when TotalCharges is null THEN 1 ELSE 0 END) as null_total_charges,
SUM(case when MonthlyCharges is null THEN 1 ELSE 0 END) as null_monthly_charges
FROM churn_raw;

-- ================================================
-- PHASE 3: FEATURE ENGINEERING
-- ================================================

USE churn_project;
ALTER TABLE churn_raw ADD COLUMN Tenure_Group VARCHAR(20);

UPDATE churn_raw
SET Tenure_Group = CASE
	WHEN Tenure between 0 and 6 THEN '0-6 Months'
    WHEN Tenure between 7 and 12 THEN '7-12 Months'
	WHEN Tenure between 13 and 24 THEN '13-24 Months'
    WHEN Tenure between 25 and 48 THEN '25-48 Months'
    ELSE '49+ Months'
end;

ALTER TABLE churn_raw ADD COLUMN chrun_Flag INT;

ALTER TABLE churn_raw
RENAME COLUMN chrun_Flag to churn_Flag;

UPDATE churn_raw
SET churn_Flag = CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END;

ALTER TABLE churn_raw ADD COLUMN Customer_Type VARCHAR(20);

UPDATE churn_raw
SET Customer_Type = CASE
	WHEN Tenure <=12 THEN 'New'
    ELSE 'Existing'
END;

SELECT CustomerID, Tenure, Tenure_Group, Churn, Churn_Flag, Customer_Type
FROM churn_raw
LIMIT 5;

-- ================================================
-- PHASE 4: CHURN ANALYSIS
-- ================================================
    
 ALTER TABLE churn_raw
RENAME COLUMN ï»¿CustomerID to CustomerID;   

-- Churn by Contract Type
SELECT Contract, 
	COUNT(*) AS total_customers,
    ROUND(SUM(churn_Flag) * 100.0/COUNT(*),2) AS churn_rate
FROM churn_raw
GROUP BY Contract
ORDER BY churn_rate DESC;

-- Churn by Internet Service
SELECT 	InternetService, 
	COUNT(*) AS total_customers,
    SUM(churn_Flag) AS churned,
    ROUND(SUM(churn_Flag) * 100.0/COUNT(*),2) AS churn_rate
FROM churn_raw
GROUP BY InternetService
ORDER BY churn_rate DESC;

-- Churn by Tenure Group
SELECT Tenure_Group, 
	COUNT(*) AS total_customers,
    SUM(churn_Flag) AS churned,
    ROUND(SUM(churn_Flag) * 100.0/COUNT(*),2) AS churn_rate
FROM churn_raw
GROUP BY Tenure_Group
ORDER BY churn_rate DESC;

-- Churn by Payment Method
SELECT PaymentMethod, 
	COUNT(*) AS total_customers,
    SUM(churn_Flag) AS churned,
    ROUND(SUM(churn_Flag) * 100.0/COUNT(*),2) AS churn_rate
FROM churn_raw
GROUP BY PaymentMethod
ORDER BY churn_rate DESC;

-- Average Charges Churned vs Retained
SELECT Churn,
	ROUND(AVG(MonthlyCharges),2) AS avg_monthly_charges,
    ROUND(AVG(Totalcharges),2) AS avg_total_charges
FROM churn_raw
GROUP BY Churn;

-- ================================================
-- PHASE 5: ADVANCED SQL
-- ================================================

-- CTE: High Value Churned Customers
WITH high_value_churned AS (
    SELECT 
        CustomerID,
        MonthlyCharges,
        TotalCharges,
        Contract,
        Tenure_Group
    FROM churn_raw
    WHERE Churn = 'Yes' 
    AND MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM churn_raw)
)
SELECT * FROM high_value_churned
ORDER BY MonthlyCharges DESC
LIMIT 10;

-- Window Function: Churn Rate Ranking
SELECT Contract,
	InternetService,
    COUNT(*) AS total,
    SUM(Churn_Flag) AS churned,
    ROUND(SUM(Churn_Flag) * 100.0 /COUNT(*), 2) AS churn_rate,
    RANK() OVER(ORDER BY SUM(Churn_Flag) * 100.0 /COUNT(*) DESC) AS risk_rank
FROM churn_raw
GROUP BY Contract, InternetService;

-- CTE: Churn Risk Scoring
WITH risk_score AS(
	SELECT CustomerID, MonthlyCharges, Tenure, Contract,
		CASE WHEN Contract = 'Month-to-Month' and Tenure < 12 and MonthlyCharges > 65 THEN 'High Risk'
			 WHEN Contract = 'Month-to-Month' and Tenure between 12 and 24 THEN 'Medium Risk'
			ELSE 'Low Risk'
		END AS churn_risk
	FROM churn_raw
    WHERE Churn = 'NO'
)
SELECT churn_risk,
COUNT(*) AS total_customers,
ROUND(AVG(MonthlyCharges),2) as avg_monthly_charges
FROM risk_score
GROUP BY churn_risk
ORDER BY total_customers DESC;

-- ================================================
-- PHASE 6: BUSINESS SUMMARY
-- ================================================

SELECT COUNT(*) AS total_customers,
	SUM(Churn_Flag) AS total_churned,
    ROUND(SUM(Churn_Flag)*100.0 / COUNT(*), 2) as overall_churn_rate,
    ROUND(AVG(MonthlyCharges),2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN Churn = 'Yes'
		THEN MonthlyCharges ELSE 0 END),2) AS revenue_lost_monthly
FROM churn_raw;




	

