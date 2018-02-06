import sys
import ipdb
from getpass import getpass
from jnpr.junos import Device
from jnpr.junos.utils.config import Config
import click

CONTEXT_SETTINGS = dict(help_option_names=['-h', '--help'])
VERBOSE = 0


@click.group(context_settings=CONTEXT_SETTINGS)
@click.option('-v', '--verbose', count=True)
def cli(verbose):
    global VERBOSE
    VERBOSE = verbose

@cli.command()
@click.option('--host', '-H', help='host to connect to')
@click.option('--user', '-u', default='root',
              help='Username to log in via SSH')
def compare(host, user):
    """Simple config check"""
    try:
        password = getpass("Device password: ")
	with Device(host=host, user=username, passwd=password) as dev:
	    config = Config(dev)
	    config.lock()
	    config.load(path='./test.conf', format="text", overwrite=True)
	    #config.commit()
	    #print(config.diff())
            log(0, 'DIFF:', 'yellow', str(config.diff()))
	    ipdb.set_trace()
	    config.unlock()
    except Exception as err:
	print (err)
	sys.exit(1)

def warn(msg, indent=0):
    log(0, '{}DRY-RUN:'.format(' ' * indent), 'yellow', msg)


def error(msg, indent=0):
    log(-1, '{}ERROR:'.format(' ' * indent), 'red', msg)


def info(msg, indent=0):
    log(1, '{}INFO:'.format(' ' * indent), 'green', msg)

def log(level, prefix, prefix_color, msg):
    '''Spit out logging messages to the console

    :param level: emit only if VERBOSE >= level
    :param prefix: What to prefix the log msg with
    :param prefix_color: Color for the prefix
    :param msg: The log message
    '''

    if VERBOSE < level:
        return
    if not isinstance(msg, str):
        msg = pprint.pformat(msg)
    click.echo(click.style(prefix, fg=prefix_color, bold=True) + ' %s' % msg)


if __name__ == '__main__':
    username = 'root'
    #compare_config()
    cli()
