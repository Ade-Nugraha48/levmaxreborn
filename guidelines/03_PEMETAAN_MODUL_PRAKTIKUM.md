# PANDUAN 03: PEMETAAN KEPATUHAN MODUL PRAKTIKUM (MODUL 2 – 8)

Dokumen ini adalah **senjata utama** saat dosen penguji bertanya:
> *"Di mana kamu menerapkan materi Modul X di kodinganmu?"*

Tabel dan penjelasan di bawah ini memetakan setiap materi praktikum dari silabus mata kuliah Pemrograman Aplikasi Mobile langsung ke berkas kode (*file path*) di dalam project LevMax.

---

## 📋 Tabel Pemetaan Cepat

| Modul | Topik Materi | Penerapan Nyata di LevMax | Lokasi File Kode Utama |
| :---: | :--- | :--- | :--- |
| **Modul 2** | **Basic Flutter Widgets** | Desain seluruh 13 layar UI menggunakan `Scaffold`, `AppBar`, `Container`, `Column`, `Row`, `Stack`, `ListView`, `GridView`, `ElevatedButton`, `OutlinedButton`, `CustomPaint`, `SvgPicture/Icons`. | [view/pages/](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/) & [view/widgets/](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/widgets/) |
| **Modul 3** | **StatefulWidget & Form Handling** | Pengelolaan input form dengan `TextEditingController`, validasi field kosong/panjang password, *conditional rendering* (ganti tampilan saat Standby vs Tracking), dan tombol stepper repetisi dengan `setState()`. | [register_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/register_page.dart), [workout_detail_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/workout_detail_page.dart) |
| **Modul 4** | **Navigation & Routing** | Navigasi halaman bertumpuk (*stack*), pengiriman parameter/argumen (`Get.arguments`), `BottomNavigationBar` dengan 4 tab via `IndexedStack`, dan route guarding (*pop/offAll*). | [app_routes.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/routes/app_routes.dart), [main_shell_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/main_shell_page.dart) |
| **Modul 5** | **HTTP & REST API** | Mengambil data JSON secara asinkron (`async/await`) dari 2 API publik (Quotes motivasi & Cuaca Open-Meteo), decoding JSON, konversi ke Model Class, loading state, dan *offline fallback*. | [api_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/api_service.dart), [quote_controller.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/controller/quote_controller.dart) |
| **Modul 6** | **Local Storage (SP & Hive)** | Sesi login di `SharedPreferences`; Database lokal NoSQL `Hive` (4 Box: `users`, `quest_logs`, `grooming_items`, `daily_quest_states`) lengkap dengan registrasi `TypeAdapter` dan operasi **Full CRUD**. | [session_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/session_service.dart), [hive_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/hive_service.dart), [grooming_controller.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/controller/grooming_controller.dart) |
| **Modul 7** | **LBS (GPS) & Notifications** | Pelacakan GPS real-time via `geolocator`, rendering peta OpenStreetMap via `flutter_map`, perhitungan jarak, filter kecepatan anti-cheat, notifikasi lokal instan (Level Up/Quest) & terjadwal (19:00 Reminder). | [location_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/location_service.dart), [notification_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/notification_service.dart), [cardio_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/cardio_page.dart) |
| **Modul 8** | **GetX State & DI** | Arsitektur MVC GetX: Reactive variables (`.obs`), builder otomatis (`Obx()`), Dependency Injection (`Get.put`, `Get.lazyPut`, `Bindings`), dan navigasi deklaratif GetX (`Get.toNamed`, `Get.snackbar`, `Get.dialog`). | [app_bindings.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/routes/app_bindings.dart), seluruh file di [controller/](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/controller/) |

---

## 🔍 Penjelasan Rinci Per Modul

### 1. Modul 2: Basic Widgets
- **Apa yang dipelajari**: Tata letak dasar Flutter (`Row`, `Column`, `Stack`, `Container`, `Scaffold`, dsb.).
- **Di mana diterapkan di LevMax**:
  - `PlayerStatusCard`: Menggabungkan `Stack`, `Container` bergradasi warna neon, `LinearProgressIndicator` kustom, dan `Row` untuk telemetry angka.
  - `StatRadarChart`: Menggunakan package `fl_chart` untuk menggambar bagan radar heksagonal 6 dimensi.
  - `WorkoutDetailPage`: Menggunakan `Column`, `Row`, tombol `ElevatedButton`, dan bilah bersegmen untuk menampilkan repetisi latihan.

### 2. Modul 3: State & Data Handling
- **Apa yang dipelajari**: Perbedaan `Stateless` vs `Stateful`, form input, controller teks, dan `setState`.
- **Di mana diterapkan di LevMax**:
  - [register_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/register_page.dart): Menggunakan `TextEditingController` untuk username dan password, serta `Checkbox` untuk persetujuan aturan protokol sistem.
  - [workout_detail_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/workout_detail_page.dart): Menggunakan `setState()` untuk meng-update angka repetisi saat tombol `[+]` dan `[-]` diklik, serta menghitung status tombol selesai secara dinamis.
  - [study_detail_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/study_detail_page.dart): Menggunakan `Timer.periodic` dan `setState()` untuk menjalankan hitung mundur waktu belajar detik demi detik.

### 3. Modul 4: Navigation
- **Apa yang dipelajari**: Navigasi antar halaman, oper data antar layar, dan menu bawah.
- **Di mana diterapkan di LevMax**:
  - [main_shell_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/main_shell_page.dart): Menggunakan `IndexedStack` untuk membungkus 4 tab utama (`HOME`, `MAP`, `STATS`, `PROFILE`). Kelebihannya: state masing-masing tab tidak ter-reset saat berpindah tab.
  - [app_pages.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/routes/app_pages.dart): Mengelola routing berbasis string seperti `AppRoutes.workoutDetail` lengkap dengan pengiriman argumen `Get.arguments`.

### 4. Modul 5: HTTP & REST API
- **Apa yang dipelajari**: Mengambil data online via internet, JSON parsing, dan error handling.
- **Di mana diterapkan di LevMax**:
  - [api_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/api_service.dart):
    - `fetchDailyQuote()`: Memanggil DummyJSON API (`https://dummyjson.com/quotes/random`).
    - `fetchCurrentWeather()`: Memanggil Open-Meteo Weather API (`https://api.open-meteo.com/v1/forecast`).
  - Dilengkapi `try-catch` dan fallback data default sehingga aplikasi tetap berjalan mulus meskipun mode pesawat aktif.

### 5. Modul 6: Local Storage (Penyimpanan Lokal)
- **Apa yang dipelajari**: Menyimpan data di memori internal ponsel agar tidak hilang saat aplikasi ditutup.
- **Di mana diterapkan di LevMax**:
  - [session_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/session_service.dart): Menggunakan `SharedPreferences` untuk menyimpan boolean `isLoggedIn`, username yang sedang aktif, dan setting skip rest timer.
  - [hive_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/hive_service.dart): Menginisialisasi database NoSQL Hive dengan 4 Box.
  - [grooming_controller.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/controller/grooming_controller.dart): Menunjukkan operasi **Full CRUD Hive**:
    - *Create*: `box.add(item)`
    - *Read*: `box.values.toList()`
    - *Update*: `item.save()` (mengubah centang atau nama)
    - *Delete*: `item.delete()` (menghapus item)

### 6. Modul 7: LBS (Location Based Services) & Notifikasi
- **Apa yang dipelajari**: GPS perangkat dan notifikasi lokal Android.
- **Di mana diterapkan di LevMax**:
  - [location_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/location_service.dart): Meminta izin lokasi (`checkPermission` & `requestPermission`), menyalakan stream posisi GPS via `Geolocator.getPositionStream`, dan memfilter batas kecepatan lari maksimal 24 km/jam.
  - [cardio_page.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/view/pages/cardio_page.dart): Menampilkan peta interaktif `flutter_map` dengan koordinat pengguna dan menggambar garis rute perjalanan.
  - [notification_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/notification_service.dart): Menggunakan `flutter_local_notifications` untuk:
    - *Immediate Notification*: Notifikasi instan saat quest selesai, Level Up, Rank Up, atau Achievement terbuka.
    - *Scheduled Notification*: Pengingat harian pukul 19:00 menggunakan zona waktu lokal (`timezone`).

### 7. Modul 8: GetX State Management
- **Apa yang dipelajari**: State management modern, reaktivitas, dan Dependency Injection.
- **Di mana diterapkan di LevMax**:
  - Variabel reaktif `.obs` (misal: `RxInt exp = 0.obs;`, `RxList logs = <QuestLogModel>[].obs;`).
  - Widget `Obx(() => ...)` yang otomatis merender ulang hanya bagian widget yang datanya berubah tanpa perlu memuat ulang seluruh layar.
  - [app_bindings.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/routes/app_bindings.dart): Menginject controller ke memori secara rapi dengan `Get.put()` dan `Get.lazyPut()`.
