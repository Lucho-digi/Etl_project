loans -> status, A lot of missing values 
Accounts -> status, some values on spanish
accounts -> account_type, some values need to be trimed
transactions -> status, need to be lowercased. some values are CAPS
transactions -> channel, i see no problems at all
transactions -> type, caps and spanish
checks on all id's using REGEX
    tests -> account_id format ACC-[A-F0-9]{12}
    tests -> transaction_id format TXN-[A-F0-9]{12}
    tests -> customer_id format CUST-[0-9]{7}
    tests -> branch_code format BR-[0-9]{3}
customers -> names trimmed + initcap
customers -> email validated by regex, invalid set to null
customers -> gender/country/kyc_status/customer_segment/status normalized (lower/upper/initcap)
customers -> status values mapped from spanish to english (activo/inactivo/suspendido/cerrado)
accounts -> currency upper, numeric fields cast to float/int
accounts -> status mapped from spanish to english (activo/cerrado/congelado)
accounts -> branch_code trimmed
transactions -> type mapped from spanish to english (deposito/retiro/transferencia/pago/reembolso/comision)
transactions -> category/channel/status lower + trimmed
transactions -> merchant initcap
loans -> currency upper + numeric fields cast
loans -> status lower + trimmed, collateral_type trimmed
credit_info -> numeric fields cast + boolean flag
digital_engagement -> boolean fields, last_login_date kept as text
tests -> credit_limit >= 0, interest_rate >= 0
tests -> risk_score between 0 and 100
loans -> tpye lot of missing values
loans -> currency a lot of missing values
loans -> status, missing values
