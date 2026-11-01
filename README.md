# Brave Hardening for Linux

A managed policy configuration for Brave Browser on Linux. The policy JSON is kept separate from the installation scripts so users can customize browser behavior without modifying the installer.

The project targets native Brave installations and uses Brave's managed policy directory. It is not tied to a specific Linux distribution or desktop environment.

## Included policies

| Policy | Value | Purpose |
|---|---:|---|
| `BraveRewardsDisabled` | `true` | Disables Brave Rewards and its associated features |
| `BraveWalletDisabled` | `true` | Disables the built-in Brave Wallet and related Web3 functionality |
| `BraveVPNDisabled` | `true` | Disables Brave VPN integration |
| `BraveAIChatEnabled` | `false` | Disables Brave Leo AI assistant |
| `BraveNewsDisabled` | `true` | Disables the Brave News feed |
| `BraveTalkDisabled` | `true` | Disables Brave Talk video conferencing |
| `BravePlaylistEnabled` | `false` | Disables Brave Playlist |
| `TorDisabled` | `true` | Disables Tor private windows |
| `PasswordManagerEnabled` | `false` | Disables the built-in password manager |
| `BraveP3AEnabled` | `false` | Disables Privacy-Preserving Product Analytics (P3A) |
| `BraveStatsPingEnabled` | `false` | Disables Brave's daily usage statistics ping |
| `BraveWebDiscoveryEnabled` | `false` | Disables participation in the Brave Web Discovery Project |
| `UrlKeyedAnonymizedDataCollectionEnabled` | `false` | Disables URL-keyed anonymized data collection |
| `MetricsReportingEnabled` | `false` | Disables Chromium usage and crash-related metrics reporting |
| `CloudReportingEnabled` | `false` | Disables cloud reporting to the Chrome Enterprise management service |
| `SafeBrowsingSurveysEnabled` | `false` | Prevents users from receiving Safe Browsing-related surveys |

### Policy value types

All policy values in this configuration use JSON boolean values (`true` or `false`).

## ⚠️ Warning: Built-in Password Manager is disabled

This configuration sets `PasswordManagerEnabled` to `false`. As a result, Brave's built-in password manager is disabled by policy.

- Make sure you already use another password manager before installing this policy.
- If you want to keep using Brave's built-in password manager, open `brave-policy.json` and either remove the `"PasswordManagerEnabled": false,` line or change its value to `true`.
- Save the file and run the installer again. Then reload policies at `brave://policy` and restart Brave if needed.

**Do not install this configuration without reviewing this setting first.** The installer does not migrate, export, or back up passwords stored in Brave.


## Installation

### Quick install (no repository clone)

```bash
curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/main/install.sh | bash
```

### Install from a local clone

```bash
git clone https://github.com/slvinnm/brave-hardening-for-linux.git
cd brave-hardening-for-linux
chmod +x install.sh uninstall.sh
./install.sh
```

When run from a local clone, the installer uses the adjacent `brave-policy.json`. When run through `curl | bash`, it downloads the policy JSON from this repository. Set `BRAVE_POLICY_REF` to select a branch or tag for the downloaded policy.

> **Security note:** Piping a remote script to Bash executes code from that URL. Review `install.sh` before running it if you want to inspect the changes first.

Restart Brave after installation so the browser loads the managed policies.

## Verify policies

Open these pages in Brave:

- `brave://policy` — click **Reload policies** and check that the policies appear without errors.
- `brave://management` — shows whether Brave detects managed policies.

If a policy is missing or reports an error, check your Brave version and the expected policy value type. Some Brave-specific policies are only available in newer browser versions.

## Uninstall / rollback

```bash
curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/main/uninstall.sh | bash
```

Or run `./uninstall.sh` from your local clone.

The uninstaller removes only this project's policy file. If a file already existed at the target path before the first installation, the installer stores a copy under `/var/lib/brave-hardening/` and the uninstaller restores it.

The installer and uninstaller also recognize the previous project-specific policy and backup locations so an upgrade does not leave the old managed policy active.

The scripts do not remove other policy files, do not remove non-empty directories, and do not modify your Brave profile or browsing data.

## Scope and limitations

- This project does not configure every browser privacy setting. Configure Shields, fingerprinting protection, Safe Browsing, and site permissions separately in Brave.
- Disabling the built-in password manager does not install or configure an alternative password manager.
- Managed policies enforce settings; this is not the same as hiding toolbar buttons.
- Brave may change policy names, accepted values, or minimum supported versions. Review the official documentation before adding or changing policies.

## References

- [Brave Group Policy documentation](https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy)
- [Chromium Enterprise Policy List](https://chromeenterprise.google/policies/)
