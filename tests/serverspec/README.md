# Serverspec

Used to validate a linux host after its been provisioned

## Prereqs

To run `serverspec` the following is required:

* [rbenv](https://github.com/rbenv/rbenv)
* bundle

Install the correct version of ruby:

```
cd test/serverspec
rbenv install $(cat .ruby-version)
```

Install the dependencies and `serverspec` into `rbenv`:

```
bundle install
rbenv rehash
```

## Openwrt

Example of running `serverspec` on an AP@192.168.254.100:
```
rake spec TEST_TYPE=openwrt TARGET_HOST=192.168.254.100
```

Run openwrt show specific tests
```
rake spec TEST_TYPE=openwrt_show TARGET_HOST=192.168.254.100
```

## Servers

Example of running `serverspec` on a VM with role=core:

```
rake spec TEST_TYPE=core TARGET_HOST=10.0.3.5
```

## Overriding remote bundle

To reference a repo thats already on the machine:

```
git clone https://github.com/net-ssh/net-ssh.git
bundle config --local local.net-ssh ./net-ssh
bundle config --local disable_local_branch_check true
```
