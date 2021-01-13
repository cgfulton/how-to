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
TYPE_SPEED=100

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${BLACK}➜ ${CYAN}\W "

# text color
DEMO_CMD_COLOR=$BLACK


# hide the evidence
clear

p "List Operator Availability"
pe "oc get packagemanifests -n openshift-marketplace | grep compliance-operator"
pe ""
clear

p "Inspect Install Modes and Channels"
pe "oc describe packagemanifests compliance-operator -n openshift-marketplace | less"
pe ""
clear

p "Create Namespace"
pe "oc new-project ${NAMESPACE}"
pe ""
clear

p "Inspect redhat-marketplace Catalog Source"
pe "oc describe catalogsource redhat-marketplace -n openshift-marketplace | less"
pe ""
clear

p "Create and Inspect Operator Group"
pe "oc apply -n ${NAMESPACE} -f- <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${NAMESPACE}-compliance-operator
spec:
  targetNamespaces:
  - ${NAMESPACE}
EOF"
pe "oc get OperatorGroup -n ${NAMESPACE}"
pe "oc describe OperatorGroup -n ${NAMESPACE} ${NAMESPACE}-compliance-operator | less"
pe ""
clear

p "Create and Inspect Subscription"
pe "oc apply -n ${NAMESPACE} -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${NAMESPACE}-subscription
  namespace: ${NAMESPACE}
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: compliance-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: compliance-operator.v0.1.17  
EOF"
pe "oc get subscription -n ${NAMESPACE}"
pe "oc describe subscription ${NAMESPACE}-subscription -n ${NAMESPACE} | less"
pe ""
clear

p "List Cluster Service Version"
pe "oc get clusterserviceversion -n ${NAMESPACE}"
pe ""
clear

p "List Install Plan"
pe "oc get installplan -n ${NAMESPACE}"
pe ""
clear

p "List Deployment"
pe "oc get deploy -n ${NAMESPACE}"
pe ""
clear

p "List Running Pods"
pe "oc get pods -n ${NAMESPACE}"
pe ""
clear

p "List Profile Bundle"
pe "oc get profilebundle -n ${NAMESPACE}"
pe ""
clear

p "List out-of-the-box Profiles"
pe "oc get profiles.compliance -n ${NAMESPACE}"
pe ""
clear

p "Create Compliance Suite"
pe "oc apply -n ${NAMESPACE} -f - <<EOF
apiVersion: compliance.openshift.io/v1alpha1
kind: ComplianceSuite
metadata:
  name: ${NAMESPACE}-compliance-suite
spec:
  autoApplyRemediations: false
  schedule: '0 1 * * *'
  scans:
    - name: ${NAMESPACE}-rhcos4-scan
      scanType: Node
      profile: xccdf_org.ssgproject.content_profile_moderate
      content: ssg-rhcos4-ds.xml
      nodeSelector:
        node-role.kubernetes.io/worker: ''
EOF"
pe "oc get compliancescan -n ${NAMESPACE}"
pe "oc describe compliancescan -n ${NAMESPACE} ${NAMESPACE}-rhcos4-scan | less"
pe ""
clear

p "Watch Suite Progress"
pe "oc get -n ${NAMESPACE} compliancesuites -w"
pe ""
clear

p "List Compliance Scan Events"
pe "oc get events --field-selector involvedObject.kind=ComplianceScan,involvedObject.name=gfulton-how-to-demo-rhcos4-scan"
pe ""
clear

p "List and Inspect Scan Settings"
pe "oc get scansetting -n ${NAMESPACE}"
pe "oc get scansetting -n ${NAMESPACE} -oyaml | less"
pe ""
clear

p "List and Inspect Scan Setting Binding"
pe "oc get scansettingbinding -n ${NAMESPACE}"
pe "oc get scansettingbinding -n ${NAMESPACE} -o yaml | less"
pe ""
clear

p "List Scan Pods"
pe "oc get -n ${NAMESPACE} pods"
pe ""
clear

p "List Compliance Check Result"
pe "oc get compliancesuites -n ${NAMESPACE} -l compliance.openshift.io/suite=${NAMESPACE}-compliance-suite | less"
pe ""
clear

p "List Compliance Remediation"
pe "oc get -n ${NAMESPACE} complianceremediations"
pe ""
clear

p "Apply Compliance Remediation"
p "oc edit -n ${NAMESPACE} complianceremediation/<compliance-rule-name>"
cmd


# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
