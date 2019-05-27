function main
{
    if [ $# -lt 3 ] || [[ $* =~ -h ]] || [[ $* =~ --help ]]; then
        cat usage.txt
        return
    fi

    # this is in dd's terms .. 1M=1024*1024
    # whereas 1MB is 1000*1000 for dd!!
    _1M=1048576

    n_cores=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
    n_pdls=n_cores # number of parallel downloads
    n_pdls=$4 # number of parallel downloads
    if [[ "$n_pdls" == "" ]]; then
        n_pdls=$((n_cores + 0))
    fi

    # this has to be in the format user@machine
    remote=$1

    #foll later ..
    #https://superuser.com/a/686527
    #server=$1
    #downloader=$4

    # remote file path
    # this has to be in the format
    rmtfp=$2 # src at remote machine

    # local file path
    locfp=$3 # dest at local machine

    /dev/null > $locfp
    # ssh $remote dd if=/dev/random of=$rmtfp bs=1M count=4

    bytes=$(ssh $remote ls -l $rmtfp | awk '{print $5}')

    spbytes=$((bytes / n_pdls )) # single part's byte-size

    # if spbytes<1MB file size then no need to do multi part
    if [ $spbytes -lt $_1M ]; then
        n_pdls=1
    fi

    # i am so much concerned about keeping read/write MB sized
    # because of the perf hit that it would take to read into bytes
    spMBs=$((spbytes / _1M))

    function chk_chksum
    {
        rmtsum=`ssh $remote md5sum "$rmtfp" | awk '{print $1}'`
        locsum=`md5sum "$locfp" | awk '{print $1}'`

        if [[ "$rmtsum" == "$locsum" ]]; then
            echo checksum match
        else
            >&2 echo checksum differ
        fi
    }

    function do_dwn
    {
        for i in `seq 0 $((n_pdls - 2))`; do
            echo downloading part\#$((i + 1)) ..
            # https://unix.stackexchange.com/a/121868
            echo \
            ssh $remote dd iflag=fullblock if="$rmtfp" bs=1M count=$spMBs skip=$((spMBs * i)) \| \
                dd iflag=fullblock of="$locfp" bs=1M count=$spMBs seek=$((spMBs * i)) conv=notrunc \&
            ssh $remote dd iflag=fullblock if="$rmtfp" bs=1M count=$spMBs skip=$((spMBs * i)) | \
                dd iflag=fullblock of="$locfp" bs=1M count=$spMBs seek=$((spMBs * i)) conv=notrunc &
        done

        echo downloading part\#$n_pdls ..
        echo \
        ssh $remote dd iflag=fullblock if="$rmtfp" bs=1M skip=$((spMBs * (n_pdls - 1))) \| \
            eval dd iflag=fullblock of="$locfp" bs=1M seek=$((spMBs * (n_pdls - 1))) conv=notrunc \&
        ssh $remote dd iflag=fullblock if="$rmtfp" bs=1M skip=$((spMBs * (n_pdls - 1))) | \
            dd iflag=fullblock of="$locfp" bs=1M seek=$((spMBs * (n_pdls - 1))) conv=notrunc &

        # https://unix.stackexchange.com/a/76719
        wait
        echo download completed.
    }

    if [[ $* =~ -t ]] || [[ $* =~ --time ]]; then
        time do_dwn
    else
        do_dwn
    fi

    if [[ $* =~ -c ]] || [[ $* =~ --checksum ]]; then
        chk_chksum
    fi
}

main $@

