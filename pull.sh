#!/bin/bash -

here=$(dirname $0)
repos=$(sed -e 's|#.*$||' < $here/repos)

for repo in $repos ; do
	if [ -e $here/$repo/.git/config ] ; then
		bare="$(git -C $here/$repo config core.bare 2>/dev/null || echo default)"
		if [ $bare != true ] ; then
			echo ""
			echo "Repository: $repo"
			git -C $here/$repo pull --ff-only
		fi
	fi
done
