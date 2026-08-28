# TripPick / 旅先ピック

TripPick is a bilingual Flutter travel recommender. Tell it where you are
travelling from, whether you want a domestic or international trip, your
budget, trip length, interests, and optional travel month. It returns three
destination ideas, three highlights for each destination, and Google Maps
search links.

- English and Japanese UI
- Light, dark, and system themes
- Flutter Web client with a separate Dart API server
- Deterministic fake mode for development without credentials
- Live recommendations generated with Gemini
- Freely licensed destination photos and attribution from Wikimedia Commons
- Gemini credentials stay on the server and are never sent to the browser

[日本語の説明はこちら](#日本語)

## Project structure

```text
TripPick/
├── lib/                  Flutter application
│   ├── controllers/      Loading, success, and error state
│   ├── data/             API and fake recommendation repositories
│   ├── domain/           Request and recommendation models
│   ├── l10n/             English and Japanese translations
│   └── ui/               Application screens and widgets
├── server/               Dart HTTP API
│   ├── bin/server.dart   Server entry point and environment loading
│   ├── lib/src/          Validation, Gemini, Wikimedia, and fake services
│   └── test/             Server tests
├── assets/               Images and the Noto Sans JP font
└── test/                 Flutter tests
```

## Requirements

- Flutter SDK with Dart 3.11.5 or newer
- Chrome for the web client
- A Gemini API key only when using live mode

Check your installation:

```sh
flutter doctor
dart --version
```

## Run the full app with the fake server

This is the recommended first run. It exercises the browser-to-server request
flow but uses deterministic data and does not need an API key.

### 1. Install the server dependencies

Open a terminal in the repository root:

```sh
cd server
dart pub get
```

### 2. Create the server configuration

On macOS or Linux:

```sh
cp .env.example .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Make sure `server/.env` contains:

```dotenv
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.5-flash-lite
PORT=8080
ALLOWED_ORIGIN=http://127.0.0.1:3000
USE_FAKE_APIS=true
```

### 3. Start the server

Run this from the `server` directory:

```sh
dart run bin/server.dart
```

You should see:

```text
TripPick server listening on http://127.0.0.1:8080 (fake mode)
```

Keep this terminal open. To verify the server, visit
<http://127.0.0.1:8080/health> or run:

```sh
curl http://127.0.0.1:8080/health
```

The response should be `{"status":"ok"}`.

### 4. Start the Flutter client

Open a second terminal in the repository root (not the `server` directory):

```sh
flutter pub get
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8080
```

PowerShell also accepts the command on one line:

```powershell
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8080
```

The hostname and port must match `ALLOWED_ORIGIN` exactly. The application will
open at <http://127.0.0.1:3000>.

## Run with live Gemini recommendations

Complete the dependency installation above, then edit `server/.env`:

```dotenv
GEMINI_API_KEY=your_api_key_here
GEMINI_MODEL=gemini-3.5-flash-lite
PORT=8080
ALLOWED_ORIGIN=http://127.0.0.1:3000
USE_FAKE_APIS=false
```

Restart the server, then launch the Flutter client using the same command from
step 4. Never put `GEMINI_API_KEY` in Flutter code or pass it with
`--dart-define`; `.env` is ignored by Git.

Live mode requires outbound access to the Gemini API, Wikipedia, Wikidata, and
Wikimedia Commons. Google Maps search links do not require a Maps API key.

## Flutter-only preview

To work on the UI without running any server, use the client's in-memory fake
repository:

```sh
flutter pub get
flutter run -d chrome --web-port=3000 \
  --dart-define=USE_FAKE_REPOSITORY=true
```

In this mode there are no HTTP requests. It is useful for UI development, but
it does not test API integration, request validation, or CORS.

## How it works

1. The user chooses an origin country, travel scope, budget level, trip length,
   one to five interests, an optional month, and a UI language.
2. The Flutter client converts those choices to JSON and sends a `POST` request
   to `/v1/recommendations` on the Dart server.
3. The server checks the browser origin, limits the request body to 32 KB, and
   validates every field. Invalid requests receive a structured JSON error.
4. In fake mode, the server returns three deterministic destinations. In live
   mode, it asks Gemini for six structured candidates and filters them for the
   selected domestic or international scope, uniqueness, and valid fields.
5. For the first three valid live candidates, the server looks up a matching
   city image through Wikipedia, Wikidata, and Wikimedia Commons. It only uses
   images with usable source and licence information. Results are cached in
   memory; a gradient placeholder is used when no suitable photo is found.
6. The server creates ordinary Google Maps search URLs for each city and
   highlight, then returns exactly three display-ready recommendations.
7. The Flutter controller updates the UI to loading, success, or error state.
   Language and theme preferences are saved locally with SharedPreferences.

```text
Flutter form
    │  POST /v1/recommendations
    ▼
Dart API ── validation + CORS
    │
    ├── fake mode ────────────────┐
    │                             │
    └── live mode ── Gemini       │
                     + Wikimedia  │
                            │     │
                            ▼     ▼
                  3 recommendations
                            │
                            ▼
                       Flutter UI
```

### API endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Server health check |
| `POST` | `/v1/recommendations` | Validate preferences and return three recommendations |
| `OPTIONS` | Any path | CORS preflight response |

Example request:

```json
{
  "originCountry": "JP",
  "scope": "international",
  "budgetLevel": "medium",
  "tripDays": 5,
  "interests": ["food", "culture"],
  "travelMonth": 10,
  "locale": "en"
}
```

## Tests and verification

From the repository root:

```sh
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd server
dart format --output=none --set-exit-if-changed bin lib test
dart analyze
dart test
```

## Troubleshooting

- **403 `ORIGIN_NOT_ALLOWED`:** ensure the browser URL exactly matches
  `ALLOWED_ORIGIN`, including `localhost` versus `127.0.0.1` and the port.
- **The client cannot connect:** confirm the server terminal is still running,
  `/health` responds, and `BACKEND_BASE_URL` points to port 8080.
- **The server asks for `GEMINI_API_KEY`:** set `USE_FAKE_APIS=true`, or add a
  valid key for live mode and restart the server.
- **Live requests fail:** check internet access, the Gemini model name, API key,
  quota, and the JSON request log printed by the server.
- **Port already in use:** change `PORT` and use the same port in
  `BACKEND_BASE_URL`. If the Flutter port changes, update `ALLOWED_ORIGIN` too.

## MVP limitations

Budget is a soft preference, not a price quote. TripPick does not calculate
flights, hotels, food, or total costs, and it does not verify current opening
hours or availability. The MVP has no accounts, bookings, saved trips,
analytics, generated itineraries, restaurant menus, or embedded maps. The
local server must be deployed and hardened before the web client is published.

---

## 日本語

TripPick（旅先ピック）は、旅行条件から3つの旅行先を提案する、日本語・英語対応の
Flutter Webアプリです。出発国、国内旅行または海外旅行、予算、日数、興味、任意の
旅行月を入力すると、各都市のおすすめ理由、3つの見どころ、Google Mapsへのリンクを
表示します。

### 主な機能

- 日本語・英語の切り替え
- ライト、ダーク、システムテーマ
- Flutter WebクライアントとDart APIサーバーを分離した構成
- APIキー不要の再現可能なフェイクモード
- Geminiによるライブ旅行先提案
- Wikimedia Commonsから取得したライセンス表記付きの都市画像
- Gemini APIキーをブラウザへ送らない安全なサーバー側構成

## 必要な環境

- Dart 3.11.5以降を含むFlutter SDK
- Web版を実行するためのGoogle Chrome
- ライブモードを使用する場合のみGemini APIキー

インストール状況を確認します。

```sh
flutter doctor
dart --version
```

## フェイクサーバーで起動する手順

初回はこの方法がおすすめです。APIキーなしで、ブラウザからサーバーまでの通信を
含むアプリ全体の動作を確認できます。

### 1. サーバーの依存関係をインストールする

リポジトリのルートから次を実行します。

```sh
cd server
dart pub get
```

### 2. 設定ファイルを作成する

macOS / Linuxの場合：

```sh
cp .env.example .env
```

Windows PowerShellの場合：

```powershell
Copy-Item .env.example .env
```

`server/.env`が次の内容になっていることを確認します。

```dotenv
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.5-flash-lite
PORT=8080
ALLOWED_ORIGIN=http://127.0.0.1:3000
USE_FAKE_APIS=true
```

### 3. サーバーを起動する

`server`フォルダー内で実行します。

```sh
dart run bin/server.dart
```

次のメッセージが表示されれば起動成功です。

```text
TripPick server listening on http://127.0.0.1:8080 (fake mode)
```

このターミナルは開いたままにしてください。別のターミナルで次を実行すると、
サーバーの状態を確認できます。

```sh
curl http://127.0.0.1:8080/health
```

`{"status":"ok"}`が返れば正常です。

### 4. Flutterクライアントを起動する

2つ目のターミナルを開き、リポジトリのルート（`server`の1つ上）で実行します。

```sh
flutter pub get
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 \
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8080
```

Windows PowerShellでは、次のように1行で実行できます。

```powershell
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8080
```

ブラウザで<http://127.0.0.1:3000>が開きます。ホスト名とポートは
`ALLOWED_ORIGIN`と完全に一致させてください。

## Geminiライブモードで起動する手順

上記の依存関係をインストールした後、`server/.env`を編集します。

```dotenv
GEMINI_API_KEY=ここにAPIキーを入力
GEMINI_MODEL=gemini-3.5-flash-lite
PORT=8080
ALLOWED_ORIGIN=http://127.0.0.1:3000
USE_FAKE_APIS=false
```

サーバーを再起動し、手順4と同じコマンドでFlutterクライアントを起動します。
`GEMINI_API_KEY`をFlutterのコードや`--dart-define`に入れないでください。
`.env`はGitの管理対象外です。

ライブモードでは、Gemini API、Wikipedia、Wikidata、Wikimedia Commonsへの
インターネット接続が必要です。Google Mapsの検索リンクにはMaps APIキーは不要です。

## サーバーなしでUIだけを起動する

Flutter内蔵のフェイクリポジトリを使うと、サーバーなしでUIを確認できます。

```sh
flutter pub get
flutter run -d chrome --web-port=3000 \
  --dart-define=USE_FAKE_REPOSITORY=true
```

このモードではHTTP通信を行わないため、UI開発には便利ですが、API連携、入力検証、
CORSのテストにはなりません。

## 仕組み

1. ユーザーが出発国、国内・海外、予算、旅行日数、1〜5個の興味、任意の旅行月、
   表示言語を選択します。
2. Flutterクライアントが入力をJSONに変換し、Dartサーバーの
   `/v1/recommendations`へ`POST`します。
3. サーバーはブラウザのOrigin、32 KBの本文サイズ上限、各入力項目を検証します。
   不正な入力には構造化されたJSONエラーを返します。
4. フェイクモードでは固定の3都市を返します。ライブモードではGeminiに構造化された
   6件の候補を生成させ、国内・海外の条件、重複、必須項目を検証します。
5. 最初の有効な3都市について、Wikipedia、Wikidata、Wikimedia Commonsを使って
   都市画像と出典・ライセンスを取得します。適切な画像がない場合はグラデーションの
   プレースホルダーを表示します。画像結果はサーバーのメモリにキャッシュされます。
6. サーバーが都市と見どころのGoogle Maps検索URLを作り、表示用の3件の提案を
   Flutterへ返します。
7. Flutterのコントローラーが読み込み中、成功、エラーの状態をUIへ反映します。
   言語とテーマの選択はSharedPreferencesで端末内に保存されます。

## テスト

リポジトリのルートから実行します。

```sh
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd server
dart format --output=none --set-exit-if-changed bin lib test
dart analyze
dart test
```

## トラブルシューティング

- **403 `ORIGIN_NOT_ALLOWED`：** ブラウザのURLと`ALLOWED_ORIGIN`のホスト名・
  ポートが完全に一致しているか確認してください。
- **クライアントが接続できない：** サーバーが起動中か、`/health`が応答するか、
  `BACKEND_BASE_URL`が8080番ポートを指しているか確認してください。
- **`GEMINI_API_KEY`を要求される：** `USE_FAKE_APIS=true`にするか、有効なキーを
  設定してサーバーを再起動してください。
- **ライブ通信に失敗する：** インターネット接続、モデル名、APIキー、割り当て量、
  サーバーが出力するJSONログを確認してください。
- **ポートが使用中：** `PORT`と`BACKEND_BASE_URL`を同じ別ポートに変更します。
  Flutter側のポートを変えた場合は`ALLOWED_ORIGIN`も変更してください。

## MVPの制限

予算はおおまかな希望条件であり、価格の見積もりではありません。航空券、ホテル、
食事、旅行総額、最新の営業時間・空き状況は計算・確認しません。アカウント、予約、
旅行の保存、分析、旅程生成、レストランメニュー、埋め込み地図も対象外です。
Webで一般公開する前に、ローカルサーバーを本番向けにデプロイし、セキュリティを
強化する必要があります。
