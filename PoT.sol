// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ProofOfTransit{

    /* DEV SETTINGS */

    address private controller;
    string private egress_edge;
    string private current_routeID;
    
    mapping(string => string) public probHash;
    mapping(string => logStructure) public route_id_audit;

    struct logStructure{
        uint probeFailAmount;
        uint probeNullAmount;
        uint probeSuccessAmount;
        uint probeTotal;
    }

    struct pastRouteConfig {
        string route_id;
        string egress_edge;
        uint last_timestamp;
    }

    pastRouteConfig[] public routeIdHistory;

    event ControllerSet(address indexed oldController, address indexed newController);

    modifier isController() {
        require(msg.sender == controller, "Caller is not controller");
        _;
    }

    modifier isEgressEdge() {
        require(msg.sender == controller, "Caller is not egress edge");
        _;
    }

    
    constructor(address controllerAddr, string memory egress_edgeAddr,string memory routeId) {
        
        route_id_audit[routeId].probeFailAmount = 0;
        route_id_audit[routeId].probeSuccessAmount = 0;
        route_id_audit[routeId].probeNullAmount = 0;
        route_id_audit[routeId].probeTotal = 0;

        controller = controllerAddr;
        egress_edge = egress_edgeAddr;
        current_routeID = routeId;
        routeIdHistory.push(pastRouteConfig(routeId,egress_edgeAddr,block.timestamp));
        
        emit ControllerSet(address(0), controller);
    }


    /* POT FUNCTIONS */
    function changeController(address newController) public isController {
        emit ControllerSet(controller, newController);
        controller = newController;
    }

    function changeRouteIdAndEgressEdge(string memory newRouteId,string memory newEgressEdge) public isEgressEdge {
        routeIdHistory.push(pastRouteConfig(newRouteId,newEgressEdge,block.timestamp));
        current_routeID = newRouteId;
        egress_edge = newEgressEdge;
    }

    function getController() external view returns (address) {
        return controller;
    }

    function setProbeHash(string memory id_x, string memory hash) public isController {
        probHash[id_x] = hash;
    }

    event ProbeFail();

    function logProbe(string memory id_x,string memory sig) public isEgressEdge{
        if (compareStrings(probHash[id_x],"")) {
            route_id_audit[current_routeID].probeNullAmount += 1;
        } else if (compareStrings(probHash[id_x],sig)){
            route_id_audit[current_routeID].probeSuccessAmount += 1;
        } else {
            route_id_audit[current_routeID].probeFailAmount += 1;
            emit ProbeFail();
        }
        route_id_audit[current_routeID].probeTotal += 1
    }

    function getCompliance() public view returns (uint,uint,uint) {
        return (route_id_audit[current_routeID].probeSuccessAmount,route_id_audit[current_routeID].probeFailAmount,route_id_audit[current_routeID].probeNullAmount);
    }


    /* AUX FUNCTIONS */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}

contract PoTFactory{

    mapping(string => ProofOfTransit) private flowPOT;
    mapping(string => address) public flowAddr;

    function newFlow(string memory flowId, string memory egress_edgeAddr, string memory routeId) public{
        ProofOfTransit new_pot = new ProofOfTransit(msg.sender,egress_edgeAddr,routeId);

        flowPOT[flowId] = new_pot;
        flowAddr[flowId] = address(new_pot);
    }

    function setFlowProbeHash(string memory flowId, string memory id_x, string memory hash) public{
        ProofOfTransit pot = ProofOfTransit(flowPOT[flowId]);
        
        pot.setProbeHash(id_x,hash);
    }


    function setRouteId(string memory flowId,string memory newRouteID, string memory newEgressEdge) public{
        ProofOfTransit pot = ProofOfTransit(flowPOT[flowId]);
        
       
        pot.changeRouteIdAndEgressEdge(newRouteID,newEgressEdge);
    }

    function getFlowCompliance(string memory flowId) public view returns (uint,uint,uint){
        ProofOfTransit pot = ProofOfTransit(flowPOT[flowId]);

        uint success;
        uint fail;
        uint nil;

        (success, fail, nil) = pot.getCompliance();

        return (success, fail, nil);

    }

}
