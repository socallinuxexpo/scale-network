# Openwrt Goldens

## Usage

To test the template output from whats generated using gomplate. If does this by `diff`ing
a known good generated set of files found in `./golden` with generated files in `./tmp`.

Just run:

```
sh test.sh
```

If it returns a diff then the goldens dont match the current output. If this is intended
due to other code changes then you can run the same script with `-u` to update the goldens.

```
sh test.sh -u
```

> **NOTE:** This all needs to be done from the scripts current directory

There is also the ability to target the architecture `ar71xx`(default) and `ipq806x`:

```
sh test.sh -t ipq806x -u
```
