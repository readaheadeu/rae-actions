#
# Publish a Release on GitHub
#
# Read a `NEWS.md` file from the current directory and try to extract
# the release-notes for the specified release. Then use `gh` to publish
# a release on GitHub with those release-notes.
#

import subprocess
import sys

title = sys.argv[1]     # Project title to use for the release
repo = sys.argv[2]      # GitHub repo slug (`owner/repo`)
tag = sys.argv[3]       # Git tag of the release
version = sys.argv[4]   # Version number of the release

#
# Extract the release notes from `NEWS.md`.
#

with open('NEWS.md', 'r') as f:
    content = f.read()

sections = content.split("\n## CHANGES WITH ")
header = sections[0].splitlines()[0]
releases = sections[1:]

notes = dict(map(lambda v: (v[:v.find(":")], v), releases))
notes = notes[version].strip()

relnotes = f"    {header}\n\n    ## CHANGES WITH {notes}"

#
# Run `gh release create [...]` to publish the release.
#

args = [
    "gh",
    "release",
    "--repo", repo,
    "create",
    "--verify-tag",
    "--title", f"{title}-{version}",
    "--notes-file", "-",
    tag,
]

subprocess.run(args, check=True, encoding="utf-8", input=relnotes)
