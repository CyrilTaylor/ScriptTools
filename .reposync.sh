#!/usr/bin/env bash
function _wrap_build()
{
    local start_time=$(date +"%s")
    local start_ns=$(date +"%N")
    "$@"
    local ret=$?
    local end_ns=$(date +"%N")
    ((start_ns=10#$start_ns))
    ((end_ns=10#$end_ns))
    local end_time=$(date +"%s")
    if [ $start_ns -gt $end_ns ] ; then
        end_time=$(($end_time-1))
        end_ns=$(($end_ns+1000000000))
    fi
    local tdiff=$(($end_time-$start_time))
    local nsdiff=$((($end_ns-${start_ns}) / 10000000))
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
    elif [[ $secs -ne 0 || $nsdiff -ne 0 ]] ; then
        printf "(%s.%02g seconds)" $secs $nsdiff
    fi
    echo " ---${color_reset}"
    echo
    return $ret
}

function reposync()
{
    # 当前 repo sync 进程的 pid
    PID=

    kill_prog() {
        # kill 当前repo sync子进程
        echo "kill : $PID"
        [[ -n $PID ]] && kill $PID
    }

    start_sync() {
        # 启动子进程(使用coproc)
        coproc syncproc { repo sync; }
        PID=$syncproc_PID
    }

    restart_sync() {
        kill_prog
        start_sync
    }

    # 如果网络流量在retry_delay时间内小于min_speed, 则认为repo sync已经卡住了

    min_speed="50"
    retry_delay=300

    ((counter=0))
    ((n_retries=0))

    restart_sync

    while true; do
        # 用ifstat检测网速
        speed=$(ifstat 1 1 | tail -n 1 | awk '{print $1}')
        result=$(echo "$speed < $min_speed" | bc)
        if [[ $result == "1" ]]; then
            ((counter++))
        else
            ((counter=0))
        fi
        if [[ `ps -p $PID| wc -l` == "1" ]]; then
            # 检测到子进程已经退出(ps已经查不到它了)

            # 用wait取得子进程返回值
            wait $PID

            if [[ $? -eq 0 ]]; then
                echo "sync successful"
                break
            else
                echo "sync failed"
                ((counter=0))
                ((n_retries++))
                restart_sync
                continue
            fi
        fi
        if ((counter > retry_delay)); then
            ((counter=0))
            echo "netspeed low. restart!"
            ((n_retries++))
            restart_sync
        fi
    done
}

_wrap_build reposync "$@"
