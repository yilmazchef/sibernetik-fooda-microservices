from requests.exceptions import JSONDecodeError
from woocommerce import API

wcapi = API(
    url="http://localhost",
    consumer_key="ck_c265593a771c48e0efc26803b3ce33ee87185cb6",
    consumer_secret="cs_120d54a1f2b765d5a3072872347de07726ec516f",
    wp_api=True,
    version="wc/v3",
    query_string_auth=True
)

dj = wcapi.get("")

try: 
    print(dj.json())
except JSONDecodeError as jerr:
    print(jerr)

