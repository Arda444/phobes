/**
 * Picks a free Firestore emulator port and runs rules tests via firebase emulators:exec.
 * Avoids "port taken" when a fixed port (e.g. 19080) is already in use.
 */
const net = require("net");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

function getFreePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      server.close((err) => (err ? reject(err) : resolve(port)));
    });
  });
}

async function main() {
  const port = await getFreePort();
  const repoRoot = path.join(__dirname, "..");
  const configPath = path.join(repoRoot, ".firebase-test-config.json");

  const config = {
    firestore: {
      rules: "firestore.rules",
      indexes: "firestore.indexes.json",
    },
    emulators: {
      firestore: { host: "127.0.0.1", port },
      ui: { enabled: false },
    },
  };

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`Firestore emulator port: ${port}`);

  const firebaseCmd = process.platform === "win32" ? "firebase.cmd" : "firebase";
  const testScript = "node rules_test/firestore.rules.test.js";
  const cmd = [
    `"${firebaseCmd}"`,
    `--config "${configPath}"`,
    "emulators:exec",
    "--only firestore",
    `"${testScript}"`,
  ].join(" ");
  const result = spawnSync(cmd, {
    cwd: repoRoot,
    stdio: "inherit",
    shell: true,
  });

  try {
    fs.unlinkSync(configPath);
  } catch (_) {
    /* ignore */
  }

  process.exit(result.status ?? 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
