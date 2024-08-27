/**
 *Submitted for verification at BscScan.com on 2022-12-23
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org


// SPDX-License-Identifier: MIT
// Info: https://bscscan.com/address/0x505751023083BfC7D2AFB0588717dCC6182e54B2#readProxyContract
// Source codes: https://bscscan.com/address/0x9b8e1c29f1ae9d581a708d7bb8c232585e3aadd9#code

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// File contracts/interfaces/ISafeswapFactory.sol
import {ISafeswapFactory} from "./interfaces/ISafeswapFactory.sol";

// File contracts/interfaces/ISafeswapPair.sol
import {ISafeswapPair} from "./ISafeswapPair.sol";

// File contracts/interfaces/ISafeswapERC20.sol
import {ISafeswapERC20} from "./ISafeswapERC20.sol";

// File contracts/SafeswapERC20.sol
import {SafeswapERC20} from "./SafeswapERC20.sol";

// File contracts/libraries/Initializable.sol
import {Initializable} from "./libraries/Initializable.sol";

// File contracts/libraries/Math.sol
import {Math} from "./libraries/Math.sol";

// File contracts/libraries/UQ112x112.sol
import {UQ112x112} from "./libraries/UQ112x112.sol";

// File contracts/interfaces/IERC20.sol
import {IERC20} from "./interfaces/IERC20.sol";

// File contracts/interfaces/ISafeswapCallee.sol
import {ISafeswapCallee} from "./interfaces/ISafeswapCallee.sol";

// File contracts/SafeswapPair.sol
import {SafeswapPair} from "./SafeswapPair.sol";

// File contracts/libraries/proxy/Proxy.sol


/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}


// File @openzeppelin/contracts/utils/Address.sol@v4.7.3

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/libraries/proxy/UpgradeableProxy.sol


/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * factory address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * factory behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial factory specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    function _UpgradeableProxy_init_(address _factory, bytes memory _data) internal {
        assert(_FACTORY_SLOT == bytes32(uint256(keccak256("eip1967.proxy.factoryfactory")) - 1));
        _setFactory(_factory);
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            address impl = ISafeswapFactory(_factory).implementation();
            (bool success, ) = impl.delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Emitted when the factory is upgraded.
     */
    event Upgraded(address indexed factory);

    /**
     * @dev Storage slot with the address of the current factory.
     * This is the keccak-256 hash of "eip1967.proxy.factoryfactory" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _FACTORY_SLOT = 0xb2101b231486a8a17a16c101f8dde1145d21799358462f57035a227f25614da3;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address impl) {
        address factory;
        bytes32 slot = _FACTORY_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            factory := sload(slot)
        }

        // call to Factory and get Impl
        impl = ISafeswapFactory(factory).implementation();
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newFactory) internal {
        _setFactory(newFactory);
        emit Upgraded(newFactory);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setFactory(address newFactory) private {
        require(Address.isContract(newFactory), "UpgradeableProxy: new factory is not a contract");

        bytes32 slot = _FACTORY_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newFactory)
        }
    }
}


// File contracts/libraries/proxy/OptimizedTransparentUpgradeableProxy.sol


/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative inerface of your proxy.
 */
contract OptimizedTransparentUpgradeableProxy is UpgradeableProxy, Initializable {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    function _OptimizedTransparentUpgradeableProxy_init_(
        address factory,
        address initialAdmin,
        bytes memory _data
    ) external initializer {
        _UpgradeableProxy_init_(factory, _data);

        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        bytes32 slot = _ADMIN_SLOT;

        // still store it to work with EIP-1967
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, initialAdmin)
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newFactory) external ifAdmin {
        _upgradeTo(newFactory);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newFactory, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newFactory);
        address newImplementation = _implementation();
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}


// File contracts/SafeswapFactory.sol
contract SafeswapFactory is ISafeswapFactory, Initializable {
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(OptimizedTransparentUpgradeableProxy).creationCode));

    address public feeTo;
    address public feeToSetter;
    address public router;
    address public admin;

    mapping(address => bool) public isBlacklistedStatus;
    mapping(address => bool) public approvePartnerStatus;
    mapping(address => bool) public isBlacklistedToken;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    address public implementation;

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function initialize(address _feeToSetter, address _feeTo) external initializer {
        feeToSetter = _feeToSetter;
        feeTo = _feeTo;
        admin = msg.sender;
    }

    function setImplementation(address _impl) external onlyOwner {
        require(_impl != address(0), "Not allow zero address");
        implementation = _impl;
    }

    function deployImplementation() external onlyOwner {
        implementation = address(new SafeswapPair());
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address to
    ) public returns (address pair) {
        require(implementation != address(0), "Please set implementation");
        require((isBlacklistedToken[tokenA] == false), "Cannot create with tokenA");
        require((isBlacklistedToken[tokenB] == false), "Cannot create with tokenB");
        require((approvePartnerStatus[to] == true), "Not approved the partner");
        require((approvePartnerStatus[msg.sender] == true), "Not approved the partner");

        require(tokenA != tokenB, "Safeswap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Safeswap: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Safeswap: PAIR_EXISTS"); // single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        OptimizedTransparentUpgradeableProxy pairProxy = new OptimizedTransparentUpgradeableProxy{ salt: salt }();
        pairProxy._OptimizedTransparentUpgradeableProxy_init_(
            address(this),
            address(0x000000000000000000000000000000000000dEaD),
            hex""
        );
        pair = address(pairProxy);
        ISafeswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setPair(
        address tokenA,
        address tokenB,
        address to,
        address pair) public {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        ISafeswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
    function setRouter(address _router) public {
        require(msg.sender == admin, "NOT AUTHORIZED");
        router = _router;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "Safeswap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "Safeswap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function blacklistAddress(address account) external onlyOwner {
        require((isBlacklistedStatus[account] == false), "Already Blacklisted");
        isBlacklistedStatus[account] = true;
    }

    function unBlacklistAddress(address account) external onlyOwner {
        require((isBlacklistedStatus[account] == true), "Already Not Blacklisted");
        isBlacklistedStatus[account] = false;
    }

    function blacklistTokenAddress(address token) external onlyOwner {
        require((isBlacklistedToken[token] == false), "Already Blacklisted");
        isBlacklistedToken[token] = true;
    }

    function whitelistTokenAddress(address token) external onlyOwner {
        require((isBlacklistedToken[token] == true), "Already Whitelisted");
        isBlacklistedToken[token] = false;
    }

    function approveLiquidityPartner(address account) external onlyOwner {
        require((approvePartnerStatus[account] == false), "Already approved");
        approvePartnerStatus[account] = true;
    }

    function unApproveLiquidityPartner(address account) external onlyOwner {
        require((approvePartnerStatus[account] == true), "Not approved yet");
        approvePartnerStatus[account] = false;
    }
}