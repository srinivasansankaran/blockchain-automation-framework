const dotenv = require('dotenv');
dotenv.config();
module.exports = {
  port: "8081",
  quorumServer : "P2P",
  ganacheServer : "http://manufacturersr.rc.dev2.aws.blockchaincloudpoc-develop.com:15221",
  nodeIdentity : "0x89b5de86b80dbebf1aa096a54a078a4fa02c2f51",
  productContractAddress : "0x7d9116B41623d276F671C95a46F0aCeB1d62839a",
  nodeOrganization : "manufacturersr",
  nodeOrganizationUnit : "manufacturersr",
  nodeSubject : "Manufacturer,OU=Manufacturer,L=47.38/8.54/Zurich,C=CH",
  protocol: "raft"
};
