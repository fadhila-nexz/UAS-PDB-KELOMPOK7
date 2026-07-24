-- ============================================================
-- PROJEK TUGAS AKHIR PEMROGRAMAN BASIS DATA
-- TEMA : SISTEM BASIS DATA INVENTARIS LABORATORIUM
-- FILE : 01_create_database.sql  (CREATE DATABASE)
-- DBMS : MySQL / MariaDB (XAMPP)
-- CATATAN: Script ini dapat dijalankan ulang dari awal tanpa error.
-- ============================================================

-- Hapus database lama (jika ada) agar instalasi selalu bersih
DROP DATABASE IF EXISTS db_inventaris_lab;

-- Membuat database baru
CREATE DATABASE db_inventaris_lab
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

-- Memilih database yang akan digunakan
USE db_inventaris_lab;
