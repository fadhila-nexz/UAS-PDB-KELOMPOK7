-- ============================================================
-- FILE : 03_insert_data_dummy.sql  (Data Awal / Dummy)
-- ============================================================
USE db_inventaris_lab;

-- Kategori Barang
INSERT INTO kategori_barang (nama_kategori, deskripsi) VALUES
('Alat Ukur', 'Alat untuk mengukur besaran fisika/kimia'),
('Alat Gelas', 'Peralatan berbahan kaca laboratorium'),
('Elektronik', 'Perangkat elektronik dan komponen praktikum'),
('Komputer', 'Perangkat komputer dan aksesoris'),
('Bahan Habis Pakai', 'Bahan praktikum sekali pakai');

-- Laboratorium
INSERT INTO laboratorium (nama_lab, lokasi, penanggung_jawab) VALUES
('Lab Komputer 1', 'Gedung A Lantai 2', 'Budi Santoso'),
('Lab Fisika', 'Gedung B Lantai 1', 'Siti Aminah'),
('Lab Kimia', 'Gedung B Lantai 2', 'Ahmad Fauzi'),
('Lab Jaringan', 'Gedung A Lantai 3', 'Dewi Lestari');

-- Petugas
INSERT INTO petugas (nama_petugas, jabatan, no_hp, username, password) VALUES
('Rina Marlina', 'Kepala Laboran', '081234567801', 'rina.admin', 'hashed_pw_1'),
('Dedi Kurniawan', 'Laboran', '081234567802', 'dedi.laboran', 'hashed_pw_2'),
('Fitri Handayani', 'Laboran', '081234567803', 'fitri.laboran', 'hashed_pw_3');

-- Peminjam
INSERT INTO peminjam (nama_peminjam, jenis, no_identitas, no_hp) VALUES
('Andi Saputra', 'mahasiswa', '2201010001', '081211110001'),
('Bella Putri', 'mahasiswa', '2201010002', '081211110002'),
('Dr. Hartono', 'dosen', 'DSN0001', '081211110003'),
('Citra Ayu', 'mahasiswa', '2201010004', '081211110004'),
('Eko Prabowo', 'staff', 'STF0001', '081211110005');

-- Barang
INSERT INTO barang (nama_barang, id_kategori, id_lab, stok_total, stok_tersedia, kondisi, harga_satuan, tanggal_masuk) VALUES
('Multimeter Digital', 1, 2, 20, 20, 'baik', 150000.00, '2024-01-10'),
('Osiloskop', 1, 2, 5, 5, 'baik', 3500000.00, '2024-01-10'),
('Gelas Ukur 100ml', 2, 3, 50, 50, 'baik', 25000.00, '2024-02-05'),
('Erlenmeyer 250ml', 2, 3, 40, 40, 'baik', 30000.00, '2024-02-05'),
('Proyektor', 3, 1, 6, 6, 'baik', 4500000.00, '2024-01-20'),
('Laptop Praktikum', 4, 1, 15, 15, 'baik', 6500000.00, '2024-03-01'),
('Router Mikrotik', 4, 4, 10, 10, 'baik', 850000.00, '2024-03-15'),
('Kabel LAN (roll)', 4, 4, 25, 25, 'baik', 350000.00, '2024-03-15'),
('Mikroskop', 1, 3, 8, 8, 'baik', 2200000.00, '2024-01-25'),
('Bunsen Burner', 2, 3, 12, 12, 'baik', 75000.00, '2024-02-10');
