#!/bin/sh -eu

# Alpine names every Lua binary and every Lua package after the major.minor
# version, so lua5.5 installs /usr/bin/lua5.5 and /usr/bin/luac5.5, and an
# add-on such as busted is packaged separately for each.
#
# Which version that is gets resolved from the index at build time rather than
# written down here, so a rebuild picks up a new stable Lua by itself. Writing
# it down would pin the image to whichever release was current when someone
# last edited this file. Alpine's index carries released versions only, so the
# highest lua<major>.<minor> package in it is the newest stable Lua. The sort
# is a version sort rather than a plain one, so that a future 5.10 comes after
# 5.9 instead of before it.
apk update

# grep is busybox here and takes -E only, unlike the sort and sed below, which
# alpine's coreutils supplies with their long forms.
readonly LUA_MAJOR_MINOR=$(apk search --quiet lua \
  | grep -E '^lua[0-9]+\.[0-9]+$' \
  | sort --version-sort \
  | tail --lines=1 \
  | sed 's/^lua//')

# An index with no lua in it at all means the search is wrong rather than that
# Lua has gone away, and an empty version would go on to install a package
# named "lua-", so stop here and say so.
if [ -z "${LUA_MAJOR_MINOR}" ]; then
  echo 'Found no lua<major>.<minor> package in the alpine index' >&2
  exit 1
fi

apk add "lua${LUA_MAJOR_MINOR}"

# The unversioned names a kata calls.
ln --symbolic "/usr/bin/lua${LUA_MAJOR_MINOR}"  /usr/local/bin/lua
ln --symbolic "/usr/bin/luac${LUA_MAJOR_MINOR}" /usr/local/bin/luac

# Recorded in /versions.json and read by the install.sh of images built on
# this one, so both state the version this image actually holds rather than
# one written down when someone last edited them. The interpreter is asked rather than the
# package index, so a version recorded here is one the image can run.
readonly LUA_VERSION=$(lua -v | sed --quiet 's/^Lua \([0-9][0-9.]*\).*/\1/p')
cat > /versions.json <<EOF
{
  "language": {
    "name": "Lua",
    "version": "${LUA_VERSION}"
  },
  "test_frameworks": []
}
EOF

rm -rf /var/cache/apk/*
