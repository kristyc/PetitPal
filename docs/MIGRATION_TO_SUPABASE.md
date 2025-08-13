# Migration to Supabase

## When to Migrate
- Approaching KV scale or requiring relational queries.

## Steps
1. Create Supabase project + tables mirroring `family:{id}` and `invites:{token}`.
2. Implement a `Storage` interface in Worker and add `StorageSupabase` adapter.
3. Dual-write for a week, backfill KV → Supabase, flip reads.
4. Rollback by disabling Supabase adapter and reading from KV.
