-- ============================================================
-- FILE : 10_query_laporan.sql  (Query Laporan)
-- Kumpulan stored procedure & query SELECT untuk kebutuhan
-- pelaporan Sistem Inventaris Laboratorium.
-- ============================================================
USE db_inventaris_lab;

DELIMITER //

-- ------------------------------------------------------------
-- PROCEDURE : sp_laporan_peminjaman_periode
-- Menampilkan laporan transaksi peminjaman pada rentang tanggal
-- tertentu, lengkap dengan nama peminjam, barang, dan status.
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_laporan_peminjaman_periode //
CREATE PROCEDURE sp_laporan_peminjaman_periode (
    IN p_tanggal_awal  DATE,
    IN p_tanggal_akhir DATE
)
BEGIN
    SELECT
        p.id_peminjaman,
        pm.nama_peminjam,
        pm.jenis,
        b.nama_barang,
        d.jumlah,
        p.tanggal_pinjam,
        p.tanggal_rencana_kembali,
        p.status
    FROM peminjaman p
    JOIN peminjam pm          ON pm.id_peminjam = p.id_peminjam
    JOIN detail_peminjaman d  ON d.id_peminjaman = p.id_peminjaman
    JOIN barang b             ON b.id_barang = d.id_barang
    WHERE p.tanggal_pinjam BETWEEN p_tanggal_awal AND p_tanggal_akhir
    ORDER BY p.tanggal_pinjam ASC;
END //

DELIMITER ;

-- Contoh pemanggilan:
-- CALL sp_laporan_peminjaman_periode('2026-01-01', '2026-12-31');


-- ------------------------------------------------------------
-- LAPORAN 1 : Rekap stok barang per kategori & laboratorium
-- ------------------------------------------------------------
SELECT
    k.nama_kategori,
    l.nama_lab,
    b.nama_barang,
    b.stok_total,
    b.stok_tersedia,
    (b.stok_total - b.stok_tersedia) AS jumlah_dipinjam,
    b.kondisi,
    b.harga_satuan
FROM barang b
JOIN kategori_barang k ON k.id_kategori = b.id_kategori
JOIN laboratorium l    ON l.id_lab = b.id_lab
ORDER BY k.nama_kategori, l.nama_lab, b.nama_barang;

-- ------------------------------------------------------------
-- LAPORAN 2 : Peminjaman yang masih aktif / belum dikembalikan
-- ------------------------------------------------------------
SELECT
    p.id_peminjaman,
    pm.nama_peminjam,
    pm.jenis,
    b.nama_barang,
    d.jumlah,
    p.tanggal_pinjam,
    p.tanggal_rencana_kembali,
    p.status,
    DATEDIFF(CURRENT_DATE, p.tanggal_rencana_kembali) AS hari_terlambat
FROM peminjaman p
JOIN peminjam pm         ON pm.id_peminjam = p.id_peminjam
JOIN detail_peminjaman d ON d.id_peminjaman = p.id_peminjaman
JOIN barang b             ON b.id_barang = d.id_barang
WHERE p.status IN ('dipinjam', 'terlambat')
ORDER BY p.tanggal_rencana_kembali ASC;

-- ------------------------------------------------------------
-- LAPORAN 3 : Rekap denda per peminjam
-- ------------------------------------------------------------
SELECT
    pm.nama_peminjam,
    pm.jenis,
    COUNT(pg.id_pengembalian) AS jumlah_pengembalian,
    SUM(pg.denda)             AS total_denda
FROM pengembalian pg
JOIN peminjaman p  ON p.id_peminjaman = pg.id_peminjaman
JOIN peminjam pm   ON pm.id_peminjam = p.id_peminjam
GROUP BY pm.id_peminjam, pm.nama_peminjam, pm.jenis
HAVING total_denda > 0
ORDER BY total_denda DESC;

-- ------------------------------------------------------------
-- LAPORAN 4 : Barang yang paling sering dipinjam
-- ------------------------------------------------------------
SELECT
    b.nama_barang,
    COUNT(d.id_detail)  AS jumlah_transaksi,
    SUM(d.jumlah)        AS total_unit_dipinjam
FROM detail_peminjaman d
JOIN barang b ON b.id_barang = d.id_barang
GROUP BY b.id_barang, b.nama_barang
ORDER BY total_unit_dipinjam DESC
LIMIT 5;

-- ------------------------------------------------------------
-- LAPORAN 5 : Riwayat audit log terbaru per tabel
-- ------------------------------------------------------------
SELECT
    nama_tabel,
    aksi,
    data_lama,
    data_baru,
    waktu_aksi,
    user_db
FROM audit_log
ORDER BY waktu_aksi DESC
LIMIT 20;

-- ------------------------------------------------------------
-- LAPORAN 6 : Rekap performa petugas (jumlah transaksi ditangani)
-- ------------------------------------------------------------
SELECT
    pt.nama_petugas,
    pt.jabatan,
    COUNT(DISTINCT p.id_peminjaman)  AS jumlah_peminjaman_ditangani,
    COUNT(DISTINCT pg.id_pengembalian) AS jumlah_pengembalian_ditangani
FROM petugas pt
LEFT JOIN peminjaman p    ON p.id_petugas = pt.id_petugas
LEFT JOIN pengembalian pg ON pg.id_petugas = pt.id_petugas
GROUP BY pt.id_petugas, pt.nama_petugas, pt.jabatan
ORDER BY jumlah_peminjaman_ditangani DESC;
