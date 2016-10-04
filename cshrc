if ( -f /usr/local/lib/cshrc.local )  then
	source /usr/local/lib/cshrc.local
endif

# @(#)Cshrc 1.6 91/09/05 SMI
#################################################################
#
#         .cshrc file
#
#         initial setup file for both interactive and noninteractive
#         C-Shells
#
#################################################################

# This is a kludge to get some scripts to work.
# If startMiriad = 0, then do not start miriad
# This can be overriden on the command line with:
# source .cshrc startMiriad=0
set startMiriad = 1

# Override user supplied parameters with command line arguments
  foreach a ( $* )
    set nargs = `echo $a | awk -F= '{print NF}'`
    set var   = `echo $a | awk -F= '{print $1}'`
    if ("$nargs" == 1) then
       echo "Error reading command line option '$a'"
       echo "Format is $a=<value>"
       exit
    endif
    set $a
  end


# Set openwin as my default window system 
set mychoice=openwin


# Path
set path = (/usr/bin/ $path /scr/carmaorion/sw/casa/bin .)

#set lcd = ( )  #  add parents of frequently used directories
#set cdpath = (.. ~ ~/bin ~/src $lcd)

# set this for all shells
set noclobber

# Other aliases
alias cp            'cp -i'
alias mv            'mv -i'
alias rm            'rm -i'
alias pwd           'echo $cwd'
umask 022

# Path
set host = `hostname`
if ($host == "hifi") then
    setenv PYTHONPATH /hifi/carmaorion/scripts:/scr/carmaorion/sw/python/lib/python2.7/site-packages
    set path = ($path /hifi/carmaorion/scripts)
else if ($host == "jansky") then
    setenv PYTHONPATH /scr2/carmaorion/scripts
    set path = ($path /scr2/carmaorion/scripts)
endif

#for python setup
setenv PATH /usr/local/EPD/epd-7.5.2/bin:${PATH}

# skip remaining setup if not an interactive shell
if ($?USER == 0 || $?prompt == 0) exit

# --- Frame labeling or not
      if ($term == xterm || $term == 'dtterm' || $term == "xterm-r5" || $term == "xterm-color") then
         set term = "xterm"
         alias chfname 'echo -n "]2;\!*"'
         alias pwdset chfname '`hostname`:$cwd'
         alias cd 'set old=$cwd; chdir \!*; set prompt="`hostname`% "; pwdset'
      else
         alias pwdset clear
         alias cd 'set old=$cwd; chdir \!*; set prompt="[`hostname`:$cwd]> "'
      endif
      cd .

# --- set the prompt
      alias back 'set back="$old"; cd "$back"; unset back'

# settings  for interactive shells
set history=40
set ignoreeof
#set notify
#set savehist=40
#set prompt="% "
#set prompt="`hostname`{`whoami`}\!: "
#set time=100

# commands for interactive shells

# OS specific commands
switch ("`uname -s`")
    case AIX:
	#commands for AIX

        breaksw
    case HP-UX
	#commands for HP-UX

   	breaksw
    case SunOS:
	#commands for all types of Sun systems

        switch ("`uname -r`")
            case 4.*:
		#commands for SunOS 4.x

                breaksw
            case 5.*:
		#commands for SunOS 5.x aka Solaris 2.x

                breaksw
        endsw
        
endsw

# --- Set cdpath
set cdpath = ( . /scr/carmaorion/ /scr2/carmaorion/ /hifi/carmaorion .. ~)

# Library path
  unsetenv LD_LIBRARY_PATH

# Miriad
if ($host == "hifi") then
   if ($startMiriad != 0) source /scr/carmaorion/sw/miriad_64/miriad_start.csh
   alias load_miriad   "source /scr/carmaorion/sw/miriad-4.3.8/miriad_start.csh"
   alias load_miriad64 "source /scr/carmaorion/sw/miriad_64/miriad_start.csh"
else
   if ($startMiriad != 0) source /scr2/carmaorion/sw/miriad_64/miriad_start.csh
   alias load_miriad   "source /scr2/carmaorion/sw/miriad-4.3.8/miriad_start.csh"
   alias load_miriad64 "source /scr2/carmaorion/sw/miriad_64/miriad_start.csh"
endif

#for KARMA
# source /usr/local/karma/.login

# Other aliases
alias edit    vi
alias xterm   'xterm -rightbar -bg black -fg white -geometry 80x30+0 -fn 10x20 &'

# Don't save bit codes
setenv PYTHONDONTWRITEBYTECODE 1
