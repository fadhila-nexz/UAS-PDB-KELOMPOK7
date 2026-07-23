-- ============================================================
-- FILE : 07_cursor.sql  (Cursor)
-- Berisi stored procedure yang menerapkan CURSOR untuk
-- memproses baris data satu per satu.
-- ============================================================
USE db_inventaris_lab;

DELIMITER //

-- ------------------------------------------------------------
-- PROCEDURE 1 : sp_batalkan_peminjaman
-- Membatalkan transaksi peminjaman yang belum dikembalikan.
-- Menerapkan CURSOR untuk memproses setiap item barang dalam
-- peminjaman satu per satu, dan SAVEPOINT agar kegagalan pada
-- satu item tidak membatalkan seluruh proses pembatalan.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_batalkan_peminjaman //
CREATE PROCEDURE sp_batalkan_peminjaman (
    IN  p_id_peminjaman  INT,
    OUT p_status_pesan   VARCHAR(255)
)
BEGIN
    DECLARE v_status        VARCHAR(20);
    DECLARE v_id_barang     INT;
    DECLARE v_jumlah        INT;
    DECLARE v_done          INT DEFAULT 0;
    DECLARE v_gagal_item    INT DEFAULT 0;

    -- Deklarasi CURSOR untuk membaca setiap baris detail_peminjaman
    DECLARE cur_detail CURSOR FOR
        SELECT id_barang, jumlah FROM detail_peminjaman
        WHERE id_peminjaman = p_id_peminjaman;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status_pesan = 'GAGAL: Pembatalan dibatalkan seluruhnya akibat kesalahan sistem.';
    END;

    SELECT status INTO v_status FROM peminjaman WHERE id_peminjaman = p_id_peminjaman;

    IF v_status IS NULL THEN
        SET p_status_pesan = 'GAGAL: Data peminjaman tidak ditemukan.';
    ELSEIF v_status <> 'dipinjam' THEN
        SET p_status_pesan = 'GAGAL: Transaksi tidak valid untuk dibatalkan (status bukan dipinjam).';
    ELSE
        START TRANSACTION;
        SAVEPOINT sp_awal;

        OPEN cur_detail;
        read_loop: LOOP
            FETCH cur_detail INTO v_id_barang, v_jumlah;
            IF v_done = 1 THEN
                LEAVE read_loop;
            END IF;

            SAVEPOINT sp_item;
            UPDATE barang
            SET stok_tersedia = stok_tersedia + v_jumlah
            WHERE id_barang = v_id_barang;

            IF ROW_COUNT() = 0 THEN
                -- item gagal diproses -> batalkan hanya perubahan item ini
                ROLLBACK TO SAVEPOINT sp_item;
                SET v_gagal_item = v_gagal_item + 1;
            END IF;
        END LOOP;
        CLOSE cur_detail;

        DELETE FROM detail_peminjaman WHERE id_peminjaman = p_id_peminjaman;
        UPDATE peminjaman SET status = 'dibatalkan' WHERE id_peminjaman = p_id_peminjaman;

        COMMIT;
        SET p_status_pesan = CONCAT('BERHASIL: Peminjaman dibatalkan. Item gagal dikembalikan stoknya: ', v_gagal_item);
    END IF;
END //

-- ------------------------------------------------------------
-- PROCEDURE 2 : sp_update_status_terlambat
-- Menggunakan CURSOR untuk memeriksa seluruh peminjaman yang
-- masih berstatus 'dipinjam' satu per satu, lalu mengubah
-- statusnya menjadi 'terlambat' jika sudah melewati batas waktu.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_update_status_terlambat //
CREATE PROCEDURE sp_update_status_terlambat (
    OUT p_jumlah_diupdate INT
)
BEGIN
    DECLARE v_id_peminjaman INT;
    DECLARE v_tgl_rencana   DATE;
    DECLARE v_done          INT DEFAULT 0;
    DECLARE v_counter       INT DEFAULT 0;

    DECLARE cur_terlambat CURSOR FOR
        SELECT id_peminjaman, tanggal_rencana_kembali
        FROM peminjaman
        WHERE status = 'dipinjam';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cur_terlambat;

    cek_loop: LOOP
        FETCH cur_terlambat INTO v_id_peminjaman, v_tgl_rencana;
        IF v_done = 1 THEN
            LEAVE cek_loop;
        END IF;

        IF v_tgl_rencana < CURRENT_DATE THEN
            UPDATE peminjaman
            SET status = 'terlambat'
            WHERE id_peminjaman = v_id_peminjaman;
            SET v_counter = v_counter + 1;
        END IF;
    END LOOP;

    CLOSE cur_terlambat;

    SET p_jumlah_diupdate = v_counter;
END //

-- ------------------------------------------------------------
-- PROCEDURE 3 : sp_cek_barang_stok_menipis
-- Contoh CURSOR tambahan: menelusuri seluruh tabel barang satu
-- per satu dan mengumpulkan barang yang stoknya di bawah batas
-- minimum ke dalam tabel sementara (temporary table).
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cek_barang_stok_menipis //
CREATE PROCEDURE sp_cek_barang_stok_menipis (
    IN p_batas_minimum INT
)
BEGIN
    DECLARE v_id_barang    INT;
    DECLARE v_nama_barang  VARCHAR(100);
    DECLARE v_stok         INT;
    DECLARE v_done         INT DEFAULT 0;

    DECLARE cur_barang CURSOR FOR
        SELECT id_barang, nama_barang, stok_tersedia FROM barang;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_stok_menipis;
    CREATE TEMPORARY TABLE tmp_stok_menipis (
        id_barang     INT,
        nama_barang   VARCHAR(100),
        stok_tersedia INT
    );

    OPEN cur_barang;
    baca_loop: LOOP
        FETCH cur_barang INTO v_id_barang, v_nama_barang, v_stok;
        IF v_done = 1 THEN
            LEAVE baca_loop;
        END IF;

        IF v_stok <= p_batas_minimum THEN
            INSERT INTO tmp_stok_menipis VALUES (v_id_barang, v_nama_barang, v_stok);
        END IF;
    END LOOP;
    CLOSE cur_barang;

    SELECT * FROM tmp_stok_menipis;
END //

DELIMITER ;

-- ------------------------------------------------------------
-- CONTOH PEMANGGILAN
-- ------------------------------------------------------------
-- CALL sp_update_status_terlambat(@jumlah_update);
-- SELECT @jumlah_update;
--
-- CALL sp_cek_barang_stok_menipis(10);
