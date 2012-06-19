'''
metlog demo
'''
import datetime
from metlog.holder import get_client
import random
import time

cfg = {'sender': {'class': 'metlog.senders.zmq.ZmqPubSender',
    #'bindstrs': 'tcp://aitc1.web.mtv1.dev.svc.mozilla.com:5565'}}
    'bindstrs': 'tcp://192.168.20.2:5565'}}


client = get_client('myapp', cfg)


def test_incr_pegs():
    """
    Just a check for increment counts
    """
    cluster_name = 'colo1'
    host_name = 'mozhost2'
    for k in ['syncstorage.request_rate.200',
            'syncstorage.request_rate.302',
            'syncstorage.request_rate.401',
            'syncstorage.request_rate.404',
            'syncstorage.request_rate.503']:

        min = random.randint(10, 200)
        max = random.randint(min, min + 500)

        for i in range(random.randint(min, max)):
            client.incr("%s.%s.%s" % (k, cluster_name, host_name))
    print "Sleeping 1 : %s" % datetime.datetime.now()
    time.sleep(1)


def test_exceptions():
    '''
    Exceptions should get routed to
    '''
    pass


#test_incr_pegs()

while True:
    for i in range(100):
        msg = "this is some text from osx to aitc : %s"
        msg = msg % datetime.datetime.now()
        client.error(msg)
    time.sleep(1)
    print "Slept: %s" % datetime.datetime.now()
