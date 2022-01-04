/* eslint-disable prefer-const */
/* global artifacts */
const EgorasNFTFacet = artifacts.require('EgorasNFTFacet')



module.exports = function (deployer, network, accounts) {
let symbol = "eNFT";
let name = "Egoras eNFT";
let LoanAddress = "0xBe807Dddb074639cD9fA61b47676c064fc50D62C";
return deployer.deploy(EgorasNFTFacet, name, symbol, LoanAddress)
}
 