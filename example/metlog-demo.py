'''
metlog demo
'''
import datetime
import random
import time
from metlog.config import client_from_text_config

cfg_txt = """[metlog]
sender_class = metlog.senders.ZmqPubSender
sender_bindstrs = tcp://192.168.20.2:5565

[metlog_plugin_raven]
provider=metlog_raven.raven_plugin:config_plugin
sentry_project_id=2
"""
client = client_from_text_config(cfg_txt, 'metlog')


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

def send_error_msgs():
    while True:
        for i in range(100):
            msg = "this is some text from osx to aitc : %s"
            msg = msg % datetime.datetime.now()
            client.error(msg)
        time.sleep(1)
        print "Slept: %s" % datetime.datetime.now()


def send_raven_msgs():
    try:
        1 / 0
    except:
        client.raven('myapp')

send_raven_msgs()
