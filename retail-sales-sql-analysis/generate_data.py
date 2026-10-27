"""Generate a synthetic retail dataset (customers, products, orders, order_items).

All data is synthetic (random, seeded) so the project is reproducible and
contains no real customer information.
"""
import csv
import random
from datetime import date, timedelta

random.seed(42)

REGIONS = ["North", "South", "East", "West"]
SEGMENTS = ["Consumer", "Corporate", "Home Office"]
CATEGORIES = {
    "Electronics": (80, 900),
    "Furniture": (60, 700),
    "Office Supplies": (3, 60),
    "Clothing": (15, 150),
    "Groceries": (2, 40),
}
CHANNELS = ["Online", "Store"]

N_CUSTOMERS, N_PRODUCTS, N_ORDERS = 3000, 60, 9000
START, END = date(2024, 1, 1), date(2025, 12, 31)

def rand_date(a, b):
    return a + timedelta(days=random.randint(0, (b - a).days))

# customers
customers = []
for cid in range(1, N_CUSTOMERS + 1):
    customers.append({
        "customer_id": cid,
        "customer_name": f"Customer {cid:04d}",
        "region": random.choices(REGIONS, weights=[30, 20, 25, 25])[0],
        "segment": random.choices(SEGMENTS, weights=[60, 25, 15])[0],
        "signup_date": rand_date(date(2022, 1, 1), date(2024, 6, 30)).isoformat(),
    })

# products
products = []
pid = 1
per_cat = N_PRODUCTS // len(CATEGORIES)
for cat, (lo, hi) in CATEGORIES.items():
    for i in range(per_cat):
        price = round(random.uniform(lo, hi), 2)
        cost = round(price * random.uniform(0.55, 0.85), 2)
        products.append({
            "product_id": pid,
            "product_name": f"{cat} Item {i + 1}",
            "category": cat,
            "unit_price": price,
            "unit_cost": cost,
        })
        pid += 1

# orders + items (seasonality: Nov/Dec uplift; customers vary in activity)
cust_weights = [random.paretovariate(2.2) for _ in customers]
prod_weights = [random.paretovariate(3.0) for _ in products]
# regional taste differences so category rankings are not identical everywhere
REGION_BIAS = {
    "North": {"Furniture": 1.6, "Electronics": 1.0, "Clothing": 1.0, "Office Supplies": 1.0, "Groceries": 1.0},
    "South": {"Furniture": 1.0, "Electronics": 1.0, "Clothing": 1.8, "Office Supplies": 1.0, "Groceries": 1.5},
    "East":  {"Furniture": 1.0, "Electronics": 1.7, "Clothing": 1.0, "Office Supplies": 1.0, "Groceries": 1.0},
    "West":  {"Furniture": 1.0, "Electronics": 1.0, "Clothing": 1.0, "Office Supplies": 1.8, "Groceries": 1.0},
}
orders, items = [], []
item_id = 1
for oid in range(1, N_ORDERS + 1):
    while True:
        d = rand_date(START, END)
        if d.month in (11, 12) or random.random() < 0.8:
            break
    c = random.choices(customers, weights=cust_weights)[0]
    discount = random.choices([0, 0.05, 0.10, 0.20], weights=[60, 20, 15, 5])[0]
    orders.append({
        "order_id": oid,
        "customer_id": c["customer_id"],
        "order_date": d.isoformat(),
        "order_month": d.strftime("%Y-%m"),
        "channel": random.choices(CHANNELS, weights=[55, 45])[0],
        "discount": discount,
    })
    for _ in range(random.choices([1, 2, 3, 4], weights=[45, 30, 17, 8])[0]):
        w = [pw * REGION_BIAS[c["region"]][pr["category"]] for pw, pr in zip(prod_weights, products)]
        p = random.choices(products, weights=w)[0]
        items.append({
            "item_id": item_id,
            "order_id": oid,
            "product_id": p["product_id"],
            "quantity": random.choices([1, 2, 3, 4, 5], weights=[55, 25, 10, 6, 4])[0],
        })
        item_id += 1

def write(name, rows):
    with open(f"data/{name}.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    print(f"{name}: {len(rows)} rows")

write("customers", customers)
write("products", products)
write("orders", orders)
write("order_items", items)
