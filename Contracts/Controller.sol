// SPDX-License-Identifier: MIT
/*

🅂🅃🄰🅁🅂🄴🄴🄳🅂


░██████╗██████╗░░█████╗░░█████╗░███████╗░██████╗████████╗░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
╚█████╗░██████╔╝███████║██║░░╚═╝█████╗░░╚█████╗░░░░██║░░░███████║░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
░╚═══██╗██╔═══╝░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗░░░██║░░░██╔══██║░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝░░░██║░░░██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

Token Rewarding NFT platform.


*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interface with the SpaceStation NFT contracts functions
abstract contract spaceStationInterface {
    function safeMint(address account) virtual external returns (uint256);
    function transferOwnership(address newOwner) virtual external;
    function updateWeight(uint256 tokenId, uint256 increase) virtual external;
}

contract SpaceStation_Control is Context, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SpaceStations{
        uint256 tokenId;            // Id of the SpaceStation NFT
        uint256 class;              // Class of the SpaceStation
        uint256 weight;             // Weight of the SpaceStation
        uint256 lastUpdate;         // number of Stations when last updated.
    }

    struct StationClass{
        uint256 class;              // Space station class PID value
        address contractAddress;    // Address of the classes contract
        uint256 startingWeight;     // Initial Weight used for new mints
        uint256 upgradeRate;        // Rate the weight is increased when more stations are minted
        uint256 price;              // Star cost to mint Space Station
    }

    uint256 emissionRate = 0;       // Star emmission Rate used to ensure prob reward delivery
    uint256 totalMinted = 0;        // Total number of nfts minted. Used as a tracker for all space station classes and used for calculating station upgrades.
    address constant rewardPool = 0x8A4a253f3F3Bd17fF90Ff5b7a6460269b89718c8;    // Address for reward pool. Set at deployment    
    address constant star = 0x99c0b46d0DB69591EB209027D98e3512F2fFe789; //0x8440178087C4fd348D43d0205F4574e0348a06F0;
    uint256 totalWeight = 0;        // Weight of all minted stations
    StationClass[] private stationClasses;  // Array of all the Spation Classes
    SpaceStations[] private spaceStations;   // Tracker for stations used for rewards 

    constructor(uint256 _emissionRate) {
        emissionRate = _emissionRate;

        stationClasses.push(StationClass({
            class:0,
            contractAddress:0x4D4DFB44b026bBCf6449bb499c052CDd4C482CBD,
            startingWeight:1000,
            upgradeRate:10,
            price:1
        }));
        stationClasses.push(StationClass({
            class:1,
            contractAddress:0xf111F03D63bd0D9a7CE3b1F7d22a424569daf338,
            startingWeight:3300,
            upgradeRate:3,
            price:33
        }));
        stationClasses.push(StationClass({
            class:2,
            contractAddress:0x35Fc75cc695E5Ee1587847E5b5dE7C8A8032EA43,
            startingWeight:12000,
            upgradeRate:1,
            price:120
        }));
    }

    // Update the weight of existing SpaceStations
    function updateWeight(uint256 _startId, uint256 _endId) external {
        for (uint256 pid = _startId; pid <= _endId; pid++) {                                            // Cycle through all Spacestations
            if(spaceStations[pid].lastUpdate < totalMinted){                                    // Check that new Nfts have been minted since stations last update
                uint256 newStations = totalMinted.sub(spaceStations[pid].lastUpdate);               // Get the number of new nfts minted since last update
                StationClass memory stationClass = stationClasses[spaceStations[pid].class];        // Get the Station Calsses stats
                uint256 currentWeight = spaceStations[pid].weight;                                  // Get the current weight of the Station
                uint256 upgradeRate = stationClass.upgradeRate;                                     // Fetch upgrade rate for current station
                uint256 newWeight = ((currentWeight.mul(upgradeRate)).div(1000)).mul(newStations);   // Calculate the new weight.

                spaceStations[pid].weight = currentWeight.add(newWeight);                           // Update the ships weight.
                totalWeight = totalWeight.add(newWeight);                                           // Add the new weight to the total weight tracker
                spaceStations[pid].lastUpdate = totalMinted;                                        // Update the lastUpdated ot the new total.
            }
        }
    }

    // Mint requested NFT
    function mintNFT(uint256 _classPID) external{
        StationClass memory station = stationClasses[_classPID];                                // Fetch stats for the requested NFT
        uint256 price = station.price**10*18;                                                   // Convert price to wei
        (bool success) = IERC20(star).transferFrom(_msgSender(), address(this), price);        // Pay for the NFT
        require(success, "Transfer failed.");                                                   // Ensure transfer completed successfully
        spaceStationInterface spaceStationContract = spaceStationInterface(station.contractAddress);   //Create an interface to Stations NFT contract
        uint256 tokenId = spaceStationContract.safeMint(_msgSender());                         // Pay for the NFT
        totalMinted ++;                                                                         // Increase mint count by 1
        spaceStations.push(SpaceStations({                                                      // Add new station to the station array
            tokenId:tokenId,                                                                    // Set new stations tokenId
            class:_classPID,                                                                    // Set the calss of the Station
            weight:station.startingWeight,                                                      // Set the weight of the Station
            lastUpdate:totalMinted                                                              // Set lastUpdate to the current toal minted stations
        }));
        totalWeight = totalWeight.add(station.startingWeight);                                  // Add the Stations weight to the Total Weight tracker
    }

    // Update the emmision rate fo the SpaceStation Stystem
    function updateEmission(uint256 _rate) external onlyOwner{                              
        require(_rate > 0,"Emission must be more then 0");      // Make sure the emmisiion is greater then 0
        emissionRate = _rate;                                   // Set the emmsion rate to the new value
    }

    // Add anew class of Station to the SpaceStation System
    function addClass(StationClass calldata _station )external onlyOwner{
        stationClasses.push(StationClass({                      // Add new station to the SpaceStations array
            class:stationClasses.length,                        // Set the new classes ID to the current length of the array(class is base zero length is base 1)
            contractAddress:_station.contractAddress,           // Set Classes NFT contract address
            startingWeight:_station.startingWeight,             // Set classess starting weight
            upgradeRate:_station.upgradeRate,                   // Set classess upgrade rate
            price:_station.price                                // Set classess mint price
        }));
    }

    //Update a calsses stats
    function updateClassWeight(uint256 _classPid, uint256 _startingWeight)external onlyOwner{
        stationClasses[_classPid].startingWeight = _startingWeight;                             // Update the Starting weight for the class
    }
    function updateClassUpgrade(uint256 _classPid, uint256 _upgradeRate)external onlyOwner{
        stationClasses[_classPid].upgradeRate = _upgradeRate;                                   // Update the Upgrade Rate for the class
    }
    function updateClassPrice(uint256 _classPid, uint256 _price)external onlyOwner{
        stationClasses[_classPid].price = _price;                                               // Update the Price for the class
    }

    // Fetch array of existing stations (used by controller)
    function getStations()external view returns(SpaceStations[] memory){
        return spaceStations;
    }

    // Get current emmsion rate
    function getEmission()external view returns(uint256){
        return emissionRate;
    }

    // Get total weight
    function getWeight()external view returns(uint256){
        return totalWeight;
    }

    // Allow for owner of stations contract change incase of new controller
    function setStationOwner(address _newOwner)external onlyOwner {
        for(uint256 classId =0; classId < stationClasses.length; classId++){
            spaceStationInterface spaceStationContract = spaceStationInterface(stationClasses[classId].contractAddress);   //Create an interface to Stations NFT contract
            spaceStationContract.transferOwnership(_newOwner);
        }
    }

    // Allow for owner of stations contract change incase of new controller
    function updateNftWeight(uint256 classId, uint256 tokenId,uint256 increase)external onlyOwner {
        spaceStationInterface spaceStationContract = spaceStationInterface(stationClasses[classId].contractAddress);   //Create an interface to Stations NFT contract
        spaceStationContract.updateWeight(tokenId,increase);
    }
}