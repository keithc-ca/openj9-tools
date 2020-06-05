#!/bin/bash -

here=$(dirname $0)
repos=$(sed -e 's|#.*$||' < $here/repos)

for repo in $repos ; do
	if [ -e $here/$repo/.git/config -o -e $here/$repo/config ] ; then
		echo ""
		echo "Repository: $repo"
		git -C $here/$repo gc
	fi
done
