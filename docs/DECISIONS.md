# Architectural Decisions

- **Flutter**: Single cross-platform codebase for iOS and Android with 60fps Material 3 UI.
- **Neon PostgreSQL**: Serverless Postgres with instant branching, pooling, and unpooled migrations.
- **Fixed 7 Categories**: Academic, Career, Entertainment, Fitness, Life & Family, Personal, Social — avoids choice overload.
- **Server Time as Source of Truth**: Server `now()` controls start/pause timestamps; responses include `serverTime` to cancel client clock drift.
- **One Active Timer at a Time**: Enforces focus; starting any timer automatically pauses the running one in an atomic transaction with row locking.
- **Signed Remaining Time (Overtime Allowed)**: Remaining seconds go negative when over-budget, giving honest feedback without blocking.
- **Server-Computed Waking Seconds**: Gross awake time minus routine minutes computed by server; client values untrusted.
- **30-Minute Allocation Blocks**: Daily plans use 1800s steps, keeping planning fast and granular enough.
- **Minimum Planned Rule**: Editing today's plan rejects lowering planned time below time already spent today (rounded up to 30m).
- **Separation of CI Unit vs Live Tests**: CI runs fast offline unit math tests without secrets; live DB tests run locally in `test:live`.
- **Neon Object Storage**: S3-compatible storage with `forcePathStyle: true` for user asset uploads.
- **JWT Auth**: Short-lived access token (15m) + refresh token (7d) with Argon2 hashing and rate-limited auth endpoints.
