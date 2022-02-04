#!/bin/bash
if [[ "$1" == '-h' || "$1" == '--help' ]] ; then
    cat <<EOF
usage: atmopen 

Open the automeasurement in special X window.
EOF
    exit
fi
if [[ "$1" == '-x' ]] ; then
    shift
fi

DOCKER_HOST=k1ctr27
EPICS_GATEWAY=172.20.0.2
ADL=/kagra/Dropbox/Subsystems/VIS/Scripts/automeasurement/pcas/AUTOMEASUREMENT_OVERVIEW.adl

exec xterm \
    -si -sk +sb \
    -geometry 150x20 \
    -bg ForestGreen \
    -fg white \
    -fa Monospace \
    -fs 10 \
    -title "AutoMeasurement: $*" \
    -e "ssh -X ${DOCKER_HOST} -o ControlMaster=auto -o ControlPersist=600 -t env EPICS_CA_ADDR_LIST=${EPICS_GATEWAY} EPICS_CA_AUTO_ADDR_LIST=NO medm -x ${ADL}"
    &    