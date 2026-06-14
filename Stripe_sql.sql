-- Create charges table
CREATE TABLE stripe_charges (
    charge_id VARCHAR(255),
    amount DECIMAL(10,2),
    currency VARCHAR(10),
    description VARCHAR(255),
    created_at TIMESTAMP,
    card_brand VARCHAR(50),
    card_funding VARCHAR(50),
    customer_country VARCHAR(10),
    product_category VARCHAR(50),
    risk_score INTEGER,
    time TIME
);

-- Create balance table
CREATE TABLE stripe_balance (
    txn_id VARCHAR(255),
    amount DECIMAL(10,2),
    fee DECIMAL(10,2),
    net DECIMAL(10,2),
    charge_id VARCHAR(255)
);

ALTER TABLE stripe_charges DROP COLUMN time;

SELECT COUNT(*) FROM stripe_charges;
SELECT COUNT(*) FROM stripe_balance;

ALTER TABLE stripe_charges ADD COLUMN full_country_name VARCHAR(50);

UPDATE stripe_charges
SET full_country_name = 
    CASE customer_country
        WHEN 'US' THEN 'United States'
        WHEN 'GB' THEN 'United Kingdom'
        WHEN 'DE' THEN 'Germany'
        WHEN 'FR' THEN 'France'
        WHEN 'CA' THEN 'Canada'
        WHEN 'AU' THEN 'Australia'
        WHEN 'IN' THEN 'India'
        WHEN 'SG' THEN 'Singapore'
        ELSE 'Unknown'
    END;

-- Query 1: Rank countries by total revenue using window function
SELECT 
    full_country_name,
    ROUND(SUM(amount)::NUMERIC, 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank
FROM stripe_charges
GROUP BY full_country_name
ORDER BY revenue_rank;


-- Query 2: Find transactions above the average transaction value for each product category
SELECT 
    charge_id,
    product_category,
    amount,
    ROUND(AVG(amount) OVER (PARTITION BY product_category)::NUMERIC, 2) AS avg_category_amount
FROM stripe_charges
WHERE amount > (
    SELECT AVG(amount) 
    FROM stripe_charges sc2 
    WHERE sc2.product_category = stripe_charges.product_category
)
ORDER BY product_category, amount DESC;


-- Query 3: Calculate cumulative revenue over transactions per country
SELECT 
    charge_id,
    amount,
    full_country_name,
    ROUND(SUM(amount) OVER (
        PARTITION BY full_country_name 
        ORDER BY charge_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) AS cumulative_revenue
FROM stripe_charges
ORDER BY full_country_name, charge_id;


-- Query 4: Find the top 3 highest spending transactions by country
SELECT 
    full_country_name,
    charge_id,
    amount
FROM stripe_charges sc1
WHERE charge_id IN (
    SELECT charge_id 
    FROM (
        SELECT 
            charge_id,
            full_country_name,
            amount,
            ROW_NUMBER() OVER (
                PARTITION BY full_country_name 
                ORDER BY amount DESC
            ) AS rn
        FROM stripe_charges
    ) ranked
    WHERE rn <= 3
)
ORDER BY full_country_name, amount DESC;


-- Query 5: Calculate fee efficiency - ratio of net revenue to gross amount per card brand
SELECT 
    sc.card_brand,
    ROUND(SUM(sc.amount)::NUMERIC, 2) AS total_gross,
    ROUND(SUM(sb.fee)::NUMERIC, 2) AS total_fees,
    ROUND(SUM(sb.net)::NUMERIC, 2) AS total_net,
    ROUND((SUM(sb.net) / NULLIF(SUM(sc.amount), 0) * 100)::NUMERIC, 2) AS net_efficiency_pct
FROM stripe_charges sc
LEFT JOIN stripe_balance sb ON sc.charge_id = sb.charge_id
GROUP BY sc.card_brand
ORDER BY net_efficiency_pct DESC;


-- Query 6: Identify high risk transactions with above average amount
SELECT 
    charge_id,
    amount,
    risk_score,
    full_country_name,
    card_brand,
    ROUND(AVG(amount) OVER ()::NUMERIC, 2) AS overall_avg_amount,
    ROUND(AVG(risk_score) OVER ()::NUMERIC, 2) AS overall_avg_risk
FROM stripe_charges
WHERE risk_score > 45 
AND amount > (SELECT AVG(amount) FROM stripe_charges)
ORDER BY risk_score DESC, amount DESC;


-- Query 7: Product category performance - revenue, transaction count and avg risk score
SELECT 
    product_category,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_transaction_value,
    ROUND(AVG(risk_score)::NUMERIC, 2) AS avg_risk_score,
    ROUND((SUM(amount) / SUM(SUM(amount)) OVER () * 100)::NUMERIC, 2) AS revenue_share_pct
FROM stripe_charges
GROUP BY product_category
ORDER BY total_revenue DESC;


-- Query 8: Find card brands where average risk score is above overall average
SELECT 
    card_brand,
    card_funding,
    ROUND(AVG(risk_score)::NUMERIC, 2) AS avg_risk_score,
    ROUND(AVG(amount)::NUMERIC, 2) AS avg_amount,
    COUNT(*) AS transaction_count
FROM stripe_charges
GROUP BY card_brand, card_funding
HAVING AVG(risk_score) > (
    SELECT AVG(risk_score) 
    FROM stripe_charges
)
ORDER BY avg_risk_score DESC;


-- Query 9: Revenue contribution percentage by currency with running total
SELECT 
    currency,
    ROUND(SUM(amount)::NUMERIC, 2) AS total_revenue,
    ROUND((SUM(amount) / SUM(SUM(amount)) OVER () * 100)::NUMERIC, 2) AS revenue_share_pct,
    ROUND(SUM(SUM(amount)) OVER (
        ORDER BY SUM(amount) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::NUMERIC, 2) AS cumulative_revenue
FROM stripe_charges
GROUP BY currency
ORDER BY total_revenue DESC;


-- Query 10: Compare high value transactions (amount > 300) vs normal transactions per country
SELECT 
    full_country_name,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN amount > 300 THEN 1 ELSE 0 END) AS high_value_count,
    SUM(CASE WHEN amount <= 300 THEN 1 ELSE 0 END) AS normal_count,
    ROUND(SUM(CASE WHEN amount > 300 THEN amount ELSE 0 END)::NUMERIC, 2) AS high_value_revenue,
    ROUND((SUM(CASE WHEN amount > 300 THEN 1 ELSE 0 END)::NUMERIC * 100 / 
        NULLIF(COUNT(*), 0)), 2) AS high_value_pct
FROM stripe_charges
GROUP BY full_country_name
ORDER BY high_value_pct DESC;