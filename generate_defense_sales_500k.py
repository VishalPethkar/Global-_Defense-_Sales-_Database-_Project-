"""
Global Defense & Tactical Equipment Sales Data Generator  (500,000 rows)
-----------------------------------------------------------------------
Single, self-contained script. Generates SYNTHETIC B2B/B2G sales data using the
same schema and business rules as the original 10K / 110K files, and saves
'Global_Defense_Sales_Data_500K.xlsx'.

NOTE: Simulated data for analytics/BI practice. Supplier names are real
companies used only as labels; no figure reflects any real transaction.

Requirements:  pip install pandas numpy xlsxwriter
Run:           python generate_defense_sales_500k.py
(Excel's row limit is 1,048,576, so 500,000 rows fit on one sheet.)
"""

import math
import random
from datetime import date, timedelta

import numpy as np
import pandas as pd

# --------------------------------------------------------------------------
# CONFIGURATION
# --------------------------------------------------------------------------
SEED = 42
NUM_ROWS = 500_000
NUM_CUSTOMERS = 100_000          # << NUM_ROWS  => many repeat contracts
OUTPUT_FILE = "Global_Defense_Sales_Data_500K.xlsx"

random.seed(SEED)                # same seed as the original => same SKU costs/suppliers
rng = np.random.default_rng(SEED)

# --------------------------------------------------------------------------
# PRODUCT CATALOG
# --------------------------------------------------------------------------
CATALOG = {
    "Assault Rifle": {
        "code": "AR",
        "items": ["AKM", "M416", "SCAR-L", "Groza", "AUG A3", "Beryl M762",
                  "M16A4", "QBZ", "ACE32", "Mk47 Mutant"],
        "cost_range": (3000, 7000), "weight": 20,
        "suppliers": ["Heckler & Koch (Germany)",
                      "Advanced Weapons and Equipment India Ltd. (AWEIL India)",
                      "Beretta Holding (Italy)", "FN Herstal (Belgium)",
                      "Colt Defense (USA)"],
    },
    "Sniper Rifle": {
        "code": "SR",
        "items": ["Kar98k", "M24", "AWM", "Mosin-Nagant", "Win94", "SKS",
                  "Mini 14", "Mk14", "SLR", "VSS"],
        "cost_range": (5000, 10000), "weight": 10,
        "suppliers": ["Accuracy International (UK)", "Heckler & Koch (Germany)",
                      "Sig Sauer (USA)",
                      "Advanced Weapons and Equipment India Ltd. (AWEIL India)"],
    },
    "SMG": {
        "code": "SM",
        "items": ["Micro UZI", "UMP45", "Vector", "Thompson SMG", "PP-19 Bizon"],
        "cost_range": (1500, 4000), "weight": 10,
        "suppliers": ["Heckler & Koch (Germany)", "Beretta Holding (Italy)",
                      "Naraindas Deepchand and Sons (India)"],
    },
    "Shotgun": {
        "code": "SG",
        "items": ["S686", "S1897", "S12K", "DBS"],
        "cost_range": (1000, 3500), "weight": 7,
        "suppliers": ["Beretta Holding (Italy)", "Benelli (Italy)",
                      "Khadki Arms and Ammunition Dealer (India)"],
    },
    "Handgun": {
        "code": "HG",
        "items": ["R1895 Revolver", "R45 Revolver", "Desert Eagle", "P92",
                  "P1911", "Skorpion"],
        "cost_range": (1000, 3000), "weight": 10,
        "suppliers": ["Glock Ges.m.b.H. (Austria)", "Beretta Holding (Italy)",
                      "Taurus Armas (Brazil)", "Heckler & Koch (Germany)"],
    },
    "Throwable": {
        "code": "TH",
        "items": ["Frag Grenade", "Smoke Grenade", "Molotov Cocktail", "Stun Grenade"],
        "cost_range": (200, 500), "weight": 9,
        "suppliers": ["Rheinmetall (Germany)",
                      "Khadki Arms and Ammunition Dealer (India)",
                      "Naraindas Deepchand and Sons (India)"],
    },
    "Armor": {
        "code": "AM",
        "items": ["Spetsnaz Helmet (Level 3)", "Military Vest (Level 3)",
                  "Police Vest (Level 2)", "Helmet (Level 2)",
                  "Police Vest (Level 1)", "Motorcycle Helmet (Level 1)"],
        "cost_range": (5000, 25000), "weight": 12,
        "suppliers": ["Tata Advanced Systems (India)", "Safariland (USA)",
                      "Point Blank Enterprises (USA)"],
    },
    "Ammunition": {
        "code": "AX",
        "items": ["5.56mm Ammo", "7.62mm Ammo", "9mm Ammo", ".45 ACP Ammo",
                  "12 Gauge Ammo", ".300 Magnum Ammo"],
        "cost_range": (10, 50), "weight": 22,
        "suppliers": ["Khadki Arms and Ammunition Dealer (India)",
                      "Naraindas Deepchand and Sons (India)",
                      "Advanced Weapons and Equipment India Ltd. (AWEIL India)",
                      "Rheinmetall (Germany)",
                      "Companhia Brasileira de Cartuchos (Brazil)"],
    },
}

COUNTRY_INFO = {   # country: (region, currency, sampling weight)
    "USA":         ("North America", "USD", 24),
    "Germany":     ("EMEA",          "EUR", 12),
    "UK":          ("EMEA",          "GBP", 11),
    "Japan":       ("APAC",          "JPY", 10),
    "India":       ("APAC",          "INR", 22),
    "South Korea": ("APAC",          "KRW", 10),
    "Brazil":      ("LATAM",         "BRL", 11),
}

SEGMENTS = ["Personal Use", "Military/Army", "Private Security", "Law Enforcement/Defense"]
SEGMENT_WEIGHTS = [15, 30, 20, 35]

QTY_BOUNDS = {     # segment: {gear:(lo,hi), ammo:(lo,hi)}
    "Personal Use":            {"gear": (1, 5),  "ammo": (5000, 15000)},
    "Military/Army":           {"gear": (1, 50), "ammo": (5000, 100000)},
    "Private Security":        {"gear": (1, 30), "ammo": (5000, 60000)},
    "Law Enforcement/Defense": {"gear": (1, 50), "ammo": (5000, 100000)},
}

STATUS_MIX = {"Completed": 0.80, "Returned": 0.10, "Pending": 0.05, "Cancelled": 0.05}


# --------------------------------------------------------------------------
# REFERENCE TABLES
# --------------------------------------------------------------------------
def build_product_master():
    """One row per SKU: fixed ID, category, supplier and base unit cost."""
    products = []
    for category, cfg in CATALOG.items():
        for idx, name in enumerate(cfg["items"], start=1):
            products.append({
                "Product_ID": f"SKU-{cfg['code']}-{idx:03d}",
                "Product_Name": name,
                "Product_Category": category,
                "Supplier_Name": random.choice(cfg["suppliers"]),
                "Unit_Cost": round(random.uniform(*cfg["cost_range"]), 2),
                "weight": cfg["weight"] / len(cfg["items"]),
            })
    return pd.DataFrame(products)


def build_customer_pool(n):
    """Fixed attributes per Customer_ID so repeat contracts stay consistent."""
    countries = list(COUNTRY_INFO)
    c_w = np.array([COUNTRY_INFO[c][2] for c in countries], dtype=float)
    country = rng.choice(countries, size=n, p=c_w / c_w.sum())
    segment = rng.choice(SEGMENTS, size=n, p=np.array(SEGMENT_WEIGHTS) / sum(SEGMENT_WEIGHTS))
    ids = rng.choice(np.arange(100_000, 1_000_000), size=n, replace=False)   # unique 6-digit

    pool = pd.DataFrame({
        "Customer_ID": [f"CUST-{i}" for i in ids],
        "Customer_Segment": segment,
        "Customer_Country": country,
    })
    pool["Customer_Region"] = pool["Customer_Country"].map(lambda c: COUNTRY_INFO[c][0])
    pool["Local_Currency"] = pool["Customer_Country"].map(lambda c: COUNTRY_INFO[c][1])

    # Heavy-tailed activity: a few anchor accounts place many repeat orders (capped at 20x)
    activity = np.minimum(rng.pareto(1.5, size=n) + 1, 20)
    return pool, activity / activity.sum()


def build_status_array(n):
    """Exact 80/10/5/5 split, shuffled."""
    counts = {s: int(n * p) for s, p in STATUS_MIX.items() if s != "Completed"}
    counts["Completed"] = n - sum(counts.values())
    arr = np.array([s for s, c in counts.items() for _ in range(c)])
    rng.shuffle(arr)
    return arr


# --------------------------------------------------------------------------
# GENERATE (vectorised -> 500K rows in a few seconds)
# --------------------------------------------------------------------------
def generate_dataset(n=NUM_ROWS):
    products = build_product_master()
    customers, cust_p = build_customer_pool(NUM_CUSTOMERS)

    prod_p = products["weight"].to_numpy() / products["weight"].sum()
    prod = products.iloc[rng.choice(len(products), size=n, p=prod_p)].reset_index(drop=True)
    cust = customers.iloc[rng.choice(len(customers), size=n, p=cust_p)].reset_index(drop=True)

    # Dates: last 3 years, ending 7 days ago so every Ship_Date <= today
    end = date.today() - timedelta(days=7)
    start = end - timedelta(days=3 * 365)
    span = (end - start).days
    order_date = pd.Timestamp(start) + pd.to_timedelta(rng.integers(0, span + 1, size=n), unit="D")
    ship_date = order_date + pd.to_timedelta(rng.integers(1, 8, size=n), unit="D")

    # Selling price = cost + 15%..50% (done in whole cents so it never leaves the band)
    cost = prod["Unit_Cost"].to_numpy()
    lo_c = np.ceil(cost * 1.15 * 100 - 1e-9).astype(np.int64)
    hi_c = np.floor(cost * 1.50 * 100 + 1e-9).astype(np.int64)
    price = rng.integers(lo_c, hi_c + 1) / 100

    # Quantity by segment and category (ammo vs. gear)
    is_ammo = (prod["Product_Category"] == "Ammunition").to_numpy()
    seg = cust["Customer_Segment"].to_numpy()
    q_lo = np.empty(n, dtype=np.int64)
    q_hi = np.empty(n, dtype=np.int64)
    for s, b in QTY_BOUNDS.items():
        m = seg == s
        q_lo[m & is_ammo], q_hi[m & is_ammo] = b["ammo"]
        q_lo[m & ~is_ammo], q_hi[m & ~is_ammo] = b["gear"]
    qty = rng.integers(q_lo, q_hi + 1)

    disc = rng.integers(0, 21, size=n) / 100
    status = build_status_array(n)

    profit = np.round((price * (1 - disc) - cost) * qty, 2)
    profit[np.isin(status, ["Cancelled", "Returned"])] = 0.0

    suffix = rng.choice(np.arange(100_000, 1_000_000), size=n, replace=False)  # unique
    order_id = [f"ORD-{y}-{s}" for y, s in zip(order_date.year, suffix)]

    df = pd.DataFrame({
        "Order_ID": order_id,
        "Order_Date": order_date,
        "Ship_Date": ship_date,
        "Order_Status": status,
        "Customer_ID": cust["Customer_ID"],
        "Customer_Segment": cust["Customer_Segment"],
        "Customer_Country": cust["Customer_Country"],
        "Customer_Region": cust["Customer_Region"],
        "Product_ID": prod["Product_ID"],
        "Product_Name": prod["Product_Name"],
        "Product_Category": prod["Product_Category"],
        "Supplier_Name": prod["Supplier_Name"],
        "Local_Currency": cust["Local_Currency"],
        "Unit_Cost": cost,
        "Unit_Selling_Price": price,
        "Order_Quantity": qty,
        "Discount_Applied": disc,
        "Net_Profit": profit,
    })
    return df.sort_values("Order_Date", kind="stable").reset_index(drop=True)


# --------------------------------------------------------------------------
# VALIDATE
# --------------------------------------------------------------------------
def validate(df, expected_rows=NUM_ROWS):
    assert df.shape == (expected_rows, 18), f"Schema must be {expected_rows:,} rows x 18 columns"
    assert df["Order_ID"].is_unique, "Order_ID must be unique"

    gap = (df["Ship_Date"] - df["Order_Date"]).dt.days
    assert gap.between(1, 7).all(), "Ship_Date must be 1-7 days after Order_Date"

    share = df["Order_Status"].value_counts(normalize=True).to_dict()
    for status, pct in STATUS_MIX.items():
        assert abs(share[status] - pct) < 1e-6, f"Status mix off for {status}"

    markup = df["Unit_Selling_Price"] / df["Unit_Cost"] - 1
    assert markup.between(0.15 - 1e-6, 0.50 + 1e-6).all(), "Markup outside 15-50%"
    assert df["Discount_Applied"].between(0, 0.20).all(), "Discount outside 0-20%"

    ammo = df["Product_Category"] == "Ammunition"
    assert df.loc[ammo, "Order_Quantity"].between(5000, 100000).all(), "Ammo qty out of range"
    assert df.loc[~ammo, "Order_Quantity"].between(1, 50).all(), "Gear qty out of range"

    for cat, cfg in CATALOG.items():
        sub = df[df["Product_Category"] == cat]
        assert sub["Unit_Cost"].between(*cfg["cost_range"]).all(), f"Unit_Cost out of band: {cat}"
        assert set(sub["Product_Name"]) <= set(cfg["items"]), f"Product/category mismatch: {cat}"

    zero = df["Order_Status"].isin(["Cancelled", "Returned"])
    assert (df.loc[zero, "Net_Profit"] == 0).all(), "Cancelled/Returned must have 0 profit"
    expected = ((df["Unit_Selling_Price"] * (1 - df["Discount_Applied"]) - df["Unit_Cost"])
                * df["Order_Quantity"]).round(2)
    assert (df.loc[~zero, "Net_Profit"] - expected[~zero]).abs().max() < 0.011, \
        "Net_Profit formula mismatch"

    for _, r in df[["Customer_Country", "Customer_Region", "Local_Currency"]].drop_duplicates().iterrows():
        region, currency, _w = COUNTRY_INFO[r["Customer_Country"]]
        assert (r["Customer_Region"], r["Local_Currency"]) == (region, currency), "Geo mismatch"

    assert df.groupby("Customer_ID")["Customer_Country"].nunique().max() == 1, "Customer changed country"
    assert df.groupby("Customer_ID")["Customer_Segment"].nunique().max() == 1, "Customer changed segment"
    print("All validation checks passed.")


# --------------------------------------------------------------------------
# EXPORT
# --------------------------------------------------------------------------
def export_to_excel(df, path):
    with pd.ExcelWriter(path, engine="xlsxwriter", datetime_format="yyyy-mm-dd") as writer:
        df.to_excel(writer, index=False, sheet_name="Sales_Data")
        wb, ws = writer.book, writer.sheets["Sales_Data"]

        base = {"font_name": "Arial", "font_size": 10}
        money = wb.add_format({**base, "num_format": "#,##0.00"})
        qty = wb.add_format({**base, "num_format": "#,##0"})
        disc = wb.add_format({**base, "num_format": "0.00"})
        date_f = wb.add_format({**base, "num_format": "yyyy-mm-dd"})
        text = wb.add_format(base)
        header = wb.add_format({"font_name": "Arial", "bold": True, "font_color": "#FFFFFF",
                                "bg_color": "#1F3864", "align": "center"})

        fmt = {"Unit_Cost": money, "Unit_Selling_Price": money, "Net_Profit": money,
               "Order_Quantity": qty, "Discount_Applied": disc,
               "Order_Date": date_f, "Ship_Date": date_f}

        for i, col in enumerate(df.columns):
            ws.write(0, i, col, header)
            width = min(max(len(col), int(df[col].astype(str).str.len().max())) + 3, 40)
            ws.set_column(i, i, width, fmt.get(col, text))

        ws.freeze_panes(1, 0)
        ws.autofilter(0, 0, len(df), len(df.columns) - 1)


if __name__ == "__main__":
    data = generate_dataset()
    validate(data)
    export_to_excel(data, OUTPUT_FILE)
    print(f"Saved {len(data):,} rows x {data.shape[1]} columns to '{OUTPUT_FILE}'")
    print(data.head(5).to_string(index=False))
