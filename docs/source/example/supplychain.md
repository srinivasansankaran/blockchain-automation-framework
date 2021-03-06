# Supplychain

## Use case description
Welcome to the Supply Chain application which allows nodes to track products or goods along their chain of custody,
providing everyone along the way with relevant data to their product. The implementation has been done for Hyperledger Fabric and R3 Corda. The two will slightly differ in behavior but follow the same principles. There are two types of items that can be tracked, products and containers. Products are defined as such:


| Field       | Description                 |
|-------------|-----------------------------|
| trackingID  | which is a predefined unique ID, also a UUID, which is directly extracted from a <br>QR code.|
| participants| List of parties that will be in the chain of custody for the given product (extracted<br>                 from QR code) |
|custodian    | Party details of the current holder of the good.. This is changed to null when items<br>                  are scanned out of possession and set to new  owner upon scanning into possession<br>                       at next node |
|health       | Data from IOT sensors regarding condition of good (might only store min, max,<br>                     average values  which are stored on the local device until custodian changes or<br>                         something to minimize constant state changes) NOTE: This value is obsolete and not<br>                      used right now, it'll remain for future updates. |
| productName | Item name extracted from the QR|
| timestamp | Time at which most recent change of hands occurred |
| misc | Other data which is configurable and is being mapped from QR code |
|containerID | ID of any outer containing box. If null, behave normally. If container exists,<br>                   then custodian should be null and actually be read from the ContainerState |


The creator of the product will be marked as its initial custodian.  As a custodian, a node is able to package and unpackage goods. Packaging a good
stores an item in an existing ContainerState structured as such:

| Field       | Description        |
|-------------|-------------|
| trackingID | which is a predefined unique ID which is directly extracted from a QR code |
| participants | List of parties that will be in the chain of custody for the given product<br>                             (extracted from QR code) |
| custodian | Party details of the current holder of the good.. This is changed to null when items<br>                  are scanned out of possession and set to new  owner upon scanning into possession <br>                      at next node|
| health| Data from IOT sensors regarding condition of good (might only store min, max, average<br>                  values which are stored on the local device until custodian changes or something to<br>                     minimize constant state changes) NOTE: This value is obsolete and not used right now,<br>                   it'll remain for future updates. |
| timestamp| Time at which most recent change of hands occurred |
| misc | other data which is configurable and is being mapped from QR code |
| containerID | ID of any outer containing box. If null, behave normally. If container exists, then <br>                    custodian should be null and actually be read from the ContainerState |
| contents |  list of linearIDs for items contained inside |


Products being packaged will have their trackingID added to the contents list of the container. The Product will be
updated when its container is updated. If a product is contained it can no longer be handled directly (ie transfer ownership of a single product while still in a container with others).

Any of the participants can scan the QR code to claim custodianship.  History can be extracted via transactions stored on the ledger/ within the vault.

As mentioned before, items are identified by their QR code. These codes are meant to be generated about a product and used to
interact with a product. The QR will store a parsable JSON body with the following format:

| Field       | Description        |
|-------------|-------------|
| productName | Item name extracted from the QR
| trackingID | which is a predefined unique ID which is directly extracted from a QR code |
counterparties | List of parties that will be in the chain of custody for the given product (extracted <br>                 from QR code) |
| misc | other data which is configurable and is being mapped from QR code |

Also containers are identified by their QR code. These codes are meant to be generated about a container and use to interact with a container. The QR will store a parsable JSON body with the following format:

| Field       | Description        |
|-------------|-------------|
| trackingID | which is a predefined unique ID which is directly extracted from a QR code |
counterparties | List of parties that will be in the chain of custody for the given product (extracted<br>           from QR code)
| misc | other data which is configurable and is being mapped from QR code |


## Prerequisites

* The supplychain application requires that nodes have subject names that include a location field in the x.509 name formatted as such:
`L=<lat>/<long>/<city>`
* Fabric or Corda network of 1 or more organizations

## Setup Guide

The setup process has been automated using Ansible scripts, GitOps, and Helm charts. The files have all been provided to use and require the user to populate the network.yaml file accordingly.

The playbooks are as listed:
* platforms\r3-corda\configuration\deploy_cordapps.yaml
* platforms\hyperledger-fabric\configuration\chaincode-install-instantiate.yaml
* examples\supplychain-app\configuration\deploy-supplychain-app.yaml

These playbooks make use of several roles defined within 
* create/corda/api_components
* create/corda/api_values
* create/fabric/api_components
* create/fabric/api_values
* create/frontend

They are responsible for creating the helm release files for the platform specfic rest service, the nodejs api abstraction layer, and the front end. 

Jenkinsfiles have also been provided to automate the execution of these playbooks and other additional steps:

* buildFrontendImages.jenkinsfile - Build images for frontend and pushes to the desired container repository
* buildImages.Jenkinsfile - Build images for rest server and nodejs application
* deployChaincode.Jenkinsfile or deployCorDapps.Jenkinsfile - Follows the necessary steps to deploy the platforms smartcontracts to the existing network
* deployApp.Jenkinsfile - Uses ansible playbooks to create helm releases which GitOps uses to deploy the rest server, nodejs app, and frontend images.

The jenkins pipelines can automate the execution of the ansible playbooks as well as pass in any values that are not to be hardcoded in the network.yaml file

