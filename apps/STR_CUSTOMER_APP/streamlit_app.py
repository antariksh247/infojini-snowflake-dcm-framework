"""INFOJINI customer app (Streamlit in Snowflake, deployed by DCM as an asset).

Environment-agnostic: no database names in this file. The app is created inside
INFOJINI_<ENV>_GOLD_DB, so CURRENT_DATABASE() tells us which environment we are in.
Reads  : Gold views only (MART.V_CUSTOMER_ORDERS, APP.V_CUSTOMER_NOTES)
Writes : only through the stored procedure APP.SP_ADD_NOTE (never direct INSERT)
Uses only APIs of the Streamlit version in the warehouse runtime (no hide_index etc.).
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()
DB = session.sql("SELECT CURRENT_DATABASE()").collect()[0][0]  # e.g. INFOJINI_DEV_GOLD_DB


@st.cache_data(ttl=600)  # cost: reruns / other viewers reuse results for 10 min
def query(sql: str):
    return session.sql(sql).to_pandas()


st.set_page_config(page_title="INFOJINI customer app", layout="wide")
st.title("Customer orders & notes")
st.caption(f"Environment database: {DB}")

# ---------------------------------------------------------------- orders
orders = query(f'SELECT * FROM "{DB}".MART.V_CUSTOMER_ORDERS ORDER BY ORDER_DATE DESC')
orders["AMOUNT"] = orders["AMOUNT"].astype(float)

c1, c2, c3 = st.columns(3)
c1.metric("Orders", len(orders))
c2.metric("Revenue", f"{orders['AMOUNT'].sum():,.0f}")
c3.metric("Customers", orders["CUSTOMER_ID"].nunique())

left, right = st.columns([2, 1])
with left:
    st.subheader("Orders")
    st.dataframe(orders, use_container_width=True)
with right:
    st.subheader("Revenue by city")
    st.bar_chart(orders.groupby("CITY")["AMOUNT"].sum())

# ---------------------------------------------------------------- notes
st.subheader("Customer notes")

customers = (
    orders[["CUSTOMER_ID", "FULL_NAME"]]
    .drop_duplicates()
    .sort_values("FULL_NAME")
)
names = dict(zip(customers["CUSTOMER_ID"], customers["FULL_NAME"]))

with st.form("add_note", clear_on_submit=True):
    customer_id = st.selectbox(
        "Customer", options=list(names), format_func=lambda cid: f"{names[cid]} ({cid})"
    )
    note = st.text_area("Note")
    if st.form_submit_button("Add note"):
        result = session.sql(
            f'CALL "{DB}".APP.SP_ADD_NOTE(?, ?)', params=[int(customer_id), note]
        ).collect()[0][0]
        if result == "OK":
            st.cache_data.clear()  # show the new note immediately
            st.success("Note saved")
        else:
            st.error(result)

notes = query(f'SELECT * FROM "{DB}".APP.V_CUSTOMER_NOTES ORDER BY CREATED_AT DESC')
st.dataframe(notes, use_container_width=True)
