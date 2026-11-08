# Setup & Running Guide

## Backend
- Setup: `cd backend && cp .env.example .env && npm install`
- Dev server: `npm run dev` (API on port 3000)
- Unit tests: `npm test` (offline, pure math, no DB required)
- Live tests: `npm run test:live` (requires running server and Neon DB)
- Migrations & Seed: `npm run db:migrate && npm run db:seed`

## Mobile
- Setup: `cd mobile && flutter pub get`
- Lint: `flutter analyze`
- Tests: `flutter test`
- Run on Chrome: `flutter run -d chrome`
- Run on Phone / Emulator: `flutter run -d <deviceId>`

## Environment Variables (backend/.env)
- `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `NEON_BRANCH`
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ENDPOINT_URL_S3`, `AWS_REGION`
- `PORT`, `NODE_ENV`, `CORS_ORIGIN`, `TEST_USER_PASSWORD`

## CI Pipeline (GitHub Actions)
- Backend CI runs: `npm ci`, `npx tsc --noEmit`, `npm test`, `npm run build`
- Mobile CI runs: `flutter pub get`, `flutter analyze`, `flutter test`
- Live integration tests (`npm run test:live`) run locally only, never in CI.
