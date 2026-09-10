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
The default API URL is `http://10.0.2.2:3000/api` for the Android emulator.
For a physical Android phone, connect the phone and computer to the same Wi-Fi,
run `ipconfig` on the computer to find its Wi-Fi IPv4 address, and launch from
`frontend/` with that address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api
```

Replace `192.168.1.5` with your computer's address. Keep the backend running in
a separate terminal. Changing this setting requires stopping and rerunning the
app; hot reload does not update it. If the phone still cannot connect, check
that Windows Firewall allows the Node.js server on your private network.

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

### Login sessions

The backend validates phone number and password before issuing a JWT. Set
`JWT_SECRET` in `backend/.env`; tokens expire after 20 days. Each authenticated
request returns a renewed token in `X-Session-Token`, extending the window by
20 days from that successful activity. Flutter stores the token under
`jwt_token` in SharedPreferences and sends it as a Bearer token on API requests.
Passwords are not saved in SharedPreferences.

On app startup/resume, `/api/auth/session` validates and renews the saved session.
The app also renews while in the foreground every 15 minutes. Expired sessions
and logout clear the saved token and return to Login. Connection errors preserve
the token and allow retrying; renewing a session requires a backend connection.

Session checks: `node test/auth.integration.js` from `backend/` and
`flutter test test/session_test.dart` from `frontend/`.

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
