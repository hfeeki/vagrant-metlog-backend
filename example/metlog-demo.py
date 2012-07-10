'''
metlog demo
'''
from ConfigParser import SafeConfigParser
import argparse
from metlog.config import client_from_stream_config
import datetime
import time

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

        print "Sending: %s" % k
        for i in range(50):
            client.incr("%s.%s.%s" % (k, cluster_name, host_name))
            print "incr %s" % k
            time.sleep(0)


def send_error_msgs():
    print "Sending Oldstyle Err msgs"
    for i in range(20):
        msg = "this is some text from osx to aitc : %s"
        msg = msg % datetime.datetime.now()
        client.error(msg)
        print "error %s" % msg
        time.sleep(0)


def send_raven_msgs():
    print "Sending Exceptions"
    for i in range(20):
        try:
            1 / 0
        except:
            # Note that the config.ini has *overridden* the default
            # exception method with a raven implementation
            client.exception(msg="Something really went wrong")
        print "raven exception sent"
        time.sleep(0)


def send_cef_logs():
    print "Sending CEF messages"

    cef_environ = {'REMOTE_ADDR': '127.0.0.1', 'HTTP_HOST': '127.0.0.1',
                    'PATH_INFO': '/', 'REQUEST_METHOD': 'GET',
                    'HTTP_USER_AGENT': 'MySuperBrowser'}

    cef_config = {'cef.version': '0', 'cef.vendor': 'mozilla',
            'cef.device_version': '3', 'cef.product': 'weave',
            'cef': True}

    def send_cef(name, severity, *args, **kwargs):
        client.cef(name, severity, cef_environ, cef_config)

    for i in range(20):
        send_cef('xx|x', 5)
        send_cef('xxx', 5, **{'ba': 1})
        send_cef('xx|x', 5, username='me')


def send_unexpected_data():
    print "Sending new unknown type data"
    for i in range(100):
        client.metlog(type='a_new_type', logger='some_new_app',
                payload='blah blah blah')


def send_psutil_data():
    print "Sending psutil data"
    for i in range(100):
        client.procinfo(net=True, cpu=True, mem=True,
                threads=True, busy=True)


def main():
    send_incr_pegs()
    send_error_msgs()
    send_raven_msgs()
    send_cef_logs()
    send_unexpected_data()
    send_psutil_data()


if __name__ == '__main__':
    main()
