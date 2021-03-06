#!/bin/bash -eu

trap 'signal_stop' SIGINT
trap 'signal_stop' SIGHUP

signal_stop(){
    echo "STOP"
    # 1. Stop Excitation Signal
    # - EXCチャンネルからFECを取る必要あり
    # 2. Stop Test Points
    # - EXCチャンネルからFECを取る必要あり
}

#
template=$1
output=$2
exc_channel=$3
DEBUG=$4
QUICK=$5
# Custum Band Width
if [[ "$exc_channel" == K1:VIS-*_BF_TEST_Y_EXC ]]; then    
    BW=0.001
elif [[ "$exc_channel" == K1:VIS-*_BF_COILOUTF_H*_EXC ]]; then
    BW=0.001
elif [[ "$exc_channel" == K1:VIS-*_BF_*_*_EXC ]]; then
    BW=0.003
elif [[ "$exc_channel" == K1:VIS-*_IP_*_*_EXC ]]; then
    BW=0.003
elif [[ "$exc_channel" == K1:VIS-*_MN_*_*_EXC ]]; then
    BW=0.01
elif [[ "$exc_channel" == K1:VIS-*_IM_*_*_EXC ]]; then
    BW=0.01
elif [[ "$exc_channel" == K1:VIS-*_TM_*_*_EXC ]]; then
    BW=0.01
elif [[ "$exc_channel" == K1:VIS-*_*_*_GAS_EXC ]]; then
    BW=0.01
else
    #printf "\n\033[1;31m Invalid Excitation Channel ${exc_channel} \033[0;39m\n\n"
    exit 1;
fi

# Change the bandwidth
if [ ${QUICK} = "1" ]; then
    BW=`python -c "print($BW*30)"` # fix me
fi
    
# Find Excitation Channel in the DTT template file
printf "\033[30;01m=== Use ${exc_channel} ===\033[00m\n"
EXCNUM=`grep -e "StimulusChannel.*${exc_channel}" $template | sed -r 's/^.*\[([0-9]+)\].*$/\1/'`
if [ -z "$EXCNUM" ]; then
    printf "\n\033[1;31m $template does not have ${exc_channel}\033[0;39m\n\n"
    exit 1;
fi

# Run
[ ${DEBUG} = "1" ] && cmd=diag || cmd=cat
$cmd <<EOF
open
 restore ${template}
  set Test.BW = ${BW}
  set Test.StimulusActive[${EXCNUM}] = true
 run -w
 save ${output}
quit
EOF
#echo --- wait 10 seconds; sleep 10
[ ${DEBUG} = "1" ] && cmd=/kagra/Dropbox/Subsystems/VIS/Scripts/automeasurement/bin/change_plotchannel.py || cmd=echo
$cmd ${output}
