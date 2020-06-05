#!/bin/bash -

show_spec() {
  sed -n -e 's/^ *CONFIGURE_COMMAND_LINE *:= *//p'
}

specs=( build/*/spec.gmk )

if [ ${#specs[@]} -gt 1 -o -f "$specs" ] ; then
  :
elif [ -f spec.gmk ] ; then
  specs=( spec.gmk )
else
  echo "No existing configuration found"
  specs=( )
fi

if [ ${#specs[@]} -eq 1 ] ; then
  show_spec < "${specs[@]}"
else
  for spec in "${specs[@]}" ; do
    printf "%s\n  " "$spec:"
    show_spec < "$spec"
  done
fi
