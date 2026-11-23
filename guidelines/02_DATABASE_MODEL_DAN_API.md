# PANDUAN 02: DATABASE, SKEMA MODEL & INTEGRASI REST API

Dokumen ini menjelaskan bagaimana LevMax mengelola penyimpanan data di memori HP (lokal) dan bagaimana aplikasi berkomunikasi dengan server internet (REST API).

---

## 1. Strategi Penyimpanan Data Lokal (Modul 6)

Aplikasi ini menggunakan **dua lapis penyimpanan lokal**:

| Jenis Storage | Teknologi | Fungsi Utama | Alasan Pemilihan |
| :--- | :--- | :--- | :--- |
| **Key-Value Ringan** | `SharedPreferences` | Menyimpan status sesi login (`isLoggedIn`), username aktif (`activeUsername`), setting rest timer, dan pengingat notifikasi harian. | Sangat cepat untuk data boolean/string sederhana, tidak perlu struktur tabel/dokumen. |
| **NoSQL Database Cepat** | `Hive` (`hive_flutter`) | Menyimpan data akun user, riwayat quest log, checklist grooming, dan status daily quest. | Berbasis binary file murni (*pure Dart*), jauh lebih cepat daripada SQLite, tidak memerlukan skema SQL yang rumit, dan mendukung objek Dart kustom melalui `TypeAdapter`. |

---

## 2. Struktur 4 Box Hive (Database Schema)

Hive menyimpan data dalam wadah yang disebut **Box** (mirip seperti tabel di SQL atau koleksi di MongoDB). Di LevMax ada 4 box utama:

### Box 1: `users` (TypeId: 0)
- **Model**: `UserModel`
- **Key**: String `username` (misal: `'sung_jinwoo'`).
- **Fungsi**: Menyimpan seluruh data akun, level, EXP, HP, nilai 6 stats, riwayat rank, daftar achievement yang terbuka, dan riwayat pertumbuhan harian (*growth snapshots*).

### Box 2: `quest_logs` (TypeId: 1)
- **Model**: `QuestLogModel`
- **Key**: String `id` gabungan timestamp (misal: `'sung_jinwoo_1732356000'`).
- **Fungsi**: Mencatat setiap aktivitas yang selesai (nama quest, repetisi/jarak/durasi, EXP yang didapat, reward stats). Digunakan untuk menghitung Lifetime Records dan grafik di tab Sejarah.

### Box 3: `grooming_items` (TypeId: 2)
- **Model**: `GroomingItemModel`
- **Key**: Auto-increment integer (menggunakan `box.add()`).
- **Fungsi**: Menyimpan daftar checklist perawatan diri yang bisa ditambah, dicentang, diedit namanya, atau dihapus secara permanen (Full CRUD).

### Box 4: `daily_quest_states` (TypeId: 3)
- **Model**: `DailyQuestStateModel`
- **Key**: String `${username}_${YYYY-MM-DD}` (misal: `'sung_jinwoo_2026-11-23'`).
- **Fungsi**: Menyimpan status selesai 5 quest pada hari tersebut dan 2 latihan workout yang dirotasi untuk hari itu.

---

## 3. Rincian Skema Model Data (`lib/model/`)

### A. `UserModel` (`user_model.dart`)
Objek utama yang merepresentasikan pengguna aplikasi:
```dart
class UserModel extends HiveObject {
  String username;                  // Identitas login unik
  String password;                  // Kata sandi
  String? photoPath;                // Path file foto lokal dari ImagePicker
  int level;                        // Level pemain (1, 2, 3...)
  int exp;                          // EXP saat ini menuju level berikutnya
  int hp;                           // Darah/kesehatan (0 - 100)
  int strength;                     // Stat STR
  int endurance;                    // Stat END
  int speed;                        // Stat SPD
  int intelligence;                 // Stat INT
  int willpower;                    // Stat WIL
  int appearance;                   // Stat APP
  int streakDays;                   // Jumlah hari login berturut-turut saat ini
  String lastActiveDate;            // Tanggal terakhir buka aplikasi (YYYY-MM-DD)
  DateTime createdAt;               // Tanggal akun dibuat
  int longestStreak;                // Rekor streak login terpanjang
  Map<String, String> rankHistory;  // Riwayat buka rank: {'Novice': '2026-11-20'}
  Map<String, String> unlockedAchievements; // {'the_awakening': '2026-11-20'}
  Map<String, int> growthSnapshots; // Total stats per hari: {'2026-11-20': 120}
}
```
*Catatan:* Model ini memiliki getter otomatis seperti `totalStats` (penjumlahan 6 stats) dan `rank` (menentukan pangkat Novice s/d Apostle berdasarkan total stats dan syarat stat tertinggi).

### B. `QuestLogModel` (`quest_log_model.dart`)
Merekam bukti penyelesaian satu sesi quest:
```dart
class QuestLogModel extends HiveObject {
  String id;                        // Unique ID
  String username;                  // Pemilik log
  String questType;                 // 'workout', 'study', 'cardio', 'grooming'
  String title;                     // Judul quest (contoh: 'PUSH UPS')
  DateTime completedAt;             // Waktu selesai
  int expGained;                    // EXP yang didapat (misal: 25)
  Map<String, int> statRewards;     // {'STR': 2, 'END': 1}
  String metricSummary;             // Teks ringkasan: '16 REPS · BODYWEIGHT'
  String? exerciseName;             // 'Push Ups', 'Squats', dll.
  int repsCount;                    // Jumlah repetisi
  int durationMinutes;              // Menit durasi (Study/Cardio)
  double distanceKm;                // Jarak tempuh lari (KM)
  double paceMinPerKm;              // Rata-rata pace lari
}
```

### C. `GroomingItemModel` (`grooming_item_model.dart`)
Mewakili satu baris kebiasaan perawatan diri:
```dart
class GroomingItemModel extends HiveObject {
  String id;                        // Unique ID item
  String username;                  // Pemilik item
  String title;                     // Nama kebiasaan: 'Minum 2L Air'
  bool isCompleted;                 // Status tercentang (true/false)
  DateTime createdAt;               // Waktu dibuat
}
```

### D. `DailyQuestStateModel` (`daily_quest_state_model.dart`)
Mencatat status 5 misi harian:
```dart
class DailyQuestStateModel extends HiveObject {
  String username;
  String date;                      // YYYY-MM-DD
  List<String> workoutExercises;    // 2 latihan rotasi hari ini (misal: Push Ups & Squats)
  List<bool> workoutCompleted;      // [false, false] -> [true, true]
  bool studyCompleted;              // Status Study
  bool cardioCompleted;             // Status Cardio
  bool groomingCompleted;           // Status Grooming
  bool fullClearClaimed;            // Apakah bonus Full Clear (+50 EXP, +2 WIL) sudah diklaim
}
```

---

## 4. Integrasi REST API Eksternal (Modul 5)

Aplikasi LevMax mengonsumsi **2 REST API Publik** melalui berkas [api_service.dart](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/lib/service/api_service.dart) menggunakan package `http`:

### A. REST API 1: DummyJSON Quotes API
- **Endpoint**: `https://dummyjson.com/quotes/random`
- **Method**: `GET`
- **Tujuan**: Mengambil kutipan motivasi acak untuk ditampilkan pada kartu elang di layar Home.
- **Contoh Response JSON**:
  ```json
  {
    "id": 42,
    "quote": "The only way to do great work is to love what you do.",
    "author": "Steve Jobs"
  }
  ```
- **Cara Kerja di Kode**:
  1. `http.get(Uri.parse(url))` dipanggil secara asynchronous (`async/await`).
  2. Hasil respons di-decode menggunakan `jsonDecode(response.body)`.
  3. Dikonversi menjadi objek `QuoteModel.fromJson(json)`.
  4. **Offline Fallback**: Jika HP sedang tidak ada sinyal atau request timeout, aplikasi secara anggun (*graceful fallback*) menampilkan quote bawaan sistem: *"The system does not bargain. Rise and conquer your daily limits."* sehingga aplikasi **tidak pernah crash**.

### B. REST API 2: Open-Meteo Weather API
- **Endpoint**: `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true`
- **Method**: `GET`
- **Tujuan**: Menampilkan suhu udara dan kondisi cuaca di lokasi lari pengguna saat ini pada tab MAP / Cardio.
- **Kelebihan API Ini**: Publik, gratis, akurat, dan **tidak memerlukan API Key rahasia** yang rawan expired atau kuota habis saat presentasi di depan dosen!
- **Contoh Response JSON**:
  ```json
  {
    "current_weather": {
      "temperature": 27.4,
      "weathercode": 3,
      "windspeed": 12.1
    }
  }
  ```
- **Interpretasi WMO Weather Code**:
  Kode cuaca dikonversikan menjadi status yang ramah gaya Cyberpunk:
  - `0`: `CLEAR SKY`
  - `1..3`: `PARTLY CLOUDY`
  - `51..67`: `ACID RAIN PROTOCOL` (Hujan)
  - `95..99`: `IONIC THUNDERSTORM` (Badai Petir)
- **Offline Fallback**: Jika GPS atau API gagal dijangkau, sistem menggunakan data default `26°C · CLOUDY`.
