"""SQL analysis for the Saudi Arabia Budget Analysis project (1993-2020).

1. Reads data/data.xlsx and stores it in SQLite (data/saudi_budget.db, table public_finances_sql).
2. Creates the view budget with English column names.
3. Runs every query in queries.sql and prints the results.

Usage (from the repository root):  python notebook/sql_analysis.py
"""
import re
import sqlite3
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent
ROOT = BASE.parent if (BASE.parent / "data").exists() else BASE   # works from notebook/ or one folder
XLSX = ROOT / "data" / "data.xlsx" if (ROOT / "data").exists() else BASE / "data.xlsx"
DB_FILE = XLSX.parent / "saudi_budget.db"
QUERIES_FILE = BASE / "queries.sql"

# ---------- 1. Load the data ----------
df = pd.read_excel(XLSX, sheet_name="public finance", header=2)
df.columns = [str(c).strip() for c in df.columns]
df = df.dropna(how="all").dropna(subset=[df.columns[0]])
df[df.columns[0]] = df[df.columns[0]].astype(int)

conn = sqlite3.connect(DB_FILE)
df.to_sql("public_finances_sql", conn, if_exists="replace", index=False)

# ---------- 2. English view (all values in million SAR) ----------
conn.executescript("""
DROP VIEW IF EXISTS budget;
CREATE VIEW budget AS
SELECT "السنة"                 AS Year,
       "الإيرادات"             AS Revenue,
       "إيرادات نفطية"         AS Oil_Revenue,
       "إيرادات غير نفطية"     AS NonOil_Revenue,
       "النفقات"               AS Expenditure,
       "نفقات تشغيلية"         AS Operating_Exp,
       "نفقات رأسمالية"        AS Capital_Exp,
       "فائض/عجز الميزانية"    AS Balance
FROM public_finances_sql;
""")
conn.commit()

print("DATABASE BUILT")
for name in ("public_finances_sql", "budget"):
    n = conn.execute(f"SELECT COUNT(*) FROM {name}").fetchone()[0]
    print(f"  {name}: {n:,} rows")

# ---------- 3. Run the queries ----------
sql = open(QUERIES_FILE, encoding="utf-8").read()
for block in [b.strip() for b in sql.split(";") if "SELECT" in b or "WITH" in b]:
    title = re.search(r"-- (Q\d+\..*)", block)
    print("\n" + (title.group(1) if title else ""))
    print(pd.read_sql(block + ";", conn).to_string(index=False))
conn.close()
