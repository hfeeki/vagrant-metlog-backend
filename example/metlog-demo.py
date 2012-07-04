'''
metlog demo
'''
from ConfigParser import SafeConfigParser
import argparse
from metlog.config import client_from_stream_config
import datetime
import random

parser = argparse.ArgumentParser(description="Upload JSON logs to HDFS")
parser.add_argument('--config',
        type=argparse.FileType('r'),
        required=True)

parsed_args = parser.parse_args()

cfg = SafeConfigParser()
client = client_from_stream_config(parsed_args.config, 'metlog')


def send_incr_pegs():
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

        print "Sending: %s" % k
        for i in range(random.randint(min, max)):
            client.incr("%s.%s.%s" % (k, cluster_name, host_name))


def send_error_msgs():
    print "Sending Oldstyle Err msgs"
    for i in range(100):
        msg = "this is some text from osx to aitc : %s"
        msg = msg % datetime.datetime.now()
        client.error(msg)


def send_raven_msgs():
    print "Sending Exceptions"
    for i in range(200):
        try:
            1 / 0
        except:
            client.raven('myapp.raven')

send_incr_pegs()
send_error_msgs()
send_raven_msgs()
