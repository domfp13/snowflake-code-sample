import os
from datetime import datetime

import pandas as pd
import psycopg2
import psycopg2.extras
import streamlit as st
from dotenv import load_dotenv

load_dotenv()


DB_CONFIG = {
    "host": os.getenv("PGHOST"),
    "port": int(os.getenv("PGPORT", "5432")),
    "user": os.getenv("PGUSER"),
    "password": os.getenv("PGPASSWORD"),
    "dbname": os.getenv("PGDATABASE", "postgres"),
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def fetch_orders(limit=10, order_id=None):
    with get_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            if order_id:
                cur.execute(
                    """
                    SELECT *
                    FROM public.orders
                    WHERE order_id = %s
                    ORDER BY order_id
                    """,
                    (order_id,),
                )
            else:
                cur.execute(
                    """
                    SELECT *
                    FROM public.orders
                    ORDER BY order_id
                    LIMIT %s
                    """,
                    (limit,),
                )
            return cur.fetchall()


def upsert_order(data):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO public.orders (
                    order_id,
                    customer_id,
                    mfg_plant_id,
                    order_date,
                    order_status,
                    product_id,
                    quantity,
                    total_price,
                    unit_price
                ) VALUES (
                    %(order_id)s,
                    %(customer_id)s,
                    %(mfg_plant_id)s,
                    %(order_date)s,
                    %(order_status)s,
                    %(product_id)s,
                    %(quantity)s,
                    %(total_price)s,
                    %(unit_price)s
                )
                ON CONFLICT (order_id) DO UPDATE SET
                    customer_id = EXCLUDED.customer_id,
                    mfg_plant_id = EXCLUDED.mfg_plant_id,
                    order_date = EXCLUDED.order_date,
                    order_status = EXCLUDED.order_status,
                    product_id = EXCLUDED.product_id,
                    quantity = EXCLUDED.quantity,
                    total_price = EXCLUDED.total_price,
                    unit_price = EXCLUDED.unit_price
                """,
                data,
            )


def delete_order(order_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM public.orders WHERE order_id = %s", (order_id,))


def parse_datetime(value):
    if isinstance(value, datetime):
        return value
    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


def main():
    st.set_page_config(page_title="Orders Admin", page_icon="📦", layout="wide")
    st.title("Orders Admin")
    st.caption("Add, edit, delete, and search orders by ORDER_ID")

    with st.sidebar:
        st.header("Connection")
        st.text_input("Host", value=DB_CONFIG.get("host") or "", disabled=True)
        st.text_input("Port", value=str(DB_CONFIG.get("port") or ""), disabled=True)
        st.text_input("User", value=DB_CONFIG.get("user") or "", disabled=True)
        st.text_input("Database", value=DB_CONFIG.get("dbname") or "", disabled=True)

    st.subheader("Search by ORDER_ID")
    search_id = st.text_input("Order ID", placeholder="e.g. 10")

    col_a, col_b, col_c = st.columns([1, 1, 2])
    with col_a:
        show_limit = st.number_input("Rows", min_value=1, max_value=100, value=10, step=1)
    with col_b:
        search_btn = st.button("Search")

    results = []
    if search_btn and search_id:
        try:
            results = fetch_orders(order_id=int(search_id))
        except ValueError:
            st.error("Order ID must be an integer.")
    elif search_btn:
        results = fetch_orders(limit=int(show_limit))
    else:
        results = fetch_orders(limit=int(show_limit))

    st.subheader("Results")
    if results:
        df = pd.DataFrame([dict(row) for row in results])
        st.dataframe(df, use_container_width=True)
    else:
        st.info("No records found.")

    st.divider()
    st.subheader("Add or Edit Order")

    with st.form("order_form"):
        order_id = st.number_input("ORDER_ID", min_value=1, step=1)
        customer_id = st.text_input("CUSTOMER_ID")
        mfg_plant_id = st.text_input("MFG_PLANT_ID")
        order_date = st.text_input("ORDER_DATE", value="2026-01-01 00:00:00")
        order_status = st.text_input("ORDER_STATUS")
        product_id = st.text_input("PRODUCT_ID")
        quantity = st.number_input("QUANTITY", min_value=0, step=1)
        total_price = st.number_input("TOTAL_PRICE", min_value=0.0, step=1.0, format="%.2f")
        unit_price = st.number_input("UNIT_PRICE", min_value=0.0, step=1.0, format="%.2f")

        submitted = st.form_submit_button("Add / Update")

        if submitted:
            try:
                data = {
                    "order_id": int(order_id),
                    "customer_id": customer_id,
                    "mfg_plant_id": mfg_plant_id,
                    "order_date": parse_datetime(order_date),
                    "order_status": order_status,
                    "product_id": product_id,
                    "quantity": int(quantity),
                    "total_price": float(total_price),
                    "unit_price": float(unit_price),
                }
                upsert_order(data)
                st.success("Order saved.")
            except Exception as exc:  # noqa: BLE001
                st.error(f"Failed to save order: {exc}")

    st.divider()
    st.subheader("Delete Order")
    delete_id = st.number_input("ORDER_ID to delete", min_value=1, step=1, key="delete_id")
    if st.button("Delete"):
        try:
            delete_order(int(delete_id))
            st.success("Order deleted.")
        except Exception as exc:  # noqa: BLE001
            st.error(f"Failed to delete order: {exc}")


if __name__ == "__main__":
    main()
