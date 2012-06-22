import time
from raven import Client
client  = Client(dsn="http://2cfcac6f616e4a90b20f4aed9f0e40dc:9a813d742a51426c9285e8222c2a65b7@192.168.20.2:9000/2")

try:
    1/0
except:
    ident = client.get_ident(client.captureException())
    print ident
    time.sleep(1)
