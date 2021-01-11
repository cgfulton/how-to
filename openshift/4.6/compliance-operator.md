# HOW-TO: Compliance Operator Using The CLI
Basic how-to for running the [compliance-operator](https://github.com/openshift/compliance-operator) on [OpenShift version 4.6](https://docs.openshift.com/container-platform/4.6/welcome/index.html) on the command line to perform a moderate compliance scan.

## Table Of Contents
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
    - [Operator Availability](#operator-availability)
    - [Modes and Channels](#modes-and-channels)
    - [Namespace](#namespace)
    - [Cataloge Source](#catalogesource)
    - [OperatorGroup](#operatorgroup)
    - [Subscription](#subscription)
    - [Deployment](#deployment)
- [Create Scans](#create-scans)
  - [Create ScanSettings](#create-scansettings)
  - [Create ScanSettingBinding](#create-scansettingbinding)
  - [Create ComplianceSuite](#create-compliancesuite)
  - [Inspect ComplianceScan](#inspect-compliancescan)
  
  
# TODO
```text
The ProfileBundle Object
The Profile Object
//Reconcile ComplianceSuite
View Scan Pods
View ComplianceCheckResult Object
The ComplianceRemediation Object
View Iitial Compliance Remediation
Apply Compliance Remediation
View Applied Compliance Remediation
```

## Installation
The [compliance-operator](https://github.com/openshift/compliance-operator) is installable on OpenShift by an account with cluster-admin permissions. See [Adding Operators to a cluster](https://docs.openshift.com/container-platform/4.6/operators/admin/olm-adding-operators-to-cluster.html) for generalized step-by-step instructions.

### Prerequisites
* Access to an OpenShift Container Platform cluster using an account with `cluster-admin` permissions.

* Assuming the `oc command` installed on your local system.

#### Operator Availability
We need to ensure that the [compliance-operator](https://github.com/openshift/compliance-operator) is available to the cluster.

**Verify** availability using the following command:

```bash
oc get packagemanifests -n openshift-marketplace | grep compliance-operator
```

#### Modes and Channels
Inspect the [compliance-operator](https://github.com/openshift/compliance-operator) package manifest to view the available `Install Modes` and `Channels`. For this exercise we will be installing the operator in a `SingleNamespace` type. 

**Inspect** the supported install modes and channels supported using the following command:

```bash
oc describe packagemanifests compliance-operator -n openshift-marketplace
```

#### Namespace
For this exercise we will be creating a unique namespace to deploy the [compliance-operator](https://github.com/openshift/compliance-operator).

**Create** the `fisma-moderate` namespace  using the following command:

```bash
oc new-project fisma-moderate
```

#### Cataloge Source
A catalog source, defined by a [CatalogSource](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html) object is a repository of CSVs, CRDs, and operator packages. For this how-to we will be using the supported "4.6" version of the operator. 

**View** the available [CatalogSource](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html) objects in the `openshift-marketplace` namespace:

```bash
oc get catalogsource redhat-marketplace -n openshift-marketplace
```

#### Operator Group
An Operator group, defined by an [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html)  object, selects target namespaces in which to generate required RBAC access for all Operators in the same namespace as the Operator group.

The namespace to which you subscribe the Operator must have an [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) that matches the install mode of the Operator. For our exercise we will be installing the [compliance-operator](https://github.com/openshift/compliance-operator) in the `fisma-moderate` namespace.

**Create** [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) object:

```bash
oc apply -n fisma-moderate -f- <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: fisma-moderate-compliance-operator
spec:
  targetNamespaces:
  - fisma-moderate
EOF
```

**Inspect** the [OperatorGroup](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/operatorgroup-operators-coreos-com-v1.html) object.

```bash
oc get OperatorGroup -n fisma-moderate -oyaml fisma-moderate-operator-group | less
```

#### Subscription
[Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) keeps operators up to date by tracking changes to [Catalogs](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/catalogsource-operators-coreos-com-v1alpha1.html).

**Create** a new [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) object:

```bash
oc apply -n fisma-moderate -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: fisma-moderate-subscription
  namespace: fisma-moderate
spec:
  channel: "4.6"
  installPlanApproval: Automatic
  name: compliance-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: compliance-operator.v0.1.17  
EOF
```

**Inspect** the [Subscription](https://docs.openshift.com/container-platform/4.6/rest_api/operatorhub_apis/subscription-operators-coreos-com-v1alpha1.html) object:

```bash
oc get subscription fisma-moderate-subscription -n fisma-moderate -oyaml | less
```

#### Deployment
At this point, [OpenShift Lifecycle Manager](https://docs.openshift.com/container-platform/4.6/operators/understanding/olm/olm-understanding-olm.html) is now aware of the selected Operator. A cluster service version (CSV) for the Operator should appear in the target namespace, and APIs provided by the Operator should be available for creation.

** Verify** the [compliance-operator](https://github.com/openshift/compliance-operator) version:

```bash
oc get csv -n fisma-moderate
```

**Verify** the [compliance-operator](https://github.com/openshift/compliance-operator) approval:

```bash
oc get ip -n fisma-moderate
```

At this point, the operator should be up and running.

**View** deployment:
```bash
oc get deploy -n fisma-moderate
```

**View** the running pods:
```bash
oc get pods -n fisma-moderate
```

### Inspect `ProfileBundle` Object
OpenSCAP content for consumption by the Compliance Operator is distributed
as container images. In order to make it easier for users to discover what
profiles a container image ships, a [ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) object can be created, which the Compliance Operator then parses and creates a [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) object for each profile in the bundle. The [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) can be then either used directly or further customized using a [TailoredProfile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-tailoredprofile-object) object.

Verify ProfileBundle objects:

```bash
oc get profilebundle -n fisma-moderate
```

### Inspct `Profile` Object
The [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) objects are never created manually, but rather based on a
[ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) object, typically one [ProfileBundle](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profilebundle-object) would result in
several [Profiles](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object). The [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) object contains parsed out details about
an OpenSCAP profile such as its XCCDF identifier, what kind of checks the
profile contains (node vs platform) and for what system or platform.

## Create `Scans` 
After we have installed the [compliance-operator](https://github.com/openshift/compliance-operator) in the `fisma-moderate` namespace we are ready to start creating scans.

**View** the out-of-the-box [Profile](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-profile-object) objects that are part of the [compliance-operator](https://github.com/openshift/compliance-operator) installation using the following command:

```bash
oc get -n fisma-moderate profiles.compliance
```

### Create `ComplianceSuite`
[ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) is a collection of [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects, each of which describes a scan. 

The [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) in the background will create as many [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects as you specify in the `scans` field. The fields will be described in the section referring to [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects.

**Create** a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object with node and platform scans named `fisma-moderate-node-type-scan-setting` and `fisma-moderate-platform-type-scan-setting`:

```bash
oc create -n fisma-moderate -f - <<EOF
apiVersion: compliance.openshift.io/v1alpha1
kind: ComplianceSuite
metadata:
  name: fisma-moderate-compliance-suite
spec:
  autoApplyRemediations: false
  schedule: "0 1 * * *"
  scans:
    - name: fisma-moderate-rhcos4-scan
      scanType: Node
      profile: xccdf_org.ssgproject.content_profile_moderate
      content: ssg-rhcos4-ds.xml
      nodeSelector:
        node-role.kubernetes.io/worker: ""
    - name: fisma-moderate-ocp4-scan
      scanType: Platform
      profile: xccdf_org.ssgproject.content_profile_moderate
      content: ssg-ocp4-ds.xml
      nodeSelector:
        node-role.kubernetes.io/worker: ""
EOF
```

Note that [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) objects will generate events which you can fetch programmatically. To get the events for the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) called `fisma-moderate-compliance-suite` use the following command:

```bash
oc get events -n fisma-moderate --field-selector involvedObject.kind=ComplianceSuite,involvedObject.name=fisma-moderate-compliance-suite
```

At this point the operator reconciles the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) custom resource, we can use this to track the progress of our scans using the following command:

**View [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) objects:

```bash
oc get -n fisma-moderate compliancesuites -w
```
### Inspect Generated `ComplianceScan` 
Similarly to `Pods` in Kubernetes, a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is the base object that the compliance-operator introduces. Also similarly to `Pods`, you normally don't want to create a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) object directly, and would instead want a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) to manage it.

When a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is created by a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object), the [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) is owned by it. Deleting a [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object will result in deleting all the [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects that it created.

Once a [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) has finished running it'll generate the results as Custom Resources of the [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object) kind. However, the raw results in ARF format will also be available. These will be stored in a Persistent Volume which has a Persistent Volume Claim associated that has the same name as the scan.

Note that [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) objects will generate events which you can fetch programmatically. 

**List** [ComplianceScan](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancescan-object) object:

```bash
oc get compliancescan -n fisma-moderate fisma-moderate-ocp4-scan
```

**View** the events for the scan called `fisma-moderate-ocp4-scan` use the following command:

```bash
oc get events --field-selector involvedObject.kind=ComplianceScan,involvedObject name=fisma-moderate-ocp4-scan
```

### Inspect Generated `ScanSettings`
[ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) fall into two basic categories - platform and node. The platform scans are for the cluster itself, in the listing above they're the ocp4-* scans, while the purpose of the node scans is to scan the actual cluster nodes. All the rhcos4-* profiles above can be used to create node scans.

**List** the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:

```bash
oc get scansetting -n fisma-moderate
```

**Inspect** the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:

```bash
oc get scansetting -n fisma-moderate -oyaml | less
```

### Inspect Generated `ScanSettingBinding` 
Before using one, you will need to configure how the scans will run. We can do this with the [ScanSetting](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) custom resource.

To run rhcos4-moderate and ocp4-moderate profiles, we will create the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) objects for each type.

**List** the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:

```bash
oc get scansettingbinding -n fisma-moderate -o yaml
```

**Inspect** the [ScanSettingBinding](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-scansetting-and-scansettingbinding-objects) object:

```bash
oc get scansettingbinding -n fisma-moderate fisma-moderate-scan-setting-binding -o yaml | less
```


The [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object then creates scan pods that run on each node in the cluster. The scan pods execute openscap-chroot on every node and eventually report the results. The scan takes several minutes to complete.

If you're interested in seeing the individual pods, you can do so with:

**List** scan pods:

```bash
oc get -n fisma-moderate pods -w
```

To get all the [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object) results from the [ComplianceSuite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) object by using the label 
`compliance.openshift.io/suite` with the following commad:

**View** [ComplianceCheckResult](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancecheckresult-object):

```bash
oc get compliancesuites -n fisma-moderate -l compliance.openshift.io/suite=fisma-moderate-suite
```

### Compliance Remediation
When the scan is done, the operator changes the state of the ComplianceSuite object to "Done" and all the pods are transition to the "Completed" state. You can then check the [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object) that were found with:

**List** [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object):

```bash
oc get -n fisma-moderate complianceremediations
```

To apply a remediation, edit that object and set its Apply attribute to true.

**Apply** [ComplianceRemediation](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-complianceremediation-object):

```bash
oc edit -n fisma-moderate complianceremediation/<compliance-rule-name>
```

#### View Applied `Compliance Remediation`
The [compliance-operator](https://github.com/openshift/compliance-operator) then aggregates all applied remediations and create a `MachineConfig` object per scan. This `MachineConfig` object is rendered to a `MachinePool` and the `MachineConfigDeamon` running on nodes in that pool pushes the configuration to the nodes and reboots the nodes.

You can watch the node status with:

```bash
oc get nodes -w
```

Once the nodes reboot, you might want to run another [Compliance Suite](https://github.com/openshift/compliance-operator/blob/master/doc/crds.md#the-compliancesuite-object) to ensure that the remediation that you applied previously was no longer found.

## References

[Compliance Operator Git Repository](https://github.com/openshift/compliance-operator)

[Compliance Operator OpenShift Documentation](https://docs.openshift.com/container-platform/4.6/security/compliance_operator/compliance-operator-understanding.html)
