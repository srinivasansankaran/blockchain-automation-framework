#!/bin/bash

set -x

CURRENT_DIR=${PWD}
FULLY_QUALIFIED_ORG_NAME="{{ component_ns }}"
ALTERNATIVE_ORG_NAMES=()
ORG_NAME="{{ component_name }}"
SUBJECT="C={{ component_country }},ST={{ component_state }},L={{ component_location }},O={{ component_name }}"
SUBJECT_PEER="{{ component_subject }}"
CA="{{ ca_url }}"
CA_ADMIN_USER="${ORG_NAME}-admin"
CA_ADMIN_PASS="${ORG_NAME}-adminpw"

ORG_ADMIN_USER="Admin@${FULLY_QUALIFIED_ORG_NAME}"
ORG_ADMIN_PASS="Admin@${FULLY_QUALIFIED_ORG_NAME}-pw"

ORG_CYPTO_FOLDER="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}"

ROOT_TLS_CERT="/crypto-config/ordererOrganizations/${FULLY_QUALIFIED_ORG_NAME}/ca/ca.${FULLY_QUALIFIED_ORG_NAME}-cert.pem"

CAS_FOLDER="${HOME}/ca-tools/cas/ca-${ORG_NAME}"
ORG_HOME="${HOME}/ca-tools/${ORG_NAME}"

## Enroll CA administrator for Org. This user will be used to create other identities
fabric-ca-client enroll -d -u https://${CA_ADMIN_USER}:${CA_ADMIN_PASS}@${CA} --tls.certfiles  ${ROOT_TLS_CERT} --home ${CAS_FOLDER} --csr.names "${SUBJECT_PEER}"

## Get the CA cert and store in Org MSP folder
fabric-ca-client getcacert -d -u https://${CA} --tls.certfiles ${ROOT_TLS_CERT} -M ${ORG_CYPTO_FOLDER}/msp
mkdir ${ORG_CYPTO_FOLDER}/msp/tlscacerts
cp ${ORG_CYPTO_FOLDER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/msp/tlscacerts

## Register and enroll admin for Org and populate admincerts for MSP
fabric-ca-client register -d --id.name ${ORG_ADMIN_USER} --id.secret ${ORG_ADMIN_PASS} --csr.names "${SUBJECT_PEER}" --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.AffiliationMgr=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" --tls.certfiles ${ROOT_TLS_CERT} --home ${CAS_FOLDER}

fabric-ca-client enroll -d -u https://${ORG_ADMIN_USER}:${ORG_ADMIN_PASS}@${CA} --tls.certfiles ${ROOT_TLS_CERT} --home ${ORG_HOME}/admin --csr.names "${SUBJECT_PEER}"

mkdir -p ${ORG_CYPTO_FOLDER}/msp/admincerts
cp ${ORG_HOME}/admin/msp/signcerts/* ${ORG_CYPTO_FOLDER}/msp/admincerts/${ORG_ADMIN_USER}-cert.pem

mkdir ${ORG_HOME}/admin/msp/admincerts
cp ${ORG_HOME}/admin/msp/signcerts/* ${ORG_HOME}/admin/msp/admincerts/${ORG_ADMIN_USER}-cert.pem

mkdir -p ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}
cp -R ${ORG_HOME}/admin/msp ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}

# Get TLS cert for admin and copy to appropriate location
fabric-ca-client enroll -d --enrollment.profile tls -u https://${ORG_ADMIN_USER}:${ORG_ADMIN_PASS}@${CA} -M ${ORG_HOME}/admin/tls --tls.certfiles ${ROOT_TLS_CERT}  --csr.names "${SUBJECT_PEER}"

# Copy the TLS key and cert to the appropriate place
mkdir -p ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls
cp ${ORG_HOME}/admin/tls/keystore/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.key
cp ${ORG_HOME}/admin/tls/signcerts/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/client.crt
cp ${ORG_HOME}/admin/tls/tlscacerts/* ${ORG_CYPTO_FOLDER}/users/${ORG_ADMIN_USER}/tls/ca.crt


## Register and enroll node and populate its MSP folder
PEER="{{ peer_name }}.${FULLY_QUALIFIED_ORG_NAME}"
CSR_HOSTS=${PEER}
for i in "${ALTERNATIVE_ORG_NAMES[@]}"
do
	CSR_HOSTS="${CSR_HOSTS},orderer.${i}"
done
echo "Registering and enrolling $PEER with csr hosts ${CSR_HOSTS}"


# Register the peer
fabric-ca-client register -d --id.name ${PEER} --id.secret ${PEER}-pw --id.type peer --tls.certfiles ${ROOT_TLS_CERT} --home ${CAS_FOLDER}

# Enroll to get peers TLS cert
fabric-ca-client enroll -d --enrollment.profile tls -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_HOME}/cas/orderers/tls --csr.hosts "${CSR_HOSTS}" --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"

# Copy the TLS key and cert to the appropriate place
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls
cp ${ORG_HOME}/cas/orderers/tls/keystore/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/server.key

cp ${ORG_HOME}/cas/orderers/tls/signcerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/server.crt

cp ${ORG_HOME}/cas/orderers/tls/tlscacerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/tls/ca.crt

rm -rf ${ORG_HOME}/cas/orderers/tls

# Enroll again to get the peer's enrollment certificate (default profile)
fabric-ca-client enroll -d -u https://${PEER}:${PEER}-pw@${CA} -M ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp --tls.certfiles ${ROOT_TLS_CERT} --csr.names "${SUBJECT_PEER}"


# Create the TLS CA directories of the MSP folder if they don't exist.
mkdir ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts
cp ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/cacerts/* ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/tlscacerts

# Copy the peer org's admin cert into target MSP directory
mkdir -p ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/admincerts

cp ${ORG_CYPTO_FOLDER}/msp/admincerts/${ORG_ADMIN_USER}-cert.pem ${ORG_CYPTO_FOLDER}/orderers/${PEER}/msp/admincerts

cd ${CURRENT_DIR}