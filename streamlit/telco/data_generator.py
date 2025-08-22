import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta

fake = Faker()

def generate_telco_data(n_customers=1000):
    """Generate realistic telco customer data"""
    
    np.random.seed(42)
    random.seed(42)
    Faker.seed(42)
    
    customers = []
    
    for i in range(n_customers):
        # Basic customer info
        customer_id = f"CUST_{i+1:06d}"
        first_name = fake.first_name()
        last_name = fake.last_name()
        email = f"{first_name.lower()}.{last_name.lower()}@{fake.free_email_domain()}"
        phone = fake.phone_number()
        
        # Demographics
        age = np.random.randint(18, 80)
        gender = np.random.choice(['Male', 'Female'], p=[0.48, 0.52])
        city = fake.city()
        state = fake.state()
        
        # Account info
        tenure_months = np.random.randint(1, 120)
        account_status = np.random.choice(['Active', 'Suspended', 'Inactive'], p=[0.85, 0.10, 0.05])
        
        # Service plan
        plan_type = np.random.choice(['Basic', 'Standard', 'Premium', 'Enterprise'], p=[0.3, 0.4, 0.25, 0.05])
        monthly_revenue = {
            'Basic': np.random.normal(45, 10),
            'Standard': np.random.normal(75, 15),
            'Premium': np.random.normal(120, 20),
            'Enterprise': np.random.normal(200, 30)
        }[plan_type]
        monthly_revenue = max(20, monthly_revenue)  # Minimum $20
        
        # Usage data (last 30 days)
        voice_minutes = max(0, np.random.gamma(2, 150))
        data_gb = max(0, np.random.gamma(3, 8))
        sms_count = max(0, np.random.poisson(50))
        
        # Billing
        last_payment_date = fake.date_between(start_date='-90d', end_date='today')
        payment_method = np.random.choice(['Credit Card', 'Debit Card', 'Bank Transfer', 'Cash'], p=[0.5, 0.25, 0.2, 0.05])
        if np.random.random() < 0.15:  # 15% chance of having overdue amount
            overdue_amount = np.random.uniform(20, 200)
        else:
            overdue_amount = 0
        
        # Customer satisfaction
        satisfaction_score = np.random.beta(3, 1.5) * 5  # Skewed towards higher satisfaction
        nps_score = np.random.randint(-10, 11)
        
        # Support tickets
        support_tickets_last_6m = np.random.poisson(1.5)
        last_support_date = fake.date_between(start_date='-180d', end_date='today') if support_tickets_last_6m > 0 else None
        
        # Churn risk factors
        days_since_last_payment = (datetime.now().date() - last_payment_date).days
        churn_risk = calculate_churn_risk(tenure_months, satisfaction_score, support_tickets_last_6m, 
                                        days_since_last_payment, overdue_amount)
        
        # Product recommendations
        products_owned = generate_products_owned(plan_type)
        recommended_products = generate_recommendations(plan_type, products_owned, usage_profile={
            'voice': voice_minutes, 'data': data_gb, 'sms': sms_count
        })
        
        customer = {
            'customer_id': customer_id,
            'first_name': first_name,
            'last_name': last_name,
            'email': email,
            'phone': phone,
            'age': age,
            'gender': gender,
            'city': city,
            'state': state,
            'tenure_months': tenure_months,
            'account_status': account_status,
            'plan_type': plan_type,
            'monthly_revenue': round(monthly_revenue, 2),
            'voice_minutes_30d': round(voice_minutes, 1),
            'data_gb_30d': round(data_gb, 2),
            'sms_count_30d': int(sms_count),
            'last_payment_date': last_payment_date,
            'payment_method': payment_method,
            'overdue_amount': round(overdue_amount, 2),
            'satisfaction_score': round(satisfaction_score, 2),
            'nps_score': nps_score,
            'support_tickets_6m': support_tickets_last_6m,
            'last_support_date': last_support_date,
            'churn_risk': churn_risk,
            'products_owned': ', '.join(products_owned),
            'recommended_products': ', '.join(recommended_products)
        }
        
        customers.append(customer)
    
    return pd.DataFrame(customers)

def calculate_churn_risk(tenure, satisfaction, support_tickets, days_since_payment, overdue):
    """Calculate churn risk score based on various factors"""
    risk_score = 0
    
    # Tenure factor (newer customers more likely to churn)
    if tenure < 6:
        risk_score += 30
    elif tenure < 12:
        risk_score += 20
    elif tenure < 24:
        risk_score += 10
    
    # Satisfaction factor
    if satisfaction < 2:
        risk_score += 40
    elif satisfaction < 3:
        risk_score += 25
    elif satisfaction < 4:
        risk_score += 10
    
    # Support tickets factor
    if support_tickets > 3:
        risk_score += 25
    elif support_tickets > 1:
        risk_score += 15
    
    # Payment behavior
    if overdue > 0:
        risk_score += 30
    if days_since_payment > 45:
        risk_score += 20
    
    # Convert to category
    if risk_score >= 60:
        return 'High'
    elif risk_score >= 30:
        return 'Medium'
    else:
        return 'Low'

def generate_products_owned(plan_type):
    """Generate products owned based on plan type"""
    base_products = ['Mobile Service']
    
    if plan_type in ['Standard', 'Premium', 'Enterprise']:
        if random.random() < 0.7:
            base_products.append('Internet')
    
    if plan_type in ['Premium', 'Enterprise']:
        if random.random() < 0.5:
            base_products.append('TV Service')
        if random.random() < 0.3:
            base_products.append('Home Security')
    
    if plan_type == 'Enterprise':
        if random.random() < 0.8:
            base_products.append('Business Solutions')
    
    # Additional products
    additional = ['Insurance', 'Device Protection', 'International Roaming', 'Cloud Storage']
    for product in additional:
        if random.random() < 0.2:
            base_products.append(product)
    
    return base_products

def generate_recommendations(plan_type, owned_products, usage_profile):
    """Generate product recommendations based on usage and current products"""
    recommendations = []
    
    # High data usage recommendations
    if usage_profile['data'] > 15 and 'Unlimited Data' not in owned_products:
        recommendations.append('Unlimited Data Plan')
    
    # International usage
    if random.random() < 0.15 and 'International Roaming' not in owned_products:
        recommendations.append('International Package')
    
    # Device upgrade
    if random.random() < 0.3:
        recommendations.append('Device Upgrade')
    
    # Cross-sell opportunities
    if 'Internet' not in owned_products and random.random() < 0.4:
        recommendations.append('Home Internet')
    
    if 'TV Service' not in owned_products and 'Internet' in owned_products and random.random() < 0.35:
        recommendations.append('TV Bundle')
    
    if plan_type in ['Premium', 'Enterprise'] and 'Home Security' not in owned_products and random.random() < 0.25:
        recommendations.append('Home Security System')
    
    return recommendations[:3]  # Limit to top 3 recommendations

def generate_usage_history(customers_df, months=6):
    """Generate historical usage data for trend analysis"""
    usage_history = []
    
    for _, customer in customers_df.iterrows():
        for month_ago in range(months):
            date = datetime.now() - timedelta(days=30 * month_ago)
            
            # Add some seasonality and trend to usage
            seasonal_factor = 1 + 0.1 * np.sin(2 * np.pi * date.month / 12)
            
            usage_record = {
                'customer_id': customer['customer_id'],
                'month': date.strftime('%Y-%m'),
                'voice_minutes': max(0, customer['voice_minutes_30d'] * seasonal_factor * np.random.normal(1, 0.2)),
                'data_gb': max(0, customer['data_gb_30d'] * seasonal_factor * np.random.normal(1, 0.3)),
                'sms_count': max(0, customer['sms_count_30d'] * seasonal_factor * np.random.normal(1, 0.4)),
                'revenue': customer['monthly_revenue'] * np.random.normal(1, 0.1)
            }
            
            usage_history.append(usage_record)
    
    return pd.DataFrame(usage_history)

if __name__ == "__main__":
    # Generate data
    print("Generating telco customer data...")
    customers = generate_telco_data(1000)
    usage_history = generate_usage_history(customers, 6)
    
    # Save to CSV
    customers.to_csv('customer_data.csv', index=False)
    usage_history.to_csv('usage_history.csv', index=False)
    
    print(f"Generated {len(customers)} customers")
    print(f"Generated {len(usage_history)} usage records")
    print("Data saved to customer_data.csv and usage_history.csv")
