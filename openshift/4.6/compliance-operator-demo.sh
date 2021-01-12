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

pei "echo 'View Operator Availability'"
pe "oc get packagemanifests -n openshift-marketplace | grep compliance-operator"
pe "clear"

pei "echo 'View Install Modes and Channels'"
pe "oc describe packagemanifests compliance-operator -n openshift-marketplace"
pe "clear"

pei "echo 'Create Namespace'"
pe "oc new-project how-to-moderate"
pe "clear"

pei "echo 'View Catalog Source'"
pe "oc describe catalogsource redhat-marketplace -n openshift-marketplace | less"
pe "clear"

pei "echo 'Create Operator Group'"
pe "oc apply -n how-to-moderate -f- <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: how-to-moderate-compliance-operator
spec:
  targetNamespaces:
  - how-to-moderate
EOF"
pe "clear"

pei "echo 'Create Subscription'"
pe "oc apply -n how-to-moderate -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: how-to-moderate-subscription
  namespace: how-to-moderate
spec:
  channel: "4.6"
  installPlanApproval: Automatic
  name: compliance-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: compliance-operator.v0.1.17  
EOF"
pe "clear"

pei "echo 'List Cluster Version'"
pe "oc get clusterserviceversion -n how-to-moderate"
pe "clear"

pei "echo 'View Install Plan'"
pe "oc describe installplan -n how-to-moderate | less"
pe "clear"

pei "echo 'View Deployment'"
pe "oc get deploy -n how-to-moderate"
pe "clear"

pei "echo 'List Running Pods'"
pe "oc get pods -n how-to-moderate"
pe "clear"

pei "echo 'List ProfileBundle'"
pe "oc get profilebundle -n how-to-moderate"
pe "clear"

pei "echo 'List out-of-the-box Profiles'"
pe "oc get -n how-to-moderate profiles.compliance"
pe "clear"

pei "echo ''"


# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
