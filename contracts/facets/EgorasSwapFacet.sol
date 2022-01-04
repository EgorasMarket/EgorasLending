// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";

interface ERC20I {
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

interface PRICEORACLE {
    /// @notice Gets price of a ticker ie ETH-EUSD.
    /// @return current price of a ticker
    function price(string memory _ticker) external view returns (uint256);
}

contract EgorasSwapFacet{
     using SafeDecimalMath for uint;
     using SafeMath for uint256;
     address private _priceOracle;
     address private _baseAddress;
     address private _tokenAddress;
     string private _price;
     mapping(address => mapping(bool => uint)) userTotalSwap;
     mapping(bool => uint) totalSwap;

     event liquidityAdded(address user, uint _amount, uint time);
     event Swaped(address user, uint _amountGive, uint _amountGet, bool isBase, uint time);
     event Init(address __priceOracle, address __baseAddress,  address __tokenAddress, string __price, uint __time);


      modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }
    
    function initContructor(address __priceOracle, address __baseAddress,  address __tokenAddress, string memory __price) external onlyOwner{
        _priceOracle = __priceOracle;
        _baseAddress = __baseAddress;
        _tokenAddress = __tokenAddress;
        _price = __price;
        emit Init(__priceOracle, __baseAddress, __tokenAddress, __price, block.timestamp);
    }
    function _tFrom(address _contract, uint _amount, address _recipient) internal{
        require(ERC20I(_contract).allowance(_msgSender(), _recipient) >= _amount, "Non-sufficient funds");
        require(ERC20I(_contract).transferFrom(_msgSender(), _recipient, _amount), "Fail to tranfer fund");
    }
     function _bFrom(address _contract, uint _amount, address _recipient) internal{
        require(ERC20I(_contract).allowance(_msgSender(), _recipient) >= _amount, "Non-sufficient funds");
        require(ERC20I(_contract).burnFrom(_msgSender(), _amount), "Fail to burn fund");
    }
     function _mint(address _contract, uint _amount, address _recipient) internal{
        require(ERC20I(_contract).mint(_recipient, _amount), "Fail to tranfer fund");
    }
    function _bOf(address _contract, address _rec) internal view returns(uint){
        return ERC20I(_contract).balanceOf(_rec);
    }

     function _tr(uint _amount, address _rec, address _contract) internal{
        require(ERC20I(_contract).transfer(_rec, _amount), "Fail to tranfer fund");
    }


   function _getPr() internal view returns (uint) {
        PRICEORACLE p = PRICEORACLE(address(this));
        return p.price(_price);
    }
    function _getAmount(uint _marketPrice, uint _amount, bool _isBase) internal pure returns (uint) {
        return _isBase ? _amount.divideDecimal(_marketPrice) : _amount.multiplyDecimal(_marketPrice);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function swap(uint _amount, bool _isBase) external{
        _isBase ? _getBase(_amount) : _getToken(_amount);
    }

    function _getBase(uint _amount) internal {
        require(_amount > 0, "Zero value provided!");
        _tFrom(_tokenAddress, _amount, address(this));
        uint _marketPrice = _getPr();
        uint getAmount = _getAmount(_marketPrice, _amount, false);
        userTotalSwap[_msgSender()][false] = userTotalSwap[_msgSender()][false].add(_amount);
        totalSwap[false] = totalSwap[false].add(_amount);
        _mint(_baseAddress, getAmount, _msgSender());
        emit Swaped( _msgSender(), _amount, getAmount, false, block.timestamp);
    }

    function _getToken(uint _amount) internal{
        require(_amount > 0, "Zero value provided!");
        _bFrom(_baseAddress, _amount, address(this));
        uint _marketPrice = _getPr();
        uint getAmount = _getAmount(_marketPrice, _amount, true);
        userTotalSwap[_msgSender()][true] = userTotalSwap[_msgSender()][true].add(_amount);
        totalSwap[true] = totalSwap[true].add(_amount);
        _tr(getAmount, _msgSender(), _tokenAddress);
          emit Swaped( _msgSender(), _amount, getAmount, true, block.timestamp);
    }

    function getUserTotalSwap(address _user) external view returns(uint _base, uint _token){
        return(userTotalSwap[_user][true], userTotalSwap[_user][false]);
    }

     function getSystemTotalSwap() external view returns(uint _base, uint _token){
        return(totalSwap[true], totalSwap[false]);
    }

    function addLiquidity(uint _amount) external onlyOwner{
        require(_amount > 0, "Zero value provided!");
        _tFrom(_tokenAddress, _amount, address(this));
        emit liquidityAdded(_msgSender(), _amount, block.timestamp);
    }
}