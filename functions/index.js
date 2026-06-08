const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

function isAdminRole(role) {
  return (
    typeof role === "string" &&
    ["admin", "superadmin"].includes(role.toLowerCase())
  );
}

async function verifyAdmin(uid) {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    return false;
  }
  const role = userDoc.data()?.role;
  return isAdminRole(role);
}

function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

exports.deleteProductAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication is required to delete a product.",
    );
  }

  const uid = context.auth.uid;
  const productId = data?.productId;

  if (!productId || typeof productId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a valid productId.",
    );
  }

  const isAdmin = await verifyAdmin(uid);
  if (!isAdmin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin privileges are required to delete a product.",
    );
  }

  const productRef = db.collection("products").doc(productId);
  const [cartSnapshot, wishlistSnapshot, productSnapshot] = await Promise.all([
    db.collectionGroup("cart").where("productId", "==", productId).get(),
    db.collectionGroup("wishlist").where("productId", "==", productId).get(),
    productRef.get(),
  ]);

  const referencesToDelete = [];
  if (productSnapshot.exists) {
    referencesToDelete.push(productRef);
  }
  cartSnapshot.docs.forEach((doc) => referencesToDelete.push(doc.ref));
  wishlistSnapshot.docs.forEach((doc) => referencesToDelete.push(doc.ref));

  const chunks = chunkArray(referencesToDelete, 500);
  for (const chunk of chunks) {
    const batch = db.batch();
    chunk.forEach((ref) => batch.delete(ref));
    await batch.commit();
  }

  return {
    success: true,
    deletedProduct: productSnapshot.exists,
    deletedCartDocuments: cartSnapshot.size,
    deletedWishlistDocuments: wishlistSnapshot.size,
  };
});
