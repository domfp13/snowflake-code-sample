import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import seaborn as sns
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
import os

# Page configuration
st.set_page_config(
    page_title="TelcoCorp Customer 360 Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: 600;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f8f9fa;
        padding: 1rem;
        border-radius: 10px;
        border-left: 4px solid #1f77b4;
        margin: 0.5rem 0;
    }
    .sidebar .sidebar-content {
        background-color: #f0f2f6;
    }
    .stSelectbox > div > div > select {
        background-color: white;
    }
</style>
""", unsafe_allow_html=True)

@st.cache_data
def load_data():
    """Load customer and usage data"""
    # Check if data files exist, if not generate them
    if not os.path.exists('customer_data.csv') or not os.path.exists('usage_history.csv'):
        st.info("Generating sample data... This may take a moment.")
        os.system('python data_generator.py')
    
    customers = pd.read_csv('customer_data.csv')
    usage_history = pd.read_csv('usage_history.csv')
    
    # Convert date columns
    customers['last_payment_date'] = pd.to_datetime(customers['last_payment_date'])
    customers['last_support_date'] = pd.to_datetime(customers['last_support_date'])
    
    return customers, usage_history

def main():
    # Load data
    customers_df, usage_history_df = load_data()
    
    # Sidebar navigation
    st.sidebar.markdown("## 🏢 TelcoCorp Dashboard")
    st.sidebar.markdown("---")
    
    page = st.sidebar.selectbox(
        "Navigate to:",
        ["🏠 Customer Overview", "📊 Service Usage Analytics", "💰 Billing & Revenue", "⚠️ Customer Risk & Retention"]
    )
    
    # Customer selector in sidebar
    st.sidebar.markdown("### Customer Lookup")
    customer_search = st.sidebar.text_input("Search Customer ID or Name:")
    
    if customer_search:
        filtered_customers = customers_df[
            customers_df['customer_id'].str.contains(customer_search, case=False) |
            customers_df['first_name'].str.contains(customer_search, case=False) |
            customers_df['last_name'].str.contains(customer_search, case=False)
        ]
        if not filtered_customers.empty:
            selected_customer = st.sidebar.selectbox(
                "Select Customer:",
                options=filtered_customers['customer_id'].tolist(),
                format_func=lambda x: f"{x} - {customers_df[customers_df['customer_id']==x]['first_name'].iloc[0]} {customers_df[customers_df['customer_id']==x]['last_name'].iloc[0]}"
            )
        else:
            selected_customer = None
            st.sidebar.warning("No customers found matching your search.")
    else:
        selected_customer = st.sidebar.selectbox(
            "Select Customer:",
            options=[''] + customers_df['customer_id'].tolist()[:50],  # Show first 50 for demo
            format_func=lambda x: f"{x} - {customers_df[customers_df['customer_id']==x]['first_name'].iloc[0]} {customers_df[customers_df['customer_id']==x]['last_name'].iloc[0]}" if x else "Select a customer..."
        )
    
    # Display selected page
    if page == "🏠 Customer Overview":
        show_customer_overview(customers_df, usage_history_df, selected_customer)
    elif page == "📊 Service Usage Analytics":
        show_usage_analytics(customers_df, usage_history_df, selected_customer)
    elif page == "💰 Billing & Revenue":
        show_billing_revenue(customers_df, usage_history_df, selected_customer)
    elif page == "⚠️ Customer Risk & Retention":
        show_risk_retention(customers_df, usage_history_df, selected_customer)

def show_customer_overview(customers_df, usage_history_df, selected_customer):
    """Customer Overview page"""
    st.markdown('<h1 class="main-header">📋 Customer Overview Dashboard</h1>', unsafe_allow_html=True)
    
    if selected_customer and selected_customer != '':
        # Individual customer view
        customer = customers_df[customers_df['customer_id'] == selected_customer].iloc[0]
        
        # Customer header
        col1, col2, col3 = st.columns([2, 2, 1])
        with col1:
            st.markdown(f"### {customer['first_name']} {customer['last_name']}")
            st.markdown(f"**Customer ID:** {customer['customer_id']}")
            st.markdown(f"**Email:** {customer['email']}")
            st.markdown(f"**Phone:** {customer['phone']}")
        
        with col2:
            st.markdown(f"**Plan:** {customer['plan_type']}")
            st.markdown(f"**Status:** {customer['account_status']}")
            st.markdown(f"**Tenure:** {customer['tenure_months']} months")
            st.markdown(f"**Location:** {customer['city']}, {customer['state']}")
        
        with col3:
            # Churn risk indicator
            risk_color = {'Low': 'green', 'Medium': 'orange', 'High': 'red'}[customer['churn_risk']]
            st.markdown(f"**Churn Risk:** <span style='color: {risk_color}; font-weight: bold'>{customer['churn_risk']}</span>", unsafe_allow_html=True)
        
        st.markdown("---")
        
        # Key metrics
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            st.metric("Monthly Revenue", f"${customer['monthly_revenue']:.2f}")
        with col2:
            st.metric("Satisfaction Score", f"{customer['satisfaction_score']:.1f}/5.0")
        with col3:
            st.metric("NPS Score", customer['nps_score'])
        with col4:
            st.metric("Support Tickets (6M)", customer['support_tickets_6m'])
        with col5:
            overdue_color = "red" if customer['overdue_amount'] > 0 else "green"
            st.metric("Overdue Amount", f"${customer['overdue_amount']:.2f}")
        
        # Usage overview
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("📱 Current Usage (30 days)")
            usage_data = {
                'Metric': ['Voice Minutes', 'Data (GB)', 'SMS Count'],
                'Usage': [customer['voice_minutes_30d'], customer['data_gb_30d'], customer['sms_count_30d']]
            }
            fig = px.bar(usage_data, x='Metric', y='Usage', 
                        title="Usage Breakdown",
                        color='Metric')
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("🛍️ Products & Recommendations")
            st.write("**Current Products:**")
            for product in customer['products_owned'].split(', '):
                st.write(f"✅ {product}")
            
            st.write("**Recommended Products:**")
            for product in customer['recommended_products'].split(', '):
                if product:  # Check if not empty
                    st.write(f"💡 {product}")
        
        # Usage trends
        customer_usage = usage_history_df[usage_history_df['customer_id'] == selected_customer].copy()
        if not customer_usage.empty:
            st.subheader("📈 Usage Trends (6 months)")
            
            customer_usage = customer_usage.sort_values('month')
            
            fig = make_subplots(
                rows=2, cols=2,
                subplot_titles=('Data Usage (GB)', 'Voice Minutes', 'SMS Count', 'Monthly Revenue'),
                specs=[[{"secondary_y": False}, {"secondary_y": False}],
                       [{"secondary_y": False}, {"secondary_y": False}]]
            )
            
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['data_gb'],
                                   mode='lines+markers', name='Data GB'), row=1, col=1)
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['voice_minutes'],
                                   mode='lines+markers', name='Voice Minutes'), row=1, col=2)
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['sms_count'],
                                   mode='lines+markers', name='SMS Count'), row=2, col=1)
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['revenue'],
                                   mode='lines+markers', name='Revenue'), row=2, col=2)
            
            fig.update_layout(height=500, showlegend=False)
            st.plotly_chart(fig, use_container_width=True)
    
    else:
        # Overview dashboard
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Total Customers", f"{len(customers_df):,}")
        with col2:
            active_customers = len(customers_df[customers_df['account_status'] == 'Active'])
            st.metric("Active Customers", f"{active_customers:,}")
        with col3:
            avg_revenue = customers_df['monthly_revenue'].mean()
            st.metric("Avg Monthly Revenue", f"${avg_revenue:.2f}")
        with col4:
            high_risk_customers = len(customers_df[customers_df['churn_risk'] == 'High'])
            st.metric("High Risk Customers", f"{high_risk_customers:,}")
        
        # Charts
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("📊 Customer Distribution by Plan")
            plan_counts = customers_df['plan_type'].value_counts()
            fig = px.pie(values=plan_counts.values, names=plan_counts.index, 
                        title="Customers by Plan Type")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("🎯 Customer Satisfaction Distribution")
            fig = px.histogram(customers_df, x='satisfaction_score', nbins=20,
                             title="Satisfaction Score Distribution")
            st.plotly_chart(fig, use_container_width=True)
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("⚠️ Churn Risk Analysis")
            risk_counts = customers_df['churn_risk'].value_counts()
            colors = ['green', 'orange', 'red']
            fig = px.bar(x=risk_counts.index, y=risk_counts.values,
                        title="Customers by Churn Risk",
                        color=risk_counts.index,
                        color_discrete_sequence=colors)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("💰 Revenue by Plan Type")
            revenue_by_plan = customers_df.groupby('plan_type')['monthly_revenue'].agg(['mean', 'sum']).round(2)
            fig = px.bar(x=revenue_by_plan.index, y=revenue_by_plan['sum'],
                        title="Total Revenue by Plan Type")
            st.plotly_chart(fig, use_container_width=True)

def show_usage_analytics(customers_df, usage_history_df, selected_customer):
    """Service Usage Analytics page"""
    st.markdown('<h1 class="main-header">📊 Service Usage Analytics</h1>', unsafe_allow_html=True)
    
    if selected_customer and selected_customer != '':
        customer = customers_df[customers_df['customer_id'] == selected_customer].iloc[0]
        st.markdown(f"### Usage Analytics for {customer['first_name']} {customer['last_name']}")
        
        # Current usage metrics
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Voice Minutes (30d)", f"{customer['voice_minutes_30d']:.0f}")
        with col2:
            st.metric("Data Usage (30d)", f"{customer['data_gb_30d']:.1f} GB")
        with col3:
            st.metric("SMS Count (30d)", f"{customer['sms_count_30d']:,}")
        
        # Usage trends
        customer_usage = usage_history_df[usage_history_df['customer_id'] == selected_customer].copy()
        if not customer_usage.empty:
            customer_usage = customer_usage.sort_values('month')
            
            # Combined usage chart
            fig = make_subplots(
                rows=3, cols=1,
                subplot_titles=('Data Usage (GB)', 'Voice Minutes', 'SMS Count'),
                vertical_spacing=0.1
            )
            
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['data_gb'],
                                   mode='lines+markers', name='Data GB', line=dict(color='blue')), row=1, col=1)
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['voice_minutes'],
                                   mode='lines+markers', name='Voice Minutes', line=dict(color='green')), row=2, col=1)
            fig.add_trace(go.Scatter(x=customer_usage['month'], y=customer_usage['sms_count'],
                                   mode='lines+markers', name='SMS Count', line=dict(color='orange')), row=3, col=1)
            
            fig.update_layout(height=600, showlegend=False, title_text="6-Month Usage Trends")
            st.plotly_chart(fig, use_container_width=True)
        
        # Usage patterns analysis
        st.subheader("📈 Usage Pattern Analysis")
        col1, col2 = st.columns(2)
        
        with col1:
            # Compare to plan average
            plan_avg = customers_df[customers_df['plan_type'] == customer['plan_type']].agg({
                'voice_minutes_30d': 'mean',
                'data_gb_30d': 'mean',
                'sms_count_30d': 'mean'
            })
            
            comparison_data = {
                'Metric': ['Voice Minutes', 'Data (GB)', 'SMS Count'],
                'Customer': [customer['voice_minutes_30d'], customer['data_gb_30d'], customer['sms_count_30d']],
                'Plan Average': [plan_avg['voice_minutes_30d'], plan_avg['data_gb_30d'], plan_avg['sms_count_30d']]
            }
            
            fig = px.bar(comparison_data, x='Metric', y=['Customer', 'Plan Average'],
                        title=f"Usage vs {customer['plan_type']} Plan Average",
                        barmode='group')
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Usage recommendations
            st.markdown("#### 💡 Usage Insights & Recommendations")
            
            # High data usage
            if customer['data_gb_30d'] > plan_avg['data_gb_30d'] * 1.5:
                st.success("📱 High data user - Consider unlimited data plan")
            
            # Low usage
            if customer['data_gb_30d'] < plan_avg['data_gb_30d'] * 0.5:
                st.info("📉 Low data usage - Could downgrade to save money")
            
            # High voice usage
            if customer['voice_minutes_30d'] > plan_avg['voice_minutes_30d'] * 1.3:
                st.warning("📞 Heavy voice user - Check voice plan limits")
            
            # SMS usage
            if customer['sms_count_30d'] > 100:
                st.info("💬 Active SMS user - Consider messaging apps")
    
    else:
        # Overall usage analytics
        col1, col2, col3 = st.columns(3)
        with col1:
            avg_voice = customers_df['voice_minutes_30d'].mean()
            st.metric("Avg Voice Minutes", f"{avg_voice:.0f}")
        with col2:
            avg_data = customers_df['data_gb_30d'].mean()
            st.metric("Avg Data Usage", f"{avg_data:.1f} GB")
        with col3:
            avg_sms = customers_df['sms_count_30d'].mean()
            st.metric("Avg SMS Count", f"{avg_sms:.0f}")
        
        # Usage distribution charts
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("📊 Data Usage Distribution")
            fig = px.histogram(customers_df, x='data_gb_30d', nbins=30,
                             title="Data Usage Distribution (GB)")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("📞 Voice Usage Distribution")
            fig = px.histogram(customers_df, x='voice_minutes_30d', nbins=30,
                             title="Voice Minutes Distribution")
            st.plotly_chart(fig, use_container_width=True)
        
        # Usage by plan type
        st.subheader("📋 Usage Patterns by Plan Type")
        
        plan_usage = customers_df.groupby('plan_type').agg({
            'voice_minutes_30d': 'mean',
            'data_gb_30d': 'mean',
            'sms_count_30d': 'mean'
        }).round(2)
        
        fig = make_subplots(
            rows=1, cols=3,
            subplot_titles=('Average Voice Minutes', 'Average Data (GB)', 'Average SMS Count'),
        )
        
        fig.add_trace(go.Bar(x=plan_usage.index, y=plan_usage['voice_minutes_30d'],
                           name='Voice Minutes'), row=1, col=1)
        fig.add_trace(go.Bar(x=plan_usage.index, y=plan_usage['data_gb_30d'],
                           name='Data GB'), row=1, col=2)
        fig.add_trace(go.Bar(x=plan_usage.index, y=plan_usage['sms_count_30d'],
                           name='SMS Count'), row=1, col=3)
        
        fig.update_layout(height=400, showlegend=False)
        st.plotly_chart(fig, use_container_width=True)

def show_billing_revenue(customers_df, usage_history_df, selected_customer):
    """Billing & Revenue page"""
    st.markdown('<h1 class="main-header">💰 Billing & Revenue Analysis</h1>', unsafe_allow_html=True)
    
    if selected_customer and selected_customer != '':
        customer = customers_df[customers_df['customer_id'] == selected_customer].iloc[0]
        st.markdown(f"### Billing Details for {customer['first_name']} {customer['last_name']}")
        
        # Billing metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Monthly Revenue", f"${customer['monthly_revenue']:.2f}")
        with col2:
            st.metric("Payment Method", customer['payment_method'])
        with col3:
            days_since_payment = (datetime.now().date() - customer['last_payment_date'].date()).days
            st.metric("Days Since Payment", days_since_payment)
        with col4:
            color = "red" if customer['overdue_amount'] > 0 else "green"
            st.metric("Overdue Amount", f"${customer['overdue_amount']:.2f}")
        
        # Payment history
        st.subheader("💳 Payment History")
        st.write(f"**Last Payment:** {customer['last_payment_date'].strftime('%Y-%m-%d')}")
        st.write(f"**Payment Method:** {customer['payment_method']}")
        
        if customer['overdue_amount'] > 0:
            st.error(f"⚠️ Customer has overdue amount of ${customer['overdue_amount']:.2f}")
        else:
            st.success("✅ Account is current with no overdue amounts")
        
        # Revenue trends
        customer_usage = usage_history_df[usage_history_df['customer_id'] == selected_customer].copy()
        if not customer_usage.empty:
            customer_usage = customer_usage.sort_values('month')
            
            fig = px.line(customer_usage, x='month', y='revenue',
                         title="6-Month Revenue Trend",
                         markers=True)
            fig.update_layout(height=400)
            st.plotly_chart(fig, use_container_width=True)
            
            # Revenue statistics
            total_revenue_6m = customer_usage['revenue'].sum()
            avg_monthly = customer_usage['revenue'].mean()
            
            col1, col2 = st.columns(2)
            with col1:
                st.metric("6-Month Total Revenue", f"${total_revenue_6m:.2f}")
            with col2:
                st.metric("Average Monthly", f"${avg_monthly:.2f}")
    
    else:
        # Overall revenue analytics
        total_revenue = customers_df['monthly_revenue'].sum()
        avg_revenue = customers_df['monthly_revenue'].mean()
        overdue_customers = len(customers_df[customers_df['overdue_amount'] > 0])
        total_overdue = customers_df['overdue_amount'].sum()
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Total Monthly Revenue", f"${total_revenue:,.2f}")
        with col2:
            st.metric("Average Revenue/Customer", f"${avg_revenue:.2f}")
        with col3:
            st.metric("Customers with Overdue", f"{overdue_customers:,}")
        with col4:
            st.metric("Total Overdue Amount", f"${total_overdue:,.2f}")
        
        # Revenue charts
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("💰 Revenue by Plan Type")
            revenue_by_plan = customers_df.groupby('plan_type')['monthly_revenue'].sum().round(2)
            fig = px.pie(values=revenue_by_plan.values, names=revenue_by_plan.index,
                        title="Revenue Distribution by Plan")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("📊 Revenue Distribution")
            fig = px.histogram(customers_df, x='monthly_revenue', nbins=30,
                             title="Monthly Revenue Distribution")
            st.plotly_chart(fig, use_container_width=True)
        
        # Payment methods
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("💳 Payment Methods")
            payment_counts = customers_df['payment_method'].value_counts()
            fig = px.bar(x=payment_counts.index, y=payment_counts.values,
                        title="Payment Method Distribution")
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("⚠️ Overdue Analysis")
            overdue_data = customers_df[customers_df['overdue_amount'] > 0]
            if not overdue_data.empty:
                fig = px.histogram(overdue_data, x='overdue_amount', nbins=20,
                                 title="Overdue Amount Distribution")
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.success("No customers with overdue amounts!")

def show_risk_retention(customers_df, usage_history_df, selected_customer):
    """Customer Risk & Retention page"""
    st.markdown('<h1 class="main-header">⚠️ Customer Risk & Retention</h1>', unsafe_allow_html=True)
    
    if selected_customer and selected_customer != '':
        customer = customers_df[customers_df['customer_id'] == selected_customer].iloc[0]
        st.markdown(f"### Risk Assessment for {customer['first_name']} {customer['last_name']}")
        
        # Risk indicators
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            risk_color = {'Low': 'green', 'Medium': 'orange', 'High': 'red'}[customer['churn_risk']]
            st.markdown(f"**Churn Risk:** <span style='color: {risk_color}; font-weight: bold; font-size: 1.2em'>{customer['churn_risk']}</span>", unsafe_allow_html=True)
        
        with col2:
            st.metric("Satisfaction Score", f"{customer['satisfaction_score']:.1f}/5.0")
        
        with col3:
            st.metric("NPS Score", customer['nps_score'])
        
        with col4:
            st.metric("Support Tickets (6M)", customer['support_tickets_6m'])
        
        # Risk factors analysis
        st.subheader("🔍 Risk Factor Analysis")
        
        risk_factors = []
        if customer['tenure_months'] < 12:
            risk_factors.append(f"📅 New customer (tenure: {customer['tenure_months']} months)")
        if customer['satisfaction_score'] < 3:
            risk_factors.append(f"😞 Low satisfaction ({customer['satisfaction_score']:.1f}/5.0)")
        if customer['support_tickets_6m'] > 2:
            risk_factors.append(f"🎫 High support activity ({customer['support_tickets_6m']} tickets)")
        if customer['overdue_amount'] > 0:
            risk_factors.append(f"💳 Overdue payments (${customer['overdue_amount']:.2f})")
        if customer['nps_score'] < 0:
            risk_factors.append(f"👎 Negative NPS score ({customer['nps_score']})")
        
        if risk_factors:
            st.warning("⚠️ **Risk Factors Identified:**")
            for factor in risk_factors:
                st.write(f"• {factor}")
        else:
            st.success("✅ **No major risk factors identified**")
        
        # Retention recommendations
        st.subheader("💡 Retention Recommendations")
        
        if customer['churn_risk'] == 'High':
            st.error("🚨 **Immediate Action Required**")
            st.write("• Schedule immediate call with customer")
            st.write("• Review account for service issues")
            st.write("• Consider retention offers or discounts")
        elif customer['churn_risk'] == 'Medium':
            st.warning("⚠️ **Monitor Closely**")
            st.write("• Proactive outreach recommended")
            st.write("• Review recent support tickets")
            st.write("• Consider service upgrades or promotions")
        else:
            st.success("✅ **Low Risk - Maintain Relationship**")
            st.write("• Continue excellent service")
            st.write("• Explore upsell opportunities")
            st.write("• Regular satisfaction surveys")
        
        # Customer journey timeline
        st.subheader("🛤️ Customer Journey")
        journey_data = {
            'Date': [customer['last_payment_date'], customer['last_support_date']],
            'Event': ['Last Payment', 'Last Support Contact'],
            'Days Ago': [
                (datetime.now().date() - customer['last_payment_date'].date()).days,
                (datetime.now().date() - customer['last_support_date'].date()).days if pd.notna(customer['last_support_date']) else None
            ]
        }
        
        journey_df = pd.DataFrame(journey_data).dropna()
        if not journey_df.empty:
            fig = px.timeline(journey_df, x_start='Date', x_end='Date', y='Event',
                             title="Recent Customer Activity")
            st.plotly_chart(fig, use_container_width=True)
    
    else:
        # Overall risk analysis
        risk_counts = customers_df['churn_risk'].value_counts()
        high_risk_pct = (risk_counts.get('High', 0) / len(customers_df)) * 100
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("High Risk Customers", f"{risk_counts.get('High', 0):,}")
        with col2:
            st.metric("Medium Risk Customers", f"{risk_counts.get('Medium', 0):,}")
        with col3:
            st.metric("Low Risk Customers", f"{risk_counts.get('Low', 0):,}")
        with col4:
            st.metric("High Risk %", f"{high_risk_pct:.1f}%")
        
        # Risk analysis charts
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("⚠️ Churn Risk Distribution")
            colors = ['green', 'orange', 'red']
            fig = px.pie(values=risk_counts.values, names=risk_counts.index,
                        title="Customer Risk Levels",
                        color_discrete_sequence=colors)
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.subheader("😊 Satisfaction vs Risk")
            fig = px.box(customers_df, x='churn_risk', y='satisfaction_score',
                        title="Satisfaction Score by Risk Level",
                        color='churn_risk',
                        color_discrete_sequence=['green', 'orange', 'red'])
            st.plotly_chart(fig, use_container_width=True)
        
        # High risk customers table
        st.subheader("🚨 High Risk Customers Requiring Attention")
        high_risk_customers = customers_df[customers_df['churn_risk'] == 'High'].copy()
        
        if not high_risk_customers.empty:
            # Select relevant columns for display
            display_cols = ['customer_id', 'first_name', 'last_name', 'plan_type', 
                          'monthly_revenue', 'satisfaction_score', 'support_tickets_6m', 'overdue_amount']
            
            high_risk_display = high_risk_customers[display_cols].sort_values('monthly_revenue', ascending=False)
            st.dataframe(high_risk_display, use_container_width=True)
        else:
            st.success("🎉 No high-risk customers identified!")
        
        # Correlation analysis
        st.subheader("📊 Risk Factor Correlations")
        
        # Create risk score for correlation
        risk_mapping = {'Low': 1, 'Medium': 2, 'High': 3}
        customers_df['risk_score'] = customers_df['churn_risk'].map(risk_mapping)
        
        correlation_data = customers_df[['risk_score', 'satisfaction_score', 'support_tickets_6m', 
                                       'tenure_months', 'overdue_amount']].corr()
        
        fig = px.imshow(correlation_data, 
                       title="Risk Factor Correlation Matrix",
                       color_continuous_scale='RdBu_r')
        st.plotly_chart(fig, use_container_width=True)

if __name__ == "__main__":
    main()
