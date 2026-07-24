-- ============================================================
-- FILE : 06_trigger.sql  (Trigger)
-- ============================================================
USE db_inventaris_lab;

DELIMITER //

-- ------------------------------------------------------------
-- TRIGGER 1 (VALIDASI) : trg_validasi_stok_before_insert
-- Menolak peminjaman apabila jumlah yang diminta melebihi
-- stok_tersedia barang.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validasi_stok_before_insert //
CREATE TRIGGER trg_validasi_stok_before_insert
BEFORE INSERT ON detail_peminjaman
FOR EACH ROW
BEGIN
    DECLARE v_stok INT DEFAULT 0;

    SELECT stok_tersedia INTO v_stok
    FROM barang
    WHERE id_barang = NEW.id_barang;

    IF v_stok IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Barang tidak ditemukan.';
    ELSEIF NEW.jumlah > v_stok THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stok barang tidak mencukupi untuk peminjaman ini.';
    ELSEIF NEW.jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah barang yang dipinjam harus lebih dari 0.';
    END IF;
END //

-- ------------------------------------------------------------
-- TRIGGER 2 (PERUBAHAN OTOMATIS) : trg_kurangi_stok_after_insert
-- Mengurangi stok_tersedia barang secara otomatis setelah
-- detail peminjaman berhasil disimpan.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_kurangi_stok_after_insert //
CREATE TRIGGER trg_kurangi_stok_after_insert
AFTER INSERT ON detail_peminjaman
FOR EACH ROW
BEGIN
    UPDATE barang
    SET stok_tersedia = stok_tersedia - NEW.jumlah
    WHERE id_barang = NEW.id_barang;
END //

-- ------------------------------------------------------------
-- TRIGGER 3 (PERUBAHAN OTOMATIS) : trg_tambah_stok_after_pengembalian
-- Mengembalikan (menambah) stok_tersedia barang secara otomatis
-- setelah data pengembalian dicatat, serta memperbarui kondisi
-- barang berdasarkan kondisi saat kembali.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_tambah_stok_after_pengembalian //
CREATE TRIGGER trg_tambah_stok_after_pengembalian
AFTER INSERT ON pengembalian
FOR EACH ROW
BEGIN
    UPDATE barang b
    INNER JOIN detail_peminjaman d ON d.id_barang = b.id_barang
    SET b.stok_tersedia = b.stok_tersedia + d.jumlah,
        b.kondisi       = NEW.kondisi_saat_kembali
    WHERE d.id_peminjaman = NEW.id_peminjaman;

    UPDATE peminjaman
    SET status = 'dikembalikan'
    WHERE id_peminjaman = NEW.id_peminjaman;
END //

-- ------------------------------------------------------------
-- TRIGGER 4 (AUDIT LOGGING) : trg_audit_barang_update
-- Mencatat setiap perubahan data pada tabel barang ke audit_log.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_barang_update //
CREATE TRIGGER trg_audit_barang_update
AFTER UPDATE ON barang
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (nama_tabel, aksi, data_lama, data_baru, user_db)
    VALUES (
        'barang',
        'UPDATE',
        CONCAT('id_barang=', OLD.id_barang,
               ';nama_barang=', OLD.nama_barang,
               ';stok_tersedia=', OLD.stok_tersedia,
               ';kondisi=', OLD.kondisi),
        CONCAT('id_barang=', NEW.id_barang,
               ';nama_barang=', NEW.nama_barang,
               ';stok_tersedia=', NEW.stok_tersedia,
               ';kondisi=', NEW.kondisi),
        CURRENT_USER()
    );
END //

-- ------------------------------------------------------------
-- TRIGGER 5 (AUDIT LOGGING) : trg_audit_peminjaman_insert
-- Mencatat setiap transaksi peminjaman baru yang dibuat.
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_audit_peminjaman_insert //
CREATE TRIGGER trg_audit_peminjaman_insert
AFTER INSERT ON peminjaman
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (nama_tabel, aksi, data_lama, data_baru, user_db)
    VALUES (
        'peminjaman',
        'INSERT',
        NULL,
        CONCAT('id_peminjaman=', NEW.id_peminjaman,
               ';id_peminjam=', NEW.id_peminjam,
               ';tanggal_pinjam=', NEW.tanggal_pinjam,
               ';status=', NEW.status),
        CURRENT_USER()
    );
END //

DELIMITER ;
