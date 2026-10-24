# Sit & Stay

Sit & Stay connects homeowners in South Africa with verified pet and house sitters. Homeowners can search for sitters, save favourites, book a sitter and message them. Sitters complete verification checks and accept or decline jobs. An admin reviews the verification checks.

| Part | Technology | Folder |
| --- | --- | --- |
| Mobile app | Flutter (Dart) | `frontend/` |
| REST API | Spring Boot 4 (Java 17) | `sittermatch/` |
| Database | MySQL | `sittermatch_db` |

The Flutter app calls the Spring Boot API on port `8080`, and the API stores its data in MySQL.

---

## 1. Prerequisites

Install these before you start:

- **Java JDK 17** or newer
- **Apache Maven** 3.9 or newer (or an IDE that runs Maven projects, such as IntelliJ IDEA or VS Code with the Java Extension Pack)
- **MySQL Server 8** and, optionally, MySQL Workbench
- **Flutter SDK** with Dart 3.13 or newer (run `flutter doctor` to check)
- **Android Studio** with an Android emulator, or a physical Android device
- **Git**

---

## 2. Get the code

**Option A: clone from GitHub**

```bash
git clone https://github.com/733Burger/sittermatch.git
cd sittermatch
```

**Option B: from the submitted ZIP file**

Extract the ZIP. It extracts to a folder called `sittermatch-main`. Open a terminal in that folder. All the steps below work the same way from there.

---

## 3. Set up the database

1. Start MySQL.
2. Create the database:

   ```sql
   CREATE DATABASE sittermatch_db;
   ```

3. Open `sittermatch/src/main/resources/application.properties` and check the connection settings:

   ```properties
   spring.datasource.url=jdbc:mysql://localhost:3306/sittermatch_db
   spring.datasource.username=root
   spring.datasource.password=YOUR_MYSQL_PASSWORD
   ```

   Change the username and password to match your MySQL install.

You don't need to create the tables yourself. `spring.jpa.hibernate.ddl-auto=update` creates and updates them when the API starts.

To create the tables manually instead, or just to see the structure, use `database/schema.sql`:

```bash
mysql -u root -p sittermatch_db < database/schema.sql
```

---

## 4. Set the Google Maps API key (for address search)

Address autocomplete and location matching use the Google Places API. The key is read from an environment variable, so it never goes into the code.

**Windows (PowerShell):**

```powershell
$env:GOOGLE_MAPS_API_KEY="your-key-here"
```

**macOS / Linux:**

```bash
export GOOGLE_MAPS_API_KEY="your-key-here"
```

Set this in the same terminal you use to start the API. Without a key the app still runs, but address search returns no results.

---

## 5. Run the back end (Spring Boot)

From the repository root:

```bash
cd sittermatch
mvn spring-boot:run
```

Alternatively, open the `sittermatch` folder in your IDE and run `SittermatchApplication.java`.

The API starts on **http://localhost:8080**. It is running when the terminal shows `Started SittermatchApplication`.

ID photos uploaded for verification are saved outside the project, in `~/sittermatch-private/identity`. The folder is created automatically.

---

## 6. Run the mobile app (Flutter)

Open a new terminal and keep the API running.

```bash
cd frontend
flutter pub get
flutter run
```

If more than one device is connected, `flutter run` asks you to choose one.

### Connecting the app to the API

The API address is set in `frontend/lib/config/api_config.dart`:

| Where the app runs | API address used |
| --- | --- |
| Android emulator | `http://10.0.2.2:8080` (the emulator's address for your computer) |
| Web / desktop | `http://localhost:8080` |

**Physical Android phone:** the phone and computer must be on the same Wi-Fi network. Find your computer's IP address (`ipconfig` on Windows, `ifconfig` on macOS/Linux) and change the Android line in `api_config.dart` to that address, for example `http://192.168.1.20:8080`.

---

## 7. Using the app

1. **Sign up** as a homeowner or a sitter from the role select screen.
2. **Homeowners** can complete their profile and verification checks, add pets, search for sitters, save sitters, make bookings and message sitters.
3. **Sitters** can complete their verification checks (identity, residence, emergency contact), view jobs, accept or decline bookings and leave reviews.
4. **Admin:** there is no admin sign-up screen. To make an admin, sign up a normal user, then set their role in MySQL:

   ```sql
   UPDATE users SET active_role = 'ADMIN' WHERE email = 'admin@example.com';
   ```

   Check the table name in MySQL Workbench if yours differs. Log out and log in again to open the admin dashboard.

---

## 8. API overview

| Area | Base path | Examples |
| --- | --- | --- |
| Authentication | `/api/auth` | `POST /login`, `POST /signup`, `POST /change-password/{userId}` |
| Homeowner profile and checks | `/api/home` | `GET/PUT /profile/{userId}`, `POST /identity-check` |
| Pets | `/api/pets` | `GET`, `POST`, `PUT`, `DELETE` on `/homeowner/{homeownerId}` |
| Bookings | `/api/bookings` | `POST /create`, `GET /homeowner/{id}`, `PATCH /{id}/status` |
| Sitters | `/api/sitters` | `GET /{homeownerId}/get-sitters`, `PUT /bookings/{bookingId}/respond` |
| Sitter verification | `/api/sitter-verifications` | `POST /identity-check`, `POST /residence-check` |
| Saved sitters | `/api/saved-sitters` | `POST /toggle-sitters` |
| Messages | `/api/messages` | `GET /conversations`, `POST /send` |
| Places | `/api/places` | `GET /autocomplete` |
| Admin | `/api/admin` | `GET /stats`, `GET /pending-checks`, `POST /resolve-check` |

---

## 9. Troubleshooting

| Problem | Fix |
| --- | --- |
| `Access denied for user 'root'` | The MySQL username or password in `application.properties` is wrong. |
| `Unknown database 'sittermatch_db'` | Run `CREATE DATABASE sittermatch_db;` first. |
| `Port 8080 already in use` | Stop the other program using port 8080, or add `server.port=8081` to `application.properties` and update `api_config.dart`. |
| The app shows connection errors | Make sure the API is running, and check the address in `api_config.dart` for your device. |
| Address search shows nothing | `GOOGLE_MAPS_API_KEY` isn't set in the terminal that started the API. |
| `./mvnw` fails | The Maven wrapper files aren't in the repository. Use `mvn spring-boot:run` or run from your IDE. |

---

## Team

ITMDA3-34, SE Group 2, Eduvos Bedfordview

- Lee Conan Burger
- Joshua James Fermor
- Zeke Maia De Oliveira
- Luke Daniel Berry
