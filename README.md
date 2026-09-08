# Medical Prescription Scanner MVP

This is an MVP application for scanning medical prescriptions, extracting text using OCR, and storing the organized data.

The project is split into two parts:
1. `backend/` - Node.js + Express REST API with SQLite database
2. `frontend/` - Flutter Mobile Application

## 1. Backend Setup

The backend uses Node.js, Express, Multer (for image uploads), SQLite, and Tesseract.js (for local OCR text extraction).

### Prerequisites
- Node.js installed

### Installation & Running
1. Open a terminal and navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
   *Note: This will automatically create the SQLite database file (`database.sqlite`) and the `uploads/` folder if they don't exist.*

The server will start on `http://localhost:3000`.

## 2. Frontend Setup

The frontend is a Flutter mobile application. It uses the `cunning_document_scanner` package to access the camera, detect document boundaries, crop, and apply perspective correction.

### Prerequisites
- Flutter SDK installed
- Android Studio / Android Emulator or a physical device

### Configuration
1. Open `frontend/lib/services/api_service.dart`.
2. By default, the API URL is set to `http://127.0.0.1:3000/api`. 
   - If you are running the app on an Android Emulator, change this to `http://10.0.2.2:3000/api`.
   - If you are running the app on a physical device, change this to your computer's local IP address (e.g., `http://192.168.1.5:3000/api`).

### Installation & Running
1. Open a terminal and navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

*Note: For Windows users, building with some Flutter plugins may require Developer Mode to be enabled in your Windows Settings.*

## API Documentation

### 1. Scan Prescription
- **URL**: `/api/prescriptions/scan`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Body**:
  - `image`: The image file to be scanned.
- **Description**: Uploads an image, processes it with OCR, and saves the extracted data to the SQLite database.

### 2. Get All Prescriptions
- **URL**: `/api/prescriptions`
- **Method**: `GET`
- **Description**: Retrieves a list of all scanned prescriptions.

### 3. Get Prescription by ID
- **URL**: `/api/prescriptions/:id`
- **Method**: `GET`
- **Description**: Retrieves detailed information about a specific prescription, including the parsed medicines.

### 4. Delete Prescription
- **URL**: `/api/prescriptions/:id`
- **Method**: `DELETE`
- **Description**: Deletes a prescription and its associated medicines.
