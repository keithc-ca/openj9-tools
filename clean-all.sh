#!/bin/bash -

# we want an empty list if there's no match
shopt -s nullglob

here=$(dirname $0)
repos=$(sed -n -e 's|#.*$||' -e 's|\t| |g' -e 's|^  *||' -e '/^jdk/p' < $here/repos)

for repo in $repos ; do
	if [ -e $here/$repo/.git/config ] ; then
		echo ""
		echo "Repository: $repo"

		specs=0
		for spec in $here/$repo/build/*/spec.gmk ; do
			# Look for this line in spec.gmk:
			# using 'configure ...'
			configuration=$(sed -n -e "s|# using '\(configure [^']*\)'|\1|p" < $spec)
			if [ -z "$configuration" ] ; then
				echo "No configuration found in $spec"
			else
				( cd $(dirname $spec) && echo "Cleaning $PWD . . ." && make CONF_CHECK= clean )
			fi
			specs=1
		done
		if [ $specs -eq 0 ] ; then
			echo "No build configurations found for $repo"
		fi
	fi
done
