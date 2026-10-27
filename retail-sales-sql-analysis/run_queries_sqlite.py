"""Load the CSVs into SQLite and run every query in sql/03_analysis_queries.sql.

Lets anyone reproduce the results without installing MySQL:
    python generate_data.py && python run_queries_sqlite.py
Results are written to results/Q*.csv and printed.
"""
import csv, re, sqlite3, pathlib

root = pathlib.Path(__file__).parent
con = sqlite3.connect(":memory:")
con.executescript("""
CREATE TABLE customers (customer_id INT PRIMARY KEY, customer_name TEXT, region TEXT, segment TEXT, signup_date TEXT);
CREATE TABLE products (product_id INT PRIMARY KEY, product_name TEXT, category TEXT, unit_price REAL, unit_cost REAL);
CREATE TABLE orders (order_id INT PRIMARY KEY, customer_id INT, order_date TEXT, order_month TEXT, channel TEXT, discount REAL);
CREATE TABLE order_items (item_id INT PRIMARY KEY, order_id INT, product_id INT, quantity INT);
""")
for table in ["customers", "products", "orders", "order_items"]:
    with open(root / "data" / f"{table}.csv") as f:
        rows = list(csv.reader(f))
    marks = ",".join("?" * len(rows[0]))
    con.executemany(f"INSERT INTO {table} VALUES ({marks})", rows[1:])

sql = (root / "sql" / "03_analysis_queries.sql").read_text()
parts = re.split(r"^-- (Q\d+): (.*)$", sql, flags=re.M)
(root / "results").mkdir(exist_ok=True)
for i in range(1, len(parts), 3):
    qid, question, body = parts[i], parts[i + 1], parts[i + 2]
    body = "\n".join(l for l in body.splitlines() if not l.startswith("--")).strip()
    cur = con.execute(body)
    cols = [d[0] for d in cur.description]
    data = cur.fetchall()
    with open(root / "results" / f"{qid}.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(cols); w.writerows(data)
    print(f"\n{qid}: {question}")
    print(" | ".join(cols))
    for r in data[:12]:
        print(" | ".join(str(x) for x in r))
