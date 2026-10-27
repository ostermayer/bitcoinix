# Deploying with Colmena

This example deploys a bitcoinix node with [Colmena](https://github.com/nix-community/colmena)
([manual](https://colmena.cli.rs/unstable/)). CI builds it on every pull request, so it
works with the current bitcoinix.

The hive in [`flake.nix`](flake.nix) defines one node, `fullnode`: the
[secure-node preset](../../modules/presets/secure-node.nix) with bitcoind, clightning with
clnrest, RTL, mempool with fulcrum, an nginx reverse proxy for mempool, and backups.

| File | Contents |
|---|---|
| [`flake.nix`](flake.nix) | inputs, the hive, and a dev shell with `colmena` |
| [`nixos/common.nix`](nixos/common.nix) | settings for every node: Nix, SSH, users |
| [`nixos/configs/fullnode/configuration.nix`](nixos/configs/fullnode/configuration.nix) | the bitcoinix services |
| [`nixos/configs/fullnode/hardware-configuration.nix`](nixos/configs/fullnode/hardware-configuration.nix) | disks and boot loader of a QEMU VM |

## Usage

1. Copy this directory and adapt it. Look for `FIXME` and placeholders like `<your_pubkey>`:
   - the root SSH keys in `nixos/common.nix`
   - `deployment.targetHost` in `flake.nix`
   - the interface names, the mempool domain and the ACME e-mail address in `configuration.nix`
   - replace `hardware-configuration.nix` with the output of `nixos-generate-config` on your node

2. Pin `bitcoinix` in `flake.nix` to the latest release tag and verify that tag
   (see [Installation](../../docs/install.md)). Commit the `flake.lock` that Nix creates.

3. Optional: use the bitcoinix binary cache with `cachix use bitcoinix`.

4. Enter the dev shell with `nix develop` (or `direnv allow`) and deploy:

   ```shell
   colmena build --on fullnode            # build only
   colmena apply --on fullnode boot       # activate on the next boot
   ssh root@fullnode.example.com reboot
   ```

   Use `switch` instead of `boot` to activate the new configuration at once.
   `buildOnTarget = true` builds on the node, which also allows deploying from macOS.

bitcoinix generates its own secrets on the node (`nix-bitcoin.generateSecrets`), in
`/etc/nix-bitcoin-secrets`. Back them up.
