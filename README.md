# Airbnb-Listings-Analysis-In-New-York-City
## New York City Airbnb Listings Analysis (SQL + Power BI)

This project presents an end-to-end data analysis of Airbnb listings in New York City using **SQL** for data cleaning and exploration, and **Power BI** for visual storytelling. 
The goal is to derive business-driven insights that support investment, operations, and host onboarding decisions.

📖 **Read the full report on Medium**: [Airbnb Listings Analysis in NYC with SQL](https://medium.com/@ajagunalliyu/airbnb-listings-analysis-in-new-york-city-with-sql-11beb1f8b615)

📊 **Interactive Dashboard**: [Explore on Power BI](#) *(Insert actual link)*



## Table of Contents

- [Project Overview](#project-overview)
- [Project Goal](#project-goal)
- [Methodology](#methodology)
- [Data Cleaning](#data-cleaning)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Insights & Recommendations](#insights--recommendations)
- [Dashboard](#dashboard)
- [Conclusion](#conclusion)



## Project Overview

This project analyzes Airbnb listings in New York City to uncover patterns in pricing, availability, host behavior, and guest engagement. 
The dataset used is publicly available and contains rich features such as price, location, minimum nights, number of reviews, room types, and host details.

Technologies used:
- **SQL Server Management Studio (SSMS)** – for cleaning, transformation & querying
- **Power BI** – for interactive data visualization
- **Medium** – for full documentation and analytical narrative



## Project Goal

The main objectives are to answer high-value business questions such as:
1. **Where are the best neighborhoods to invest in?**
2. **How do different host types and room types perform?**
3. **Which hosts or areas should be targeted for onboarding and support?**



## Methodology

- Data collection
- Data Importation and Preprocessing
- Data Cleaning and Transformation
- Categorization using `CASE` statements (e.g., minimum night ranges)
- Filtering for analysis relevance (e.g., `review_status = 1`, `price > 0`)

- Exploratory Data Analysis
- Insights and Recommendations
- Visualization using Power BI



## Data Cleaning

Key steps included:
- Validated latitude and longitude to ensure listings are within NYC (Lat: 40.5–40.9, Long: -74.25–-73.7)
- Removed unrealistic values (e.g., `minimum_nights > 365`)
- Renamed `review_exists` to `review_status` for clarity
- Column renaming and view creation using `ALTER VIEW`
- Logical validations for price, location, and availability
- Outlier detection and treatment
- Created filtered views such as `cleaned_listings` to streamline querying
- Excluded neighborhoods with fewer than 10 listings based on Q1 of listing counts
- Grouped `minimum_nights` into logical stay-duration categories using a `CASE` statement
- Flagged listings with $0 pricing and handled them cautiously



## Exploratory Data Analysis

Several exploratory queries and transformations were performed:
- Identified popular and high-earning neighborhoods
- Compared price and availability by room type and host type
- Segmented hosts based on activity (e.g., full-time vs part-time)
- Analyzed engagement trends across boroughs
- Checked review distribution and guest behavior patterns



## Insights & Recommendations

**1. Best Neighborhoods to Invest In**  
→ *Tribeca, Harlem, Williamsburg, and Midtown Manhattan* stand out for high ROI through either demand or premium pricing.

**2. Host & Room Type Performance**  
→ Commercial hosts dominate in high-value zones.  
→ Entire homes outperform in Manhattan; shared/private rooms do well in budget boroughs.

**3. Onboarding Strategy**  
→ Target part-time hosts (average availability = 112 days/year).  
→ Focus on outer boroughs with strong engagement but lower competition.  
→ Encourage new hosts to emulate top-reviewed listing strategies.



## Dashboard

The cleaned dataset was uploaded to **Power BI**, where insights were brought to life through interactive visuals:
- Geographic breakdowns by borough and neighborhood
- Price distributions by room and host types
- Availability and engagement heatmaps
- Filterable review and listing performance metrics

**Explore the Dashboard Here**: [Power BI Link](#) *(Insert actual link)*

---

## Conclusion

This project demonstrates how SQL and Power BI can be used to build a complete analytical pipeline—from raw data to decision-ready insights. 
The findings provide actionable guidance for Airbnb stakeholders on **investment decisions**, **host support**, and **platform optimization** within the New York City market.



> Want to know more?  
> Feel free to reach out: [ajagunalliyu@gmail.com](mailto:ajagunalliyu@gmail.com)  
> Connect with me on [LinkedIn](https://www.linkedin.com/in/alliyuajagun)  
> Follow on [Twitter/X](https://x.com/Sayyid_Alliyu)  
> Read more on [Medium](https://medium.com/@ajagunalliyu)  
> 💻 Explore more projects on [GitHub](https://github.com/ajagunalliyu)

