import time
from raven import Client
client  = Client(dsn="http://5030659c0a8948b8aad226cd8241e701:3b2feac77d674a3e8f094767720711d8@192.168.20.2:9000/1")

try:
    1/0
except:
    ident = client.get_ident(client.captureException())
    print ident
    time.sleep(1)
