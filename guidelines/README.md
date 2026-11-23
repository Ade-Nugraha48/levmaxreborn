# PANDUAN LENGKAP SISTEM LEVMAX (REBORN)
> **Catatan:** Dokumen ini disusun khusus dengan bahasa yang santai, terstruktur, dan mudah dipahami untuk mahasiswa Sistem Informasi (SI) sebagai bekal persiapan ujian dan presentasi tugas akhir Praktikum Pemrograman Aplikasi Mobile.

---

## 📌 Daftar Isi Panduan

Dokumen panduan ini dipecah menjadi 4 bagian utama agar kamu bisa membaca dan mempelajarinya sesuai kebutuhan:

| File | Topik Utama | Keterangan Singkat |
| :--- | :--- | :--- |
| [01_PENJELASAN_FITUR_DAN_CARA_KERJA.md](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/guidelines/01_PENJELASAN_FITUR_DAN_CARA_KERJA.md) | **Fitur & Cara Kerja** | Penjelasan semua fitur dari Auth, Home, 4 Daily Quests, Stats, Achievements, hingga Developer Demo Mode. |
| [02_DATABASE_MODEL_DAN_API.md](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/guidelines/02_DATABASE_MODEL_DAN_API.md) | **Data, Hive & REST API** | Skema 4 box Hive, SharedPreferences, struktur 6 model data, serta cara kerja integrasi REST API (Quotes & Weather). |
| [03_PEMETAAN_MODUL_PRAKTIKUM.md](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/guidelines/03_PEMETAAN_MODUL_PRAKTIKUM.md) | **Kepatuhan Modul 2 – 8** | Pemetaan materi praktikum ke baris kode nyata di project (bukti bahwa semua modul terpenuhi 100%). |
| [04_PANDUAN_PRESENTASI_DAN_TANYA_JAWAB.md](file:///c:/Semester%205/Praktikum%20Mobile/FInal%20Project/levmaxreborn/guidelines/04_PANDUAN_PRESENTASI_DAN_TANYA_JAWAB.md) | **Simulasi Sidang & Tanya Jawab** | Skrip demo aplikasi langkah demi langkah, analogi santai, serta 15+ bocoran pertanyaan dosen penguji beserta contekan jawabannya. |

---

## 🎯 Ringkasan Singkat: "Apa itu LevMax?"

Jika dosen bertanya: *"Coba jelaskan dalam 1 menit, aplikasi apa yang kamu buat?"*

> **Jawaban:**  
> "LevMax adalah aplikasi **Gamifikasi Self-Improvement** berbasis Flutter. Konsepnya terinspirasi dari sistem quest ala webtoon/anime (seperti *Solo Leveling*), di mana pengguna menjalankan 4 aktivitas produktif di dunia nyata:
> 1. **Workout** (Push-up, Pull-up, Squat, Sit-up)
> 2. **Study Lock-In** (Fokus belajar dengan pemantauan timer dan anti-distraksi)
> 3. **Cardio** (Lari/jogging dengan pelacakan GPS, rute peta, dan cuaca *real-time*)
> 4. **Daily Grooming** (Checklist perawatan diri dan hidrasi)
> 
> Setiap aktivitas selesai, pengguna akan mendapatkan **EXP**, meningkatkan **6 atribut stats** (`STR, END, SPD, INT, WIL, APP`), menaikkan **Rank**, dan membuka **Achievements**. Aplikasi ini dibangun menggunakan arsitektur **MVC GetX**, penyimpanan lokal **Hive** (NoSQL), dan **REST API** publik."

---

## 🧭 Struktur Folder Kode Sumber (`lib/`)

```text
lib/
├── main.dart                  # Titik awal jalannya aplikasi (inisialisasi Hive, Session, Notif)
├── controller/                # Logika bisnis & state management reaktif (GetX)
│   ├── auth_controller.dart       # Registrasi & Login
│   ├── cardio_controller.dart     # Pelacakan GPS, pace, dan simulasi cardio
│   ├── grooming_controller.dart   # Operasi CRUD checklist grooming di Hive
│   ├── navigation_controller.dart # Pindah-pindah tab di BottomNavigationBar
│   ├── quest_controller.dart      # Eksekusi quest, daily reset, dan hitung mundur
│   ├── quote_controller.dart      # Mengambil quote motivasi dari REST API
│   ├── stats_controller.dart      # Mengagregasi data statistik & grafik sejarah
│   └── user_controller.dart       # Data profil user, EXP, Level Up, dan Demo Controls
├── core/                      # Konstanta, tema warna, font, dan helper logika
│   ├── constants/                 # Warna, gaya font, dan konfigurasi game
│   ├── theme/                     # Dark theme aplikasi
│   └── utils/                     # Rumus kalkulator stats, kurva EXP, tanggal
├── model/                     # Cetak biru data (Hive TypeAdapters & model API)
├── routes/                    # Routing halaman GetX dan dependency injection (Bindings)
├── service/                   # Komunikasi keluar (Hive DB, SharedPrefs, HTTP, GPS, Notif)
└── view/                      # Tampilan antarmuka (UI Pages & Widgets)
    ├── pages/                     # 13 layar tampilan aplikasi
    └── widgets/                   # Komponen visual modular (HUD, Radar Chart, dsb.)
```

Selamat mempelajari panduan ini. Baca secara berurutan mulai dari `01` sampai `04` untuk pemahaman maksimal sebelum presentasi!
