#!/bin/bash
set -euo pipefail


#-----------------------------------------------------------------------------------------------------------
grey='\x1b[38;05;240m'
blue='\x1b[38;05;27m'
lime='\x1b[38;05;118m'
orange='\x1b[38;05;208m'
red='\x1b[38;05;124m'
reset='\x1b[0m'
function info    () { set +u;  printf "$grey""PSPG INSTALLER ""$blue%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function help    () { set +u;  printf "$grey""PSPG INSTALLER ""$lime%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function urge    () { set +u;  printf "$grey""PSPG INSTALLER ""$orange%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function warn    () { set +u;  printf "$grey""PSPG INSTALLER ""$red%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }
function whisper () { set +u;  printf "$grey""PSPG INSTALLER ""$grey%s$reset\n" "$1 $2 $3 $4 $5 $6"; set -u; }

#-----------------------------------------------------------------------------------------------------------
# if [ -z "${1+x}" ]; then
#   urge "usage:"
#   urge "$0 path/to/sqlite-amalgamation"
#   # exit 1
#   fi

#-----------------------------------------------------------------------------------------------------------
pspglink_path='./pspg'
pspgbin_path='./pspg-binary'
pspgbinexec_path="$pspgbin_path/pspg"
pspgbin_url='https://github.com/okbob/pspg.git'


#-----------------------------------------------------------------------------------------------------------
function procure_package {
  path="$1"
  url="$2"
  if [ -d "$path" ]; then
    help "exists: $path"
    warn "updating from $url"
    ( cd "$path" && git pull origin master )
  else
    warn "missing: $path"
    warn "retrieving $url"
    git clone "$url" "$path"
    fi
  }

#-----------------------------------------------------------------------------------------------------------
function build_pspg_binary {
  help "building pspg binary"
  cd "$pspgbin_path"; whisper "cd $(pwd)"
  ./configure
  make
  cd "$home"; whisper "cd $(pwd)"
  }

#-----------------------------------------------------------------------------------------------------------
function link_pspg_binary {
  # cd "$home"; whisper "cd $(pwd)"
  path="$pspgbinexec_path"
  help "creating symlink to $pspgbinexec_path"
  path="$(realpath $path)"
  if [ -e "$pspglink_path" ]; then
    help "exists: $path"
    if [ -L "$pspglink_path" ]; then
      help "$pspglink_path --> $(readlink $pspglink_path)"
    else
      warn "$pspglink_path is not a symlink"
      exit 1
      fi
  else
    ln -s "$(realpath --relative-to=. "$path")" "$pspglink_path"
    fi
  }

