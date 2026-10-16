-- Notes with customer name, read by the app
SELECT
  N.NOTE_ID,
  N.CUSTOMER_ID,
  C.FULL_NAME,
  N.NOTE,
  N.CREATED_AT
FROM {{ source('app', 'CUSTOMER_NOTES') }} N
LEFT JOIN {{ ref('dim_customers') }} C ON C.CUSTOMER_ID = N.CUSTOMER_ID
