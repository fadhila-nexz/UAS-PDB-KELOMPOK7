-- ============================================================
-- FILE : 09_indexing.sql  (Indexing & Optimasi Query)
-- Membandingkan hasil EXPLAIN sebelum dan sesudah pembuatan index.
-- ============================================================
USE db_inventaris_lab;

-- CATATAN PENTING:
-- Kolom id_peminjam dan id_barang TIDAK dipakai sebagai contoh
-- di sini karena InnoDB otomatis membuat index pada kolom
-- FOREIGN KEY, sehingga perbandingan sebelum/sesudah index
-- menjadi tidak representatif. Sebagai gantinya, index dibuat
-- pada kolom yang murni belum terindeks:
-- peminjaman.tanggal_pinjam dan barang.nama_barang.

-- ------------------------------------------------------------
-- A. EXPLAIN SEBELUM INDEX dibuat (full table scan)
-- ------------------------------------------------------------
EXPLAIN SELECT * FROM peminjaman WHERE tanggal_pinjam = CURRENT_DATE;
EXPLAIN SELECT * FROM barang WHERE nama_barang = 'Router Mikrotik';

-- ------------------------------------------------------------
-- B. PEMBUATAN INDEX
-- ------------------------------------------------------------
CREATE INDEX idx_peminjaman_tanggal ON peminjaman(tanggal_pinjam);
CREATE INDEX idx_barang_nama ON barang(nama_barang);

-- Index tambahan yang umum dipakai untuk mempercepat laporan
CREATE INDEX idx_peminjaman_status ON peminjaman(status);
CREATE INDEX idx_pengembalian_tanggal ON pengembalian(tanggal_kembali);

-- ------------------------------------------------------------
-- C. EXPLAIN SETELAH INDEX dibuat
-- ------------------------------------------------------------
EXPLAIN SELECT * FROM peminjaman WHERE tanggal_pinjam = CURRENT_DATE;
EXPLAIN SELECT * FROM barang WHERE nama_barang = 'Router Mikrotik';

-- ------------------------------------------------------------
-- D. MELIHAT DAFTAR INDEX YANG SUDAH DIBUAT
-- ------------------------------------------------------------
SHOW INDEX FROM peminjaman;
SHOW INDEX FROM barang;

-- Kesimpulan (lihat pembahasan lengkap pada Laporan BAB IV):
-- Sebelum index dibuat, kolom 'type' pada hasil EXPLAIN menunjukkan
-- 'ALL' (full table scan) dengan 'key' bernilai NULL, artinya seluruh
-- baris tabel diperiksa satu per satu. Setelah index dibuat, kolom
-- 'type' berubah menjadi 'ref', kolom 'key' menunjukkan nama index yang
-- dipakai, dan nilai 'rows' yang diperiksa berkurang signifikan,
-- menandakan query menjadi lebih efisien terutama saat data bertambah
-- banyak.
