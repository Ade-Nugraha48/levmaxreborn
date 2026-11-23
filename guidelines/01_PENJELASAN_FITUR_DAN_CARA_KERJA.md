# PANDUAN 01: PENJELASAN SELURUH FITUR & CARA KERJANYA

Panduan ini membahas seluruh fitur yang ada di LevMax secara mendalam dengan bahasa yang santai dan mudah dipahami. Gunakan dokumen ini untuk memahami apa yang terjadi di layar dan apa yang dijalankan oleh sistem di balik layar (*behind the scenes*).

---

## 1. Konsep Dasar Aplikasi: Gamifikasi Self-Improvement

Di LevMax, aktivitas keseharian diubah menjadi sistem game RPG:
- **EXP (Experience Points)**: Poin pengalaman yang didapat saat menyelesaikan misi. Sifatnya **permanen** (tidak pernah turun).
- **Level**: Ditentukan oleh EXP menggunakan **kurva kuadratik**. Setiap kali naik 1 level, **semua 6 stats otomatis naik +2 poin**.
- **6 Core Attributes (Stats)**:
  1. **STR (Strength)**: Didapat dari Workout (`+2` per quest).
  2. **END (Endurance)**: Didapat dari Workout (`+1`) dan Cardio (`+2`).
  3. **SPD (Speed)**: Didapat dari kecepatan lari (*pace*) Cardio (`+1` s/d `+4`).
  4. **INT (Intellect)**: Didapat dari Study Lock-In (`+3`, atau `+4` jika durasi >= 60 menit).
  5. **APP (Appearance)**: Didapat dari Daily Grooming (`+3`).
  6. **WIL (Willpower)**: Didapat dari Login Harian (`+1`), menyelesaikan seluruh 5 quest dalam 1 hari (*Full Clear*, `+2`), dan bonus streak login kelipatan 7 hari (`+1`).
- **HP (Health Points)**: Bernilai maksimal `100`. Merupakan batas toleransi kedisiplinan. Jika bolos 1 hari penuh, HP dipotong `-34`. Jika bolos 3 hari berturut-turut hingga HP `0`, sistem akan mengeksekusi penalti pemotongan stats 1 strata, lalu HP dipulihkan kembali ke `100`.

---

## 2. Fitur Autentikasi & Session (Modul 3, 6, 8)

### A. Registrasi Akun Baru (`RegisterPage`)
1. **Validasi Form Ketat**:
   - Username tidak boleh kosong dan harus **unik** (dicek ke database lokal Hive).
   - Password minimal 6 karakter.
   - Konfirmasi password harus sama persis.
   - Checkbox persetujuan protokol (`PROTOCOL CONSENT`) **wajib dicentang**. Tombol registrasi tidak akan bisa diklik jika belum dicentang.
2. **Auto-Seeding Data Awal**:
   Saat akun pertama kali dibuat, sistem secara otomatis:
   - Membuat akun user di Hive dengan level 1, EXP 0, HP 100, dan stats awal 0 (Rank: Novice).
   - Men-seed 5 checklist grooming default (Minum 2L air, Skincare, dll.).
   - Membuka achievement pertama: `THE AWAKENING`.
   - Mencatat titik awal sejarah pertumbuhan (*growth trajectory*) di hari ke-0.
3. **Alur Setelah Registrasi**:
   Sistem **tidak langsung login otomatis**, melainkan menampilkan snackbar sukses dan mengarahkan pengguna kembali ke halaman **Login** agar pengguna mencoba masuk menggunakan kredensial yang baru saja dibuat.

### B. Login Akun (`LoginPage`)
1. User memasukkan username dan password.
2. Sistem mencocokkan ke Hive box `users`:
   - Jika cocok, status `isLoggedIn = true` dan `activeUsername` disimpan ke dalam **SharedPreferences**.
   - Data user dimuat ke dalam `UserController` yang bersifat reaktif (`GetxController`).
   - Aplikasi berpindah ke halaman utama (`MainShellPage`).

### C. Auto-Login & Splash Screen (`SplashPage`)
- Saat aplikasi dibuka pertama kali, `SplashPage` mengecek `SessionService.isLoggedIn`:
  - Jika `true`, aplikasi langsung memuat data user aktif dan lompat ke halaman Home tanpa perlu login ulang.
  - Jika `false`, aplikasi menampilkan halaman Login.

---

## 3. Fitur Halaman Utama (Home Page)

Layar Home adalah pusat komando harian pengguna yang dibagi menjadi beberapa komponen:

### A. Player Status HUD Card
- Menampilkan foto profil/avatar, nama user, Rank saat ini, dan Level.
- **HP Bar (Warna Neon Pink)**: Menampilkan sisa HP (0 - 100).
- **EXP Bar (Warna Electric Cyan)**: Menampilkan progres EXP menuju level berikutnya secara real-time. Rumusnya menghitung `exp / targetExpForLevel`.

### B. Daily System Quote Card (REST API DummyJSON)
- Menampilkan kutipan motivasi yang diambil secara online via HTTP Request ke endpoint `https://dummyjson.com/quotes/random`.
- Dilengkapi dengan *loading indicator* saat proses fetch dan teks cadangan (*fallback*) jika HP sedang offline/tidak ada internet.

### C. Countdown Timer & Daily Reset (Jam 00:00:00)
- Menampilkan timer hitung mundur sampai tengah malam (`RESET HH:MM:SS`).
- Begitu jam melewati 00:00:00 atau saat aplikasi dibuka di tanggal yang berbeda, sistem otomatis:
  1. Membandingkan `today` dengan `user.lastActiveDate`.
  2. Mengecek apakah kemarin user menyelesaikan minimal 1 quest:
     - Jika ya: `streakDays` bertambah +1 dan user mendapat bonus +1 WIL.
     - Jika kemarin bolos 1 hari: HP dipotong `-34 HP`.
     - Jika bolos 3 hari: Memicu penalti inaktivitas 3 hari (stats turun 1 strata dan HP dipulihkan ke 100).
  3. **Rotasi Quest**: Memilih 2 gerakan Workout baru secara acak dari 4 pilihan (Push Ups, Pull Ups, Squats, Sit Ups) agar berbeda dari hari sebelumnya.
  4. Mereset status quest Study, Cardio, dan Grooming menjadi belum selesai.

### D. Hierarki Quest (Active-First Sorting)
- Quest yang berstatus aktif/belum selesai selalu diposisikan di **bagian atas** dengan tanda *accent stick bar* putih di sisi kiri kartu.
- Quest yang sudah selesai (*DONE*) otomatis berpindah ke **bagian bawah** dengan tampilan redup (*dimmed gray*), sehingga pengguna langsung tahu quest apa yang tersisa.

---

## 4. Cara Kerja 4 Daily Quests Utama

### A. Quest 1: Workout (`WorkoutDetailPage`)
- **Tujuan**: Latihan fisik (Push Ups / Pull Ups / Squats / Sit Ups).
- **Progressive Overload**: Jumlah Set dan Repetisi target disesuaikan secara otomatis berdasarkan Rank user (contoh: Novice 2 set x 8 reps, Saint 4 set x 25 reps).
- **Mekanisme Eksekusi**:
  1. Sesi selalu dimulai dari Set 1 dengan 0 repetisi.
  2. Pengguna menambah/mengurangi repetisi menggunakan tombol stepper `[-]` dan `[+]`.
  3. **Validasi Clamping**: Angka repetisi tidak bisa dikurangi di bawah 0 dan tidak bisa ditambah melebihi target reps.
  4. **Cadence Bar (Cyan)**: Menampilkan persentase repetisi yang sudah selesai secara real-time. Pada set terakhir ketika reps sudah genap, cadence mencapai **100% CADENCE** dan semua bilah menyala.
  5. **Tombol Selesai Terkunci**: Tombol `COMPLETE SET` tidak bisa diklik jika repetisi belum mencapai target penuh atau saat rest timer sedang berjalan.
  6. **Rest Timer (30 Detik)**: Setelah menyelesaikan Set 1, timer istirahat 30 detik otomatis berjalan sebelum masuk ke Set 2. Tersedia tombol `SKIP REST` jika ingin langsung lanjut.
  7. **Pop-up Selesai (`WORKOUT PROTOCOL COMPLETE`)**: Ketika seluruh set tuntas, pop-up modal muncul menampilkan total repetisi, status 100%, perolehan reward (`+2 STR, +1 END, +25 EXP`), serta peringatan Level Up jika level naik.

### B. Quest 2: Study Lock-In (`StudyDetailPage`)
- **Tujuan**: Membantu pengguna fokus belajar/bekerja tanpa terdistraksi HP.
- **Durasi Sesuai Rank**: Novice 25 menit, Enlighted 60 menit, Apostle 120 menit.
- **Mekanisme Anti-Distraksi (Lifecycle Observer)**:
  - Menggunakan `WidgetsBindingObserver` untuk mendeteksi apakah pengguna keluar dari aplikasi (aplikasi masuk ke background).
  - Jika pengguna meninggalkan aplikasi lebih dari 10 detik, timer otomatis di-pause dan sistem menampilkan peringatan pelanggaran protokol (*Disciplinary Violation*).
- **Penyelesaian**: Jika timer hitung mundur berhasil mencapai 00:00 tanpa pelanggaran, quest dinyatakan sukses, memberikan reward **`+3 INT`** (atau `+4 INT` untuk rank Apostle) dan **`+25 EXP`**.

### C. Quest 3: Cardio — Tab MAP / LBS (`CardioPage`)
- **Tujuan**: Aktivitas lari/jogging menggunakan GPS perangkat (*Location Based Services*).
- **Target Jarak Sesuai Rank**: Novice 1.0 km, Rookie 2.0 km, Saint 4.0 km, Apostle 7.0 km.
- **Dua Mode Tampilan**:
  1. **Standby Mode**: Menampilkan peta gelap, info cuaca real-time (Open-Meteo), target jarak rank, dan tombol `START CARDIO`.
  2. **Tracking Mode**: Mengaktifkan streaming GPS (`geolocator.getPositionStream`), menggambar garis rute lari warna pink di peta, serta menghitung jarak kumulatif, durasi, dan rata-rata pace (mnt/km).
- **Fitur Canggih di Balik Layar**:
  - **Peta Dark Mode**: Menggunakan `flutter_map` dengan tile CartoDB Dark Matter tanpa memerlukan API key berbayar.
  - **Cuaca Real-Time (Open-Meteo API)**: Mengambil suhu dan kode cuaca WMO dari koordinat GPS saat ini via REST API publik.
  - **Anti-Cheat Kecepatan**: Sistem memeriksa kecepatan setiap 5 meter. Jika kecepatan lari melebihi 24 km/jam (curiga naik motor/mobil), titik koordinat tersebut ditolak dan tidak dihitung ke dalam jarak.
  - **Proteksi Finish**: Tombol `FINISH RUN` tidak bisa memberikan reward jika jarak belum mencapai target. Pengguna diberi pilihan untuk melanjutkan lari atau membatalkan sesi tanpa reward.
  - **Reward Dinamis**: Memberikan `+2 END`, `+25 EXP`, dan bonus `SPD` berdasarkan pace lari (Pace kencang < 5.5 mnt/km mendapat `+4 SPD`).
  - **Demo Boost (+500m)**: Tombol simulasi untuk keperluan demo di depan dosen agar tidak perlu berlari sungguhan. Menambahkan jarak +500m sekaligus menambah simulasi durasi wajar (+180 detik).

### D. Quest 4: Daily Grooming (`GroomingDetailPage`)
- **Tujuan**: Kebiasaan perawatan diri dan kebersihan harian.
- **Syarat Minimal Checklist Sesuai Rank**: Novice butuh minimal 3 checklist tercentang, Saint butuh 7, Apostle butuh 8.
- **Operasi Database Penuh (Full CRUD Hive)**:
  - **Create**: Pengguna bisa menambah item kebiasaan baru melalui tombol dialog input.
  - **Read**: Menampilkan daftar item checklist yang tersimpan permanen di Hive box `grooming_items`.
  - **Update**: Mengubah status centang (*toggle*) atau mengedit nama item kustom.
  - **Delete**: Menghapus item kustom dari database lokal.
- **Penyelesaian**: Memberikan reward **`+3 APP`** dan **`+25 EXP`**.

---

## 5. Fitur Stats Page: Attributes & Sejarah

Halaman Stats memiliki 2 sub-tab:

### A. Sub-Tab `ATTRIBUTES`
1. **Hexagonal Radar Chart (`fl_chart`)**:
   - Menampilkan grafik jaring laba-laba 6 sudut untuk 6 atribut: `STR, END, SPD, INT, WIL, APP`.
   - Menggunakan skala dinamis 0-100 poin. Tetap aman dirender tanpa crash meskipun akun baru memiliki nilai stats 0.
2. **Matriks Strata 2x3**:
   - Menampilkan kartu untuk masing-masing stat lengkap dengan nilai angka dan badge Strata warna dinamis (E sampai SSS).
3. **Quest Log Archive**:
   - Menampilkan riwayat seluruh aktivitas quest yang pernah diselesaikan.
   - Dilengkapi tombol **Hapus Log** (Delete di Hive box `quest_logs`). Jika log dihapus, daftar riwayat terhapus namun poin stats yang sudah didapat tetap tersimpan aman di profil user.

### B. Sub-Tab `SEJARAH` (Reaktif Real-Time)
1. **Growth Trajectory Line Chart**:
   - Grafik garis yang memvisualisasikan kenaikan total poin statistik pengguna dari hari ke hari (menggunakan data `user.growthSnapshots`).
2. **Lifetime Records HUD (2x2)**:
   - **Quests Cleared**: Total seluruh quest yang pernah diselesaikan.
   - **Longest Streak**: Rekor streak login terpanjang.
   - **Total Cardio**: Total akumulasi jarak lari (KM).
   - **Total Study**: Total akumulasi jam belajar (Jam).
3. **Workout Cumulative Reps**:
   - Menghitung akumulasi repetisi push-up, pull-up, squat, dan sit-up sepanjang waktu langsung dari Hive.
4. **Rank Chronicle**:
   - Timeline riwayat kenaikan rank dari pertama kali mendaftar (Novice) hingga rank tertinggi yang pernah dicapai.

---

## 6. Fitur Achievements Page (Lencana Kehormatan)

Diakses melalui tombol menu di `ProfilePage`:
- Terdapat **8 Achievement** yang dievaluasi secara otomatis setiap kali quest selesai:
  1. `THE AWAKENING`: Terbuka otomatis saat pertama kali register akun.
  2. `FIRST INITIATION`: Menyelesaikan quest pertama.
  3. `IRON VESSEL`: Akumulasi repetisi workout mencapai 1.000 reps.
  4. `WAYFARER`: Akumulasi lari cardio mencapai 50 km.
  5. `PHANTOM VELOCITY` *(Rare / Pink)*: Mencapai pace lari kencang <= 3:59 mnt/km.
  6. `SCHOLAR OF SANCTUM`: Akumulasi waktu belajar mencapai 1.200 menit (20 jam).
  7. `CENTURION`: Menyelesaikan total 100 quest.
  8. `UNBROKEN` *(Rare / Pink)*: Mencapai login streak 30 hari berturut-turut.
- Setiap kali achievement terbuka, sistem langsung memicu notifikasi lokal pop-up di HP.

---

## 7. Fitur System Codex (Panduan Sistem / Guide Page)

Diakses melalui ikon tanda tanya `[?]` di kanan atas `StatsPage`:
- Berfungsi sebagai ensiklopedia aturan game yang menjelaskan:
  1. Aturan perolehan 6 atribut stats.
  2. Syarat naik rank (Novice hingga Apostle).
  3. Rentang Strata nilai (E: 0-29 hingga SSS: >= 200).
  4. Protokol penalti inaktivitas 3 hari.

---

## 8. Fitur Profil & Developer Demo Controls

Diakses melalui tab `PROFILE`:
1. **Header Profil**: Menampilkan foto profil, username, level, dan ringkasan rank.
2. **Tombol Edit Profil**: Membuka halaman untuk mengganti foto profil dari galeri HP (`image_picker`), mengubah username unik, dan mengganti password.
3. **Daily Reminder Switch**: Mengaktifkan/menonaktifkan pengingat notifikasi otomatis pukul 19:00.
4. **Developer Demo Controls (Panel Rahasia Ujian)**:
   Panel collapsible khusus presentasi yang berisi tombol-tombol instan berukuran simetris 3x2:
   - **`-34 HP (MISSED DAY)`**: Mengurangi HP sebesar -34 untuk mensimulasikan bolos 1 hari (100 -> 66 -> 32 HP).
   - **`RESTORE HP (100)`**: Mengembalikan HP kembali penuh ke 100.
   - **`+3 DAYS PENALTY`**: Mensimulasikan bolos 3 hari berturut-turut (menurunkan seluruh stats 1 strata dan mereset HP ke 100).
   - **`+50 ALL STATS`**: Menambah +50 poin ke seluruh 6 stats untuk mendemonstrasikan kenaikan Rank instan.
   - **`+300 EXP (LEVEL UP)`**: Menambah +300 EXP untuk mendemonstrasikan Level Up dan bonus +2 ke seluruh stats.
   - **`SIMULATE CARDIO +500M`**: Menyuntikkan jarak +500 meter ke sesi lari aktif.
   - **`SKIP REST TIMER (WORKOUT)`**: Toggle switch untuk mematikan rest timer 30 detik saat demo workout.
5. **Tombol Logout Session**: Menghapus session di SharedPreferences dengan dialog konfirmasi, lalu mengarahkan kembali ke halaman Login.
