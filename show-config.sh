#!/bin/bash -

show_spec() {
  sed -n -e 's/^ *CONFIGURE_COMMAND_LINE *:= *//p'
}

if [ -f spec.gmk ] ; then
  show_spec < spec.gmk
else
  specs=( )
  pattern="${1:-.}"
  for config in $(cd build 2>/dev/null && echo *) ; do
    spec="build/$config/spec.gmk"
    if [ -f "$spec" ] && echo "$config" | grep -q "$pattern" ; then
      specs+=( "$spec" )
    fi
  done

  if [ ${#specs[@]} -eq 0 ] ; then
    echo "No matching configurations found."
  elif [ ${#specs[@]} -eq 1 ] ; then
    show_spec < "${specs[@]}"
  else
    for spec in "${specs[@]}" ; do
      printf "%s\n  " "$spec:"
      show_spec < "$spec"
    done
  fi
fi
