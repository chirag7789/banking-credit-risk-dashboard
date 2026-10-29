-- Banking Credit Risk & Loan Portfolio Analytics (MySQL / PostgreSQL compatible)
CREATE TABLE loan_portfolio (
 Loan_ID VARCHAR(12) PRIMARY KEY, Customer_ID VARCHAR(12), Origination_Date DATE, Region VARCHAR(30),
 Customer_Segment VARCHAR(20), Loan_Type VARCHAR(30), Employment_Type VARCHAR(20), Age INT, Annual_Income DECIMAL(14,0),
 Credit_Score INT, Loan_Amount DECIMAL(14,0), Interest_Rate_Pct DECIMAL(5,2), Tenure_Months INT, Collateral_Type VARCHAR(25),
 Collateral_Value DECIMAL(14,0), DTI_Pct DECIMAL(5,1), Outstanding_Balance DECIMAL(14,0), Days_Past_Due INT, Loan_Status VARCHAR(20),
 Default_Flag TINYINT, Risk_Grade CHAR(1), PD DECIMAL(6,4), LGD DECIMAL(5,3), EMI DECIMAL(12,0), LTV_Pct DECIMAL(6,1),
 Delinquency_Bucket VARCHAR(20), Expected_Loss DECIMAL(14,0), Origination_Year INT);
-- Load: import 02_Dataset_Files/Processed_Dataset/loan_portfolio_processed.csv (Workbench Import Wizard, or COPY in PostgreSQL)

-- 1. Portfolio KPIs
SELECT COUNT(*) loans, SUM(Outstanding_Balance)/1e7 exposure_cr, AVG(Default_Flag) npa_rate,
 SUM(Expected_Loss)/1e7 el_cr, SUM(Expected_Loss)/SUM(Outstanding_Balance) el_pct FROM loan_portfolio;
-- 2. Exposure and NPA by loan type
SELECT Loan_Type, COUNT(*) loans, SUM(Outstanding_Balance)/1e7 exposure_cr, AVG(Default_Flag) npa_rate
FROM loan_portfolio GROUP BY Loan_Type ORDER BY exposure_cr DESC;
-- 3. Delinquency buckets
SELECT Delinquency_Bucket, COUNT(*) loans, SUM(Outstanding_Balance)/1e7 exposure_cr FROM loan_portfolio GROUP BY Delinquency_Bucket;
-- 4. Region risk ranking (window function)
SELECT Region, SUM(Expected_Loss)/SUM(Outstanding_Balance) el_pct,
 RANK() OVER (ORDER BY SUM(Expected_Loss)/SUM(Outstanding_Balance) DESC) risk_rank FROM loan_portfolio GROUP BY Region;
-- 5. Vintage analysis
SELECT Origination_Year, COUNT(*) loans, AVG(Default_Flag) npa_rate FROM loan_portfolio GROUP BY Origination_Year ORDER BY 1;
-- 6. Credit score band vs PD
SELECT CASE WHEN Credit_Score<600 THEN '<600' WHEN Credit_Score<650 THEN '600-649' WHEN Credit_Score<700 THEN '650-699'
 WHEN Credit_Score<750 THEN '700-749' WHEN Credit_Score<800 THEN '750-799' ELSE '800+' END score_band, AVG(PD) avg_pd, AVG(Default_Flag) npa_rate
FROM loan_portfolio GROUP BY 1 ORDER BY 1;
-- 7. Top 10 loan type x region segments by expected loss
SELECT Loan_Type, Region, SUM(Expected_Loss)/1e7 el_cr FROM loan_portfolio GROUP BY Loan_Type, Region ORDER BY el_cr DESC LIMIT 10;
-- 8. High-risk watchlist: grade D-F, secured loans with LTV above 80%
SELECT Loan_ID, Loan_Type, Region, Outstanding_Balance, LTV_Pct, Days_Past_Due FROM loan_portfolio
WHERE Risk_Grade IN ('D','E','F') AND LTV_Pct>80 ORDER BY Outstanding_Balance DESC LIMIT 100;
