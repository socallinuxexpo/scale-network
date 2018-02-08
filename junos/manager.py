import sys
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
@click.option('-H', '--host', help='host to connect to')
@click.option('--user', '-u', default='root',
              help='Username to log in via SSH')
@click.option('--sshkey', '-i', default=None,
              help='Full path to sshkey to use for auth')
@click.option('--config', '-c', default=None,
              help='Full path to switch config')
@click.option('--yes', '-y', default=False,
              help='Skip prompting the user')
def compare(host, user, sshkey, config, yes):
    """Simple config check"""
    try:
        password = getpass("Device password: ")
	with Device(host=host, user=username, passwd=password, ssh_private_key_file=sshkey) as dev:
	    device_config = Config(dev)
	    device_config.lock()
	    device_config.load(path=config, format="text", overwrite=True)
            log(0, 'DIFF:', 'yellow', str(device_config.diff()))
            if yes:
	      device_config.commit()
            elif question('Would you like to commit the config?\n'):
	      device_config.commit()
	    device_config.unlock()
    except Exception as err:
	print (err)
	sys.exit(1)

def question(text):
    yes = {'yes','y'}
    no = {'no','n'}

    choice = raw_input(text).lower()
    if choice in yes:
       return True
    elif choice in no:
       return False
    else:
       sys.stdout.write("Please respond with 'yes' or 'no'")
    return False

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
    cli()
