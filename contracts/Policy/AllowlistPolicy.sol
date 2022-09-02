//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./Policy.sol";
import "../interfaces/ICNSController.sol";

contract AllowlistPolicy is Policy {
    constructor(
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr,
        address _cnsControllerAddr
    ) Policy(_ensAddr, _baseRegistrarAddr, _resolverAddr, _cnsControllerAddr) {
        require(_ensAddr != address(0), "Invalid address");
        require(_baseRegistrarAddr != address(0), "Invalid address");
        require(_resolverAddr != address(0), "Invalid address");
        require(_cnsControllerAddr != address(0), "Invalid address");
    }

    mapping(bytes32 => address[]) public allowList;
    mapping(bytes32 => address) internal historyMints;
    mapping(bytes32 => bytes32) internal registeredSubdomains;

    function addAllowlist(bytes32 _node, address _allowAddress) public {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ),
            "Only owner can add Allowlist"
        );
        require(!permissionCheck(_node, _allowAddress), "Already in Allowlist");
        _addAllowlist(_node, _allowAddress);
    }

    function addMultiAllowlist(bytes32 _node, address[] memory _allowAddress)
        public
    {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ),
            "Only owner can add Allowlist"
        );
        for (uint256 i = 0; i < _allowAddress.length; ) {
            _addAllowlist(_node, _allowAddress[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _addAllowlist(bytes32 _node, address _allowAddress) internal {
        allowList[_node].push(_allowAddress);
    }

    function removeAllowlist(bytes32 _node, address _allowAddress) public {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ),
            "Only owner can add Allowlist"
        );
        _removeAllowlist(_node, _allowAddress);
    }

    function _removeAllowlist(bytes32 _node, address _allowAddress) internal {
        for (uint256 i = 0; i < allowList[_node].length; ) {
            if (allowList[_node][i] == _allowAddress) {
                delete allowList[_node][i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function permissionCheck(bytes32 _node, address _account)
        public
        view
        virtual
        returns (bool)
    {
        for (uint256 i = 0; i < allowList[_node].length; ) {
            if (
                allowList[_node][i] == _account &&
                historyMints[_node] != _account
            ) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function getAllowlist(bytes32 _node)
        public
        view
        returns (address[] memory)
    {
        return allowList[_node];
    }

    function registerSubdomain(
        string memory _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(
            (permissionCheck(_node, msg.sender) ||
                cnsController.isDomainOwner(
                    cnsController.getTokenId(_node),
                    msg.sender
                )),
            "Permission denied"
        );
        cnsController.registerSubdomain(
            _subdomainLabel,
            _node,
            _subnode,
            msg.sender
        );
        historyMints[_node] = msg.sender;
    }

    function unRegisterSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(
            (historyMints[_node] == msg.sender) ||
                (
                    cnsController.isDomainOwner(
                        cnsController.getTokenId(_node),
                        msg.sender
                    )
                ),
            "Not owner of this subdomain"
        );
        cnsController.unRegisterSubdomain(_subDomainLabel, _node, _subnode);
        delete historyMints[_node];
    }
}
