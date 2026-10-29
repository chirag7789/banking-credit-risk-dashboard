# Power BI Build Kit – Credit Risk & Loan Portfolio

## 1. Load data
1. Power BI Desktop → Get Data → Excel → `Banking_Credit_Risk_Loan_Portfolio_80000.xlsx` → select **Loan_Data** → Transform Data.
2. Set types: dates = Date, amounts = Fixed decimal, PD/LGD = Decimal. Rename table to `Loans`. Close & Apply.
3. Optional: Modeling → New table → `DimDate = CALENDAR(DATE(2000,1,1), DATE(2026,12,31))`, relate `DimDate[Date]` to `Loans[Origination_Date]`.

## 2. Calculated columns (Loans table)
```
Score Band = SWITCH(TRUE(), Loans[Credit_Score]<600,"<600", Loans[Credit_Score]<650,"600-649", Loans[Credit_Score]<700,"650-699", Loans[Credit_Score]<750,"700-749", Loans[Credit_Score]<800,"750-799","800+")
Orig Year = YEAR(Loans[Origination_Date])
```

## 3. Measures
```
Total Loans = COUNTROWS(Loans)
Exposure = SUM(Loans[Outstanding_Balance])
Exposure Cr = DIVIDE([Exposure], 10000000)
NPA Loans = CALCULATE([Total Loans], Loans[Days_Past_Due] > 90)
NPA Rate = DIVIDE([NPA Loans], [Total Loans])
GNPA Amount = CALCULATE([Exposure], Loans[Days_Past_Due] > 90)
GNPA % = DIVIDE([GNPA Amount], [Exposure])
Expected Loss = SUMX(Loans, Loans[PD] * Loans[LGD] * Loans[Outstanding_Balance])
EL % = DIVIDE([Expected Loss], [Exposure])
Avg PD = AVERAGE(Loans[PD])
Avg Credit Score = AVERAGE(Loans[Credit_Score])
Avg LTV = AVERAGEX(FILTER(Loans, Loans[Collateral_Value] > 0), DIVIDE(Loans[Outstanding_Balance], Loans[Collateral_Value]))
Early Delinquency % = DIVIDE(CALCULATE([Total Loans], Loans[Days_Past_Due] > 0, Loans[Days_Past_Due] <= 90), [Total Loans])
Exposure Share = DIVIDE([Exposure], CALCULATE([Exposure], ALL(Loans)))
High Risk Exposure % = DIVIDE(CALCULATE([Exposure], Loans[Risk_Grade] IN {"D","E","F"}), [Exposure])
```

## 4. Report layout (16:9, 3 pages)
**Page 1 – Executive Overview**
- Top row: 6 Card visuals → Total Loans, Exposure Cr, GNPA %, NPA Rate, EL %, Avg PD.
- Slicers: Loan_Type, Region, Orig Year, Customer_Segment.
- Clustered bar: Exposure Cr by Loan_Type. Donut: Exposure by Risk_Grade.
- Filled map / bar: NPA Rate by Region. Line + column: Exposure Cr and NPA Rate by Orig Year.

**Page 2 – Credit Risk Deep Dive**
- Column chart: Total Loans by Delinquency_Bucket. Column: Avg PD by Score Band.
- Matrix heatmap: Loan_Type (rows) × Region (columns), value = EL %, with conditional formatting (background colour scale white → red).
- Scatter: X = Avg Credit Score, Y = NPA Rate, size = Exposure, legend = Loan_Type.
- Decomposition tree: Expected Loss by Region → Loan_Type → Risk_Grade.

**Page 3 – Loan Detail**
- Table: Loan_ID, Customer_ID, Loan_Type, Region, Outstanding_Balance, Days_Past_Due, Risk_Grade, PD, Expected_Loss. Drill-through from Page 1/2.
- Add a Top N filter (Top 25 by Expected_Loss).

## 5. Theme
Save as `CreditRiskTheme.json`, then View → Themes → Browse for themes:
```json
{
  "name": "CreditRisk",
  "dataColors": ["#1F3864","#0F8B8D","#E9A23B","#C8423B","#6BBF8A","#7AA2E8","#C9C35A","#E0743F"],
  "background": "#FFFFFF",
  "foreground": "#14213D",
  "tableAccent": "#1F3864",
  "textClasses": {
    "title": {"fontFace": "Segoe UI Semibold", "fontSize": 14, "color": "#14213D"},
    "label": {"fontFace": "Segoe UI", "fontSize": 11, "color": "#5B6B85"}
  }
}
```
Set page background to `#EEF1F5`, and give each visual a white card background, thin `#DBE1EA` border and 8px rounded corners.

## 6. Finish
File → Save As → `Credit_Risk_Dashboard.pbix`. Publish to Power BI Service for sharing.
