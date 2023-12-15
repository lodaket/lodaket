#!/usr/bin/env fish
# change_resurrect_session.fish
#
# desc: allows a user to change the 'last' link used by tmux resurrect to
# a resurrect session file of the user's choice.
# 
# ref: https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_previously_saved_environment.md
# uses the gum program, https://github.com/charmbracelet/gum, for some TUI action
#

# config
set resurrect_directory ~/.local/share/tmux/resurrect #directory that has the
  # tmux resurrect text files, usually ~/.local/share/tmux/ressurect.
set numsess 15 # number of latest sessions to show


# run it
clear

if not test -d $resurrect_directory # -d "Returns true if FILE is a directory."
  echo "Resurrect directory \""$resurrect_directory"\" not found" >&2
  return 2
end

# get the latest $numsess sessions from the resurrect directory
set sessions ( \
  command ls -tlgGL $resurrect_directory | \
  command grep 'tmux_resurrect_.*\.txt$' | \
  command head -n $numsess | \
  command awk '{$1="";$2="";print $0}' \
  ) # I'm sure there is an efficient way to do this, but this works.

set selected (gum choose --limit 1 --height=15 --header=\
  "Select a session to use, you will be shown it and prompted to use after" \
  $sessions
)

# gum allows you to select the header which is strange, but nice for
# canceling the selection
if string match --regex "^Select a session to use," $selected > /dev/null
  echo session not selected, canceling...
  return 0
end

set session $(echo $selected | awk '{print $5}') # get the filename

if test -z $session # check if session variable has a value, -z "Returns true 
  # if the length of STRING is zero."
  # this should never hit
  echo "not using an empty session" >&2
  return 2
else if not test -e $resurrect_directory/$session # -e "Returns true if FILE exists."
  # this should never hit
  echo "session file does not exist." >&2
  return 3
end

set session_path $resurrect_directory/$session
set last_link_path $resurrect_directory"/last"

clear
if test -e $last_link_path
  gum pager < $session_path
  echo -e "remove session link and point to:\n $session_path?\n\n"
  if gum confirm "Do it!"
    rm $last_link_path
    ln -s $session_path $last_link_path 
  else
    echo not changing session, exiting...
    return 0
  end
else
  # we could just ignore the link not existing, but might as well be safe.
  echo "last link file is not in the resurrect path. Something's wrong." >&2
  echo "Manually create a file $last_link_path, and run again" >&2
  return 4
end  

return 0