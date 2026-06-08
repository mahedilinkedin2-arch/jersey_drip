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

exports.deleteProductAdmin = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
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
    const [cartSnapshot, wishlistSnapshot, productSnapshot] = await Promise.all(
      [
        db.collectionGroup("cart").where("productId", "==", productId).get(),
        db
          .collectionGroup("wishlist")
          .where("productId", "==", productId)
          .get(),
        productRef.get(),
      ],
    );

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

function validateRole(role) {
  return (
    typeof role === "string" && ["user", "admin"].includes(role.toLowerCase())
  );
}

exports.updateUserRoleAdmin = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required to update a user role.",
      );
    }

    const actorUid = context.auth.uid;
    const targetUid = data?.uid;
    const role = data?.role;

    if (!targetUid || typeof targetUid !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid user id must be provided.",
      );
    }

    if (!validateRole(role)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        'Role must be either "user" or "admin".',
      );
    }

    const isAdmin = await verifyAdmin(actorUid);
    if (!isAdmin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Admin privileges are required to update user roles.",
      );
    }

    const normalizedRole = role.toLowerCase();
    const userRef = db.collection("users").doc(targetUid);

    await db.runTransaction(async (transaction) => {
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User does not exist.",
        );
      }

      const currentRole = (userSnap.data()?.role || "user")
        .toString()
        .toLowerCase();
      if (currentRole === "superadmin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Superadmin roles cannot be modified through this endpoint.",
        );
      }

      const isCurrentAdmin = isAdminRole(currentRole);
      const willBeAdmin = isAdminRole(normalizedRole);

      if (isCurrentAdmin && !willBeAdmin) {
        const adminSnapshot = await transaction.get(
          db.collection("users").where("role", "in", ["admin", "superadmin"]),
        );
        const remainingAdmins = adminSnapshot.docs
          .where((doc) => doc.id !== targetUid)
          .where((doc) => {
            const roleValue = (doc.data()?.role || "").toString().toLowerCase();
            return isAdminRole(roleValue);
          }).length;

        if (remainingAdmins === 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Cannot remove the last admin from the system.",
          );
        }
      }

      transaction.update(userRef, { role: normalizedRole });
    });

    return {
      success: true,
      uid: targetUid,
      role: normalizedRole,
    };
  });

exports.updateUserRole = exports.updateUserRoleAdmin;
exports.deleteProduct = exports.deleteProductAdmin;
