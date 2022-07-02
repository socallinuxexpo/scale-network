# Contributing

## Overview
SCALE happens once a year but the team has ongoing projects and prep year round.
If you are interesting in volunteering please request to join our mailing list:
https://lists.linuxfests.org/cgi-bin/mailman/listinfo/tech

## Git

This repository leverages a workflow for committing code called [Github Flow](https://guides.github.com/introduction/flow/).
Below briefly explains how to create a `feature` branch and put in a pull request
to add fixes and features to the code base.

This workflow was chosen for its simplicity and the fact that anything merged to
`master` should be deployable. Github Flow allows developers have the freedom to
work on changes in `feature` branches without effecting what's deployable, other
team members work, or removing commit history. For more documentation on Github
Flow see: https://guides.github.com/introduction/flow/


### The Flow
0. Clone down this repo:
   ```
   git clone git@github.com:socallinuxexpo/scale-network.git
   ```

1. Create a `feature` branch from the repository. Make this branch name related to the
   work being done. The following example makes a `feature` branch for adding
   `coolscript.sh` to the repo:
   ```bash
   cd scale-network
   git checkout -b adding_coolscript
   ```

2. On this new branch go ahead and create, edit, rename, move, or delete files.
   For example lets create, add and commit `coolscript.sh` to the repo:
   ```bash
   cat << EOF > coolscript.sh
   #!/bin/sh
   echo "This script is so cool"
   EOF
   git add coolscript.sh
   git commit -m "Adding coolscript"
   ```

3. Push up this new branch up to Github:
   ```bash
   git push origin adding_coolscript
   ```
   > Note: This assumes write access to branches other than master
   > in the scale-network branch. Reach out to a team member via the
   > [mailing list](https://lists.linuxfests.org/cgi-bin/mailman/listinfo/tech)
   > for access.

4. Create a pull request the `feature` branch against `master` with the proposed
   changes to kick off a discussion. Make sure to fill out the PR template with
   as much information as possible regarding the changes. The pull request can be
   titled with either the `[WAIT]` or `[READY]` flag. PRs with `[WAIT]` signify that
   the author does not yet wish for the PR to be approved as further modifications
   and conversation are expected. Any PR with the title omitting either `[WAIT]` or
   `[READY]` should be assumed to be `[READY]`.

5. If further changes are needed before the pull request is merged repeat steps #2
   and #3. Your existing pull request will update automatically!

6. Any PR in `[WAIT]` will be held at this state until the author is ready for a merge.
   Once ready the title should be editted to reflect `[READY]`.

7. Once in `[READY]` another SCALE Tech member will review the PR. The reviewer should
   ensure that the changes being proposed conform to the spirit of the existing efforts
   and do their best to test any changes manually to ensure accuracy. The reviewer should
   also verify that all CI checks are passing at this time. No PR with failing
   test should ever be approved under normal circumstances.

8. The approving reviewer should then merge the PR, ensuring all CI checks are passing
   against `master`.

9. Once your branch is merged, sit back and pat yourself on the back for
   improving the repo! Now go back to the `master` branch which is the default branch and
   get the changes that were merged with your `feature` branch:
   ```bash
   git checkout master
   git pull --rebase origin master
   git log  # Check to make sure the merge exists
   ```

10. Go back to step #1 and add more fix and/or features to the repo!

### Common Scenarios

* **Q:** When working on a `feature` branch for a while and it needs to get the
         latest changes that have been merged against `master`. How is that done?

  **A:** _That's easy! First make sure the `feature` branch has everything your_
         _working on committed. Then go back to the `master` branch, `pull --rebase`_
         _to get the latest changes from the Github `master` branch, go back to_
         _the `feature` branch and rebase `master` against it. So it looks_
         _something like this:_
     ```bash
     git checkout master
     git pull --rebase origin master
     git checkout <feature_branch>
     git rebase master
     ```
* **Q:** How can I checkout an existing remote branch on another machine?

  **A:** _From the machine that didn't originate the branch,_
         _fetch the branches from the existing remote and checkout_
         _that branch exclusively on the local machine:_
     ```bash
     git fetch origin
     git checkout -b <new_branch_name> origin/<remote_branch_name>
     ```
* **Q:** How do I update my local branch with its corresponding remote branch?

  **A:** _Always make sure your `rebase` when updating. Disregard the cli's_
         _suggestions since that aren't helpful here. Instead:_
     ```bash
     git pull --rebase origin <feature_branch>:<feature_branch>
     ```
