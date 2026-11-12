# PetVida 🐾 — Cuidados de cães com ligação Dono ↔ Veterinário

```
PetVida/
├── app/                  # Flutter (MVVM + Provider)
├── backend/              # API Node.js + Express + JWT
├── database/schema.sql   # Modelo de dados (NeonDB / PostgreSQL)
└── README.md
```

## Funcionalidades (V1)
Autenticação (e-mail+senha, JWT, recuperação por código enviado por e-mail) · dois perfis exclusivos (Dono / Veterinário) · múltiplos cães · vacinas, peso (com gráfico), dieta, rotina, sintomas (foto opcional) com **editar e excluir** · timeline filtrável · convites por e-mail · recomendações/sugestões/prescrições com **doses geradas automaticamente** e taxa de adesão · galeria (Cloudinary) · lembretes dentro do app + notificações **locais**.
Fora de escopo: push/Firebase, chat, pagamentos, IA.

## Regra crítica: desligar veterinário
`POST /api/connections/:id/disconnect` só altera `pet_vets.status` para `disconnected`. As tabelas `vet_notes`, `prescriptions` e `prescription_doses` não têm ligação a `pet_vets`, portanto nada é apagado. O histórico/timeline mostra "veterinário desligado" (`vet_active = false`). O veterinário desligado perde acesso ao pet (404).

## 1. NeonDB
1. Crie conta em https://neon.tech → novo projeto → copie a *connection string* (`postgresql://...?sslmode=require`).
2. No **SQL Editor** do Neon cole e execute `database/schema.sql` (ou `psql "$DATABASE_URL" -f database/schema.sql`).

## 2. Cloudinary
1. Conta em https://cloudinary.com → *Dashboard* → copie **Cloud name**, **API Key**, **API Secret**.
2. Não é preciso criar *upload preset*: o upload é feito pelo backend (assinado). Só imagens são aceites (até 8 MB).

## 3. Backend
```bash
cd backend
cp .env.example .env      # preencha DATABASE_URL, JWT_SECRET, CLOUDINARY_*, SMTP_*
npm install
npm run dev               # http://localhost:3000  (teste: GET /health)
```
- **E-mail (recuperação de senha):** configure `SMTP_*` (Gmail com *App Password*, Brevo, Mailtrap…). Sem `SMTP_HOST`, o código de 6 dígitos é **impresso na consola do backend** (útil em desenvolvimento).
- `CORS_ORIGIN`: para Web em produção, liste as origens permitidas.

### Principais endpoints (todos `/api`, `Authorization: Bearer <jwt>`)
| Área | Rotas |
|---|---|
| Auth | `POST /auth/register · /auth/login · /auth/forgot-password · /auth/reset-password`, `GET /auth/me` |
| Pets | `GET/POST /pets`, `GET/PUT/DELETE /pets/:id` |
| Saúde | `GET/POST /pets/:id/{vaccines,weights,diets,routines,symptoms}`, `PUT/DELETE …/:recordId` |
| Timeline | `GET /pets/:id/timeline?kinds=vaccine,weight,prescription…` |
| Imagens | `POST /uploads` (devolve URL), `GET/POST/DELETE /pets/:id/images` |
| Ligações | `GET/POST /pets/:id/vets` (dono), `GET /invites`, `POST /invites/:id/accept\|decline` (vet), `POST /connections/:id/disconnect` |
| Prescrições | `GET/POST /pets/:id/notes`, `PUT/DELETE /notes/:id`, `GET /prescriptions/:id/doses`, `PATCH /doses/:id` |
| Lembretes | `GET /reminders` |

**Permissões:** o dono só acede aos seus pets; o veterinário só a pets com ligação `accepted` (e apenas leitura nos registos de saúde); respostas 404 para recursos de outros utilizadores.

## 4. Flutter
Requisitos: Flutter 3.22+ (Dart 3.3+).
```bash
cd app
./setup.sh                # Windows: setup.bat  → gera android/ ios/ web/ e corre pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000/api     # emulador Android
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api   # Web
```
`API_URL` para iOS Simulator: `http://localhost:3000/api`. Em telemóvel físico use o IP da sua máquina (`http://192.168.x.x:3000/api`) — e HTTPS em produção.

### Configurar Android/iOS (depois do setup.sh)
**Android** — `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
e dentro de `<application>`:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter>
</receiver>
```
`android/app/build.gradle(.kts)`: `compileOptions { isCoreLibraryDesugaringEnabled = true }` e `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`; `minSdk` ≥ 21. Para HTTP (dev) em dispositivo físico adicione `android:usesCleartextTraffic="true"` ao `<application>`.

**iOS** — `ios/Runner/Info.plist`: `NSPhotoLibraryUsageDescription` e `NSCameraUsageDescription`. Em `ios/Runner/AppDelegate.swift`, dentro de `didFinishLaunchingWithOptions`:
```swift
if #available(iOS 10.0, *) { UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate }
```

## Arquitetura MVVM (app/lib)
- `models/` — dados puros (`fromJson`).
- `repositories/` — acesso à API (sem estado de UI).
- `viewmodels/` — `ChangeNotifier` (estado, loading/erro, ações) — sem widgets.
- `views/` — widgets; só leem o ViewModel (`Provider`) e chamam métodos.
- `core/` — tema, cliente HTTP, notificações locais, descrição dos registos de saúde (`health_kinds.dart`: um formulário/lista genérico para vacinas, peso, dieta, rotina e sintomas).

## Lembretes e notificações
`GET /reminders` devolve vacinas (próxima dose, 09:00), doses pendentes (14 dias) e rotinas. O app expande-os em ocorrências concretas (7 dias) e agenda notificações locais (até 60) sempre que abre o separador Lembretes. Na Web só há lembretes dentro do app.

## Fluxo de teste rápido
1. Registe um **Dono** e um **Veterinário** (e-mails diferentes). 2. Dono: cadastre um cão → aba *Vets ligados* → convide o e-mail do vet. 3. Vet: *Convites* → aceitar → abrir paciente → *Veterinário* → nova prescrição (ex.: a cada 8h, 7 dias). 4. Dono: abrir a prescrição e marcar doses; vet vê a adesão. 5. Dono: desligar o vet → a prescrição continua visível, marcada como "veterinário desligado".

## Notas
- Prescrições: só título/texto são editáveis; para alterar medicamento/duração, exclua e crie outra.
- Um utilizador tem um único papel (`users.role`).
- Segurança: senhas com bcrypt, JWT 7 dias, resposta neutra em "esqueci a senha", código de recuperação com expiração (15 min) e 5 tentativas.
