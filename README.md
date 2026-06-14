# stripe-payment-analytics
End-to-end payment analytics project using Stripe API, PostgreSQL, and Power BI

# Stripe Payment Risk & Revenue Analytics

## Objective
To analyze real-world payment transactions and uncover revenue patterns, fee burden, and fraud risk across geographies, card types, and product categories.

## Tech Stack
- **Python** — Stripe API data extraction
- **Power Query** — Data cleaning and transformation
- **Power BI / DAX** — Data modeling and dashboard
- **PostgreSQL** — Structured querying and analysis

## Data Source
Data was collected using **Stripe's Test Mode API**, which mirrors the exact structure of production payment data. 3,200 transactions were generated and extracted across 8 countries, 3 currencies, and 5 product categories. While transaction values are simulated, the entire pipeline — API integration, cleaning, modeling, and analysis — follows the same workflow as real production data.

## Workflow

### 1. Data Extraction
- Used Python and Stripe's REST API to extract 3,200 transactions
- Two datasets generated: `charges` and `balance transactions`

### 2. Data Cleaning (Power Query)
- Removed 13 redundant/null columns (failure codes, receipt emails, etc.)
- Fixed data types (currency, datetime, integers)
- Standardized text casing across categorical fields
- Split timestamp into separate date and time components

### 3. Data Modeling (Star Schema)
Built a star schema with:
- **Fact_Transactions** — central fact table with Amount, Risk Score, Fee, Net, and foreign keys
- **Dim_Country** — 8 countries with full country names
- **Dim_Card** — card brand and funding type combinations
- **Dim_Currency** — USD, EUR, GBP
- **Dim_Product** — 5 product categories


### 4. DAX Measures
Developed 15+ measures across organized folders including:
- Revenue and fee measures (Total Revenue, Total Fees, Avg Fee Per Transaction)
- Risk measures (Avg Risk Score, High Risk Count, High Risk Revenue)
- Advanced measures using `RANKX`, `ALLSELECTED`, and nested `CALCULATE + FILTER`
- Currency conversion column (`Amount USD`) to normalize USD/EUR/GBP into a single currency

### 5. Power BI Dashboard
A single-page interactive dashboard featuring:
- 6 KPI cards (Total Revenue, Total Fees, Transaction Count, Avg Fee, Avg Transaction Value, Fee Percentage)
- Revenue breakdown by country, currency, and card brand
- Risk analysis by country (high risk count vs avg risk score)
- Gauge chart for overall risk score
- Matrix table combining revenue, risk, and transaction metrics
- Dynamic slicers (Currency, Country, Product Category, Risk Category) and reset button


### 6. SQL Analysis (PostgreSQL)
Loaded cleaned data into PostgreSQL and wrote 10 analytical queries using:
- Window functions (`RANK`, `ROW_NUMBER`, running totals)
- Subqueries and correlated subqueries
- Aggregations with `HAVING` and `CASE WHEN`


## Key Insights
- **United States** drives **31%** of total revenue across the dataset
- **Credit cards** account for **67%** of all transactions vs 33% debit
- **30.5%** of transactions fall into the high-risk category (risk score > 45)
- **Mastercard and Visa** together contribute over 67% of total revenue
- Average risk scores are fairly consistent across countries (~32-35), suggesting risk is uniformly distributed rather than geography-driven

## Repository Structure
## Note on Data
This project uses Stripe's test mode, which generates simulated transaction data with the same structure as production data. The focus of this project is demonstrating the complete analytics pipeline — from API extraction to dashboard — rather than deriving business insights from real transaction data.

## Author
**Tanmay Tiwari**  
[LinkedIn](https://linkedin.com/in/tanmay-tiwari-706b02228) | [GitHub](https://github.com/tanmay218)
