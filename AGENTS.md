# Day-Balance

Daily time-budgeting app (Flutter + Node.js + Neon PostgreSQL).

## Commands
- Backend: `cd backend && npm run dev` (:3000) | `npm test` (unit) | `npm run test:live` (live)
- Mobile: `cd mobile && flutter analyze && flutter test && flutter run`

## Figma Rule
Before building or changing a screen: find its row in `design/FIGMA_LINKS.md`, look at the PNG, read the `.dart` export, then build cleanly with our theme tokens and shared widgets, responsive. Never paste exported code, never import from `/design`, never edit `/design`. Do not call the Figma MCP unless I ask. If a screen has no design, build from my written spec and flag it.

## Docs Protocol
At the end of a task, update only `docs/PROGRESS.md`: the status table, 'Next step', 'Known issues' (3 lines of changes at most). Never create a document for a screen, widget or feature. Do not repeat the same information in two files. Do not paste test output into docs. Docs work must stay under 10% of a task.

## Rules
- Safety: Never run destructive DB commands (DROP, TRUNCATE, DELETE without WHERE). Test users use `@example.com` and must be deleted.
- Git: One feature branch per task (`feature/<name>`). Never push to `main`. Never run `git push` yourself; report the branch name to push.
- Verification: Run each check once per task (`flutter analyze`, `flutter test`, `npx tsc --noEmit`, `npm test`, `npm run build`). Run `npm run test:live` once at the end of backend tasks. Do not use the schedule tool. Keep reports under 25 lines.
