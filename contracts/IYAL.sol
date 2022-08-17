// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./Address.sol";

interface IIYAICO { 
    function ICO_ENDTIME() external view returns (uint256);
}

contract IYAL is ERC20, ERC20Capped, ERC20Mintable, ERC20Burnable {

    mapping(address => mapping(uint256 => uint256)) public amountHistory;
    mapping(uint256 => uint256) public feeHistory;
    mapping(uint256 => uint256) public totalAmount;
    uint256 public start_time;
    uint256 public next_fee_distribution;

    uint256 private BurningAmount;
    uint8 public MaxTransferAmount;
    uint8 public feeAmount;
    address public feeWallet;
    address public SALE_ADDRESS;

    event MaxTransferAmountUpdate(address indexed operator, uint8 Max);

    constructor() 
        ERC20("IYAL", "IYA") 
        ERC20Capped(10000000000000000000000000)
    {
        feeWallet = msg.sender;
        feeAmount = 2;
        BurningAmount = 2;
        _mint(msg.sender, 10000000000000000000000000);
        SALE_ADDRESS = address(0);

        start_time = block.timestamp;
        next_fee_distribution = start_time + 30 days;
        totalAmount[next_fee_distribution] = 0;
        feeHistory[next_fee_distribution] = 0;
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function SetFeeWallet(address addr) public onlyOwner {
        feeWallet = addr;
    }

    function setMaxTransfer(uint8 max) public onlyOwner {
        emit MaxTransferAmountUpdate(msg.sender, max);
        MaxTransferAmount = max;
    }

    function logHistory(address sender, address receiver, uint256 amount, uint256 fee) internal {
        if(block.timestamp > next_fee_distribution) {
            next_fee_distribution += 30 days;
            totalAmount[next_fee_distribution] = totalAmount[next_fee_distribution - 30 days];
            feeHistory[next_fee_distribution] = 0;
        }
        amountHistory[sender][next_fee_distribution] = balanceOf(sender);
        amountHistory[receiver][next_fee_distribution] = balanceOf(receiver);

        if(Address.isContract(sender)) {
            if(!Address.isContract(receiver)) {
                totalAmount[next_fee_distribution] += amount;
            }
        } else {
            if(!Address.isContract(receiver)) {
                totalAmount[next_fee_distribution] -= fee;
            } else {
                totalAmount[next_fee_distribution] -= fee;
                totalAmount[next_fee_distribution] -= amount;
            }
        }
        feeHistory[next_fee_distribution] += fee;
    }

    function burnICO(uint256 amount) internal {
        uint256 burnAmount = amount * BurningAmount/ 100;
        if(balanceOf(SALE_ADDRESS) < burnAmount)
            burnAmount = balanceOf(SALE_ADDRESS);
        
        if(SALE_ADDRESS == address(0))
            return;
        if(burnAmount > 0)
            _burn(SALE_ADDRESS, burnAmount);
    }

    function transfer(
        address recipient,
        uint256 amount
    )  public virtual override returns (bool) {
        IIYAICO ico = IIYAICO(SALE_ADDRESS);

        if(msg.sender == owner() || msg.sender == SALE_ADDRESS) {
            super.transfer(recipient, amount);
            return true;
        }
        if (block.timestamp <= ico.ICO_ENDTIME()) {
            require(msg.sender == owner() || msg.sender == SALE_ADDRESS, "Transfer is locked");
        }
        uint256 transferamountlimit = balanceOf(msg.sender) * MaxTransferAmount / 100;
        require(amount <= transferamountlimit, "your amount more than max transfer");

        burnICO(amount);
        uint256 fee = amount * feeAmount / 100;
        amount -= fee;
        
        super.transfer(feeWallet, fee);
        super.transfer(recipient, amount);

        logHistory(msg.sender, recipient, amount, fee);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool)  {
        IIYAICO ico = IIYAICO(SALE_ADDRESS);

        if(sender == owner() || sender == SALE_ADDRESS) {
            super.transferFrom(sender, recipient, amount);
            return true;
        }

        if (block.timestamp <= ico.ICO_ENDTIME()) {
            require(sender == owner() || sender == SALE_ADDRESS, "Transfer is locked");
        }
            
        uint256 transferamountlimit = balanceOf(sender) * MaxTransferAmount / 100;
        require(amount <= transferamountlimit, "your amount more than max transfer");

        burnICO(amount);
        uint256 fee = amount * feeAmount / 100;
        amount -= fee;

        super.transferFrom(sender, feeWallet, fee);
        super.transferFrom(sender, recipient, amount);

        logHistory(sender, recipient, amount, fee);
        return true;
    }

    function setICOAddress(address addr) public onlyOwner {
        require(SALE_ADDRESS == address(0), "ICO Contract address is already set!");
        SALE_ADDRESS = addr;
    }    
}
