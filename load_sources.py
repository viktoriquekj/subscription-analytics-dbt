import duckdb
import pandas as pd

conn = duckdb.connect("dev.duckdb")

df = pd.read_csv("data/Telco-Customer-Churn.csv")

# TotalCharges has blank strings for brand-new customers with zero charges
# pd.to_numeric with errors='coerce' converts blanks to proper nulls
df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")

null_charges = df["TotalCharges"].isna().sum()
print(f"Customers with null TotalCharges (new, no charges yet): {null_charges}")

conn.execute("DROP TABLE IF EXISTS raw_telco_customers")
conn.execute("CREATE TABLE raw_telco_customers AS SELECT * FROM df")

count = conn.execute("SELECT COUNT(*) FROM raw_telco_customers").fetchone()[0]
churn_rate = conn.execute(
    "SELECT ROUND(AVG(CASE WHEN Churn = 'Yes' THEN 1.0 ELSE 0.0 END) * 100, 1) FROM raw_telco_customers"
).fetchone()[0]

print(f"Loaded {count} rows into raw_telco_customers")
print(f"Overall churn rate: {churn_rate}%")
conn.close()

