-- ============================================================
--  MODUL BASIS DATA VII
--  View, Trigger, Stored Procedure, dan Function
--  Database : db_akademik
--  Tool     : SQLyog / MySQL
--  Cara pakai:
--    1. Jalankan bagian per bagian (pilih → F9)
--    2. Atau jalankan semua sekaligus (Ctrl+F9)
-- ============================================================


-- ============================================================
--  BAGIAN 1 — SETUP DATABASE & TABEL
-- ============================================================

-- 1.1 Buat dan aktifkan database
DROP DATABASE IF EXISTS db_akademik;
CREATE DATABASE db_akademik
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_akademik;


-- 1.2 Tabel mahasiswa
CREATE TABLE mahasiswa (
  id_mahasiswa  INT          AUTO_INCREMENT PRIMARY KEY,
  nim           VARCHAR(20)  NOT NULL,
  nama          VARCHAR(100) NOT NULL,
  jurusan       VARCHAR(100) NOT NULL,
  angkatan      YEAR         NOT NULL
);


-- 1.3 Tabel mata_kuliah
CREATE TABLE mata_kuliah (
  id_mk    INT          AUTO_INCREMENT PRIMARY KEY,
  kode_mk  VARCHAR(20)  NOT NULL,
  nama_mk  VARCHAR(100) NOT NULL,
  sks      INT          NOT NULL
);


-- 1.4 Tabel nilai
CREATE TABLE nilai (
  id_nilai      INT            AUTO_INCREMENT PRIMARY KEY,
  id_mahasiswa  INT            NOT NULL,
  id_mk         INT            NOT NULL,
  nilai_angka   DECIMAL(5,2)   NOT NULL,
  tanggal_input DATETIME       DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_mahasiswa) REFERENCES mahasiswa(id_mahasiswa),
  FOREIGN KEY (id_mk)        REFERENCES mata_kuliah(id_mk)
);


-- 1.5 Tabel log_nilai (digunakan oleh trigger)
CREATE TABLE log_nilai (
  id_log     INT          AUTO_INCREMENT PRIMARY KEY,
  id_nilai   INT,
  aksi       VARCHAR(20),
  nilai_lama DECIMAL(5,2),
  nilai_baru DECIMAL(5,2),
  waktu_log  DATETIME     DEFAULT CURRENT_TIMESTAMP
);


-- 1.6 Insert data mahasiswa
INSERT INTO mahasiswa (nim, nama, jurusan, angkatan) VALUES
  ('23001', 'Andi Saputra', 'Informatika',          2023),
  ('23002', 'Budi Santoso', 'Sistem Informasi',      2023),
  ('23003', 'Citra Dewi',   'Informatika',           2022),
  ('23004', 'Dian Pratama', 'Teknologi Informasi',   2021);


-- 1.7 Insert data mata_kuliah
INSERT INTO mata_kuliah (kode_mk, nama_mk, sks) VALUES
  ('BD001',  'Basis Data',               3),
  ('WEB001', 'Pemrograman Web',          3),
  ('RPL001', 'Rekayasa Perangkat Lunak', 3);


-- 1.8 Insert data nilai
INSERT INTO nilai (id_mahasiswa, id_mk, nilai_angka) VALUES
  (1, 1, 85.00),   -- Andi  → Basis Data
  (1, 2, 78.00),   -- Andi  → Pemrograman Web
  (2, 1, 72.00),   -- Budi  → Basis Data
  (3, 1, 90.00),   -- Citra → Basis Data
  (4, 3, 80.00);   -- Dian  → RPL

-- Verifikasi data awal
SELECT * FROM mahasiswa;
SELECT * FROM mata_kuliah;
SELECT * FROM nilai;


-- ============================================================
--  BAGIAN 2 — VIEW
-- ============================================================

-- 2.1 View mahasiswa jurusan Informatika
CREATE VIEW view_mahasiswa_informatika AS
SELECT nim, nama, jurusan, angkatan
FROM   mahasiswa
WHERE  jurusan = 'Informatika';

SELECT * FROM view_mahasiswa_informatika;


-- 2.2 View laporan nilai (JOIN 3 tabel)
CREATE VIEW view_nilai_mahasiswa AS
SELECT
  m.nim,
  m.nama,
  m.jurusan,
  mk.kode_mk,
  mk.nama_mk,
  mk.sks,
  n.nilai_angka,
  n.tanggal_input
FROM   nilai        n
JOIN   mahasiswa    m  ON n.id_mahasiswa = m.id_mahasiswa
JOIN   mata_kuliah  mk ON n.id_mk        = mk.id_mk;

SELECT * FROM view_nilai_mahasiswa;


-- 2.3 View mahasiswa angkatan 2023 (Latihan 1)
CREATE VIEW view_mahasiswa_2023 AS
SELECT nim, nama, jurusan, angkatan
FROM   mahasiswa
WHERE  angkatan = 2023;

SELECT * FROM view_mahasiswa_2023;


-- 2.4 View laporan nilai ringkas (Latihan 2)
CREATE VIEW view_laporan_nilai AS
SELECT
  m.nim,
  m.nama,
  mk.nama_mk,
  mk.sks,
  n.nilai_angka
FROM   nilai        n
JOIN   mahasiswa    m  ON n.id_mahasiswa = m.id_mahasiswa
JOIN   mata_kuliah  mk ON n.id_mk        = mk.id_mk;

SELECT * FROM view_laporan_nilai;


-- 2.5 Mengubah definisi view (CREATE OR REPLACE)
CREATE OR REPLACE VIEW view_mahasiswa_informatika AS
SELECT nim, nama, jurusan
FROM   mahasiswa
WHERE  jurusan = 'Informatika';

SELECT * FROM view_mahasiswa_informatika;


-- ============================================================
--  BAGIAN 3 — TRIGGER
-- ============================================================

-- 3.1 AFTER INSERT — catat log saat nilai baru ditambahkan
DELIMITER $$

CREATE TRIGGER trg_after_insert_nilai
AFTER INSERT ON nilai
FOR EACH ROW
BEGIN
  INSERT INTO log_nilai (id_nilai, aksi, nilai_lama, nilai_baru)
  VALUES (NEW.id_nilai, 'INSERT', NULL, NEW.nilai_angka);
END $$

DELIMITER ;

-- Uji: tambah nilai baru
INSERT INTO nilai (id_mahasiswa, id_mk, nilai_angka)
VALUES (2, 2, 88.00);

SELECT * FROM log_nilai;


-- 3.2 AFTER UPDATE — catat nilai lama & baru saat nilai diperbarui
DELIMITER $$

CREATE TRIGGER trg_after_update_nilai
AFTER UPDATE ON nilai
FOR EACH ROW
BEGIN
  INSERT INTO log_nilai (id_nilai, aksi, nilai_lama, nilai_baru)
  VALUES (OLD.id_nilai, 'UPDATE', OLD.nilai_angka, NEW.nilai_angka);
END $$

DELIMITER ;

-- Uji: ubah nilai
UPDATE nilai
SET    nilai_angka = 92.00
WHERE  id_nilai = 1;

SELECT * FROM log_nilai;


-- 3.3 BEFORE INSERT — validasi nilai harus antara 0 dan 100
DELIMITER $$

CREATE TRIGGER trg_before_insert_nilai
BEFORE INSERT ON nilai
FOR EACH ROW
BEGIN
  IF NEW.nilai_angka < 0 OR NEW.nilai_angka > 100 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Nilai harus berada pada rentang 0 sampai 100';
  END IF;
END $$

DELIMITER ;

-- Uji: nilai di luar rentang → akan error
-- INSERT INTO nilai (id_mahasiswa, id_mk, nilai_angka)
-- VALUES (1, 3, 120.00);


-- 3.4 AFTER DELETE — catat data yang dihapus (Latihan 3)
DELIMITER $$

CREATE TRIGGER trg_after_delete_nilai
AFTER DELETE ON nilai
FOR EACH ROW
BEGIN
  INSERT INTO log_nilai (id_nilai, aksi, nilai_lama, nilai_baru)
  VALUES (OLD.id_nilai, 'DELETE', OLD.nilai_angka, NULL);
END $$

DELIMITER ;

-- Uji: hapus satu baris nilai lalu lihat log
-- DELETE FROM nilai WHERE id_nilai = 6;
-- SELECT * FROM log_nilai;


-- ============================================================
--  BAGIAN 4 — STORED PROCEDURE
-- ============================================================

-- 4.1 Procedure tanpa parameter
DELIMITER $$

CREATE PROCEDURE tampil_semua_mahasiswa()
BEGIN
  SELECT * FROM mahasiswa;
END $$

DELIMITER ;

CALL tampil_semua_mahasiswa();


-- 4.2 Procedure dengan parameter IN — cari by jurusan
DELIMITER $$

CREATE PROCEDURE cari_mahasiswa_by_jurusan(IN p_jurusan VARCHAR(100))
BEGIN
  SELECT nim, nama, jurusan, angkatan
  FROM   mahasiswa
  WHERE  jurusan = p_jurusan;
END $$

DELIMITER ;

CALL cari_mahasiswa_by_jurusan('Informatika');


-- 4.3 Procedure untuk menambah data nilai
DELIMITER $$

CREATE PROCEDURE tambah_nilai(
  IN p_id_mahasiswa INT,
  IN p_id_mk        INT,
  IN p_nilai        DECIMAL(5,2)
)
BEGIN
  INSERT INTO nilai (id_mahasiswa, id_mk, nilai_angka)
  VALUES (p_id_mahasiswa, p_id_mk, p_nilai);
END $$

DELIMITER ;

CALL tambah_nilai(3, 2, 86.00);
SELECT * FROM nilai;


-- 4.4 Procedure dengan parameter OUT — hitung total mahasiswa
DELIMITER $$

CREATE PROCEDURE hitung_jumlah_mahasiswa(OUT total_mahasiswa INT)
BEGIN
  SELECT COUNT(*) INTO total_mahasiswa
  FROM   mahasiswa;
END $$

DELIMITER ;

CALL hitung_jumlah_mahasiswa(@total);
SELECT @total AS jumlah_mahasiswa;


-- 4.5 Procedure tampil nilai berdasarkan NIM (Latihan 5)
--     Catatan: procedure ini menggunakan function konversi_grade
--     yang dibuat di bagian 5. Jalankan SETELAH bagian 5.
DELIMITER $$

CREATE PROCEDURE tampil_nilai_by_nim(IN p_nim VARCHAR(20))
BEGIN
  SELECT
    m.nim,
    m.nama,
    mk.nama_mk,
    n.nilai_angka,
    konversi_grade(n.nilai_angka) AS grade
  FROM   nilai        n
  JOIN   mahasiswa    m  ON n.id_mahasiswa = m.id_mahasiswa
  JOIN   mata_kuliah  mk ON n.id_mk        = mk.id_mk
  WHERE  m.nim = p_nim;
END $$

DELIMITER ;

-- CALL tampil_nilai_by_nim('23001');


-- 4.6 Procedure tambah data mahasiswa baru (Latihan 6)
DELIMITER $$

CREATE PROCEDURE tambah_mahasiswa(
  IN p_nim      VARCHAR(20),
  IN p_nama     VARCHAR(100),
  IN p_jurusan  VARCHAR(100),
  IN p_angkatan YEAR
)
BEGIN
  INSERT INTO mahasiswa (nim, nama, jurusan, angkatan)
  VALUES (p_nim, p_nama, p_jurusan, p_angkatan);
END $$

DELIMITER ;

CALL tambah_mahasiswa('23005', 'Eka Putra', 'Informatika', 2023);
SELECT * FROM mahasiswa;


-- 4.7 Procedure hitung jumlah nilai per mata kuliah (Latihan 7)
DELIMITER $$

CREATE PROCEDURE hitung_nilai_by_mk(
  IN  p_id_mk  INT,
  OUT p_jumlah INT
)
BEGIN
  SELECT COUNT(*) INTO p_jumlah
  FROM   nilai
  WHERE  id_mk = p_id_mk;
END $$

DELIMITER ;

CALL hitung_nilai_by_mk(1, @jumlah_nilai);
SELECT @jumlah_nilai AS total_nilai_basis_data;


-- ============================================================
--  BAGIAN 5 — FUNCTION
-- ============================================================

-- 5.1 Function konversi nilai angka → grade huruf
DELIMITER $$

CREATE FUNCTION konversi_grade(p_nilai DECIMAL(5,2))
RETURNS VARCHAR(2)
DETERMINISTIC
BEGIN
  DECLARE grade VARCHAR(2);

  IF      p_nilai >= 85 THEN SET grade = 'A';
  ELSEIF  p_nilai >= 75 THEN SET grade = 'B';
  ELSEIF  p_nilai >= 65 THEN SET grade = 'C';
  ELSEIF  p_nilai >= 50 THEN SET grade = 'D';
  ELSE                        SET grade = 'E';
  END IF;

  RETURN grade;
END $$

DELIMITER ;

-- Test function
SELECT konversi_grade(88) AS grade;   -- A
SELECT konversi_grade(70) AS grade;   -- B
SELECT konversi_grade(45) AS grade;   -- E


-- 5.2 Gunakan konversi_grade dalam query SELECT
SELECT
  m.nim,
  m.nama,
  mk.nama_mk,
  n.nilai_angka,
  konversi_grade(n.nilai_angka) AS grade
FROM   nilai        n
JOIN   mahasiswa    m  ON n.id_mahasiswa = m.id_mahasiswa
JOIN   mata_kuliah  mk ON n.id_mk        = mk.id_mk
ORDER BY n.nilai_angka DESC;


-- 5.3 Function status kelulusan
DELIMITER $$

CREATE FUNCTION status_lulus(p_nilai DECIMAL(5,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
  IF p_nilai >= 65 THEN
    RETURN 'Lulus';
  ELSE
    RETURN 'Tidak Lulus';
  END IF;
END $$

DELIMITER ;

-- Gunakan dari view_nilai_mahasiswa
SELECT
  nama,
  nama_mk,
  nilai_angka,
  status_lulus(nilai_angka) AS status
FROM view_nilai_mahasiswa;


-- 5.4 Function konversi predikat (Latihan 8)
DELIMITER $$

CREATE FUNCTION konversi_predikat(p_nilai DECIMAL(5,2))
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
  IF      p_nilai >= 85 THEN RETURN 'Sangat Baik';
  ELSEIF  p_nilai >= 75 THEN RETURN 'Baik';
  ELSEIF  p_nilai >= 65 THEN RETURN 'Cukup';
  ELSE                        RETURN 'Kurang';
  END IF;
END $$

DELIMITER ;

-- 5.5 Gabungan semua function dalam satu query (Latihan 9)
SELECT
  nim,
  nama,
  nama_mk,
  sks,
  nilai_angka,
  konversi_grade(nilai_angka)    AS grade,
  konversi_predikat(nilai_angka) AS predikat,
  status_lulus(nilai_angka)      AS status
FROM  view_nilai_mahasiswa
ORDER BY nilai_angka DESC;


-- Sekarang jalankan procedure tampil_nilai_by_nim (dari 4.5)
CALL tampil_nilai_by_nim('23001');
CALL tampil_nilai_by_nim('23003');


-- ============================================================
--  BAGIAN 6 — MELIHAT & MENGHAPUS OBJECT DATABASE
-- ============================================================

-- Melihat semua VIEW
SHOW FULL TABLES
WHERE Table_type = 'VIEW';

-- Melihat semua STORED PROCEDURE
SHOW PROCEDURE STATUS
WHERE Db = 'db_akademik';

-- Melihat semua FUNCTION
SHOW FUNCTION STATUS
WHERE Db = 'db_akademik';

-- Melihat semua TRIGGER
SHOW TRIGGERS;

-- Melihat definisi object tertentu
SHOW CREATE VIEW      view_nilai_mahasiswa;
SHOW CREATE PROCEDURE tampil_semua_mahasiswa;
SHOW CREATE FUNCTION  konversi_grade;
SHOW CREATE TRIGGER   trg_after_insert_nilai;


-- ============================================================
--  BAGIAN 7 — VERIFIKASI AKHIR
-- ============================================================

-- Cek semua tabel
SELECT 'mahasiswa'   AS tabel, COUNT(*) AS total FROM mahasiswa
UNION ALL
SELECT 'mata_kuliah' AS tabel, COUNT(*) AS total FROM mata_kuliah
UNION ALL
SELECT 'nilai'       AS tabel, COUNT(*) AS total FROM nilai
UNION ALL
SELECT 'log_nilai'   AS tabel, COUNT(*) AS total FROM log_nilai;

-- Laporan lengkap dengan semua function
SELECT
  m.nim,
  m.nama,
  m.jurusan,
  mk.kode_mk,
  mk.nama_mk,
  mk.sks,
  n.nilai_angka,
  konversi_grade(n.nilai_angka)    AS grade,
  konversi_predikat(n.nilai_angka) AS predikat,
  status_lulus(n.nilai_angka)      AS status,
  n.tanggal_input
FROM   nilai        n
JOIN   mahasiswa    m  ON n.id_mahasiswa = m.id_mahasiswa
JOIN   mata_kuliah  mk ON n.id_mk        = mk.id_mk
ORDER BY m.nim, mk.kode_mk;

-- Log semua perubahan nilai
SELECT * FROM log_nilai ORDER BY waktu_log;


-- ============================================================
--  OPSIONAL — HAPUS OBJECT (jalankan jika ingin bersih)
-- ============================================================

/*
DROP VIEW IF EXISTS view_mahasiswa_informatika;
DROP VIEW IF EXISTS view_nilai_mahasiswa;
DROP VIEW IF EXISTS view_mahasiswa_2023;
DROP VIEW IF EXISTS view_laporan_nilai;

DROP TRIGGER IF EXISTS trg_after_insert_nilai;
DROP TRIGGER IF EXISTS trg_after_update_nilai;
DROP TRIGGER IF EXISTS trg_before_insert_nilai;
DROP TRIGGER IF EXISTS trg_after_delete_nilai;

DROP PROCEDURE IF EXISTS tampil_semua_mahasiswa;
DROP PROCEDURE IF EXISTS cari_mahasiswa_by_jurusan;
DROP PROCEDURE IF EXISTS tambah_nilai;
DROP PROCEDURE IF EXISTS hitung_jumlah_mahasiswa;
DROP PROCEDURE IF EXISTS tampil_nilai_by_nim;
DROP PROCEDURE IF EXISTS tambah_mahasiswa;
DROP PROCEDURE IF EXISTS hitung_nilai_by_mk;

DROP FUNCTION IF EXISTS konversi_grade;
DROP FUNCTION IF EXISTS status_lulus;
DROP FUNCTION IF EXISTS konversi_predikat;

DROP DATABASE IF EXISTS db_akademik;
*/

-- ============================================================
--  SELESAI — Modul Basis Data VII
-- ============================================================
