# Database Migrations in investorhub-clock

This document explains the logic and structure of the database migrations system implemented in the `investorhub-clock` project.

## Overview

The migration system is designed to manage changes to the MongoDB database schema and seed data in a controlled and repeatable way. Migrations are written in TypeScript and executed automatically when the application starts.

## Migration Structure

- **Location:** All migration files are located in `src/database/migrations/`.
- **Interface:** Each migration implements an `up` and `down` function for applying and reverting the migration, respectively. Migrations also include metadata such as `name`, `version`, and `description`.
- **Schema Tracking:** The `migrations` collection in MongoDB tracks which migrations have been executed, preventing duplicate runs.

## Key Components

- **MigrationService:**
  - Located at `src/database/migrations/migration.service.ts`.
  - Maintains a list of migration modules to run.
  - Runs all `up` methods in order on startup, and can revert with `down` methods in reverse order.
  - Logs progress and errors.

- **Migration Interface:**
  - Defined in `src/database/migrations/migration.interface.ts`.
  - Each migration exports `up` and `down` async functions.

- **Migration Repository:**
  - Located at `src/database/repositories/migration.repository.ts`.
  - Handles CRUD operations for the `migrations` collection.

- **Schema:**
  - The `Migration` schema is defined in `src/database/schemas/migration.schema.ts`.
  - Stores migration `name` and `executedAt` timestamp.

## How Migrations Are Run

1. On application startup (`src/main.ts`), the `MigrationService` is invoked to run all migrations.
2. Each migration's `up` function is called if it has not already been executed (checked via the `migrations` collection).
3. If a migration fails, the process logs the error and stops.
4. The `down` function can be used to revert migrations in reverse order.

## Example Migration

A migration file (e.g., `002-add-token-decimals.ts`) exports `up` and `down` functions. The `up` function applies changes (e.g., adding a field to all tokens), and the `down` function reverts them.

```ts
export async function up(
  networkConfigRepository: NetworkConfigRepository,
  tokenRepository: TokenRepository,
  migrationRepository: MigrationRepository,
): Promise<void> {
  // Migration logic here
}

export async function down(
  networkConfigRepository: NetworkConfigRepository,
  tokenRepository: TokenRepository,
  migrationRepository: MigrationRepository,
): Promise<void> {
  // Revert logic here
}
```

## Adding a New Migration

1. Create a new file in `src/database/migrations/` (e.g., `003-new-feature.ts`).
2. Export `up` and `down` functions following the interface.
3. Add the new migration to the `migrations` array in `migration.service.ts`.
4. The migration will run automatically on the next application start.

## Notes
- Migrations should be idempotent and safe to run multiple times.
- Always test migrations in a development environment before deploying to production.

---

For more details, see the code in `src/database/migrations/` and related repository and schema files. 