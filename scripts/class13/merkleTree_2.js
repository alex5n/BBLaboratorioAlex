const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers } = require("hardhat");
const walletAndIds = require("../../utils/walletAndIds");

var merkleTree, root;
function hashToken(tokenId, account) {
  return Buffer.from(
    ethers
      .solidityPackedKeccak256(["uint256", "address"], [tokenId, account])
      .slice(2),
    "hex"
  );
}

function construyendoMerkleTree() {
  var elementosHasheados = walletAndIds.map(({ tokenId, account }) => {
    return hashToken(tokenId, account);
  });
  merkleTree = new MerkleTree(elementosHasheados, keccak256, {
    sortPairs: true,
  });

  root = merkleTree.getHexRoot();

  console.log(root);
}

var hasheandoElemento, pruebas;
function construyendoPruebas() {
  var tokenId = 7;
  var account = "0x00b7cda410001f6e52a7f19000b3f767ec8aec7d";
  hasheandoElemento = hashToken(tokenId, account);
  pruebas = merkleTree.getHexProof(hasheandoElemento);
  console.log(pruebas);

  // verificacion off-chain
  var pertenece = merkleTree.verify(pruebas, hasheandoElemento, root);
  console.log(pertenece);
}

async function main() {
  var merkleTreeContract = await ethers.deployContract("MerkleTree");
  await merkleTreeContract.actualizarRaiz(root);

  var perteneceLibreria = await merkleTreeContract.verify(
    hasheandoElemento,
    pruebas
  );
  console.log(`Libreria: ${perteneceLibreria}`);

  var perteneceAMano = await merkleTreeContract.verifyMerkleProof(
    hasheandoElemento,
    pruebas
  );
  console.log(`A mano: ${perteneceAMano}`);

  // Una persona en el futuro quiere hacer mint
  var tokenId = 7;
  var account = "0x00b7cda410001f6e52a7f19000b3f767ec8aec7d";
  await merkleTreeContract.safeMint(account, tokenId, pruebas);
}

construyendoMerkleTree();
construyendoPruebas();
main();
