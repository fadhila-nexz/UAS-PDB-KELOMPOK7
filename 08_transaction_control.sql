-- ============================================================
-- FILE : 08_transaction_control.sql  (Transaction Control)
-- Mendemonstrasikan START TRANSACTION, COMMIT, ROLLBACK, dan
-- SAVEPOINT pada MySQL/MariaDB (tabel InnoDB).
-- ============================================================
USE db_inventaris_lab;

-- ------------------------------------------------------------
-- A. DEMO DASAR : COMMIT
-- Perubahan disimpan permanen setelah COMMIT.
-- ------------------------------------------------------------
START TRANSACTION;
UPDATE barang
SET stok_tersedia = stok_tersedia - 1
WHERE id_barang = 1;
COMMIT;

SELECT stok_tersedia AS stok_setelah_commit
FROM barang WHERE id_barang = 1;

-- ------------------------------------------------------------
-- B. DEMO DASAR : ROLLBACK
-- Perubahan dibatalkan seluruhnya, data kembali seperti semula.
-- ------------------------------------------------------------
START TRANSACTION;
UPDATE barang
SET stok_tersedia = stok_tersedia - 3
WHERE id_barang = 2;
-- Setelah dicek ulang, pengurangan stok ini ternyata keliru
-- (misalnya salah input jumlah) -> batalkan seluruh perubahan
ROLLBACK;

SELECT stok_tersedia AS stok_tetap_setelah_rollback
FROM barang WHERE id_barang = 2;

-- ------------------------------------------------------------
-- C. DEMO SAVEPOINT
-- Membatalkan sebagian perubahan tanpa membatalkan seluruh
-- transaksi.
-- ------------------------------------------------------------
START TRANSACTION;

UPDATE barang SET stok_tersedia = stok_tersedia - 2 WHERE id_barang = 3;
SAVEPOINT sp_setelah_item_1;

UPDATE barang SET stok_tersedia = stok_tersedia - 5 WHERE id_barang = 4;
-- Item ke-2 ternyata salah input jumlah -> batalkan hanya perubahan sejak sp_setelah_item_1
ROLLBACK TO SAVEPOINT sp_setelah_item_1;

COMMIT;  -- perubahan item 1 tetap tersimpan, item 2 batal

SELECT id_barang, stok_tersedia
FROM barang WHERE id_barang IN (3, 4);

-- ------------------------------------------------------------
-- D. TRANSACTION CONTROL DI DALAM STORED PROCEDURE
-- (definisi lengkap ada pada file 04_stored_procedure.sql
-- dan 07_cursor.sql)
-- ------------------------------------------------------------

-- D.1 Skenario SUKSES -> COMMIT (stok mencukupi)
CALL sp_pinjam_barang(2, 1, 3, 3, DATE_ADD(CURRENT_DATE, INTERVAL 5 DAY), @pesan_sukses);
SELECT @pesan_sukses AS skenario_sukses_commit;
SELECT stok_tersedia FROM barang WHERE id_barang = 3;  -- berkurang (COMMIT berhasil)

-- D.2 Skenario GAGAL -> ROLLBACK (stok tidak mencukupi)
CALL sp_pinjam_barang(3, 1, 2, 999, DATE_ADD(CURRENT_DATE, INTERVAL 5 DAY), @pesan_gagal);
SELECT @pesan_gagal AS skenario_gagal_rollback;
SELECT stok_tersedia FROM barang WHERE id_barang = 2;  -- tetap, tidak berubah (ROLLBACK berhasil)

-- D.3 Skenario SAVEPOINT (pembatalan sebagian lewat prosedur)
-- sp_batalkan_peminjaman (file 07_cursor.sql) menggunakan SAVEPOINT
-- per item barang saat membatalkan peminjaman.
CALL sp_pinjam_barang(4, 2, 9, 2, DATE_ADD(CURRENT_DATE, INTERVAL 4 DAY), @pesan_pinjam);
SELECT @pesan_pinjam AS pinjam_sebelum_batal;

SELECT id_peminjaman FROM peminjaman
WHERE id_peminjam = 4 ORDER BY id_peminjaman DESC LIMIT 1 INTO @id_pjm_batal;

CALL sp_batalkan_peminjaman(@id_pjm_batal, @pesan_batal);
SELECT @pesan_batal AS skenario_savepoint_batal;
SELECT stok_tersedia FROM barang WHERE id_barang = 9;  -- kembali bertambah 2
