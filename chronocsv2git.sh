#!/bin/bash

# This script complements git-timemachine by processing a CSV containing the
# following format
# * note1: headerless CSV
# * note2: TAB, not comma delimited. 
#   * Originally comma, now call it "character"
#   * Normally I avoid tabs, but this is a one-off file. The format can be a little weird
# 
# src_filename	tgt_filename	commit message(which may be\n\n"complex"))
# 
# The commit message itself is interpreted through `echo -e` thus while it's
# a single line in the CSV, it can output to multiple lines. Note the
# double-escape though:
# filename_v1	filename	first "version"\\n\\nthis is seriously old. Quotes ok.
#
# The benefit of all this is that preparing the csv then running this script
# should be easier than preparing a custom import2git.sh as per example at
# https://github.com/nemothorx/indexpage/commit/0ca47029637fc5ec21c20a6c46765169f71a4f02
#
# The actual purpose is for importing into git a collection of
# found-from-backups (or similar) old versions of a single script which have
# been given ad-hoc names but have era-accurate timestamps. Eg:
# -rw-r--r-- 1 nemo 3.3K Sep 20  2003 runranplay_1.0
# -rw-r--r-- 1 nemo 3.5K Sep 30  2003 runranplay_1.0_
# -rw-r--r-- 1 nemo 5.4K Jul 14  2004 runranplay_1.2_Myk
# -rw-r--r-- 1 nemo 4.6K Mar 22  2005 runranplay_1.2
# -rw-r--r-- 1 nemo 4.6K Jul 11  2005 runranplay_1.2_
# -rw-r--r-- 1 nemo 7.4K Oct 16  2012 runranplay_1.9
# -rw-r--r-- 1 nemo 7.6K Jun 13  2020 runranplay_1.10
# -rw-r--r-- 1 nemo 7.6K Mar 30  2021 runranplay_1.10_
# -rw-r--r-- 1 nemo 7.7K Sep  9  2021 runranplay_1.11
# -rw-r--r-- 1 nemo 7.7K Apr 24 18:14 runranplay_1.11_

# HOW IT WORKS
# The script will process chrono.csv line by line, cp -a each source_filename
# to the target_filename, then git-timemachine that to set timing, then git add
# and commit it. 
# 
# WHAT IT DOES NOT DO
# * does not create the git repo itself
# * nor does it do any complex branching, merging, etc.
#   * ie, it's intended for a catchup of a single file from historic archives
#     into git, whilst maintaining date metadata. Nothing more. 

############################################ MAIN

csvfile=chrono.csv    # Taking no alternatives at this time

if [ ! -e $csvfile ] ; then
    echo "! no csvfile found (expecting $csvfile))
Exiting with nothing to do"
    exit 1
fi

if [ ! -d ".git" ] ; then
    echo "! Not yet a git repo. I dont do that step. please fix (git initmain ?)"
    exit 2
fi

IFS="	"       # tab only


#### pass 1:  sanity check csvfile
# ensure all col1 exist as files
# and all col3 are non-zero

while read srcfile tgtfile msg ; do
    [ ! -e "$srcfile" ] && echo "! no $srcfile found. Fix $csvfile" && exit 3
    [ -e "$tgtfile" ] && echo "! $tgtfile already exists. Refusing to blat it with $srcfile. pls fix" && exit 4
    [ ! -n "$msg" ] && echo "! no msg for $srcfile. Fix $csvfile" && exit 5
done < <(cat $csvfile)

# TODO: validate $msg to be suitable for "$msg" in git commandline. ie, no '"'??

#### preparation: capture state of everything right now. 
[ -e README.md ] && echo "! README.md already exists. I wont overwrite it. Fix." && exit 5
echo "
This commit of this repo was generated by chronocsv2git.sh (part of
git-timemachine) with data from $csvfile

Detailed ls of source files is as follows:
" >> README.md
ls -rot --full-time * >> README.md

git add $csvfile
git add README.md
git commit -a -m "chronocsv2git begin: adding README.md and chrono.csv"


#### pass 2: do the git-thing

while read srcfile tgtfile msg ; do
    cp -av $srcfile $tgtfile 
    eval $(git timemachine $tgtfile)
    git add $tgtfile
    git commit -a -m "$(echo -e ${msg})"
done < <(cat $csvfile)

echo ""
echo ""
echo "Manual cleanup:
* review git logs, and if satisfied, remove untracked original source files
* git rm $csvfile"
echo ""
echo "All done. Bye bye."
