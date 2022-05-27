#!/bin/bash
# General shell functions

BOOTUP=color
RES_COL=75
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[0;32m"
SETCOLOR_FAILURE="echo -en \\033[0;31m"
SETCOLOR_WARNING="echo -en \\033[0;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETCOLOR_TITLE="echo -en \\033[0;35m"
SETCOLOR_BOLD="echo -en \\033[0;1m"

echo_success() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
  echo -n $"  OK  "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 0
}

echo_dontdeploy() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
  echo -n $" NO NEED TO DEPLOY "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 0
}

echo_failure() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
  echo -n $"FAILED"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 1
}

echo_passed() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
  echo -n $"PASSED"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 1
}

echo_warning() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
  echo -n $"WARNING"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 1
}

echo_title () {
  echo
  echo
  [ "$BOOTUP" = "color" ] && $SETCOLOR_TITLE
  echo "$1"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
}

check_retcode () {
    if [ $? = "0" ] ; then
        true
    else
        exit 2
    fi
}

handle_result () {
        RETVAL=$?
        if [ "$RETVAL" = "0" ] ; then
            showresult="echo_success"
            result="OK"
        fi
        if [ "$RETVAL" = "1" ] ; then
            showresult="echo_warning"
            EXITWARN="1"
            result="WARNING"
        fi
        if [ "$RETVAL" = "2" ] ; then
            showresult="echo_failure"
            EXITCRIT="1"
            result="CRITICAL"
        fi
        if [ "$RETVAL" = "99" ] ; then
            showresult="echo_dontdeploy"
            DONTDEPLOY="1"
            result="OK"
        fi
        if [ x$show == "xyes" ] ; then
            $showresult
            echo
            echo -e "$output"
            echo
        elif [ x$show == "xfail" ] && [ x$RETVAL != "x0" ] ; then
            $showresult
            echo
            echo -e "$output"
            echo
        fi

}


# Function taken from http://www.threadstates.com/articles/parsing_xml_in_bash.html
xml_parse () {
    local tag=$1
    local xml=$2

    # Find tag in the xml, convert tabs to spaces, remove leading spaces, remove the tag.
    grep $tag $xml | \
        tr '\011' '\040' | \
        sed -e 's/^[ ]*//' \
            -e 's/^<.*>\([^<].*\)<.*>$/\1/'
}

# Prompt for next step
ask_interactive () {
    if [ x$show == "xyes" ] ; then
        echo -n $title
    fi

    if [ "$interactive" = "yes" ] ; then
        echo 
        echo "INTERACTIVE MODE: Press 'x' to exit or just return to go on" 
        read press
        case $press in 
            x) exit 2 ;;
            *) return
        esac
    fi
}

# Shows or executes a command
show_command () {
   echo
   $SETCOLOR_BOLD ; echo "$HOSTNAME: $*" ; $SETCOLOR_NORMAL

   bash -c "$*"
}

# Filtering out only:  $ ; ` | < >
shell_filter () {
    echo $1 | sed 's/\$//g' | sed 's/;//g' | sed 's/`//g' | sed 's/|//g' | sed 's/<//g' | sed 's/>//g'
}

# Filtering out:  $ ; ` | < > = ! { } [ ] / \ # &
shell_filter_strict () {
    echo $1 | sed 's/\$//g' | sed 's/;//g' | sed 's/`//g' | sed 's/|//g' | sed 's/<//g' | sed 's/>//g'  | sed 's/=//g' | sed 's/!//g' | sed 's/{//g' | sed 's/}//g' | sed 's/\[//g' | sed 's/\]//g' | sed 's/\///g' | sed 's/\\//g' | sed 's/#//g' | sed 's/&//g'
}

# Yaml parse. 
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}