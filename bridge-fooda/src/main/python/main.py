from requests.exceptions import JSONDecodeError
from woocommerce import API

wcapi = API(
    url="http://localhost:8888",
    consumer_key="ck_b969666524ce65b909b7cb9c3b3598f49a613ef8",
    consumer_secret="cs_bb15fb7a9b1a84d69c1ae864588985aa2df66f68",
    wp_api=False,
    version="wc/v3",
    query_string_auth=True
)

dj = wcapi.get("")

try: 
    print(dj.json())
except JSONDecodeError as jerr:
    print(jerr)

