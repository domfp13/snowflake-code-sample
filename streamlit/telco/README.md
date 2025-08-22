# TelcoCorp Customer 360 Dashboard

A comprehensive Streamlit dashboard for telco sales teams to analyze customer data and improve customer interactions.

## Features

### 📊 Multi-Page Dashboard
- **Customer Overview**: Individual customer details, usage metrics, and product recommendations
- **Service Usage Analytics**: Usage patterns, trends, and comparative analysis
- **Billing & Revenue**: Payment history, revenue analysis, and overdue tracking
- **Customer Risk & Retention**: Churn risk assessment and retention recommendations

### 🎯 Key Capabilities
- **Customer Search**: Quick lookup by customer ID or name
- **Interactive Visualizations**: Charts and graphs powered by Plotly
- **Risk Assessment**: Automated churn risk scoring with actionable insights
- **Product Recommendations**: AI-driven upsell/cross-sell suggestions
- **Usage Trends**: 6-month historical usage analysis

## Quick Start

### Prerequisites
- Python 3.9+
- Conda (recommended)

### Installation

1. **Create and activate conda environment:**
   ```bash
   conda create -n cursor python=3.9 -y
   conda activate cursor
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Generate sample data:**
   ```bash
   python data_generator.py
   ```

4. **Run the dashboard:**
   ```bash
   streamlit run app.py
   ```

5. **Open your browser to:**
   ```
   http://localhost:8501
   ```

## Sample Data

The dashboard includes a realistic dataset with:
- **1,000 customers** with diverse demographics and usage patterns
- **6 months** of historical usage data
- **Realistic telco metrics**: voice, data, SMS usage
- **Customer attributes**: satisfaction scores, NPS, support tickets
- **Billing information**: payment methods, overdue amounts

## Dashboard Pages

### 🏠 Customer Overview
- Individual customer profiles with key metrics
- Usage breakdown and trends
- Product ownership and recommendations
- Account status and demographics

### 📊 Service Usage Analytics
- Usage distribution across customer base
- Individual vs. plan average comparisons
- Usage recommendations and insights
- Historical trend analysis

### 💰 Billing & Revenue
- Revenue metrics and distribution
- Payment method analysis
- Overdue account tracking
- Revenue trends by plan type

### ⚠️ Customer Risk & Retention
- Churn risk scoring and factors
- High-risk customer identification
- Retention strategy recommendations
- Risk factor correlation analysis

## Technical Details

### Data Model
- **Customers**: Demographics, plan info, satisfaction metrics
- **Usage History**: Monthly usage patterns for trend analysis
- **Risk Factors**: Tenure, satisfaction, support activity, payment behavior

### Technologies Used
- **Streamlit**: Web application framework
- **Plotly**: Interactive data visualizations
- **Pandas**: Data manipulation and analysis
- **Faker**: Realistic test data generation
- **NumPy/SciPy**: Statistical analysis

## Use Cases for Sales Teams

1. **Pre-Call Preparation**: Review customer profile before sales calls
2. **Upsell Identification**: Find customers ready for plan upgrades
3. **Retention Focus**: Identify at-risk customers needing attention
4. **Usage Analysis**: Understand customer behavior patterns
5. **Revenue Optimization**: Target high-value customers for growth

## Customization

The dashboard can be easily customized for different telco environments:
- Modify `data_generator.py` to match your data schema
- Adjust risk scoring algorithms in the data generator
- Add new metrics and visualizations as needed
- Integrate with real data sources by replacing CSV loading

## Performance

- Handles 1000+ customers efficiently
- Uses Streamlit caching for optimal performance
- Responsive design works on desktop and tablet devices

