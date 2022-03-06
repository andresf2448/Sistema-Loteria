// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20.sol";
// loteriaRocket, LR, 10000
contract Loteria {
    //Direcciones
    address public owner;
    uint public randNonce = 0;
    ERC20 private token;

    constructor(string memory name, string memory symbol, uint amountSupply){
        owner = msg.sender;
        token = new ERC20(name, symbol);
        token.mint(amountSupply);
    }

    //Events
    event congratulationWinnerEvent (string);
    event buyTokensEvent (address , uint);
    event withdrawMoneyEvent (string , address , string , uint);

    //Modifier
    modifier onlyOwner (address) {
        require (msg.sender == owner, "No posees permisos para esta operacion");
        _;
    }

    //Mapping para identificar la direccion con los boletos comprados
    mapping(address => uint[]) private userTickets;
    mapping(uint => address) private participies;
    uint [] ticketsTotal;

    function priceTokens(uint _numTokens) internal pure returns (uint) {
        //Conversion my token a ethers 1 a 1
        return _numTokens * (1 ether);
    }

    function buyTokens(uint _numTokens) public payable {
        require(token.balanceOf(address(this)) >= _numTokens, "Compra menos tokens.");
        uint cost = priceTokens(_numTokens);
        require(msg.value >= cost, "Necesitas mas ethers para comprar la cantidad de tokens deseada.");
        uint returnValue = msg.value - cost;

        payable(msg.sender).transfer(returnValue);
        token.transfer(msg.sender, _numTokens);
        emit buyTokensEvent(msg.sender, _numTokens);
    }

    function seeUserTickets(address account) public view returns(uint[] memory){
        return userTickets[account];
    }

    function buyTicket(uint quantityTickets) public {
        uint price = quantityTickets * 1;
        require(balanceOf(msg.sender) >= price, "No tienes los tokens suficientes para comprar los tickets deseados.");
        token.transferTokenLottery(msg.sender, owner, price);

        for(uint i = 0; i < quantityTickets; i++){
            uint numberTicket = uint(keccak256(abi.encodePacked(msg.sender, randNonce))) % 10000;
            userTickets[msg.sender].push(numberTicket);
            participies[numberTicket] = msg.sender;
            ticketsTotal.push(numberTicket);
            randNonce++;
        }
    }

    function etherBalanceContract() public view  onlyOwner(msg.sender) returns(uint){
        return address(this).balance;
    }

    function balanceOf(address account) public view returns(uint){
        return token.balanceOf(account);
    }

    function winnerLottery() public onlyOwner(msg.sender) returns (uint){
        require (ticketsTotal.length > 0 , "No hay personas participantes.");
        uint positionWinner =  uint(uint (keccak256(abi.encodePacked(block.timestamp))) % ticketsTotal.length);
        uint ticketwinner = ticketsTotal[positionWinner];
        address winner = participies[ticketwinner];

        //saldo premio
        uint award = balanceOf(owner);

        //cargamos premio al ganador
        token.transferTokenLottery(owner , winner , award);

        emit congratulationWinnerEvent("felicidades al ganador");
        return ticketwinner;
    }
    function withdrawMoney (uint amount) public payable {
        require (balanceOf(msg.sender) >= amount, "No posees los suficientes tokens");

        token.transferTokenLottery(msg.sender, address(this) , amount);
        payable(msg.sender).transfer(priceTokens (amount));

        emit withdrawMoneyEvent( "La cuenta ", msg.sender, "ha retirado", amount);
    }
}