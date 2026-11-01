# Brave Hardening for Linux

A managed policy set for Brave Browser on Omarchy and Arch Linux. The policy JSON is kept separate from the installation scripts so users can customize browser behavior without modifying the installer.

## Included policies

| Policy | Value | Purpose |
|---|---:|---|
| `BraveRewardsDisabled` | `true` | Disables Brave Rewards |
| `BraveWalletDisabled` | `true` | Disables Brave Wallet |
| `BraveVPNDisabled` | `true` | Disables Brave VPN integration |
| `BraveAIChatEnabled` | `false` | Disables Brave Leo |
| `BraveNewsDisabled` | `true` | Disables Brave News |
| `BraveTalkDisabled` | `"Enabled"` | Disables Brave Talk |
| `BravePlaylistEnabled` | `false` | Disables Brave Playlist |
| `TorDisabled` | `true` | Disables Tor windows |
| `PasswordManagerEnabled` | `false` | Disables the built-in password manager |
| `BraveP3AEnabled` | `"Disabled"` | Disables Privacy-Preserving Product Analytics |
| `BraveStatsPingEnabled` | `0` | Disables Brave's statistics ping |
| `BraveWebDiscoveryEnabled` | `0` | Disables the Web Discovery Project |
| `UrlKeyedAnonymizedDataCollectionEnabled` | `false` | Disables URL-keyed anonymized data collection |
| `SafeBrowsingExtendedReportingEnabled` | `false` | Disables additional Safe Browsing reporting |
| `MetricsReportingEnabled` | `false` | Disables Chromium metrics reporting |

Policy values do not all use the same data type. For example, `BraveP3AEnabled` accepts the string `"Enabled"` or `"Disabled"`, while `BraveStatsPingEnabled` and `BraveWebDiscoveryEnabled` use numeric values. Do not copy Windows registry DWORD values into the Linux JSON file without checking the policy's Linux/JSON type.

## ⚠️ Warning: Built-in Password Manager is disabled

This configuration sets `PasswordManagerEnabled` to `false`. As a result, Brave's built-in password manager is disabled by policy.

- Make sure you already use another password manager before installing this policy.
- If you want to keep using Brave's built-in password manager, open `brave-policy.json` and either remove the `"PasswordManagerEnabled": false,` line or change its value to `true`.
- Save the file and run the installer again. Then reload policies at `brave://policy` and restart Brave if needed.

**Do not install this configuration without reviewing this setting first.** The installer does not migrate, export, or back up passwords stored in Brave.

## Requirements

- A native Brave Browser installation (not Flatpak-only).
- `python3` to validate the policy JSON.
- `curl` when running the installer directly from a URL.
- `sudo` to install policies under `/etc` and store backups under `/var/lib`.

The installer refuses to proceed if it detects only Brave Flatpak. Flatpak runs in a sandbox, so this project does not assume that a host policy directory under `/etc/brave/policies/managed/` will be read by the Flatpak build.

## Installation

### Quick install (no repository clone)

```bash
curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/main/install.sh | bash
```

To install from a specific release tag, pin the script and policy source to that tag. For example, after publishing `v1.0.0`:

```bash
OMARCHY_BRAVE_POLICY_REF=v1.0.0 bash <(curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/v1.0.0/install.sh)
```

### Install from a local clone

```bash
git clone https://github.com/slvinnm/brave-hardening-for-linux.git
cd brave-hardening-for-linux
chmod +x install.sh uninstall.sh
./install.sh
```

When run from a local clone, the installer uses the adjacent `brave-policy.json`. When run through `curl | bash`, it downloads the policy JSON from this repository. Set `OMARCHY_BRAVE_POLICY_REF` to select a branch or tag for the downloaded policy.

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

The uninstaller removes only this project's policy file. If a file already existed at the target path before the first installation, the installer stores a copy under `/var/lib/omarchy-brave-policy/` and the uninstaller restores it.

The scripts do not remove other policy files, do not remove non-empty directories, and do not modify your Brave profile or browsing data.

## Customize policies

Edit `brave-policy.json` before installation. Validate the JSON with:

```bash
python3 -m json.tool brave-policy.json
```

Then run `./install.sh` again and reload policies at `brave://policy`.

## Scope and limitations

- This project does not configure every browser privacy setting. Configure Shields, fingerprinting protection, Safe Browsing, and site permissions separately in Brave.
- Disabling the built-in password manager does not install or configure an alternative password manager.
- Managed policies enforce settings; this is not the same as hiding toolbar buttons.
- Brave may change policy names, accepted values, or minimum supported versions. Review the official documentation before adding or changing policies.

## References

- [Brave Group Policy documentation](https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy)
- [Chromium Enterprise Policy List](https://chromeenterprise.google/policies/)

