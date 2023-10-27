// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

/**
REPETIBLE CON LÍMITE, PREMIO POR REFERIDO

* El usuario puede participar en el airdrop una vez por día hasta un límite de 10 veces
* Si un usuario participa del airdrop a raíz de haber sido referido, el que refirió gana 3 días adicionales para poder participar
* El contrato Airdrop mantiene los tokens para repartir (no llama al `mint` )
* El contrato Airdrop tiene que verificar que el `totalSupply`  del token no sobrepase el millón
* El método `participateInAirdrop` le permite participar por un número random de tokens de 1000 - 5000 tokens
*/

interface IMiPrimerTKN {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropTwo is Pausable, AccessControl {
    // instanciamos el token en el contrato
    IMiPrimerTKN miPrimerToken;

    struct Participante{
        address usuario;
        uint8 totalParticipaciones;
        uint16 limiteParticipaciones;
        bool participacionDia;
        uint inicio;
    }
    
    mapping(address=>Participante) public participantes;
    uint public constant maxSupply = 10**6*10**18;
    uint totalSupply;

    modifier totalSupplyTop(){
        require(totalSupply<maxSupply);
        _;
    }
    modifier limiteParticipaciones(){
        if(participantes[msg.sender].totalParticipaciones == 0){
            inicializar();
        }
        require(participantes[msg.sender].totalParticipaciones<participantes[msg.sender].limiteParticipaciones, "Llegaste limite de participaciones");
        _;
    }
    modifier participoDia(){
        Participante storage participante = participantes[msg.sender];
        if(participante.inicio+(1 days)<=block.timestamp){
            actualizarParticipacion();
        }
        require(!participantes[msg.sender].participacionDia, "Ya participaste en el ultimo dia");
        _;
    }
    modifier noUnoMismo(address _elQueRefirio){
        require(msg.sender!=_elQueRefirio, "No puede autoreferirse");
        _;
    }

    constructor(address) { 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function inicializar() internal{
        Participante storage participante = participantes[msg.sender];
        participante.usuario = msg.sender;
        participante.limiteParticipaciones = 10;
        participante.inicio = block.timestamp; 
    }

    function actualizarParticipacion() internal{
        Participante storage participante = participantes[msg.sender];
        participante.participacionDia=false;
        participante.inicio=block.timestamp;
    }

    function participateInAirdrop() public totalSupplyTop limiteParticipaciones participoDia {
        uint amount = _getRadomNumber10005000();
        require(miPrimerToken.balanceOf(address(this))>=amount,"El contrato Airdrop no tiene tokens suficientes");
        Participante storage participante = participantes[msg.sender];
        totalSupply+=amount;
        participantes[msg.sender].totalParticipaciones++;
        participante.participacionDia=true;
        bool success = miPrimerToken.transfer(msg.sender, amount);
        require(success);
    }

    function participateInAirdrop(address _elQueRefirio) public totalSupplyTop limiteParticipaciones participoDia noUnoMismo(_elQueRefirio){
        uint amount = _getRadomNumber10005000();
        require(miPrimerToken.balanceOf(address(this))>=amount,"El contrato Airdrop no tiene tokens suficientes");
        Participante storage participante = participantes[msg.sender];
        totalSupply+=amount;
        participantes[msg.sender].totalParticipaciones++;
        participante.participacionDia=true;
        if(participantes[_elQueRefirio].limiteParticipaciones==0){
            participantes[_elQueRefirio].limiteParticipaciones=10;
        }
        participantes[_elQueRefirio].limiteParticipaciones+=3;
        bool success = miPrimerToken.transfer(msg.sender, amount);
        require(success);
    }

    ///////////////////////////////////////////////////////////////
    ////                     HELPER FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function _getRadomNumber10005000() internal view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                4000) +
            1000 +
            1;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function transferTokensFromSmartContract()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        miPrimerToken.transfer(
            msg.sender,
            miPrimerToken.balanceOf(address(this))
        );
    }

}
