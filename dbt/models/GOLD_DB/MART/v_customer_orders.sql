{{ config(materialized='view', post_hook=["{{ grant_app() }}"]) }}

-- Reporting view: one row per order with customer and product details
SELECT
  F.CUSTOMER_ID,
  C.FULL_NAME,
  C.CITY,
  F.ORDER_ID,
  F.ORDER_DATE,
  F.STATUS,
  P.PRODUCT_NAME,
  P.CATEGORY,
  F.QUANTITY,
  F.AMOUNT
FROM {{ ref('fct_orders') }} F
JOIN {{ ref('dim_customers') }} C ON C.CUSTOMER_ID = F.CUSTOMER_ID
JOIN {{ ref('stg_products') }}  P ON P.PRODUCT_ID  = F.PRODUCT_ID
