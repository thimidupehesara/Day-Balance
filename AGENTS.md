# Day-Balance

Daily time-budgeting app: Flutter in `mobile/`; Node.js, Express, TypeScript and Drizzle in `backend/`; Neon PostgreSQL.

## Run
- Backend: in `backend/`, run `npm install`, then `npm run dev` (port 3000); requires a configured local `.env`.
- Mobile: in `mobile/`, run `flutter pub get`.
- Chrome: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`.
- Android phone: enable USB debugging, connect and authorize the phone; use `adb devices` and `flutter devices` to find its ID.
- Run `adb -s <deviceId> reverse tcp:3000 tcp:3000`, then in `mobile/` run `flutter run -d <deviceId> --dart-define=API_BASE_URL=http://localhost:3000`.

## Figma
- Before building or changing a screen, find its row in `design/FIGMA_LINKS.md` and review its PNG in `design/exports/png/`.
- Build cleanly with theme tokens in `mobile/lib/core/theme` and shared widgets in `mobile/lib/shared/widgets`; make layouts responsive.
- Never paste exported code, import from `/design`, or edit `/design`. Do not use the Figma MCP.
- If no design exists, build from the user's written spec and flag it in the report.

## Safety
- Never run `DROP`, `TRUNCATE`, or `DELETE` without `WHERE`.
- Never commit `.env` files or print secrets.
- Test users must use `@example.com` and be cleaned up with scoped deletion.
- Inspect test scripts before execution; do not run database-dependent commands when database access is prohibited.

## Git
- Use one `feature/<name>` branch per task; make small commits with useful messages. Never commit directly to `main`.
- Stage only task changes; preserve unrelated work. Never push to `main` or run `git push`; the user pushes and merges.
- Report the branch name for the user to push.

## Quiet verification
- Run each applicable check once per task: in `mobile/`, `flutter analyze` and `flutter test`; in `backend/`, `npx tsc --noEmit`, `npm test`, and `npm run build`.
- Safety takes precedence: skip prohibited checks and report why. Documentation-only tasks need only content/diff checks.
- Do not print long banners. Keep the final report under 20 lines. Do not use the schedule tool.

## Docs
- Update only `docs/PROGRESS.md`: status table, Next Step, and Known Issues, with at most 3 lines of changes per task.
- Never create a document per screen, widget, or feature; do not duplicate information or paste test output into docs.
