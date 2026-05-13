# Revenue Leakage Analysis
### E-Commerce SQL Project | PostgreSQL

---

## Project Summary

This project identifies **$519,673 in lost revenue (41.1% of total GMV)** caused by cancellations and returns — then pinpoints the exact root causes by product, payment method, marketing channel, and coupon usage, delivering **5 data-driven recovery strategies worth $70–104K annually**.

| | |
|---|---|
| **Tool** | PostgreSQL |
| **Dataset** | 1,200 orders · Jan 2023 – Jun 2025 |
| **Approach** | Root-cause analysis · Multi-dimensional segmentation · Trend analysis |
| **Business Impact** | $70–104K annual recovery potential |

---

## Key Findings

| Dimension | Worst Performer | Loss Rate | Best Performer | Loss Rate |
|-----------|----------------|-----------|----------------|-----------|
| **Product** | Monitor | 43.6% | Printer | 35.1% |
| **Payment** | Gift Card | 44.3% | Online | 35.3% |
| **Channel** | Email | 43.2% | Instagram | 37.1% |
| **Coupon** | WINTER15 | 44.5% | SAVE10 | 36.7% |

**Critical insight:** Only **19.3% delivery rate** — 497 out of 1,200 orders are cancelled or returned. The fulfillment pipeline is broken.

---

## Files in This Repository

| File | Description |
|------|-------------|
| 📄 [`project2_revenue_leakage_analysis.sql`](./project2_revenue_leakage_analysis.sql) | Full SQL analysis · 888 lines · 10 sections |
| 📊 [`project2_leakage_query_results.pdf`](./project2_leakage_query_results.pdf) | SQL queries with output screenshots |
| 📁 [`ecommerce_orders.csv`](./ecommerce_orders.csv) | Raw dataset used in this analysis |

---

## SQL File — Navigate by Section

Click any section to jump directly to that part of the code:

| Section | Description | Link |
|---------|-------------|------|
| 0 | Database Setup & Data Import | [Go →](./project2_revenue_leakage_analysis.sql#L75) |
| 1 | Data Quality & Validation | [Go →](./project2_revenue_leakage_analysis.sql#L116) |
| 2 | Revenue Health Overview | [Go →](./project2_revenue_leakage_analysis.sql#L161) |
| 3 | Lost Revenue by Product | [Go →](./project2_revenue_leakage_analysis.sql#L222) |
| 4 | Lost Revenue by Payment Method | [Go →](./project2_revenue_leakage_analysis.sql#L285) |
| 5 | Marketing Channel Quality Analysis | [Go →](./project2_revenue_leakage_analysis.sql#L336) |
| 6 | Coupon Code Abuse Detection | [Go →](./project2_revenue_leakage_analysis.sql#L396) |
| 7 | Monthly Cancellation Trend | [Go →](./project2_revenue_leakage_analysis.sql#L456) |
| 7.4 | Cohort Analysis: Instagram vs Google | [Go →](./project2_revenue_leakage_analysis.sql#L527) |
| 8 | Order Funnel Conversion Rate | [Go →](./project2_revenue_leakage_analysis.sql#L649) |
| 9 | High-Risk Order Profiling | [Go →](./project2_revenue_leakage_analysis.sql#L702) |
| 10 | Business Decisions & Recommendations | [Go →](./project2_revenue_leakage_analysis.sql#L787) |

> **Tip:** Press `Ctrl + F` inside the SQL file to search by section name.

---

## Business Decisions Delivered

1. **Product Audit** → Review Monitor, Tablet, Laptop listings → recover $22K
2. **Payment Policy** → Restrict Gift Card orders >$500 → recover $19.5K
3. **Budget Reallocation** → Shift spend from Email to Instagram → recover $17K
4. **Coupon Governance** → Restrict WINTER15 to non-returnable categories → recover $12K
5. **Fulfillment SLA** → 24–48hr order processing target → recover $32K+

**Total projected annual recovery: $70,000–$104,000**

---

## Dataset

📁 **Source file:** [`ecommerce_orders.csv`](./ecommerce_orders.csv)
- 1,200 orders · 14 columns
- Columns: OrderID, Date, CustomerID, Product, Quantity, UnitPrice, PaymentMethod, OrderStatus, TrackingNumber, ItemsInCart, CouponCode, ReferralSource, TotalPrice

---

## Related Projects

| | Repository | Focus | Impact |
|--|------------|-------|--------|
| ➡️ | [customer-rfm-segmentation](https://github.com/YOUR-USERNAME/customer-rfm-segmentation) | Who are our best customers? | $235K retention |
| ➡️ | [executive-dashboard](https://github.com/YOUR-USERNAME/executive-dashboard) | Power BI KPI dashboard | Real-time insights |

---

**Author:** [MD FAHIM HASAN JALANEY] · [hasanfahim087@gmail.com] · [LinkedIn](https://www.linkedin.com/in/md-fahim-hasan-jalaney/)
