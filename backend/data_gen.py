import pandas as pd
import numpy as np

def generate_optimized_data(n_samples=5000):
    np.random.seed(42)
    
    age = np.random.randint(18, 95, n_samples)
    income = np.random.randint(30000, 800000, n_samples)
    land_size = np.random.uniform(0, 15, n_samples)
    is_rural = np.random.choice([0, 1], size=n_samples, p=[0.3, 0.7])
    house_type = np.random.choice([0, 1], size=n_samples, p=[0.5, 0.5]) 
    is_taxpayer = np.random.choice([0, 1], size=n_samples, p=[0.8, 0.2])
    is_govt_emp = np.random.choice([0, 1], size=n_samples, p=[0.9, 0.1])

    data = pd.DataFrame({
        'age': age, 'income': income, 'land_size': land_size,
        'is_rural': is_rural, 'house_type': house_type,
        'is_taxpayer': is_taxpayer, 'is_govt_emp': is_govt_emp
    })

    def determine_eligibility(row):
        if row['is_taxpayer'] == 1 or row['is_govt_emp'] == 1:
            if row['age'] < 70:  # Only Ayushman Bharat senior rule bypasses this
              return 0
        if row['is_taxpayer'] == 1 or row['is_govt_emp'] == 1: return 0
        if row['is_rural'] == 1 and row['land_size'] <= 5 and row['income'] <= 300000: return 1
        if row['is_rural'] == 1 and row['house_type'] == 0 and row['income'] <= 180000: return 1
        return 0

    data['eligible'] = data.apply(determine_eligibility, axis=1)
    data.to_csv('vaani_seva_training.csv', index=False)
    print(f"✅ Success! Generated {n_samples} samples in 'vaani_seva_training.csv'")

if __name__ == "__main__":
    generate_optimized_data()