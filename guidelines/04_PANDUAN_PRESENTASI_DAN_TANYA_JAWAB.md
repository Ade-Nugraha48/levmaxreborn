# PANDUAN 04: PANDUAN PRESENTASI & CONTEKAN TANYA JAWAB DOSEN

Dokumen ini adalah **panduan praktis untuk kamu saat maju ke depan kelas atau ruang sidang**. Jangan panik jika kamu merasa kemampuan coding-mu standar—sebagai mahasiswa Sistem Informasi, kekuatan utamamu adalah **memahami alur sistem, logika bisnis, dan bagaimana teknologi ini memecahkan masalah nyata**.

---

## 🎤 Skrip Pembuka Presentasi (2 Menit)

> *"Selamat pagi/siang Bapak/Ibu Dosen penguji dan teman-teman sekalian.*
> 
> *Perkenalkan, saya [Nama Kamu]. Pada kesempatan kali ini, saya ingin mempresentasikan Final Project Praktikum Pemrograman Aplikasi Mobile yang berjudul **LevMax**.*
> 
> *Banyak orang mengalami kesulitan dalam menjaga konsistensi self-improvement—baik itu olahraga, belajar fokus, maupun kebiasaan harian—karena aktivitas tersebut terasa membosankan dan tidak memberikan kepuasan instan (*instant reward*).*
> 
> *Oleh karena itu, **LevMax** hadir dengan mengadopsi konsep **Gamifikasi RPG**. Di aplikasi ini, setiap aktivitas produktif di dunia nyata diubah menjadi Daily Quest yang memberikan EXP, menaikkan Level, meningkatkan 6 statistik atribut, menaikkan Rank, dan membuka Achievements.*
> 
> *Aplikasi ini dibangun menggunakan framework **Flutter** dengan arsitektur **MVC GetX**, database lokal cepat **Hive**, dan mengintegrasikan seluruh materi dari **Modul 2 hingga Modul 8** secara komprehensif. Izinkan saya mendemonstrasikan cara kerja sistem ini."*

---

## 📱 Skenario Alur Demo Aplikasi (Langkah Demi Langkah)

Ikuti urutan demo ini di HP/emulator agar presentasimu terlihat sangat terstruktur dan meyakinkan:

1. **Langkah 1: Registrasi & Validasi Form**
   - Buka aplikasi -> Tampilkan halaman Register.
   - *Tunjukkan:* Coba klik tombol Register saat form kosong -> Tunjukkan validasi error.
   - *Tunjukkan:* Tunjukkan checkbox persetujuan protokol yang wajib dicentang.
   - Masukkan username & password baru -> Klik Register.
   - *Jelaskan:* "Setelah registrasi, sistem mengarahkan user ke halaman Login untuk memastikan kredensial benar-benar berfungsi."
2. **Langkah 2: Login & Home Dashboard**
   - Masuk dengan akun baru -> Tampilkan Home.
   - *Tunjukkan:* Kartu HUD Status di atas: Level 1, EXP 0/100, HP 100, Rank Novice.
   - *Tunjukkan:* Quote motivasi harian yang diambil secara online dari REST API DummyJSON.
   - *Tunjukkan:* Hitung mundur `RESET HH:MM:SS` menuju jam 00:00:00.
3. **Langkah 3: Demo Workout Quest**
   - Klik kartu Workout (misal: Push Ups).
   - *Tunjukkan:* Sesi mulai dari Set 1 dan 0 reps. Tombol selesai masih nonaktif (*disabled*).
   - Tekan tombol `[+]` sampai 8 reps -> Bilah cadence bertambah dan tombol `COMPLETE SET 1` menyala.
   - Klik `COMPLETE SET 1` -> Rest Timer 30 detik aktif. Klik `SKIP REST` untuk mempercepat demo.
   - Pada Set 2, isi repetisi penuh -> Bilah menunjukkan **`100% CADENCE`**.
   - Klik `COMPLETE WORKOUT` -> Muncul pop-up **`WORKOUT PROTOCOL COMPLETE`** yang merinci volume repetisi dan reward `+2 STR, +1 END, +25 EXP`.
4. **Langkah 4: Demo Study Lock-In**
   - Buka kartu Study.
   - Tekan `START LOCK-IN` -> Timer hitung mundur berjalan.
   - *Tunjukkan fitur anti-distraksi:* Tekan tombol Home di HP/emulator (keluar aplikasi) selama beberapa detik, lalu buka kembali -> Tunjukkan bahwa sistem mendeteksi jeda dan men-pause timer.
5. **Langkah 5: Demo Tab MAP & Cardio LBS (GPS Tracking)**
   - Pindah ke Tab `MAP` di navigasi bawah.
   - *Tunjukkan:* Peta bertema gelap (Dark Mode) menggunakan `flutter_map` (OpenStreetMap).
   - *Tunjukkan:* Widget cuaca real-time yang mengambil data suhu dari Open-Meteo REST API.
   - Klik `START CARDIO` -> Mode berubah ke Tracking Mode.
   - Di tab Profile -> Developer Controls, klik **`SIMULATE CARDIO +500M`** untuk mendemokan pergerakan jarak dan pace lari tanpa harus berlari di dalam ruangan sidang.
6. **Langkah 6: Demo Daily Grooming (Full CRUD Hive)**
   - Buka kartu Grooming.
   - *Create:* Tambahkan item baru: `"Minum Vitamin"`.
   - *Update:* Centang checklist atau ubah namanya.
   - *Delete:* Geser/klik ikon sampah untuk menghapus item.
   - *Jelaskan:* "Ini adalah implementasi Full CRUD (Create, Read, Update, Delete) yang tersimpan langsung di database lokal Hive."
7. **Langkah 7: Demo Tab Stats (Radar Chart & Sejarah)**
   - Buka Tab `STATS`.
   - *Sub-Tab ATTRIBUTES:* Tunjukkan **Hexagonal Radar Chart** 6 sudut (`STR, END, SPD, INT, WIL, APP`) dan daftar Quest Log.
   - *Sub-Tab SEJARAH:* Tunjukkan grafik garis **Growth Trajectory** yang mencatat kenaikan total stats, serta 4 kartu Lifetime Records (Total Reps, Jarak Lari, dsb.).
8. **Langkah 8: Demo Developer Controls (Panel Ujian)**
   - Buka Tab `PROFILE` -> Buka menu **`DEVELOPER DEMO CONTROLS`**.
   - *Uji Penalti HP:* Klik **`-34 HP (MISSED DAY)`** -> Tunjukkan di Home bahwa HP berkurang dari 100 menjadi 66 HP. Klik **`RESTORE HP (100)`** untuk mengembalikan darah.
   - *Uji Level Up:* Klik **`+300 EXP (LEVEL UP)`** -> Tunjukkan notifikasi Level Up instan dan penambahan +2 poin ke semua 6 stats.
   - *Uji Rank:* Klik **`+50 ALL STATS`** -> Tunjukkan rank user langsung naik.

---

## 🧠 Contekan Jawaban Jitu untuk 15+ Pertanyaan Dosen Penguji

Berikut adalah daftar pertanyaan yang paling sering ditanyakan dosen penguji lengkap dengan contekan jawabannya:

### Q1: "Kenapa kamu memilih menggunakan Hive daripada SQLite untuk database lokal?"
> **Jawaban:**  
> "Ada 3 alasan utama, Pak/Bu:
> 1. **Performa Kecepatan**: Hive berbasis NoSQL murni dalam Dart (*pure Dart*), sehingga proses read dan write jauh lebih cepat daripada SQLite karena tidak ada lapisan perantara (*overhead*) native bridge.
> 2. **Struktur Data Kompleks**: Di aplikasi game ini, banyak data bertipe `List` dan `Map` (seperti `growthSnapshots`, `rankHistory`, dan `unlockedAchievements`). Di SQLite kita harus mengonversi bolak-balik ke JSON string, sedangkan di Hive data tersebut bisa disimpan langsung sebagai objek native.
> 3. **Type Safety**: Dengan `TypeAdapter`, Hive menjamin tipe data aman saat dibaca dari database."

---

### Q2: "Apa perbedaan kegunaan SharedPreferences dan Hive di aplikasi ini?"
> **Jawaban:**  
> "Kami membagi penyimpanan lokal menjadi 2 lapis:
> - **SharedPreferences** digunakan khusus untuk data konfigurasi dan sesi sederhana yang berbentuk *key-value*, seperti `isLoggedIn` (apakah user sudah login) dan `activeUsername`.
> - **Hive** digunakan untuk database inti yang menyimpan kumpulan objek data (*collection*), seperti data lengkap profil user, riwayat ribuan log quest, checklist grooming, dan status harian."

---

### Q3: "Bagaimana arsitektur GetX diimplementasikan di project ini?"
> **Jawaban:**  
> "Aplikasi ini memisahkan kode menggunakan arsitektur **MVC (Model-View-Controller)** yang disediakan oleh GetX:
> - **Model** (`lib/model/`): Mendefinisikan struktur data.
> - **View** (`lib/view/`): Hanya berisi tata letak widget tampilan antarmuka. View mendengarkan perubahan data menggunakan `Obx()`.
> - **Controller** (`lib/controller/`): Mengelola variabel reaktif (`.obs`) dan logika bisnis (misal menghitung repetisi, EXP, Level Up).
> - **Binding** (`lib/routes/app_bindings.dart`): Menginjeksi (*Dependency Injection*) controller ke memori secara otomatis menggunakan `Get.put()` dan `Get.lazyPut()`, sehingga kode sangat rapi dan hemat memori."

---

### Q4: "Bagaimana aplikasi mendeteksi pergantian hari untuk Daily Reset jam 00:00?"
> **Jawaban:**  
> "Setiap kali aplikasi dibuka atau dipanggil dari background, fungsi `runDailyResetCheck()` di `QuestController` membandingkan tanggal hari ini (`today` dalam format `YYYY-MM-DD`) dengan field `user.lastActiveDate` di database Hive.
> - Jika selisih hari (`deltaDays`) sama dengan 0, berarti masih di hari yang sama.
> - Jika selisih hari >= 1, sistem otomatis mengeksekusi logika streak, pemotongan HP jika bolos, dan mengacak 2 latihan workout baru untuk hari yang baru."

---

### Q5: "Kenapa saat user bolos 3 hari dan terkena penalti, HP-nya di-reset kembali ke 100?"
> **Jawaban:**  
> "Sesuai aturan gamifikasi di PRD kami, HP berfungsi sebagai *buffer* atau toleransi kedisiplinan.
> - Bolos hari ke-2: HP dipotong -34 (sisa 66 HP).
> - Bolos hari ke-3: HP menyentuh 0 HP.
> Ketika HP menyentuh 0 HP, **hukuman sesungguhnya dieksekusi**: seluruh 6 stats user dipotong 1 strata ke bawah (misal Rank turun dari C ke D).
> Setelah hukuman pemotongan stats selesai dijalankan, sistem secara otomatis **memulihkan HP kembali ke 100 (*revival protocol*)** agar akun user tidak 'mati permanen' atau *game over* selamanya, sehingga user memiliki kesempatan untuk memperbaiki diri di hari berikutnya."

---

### Q6: "Bagaimana cara kerja anti-cheat pada fitur lari Cardio GPS?"
> **Jawaban:**  
> "Di file `location_service.dart`, kami menerapkan validasi kecepatan lari:
> Sistem menghitung jarak antara titik GPS sebelumnya dan titik GPS baru dibagi selisih waktu tempuhnya. Jika kecepatan lari terdeteksi **lebih dari 24 km/jam**, titik koordinat tersebut otomatis ditolak dan tidak dihitung ke dalam jarak tempuh. Hal ini mencegah kecurangan pengguna yang menggunakan sepeda motor atau mobil saat menyelesaikan quest lari."

---

### Q7: "Kenapa EXP dan Level tidak pernah berkurang saat terkena penalti?"
> **Jawaban:**  
> "Dalam psikologi gamifikasi self-improvement, EXP dan Level merepresentasikan **jam terbang dan usaha kumulatif** yang sudah dilakukan pengguna di masa lalu. Jam terbang tidak boleh hilang karena akan membuat pengguna putus asa (*demotivated*). Yang berkurang akibat malas adalah **performa/kondisi fisik (Stats & Rank)**, bukan jam terbang (Level)."

---

### Q8: "Bagaimana rumus perhitungan Level Up di aplikasi ini?"
> **Jawaban:**  
> "Kami menggunakan **kurva EXP kuadratik** di `stat_calculator.dart`:
> `targetExp = (100 * level) + (25 * level * (level - 1))`
> Dengan rumus ini:
> - Level 1 ke 2 butuh 100 EXP.
> - Level 2 ke 3 butuh 250 EXP.
> - Level 5 ke 6 butuh 1.000 EXP.
> Kurva ini membuat naik level di awal terasa cepat dan memuaskan, namun semakin tinggi levelnya, usaha yang dibutuhkan akan semakin menantang (*progressive overload*)."

---

### Q9: "Bagaimana integrasi REST API bekerja jika perangkat pengguna sedang offline?"
> **Jawaban:**  
> "Seluruh panggilan REST API di `api_service.dart` dibungkus dalam blok `try-catch` dengan timeout. Jika request gagal karena tidak ada koneksi internet, sistem secara otomatis menggunakan **data cadangan (*graceful fallback*)**:
> - Untuk quote: menggunakan kutipan default sistem.
> - Untuk cuaca: menggunakan data cuaca default (26°C · Cloudy).
> Dengan begitu, antarmuka pengguna tidak akan memunculkan layar merah (*red screen of death*) atau force close saat offline."

---

### Q10: "Bagaimana cara kerja notifikasi terjadwal pukul 19:00?"
> **Jawaban:**  
> "Menggunakan package `flutter_local_notifications` dan `timezone`. Sistem mendaftarkan jadwal notifikasi harian pada jam 19:00 waktu lokal HP. Karena ini dijadwalkan langsung ke AlarmManager sistem operasi Android, notifikasi akan tetap berbunyi tepat waktu meskipun aplikasi LevMax sedang ditutup atau dikeluarkan dari recent apps."

---

### Q11: "Di mana letak operasi Full CRUD di aplikasi ini?"
> **Jawaban:**  
> "Operasi CRUD (Create, Read, Update, Delete) lengkap diimplementasikan pada fitur **Daily Grooming** (`grooming_controller.dart`):
> 1. **Create**: Menambah item kebiasaan baru ke box `grooming_items` menggunakan `box.add()`.
> 2. **Read**: Menampilkan daftar item checklist menggunakan `box.values.toList()`.
> 3. **Update**: Mengubah status centang checklist atau mengedit nama item menggunakan `item.save()`.
> 4. **Delete**: Menghapus item kustom dari database menggunakan `item.delete()`."

---

### Q12: "Apa fungsi tombol Developer Demo Controls di tab Profil?"
> **Jawaban:**  
> "Tombol Developer Demo Controls sengaja kami buat khusus untuk mempermudah pengujian dan demonstrasi sistem di depan dosen:
> - Menguji pemotongan HP tanpa harus menunggu bolos 1 hari.
> - Menguji kenaikan level tanpa harus menunggu menyelesaikan 4 quest.
> - Menguji kenaikan rank tanpa harus berolahraga ratusan kali.
> - Menambahkan simulasi jarak lari +500 meter tanpa harus berlari sungguhan di dalam ruangan."

---

### Q13: "Bagaimana cara radar chart 6 stats tetap aman saat akun baru bernilai 0?"
> **Jawaban:**  
> "Di file `stat_radar_chart.dart`, kami menambahkan guard clause: jika seluruh 6 stats bernilai 0, sistem memberikan nilai *dummy* visual yang sangat kecil (0.01) untuk merender garis luar radar chart tanpa menyebabkan error pembagian nol (*division by zero*) atau crash pada package `fl_chart`."

---

### Q14: "Apa keunggulan penggunaan IndexedStack pada BottomNavigationBar?"
> **Jawaban:**  
> "Di file `main_shell_page.dart`, kami menggunakan `IndexedStack` untuk membungkus ke-4 tab. Berbeda dengan `Navigator.push` biasa yang menghancurkan widget saat berpindah layar, `IndexedStack` menjaga semua widget tetap hidup di memori. Sehingga saat pengguna berpindah dari tab MAP ke tab HOME lalu kembali lagi ke MAP, sesi lari GPS dan posisi peta tidak hilang atau ter-reset."

---

### Q15: "Pesan Penutup Presentasi"
> *"Demikian presentasi dari sistem aplikasi LevMax. Aplikasi ini membuktikan bahwa penggabungan konsep sistem informasi, gamifikasi psikologis, dan teknologi mobile Flutter dapat menciptakan solusi nyata untuk meningkatkan produktivitas harian. Terima kasih atas perhatian Bapak/Ibu Dosen, saya siap menerima masukan dan pertanyaan."*
