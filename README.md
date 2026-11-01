# Brave Hardening for Linux

Kumpulan policy terkelola untuk Brave Browser di Omarchy / Arch Linux. File JSON sengaja dipisahkan dari script instalasi, sehingga nilai policy dapat diedit tanpa mengubah mekanisme install/uninstall.

## Isi konfigurasi

| Policy | Nilai | Tujuan |
|---|---:|---|
| `BraveRewardsDisabled` | `true` | Menonaktifkan Brave Rewards |
| `BraveWalletDisabled` | `true` | Menonaktifkan Brave Wallet |
| `BraveVPNDisabled` | `true` | Menonaktifkan integrasi Brave VPN |
| `BraveAIChatEnabled` | `false` | Menonaktifkan Leo |
| `BraveNewsDisabled` | `true` | Menonaktifkan Brave News |
| `BravePlaylistEnabled` | `false` | Menonaktifkan Playlist |
| `PasswordManagerEnabled` | `false` | Mematikan password manager bawaan karena menggunakan pengelola eksternal |
| `BraveP3AEnabled` | `"Disabled"` | Menonaktifkan P3A |
| `BraveStatsPingEnabled` | `0` | Menonaktifkan daily/statistics ping |
| `BraveWebDiscoveryEnabled` | `0` | Menonaktifkan Web Discovery Project |
| `MetricsReportingEnabled` | `false` | Menonaktifkan pelaporan metrik Chromium |

Policy Brave memakai tipe nilai yang berbeda-beda. Jangan mengubah semuanya menjadi `true`/`false`; khususnya `BraveP3AEnabled` memakai string `"Disabled"`, sedangkan Stats Ping dan Web Discovery memakai angka `0` menurut dokumentasi Brave.

## Persyaratan

- Brave Browser native terpasang (bukan hanya Flatpak).
- `python3` untuk memvalidasi JSON.
- `curl` saat menjalankan installer langsung dari URL.
- `sudo` untuk memasang policy ke `/etc` dan menyimpan backup di `/var/lib`.

Script akan menolak instalasi jika yang terdeteksi hanya Brave Flatpak. Brave Flatpak berada di sandbox dan tidak boleh diasumsikan membaca policy host di `/etc/brave/policies/managed/`.

## Instalasi

**Metode cepat (tanpa clone repository):**

```bash
curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/main/install.sh | bash
```

Untuk menggunakan versi rilis tertentu, pin ref ke tag rilis. Contoh setelah tag `v1.0.0` tersedia:

```bash
OMARCHY_BRAVE_POLICY_REF=v1.0.0 bash <(curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/v1.0.0/install.sh)
```

**Metode clone / instalasi lokal:**

```bash
git clone https://github.com/slvinnm/brave-hardening-for-linux.git
cd brave-hardening-for-linux
chmod +x install.sh uninstall.sh
./install.sh
```

Script lokal menggunakan `brave-policy.json` yang berada di direktori yang sama. Jika dijalankan melalui `curl | bash`, script mengunduh JSON dari repository. Variabel `OMARCHY_BRAVE_POLICY_REF` dapat digunakan untuk memilih branch atau tag sumber JSON.

> Catatan keamanan: `curl | bash` mengeksekusi script yang diunduh. Periksa isi `install.sh` terlebih dahulu jika ingin meninjau perubahan yang akan dilakukan.

Tutup lalu buka kembali Brave, atau restart Brave jika masih berjalan.

## Verifikasi

Buka alamat berikut di Brave:

- `brave://policy` — klik **Reload policies**, lalu pastikan policy terdaftar dan tidak memiliki error.
- `brave://management` — policy lokal dapat membuat browser menampilkan status dikelola.

Policy hanya diterapkan setelah browser memuatnya kembali. Jika satu policy tidak muncul atau berstatus error, periksa versi Brave dan tipe nilai policy.

## Uninstall / rollback

```bash
curl -fsSL https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/main/uninstall.sh | bash
```

Atau jalankan `./uninstall.sh` dari hasil clone repository.

Script hanya menghapus file policy milik project ini. Jika file dengan nama tujuan sudah ada sebelum instalasi pertama, script menyimpan salinan aslinya di `/var/lib/omarchy-brave-policy/` dan mengembalikannya saat uninstall.

Script tidak menghapus file policy lain, tidak menghapus direktori yang masih berisi file lain, dan tidak mengubah profil atau data browsing Brave.

## Kustomisasi

Edit `brave-policy.json`, validasi dengan:

```bash
python3 -m json.tool brave-policy.json
```

Kemudian jalankan kembali `./install.sh` dan reload policy di `brave://policy`.

## Batasan

- Policy ini tidak mengatur seluruh preferensi privasi browser. Atur Shields, fingerprinting protection, Safe Browsing, dan site permissions melalui GUI Brave.
- Mematikan password manager bawaan tidak memasang atau mengonfigurasi password manager eksternal.
- Policy mengunci beberapa fitur sampai policy dihapus; ini berbeda dari sekadar menyembunyikan ikon toolbar.
- Brave memperbarui daftar policy dan tipe nilainya dari waktu ke waktu. Rujuk dokumentasi resmi sebelum menambah policy baru.

Dokumentasi: https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
