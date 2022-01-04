/* eslint-disable prefer-const */
/* global artifacts */

const EgorasLoanDao = artifacts.require('EgorasLoanDao')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const EgorasLoanFacet = artifacts.require('EgorasLoanFacet')
const EgorasNFTFacets = artifacts.require('EgorasNFTFacets')
const EgorasPriceOracleFacet = artifacts.require('EgorasPriceOracleFacet')
const EgorasSwapFacet = artifacts.require('EgorasSwapFacet')

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}


//

function getSelectors (contract) {
  const selectors = contract.abi.reduce((acc, val) => {
    if (val.type === 'function') {
      acc.push(val.signature)
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) {
 deployer.deploy(EgorasLoanFacet);
 deployer.deploy(EgorasNFTFacets);
 deployer.deploy(EgorasPriceOracleFacet);
 deployer.deploy(EgorasSwapFacet);

  deployer.deploy(DiamondCutFacet)
  deployer.deploy(DiamondLoupeFacet)
  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [EgorasLoanFacet.address, FacetCutAction.Add, getSelectors(EgorasLoanFacet)],
      [EgorasNFTFacets.address, FacetCutAction.Add, getSelectors(EgorasNFTFacets)],
      [EgorasPriceOracleFacet.address, FacetCutAction.Add, getSelectors(EgorasPriceOracleFacet)],
      [EgorasSwapFacet.address, FacetCutAction.Add, getSelectors(EgorasSwapFacet)],
      [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    ]
    return deployer.deploy(EgorasLoanDao, diamondCut, [accounts[0]])
  })
}
 