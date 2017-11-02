## Gitlab Check

[![Build Status](https://travis-ci.org/hyperia-sk/gitlab-check.svg?branch=master)](https://travis-ci.org/hyperia-sk/gitlab-check) [![codecov](https://codecov.io/gh/hyperia-sk/gitlab-check/branch/master/graph/badge.svg)](https://codecov.io/gh/hyperia-sk/gitlab-check)

> `gitlab-check` command line utility that uses the gitlab API to check your repository and base funcionality.

![gitlabchecker](https://user-images.githubusercontent.com/6382002/32325876-0913b9d2-bfd1-11e7-9841-bc5451311e18.png)

## Usage

```bash
gitlab-check -n "https://gitlab.foo-bar.com" -i 194 -t gI1l4bR4nD0m1Ok3nH3r3 
```

#### Parameters

```bash
gitlab-check [ -n | -i | -t | -h ]

-n <ip|hostname>
Name of the host or IP address.

-i <number>
Project ID.
See: "Project" -> "General Settings" -> "Expand: General project settings"

-t
Personal access tokens. 
See: "User Settings" -> "Access Tokens"

-h
Prints this help.
```

## Installation

```bash
git clone https://github.com/hyperia-sk/gitlab-check.git && cd gitlab-check
```

Open up the cloned directory and run:

#### Unix like OS

```bash
sudo make install
```

For uninstalling

```bash
sudo make uninstall
```

For update/reinstall

```bash
sudo make reinstall
```

#### OS X (homebrew)

@todo

#### Windows (cygwin)

@todo


## System requirements

* Unix like OS with a proper shell
* Tools we use: basename ; mktemp ; tee ; tail ; seq ; awk ; tr ; printf ; curl ; wget ; jq ; git

`sudo apt install git jq wget curl`

## Contribution 

Want to contribute? Great! First, read this page.

#### Code reviews

All submissions, including submissions by project members, require review. 
We use Github pull requests for this purpose.

#### Some tips for good pull requests:
* Use our code
  When in doubt, try to stay true to the existing code of the project.
* Write a descriptive commit message. What problem are you solving and what
  are the consequences? Where and what did you test? Some good tips:
  [here](http://robots.thoughtbot.com/5-useful-tips-for-a-better-commit-message)
  and [here](https://www.kernel.org/doc/Documentation/SubmittingPatches).
* If your PR consists of multiple commits which are successive improvements /
  fixes to your first commit, consider squashing them into a single commit
  (`git rebase -i`) such that your PR is a single commit on top of the current
  HEAD. This make reviewing the code so much easier, and our history more
  readable.

#### Formatting

This documentation is written using standard [markdown syntax](https://help.github.com/articles/markdown-basics/). Please submit your changes using the same syntax.

#### Tests

```bash
make test
```

## Licensing
MIT see [LICENSE][] for the full license text.

   [read this page]: https://github.com/hyperia-sk/gitlab-check/blob/master/CONTRIBUTING.md
   [landing page]: https://github.com/hyperia-sk/gitlab-check
   [LICENSE]: https://github.com/hyperia-sk/gitlab-check/blob/master/LICENSE


