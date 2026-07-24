# Sistem Basis Data Inventaris Laboratorium

Proyek tugas akhir mata kuliah **Pemrograman Basis Data** — implementasi sistem basis data untuk mengelola inventaris alat/bahan laboratorium, transaksi peminjaman, dan pengembalian barang menggunakan **MySQL / MariaDB (XAMPP)**.

## 📋 Deskripsi

Basis data `db_inventaris_lab` dirancang untuk mencatat dan mengelola:
- Data barang/aset laboratorium beserta kategorinya
- Data laboratorium dan penanggung jawabnya
- Data petugas (laboran) dan peminjam (mahasiswa/dosen/staff)
- Transaksi peminjaman dan pengembalian barang, lengkap dengan perhitungan denda otomatis
- Log audit perubahan data (audit trail)

## 🗂️ Struktur File

Jalankan file-file berikut **secara berurutan** (sesuai penomoran) di MySQL/MariaDB:

| No | File | Deskripsi |
|----|------|-----------|
| 01 | `01_create_database.sql` | Membuat database `db_inventaris_lab` (charset `utf8mb4`) |
| 02 | `02_create_table.sql` | Membuat 9 tabel beserta relasi *foreign key* dan constraint |
| 03 | `03_insert_data_dummy.sql` | Mengisi data awal/dummy untuk kebutuhan pengujian |
| 04 | `04_stored_procedure.sql` | Stored procedure transaksi peminjaman & pengembalian |
| 05 | `05_function.sql` | Function untuk cek stok, hitung denda, dan hitung peminjaman aktif |
| 06 | `06_trigger.sql` | Trigger validasi stok, update stok otomatis, dan audit log |
| 07 | `07_cursor.sql` | Stored procedure dengan CURSOR (pembatalan peminjaman, update status telat, cek stok menipis) |
| 08 | `08_transaction_control.sql` | Demonstrasi COMMIT, ROLLBACK, dan SAVEPOINT |
| 09 | `09_indexing.sql` | Pembuatan index dan perbandingan hasil EXPLAIN sebelum/sesudah |
| 10 | `10_query_laporan.sql` | Kumpulan query dan stored procedure untuk laporan |

## 🧩 Struktur Tabel

1. **kategori_barang** — kategori alat/bahan (Alat Ukur, Alat Gelas, Elektronik, dll.)
2. **laboratorium** — data laboratorium (nama, lokasi, penanggung jawab)
3. **petugas** — data laboran/petugas (username & password login)
4. **peminjam** — data peminjam (mahasiswa/dosen/staff)
5. **barang** — data barang inventaris (stok total, stok tersedia, kondisi, harga)
6. **peminjaman** — header transaksi peminjaman
7. **detail_peminjaman** — rincian barang yang dipinjam per transaksi
8. **pengembalian** — data pengembalian barang beserta denda
9. **audit_log** — pencatatan otomatis perubahan data (INSERT/UPDATE/DELETE)

## ⚙️ Fitur Utama

- **Stored Procedure**: `sp_pinjam_barang`, `sp_proses_pengembalian`, `sp_batalkan_peminjaman`, `sp_update_status_terlambat`, `sp_cek_barang_stok_menipis`, `sp_laporan_peminjaman_periode`
- **Function**: `fn_cek_stok_tersedia`, `fn_hitung_denda` (tarif Rp 2.000/hari/unit), `fn_jumlah_peminjaman_aktif`
- **Trigger**:
  - Validasi stok sebelum peminjaman disimpan
  - Pengurangan stok otomatis saat barang dipinjam
  - Penambahan stok otomatis saat barang dikembalikan
  - Audit log otomatis untuk perubahan tabel `barang` dan `peminjaman`
- **Transaction Control**: `START TRANSACTION`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` (termasuk rollback parsial per item menggunakan cursor)
- **Cursor**: memproses baris data satu per satu (misalnya membatalkan tiap item peminjaman, mengecek status keterlambatan, mengecek stok menipis)
- **Indexing**: index pada `peminjaman.tanggal_pinjam`, `barang.nama_barang`, `peminjaman.status`, `pengembalian.tanggal_kembali` untuk optimasi query
- **Laporan**: rekap stok per kategori/lab, peminjaman aktif, rekap denda, barang terpopuler, riwayat audit log, performa petugas

## 🚀 Cara Menjalankan

### Melalui phpMyAdmin (XAMPP)
1. Buka phpMyAdmin, lalu buka tab **SQL**.
2. Jalankan file satu per satu sesuai urutan nomor (01 → 10), atau gunakan menu **Import** untuk setiap file.

### Melalui terminal / command line
```bash
mysql -u root -p < 01_create_database.sql
mysql -u root -p < 02_create_table.sql
mysql -u root -p < 03_insert_data_dummy.sql
mysql -u root -p < 04_stored_procedure.sql
mysql -u root -p < 05_function.sql
mysql -u root -p < 06_trigger.sql
mysql -u root -p < 07_cursor.sql
mysql -u root -p < 08_transaction_control.sql
mysql -u root -p < 09_indexing.sql
mysql -u root -p < 10_query_laporan.sql
```

> **Catatan:** Seluruh script bersifat *idempotent* (menggunakan `DROP ... IF EXISTS` sebelum `CREATE`), sehingga aman dijalankan ulang dari awal tanpa error.

## 🔍 Contoh Pemanggilan Stored Procedure

```sql
-- Meminjam barang
CALL sp_pinjam_barang(1, 1, 1, 2, DATE_ADD(CURRENT_DATE, INTERVAL 3 DAY), @pesan);
SELECT @pesan;

-- Memproses pengembalian
CALL sp_proses_pengembalian(1, 2, 'baik', @pesan);
SELECT @pesan;

-- Membatalkan peminjaman
CALL sp_batalkan_peminjaman(1, @pesan);
SELECT @pesan;

-- Laporan peminjaman per periode
CALL sp_laporan_peminjaman_periode('2026-01-01', '2026-12-31');
```

## 🛠️ Kebutuhan Sistem

- MySQL 5.7+ atau MariaDB 10.x (disarankan menggunakan **XAMPP**)
- Storage engine **InnoDB** (untuk mendukung foreign key & transaction)

## 📄 Lisensi

Proyek ini dibuat untuk keperluan tugas akhir/akademik.
