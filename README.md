# UTS Pengkodean Akuntansi
## Desain Database, Otomasi Persediaan, dan Prototype Voucher Kas Keluar

Repository ini dibuat untuk memenuhi tugas Ujian Tengah Semester (UTS) mata kuliah **Pemrograman / Coding** pada Program Studi S1 Akuntansi, Fakultas Ekonomika dan Bisnis, Universitas Diponegoro.

Proyek ini mencakup perancangan basis data relasional, penerapan integritas jurnal debit dan kredit, otomasi transaksi persediaan menggunakan PostgreSQL, serta pembuatan prototype formulir voucher kas keluar berbasis web yang dilengkapi validasi keseimbangan jurnal dan rancangan mekanisme audit trail.

---

## Identitas Mahasiswa

- **Nama:** Imanina Nur Shadrina
- **NIM:** 12030124140230
- **Kelas:** D
- **Mata Kuliah:** Pemrograman / Coding
- **Dosen Pengampu:** Dr. Totok Dewayanto, S.E., M.Si., Akt.
- **Program Studi:** S1 Akuntansi
- **Fakultas:** Ekonomika dan Bisnis
- **Universitas:** Universitas Diponegoro

---

## Tujuan Proyek

1. Merancang skema database akuntansi relasional dengan memperhatikan normalisasi dan integritas data.
2. Menerapkan kontrol transaksi jurnal agar total debit sama dengan total kredit sebelum jurnal diposting.
3. Mengembangkan otomasi bisnis persediaan melalui stored procedure dan database trigger.
4. Membuat prototype formulir voucher kas keluar dengan kalkulasi debit dan kredit secara otomatis.
5. Mendokumentasikan penggunaan AI generatif untuk membantu perancangan antarmuka dan verifikasi aturan bisnis.
6. Merancang mekanisme audit trail, penguncian transaksi yang telah diposting, dan pemeriksaan integritas data.

---

## Teknologi yang Digunakan

- **PostgreSQL** — basis data relasional dan implementasi aturan integritas.
- **SQL / PL/pgSQL** — pembuatan tabel, fungsi, trigger, dan skrip pengujian.
- **HTML, CSS, dan JavaScript** — prototype antarmuka voucher kas keluar.
- **Gemini Canvas** — alat bantu perancangan antarmuka melalui prompt.
- **NotebookLM** — alat bantu untuk mengkaji aturan bisnis berdasarkan sumber standar akuntansi.
- **GitHub** — penyimpanan kode sumber dan dokumentasi proyek.

---

## Struktur Repository

```text
UTS_Imanina-Nur-Shadrina/
├── README.md
├── 01_schema_jurnal.sql
├── 02_inventory_trigger.sql
├── 03_voucher_audit.sql
├── 04_test_jurnal.sql
├── 05_test_persediaan.sql
├── index.html
├── prompt_gemini_canvas.txt
└── prompt_notebooklm.txt
```

### Keterangan File

| File | Fungsi |
|---|---|
| `01_schema_jurnal.sql` | Membuat struktur tabel akun, header jurnal, detail jurnal, serta validasi keseimbangan debit dan kredit. |
| `02_inventory_trigger.sql` | Berisi implementasi otomasi dan validasi transaksi persediaan menggunakan PostgreSQL. |
| `03_voucher_audit.sql` | Berisi rancangan database voucher kas keluar, audit log, mekanisme posting, checksum, dan perlindungan transaksi yang telah diposting. |
| `04_test_jurnal.sql` | Berisi skrip pengujian aturan integritas jurnal. |
| `05_test_persediaan.sql` | Berisi skrip pengujian aturan transaksi persediaan. |
| `index.html` | Prototype antarmuka formulir voucher kas keluar. |
| `prompt_gemini_canvas.txt` | Dokumentasi prompt untuk membantu pembuatan antarmuka menggunakan Gemini Canvas. |
| `prompt_notebooklm.txt` | Dokumentasi prompt untuk membantu kajian aturan bisnis menggunakan NotebookLM. |

---

## Soal 1 — Desain Arsitektur Data, Normalisasi, dan Integritas Jurnal

### 1.1 Perancangan Skema Relasional

Perancangan database menggunakan tiga tabel utama:

- **`chart_of_accounts`**: menyimpan kode akun, nama akun, saldo normal, dan klasifikasi laporan.
- **`journal_headers`**: menyimpan informasi umum jurnal, seperti tanggal transaksi, nomor referensi, deskripsi, dan status posting.
- **`journal_lines`**: menyimpan rincian akun dan nilai debit atau kredit pada setiap baris jurnal.

Relasi antar tabel:

- Satu header jurnal dapat memiliki banyak baris jurnal.
- Satu akun dapat digunakan pada banyak baris jurnal.
- Setiap baris jurnal harus mengacu pada satu header dan satu akun yang valid.

### 1.2 Penerapan Integritas Database

File `01_schema_jurnal.sql` menerapkan beberapa pengendalian, yaitu:

- Primary Key untuk mengidentifikasi setiap data.
- Foreign Key dengan `ON DELETE RESTRICT` untuk menjaga referensi antar tabel.
- Unique constraint pada kode akun dan nomor referensi jurnal.
- Check constraint untuk memastikan nilai debit dan kredit tidak negatif.
- Larangan baris jurnal dengan debit dan kredit sama-sama nol.
- Larangan pengisian debit dan kredit positif secara bersamaan pada satu baris.
- Trigger untuk memvalidasi jumlah debit dan kredit ketika jurnal diubah menjadi status `POSTED`.

Prinsip utama yang diterapkan adalah:

**Total Debit = Total Kredit**

Jurnal yang tidak seimbang harus ditolak sebelum proses posting berhasil dilakukan.

### 1.3 Analisis Audit dan Normalisasi

Pemisahan tabel header dan detail membantu mengurangi pengulangan informasi transaksi, menjaga konsistensi data, dan memudahkan penelusuran riwayat jurnal.

Pemisahan data akun, informasi umum jurnal, dan rincian jurnal juga mendukung penerapan prinsip normalisasi hingga Third Normal Form (3NF), dengan tujuan mengurangi redundansi serta anomali penambahan, perubahan, dan penghapusan data.

---

## Soal 2 — Otomasi Bisnis dan Database Trigger Persediaan

Implementasi soal kedua didokumentasikan pada file `02_inventory_trigger.sql`.

Fokus perancangan meliputi:

1. Pengelolaan data barang dan transaksi persediaan.
2. Validasi jumlah barang yang masuk atau keluar.
3. Pencegahan transaksi penjualan yang melebihi stok tersedia.
4. Penggunaan stored procedure atau trigger untuk mengotomatisasi aturan bisnis.
5. Pencegahan inkonsistensi saldo persediaan.
6. Pengujian logika persediaan melalui file `05_test_persediaan.sql`.

### Pengujian

Skrip pengujian disediakan untuk membantu memeriksa perilaku aturan database, termasuk validasi transaksi dan pengendalian stok.

Hasil akhir pengujian perlu didokumentasikan berdasarkan eksekusi aktual di PostgreSQL atau Supabase, misalnya melalui screenshot query dan hasil yang ditampilkan.

---

## Soal 3 — Prototype Voucher Kas Keluar, AI, dan Audit Trail

### 3.1 Prototype Formulir Voucher Kas Keluar

Prototype antarmuka tersedia pada file `index.html`.

Rancangan formulir mencakup:

- Nomor voucher dan tanggal transaksi.
- Deskripsi transaksi.
- Baris jurnal yang dapat ditambah atau dihapus.
- Pengisian akun, debit, dan kredit.
- Perhitungan total debit dan kredit secara otomatis.
- Indikator status keseimbangan jurnal.
- Pengendalian tombol posting berdasarkan validitas input.

Validasi keseimbangan menggunakan prinsip:

`Total Debit = Total Kredit`

Prototype ini berfungsi sebagai demonstrasi antarmuka. Koneksi penyimpanan ke database perlu dinyatakan sesuai implementasi yang benar-benar tersedia.

### 3.2 Pemanfaatan AI Generatif

**Gemini Canvas**

File `prompt_gemini_canvas.txt` menyimpan prompt yang digunakan sebagai dokumentasi instruksi perancangan antarmuka formulir voucher kas keluar.

**NotebookLM**

File `prompt_notebooklm.txt` menyimpan prompt untuk membantu pemeriksaan aturan bisnis terkait pengakuan kas dan setara kas berdasarkan sumber standar akuntansi yang relevan.

Hasil verifikasi NotebookLM perlu dilengkapi berdasarkan sumber resmi yang benar-benar digunakan, termasuk ringkasan temuan, rujukan halaman atau kutipan, serta aturan yang sudah atau belum dapat diverifikasi.

### 3.3 Audit Trail dan Immutability

Implementasi terkait voucher dan audit trail didokumentasikan dalam `03_voucher_audit.sql`.

Rancangan mencakup:

- Penyimpanan data voucher dan detail jurnal.
- Pencatatan aktivitas melalui audit log.
- Validasi keseimbangan jurnal sebelum posting.
- Penguncian transaksi yang telah berstatus `POSTED`.
- Penggunaan `created_by` dan `created_at` untuk mendukung penelusuran transaksi.
- Penggunaan `hash_checksum` untuk membantu memeriksa integritas data.
- Mekanisme jurnal pembalik (*reversing entry*) untuk koreksi transaksi yang telah diposting.

Tujuan rancangan ini adalah menjaga agar transaksi yang sudah diposting tidak dapat diubah atau dihapus secara sembarangan dan agar perubahan memiliki jejak audit.

---

## Dokumentasi Pengujian

File pengujian yang tersedia:

- [`04_test_jurnal.sql`](./04_test_jurnal.sql) — pengujian integritas jurnal.
- [`05_test_persediaan.sql`](./05_test_persediaan.sql) — pengujian aturan persediaan.

Dokumentasi hasil pengujian dapat ditambahkan pada bagian ini dalam bentuk screenshot, misalnya:

1. Struktur tabel database.
2. Hasil pengujian jurnal seimbang dan jurnal tidak seimbang.
3. Hasil pengujian validasi transaksi persediaan.
4. Tampilan formulir voucher kas keluar dengan status seimbang.
5. Hasil kajian NotebookLM beserta sumber yang digunakan.

Screenshot harus berasal dari proses pengujian yang benar-benar dilakukan.

---

## Cara Menjalankan

### A. Menjalankan Skrip SQL

1. Siapkan database PostgreSQL atau project Supabase.
2. Buka SQL Editor atau gunakan klien PostgreSQL.
3. Jalankan skrip sesuai urutan kebutuhan dan dependensi tabel.
4. Periksa apakah tabel, fungsi, dan trigger berhasil dibuat.
5. Jalankan skrip pengujian pada lingkungan database yang sesuai.
6. Simpan screenshot hasil eksekusi untuk dokumentasi tugas.

**Catatan:** Jalankan skrip pengujian pada database uji atau setelah memastikan bahwa data yang digunakan tidak mengganggu data penting. Periksa isi setiap skrip sebelum menjalankannya.

### B. Membuka Prototype Web

1. Unduh atau clone repository.
2. Buka file `index.html` menggunakan browser.
3. Uji penambahan baris jurnal, pengisian debit dan kredit, serta indikator keseimbangan.
4. Ambil screenshot tampilan sebagai dokumentasi.

Prototype frontend tidak otomatis berarti data sudah tersimpan ke database. Status integrasi perlu disesuaikan dengan implementasi yang benar-benar dilakukan.

---

## Tautan Repository

Repository GitHub:

[UTS_Imanina-Nur-Shadrina](https://github.com/imaninashdrina/UTS_Imanina-Nur-Shadrina)

---

## Kesimpulan

Proyek UTS ini mendokumentasikan perancangan database akuntansi relasional, penerapan aturan integritas jurnal, otomasi pengendalian persediaan, serta prototype formulir voucher kas keluar. Proyek juga membahas pemanfaatan AI generatif untuk membantu perancangan antarmuka dan kajian aturan bisnis, serta rancangan audit trail dan perlindungan transaksi yang telah diposting.

Seluruh kode sumber, skrip SQL, prototype web, dan prompt AI disimpan dalam repository GitHub sebagai artefak pendukung pengerjaan Ujian Tengah Semester.

---

**Catatan sebelum pengumpulan:** lengkapi PDF jawaban UTS dengan tautan repository dan screenshot dokumentasi. Pastikan hasil pengujian SQL dan verifikasi NotebookLM sudah benar-benar dilakukan sebelum menyatakan bahwa seluruh pengujian berhasil.
