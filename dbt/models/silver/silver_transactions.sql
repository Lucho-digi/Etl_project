{{ config(materialized='table') }}
SELECT
  customer_id,
  transaction_id,
  account_id,
  date::date                                              as transaction_date,
  amount::float                                           as amount,
  upper(currency)                                         as currency,
  CASE lower(type)
    WHEN 'deposit'       THEN 'deposit'
    WHEN 'deposito'      THEN 'deposit'
    WHEN 'withdrawal'    THEN 'withdrawal'
    WHEN 'retiro'        THEN 'withdrawal'
    WHEN 'transfer'      THEN 'transfer'
    WHEN 'transferencia' THEN 'transfer'
    WHEN 'payment'       THEN 'payment'
    WHEN 'pago'          THEN 'payment'
    WHEN 'refund'        THEN 'refund'
    WHEN 'reembolso'     THEN 'refund'
    WHEN 'fee'           THEN 'fee'
    WHEN 'comision'      THEN 'fee'
    ELSE NULL
  END                                                     as type,
  lower(trim(category))                                   as category,
  initcap(trim(merchant))                                 as merchant,
  lower(trim(channel))                                    as channel,
  lower(trim(status))                                     as status,
  trim(description)                                       as description
FROM {{ source('silver', 'stg_transactions') }}