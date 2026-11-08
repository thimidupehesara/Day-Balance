---
name: new-screen
description: >-
  Standard workflow for building or modifying any screen in Day-Balance from Figma designs
  and CodeTea Flutter exports.
---

# New Screen Workflow

When asked to build or rebuild a screen in Day-Balance, execute these steps in order:

## Step 0: Branching
- Check out a dedicated feature branch for the screen:
  ```bash
  git checkout -b feature/<screen-name>
  ```

## Step 1: Design Inspection
- Find the screen's row in `design/FIGMA_LINKS.md`.
- Look at the PNG and read the `.dart` export in `design/exports/`.
- Do not call the Figma MCP unless explicitly asked.
- If a screen has no design, build from the written spec and flag it in the report.

## Step 2: Implementation
- Build cleanly using theme tokens (`mobile/lib/core/theme`) and shared widgets (`mobile/lib/shared/widgets`).
- Make the layout responsive (`Column`, `Row`, `Expanded`, `Padding`, `SafeArea`, `SingleChildScrollView`).
- Never paste exported CodeTea code unchanged, never import from `/design`, never edit `/design`.

## Step 3: Verification
- Run verification checks once:
  - `flutter analyze`
  - `flutter test`
  - `npx tsc --noEmit`
- Run the screen/test and compare with PNG, noting any visual differences.

## Step 4: Progress Update
- Update only `docs/PROGRESS.md`: mark status as `Done`, update "Next step", and add any new gotchas to "Known issues" (3 lines max).
- Never create a separate document for a screen, widget or feature.

## Step 5: Git Commit
- Stage all files and commit:
  ```bash
  git add .
  git commit -m "feat(<scope>): rebuild <screen> from Figma design"
  ```
- **NEVER push to remote (`git push`) yourself.** Report the branch name for manual push.
