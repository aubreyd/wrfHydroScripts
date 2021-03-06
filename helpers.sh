#!/bin/bash

## Remember in bash: TRUE=0, FALSE=1, unless you're using (( ))

function checkExist {
    # arg 1: the thing to test for existence
    # arg 2: OPTIONAL, additional text to echo
    if [ ! -e $1 ]; then 
        echo -e "\e[31m${1} does not exist.\e[0m" 
        if [ ! -z $2 ]; then echo -e "$2"; fi
        return 1
    else 
        return 0
    fi
}


function notCommented {
    noBlank=`echo $1 | tr -d ' '`
    if [[ $noBlank == !* ]]; then return 1; else return 0; fi
}


function getAbsPath {
    ## usage: file=`getAbsPath $file`
    if [[ ! "$1" = /* ]]; then echo `pwd`/$1; else echo $1; fi; return 0;
}


function checkBinary {
    theBinary=$1
    message="$2"
    if [[ -z $theBinary ]]; then echo -e "\e[31mNo binary supplied, returning.\e[0m"; return 1; fi
    if [[ ! -e $theBinary ]] 
    then
        echo -e "\e[31mBinary does not exist:\e[0m $theBinary"
        if [[ ! -z "$message" ]]; then echo -e "$message"; fi
        return 1
    fi
    checkBinary=`ldd $theBinary`
    if [ ! $? -eq 0 ] 
    then
        echo -e "\e[31mProblems with executable:\e[0m $theBinary"
        if [[ ! -z "$message" ]]; then echo -e "$message"; fi
        return 1
    fi
    return 0
}


function getMenu {
    if [ -z $1 ]; then echo -e "\e[31mgetMenu requires its first arg to be a config file.\e[0m"; fi
    if [ -z "$2" ]; then echo -e "\e[31mgetMenu requires its second arg to be a menu name.\e[0m"; fi
    if [ -z $1 ] | [ -z "$2" ]; then return 1; fi
    configFile=$1
    menuName=$2
    checkExist $configFile || return 1
    whMenu=(`grep -n "$menuName" $configFile | cut -d ':' -f1`)
    nMenu="${#whMenu[@]}"
    if [[ $nMenu -ne 2 ]]; then 
        if [[ $nMenu -eq 0 ]]; then 
            echo -e "\e[31mmenu name was not found in config file: $configFile\e[0m"
        else
            echo -e "\e[31mMalformed menu (\"$menuName\") in config file: $configFile\e[0m"
        fi
        return 1
    fi
    nItems=$((${whMenu[1]}-${whMenu[0]}-1))
    head -$((${whMenu[1]}-1)) $configFile | tail -${nItems}
    return 0
}


function isInSet {
    # usage: 
    # fruit='orange bannana apple'
    # isMember [grep options] apple "$fruit"
    # Same exact options as grep, mostly focused on -i for case matching.
    nArgs=$#
    set="${@:$nArgs}"
    opts="${@:1:$(($nArgs-2))}"
    member="${@:$(($nArgs-1)):1}"
    #echo set: "$set"
    #echo opts: "$opts"
    #echo member?: "$member"
    set=`echo "$set" | tr ' ' '\n'`
    setSize=`echo "$set" | wc -l`
    if [[ $setSize -le 1 ]] 
    then
        echo "The passed set only has one member, you likely forgot the double quotes on the set variable"
        return 1
    fi
    for ss in $set
    do
        if [ -z $opts ] 
        then
            result=`echo $ss | grep "^$member$"`
        else 
            result=`echo $ss | grep "$opts" "^$member$"`
        fi
        if [ ! -z "$result" ]; then return 0; fi
    done
    return 1
}


round() {
    # $1 is expression to round (should be a valid bc expression)
    # $2 is number of decimal figures (optional). Defaults to three if none given
    [ !  -z $1 ] || return 1
    local df=${2:-0}
    printf '%.*f\n' "$df" "$(bc -l <<< "a=$1; if(a>0) a+=5/10^($df+1) else if (a<0) a-=5/10^($df+1); scale=$df; a/1")"
    return 0
}

ceiling() {
    # $1 is expression to ceiling (should be a valid bc expression)
    [ !  -z $1 ] || return 1
    in=$1
    inRound=`round $in`
    isInteger=`echo "$in == $inRound" | bc`
    isNegative=`echo "$in < 0.0" | bc`
    ## the result here is opposite the bash convention
    if [[ $isInteger -eq 1 ]] || [[ $isNegative -eq 1 ]] 
    then 
        echo $inRound
    else 
        echo $((${inRound}+1)) 
    fi
    return 0
}

