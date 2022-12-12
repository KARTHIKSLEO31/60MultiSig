async function deployContract() {
  const Multi = await ethers.getContractFactory("multi")
  const Multi60 = await Multi.deploy()
  await Multi60.deployed()
  const txHash = Multi60.deployTransaction.hash
  const txReceipt = await ethers.provider.waitForTransaction(txHash)
  const contractAddress = txReceipt.contractAddress
  console.log("Contract deployed to address:", contractAddress)
 }
 
deployContract()
.then(() => process.exit(0))
.catch((error) => {
 console.error(error);
 process.exit(1);
});