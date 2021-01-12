#!/usr/bin/env bash

########################
# include the magic
########################
. ./demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=$BLACK

# hide the evidence
clear

p "echo 'View Operator Availability'"
pe "oc get packagemanifests -n openshift-marketplace | grep compliance-operator"
pe "clear"

p "echo 'View Install Modes and Channels'"
pe "oc describe packagemanifests compliance-operator -n openshift-marketplace"
pe "clear"

p "echo 'Create Namespace'"
pe "oc new-project how-to-moderate"
pe "clear"

p "echo 'View Catalog Source'"
pe "oc describe catalogsource redhat-marketplace -n openshift-marketplace | less"
pe "clear"



# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
