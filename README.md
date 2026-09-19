# 🎓 CodePath

> Platform e-learning berbasis kurasi video YouTube untuk belajar programming secara terstruktur, dilengkapi dengan *tracking progress*, gamifikasi, dan AI Assistant.

🔗 **Live Demo:** [https://codepath-app.my.id](https://codepath-app.my.id)

---

## 📖 Tentang Aplikasi
CodePath adalah solusi belajar *programming* yang mengkurasi video-video tutorial terbaik dari YouTube ke dalam sebuah **Jalur Belajar (Roadmap)** yang sistematis. Pengguna tidak perlu lagi bingung harus mulai belajar dari mana. Cukup pilih bidang yang diminati (misal: Frontend, Backend, Data Science), ikuti *roadmap*-nya, tandai progress belajar, dan tanyakan materi yang kurang dipahami langsung kepada AI Assistant yang terintegrasi di dalam pemutar video.

## ✨ Fitur Utama

### 🔐 Autentikasi & Profil
- Login/Register via Google Sign-In & kredensial standar.
- Manajemen profil pengguna (Upload foto avatar, ganti nama & password).
- Sistem *Role-based access* (User reguler vs Admin).

### 📚 Pengalaman Belajar
- **Roadmap Terstruktur:** Kumpulan video yang diurutkan berdasarkan kurikulum spesifik.
- **YouTube Embed:** Tonton video langsung di dalam aplikasi.
- **Chapter Navigation:** Lompat ke menit tertentu secara presisi berdasarkan *timestamp*.
- **Search:** Pencarian *real-time* untuk video dan *roadmap* di sisi *client*.

### 🤖 AI Learning Assistant
- Tombol *chat* AI mengambang (seperti antarmuka AI YouTube).
- AI Assistant secara otomatis mengetahui konteks video dan *chapter* yang sedang ditonton pengguna.
- Sugesti pertanyaan pintar.
- Ditenagai oleh OpenRouter API (Model: GLM-5.2).

### 📈 Gamifikasi & Progress
- Pelacakan progres belajar dalam bentuk persentase per *roadmap*.
- Sistem *Streak* harian untuk menjaga konsistensi.
- Statistik mingguan dengan grafik aktivitas.

### ⚙️ Admin Panel
- **CRUD Manajemen:** Kelola *Roadmap*, Video, *Chapter*, Tugas, dan Bidang Ilmu.
- **Bulk Import Chapter:** Tambahkan *timestamp* secara massal langsung dari deskripsi YouTube.
- Moderasi forum dan interaksi pengguna.

## 🛠️ Tech Stack

*   **Frontend:** Flutter (Web + Android)
*   **Backend & Database:** Supabase (PostgreSQL, Auth, Storage)
*   **AI Integration:** OpenRouter API (via Supabase Edge Functions)
*   **Deployment:** Vercel (Web Version)
*   **UI/UX:** Custom Animated UI (Tema: Teal `#0D3B36` & Gold `#C9A227`)
