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

pei "echo 'List Profile Bundle'"
pe "oc get profilebundle -n how-to-moderate"
pe "clear"

pei "echo 'List out-of-the-box Profiles'"
pe "oc get -n how-to-moderate profiles.compliance"
pe "clear"

pei "echo 'Create Compliance Suite'"
pe "oc apply -n how-to-moderate -f - <<EOF
apiVersion: compliance.openshift.io/v1alpha1
kind: ComplianceSuite
metadata:
  name: how-to-moderate-compliance-suite
spec:
  autoApplyRemediations: false
  schedule: "0 1 * * *"
  scans:
    - name: how-to-moderate-rhcos4-scan
      scanType: Node
      profile: xccdf_org.ssgproject.content_profile_moderate
      content: ssg-rhcos4-ds.xml
      nodeSelector:
        node-role.kubernetes.io/worker: ""
    - name: how-to-moderate-ocp4-scan
      scanType: Platform
      profile: xccdf_org.ssgproject.content_profile_moderate
      content: ssg-ocp4-ds.xml
      nodeSelector:
        node-role.kubernetes.io/worker: ""
EOF"
pe "clear"

pei "echo 'View Compliance Suite Events'"
pe "oc get events -n how-to-moderate --field-selector involvedObject.kind=ComplianceSuite,involvedObject.name=how-to-moderate-compliance-suite
"
pe "clear"

pei "echo 'View Compliance Suite Progress'"
pe "oc get -n how-to-moderate compliancesuites -w"
pe "clear"

pei "echo 'View Compliance Scan'"
pe "oc get compliancescan -n how-to-moderate how-to-moderate-ocp4-scan"
pe "clear"

pei "echo 'View Compliance Scan Events'"
pe "oc get events --field-selector involvedObject.kind=ComplianceScan,involvedObject name=how-to-moderate-ocp4-scan"
pe "clear"

pei "echo 'List and View Scan Settings'"
pe "oc get scansetting -n how-to-moderate"
pe "oc get scansetting -n how-to-moderate -oyaml | less"
pe "clear"

pei "echo 'List and View Scan Setting Binding'"
pe "oc get scansettingbinding -n how-to-moderate"
pe "oc get scansettingbinding -n how-to-moderate -o yaml | less"
pe "clear"

pei "echo 'Watch Scan Pods'"
pe "oc get -n how-to-moderate pods -w"
pe "clear"

pei "echo 'View Compliance Check Result'"
pe "oc get compliancesuites -n how-to-moderate -l compliance.openshift.io/suite=how-to-moderate-suite | less"
pe "clear"

pei "echo 'List Compliance Remediation'"
pe "oc get -n how-to-moderate complianceremediations"
p ""

pe "echo 'Apply Compliance Remediation'"
pe "oc edit -n how-to-moderate complianceremediation/<compliance-rule-name>"



# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
