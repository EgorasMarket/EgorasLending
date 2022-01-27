// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface NFT {
function ownerOf(uint256 tokenId) external view returns (address);
function mint(address to, uint tokenID) external returns(bool);
function burn(uint tokenID) external returns(bool);
  
}

interface LOAN {
      struct Loan{
        string title;
        uint amount;
        uint length;
        string image_url;
        address creator;
        bool isloan;
        string loanMetaData;
        uint inventoryFee;
        bool isConfirmed;
    }
function rewardMeta() external view returns(bool, uint, uint, uint, uint, address);
function rewardUsserMeta(uint index, uint curPeriod) external view returns(address, uint, uint);
function updatePeriods() external;
function getLoanData(uint _lID) external view returns (Loan memory, bool);
function getAddresses() external view returns (address, address);
}



contract EgorasLoanHelperFacet {
  using SafeDecimalMath for uint;
  struct LoanPlaceholder{
        string title;
        uint amount;
        uint length;
        string image_url;
        address creator;
        bool isloan;
        string loanMetaData;
        uint inventoryFee;
        bool isConfirmed;
    }
event Bought(uint _id, string _metadata, uint _time);
event Rewarded(uint amount, address voterAddress, uint _id, uint time);
function rewardVoters() external{
LOAN ln = LOAN(address(this));
bool _HcanReward;
uint _HnextRewardDate;
uint _HcurVoterLen;
uint _HdailyIncentive;
address _HegorasEGC;
uint _HcurrentPeriod;
(_HcanReward, _HnextRewardDate, _HcurVoterLen, _HdailyIncentive, _HcurrentPeriod, _HegorasEGC) = ln.rewardMeta();
require(block.timestamp >= _HnextRewardDate, "Not yet time. Try again later");
require(_HcanReward, "No votes yet");
 IERC20 iERC20 = IERC20(_HegorasEGC);
 for (uint256 i = 0; i < _HcurVoterLen; i++) {
           address _HvoterAddress;
           uint _Hamount;
           uint _Htotal;
           (_HvoterAddress, _Hamount, _Htotal) = ln.rewardUsserMeta(i, _HcurrentPeriod);
           uint per = _Hamount.divideDecimalRound(_Htotal);
           uint reward = _HdailyIncentive.multiplyDecimalRound(per);
           require(iERC20.mint(_HvoterAddress, reward ), "Fail to mint EGC");
           emit Rewarded(reward, _HvoterAddress, _HcurrentPeriod, block.timestamp);
    } 
   
   ln.updatePeriods();
}


function buy(uint _id, string memory _buyerMetadata) external{
    LOAN ln = LOAN(address(this));
    LoanPlaceholder memory buyorder;
    bool isApproved;
     (buyorder,isApproved) =  ln.getLoanData(_id);
    require(!buyorder.isloan, "Invalid buy order.");
    require(isApproved, "You can't buy this asset at the moment!");
    address egorasEUSD;
    address eNFTAddress;
    (egorasEUSD, eNFTAddress) = ln.getAddresses();
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= buyorder.amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, buyorder.amount);
    eNFT.burn(_id);
    emit Bought(_id,_buyerMetadata, block.timestamp); 
}

 function auction(uint _loanID, string memory _buyerMetadata) external{
   LOAN ln = LOAN(address(this));
   LoanPlaceholder memory loan;
   bool isApproved;
   (loan,isApproved) =  ln.getLoanData(_loanID);
   require(loan.isloan, "Invalid loan.");
   require(block.timestamp >= loan.length, "You can't auction it now!");
   require(isApproved, "This loan is not eligible for repayment!");
   require(loan.creator != msg.sender, "Unauthorized.");
   address egorasEUSD;
    address eNFTAddress;
    (egorasEUSD, eNFTAddress) = ln.getAddresses();
    IERC20 iERC20 = IERC20(egorasEUSD);
    NFT eNFT = NFT(eNFTAddress);
    require(iERC20.allowance(msg.sender, address(this)) >= loan.amount, "Insufficient EUSD allowance for repayment!");
    iERC20.burnFrom(msg.sender, loan.amount);
    eNFT.burn(_loanID);
    emit Bought(_loanID,_buyerMetadata, block.timestamp); 
 }

    
}