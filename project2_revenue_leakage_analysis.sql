/*
================================================================================
  PROJECT 2 — REVENUE LEAKAGE ANALYSIS
  Order Cancellations, Returns & Lost Revenue Recovery
================================================================================

  Author        : MD FAHIM HASAN JALANEY
  Tool          : PostgreSQL 18 (pgAdmin 4) or DBeaver(used it)
  Dataset       : E-Commerce Orders (1,200 records | Jan 2023 – Jun 2025)
  GitHub        : https://github.com/fahimhasan-data
  LinkedIn      : https://www.linkedin.com/in/md-fahim-hasan-jalaney/

--------------------------------------------------------------------------------
  BUSINESS PROBLEM
--------------------------------------------------------------------------------
  An e-commerce business is losing significant revenue through order
  cancellations and returns, but has no visibility into:

    1. Which products are bleeding the most revenue?
    2. Which payment methods correlate with highest cancellation rates?
    3. Which marketing channels bring in low-quality, high-risk orders?
    4. Are discount coupons being abused to get free returns?
    5. Is the problem getting worse month over month?

  Without answers, the business is spending marketing budget to acquire
  customers who cancel, and operations cost to process returns with no
  corrective action.

--------------------------------------------------------------------------------
  OBJECTIVE
--------------------------------------------------------------------------------
  Quantify every dollar of lost revenue, identify root causes by product,
  payment method, marketing channel, and coupon usage — then deliver
  actionable business decisions to reduce leakage by a target of 15-20%.

--------------------------------------------------------------------------------
  DATASET COLUMNS
--------------------------------------------------------------------------------
  OrderID          — Unique order identifier
  Date             — Order date (YYYY-MM-DD)
  CustomerID       — Unique customer identifier
  Product          — Product category (Laptop, Phone, Tablet, etc.)
  Quantity         — Number of units ordered
  UnitPrice        — Price per unit
  ShippingAddress  — Delivery address
  PaymentMethod    — Payment type (Credit Card, Debit Card, Cash, etc.)
  OrderStatus      — Current status (Delivered, Shipped, Pending,
                     Cancelled, Returned)
  TrackingNumber   — Shipment tracking ID
  ItemsInCart      — Total items in cart at time of order
  CouponCode       — Discount code applied (SAVE10, FREESHIP, WINTER15)
  ReferralSource   — Acquisition channel (Google, Instagram, Facebook, etc.)
  TotalPrice       — Final order value

--------------------------------------------------------------------------------
  ANALYSIS ROADMAP
--------------------------------------------------------------------------------
  SECTION 0  — Database Setup & Data Import
  SECTION 1  — Data Quality & Validation
  SECTION 2  — Revenue Health Overview
  SECTION 3  — Lost Revenue by Product
  SECTION 4  — Lost Revenue by Payment Method
  SECTION 5  — Marketing Channel Quality Analysis
  SECTION 6  — Coupon Code Abuse Detection
  SECTION 7  — Monthly Cancellation Trend (2023–2025)
  SECTION 8  — Order Funnel Conversion Rate
  SECTION 9  — High-Risk Order Profiling (Multi-Dimensional)
  SECTION 10 — Business Decisions & Recommendations

================================================================================
*/


/* =============================================================================
   SECTION 0 — DATABASE SETUP & DATA IMPORT
   ============================================================================= */


-- Drop table if re-running
DROP TABLE IF EXISTS ecommerce;

-- Create orders table
CREATE TABLE ecommerce (
    order_id         VARCHAR(20)    PRIMARY KEY,
    order_date       DATE           NOT NULL,
    customer_id      VARCHAR(20)    NOT NULL,
    product          VARCHAR(50)    NOT NULL,
    quantity         INT            NOT NULL,
    unit_price       NUMERIC(10,2)  NOT NULL,
    shipping_address VARCHAR(255),
    payment_method   VARCHAR(50)    NOT NULL,
    order_status     VARCHAR(30)    NOT NULL,
    tracking_number  VARCHAR(30),
    items_in_cart    INT,
    coupon_code      VARCHAR(20),
    referral_source  VARCHAR(50),
    total_price      NUMERIC(10,2)  NOT NULL
);

/*
  ► Import data using psql COPY command:

  \COPY orders(order_id, order_date, customer_id, product, quantity, unit_price,
               shipping_address, payment_method, order_status, tracking_number,
               items_in_cart, coupon_code, referral_source, total_price)
  FROM '/path/to/E-Commerce_Orders2.csv'
  DELIMITER ','
  CSV HEADER;
*/



/* =============================================================================
   SECTION 1 — DATA QUALITY & VALIDATION
   ============================================================================ */

-- 1.1  Total record count
SELECT COUNT(*) AS totalrecords
FROM ecommerce;


-- 1.2  Check for duplicate order IDs
SELECT orderid,
       COUNT(*) AS duplicatecount
FROM ecommerce
GROUP BY orderid
HAVING COUNT(*) > 1;


-- 1.3  Check for NULL values in critical columns
SELECT
    SUM(CASE WHEN orderid       IS NULL THEN 1 ELSE 0 END) AS nullorderid,
    SUM(CASE WHEN date          IS NULL THEN 1 ELSE 0 END) AS nulldate,
    SUM(CASE WHEN customerid    IS NULL THEN 1 ELSE 0 END) AS nullcustomer,
    SUM(CASE WHEN product       IS NULL THEN 1 ELSE 0 END) AS nullproduct,
    SUM(CASE WHEN orderstatus   IS NULL THEN 1 ELSE 0 END) AS nullstatus,
    SUM(CASE WHEN totalprice    IS NULL THEN 1 ELSE 0 END) AS nullprice,
    SUM(CASE WHEN couponcode    IS NULL THEN 1 ELSE 0 END) AS nullcoupon
FROM ecommerce;

-- 1.4  Verify all order statuses are expected values
SELECT orderstatus,
       COUNT(*) AS recordcount
FROM ecommerce
GROUP BY orderstatus
ORDER BY recordcount DESC;


-- 1.5  Date range validation
SELECT
    MIN(date) AS earliestorder,
    MAX(date) AS latestorder,
    COUNT(DISTINCT date) AS uniquedates
FROM ecommerce;



/* =============================================================================
   SECTION 2 — REVENUE HEALTH OVERVIEW
   Business Question: What is the total scale of the revenue leakage problem?
   ============================================================================ */

-- 2.1  Revenue breakdown by order status
SELECT
    orderstatus,
    COUNT(*)                                AS totalorders,
    ROUND(SUM(totalprice), 2)               AS totalrevenue,
    ROUND(AVG(totalprice), 2)               AS avgordervalue,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2
    )                                       AS pctoforders,
    ROUND(
        SUM(totalprice) * 100.0 / SUM(SUM(totalprice)) OVER (), 2
    )                                       AS pctofrevenue
FROM ecommerce
GROUP BY orderstatus
ORDER BY totalrevenue DESC;

-- 2.2  Lost revenue summary (Cancelled + Returned)
SELECT
    COUNT(*)                                                        AS lostorders,
    ROUND(SUM(totalprice), 2)                                       AS totallostrevenue,
    ROUND(AVG(totalprice), 2)                                       AS avglostperorder,
    ROUND(
        SUM(totalprice) * 100.0 /
        (SELECT SUM(totalprice) FROM ecommerce), 2
    )                                                                AS pctoftotalrevenue
FROM ecommerce
WHERE orderstatus IN ('Cancelled', 'Returned');

-- 2.3  Leakage vs healthy revenue comparison
SELECT
    CASE
        WHEN orderstatus IN ('Cancelled', 'Returned') THEN 'Lost Revenue'
        WHEN orderstatus = 'Delivered'                 THEN 'Confirmed Revenue'
        ELSE                                                'In-Progress Revenue'
    END                                                AS revenuecategory,
    COUNT(*)                                           AS orders,
    ROUND(SUM(totalprice), 2)                          AS revenue
FROM ecommerce
GROUP BY revenuecategory
ORDER BY revenue DESC;


/* =============================================================================
   SECTION 3 — LOST REVENUE BY PRODUCT
   ============================================================================ */

-- 3.1  Full product-level loss analysis
SELECT
    product,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus = 'Cancelled' THEN 1 ELSE 0 END) AS cancelledorders,
    SUM(CASE WHEN orderstatus = 'Returned'  THEN 1 ELSE 0 END) AS returnedorders,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
                                                           AS totallostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    )                                                      AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                      AS lossratepct,
    ROUND(AVG(
        CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN totalprice END), 2
    )                                                      AS avglostordervalue
FROM ecommerce
GROUP BY product
ORDER BY lossratepct DESC;

-- 3.2  Product cancellation vs return breakdown
SELECT
    product,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS cancellationratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Returned' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS returnratepct
FROM ecommerce
GROUP BY product
ORDER BY cancellationratepct DESC;


/* =============================================================================
   SECTION 4 — LOST REVENUE BY PAYMENT METHOD
   ============================================================================ */

-- 4.1  Payment method risk analysis
SELECT
    paymentmethod,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN 1 ELSE 0 END) AS lostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS deliverysuccesspct
FROM ecommerce
GROUP BY paymentmethod
ORDER BY lossratepct DESC;

-- 4.2  Payment method — revenue successfully delivered
SELECT
    paymentmethod,
    ROUND(SUM(CASE WHEN orderstatus = 'Delivered'
              THEN totalprice ELSE 0 END), 2) AS confirmedrevenue,
    ROUND(SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
              THEN totalprice ELSE 0 END), 2) AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Delivered' THEN totalprice ELSE 0 END)
        * 100.0 / SUM(totalprice), 1
    ) AS revenuerecoverypct
FROM ecommerce
GROUP BY paymentmethod
ORDER BY revenuerecoverypct DESC;


/* =============================================================================
   SECTION 5 — MARKETING CHANNEL QUALITY ANALYSIS
   ============================================================================ */

-- 5.1  Channel-level loss and order quality
SELECT
    referralsource,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus = 'Delivered'  THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN orderstatus = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN orderstatus = 'Returned'   THEN 1 ELSE 0 END) AS returned,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS qualityscorepct,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue
FROM ecommerce
GROUP BY referralsource
ORDER BY lossratepct DESC;

-- 5.2  Revenue value per channel
SELECT
    referralsource,
    ROUND(AVG(totalprice), 2) AS avgordervalue,
    ROUND(SUM(totalprice), 2) AS totalgmv,
    ROUND(SUM(CASE WHEN orderstatus = 'Delivered'
              THEN totalprice ELSE 0 END), 2) AS netdeliveredrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Delivered' THEN totalprice ELSE 0 END)
        * 100.0 / SUM(totalprice), 1
    ) AS revenueefficiencypct
FROM ecommerce
GROUP BY referralsource
ORDER BY revenueefficiencypct DESC;


/* =============================================================================
   SECTION 6 — COUPON CODE ABUSE DETECTION
   ============================================================================ */

-- 6.1  Coupon code performance and abuse rate
SELECT
    COALESCE(couponcode, 'NO COUPON') AS couponcode,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN 1 ELSE 0 END) AS lostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Returned' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS returnratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS cancelratepct,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS discountedlostrevenue
FROM ecommerce
GROUP BY couponcode
ORDER BY lossratepct DESC;

-- 6.2  Coupon vs no-coupon order completion quality
SELECT
    CASE WHEN couponcode IS NOT NULL THEN 'Coupon Used' ELSE 'No Coupon' END
                                                   AS couponusage,
    COUNT(*)                                       AS totalorders,
    ROUND(AVG(totalprice), 2)                      AS avgordervalue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus = 'Delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS deliveryratepct
FROM ecommerce
GROUP BY couponusage
ORDER BY lossratepct DESC;


/* =============================================================================
   SECTION 7 — MONTHLY CANCELLATION TREND (2023–2025)
   ============================================================================ */

-- 7.1  Monthly revenue and loss trend
SELECT
    DATE_TRUNC('month', date)::DATE AS ordermonth,
    COUNT(*) AS totalorders,
    ROUND(SUM(totalprice), 2) AS totalrevenue,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN 1 ELSE 0 END) AS lostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct
FROM ecommerce
GROUP BY ordermonth
ORDER BY ordermonth;

-- 7.2  Year-over-year leakage comparison
SELECT
    EXTRACT(YEAR FROM date) AS orderyear,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN 1 ELSE 0 END) AS lostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct
FROM ecommerce
GROUP BY orderyear
ORDER BY orderyear;

-- 7.3  Quarterly performance overview
SELECT
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(QUARTER FROM date) AS quarter,
    CONCAT('Q', EXTRACT(QUARTER FROM date)::INT,
           '-', EXTRACT(YEAR FROM date)::INT) AS period,
    COUNT(*) AS totalorders,
    ROUND(SUM(totalprice), 2) AS totalrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct
FROM ecommerce
GROUP BY year, quarter, period
ORDER BY year, quarter;

/* =============================================================================
   SECTION 7.4 — COHORT ANALYSIS: CHANNEL RETENTION & CANCELLATION BEHAVIOR
   ============================================================================ */

-- 7.4a  Cohort analysis: Customer acquisition channel vs cancellation behavior
WITH customerfirstsource AS (
    SELECT
        customerid,
        referralsource,
        MIN(date) AS firstorderdate,
        MAX(date) AS lastorderdate,
        COUNT(*) AS totalorders
    FROM ecommerce
    GROUP BY customerid, referralsource
)
SELECT
    cfs.referralsource,
    COUNT(DISTINCT cfs.customerid) AS uniquecustomers,
    SUM(cfs.totalorders) AS totalordersfromcohort,
    ROUND(AVG(cfs.totalorders), 2) AS avgorderspercustomer,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.orderstatus IN ('Cancelled','Returned')
                       THEN o.orderid END)
        * 100.0 / COUNT(DISTINCT o.orderid), 1
    ) AS cohortlossratepct,
    ROUND(
        SUM(CASE WHEN o.orderstatus IN ('Cancelled','Returned')
            THEN o.totalprice ELSE 0 END), 2
    ) AS cohortlostrevenue
FROM customerfirstsource cfs
LEFT JOIN ecommerce o ON cfs.customerid = o.customerid
GROUP BY cfs.referralsource
ORDER BY cohortlossratepct DESC;

-- 7.4b  Deep dive: Instagram vs Google cohort comparison
WITH channelcohorts AS (
    SELECT
        CASE WHEN referralsource IN ('Instagram') THEN 'Instagram'
             WHEN referralsource IN ('Google') THEN 'Google'
             ELSE 'Other' END AS channelgroup,
        orderid,
        customerid,
        orderstatus,
        totalprice,
        date
    FROM ecommerce
    WHERE referralsource IN ('Instagram', 'Google')
)
SELECT
    channelgroup,
    COUNT(DISTINCT customerid) AS uniquecustomers,
    COUNT(orderid) AS totalorders,
    ROUND(
        COUNT(CASE WHEN orderstatus = 'Delivered' THEN 1 END)
        * 100.0 / COUNT(orderid), 1
    ) AS deliveryratepct,
    ROUND(
        COUNT(CASE WHEN orderstatus = 'Cancelled' THEN 1 END)
        * 100.0 / COUNT(orderid), 1
    ) AS cancellationratepct,
    ROUND(
        COUNT(CASE WHEN orderstatus = 'Returned' THEN 1 END)
        * 100.0 / COUNT(orderid), 1
    ) AS returnratepct,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue,
    ROUND(AVG(totalprice), 2) AS avgordervalue
FROM channelcohorts
GROUP BY channelgroup
ORDER BY cancellationratepct DESC;

-- 7.4c  Repeat purchase behavior by acquisition channel
WITH firstorderchannel AS (
    SELECT
        customerid,
        referralsource,
        MIN(date) AS firstorderdate
    FROM ecommerce
    GROUP BY customerid, referralsource
)
SELECT
    foc.referralsource,
    COUNT(DISTINCT foc.customerid) AS customersacquired,
    COUNT(DISTINCT CASE WHEN o.date > foc.firstorderdate
                       THEN o.customerid END) AS customersrepeatpurchased,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.date > foc.firstorderdate
                           THEN o.customerid END)
        * 100.0 / COUNT(DISTINCT foc.customerid), 1
    ) AS repeatpurchaseratepct,
    ROUND(
        AVG(CASE WHEN o.date > foc.firstorderdate
               AND o.orderstatus IN ('Cancelled','Returned')
            THEN 1 ELSE 0 END) * 100, 1
    ) AS repeatorderlossratepct
FROM firstorderchannel foc
LEFT JOIN ecommerce o ON foc.customerid = o.customerid
GROUP BY foc.referralsource
ORDER BY repeatpurchaseratepct DESC;

/* =============================================================================
   SECTION 8 — ORDER FUNNEL CONVERSION RATE
   ============================================================================ */

-- 8.1  Full funnel with conversion rates
WITH funnel AS (
    SELECT
        SUM(CASE WHEN orderstatus IN ('Pending','Shipped','Delivered','Cancelled','Returned') THEN 1 ELSE 0 END) AS placed,
        SUM(CASE WHEN orderstatus IN ('Shipped','Delivered') THEN 1 ELSE 0 END) AS shipped,
        SUM(CASE WHEN orderstatus = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
        SUM(CASE WHEN orderstatus = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN orderstatus = 'Returned' THEN 1 ELSE 0 END) AS returned
    FROM ecommerce
)
SELECT
    placed AS ordersplaced,
    shipped AS ordersshipped,
    delivered AS ordersdelivered,
    cancelled AS orderscancelled,
    returned AS ordersreturned,
    ROUND(shipped * 100.0 / placed, 1) AS shipmentratepct,
    ROUND(delivered * 100.0 / placed, 1) AS deliverysuccesspct,
    ROUND(cancelled * 100.0 / placed, 1) AS cancellationratepct,
    ROUND(returned * 100.0 / placed, 1) AS returnratepct
FROM funnel;

-- 8.2  Funnel by product
SELECT
    product,
    COUNT(*) AS total,
    ROUND(SUM(CASE WHEN orderstatus = 'Delivered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1) AS deliverypct,
    ROUND(SUM(CASE WHEN orderstatus = 'Cancelled' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1) AS cancelpct,
    ROUND(SUM(CASE WHEN orderstatus = 'Returned' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1) AS returnpct,
    ROUND(SUM(CASE WHEN orderstatus = 'Pending' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1) AS pendingpct
FROM ecommerce
GROUP BY product
ORDER BY deliverypct DESC;

/* =============================================================================
   SECTION 9 — HIGH-RISK ORDER PROFILING (MULTI-DIMENSIONAL)
   ============================================================================ */

-- 9.1  Cross-dimensional risk: Product × Payment Method
SELECT
    product,
    paymentmethod,
    COUNT(*) AS totalorders,
    SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
        THEN 1 ELSE 0 END) AS lostorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue
FROM ecommerce
GROUP BY product, paymentmethod
HAVING COUNT(*) >= 10
ORDER BY lossratepct DESC
LIMIT 15;

-- 9.2  Cross-dimensional risk: Channel × Product
SELECT
    referralsource,
    product,
    COUNT(*) AS totalorders,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned') THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS lossratepct,
    ROUND(
        SUM(CASE WHEN orderstatus IN ('Cancelled','Returned')
            THEN totalprice ELSE 0 END), 2
    ) AS lostrevenue
FROM ecommerce
GROUP BY referralsource, product
HAVING COUNT(*) >= 8
ORDER BY lossratepct DESC
LIMIT 15;

-- 9.3  High-risk order flag
WITH productavg AS (
    SELECT
        product,
        ROUND(AVG(totalprice), 2) AS avgproductprice
    FROM ecommerce
    WHERE orderstatus IN ('Cancelled','Returned')
    GROUP BY product
)
SELECT
    o.orderid,
    o.date,
    o.customerid,
    o.product,
    o.paymentmethod,
    o.referralsource,
    o.couponcode,
    o.orderstatus,
    o.totalprice,
    pa.avgproductprice,
    CASE
        WHEN o.totalprice > pa.avgproductprice * 1.5 THEN 'HIGH RISK — Above 150% avg'
        WHEN o.totalprice > pa.avgproductprice THEN 'MEDIUM RISK — Above avg'
        ELSE 'STANDARD RISK'
    END AS riskflag
FROM ecommerce o
JOIN productavg pa ON o.product = pa.product
WHERE o.orderstatus IN ('Cancelled','Returned')
ORDER BY o.totalprice DESC
LIMIT 20;


/* =============================================================================
   SECTION 10 — BUSINESS DECISIONS & RECOMMENDATIONS
   ============================================================================= */

/*
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  EXECUTIVE SUMMARY — KEY FINDINGS                                           │
  ├─────────────────────────────────────────────────────────────────────────────┤
  │                                                                             │
  │  Total Revenue (GMV)     :  $1,264,761.96                                  │
  │  Lost Revenue            :  $519,673.91  (41.1% of GMV)                   │
  │  Cancellations           :  250 orders   ($276,396)                        │
  │  Returns                 :  247 orders   ($243,277)                        │
  │  Delivery Success Rate   :  19.3%  ← critically low                        │
  │                                                                             │
  └─────────────────────────────────────────────────────────────────────────────┘

  ────────────────────────────────────────────────────────────────────────────
  DECISION 1 — PRODUCT STRATEGY
  ────────────────────────────────────────────────────────────────────────────
  FINDING : Monitor (43.6%) and Tablet (43.0%) have the highest loss rates.
            Laptop has the highest absolute lost revenue at $83,416.

  ACTION  : Conduct product listing audit for Monitor, Tablet, and Laptop.
            Improve product descriptions, size/spec accuracy, and customer
            reviews. Add a pre-purchase checklist for high-value electronics.
            Consider reducing return window from 30 to 14 days for Laptop.

  TARGET  : Reduce Monitor and Tablet loss rate from ~43% to below 30%.
            Projected recovery: ~$22,000/year.

  ────────────────────────────────────────────────────────────────────────────
  DECISION 2 — PAYMENT METHOD POLICY
  ────────────────────────────────────────────────────────────────────────────
  FINDING : Gift Card (44.3%) and Credit Card (44.0%) have the highest loss
            rates. Online payments have the lowest at 35.3%.

  ACTION  : Require order confirmation email verification for Gift Card
            purchases above $500. Introduce a small restocking fee for
            Credit Card returns on high-ticket items. Offer Online payment
            incentive (0.5% cashback) to shift buyers toward lower-risk
            payment behaviour.

  TARGET  : Reduce Gift Card loss rate from 44.3% to 35%. Recovery: ~$19,500.

  ────────────────────────────────────────────────────────────────────────────
  DECISION 3 — MARKETING CHANNEL REALLOCATION
  ────────────────────────────────────────────────────────────────────────────
  FINDING : Email (43.2%) and Facebook (43.0%) have the worst order quality.
            Instagram has the best quality score (37.1% loss rate) and strong
            average order value.

  ACTION  : Reduce Facebook Ads budget by 20% and reallocate to Instagram.
            Redesign Email campaigns: replace mass-blast promotions with
            personalised product recommendations to reduce impulse buying.
            Add purchase-intent qualification to Facebook ad funnels.

  TARGET  : Improve Email channel loss rate from 43.2% to 36%. Recovery: ~$17,000.

  ────────────────────────────────────────────────────────────────────────────
  DECISION 4 — COUPON CODE GOVERNANCE
  ────────────────────────────────────────────────────────────────────────────
  FINDING : WINTER15 (44.5%) has the highest loss rate among all coupons.
            SAVE10 is the healthiest coupon at 36.7% loss rate.
            Coupon orders are only marginally worse than non-coupon orders.

  ACTION  : Restrict WINTER15 usage to non-returnable or low-return categories
            (Desk, Chair). Cap FREESHIP usage to orders above $300 to reduce
            low-commitment purchases. Keep SAVE10 as primary promotional code.

  TARGET  : Reduce WINTER15 loss rate from 44.5% to 38%. Recovery: ~$12,000.

  ────────────────────────────────────────────────────────────────────────────
  DECISION 5 — OPERATIONAL PRIORITY
  ────────────────────────────────────────────────────────────────────────────
  FINDING : Only 19.3% of orders reach Delivered status — an operational
            red flag. 23.8% pending orders may also convert to cancellations
            if not fulfilled promptly.

  ACTION  : Implement an automated 24-hour pending order alert system.
            Set SLA: all orders must transition from Pending to Shipped within
            48 hours. Investigate fulfilment bottleneck in Chair and Monitor
            product lines (highest cancellation rates).

  TARGET  : Increase delivery success rate from 19.3% to 30% within 2 quarters.

  ────────────────────────────────────────────────────────────────────────────
  COMBINED RECOVERY POTENTIAL
  ────────────────────────────────────────────────────────────────────────────
  If all 5 decisions are implemented and targets are met:
    Estimated annual revenue recovery : $70,500 – $103,934
    Improvement in delivery rate      : 19.3% → 30%+
    Reduction in overall loss rate    : 41.1% → ~28%

  These decisions require zero new customer acquisition spend — all gains
  come from fixing what the business already has.

*/


/* =============================================================================
   END OF PROJECT
   ============================================================================= */
