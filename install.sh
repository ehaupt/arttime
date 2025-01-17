#!/usr/bin/env zsh
# Copyrights 2022 Aman Mehra.
# Check ./LICENSE_CODE, ./LICENSE_ART, and ./LICENSE_ADDENDUM_CFLA
# files to know the terms of license
# License files are also on github: https://github.com/poetaman/arttime

zparseopts -D -E -F - \
    l=local_arg_array \
    -local=local_arg_array \
    g=global_arg_array \
    -global=global_arg_array \
    p:=prefix_arg_array \
    -prefix:=prefix_arg_array \
    h=help_arg_array \
    -help=help_arg_array \
    || return

local_arg="$local_arg_array[-1]"
global_arg="$global_arg_array[-1]"
prefix_arg="$prefix_arg_array[-1]"
help_arg="$help_arg_array[-1]"

function printhelp {
read -r -d '' VAR <<-'EOF'
Name:
    installer for arttime

Invocation:
    ./install.sh [OPTIONS]...

Description:
    arttime is an application that runs in your terminal emulator. It blends
    beauty of text art with functionality of a feature-rich clock/timer
    /pattern-based time manager. For more information on arttime, run
    ./bin/arttime -h and visit it's github page:
    https://github.com/poetaman/arttime

Options:
    -l --local          Install arttime executables locally in ~/.local/bin
                        and art files in ~/.local/share/arttime/textart
                        Note: This is the default method used when none
                        of -l/-g/-p is provided
                        
    -g --global         Install arttime executables globally in /usr/local/bin
                        and art files in /usr/local/share/arttime/textart
                        
    -p --prefix PREFIX  Install arttime executables in PREFIX/bin
                        and art files in PREFIX/share/arttime/textart

    -h --help           Print this help string for arttime installer, and exit
EOF
echo "$VAR"
}

[[ $help_arg != "" ]] && printhelp && exit 0

count=0
[[ $prefix_arg != "" ]] && count=$((count+1))
[[ $local_arg != "" ]] && count=$((count+1))
[[ $global_arg != "" ]] && count=$((count+1))

if ((count>1)); then
    echo "Error: only one of a) -p/--prefix, b) -l/--local, or c) -g/--global should be passed."
    exit 1
elif ((count==0)); then
    local_arg="1"
fi

if [[ $local_arg != "" ]]; then
    # Install in $HOME/.local/
    installdir="$HOME/.local"
    installtype="local"
elif [[ $global_arg != "" ]]; then
    # Install in /usr/local/
    installdir="/usr/local"
    installtype="global"
else
    # Install in $prefix_arg
    installdir="$prefix_arg"
    installtype="prefix"
fi
bindir="$installdir/bin"
artdir="$installdir/share/arttime/textart"

function checkdir {
    if [[ -d $1 ]]; then
        if [[ -w $1 ]]; then
            echo "1"
        else
            echo "4"
        fi
    elif [[ -L $1 ]]; then
        if [[ -d "$(readlink $1)" ]]; then
            echo "2"
        else
            echo "5"
        fi
    elif [[ -f $1 ]]; then
        echo "6"
    else
        if /bin/mkdir -p $1 &>/dev/null; then
            echo "3"
        else
            echo "7"
        fi
    fi
}

direrrorarray=()
function printdirerror {
    if [[ $1 == "4" ]]; then
        direrrorarray+=("Error: $2 exists but is not writable directory (check permissions?)")
    elif [[ $1 == "5" ]]; then
        direrrorarray+=("Error: $2 is a symlink but does not point to a directory")
    elif [[ $1 == "6" ]]; then
        direrrorarray+=("Error: $2 exist but is a regular file, not a directory")
    elif [[ $1 == "7" ]]; then
        direrrorarray+=("Error: $2 does't exist and is not creatable directory (check permissions?)")
    fi
}

installdircode=$(checkdir $installdir)
bindircode=$(checkdir $bindir)
artdircode=$(checkdir $artdir)

printdirerror $installdircode $installdir
printdirerror $bindircode $bindir
printdirerror $artdircode $artdir

if [[ ! ${#direrrorarray[@]} -eq 0 ]]; then
    for i ("$direrrorarray[@]"); do
        printf "$i\n"
    done
    exit 1
fi

# If we are here, we can successfully install
installerdir="${0:a:h}"

# Copy bin files
cd $installerdir/bin
cp arttime $bindir/arttime
cp artprint $bindir/artprint

# Copy share files
cd $installerdir/share/arttime/textart

artfilearray=()
artfilearray=(*(.))
artfilearraysize="${#artfilearray}"
tput_cuu1=$(tput cuu1)
tput civis
for ((i = 1; i <= $artfilearraysize; i++)); do
    file="$artfilearray[i]"
    if [[ -f "$artdir/$file" ]]; then
        oldmessage='"Custom message for art goes here"'
        oldmessage="$(head -n1 $artdir/$file)"
        newart="$(tail -n +2 $file)"
        printf '%s\n' "$oldmessage" >$artdir/$file
        printf '%s\n' "$newart" >>$artdir/$file
    else
        cp $file $artdir/$file
    fi
    percentdone=$(((i-1.0)/(artfilearraysize-1.0)*100.0))
    [[ $percentdone -lt 1 ]] && percentdone="0"
    if ((percentdone<1.0)); then
        percentdone="0"
    else
        percentdone="${percentdone%.*}"
    fi
    echo "Progress: ${(l:3:: :)percentdone}% done$tput_cuu1\r"
done
# Check if path to arttime excutable is on user's $PATH
if [[ ":$PATH:" == *":$bindir:"* ]]; then
    echo "\nInstallation complete!\nRestart your terminal application, type 'arttime' and press Enter."
else
    loginshell="${SHELL}"
    loginshell=$(basename ${SHELL})
    if [[ $loginshell == *zsh* ]]; then
        echo "\n# Following line was automatically added by arttime installer" >>~/.zshrc
        echo 'export PATH='"$bindir"':$PATH' >>~/.zshrc
        echo '\nNote: Added export PATH='"$bindir"':$PATH to ~/.zshrc'
        echo "Installation complete!\nRestart your terminal application, type 'arttime' and press Enter."
    elif [[ $loginshell == *bash* ]]; then
        echo "\n# Following line was automatically added by arttime installer" >>~/.profile
        echo 'export PATH='"$bindir"':$PATH' >>~/.profile
        echo '\nNote: Added export PATH='"$bindir"':$PATH to ~/.profile'
        echo "Installation complete!\nRestart your terminal application, type 'arttime' and press Enter."
    else
        echo "\nInstallation [31m*[0malmost[31m*[0m complete! To start using arttime, follow these steps:\n    1) Add $bindir to your PATH environment variable,\n    2) Restart your terminal application, type 'arttime' and press Enter."
    fi
fi
tput cnorm
