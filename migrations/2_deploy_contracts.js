const MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = function (deployer) {
  deployer.deploy(MultiSigWallet, '0xf55be7a87b8633b3a8f49aa606a113fc468fdbb7', '0x8f9f952dd592e06d13afabdbef9a80ba92a9d810', '0x82e6eebba518b2a10e65d17a27baab35e0683614', 2
  );
};
