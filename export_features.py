import duckdb
import pandas as pd
from pathlib import Path


Path("exports").mkdir(exist_ok=True)

conn = duckdb.connect("dev.duckdb")

df = conn.execute("SELECT * FROM fct_churn_features").df()

df.to_csv("exports/fct_churn_features.csv", index=False)

print(f"Exported {len(df)} rows, {df.columns.tolist()}")
print(f"Churn rate in export: {df['has_churned'].mean():.1%}")
print(f"Null counts:\n{df.isna().sum()[df.isna().sum() > 0]}")


conn.close()
