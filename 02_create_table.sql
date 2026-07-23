-- ============================================================
-- FILE : 02_create_table.sql  (CREATE TABLE)
-- Membuat seluruh struktur tabel Sistem Basis Data Inventaris Lab
-- ============================================================
USE db_inventaris_lab;

-- Nonaktifkan sementara pengecekan foreign key.
-- Ini WAJIB agar script bisa dijalankan ulang (re-run) kapan saja
-- tanpa error #1451, karena urutan DROP TABLE di bawah ini tidak
-- selalu sesuai urutan ketergantungan (dependency) foreign key,
-- terutama jika sebagian tabel sudah pernah dibuat sebelumnya.
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. TABEL KATEGORI_BARANG
-- ------------------------------------------------------------
DROP TABLE IF EXISTS kategori_barang;
CREATE TABLE kategori_barang (
    id_kategori     INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori   VARCHAR(50) NOT NULL UNIQUE,
    deskripsi       VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. TABEL LABORATORIUM
-- ------------------------------------------------------------
DROP TABLE IF EXISTS laboratorium;
CREATE TABLE laboratorium (
    id_lab              INT AUTO_INCREMENT PRIMARY KEY,
    nama_lab            VARCHAR(50) NOT NULL UNIQUE,
    lokasi              VARCHAR(100) NOT NULL,
    penanggung_jawab    VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. TABEL PETUGAS
-- ------------------------------------------------------------
DROP TABLE IF EXISTS petugas;
CREATE TABLE petugas (
    id_petugas      INT AUTO_INCREMENT PRIMARY KEY,
    nama_petugas    VARCHAR(100) NOT NULL,
    jabatan         VARCHAR(50) NOT NULL,
    no_hp           VARCHAR(20) DEFAULT NULL,
    username        VARCHAR(50) NOT NULL UNIQUE,
    password        VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. TABEL PEMINJAM (mahasiswa / dosen / staff)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS peminjam;
CREATE TABLE peminjam (
    id_peminjam     INT AUTO_INCREMENT PRIMARY KEY,
    nama_peminjam   VARCHAR(100) NOT NULL,
    jenis           ENUM('mahasiswa','dosen','staff') NOT NULL DEFAULT 'mahasiswa',
    no_identitas    VARCHAR(30) NOT NULL UNIQUE,
    no_hp           VARCHAR(20) DEFAULT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. TABEL BARANG (alat/bahan inventaris laboratorium)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS barang;
CREATE TABLE barang (
    id_barang       INT AUTO_INCREMENT PRIMARY KEY,
    nama_barang     VARCHAR(100) NOT NULL,
    id_kategori     INT NOT NULL,
    id_lab          INT NOT NULL,
    stok_total      INT NOT NULL DEFAULT 0 CHECK (stok_total >= 0),
    stok_tersedia   INT NOT NULL DEFAULT 0 CHECK (stok_tersedia >= 0),
    kondisi         ENUM('baik','rusak_ringan','rusak_berat') NOT NULL DEFAULT 'baik',
    harga_satuan    DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (harga_satuan >= 0),
    tanggal_masuk   DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_barang_kategori FOREIGN KEY (id_kategori)
        REFERENCES kategori_barang(id_kategori)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_barang_lab FOREIGN KEY (id_lab)
        REFERENCES laboratorium(id_lab)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_stok_tersedia_valid CHECK (stok_tersedia <= stok_total)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. TABEL PEMINJAMAN (header transaksi peminjaman)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS peminjaman;
CREATE TABLE peminjaman (
    id_peminjaman           INT AUTO_INCREMENT PRIMARY KEY,
    id_peminjam             INT NOT NULL,
    id_petugas              INT NOT NULL,
    tanggal_pinjam          DATE NOT NULL DEFAULT (CURRENT_DATE),
    tanggal_rencana_kembali DATE NOT NULL,
    status                  ENUM('dipinjam','dikembalikan','terlambat','dibatalkan')
                             NOT NULL DEFAULT 'dipinjam',
    CONSTRAINT fk_peminjaman_peminjam FOREIGN KEY (id_peminjam)
        REFERENCES peminjam(id_peminjam)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_peminjaman_petugas FOREIGN KEY (id_petugas)
        REFERENCES petugas(id_petugas)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_tgl_rencana CHECK (tanggal_rencana_kembali >= tanggal_pinjam)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. TABEL DETAIL_PEMINJAMAN (item barang yang dipinjam)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS detail_peminjaman;
CREATE TABLE detail_peminjaman (
    id_detail             INT AUTO_INCREMENT PRIMARY KEY,
    id_peminjaman         INT NOT NULL,
    id_barang             INT NOT NULL,
    jumlah                INT NOT NULL CHECK (jumlah > 0),
    kondisi_saat_pinjam   ENUM('baik','rusak_ringan','rusak_berat') NOT NULL DEFAULT 'baik',
    CONSTRAINT fk_detail_peminjaman FOREIGN KEY (id_peminjaman)
        REFERENCES peminjaman(id_peminjaman)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detail_barang FOREIGN KEY (id_barang)
        REFERENCES barang(id_barang)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. TABEL PENGEMBALIAN
-- ------------------------------------------------------------
DROP TABLE IF EXISTS pengembalian;
CREATE TABLE pengembalian (
    id_pengembalian       INT AUTO_INCREMENT PRIMARY KEY,
    id_peminjaman         INT NOT NULL,
    tanggal_kembali       DATE NOT NULL DEFAULT (CURRENT_DATE),
    kondisi_saat_kembali  ENUM('baik','rusak_ringan','rusak_berat') NOT NULL DEFAULT 'baik',
    denda                 DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (denda >= 0),
    id_petugas            INT NOT NULL,
    CONSTRAINT fk_pengembalian_peminjaman FOREIGN KEY (id_peminjaman)
        REFERENCES peminjaman(id_peminjaman)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pengembalian_petugas FOREIGN KEY (id_petugas)
        REFERENCES petugas(id_petugas)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 9. TABEL AUDIT_LOG
-- ------------------------------------------------------------
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    id_log        INT AUTO_INCREMENT PRIMARY KEY,
    nama_tabel    VARCHAR(50) NOT NULL,
    aksi          ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    data_lama     TEXT DEFAULT NULL,
    data_baru     TEXT DEFAULT NULL,
    waktu_aksi    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_db       VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Aktifkan kembali pengecekan foreign key setelah semua tabel selesai dibuat.
SET FOREIGN_KEY_CHECKS = 1;
