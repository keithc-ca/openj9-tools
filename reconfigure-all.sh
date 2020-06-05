#!/bin/bash -

here=$(dirname $0)
repos=$(sed -n -e 's|#.*$||' -e '/jdk/p' < $here/repos)

for repo in $repos ; do
	if [ -e $here/$repo/.git/config ] ; then
		echo ""
		echo "Repository: $repo"

		spec=$(echo $here/$repo/build/*/spec.gmk)
		if [ -f "$spec" ] ; then
			# Look for this line in $spec:
			# using 'configure ...'
			configuration=$(sed -n -e "s|# using '\(configure [^']*\)'|\1|p" < $spec)
		else
			configuration=
		fi
		if [ -n "$configuration" ] ; then
			( cd $here/$repo && bash $configuration )
		else
			echo "No existing configuration found for $repo"
		fi
	fi
done
