function _wrap_build()
{
    local start_time=$(date +"%s")
    "$@"
    local ret=$?
    local end_time=$(date +"%s")
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$((($tdiff % 3600) / 60))
    local secs=$(($tdiff % 60))
    local ncolors=$(tput colors 2>/dev/null)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        color_failed=$'\E'"[0;31m"
        color_success=$'\E'"[0;32m"
        color_reset=$'\E'"[00m"
    else
        color_failed=""
        color_success=""
        color_reset=""
    fi
    echo
    if [ $ret -eq 0 ] ; then
        echo -n "${color_success}--- sync completed successfully "
    else
        echo -n "${color_failed}--- failed to sync some targets "
    fi
    if [ $hours -gt 0 ] ; then
        printf "(%02g:%02g:%02g)" $hours $mins $secs
    elif [ $mins -gt 0 ] ; then
        printf "(%02g:%02g)" $mins $secs
    elif [ $secs -gt 0 ] ; then
        printf "(%s seconds)" $secs
    fi
    echo " ---${color_reset}"
    echo
    return $ret
}

function reposync()
{
    local ret=-1
    while [ 0 != $ret ]; do
    repo --trace sync --current-branch --no-clone-bundle --no-tags --prune
    ret=$?
    done
}

_wrap_build reposync "$@"
