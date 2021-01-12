# HOW-TO: Compliance Operator
Basic how-to for running the [compliance-operator](https://github.com/openshift/compliance-operator) on [OpenShift version 4.6](https://docs.openshift.com/container-platform/4.6/welcome/index.html) on the command line to perform a compliance scan ocp4 and rhcos4 profiles.

## Table Of Contents
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
    - [View Operator Availability](#view-operator-availability)
    - [View Install Modes and Channels](#view-install-modes-and-channels)
  - [Create Namespace](#create-namespace)
  - [View Catelog Source](#view-catalog-source)
  - [Create Operator Group](#create-operator-group)
  - [Create Subscription](#create-subscription)
  - [View Deployment](#view-deployment)
  - [View Profile](#view-profile)
  - [View Profile Bundle](#view-profile-bundle)
- [Create Scans](#create-scans)
  - [Create Compliance Suite](#create-compliance-suite)
  - [View Compliance Scan](#view-compliance-scan)
  - [View Scan Settings](#view-scan-settings)
  - [View Scan Setting Binding](#view-scan-setting-binding)
- [Apply Compliance Remediation](#apply-compliance-remediation)
  
## Installation
The [compliance-operator](https://github.com/openshift/compliance-operator) is installable on OpenShift by an account with cluster-admin permissions. See [Adding Operators to a cluster](https://docs.openshift.com/container-platform/4.6/operators/admin/olm-adding-operators-to-cluster.html) for generalized operator installation instructions.

### Prerequisites
* Access to an OpenShift Container Platform cluster using an account with `cluster-admin` permissions.

* Assuming the `oc command` installed on your local system.

#### View Operator Availability
To ensure that the [compliance-operator](https://github.com/openshift/compliance-operator) is available to the cluster verify the [compliance-operator](https://github.com/openshift/compliance-operator) using the following command:
```bash
oc get packagemanifests -n openshift-marketplace | grep compliance-operator
``` 

#### View Install Modes and Channels
View the supported install modes and channels to see namespaces tenacy supported by the operator using the following command:
```bash
oc describe packagemanifests compliance-operator -n openshift-marketplace
```

### Create Namespace
We will be creating a new namespace, `how-to-moderate`, to deploy the [compliance-operator](https://github.com/openshift/compliance-operator).

Create the namespace using the following command:
```bash
oc new-project how-to-moderate
```

### View Catalog Source
A catalog source, defined by a [CatalogSource](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html) object is a repository of [Cluster Service Versions](https://docs.openshift.com/container-platform/4.6/operators/operator_sdk/osdk-generating-csvs.html), [Custom Resource Definitions](https://docs.openshift.com/container-platform/4.6/operators/understanding/crds/crd-extending-api-with-crds.html#crd-extending-api-with-crds), and operator packages. For this how-to we will be using the Red Hat supported version `4.6` of the operator. 

View the `redhat-marketplace` [CatalogSource](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html) object in the `openshift-marketplace` namespace using the following command:
```bash
oc describe catalogsource redhat-marketplace -n openshift-marketplace | less
```

### Create Operator Group
An Operator group, defined by an [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html)  object, selects target namespaces in which to generate required RBAC access for all Operators in the same namespace as the Operator group.

The namespace to which you subscribe the Operator must have an [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) that matches the install mode of the Operator. We will be installing the [compliance-operator](https://github.com/openshift/compliance-operator) in the `how-to-moderate` namespace.

Create a new [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) object using the following command:
```bash
oc apply -n how-to-moderate -f- <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: how-to-moderate-compliance-operator
spec:
  targetNamespaces:
  - how-to-moderate
EOF
```

View the [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) object using the following command:
```bash
oc describe OperatorGroup -n how-to-moderate how-to-moderate-operator-group | less
```

### Create Subscription
[Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) object keep operators up to date by tracking changes to [Catalogs](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html).

Create [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) object using the following command:
```bash
oc apply -n how-to-moderate -f- <<EOF
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
EOF
```

View the [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) object using the following command:
```bash
oc describe subscription how-to-moderate-subscription -n how-to-moderate | less
```

### View Deployment
At this point, [OpenShift Lifecycle Manager](https://docs.openshift.com/container-platform/4.6/operators/understanding/olm/olm-understanding-olm.html) is now aware of the selected Operator. A cluster service version (CSV) for the Operator should appear in the target namespace, and APIs provided by the Operator should be available for creation.

List the [Cluster Service Version](https://docs.openshift.com/container-platform/4.6/operators/operator_sdk/osdk-generating-csvs.html) version using the following command:

```bash
oc get clusterserviceversion -n how-to-moderate
```

View the `Install Plan` using the following command:
```bash
oc describe installplan -n how-to-moderate | less
```

At this point, the operator should be up and running.

List the `Deployment` using the following command:
```bash
oc get deploy -n how-to-moderate
```

List the Running `Pods` using the following command:
```bash
oc get pods -n how-to-moderate
```

### View Profile Bundle
OpenSCAP content for consumption by the Compliance Operator is distributed as container images. In order to make it easier for users to discover what profiles a container image ships, a [ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) object can be created, which the Compliance Operator then parses and creates a [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) object for each profile in the bundle. 

List the [ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) using the following command:
```bash
oc get profilebundle -n how-to-moderate
```

### View Profile
The [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) objects are never created manually, but rather based on a
[ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) object, typically one [ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) would result in
several [Profiles](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object). The [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) object contains parsed out details about
an OpenSCAP profile such as its XCCDF identifier, what kind of checks the
profile contains (node vs platform) and for what system or platform.

List the out-of-the-box [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) objects that are part of the [compliance-operator](https://github.com/openshift/compliance-operator) installation and can be listed using the following command:
```bash
oc get -n how-to-moderate profiles.compliance
```

## Create Scans 
After we have installed the [compliance-operator](https://github.com/openshift/compliance-operator) in the `how-to-moderate` namespace we are ready to start creating scans.

### Create Compliance Suite
[ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) is a collection of [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects, each of which describes a scan. 

The [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) in the background will create as many [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects as you specify in the `scans` field. The fields will be described in the section referring to [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects.

Create a new [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object with node and platform scans named `how-to-moderate-node-type-scan-setting` and `how-to-moderate-platform-type-scan-setting`:

```bash
oc apply -n how-to-moderate -f - <<EOF
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
EOF
```

Note that [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) objects will generate events which you can fetch programmatically. To get the events for the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) called `how-to-moderate-compliance-suite` use the following command:

```bash
oc get events -n how-to-moderate --field-selector involvedObject.kind=ComplianceSuite,involvedObject.name=how-to-moderate-compliance-suite
```

At this point the operator reconciles the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) custom resource, we can use this to track the progress of our scans using the following command:

Watch the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) objects:
```bash
oc get -n how-to-moderate compliancesuites -w
```

### View Compliance Scan
Similarly to `Pods` in Kubernetes, a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is the base object that the compliance-operator introduces. Also similarly to `Pods`, you normally don't want to create a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) object directly, and would instead want a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) to manage it.

When a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is created by a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object), the [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is owned by it. Deleting a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object will result in deleting all the [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects that it created.

Once a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) has finished running it'll generate the results as Custom Resources of the [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object) kind. However, the raw results in ARF format will also be available. These will be stored in a Persistent Volume which has a Persistent Volume Claim associated that has the same name as the scan.

Note that [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects will generate events which you can fetch programmatically. 

View [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) object:
```bash
oc get compliancescan -n how-to-moderate how-to-moderate-ocp4-scan
```

View the events for the scan called `how-to-moderate-ocp4-scan` use the following command:
```bash
oc get events --field-selector involvedObject.kind=ComplianceScan,involvedObject name=how-to-moderate-ocp4-scan
```

### View Scan Settings
[ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) fall into two basic categories - platform and node. The platform scans are for the cluster itself, in the listing above they're the ocp4-* scans, while the purpose of the node scans is to scan the actual cluster nodes. All the rhcos4-* profiles above can be used to create node scans.

List the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:
```bash
oc get scansetting -n how-to-moderate
```

View the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:
```bash
oc get scansetting -n how-to-moderate -oyaml | less
```

### View Scan Setting Binding
Before using one, you will need to configure how the scans will run. We can do this with the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) custom resource.

To run rhcos4-moderate and ocp4-moderate profiles, we will create the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) objects for each type.

List the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object using the following command:
```bash
oc get scansettingbinding -n how-to-moderate 
```

View the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object using the following command:
```bash
oc get scansettingbinding -n how-to-moderate -o yaml | less
```

The [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object then creates scan pods that run on each node in the cluster. The scan pods execute openscap-chroot on every node and eventually report the results. The scan takes several minutes to complete.

List the scan pods of you're interested in seeing the individual pods using the following command:
```bash
oc get -n how-to-moderate pods -w
```

To get all the [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object) results from the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object by using the label.

View [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object) using the following command:
```bash
oc get compliancesuites -n how-to-moderate -l compliance.openshift.io/suite=how-to-moderate-suite | less
```

### Apply Compliance Remediation
When the scan is done, the operator changes the state of the ComplianceSuite object to "Done" and all the pods are transition to the "Completed" state. You can then check the [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object) that were found with:

List [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object) using the following command:
```bash
oc get -n how-to-moderate complianceremediations
```

Apply remediation by setting `apply` item to `true` [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object) object using the following command:
```bash
oc edit -n how-to-moderate complianceremediation/<compliance-rule-name>
```

The [compliance-operator](https://github.com/openshift/compliance-operator) then aggregates all applied remediations and create a `MachineConfig` object per scan. This `MachineConfig` object is rendered to a `MachinePool` and the `MachineConfigDeamon` running on nodes in that pool pushes the configuration to the nodes and reboots the nodes.

You can watch the node status with using the following command:
```bash
oc get nodes -w
```

Once the nodes reboot, you might want to run another [Compliance Suite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) to ensure that the remediation that you applied previously was no longer found.

## References
[Compliance Operator Git Repository](https://github.com/openshift/compliance-operator)

[Compliance Operator OpenShift Documentation](https://docs.openshift.com/container-platform/4.6/security/compliance_operator/compliance-operator-understanding.html)

[Demo Magic](https://github.com/paxtonhare/demo-magic)

## Demo
Execute each shell scipts in a common directory to run the demo.

<details>
  <summary>Demo Magic Functions</summary>
  
```bash
cat <<EOT >> demo-magic.sh
#!/usr/bin/env bash

###############################################################################
#
# demo-magic.sh
#
# Copyright (c) 2015 Paxton Hare
#
# This script lets you script demos in bash. It runs through your demo script when you press
# ENTER. It simulates typing and runs commands.
#
###############################################################################

# the speed to "type" the text
TYPE_SPEED=20

# no wait after "p" or "pe"
NO_WAIT=false

# if > 0, will pause for this amount of seconds before automatically proceeding with any p or pe
PROMPT_TIMEOUT=0

# don't show command number unless user specifies it
SHOW_CMD_NUMS=false


# handy color vars for pretty prompts
BLACK="\033[0;30m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"
GREY="\033[0;90m"
CYAN="\033[0;36m"
RED="\033[0;31m"
PURPLE="\033[0;35m"
BROWN="\033[0;33m"
WHITE="\033[1;37m"
COLOR_RESET="\033[0m"

C_NUM=0

# prompt and command color which can be overriden
DEMO_PROMPT="$ "
DEMO_CMD_COLOR=$WHITE
DEMO_COMMENT_COLOR=$GREY

##
# prints the script usage
##
function usage() {
  echo -e ""
  echo -e "Usage: $0 [options]"
  echo -e ""
  echo -e "\tWhere options is one or more of:"
  echo -e "\t-h\tPrints Help text"
  echo -e "\t-d\tDebug mode. Disables simulated typing"
  echo -e "\t-n\tNo wait"
  echo -e "\t-w\tWaits max the given amount of seconds before proceeding with demo (e.g. '-w5')"
  echo -e ""
}

EOT
```

</details>


<details>
  <summary>Demo Script</summary>
  
```bash
sh <<EOF
#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

# hide the evidence
clear

# Put your stuff here

EOF
```

</details>
