-- ============================================================
-- FILE : 05_function.sql  (Function)
-- ============================================================
USE db_inventaris_lab;

DELIMITER //

-- ------------------------------------------------------------
-- FUNCTION 1 : fn_cek_stok_tersedia
-- Mengembalikan jumlah stok tersedia untuk suatu barang.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_cek_stok_tersedia //
CREATE FUNCTION fn_cek_stok_tersedia (p_id_barang INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stok INT DEFAULT 0;

    SELECT stok_tersedia INTO v_stok
    FROM barang
    WHERE id_barang = p_id_barang;

    RETURN IFNULL(v_stok, 0);
END //

-- ------------------------------------------------------------
-- FUNCTION 2 : fn_hitung_denda
-- Menghitung denda keterlambatan pengembalian.
-- Tarif denda : Rp 2.000 / hari terlambat / unit barang.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_hitung_denda //
CREATE FUNCTION fn_hitung_denda (p_id_peminjaman INT, p_tanggal_kembali DATE)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_tgl_rencana   DATE;
    DECLARE v_hari_telat    INT DEFAULT 0;
    DECLARE v_total_barang  INT DEFAULT 0;
    DECLARE v_denda         DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tarif         DECIMAL(12,2) DEFAULT 2000.00;

    SELECT tanggal_rencana_kembali INTO v_tgl_rencana
    FROM peminjaman
    WHERE id_peminjaman = p_id_peminjaman;

    SET v_hari_telat = DATEDIFF(p_tanggal_kembali, v_tgl_rencana);
    IF v_hari_telat < 0 THEN
        SET v_hari_telat = 0;
    END IF;

    SELECT IFNULL(SUM(jumlah), 0) INTO v_total_barang
    FROM detail_peminjaman
    WHERE id_peminjaman = p_id_peminjaman;

    SET v_denda = v_hari_telat * v_tarif * v_total_barang;

    RETURN v_denda;
END //

-- ------------------------------------------------------------
-- FUNCTION 3 : fn_jumlah_peminjaman_aktif
-- Menghitung jumlah transaksi peminjaman yang masih aktif
-- (status dipinjam / terlambat) milik seorang peminjam.
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_jumlah_peminjaman_aktif //
CREATE FUNCTION fn_jumlah_peminjaman_aktif (p_id_peminjam INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_jumlah INT DEFAULT 0;

    SELECT COUNT(*) INTO v_jumlah
    FROM peminjaman
    WHERE id_peminjam = p_id_peminjam
      AND status IN ('dipinjam', 'terlambat');

    RETURN v_jumlah;
END //

DELIMITER ;
