# 📱 Ứng dụng iOS Nghe Nhạc & Xem Video (Tải MP3 & MP4 từ YouTube)

Dự án gồm 2 phần chính:
1. **Backend Microservice (`backend/`):** Python FastAPI + `yt-dlp` bóc tách link âm thanh MP3 và MP4 video trực tiếp từ YouTube.
2. **iOS App (`ios-app/`):** Ứng dụng iOS viết bằng SwiftUI + AVFoundation (xem video MP4offline với PiP, nghe nhạc ngầm MP3, Lockscreen Controls).

---

## 🚀 1. Hướng dẫn Chạy Backend (Python + `yt-dlp`)

### Bước 1: Cài đặt thư viện
Mở Terminal / PowerShell tại thư mục `backend/` và chạy:
```bash
pip install -r requirements.txt
```

### Bước 2: Khởi chạy Server Backend
```bash
python main.py
```
Server sẽ chạy tại địa chỉ: `http://localhost:8000`. Bạn có thể mở trình duyệt xem tài liệu API Swagger tại: `http://localhost:8000/docs`.

---

## 📲 2. Hướng dẫn Khởi chạy trên Xcode (iOS App)

### Bước 1: Mở dự án trên Xcode
- Tạo một dự án SwiftUI mới trên Xcode đặt tên **`YTMusicPlayer`**.
- Kéo toàn bộ thư mục `ios-app/YTMusicPlayer/` vào Xcode.

### Bước 2: Cấu hình Quyền (Info.plist)
Đảm bảo đã cấu hình:
- **`UIBackgroundModes`**: `audio` (Cho phép phát nhạc khi khóa màn hình).
- **`NSAppTransportSecurity`**: `NSAllowsArbitraryLoads = true` (Cho phép kết nối tới HTTP Local Backend).

### Bước 3: Đổi IP Backend khi test trên iPhone thật
- Nếu chạy trên **iOS Simulator**: App sẽ mặc định kết nối `http://localhost:8000`.
- Nếu test trên **iPhone thật**: Nhấp vào biểu tượng **Bánh răng (Cài đặt)** ở góc phải màn hình app, đổi IP thành IP máy tính của bạn (VD: `http://192.168.1.50:8000`).

---

## ✨ Các tính năng nổi bật
- 🎵 **Tải MP3:** Bóc tách âm thanh chất lượng cao, phát nhạc nền khi tắt màn hình.
- 🎬 **Tải MP4:** Chọn độ phân giải (720p, 1080p), hỗ trợ **Picture-in-Picture (PiP)** thu nhỏ video thành cửa sổ nổi trên màn hình iPhone.
- 📁 **Thư viện Offline:** Quản lý bài hát/video, tìm kiếm, xóa file dễ dàng.
