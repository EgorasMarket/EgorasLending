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

contract EgorasLoanFacet{
   using SafeDecimalMath for uint;
    mapping(uint => bool) activeRequest;
    mapping(uint => mapping(address => uint)) requestPower;
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
 modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }
   Loan[] loans;
   Votters[] voters;
   struct Votters{
      address voter;
    }
    struct Requests{
      address creator;
      uint requestType;
      uint backers;
      uint company;
      uint branch;
      uint incentive;
      uint threshold;
      string reason;
      bool stale;
      
    }
    event RequestCreated(
      address _creator,
      uint _requestType,
      uint _backers,
      uint _company,
      uint _branch,
      uint _incentive,
      string _reason,
      uint _threshold,
      bool _stale,
      uint _requestID
      );
  event Confirmed(uint _loanID, uint _votingThreshold);
  event ApproveRequest(uint _requestID, bool _state, address _initiator);    
  Requests[] requests;
  mapping(uint => Votters[]) listOfvoters;
  mapping(uint => mapping(address => bool)) hasVoted;
  mapping(uint => bool) stale;
  mapping(uint => mapping(address => uint)) userVoteAmount;
  mapping(uint => uint) requestVoteAmount;
  mapping(uint => uint) loanVoteAmount;
  mapping(uint => uint) buyVoteAmount;
  mapping(uint => bool) isApproved;
  using SafeMath for uint256;
  address private egorasEUSD;
  address private egorasEGC;
  address private eNFTAddress;
  address private egorasEGR;
  uint private votingThreshold;
  uint private systemFeeBalance;
  uint private requestCreationPower;
  uint public backers;
  uint public company;
  uint public branch;
  uint public dailyIncentive;
  mapping(uint => uint) backersReward;
  mapping(uint => uint) companyReward;
  mapping(uint => uint) branchReward;
  mapping(address => bool)  branchAddress;
  mapping(address => address) branchRewardAddress;
  mapping(uint => mapping(address => bool)) manageRequestVoters;
  mapping(uint => mapping(address => bool)) currentVoters;
  mapping(uint => Votters[]) curVoters;
  mapping(uint => Votters[]) requestVoters;
  mapping(uint => mapping(address => uint)) votePower;
  uint private currentPeriod;
  uint public nextRewardDate;
  mapping(uint => uint) currentTotalVotePower;
  mapping(uint => bool) canReward;
  mapping(uint => mapping(address => uint)) currentUserTotalVotePower;
  event Repay(uint _amount, uint _time, uint _loanID);
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
      event RequestVote(
        address _voter,
        uint _requestID,
        uint _power,
        uint _totalPower
        
    );
    event Bought(uint _id, string _metadata, uint _time);
    event Refunded(uint amount, address voterAddress, uint _id, uint time);
    event Rewarded(uint amount, address voterAddress, uint _id, uint time);
    
    event LoanCreated(
        uint newLoanID, string _title,  uint _amount,  uint _length, 
       string _image_url, uint _inventoryFee, address _creator, bool _isLoan, bool _isConfirmed,
       string _metadata
);
event Voted(address voter,  uint loanID, uint _totalBackedAmount, uint _userPower);
 function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 function Initconstructor(
address _egorasEusd, address _egorasEgr, address _egorasEGC, uint _votingThreshold, uint _backers, uint _company, uint _branch, uint _dailyIncentive) external{
        require(address(0) != _egorasEusd, "Invalid address");
        require(address(0) != _egorasEgr, "Invalid address");
         require(address(0) != _egorasEGC, "Invalid address");
        egorasEGR = _egorasEgr;
        egorasEUSD = _egorasEusd;
        egorasEGC  = _egorasEGC;
        votingThreshold = _votingThreshold;
        backers = _backers;
        company = _company;
        branch = _branch;
        nextRewardDate = block.timestamp.add(1 days);
        currentPeriod = block.timestamp;
        dailyIncentive = _dailyIncentive;
  }

   function addBranch(address _branch, address _branchRewardAddress) external onlyOwner returns(bool){
        branchAddress[_branch] = true;
        branchRewardAddress[_branch] = _branchRewardAddress;
        return true;
    }
     function addNFTAddress(address _eNFTAddress) external onlyOwner returns(bool){
        eNFTAddress = _eNFTAddress;
        return true;
    }
   function suspendBranch(address _branch) external onlyOwner returns(bool) {
       branchAddress[_branch] = false;
       return true;
   }

    /*** Restrict access to Branch role*/    
      modifier onlyBranch() {        
        require(branchAddress[msg.sender] == true, "Address is not allowed to upload a loan!");       
        _;}
 
    /// Request
function createRequest(uint _requestType,uint _threshold, uint _incentive, uint _backers, uint _company, uint _branch, string memory _reason) public onlyOwner{
    require(_requestType >= 0 && _requestType <  2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      backers: _backers,
      company: _company,
      branch: _branch,
      incentive: _incentive,
      reason: _reason,
      stale: false,
      threshold: _threshold
     
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.backers,
      request.company,
      request.branch,
      request.incentive,
      request.reason,
      request.threshold,
      request.stale,
      newRequestID
      );
     
}

function governanceVote(uint _requestID, uint _votePower) public{
    require(_votePower > 0, "Power must be greater than zero!");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
    require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error");
    requestPower[_requestID][msg.sender] = requestPower[_requestID][msg.sender].add(_votePower);

      requestVoteAmount[_requestID] = requestVoteAmount[_requestID].add(_votePower);
        currentTotalVotePower[currentPeriod] = currentTotalVotePower[currentPeriod].add(_votePower);
        currentUserTotalVotePower[currentPeriod][msg.sender] = currentUserTotalVotePower[currentPeriod][msg.sender].add(_votePower);
         
         if(!currentVoters[currentPeriod][msg.sender]){
             currentVoters[currentPeriod][msg.sender] == true;
             curVoters[currentPeriod].push(Votters(msg.sender));
         }
        if(!manageRequestVoters[_requestID][msg.sender]){
            manageRequestVoters[_requestID][msg.sender] = true;  
            
            requestVoters[_requestID].push(Votters(msg.sender));
        }   
        canReward[currentPeriod] = true;
        emit RequestVote(msg.sender, _requestID, _votePower, requestVoteAmount[_requestID]);   
}

function validateRequest(uint _requestID) public{
    Requests storage request = requests[_requestID];
    require(requestVoteAmount[_requestID] >= votingThreshold, "It has not reach the voting threshold!");
    require(!request.stale, "This has already been validated");
    IERC20 egr = IERC20(egorasEGR);
    if(request.requestType == 0){
        votingThreshold = request.threshold;
    }else if(request.requestType == 1){
        dailyIncentive = request.incentive;
    }else if(request.requestType == 2){
        backers = request.backers;
        company = request.company;       
        branch  = request.branch;
    }
    
    for (uint256 i = 0; i < requestVoters[_requestID].length; i++) {
           address voterAddress = requestVoters[_requestID][i].voter;
           uint amount = requestPower[_requestID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, block.timestamp);
    }
    
   request.stale = true;
    emit ApproveRequest(_requestID, requestVoteAmount[_requestID] >= votingThreshold, msg.sender);
}
  
 function applyForLoan(
        string memory _title,
        uint _amount,
        uint _length,
        uint _inventoryFee,
        string memory _image_url,
        bool _isloan,
        string memory _loanMetaData
        ) external onlyBranch {
        require(_amount > 0, "Loan amount should be greater than zero");
        require(_length > 0, "Loan duration should be greater than zero");
        require(bytes(_title).length > 3, "Loan title should more than three characters long");
        require(branch.add(backers.add(company)) == 10000, "Invalid percent");
         Loan memory _loan = Loan({
         title: _title,
         amount: _amount,
         length: _length,
         image_url: _image_url,
         inventoryFee: _inventoryFee,
         loanMetaData: _loanMetaData,
         creator: msg.sender,
         isloan: _isloan,
         isConfirmed: false
        });
             loans.push(_loan);
             uint256 newLoanID = loans.length - 1;
             backersReward[newLoanID] = backersReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(backers))));
             companyReward[newLoanID] = companyReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(company))));
             branchReward[newLoanID] = branchReward[newLoanID].add(uint(uint(_inventoryFee).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(branch))));
             emit LoanCreated(newLoanID, _title, _amount, _length,_image_url, _inventoryFee, msg.sender, _isloan, false, _loanMetaData);
        }


        function vote(uint _loanID, uint _votePower) external{
            require(!stale[_loanID], "The loan is either approve/declined");
            require(!hasVoted[_loanID][msg.sender], "You cannot vote twice");
            Loan memory loan = loans[_loanID];
            require(loan.isConfirmed, "Can't vote at the moment!");
            require(_votePower > 0, "Power must be greater than zero!");
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
            require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error!");
            loanVoteAmount[_loanID] = loanVoteAmount[_loanID].add(_votePower);
             votePower[_loanID][msg.sender] = votePower[_loanID][msg.sender].add(_votePower);
            currentTotalVotePower[currentPeriod] = currentTotalVotePower[currentPeriod].add(_votePower);
            currentUserTotalVotePower[currentPeriod][msg.sender] = currentUserTotalVotePower[currentPeriod][msg.sender].add(_votePower);
             if(!currentVoters[currentPeriod][msg.sender]){
             currentVoters[currentPeriod][msg.sender] == true;
             curVoters[currentPeriod].push(Votters(msg.sender));
         }
            if(!hasVoted[_loanID][msg.sender]){
                 hasVoted[_loanID][msg.sender] = true;
                listOfvoters[_loanID].push(Votters(msg.sender));
            }
             canReward[currentPeriod] = true;
            emit Voted(msg.sender, _loanID,  loanVoteAmount[_loanID], _votePower);
    } 

    function isDue(uint _loanID) public view returns (bool) {
        if (loanVoteAmount[_loanID] >= votingThreshold)
            return true;
        else
            return false;
    }

function confirmLoan(uint _loanID)  external  onlyOwner{
    Loan storage loan = loans[_loanID];
    loan.isConfirmed = true;
    emit Confirmed(_loanID,votingThreshold);
}
    function approveLoan(uint _loanID) external{
    Loan storage loan = loans[_loanID];
    require(loan.isConfirmed, "This loan is yet to be confirmed!");
     require(isDue(_loanID), "Voting is not over yet!");
     require(!stale[_loanID], "The loan is either approve/declined");
     NFT ENFT = NFT(eNFTAddress);
     IERC20 EUSD = IERC20(egorasEUSD);
     IERC20 egr = IERC20(egorasEGR);
     if(loanVoteAmount[_loanID] >= votingThreshold){
     require(ENFT.mint(loan.creator, _loanID), "Unable to mint token");
     require(EUSD.mint(loan.creator, loan.amount.sub(loan.inventoryFee)), "Fail to transfer fund");
     require(EUSD.mint(LibDiamond.contractOwner(), companyReward[_loanID]), "Fail to transfer fund");
     require(EUSD.mint(branchRewardAddress[loan.creator], branchReward[_loanID]), "Fail to transfer fund");
    for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
            // Start of reward calc
            uint totalUserVotePower = votePower[_loanID][voterAddress].mul(1000);
            uint currentTotalPower = loanVoteAmount[_loanID];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(backersReward[_loanID]).div(1000);
            // End of reward calc
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           votePower[_loanID][voterAddress] = votePower[_loanID][voterAddress].sub(amount);
           require(EUSD.mint(voterAddress, share), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, block.timestamp);
    }
     isApproved[_loanID] = true;
     stale[_loanID] = true;
     
     emit ApproveLoan(_loanID, true, msg.sender, block.timestamp);
     }else{
        for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, block.timestamp);
    } 
     stale[_loanID] = true;
     emit ApproveLoan(_loanID, false, msg.sender, block.timestamp);
     }
}

function repayLoan(uint _loanID) external{
   Loan storage loan = loans[_loanID];
   require(loan.isloan, "Invalid loan.");
   require(loan.length >= block.timestamp, "Repayment period is over!");
   require(isApproved[_loanID], "This loan is not eligible for repayment!");
   require(loan.creator == msg.sender, "Unauthorized.");
   IERC20 iERC20 = IERC20(egorasEUSD);
   NFT eNFT = NFT(eNFTAddress);
   require(iERC20.allowance(msg.sender, address(this)) >= loan.amount, "Insufficient EUSD allowance for repayment!");
   iERC20.burnFrom(msg.sender, loan.amount);
   eNFT.burn(_loanID);
   emit Repay(loan.amount, block.timestamp, _loanID);  
}


// function buy(uint _id, string memory _buyerMetadata) external{
//     Loan storage buyorder = loans[_id];
//     require(!buyorder.isloan, "Invalid buy order.");
//     require(isApproved[_id], "You can't buy this asset at the moment!");
//     IERC20 iERC20 = IERC20(egorasEUSD);
//     NFT eNFT = NFT(eNFTAddress);
//     require(iERC20.allowance(msg.sender, address(this)) >= buyorder.amount, "Insufficient EUSD allowance for repayment!");
//     iERC20.burnFrom(msg.sender, buyorder.amount);
//     eNFT.burn(_id);
//     emit Bought(_id,_buyerMetadata, block.timestamp); 
// }

//  function auction(uint _loanID, string memory _buyerMetadata) external{
//    Loan storage loan = loans[_loanID];
//    require(loan.isloan, "Invalid loan.");
//    require(block.timestamp >= loan.length, "You can't auction it now!");
//    require(isApproved[_loanID], "This loan is not eligible for repayment!");
//    require(loan.creator != msg.sender, "Unauthorized.");
//     IERC20 iERC20 = IERC20(egorasEUSD);
//     NFT eNFT = NFT(eNFTAddress);
//     require(iERC20.allowance(msg.sender, address(this)) >= loan.amount, "Insufficient EUSD allowance for repayment!");
//     iERC20.burnFrom(msg.sender, loan.amount);
//     eNFT.burn(_loanID);
//     emit Bought(_loanID,_buyerMetadata, block.timestamp); 
//  }

function rewardVoters() external{
require(block.timestamp >= nextRewardDate, "Not yet time. Try again later");
require(canReward[currentPeriod], "No votes yet");
 IERC20 iERC20 = IERC20(egorasEGC);
 for (uint256 i = 0; i < curVoters[currentPeriod].length; i++) {
           address voterAddress = curVoters[currentPeriod][i].voter;
           uint amount = currentUserTotalVotePower[currentPeriod][voterAddress];
           uint total = currentTotalVotePower[currentPeriod];
           uint per = amount.divideDecimalRound(total);
           uint reward = dailyIncentive.multiplyDecimalRound(per);
           require(iERC20.mint(voterAddress, reward ), "Fail to mint EGC");
           emit Rewarded(reward, voterAddress, currentPeriod, block.timestamp);
    } 
   currentPeriod = block.timestamp;
   nextRewardDate = block.timestamp.add(1 days);
   canReward[currentPeriod] = false;

}


}