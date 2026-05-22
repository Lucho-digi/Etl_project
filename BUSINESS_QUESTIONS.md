# Business Questions — Dashboard Answers

All answers are derived directly from the PowerBI dashboard connected to the Gold layer in PostgreSQL.

---

## Revenue & Profitability

**Q1 — What is the average revenue per customer by segment?**
- SME: $403,36K
- Premium: $402,65K
- Private Banking: $372,86K
- Retail: $350,10K

**Q2 — What are the total account balances by country?**
- PE: $585,82M
- MX: $574,85M
- CO: $562,10M
- UY: $546,25M
- BR: $539,08M
- CL: $502,76M
- AR: $444,16M

**Q3 — What is the revenue breakdown by transaction channel?**
Fee revenue only — interest income cannot be attributed to a specific channel.
- Branch: ~$18M
- POS: ~$18M
- Mobile: ~$16M
- Web: ~$16M
- ATM: ~$15M

**Q4 — What is the interest income by loan type?**
- Education: $168,07M
- Business: $167,15M
- Auto: $166,27M
- Personal: $146,72M
- Mortgage: $137,27M

---

## Risk & Credit

**Q5 — What is the loan delinquency rate by customer segment?**
- Private Banking: 49,80%
- Retail: 49,64%
- Premium: 49,09%
- SME: 49,04%

**Q6 — What is the credit score distribution by country?**
Average credit score by country:
- BR: 572,86
- CO: 572,62
- MX: 572,40
- UY: 571,62
- AR: 568,22
- PE: 565,03
- CL: 554,98

All countries fall in the `fair` credit score bucket (580–669), with CL slightly below average.

**Q7 — Is there a relationship between credit utilization and delinquency?**
Delinquency rate by utilization bucket:
- Very Low: 50,97%
- Low: 50,88%
- High: 49,85%
- Moderate: 48,73%
- Maxed: 48,55%
- Very High: 48,40%

No significant relationship found — delinquency rates are nearly uniform across all utilization buckets (~48–51%). This is consistent with the synthetic nature of the dataset.

**Q8 — What is the days past due distribution by loan type?**
All loan types show similar DPD distribution:
- Current (~33–35%)
- 90+ (~32–34%)
- 1-30 (~9–12%)
- 31-60 (~8–11%)
- 61-90 (~7–9%)

Auto loans have the highest share of current loans (33,69%) and Business loans the highest 90+ rate (35,17%).

**Q9 — How do risk scores segment customers (low/medium/high/critical)?**
- Medium: 1,137
- High: 1,110
- Critical: 1,062
- Low: 993

Distribution is roughly uniform across all buckets — consistent with a synthetic dataset generating scores across the full 0–100 range.

---

## Customer Demographics

**Q10 — What is the customer count by country and city?**
Top cities by customer count:
- Tijuana (MX): 148
- Rio De Janeiro (BR): 147
- Salto (UY): 144
- Cali (CO): 139
- Rosario (AR): 137
- Arequipa (PE): 133
- Lima (PE): 133
- Cusco (PE): 131
- Fortaleza (BR): 131
- Guadalajara (MX): 130
- Maldonado (UY): 130
- Brasilia (BR): 127

**Q11 — What is the age distribution by customer segment?**
Distribution is relatively uniform across segments. The 35–44 age group is consistently the largest across all segments (~19–20%). Full breakdown:

| Age | SME | Retail | Premium | Private Banking |
|-----|-----|--------|---------|-----------------|
| 18-24 | 11,95% | 13,04% | 13,74% | 13,40% |
| 25-34 | 15,75% | 17,14% | 15,61% | 17,96% |
| 35-44 | 16,83% | 16,13% | 15,89% | 16,99% |
| 45-54 | 19,46% | 15,95% | 15,33% | 16,60% |
| 55-64 | 18,28% | 17,32% | 19,72% | 16,31% |
| 65+  | 17,74% | 20,42% | 19,72% | 18,74% |

**Q12 — What is the customer acquisition trend over time (monthly)?**
Monthly registrations range between 328 and 401 customers. Peak acquisition was in May (401). The lowest month was February (328). No strong seasonal trend is visible — consistent with synthetic data generation.

**Q13 — What is the customer status breakdown?**
- Active: 1,109
- Suspended: 1,109
- Inactive: 1,043
- Closed: 1,041

Distribution is nearly uniform across all statuses — ~25% each.

**Q14 — What is the KYC status distribution?**
- Pending: 1,114
- Verified: 1,070
- Expired: 1,060
- Rejected: 1,058

Distribution is nearly uniform — ~25% each status.

---

## Transaction Patterns

**Q15 — What are the most common transaction categories by volume and value?**

By volume (count):
- healthcare: 4,888
- dining: 4,879
- utilities: 4,866
- shopping: 4,860
- travel: 4,829

By value:
- dining: $124,1M
- utilities: $121,4M
- other: $121,0M
- travel: $120,8M
- healthcare: $120,7M

All categories are nearly equal in both volume and value — consistent with synthetic data.

**Q16 — What is the transaction volume by day of week?**
- Wednesday: 12,264
- Tuesday: 11,900
- Monday: 11,709
- Friday: 11,646
- Sunday: 11,531
- Saturday: 11,428
- Thursday: 11,386

Wednesday has the highest volume. Weekdays generally outperform weekends slightly.

**Q17 — What is the average transaction size by channel?**
- Branch: $1,083,67
- POS: $1,073,3
- Web: $991,67
- Mobile: $976,4
- ATM: $933,27

**Q18 — What is the failed transaction rate by channel?**
- Branch: 25,25%
- POS: 25,24%
- ATM: 25,01%
- Web: 24,89%
- Mobile: 24,72%

Failure rates are uniform across channels (~25%) — consistent with synthetic data having equal distribution across transaction statuses.

**Q19 — What are the international transfer patterns?**

By country (international transaction count):
- UY: ~11K
- MX: ~11K
- PE: ~11K
- BR: ~10,9K
- AR: ~10,7K
- CO: ~10,7K
- CL: ~10,2K

By currency:
- USD: ~38K (largest — dominant international currency)
- ARS, PEN, UYU, COP, BRL, MXN, CLP: ~6K each
- EUR: ~1K

---

## Digital Engagement

**Q20 — What is the mobile app adoption rate by segment?**
- Private Banking: 49,78% (True)
- SME: 49,53%
- Premium: 49,35%
- Retail: 48,00%

Overall mobile adoption rate: 49,15%

**Q21 — What is the digital vs branch preference by age group?**
Digital preferred (True) vs non-digital (False) by age group:

| Age Group | Digital | Non-Digital |
|-----------|---------|-------------|
| 65+ | 480 | 344 |
| 55-64 | 453 | 318 |
| 45-54 | 421 | 304 |
| 25-34 | 426 | 288 |
| 35-44 | 445 | 263 |
| 18-24 | 338 | 222 |

Digital preference is consistent across all age groups — no strong age-based divergence found in this dataset.

---

## Product Analysis

**Q22 — What are the most popular account types?**
- Credit Card: 4,170
- Savings: 4,143
- Checking: 4,098
- Investment: 3,981

Credit Card is the most popular account type, followed closely by Savings.

**Q23 — What is the loan portfolio composition?**
Outstanding balance by type and status (active loans only — paid off loans have $0 outstanding balance by definition):

| Type | Current | Default | Delinquent |
|------|---------|---------|------------|
| Auto | 32,72% | 32,57% | 34,71% |
| Education | 32,81% | 35,09% | 32,10% |
| Personal | 33,57% | 35,49% | 30,93% |
| Business | 35,64% | 30,95% | 33,41% |
| Mortgage | 33,98% | 34,04% | 31,98% |

**Q24 — What is the average number of products per customer by segment?**
Overall average: 5,04 products per customer.
- Retail: 5,06
- Private Banking: 5,05
- Premium: 5,02
- SME: 5,03