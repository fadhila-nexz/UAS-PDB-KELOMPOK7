-- ============================================================
-- FILE : 04_stored_procedure.sql  (Stored Procedure)
-- Prosedur dasar transaksi peminjaman & pengembalian barang.
-- Menerapkan TRANSACTION CONTROL (START TRANSACTION / COMMIT /
-- ROLLBACK) dan EXCEPTION HANDLING (SQLEXCEPTION).
-- Catatan: Prosedur yang menggunakan CURSOR ada di file
-- 07_cursor.sql, dan prosedur laporan ada di file
-- 10_query_laporan.sql.
-- ============================================================
USE db_inventaris_lab;

DELIMITER //

-- ------------------------------------------------------------
-- PROCEDURE 1 : sp_pinjam_barang
-- Membuat transaksi peminjaman baru untuk satu jenis barang.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_pinjam_barang //
CREATE PROCEDURE sp_pinjam_barang (
    IN  p_id_peminjam           INT,
    IN  p_id_petugas            INT,
    IN  p_id_barang             INT,
    IN  p_jumlah                INT,
    IN  p_tanggal_rencana       DATE,
    OUT p_status_pesan          VARCHAR(255)
)
BEGIN
    DECLARE v_stok          INT DEFAULT 0;
    DECLARE v_id_peminjaman INT;
    DECLARE v_exists        INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_pesan = 'GAGAL: Terjadi kesalahan pada transaksi, seluruh proses dibatalkan.';
    END;

    -- Exception handling: validasi data peminjam & petugas
    SELECT COUNT(*) INTO v_exists FROM peminjam WHERE id_peminjam = p_id_peminjam;
    IF v_exists = 0 THEN
        SET p_status_pesan = 'GAGAL: Data peminjam tidak ditemukan.';
    ELSE
        SELECT COUNT(*) INTO v_exists FROM petugas WHERE id_petugas = p_id_petugas;
        IF v_exists = 0 THEN
            SET p_status_pesan = 'GAGAL: Data petugas tidak ditemukan.';
        ELSE
            SELECT stok_tersedia INTO v_stok FROM barang WHERE id_barang = p_id_barang;

            START TRANSACTION;

            -- Exception handling: validasi stok mencukupi
            IF v_stok IS NULL THEN
                ROLLBACK;
                SET p_status_pesan = 'GAGAL: Barang tidak ditemukan.';
            ELSEIF p_jumlah <= 0 THEN
                ROLLBACK;
                SET p_status_pesan = 'GAGAL: Jumlah pinjaman harus lebih dari 0.';
            ELSEIF v_stok < p_jumlah THEN
                ROLLBACK;
                SET p_status_pesan = CONCAT('GAGAL: Stok tidak mencukupi. Stok tersedia hanya ', v_stok, '.');
            ELSE
                INSERT INTO peminjaman (id_peminjam, id_petugas, tanggal_pinjam, tanggal_rencana_kembali, status)
                VALUES (p_id_peminjam, p_id_petugas, CURRENT_DATE, p_tanggal_rencana, 'dipinjam');

                SET v_id_peminjaman = LAST_INSERT_ID();

                -- trigger trg_validasi_stok_before_insert dan
                -- trg_kurangi_stok_after_insert berjalan otomatis di sini
                INSERT INTO detail_peminjaman (id_peminjaman, id_barang, jumlah, kondisi_saat_pinjam)
                VALUES (v_id_peminjaman, p_id_barang, p_jumlah, 'baik');

                COMMIT;
                SET p_status_pesan = CONCAT('BERHASIL: Peminjaman tercatat dengan id_peminjaman = ', v_id_peminjaman);
            END IF;
        END IF;
    END IF;
END //

-- ------------------------------------------------------------
-- PROCEDURE 2 : sp_proses_pengembalian
-- Memproses pengembalian barang, menghitung denda otomatis
-- menggunakan fn_hitung_denda, dan menandai status peminjaman.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_proses_pengembalian //
CREATE PROCEDURE sp_proses_pengembalian (
    IN  p_id_peminjaman        INT,
    IN  p_id_petugas           INT,
    IN  p_kondisi_saat_kembali ENUM('baik','rusak_ringan','rusak_berat'),
    OUT p_status_pesan         VARCHAR(255)
)
BEGIN
    DECLARE v_status_sekarang VARCHAR(20);
    DECLARE v_denda           DECIMAL(12,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_pesan = 'GAGAL: Terjadi kesalahan saat memproses pengembalian.';
    END;

    SELECT status INTO v_status_sekarang
    FROM peminjaman WHERE id_peminjaman = p_id_peminjaman;

    IF v_status_sekarang IS NULL THEN
        SET p_status_pesan = 'GAGAL: Data peminjaman tidak ditemukan.';
    ELSEIF v_status_sekarang IN ('dikembalikan', 'dibatalkan') THEN
        SET p_status_pesan = 'GAGAL: Peminjaman ini sudah selesai/dibatalkan sebelumnya (data duplikat).';
    ELSE
        START TRANSACTION;

        SET v_denda = fn_hitung_denda(p_id_peminjaman, CURRENT_DATE);

        -- trigger trg_tambah_stok_after_pengembalian berjalan otomatis
        -- (menambah stok & mengubah status peminjaman menjadi 'dikembalikan')
        INSERT INTO pengembalian (id_peminjaman, tanggal_kembali, kondisi_saat_kembali, denda, id_petugas)
        VALUES (p_id_peminjaman, CURRENT_DATE, p_kondisi_saat_kembali, v_denda, p_id_petugas);

        COMMIT;
        SET p_status_pesan = CONCAT('BERHASIL: Pengembalian tercatat. Denda = Rp ', FORMAT(v_denda, 0));
    END IF;
END //

DELIMITER ;

-- ------------------------------------------------------------
-- CONTOH PEMANGGILAN
-- ------------------------------------------------------------
-- CALL sp_pinjam_barang(1, 1, 1, 2, DATE_ADD(CURRENT_DATE, INTERVAL 3 DAY), @pesan1);
-- SELECT @pesan1;
--
-- CALL sp_proses_pengembalian(1, 2, 'baik', @pesan2);
-- SELECT @pesan2;
