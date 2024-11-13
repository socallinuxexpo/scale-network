# Gitlab

See the pipelines defined: https://github.com/socallinuxexpo/scale-network/blob/master/.gitlab-ci.yml

Our [autoflash process](./openwrt/docs/AUTOFLASH.md) leverages `gitlab-runners` to be able to interact with real hardware so that
we can automate the flashing process to test our openwrt images.

## Generate token for runner

1. Navigate to the [runner page](https://gitlab.com/groups/socallinuxexpo/-/runners)

1. Click the `New Group Runner`

1. Ensure that you have the right tags for the runner. These should match the `.gitlab-ci` jobs you expect to run.

1. Add a description and set an appropriate timeout if different from the default.

1. Take the token and place it on the runner.

> NOTE: Runners cannot be configured with additional tags or config. These are encoded into the token. Should these
> config need to change you'll need a new token.
