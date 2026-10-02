# Market Manager Handover

> Handover context for agents working on the `market_manager` Elixir umbrella.
> Local only (git-ignored). Last updated: **2026-10-02**.

## How to Use This File

- Read **Status** and **Active Blockers** first; they change most often.
- Every fact is dated. Re-verify anything older than the latest commit before relying on it.
- Precedence: user instructions > `AGENTS.md` > this file.
- After finishing work, update **Status**, the affected section, and **Change Log**. Replace stale facts instead of appending contradicting ones.
- Section headings are stable; refer to them by name.

## Status (2026-10-02)

| Item | Value |
|---|---|
| Branch | `fixing-auth-v2` at `576ad73 adding handover file`, same commit as `master` and `origin/master` |
| Uncommitted | Phase 1 of the auth rework (`shared`, `store`, doc examples in `auction_house.ex`); umbrella compile broken until Phases 2-3 |
| Version | `2.2.9` in `mix.exs`; latest tag `2.2.9`; README badge `v=2.2.9` |
| Local toolchain | Elixir 1.20.1, Erlang/OTP 28.3.2 (ASDF) |
| CI toolchain | Elixir 1.20.x, OTP 28.5.x on `windows-2022` (`.github/workflows/master.yml`) |
| Compile | `mix compile --warnings-as-errors`: clean |
| Tests | `mix coveralls -u`: **74 passed** |
| Coverage | **76.2%** total |
| Active blocker | PROD login broken: the website sign-in path is permanently blocked; a header-based replacement is verified but not implemented (see **Active Blockers**) |
| Release build | Last known to fail (see **Known Issues**); not re-verified on 2026-10-01 |

## Active Blockers

1. **PROD login broken; the authentication flow must be reworked.**
   - The website sign-in path (`warframe.market/auth/signin`) is permanently blocked for the app (Cloudflare, 2026-10-02).
   - Replacement verified by hand: header-based v1 sign-in, then `Authorization: Bearer <token>` on v2 calls.
   - State: **Phase 1 implemented (uncommitted); the umbrella does not compile until Phases 2-3 land** (defect D1). Phases 2-6 have open decisions.
   - Rule: do not implement any fix without explicit user approval.
   - Details: section **Header-Based Authentication (2026-10-02)**, subsection **Rework Plan**, plus background in **PROD Login Blocked by Cloudflare (2026-10-01)**.

## Project Map

Umbrella project; apps live under `apps/`. Dependency direction:

- `web_interface` → `manager`, `shared`
- `manager` → `auction_house`, `store`, `shared`
- `auction_house` → `rate_limiter`, `shared`
- `store` → `shared`

| App | Responsibility | Key paths (under `apps/<app>/`) |
|---|---|---|
| `web_interface` | Phoenix LiveView UI; desktop window via `desktop` (`:wxWebView`) | `lib/web_interface/application.ex`, `lib/web_interface/live/*_live.ex`, `lib/web_interface/persistence.ex`, `lib/web_interface/persistence/*`, `lib/web_interface/desktop/*` |
| `manager` | Core entry point; login, activate, and deactivate sagas; pricing strategies | `lib/manager.ex`, `lib/saga/{login,activate,deactivate}.ex`, `lib/runtime/*`, `lib/impl/price_analyst.ex`, `lib/impl/strategy/*` |
| `auction_house` | warframe.market HTTP client and use cases | `lib/impl/http_async_client.ex`, `lib/impl/use_case/*.ex`, `lib/runtime/server.ex` |
| `store` | File-system persistence | `lib/store.ex`, `lib/store/file_system.ex` |
| `shared` | Domain structs and utilities | `lib/data/*`, `lib/utils/*` |
| `rate_limiter` | Leaky-bucket throttling of outbound requests | `lib/rate_limiter.ex`, `lib/rate_limiter/leaky_bucket.ex` |

- warframe.market URLs are set per environment in `config/{dev,test,prod}.exs` under `:auction_house`. Dev and test point to `localhost:8082`. They are read with `Application.compile_env!`, so changes need a recompile.
- Release: Burrito, Windows x86_64 only. A post-wrap step adds the icon with Resource Hacker under Wine (`add_windows_icon/1` in `mix.exs`).
- Docs: ExDoc output in `docs/`, published to GitHub Pages.

## Commands

Run from the repository root unless noted:

```sh
mix deps.get
mix compile --warnings-as-errors
mix test
mix coveralls -u
mix credo --strict
mix dialyzer
mix release market_manager --overwrite
(cd apps/web_interface && MIX_ENV=prod mix phx.server)
```

Focused suites:

```sh
mix test apps/web_interface/test/web_interface/persistence_test.exs
mix test apps/manager/test/unit/saga/deactivate_test.exs apps/manager/test/unit/saga/login_test.exs
mix test apps/auction_house/test/unit/runtime/server_test.exs
```

- Run the focused test first and the full umbrella suite last, because apps share runtime processes and mocks.
- Validation order: `mix compile --warnings-as-errors` before `mix dialyzer`.
- Run Mix commands unsandboxed (see **Known Issues**).

## Working Agreements

Sources: `AGENTS.md` and recorded user preferences.

- Do not edit code unless the user explicitly asks for implementation. "Let's start with X" is not an implementation request.
- Ask whenever anything is ambiguous. Never infer decisions from existing patterns (names, message shapes, namespaces, signatures, doc updates).
- Do not modify code unrelated to the task; match the style of the code you touch.
- Tests:
  - Write meaningful tests; `assert actual == expected`, with the subject on the left.
  - Prefer DAMP tests: keep each scenario's decisive input, action, and expected result explicit and readable in place.
  - Tests must not produce warnings under `mix compile --warnings-as-errors`.
  - Never change assertions during refactoring and never skip failing tests.
- Typespecs: always `any()`, never `term()`.
- Module sections: PUBLIC API holds only functions that clients call; `child_spec/1` goes with the callbacks.
- When `version` in `mix.exs` changes, update the coverage badge `v=` in `README.md`.
- Keep docs and specs in Markdown; keep `README.md` setup and run info current.
- Prefer `rg` over `grep`.

## Known Issues

- **Release build** (last known, not re-verified): `mix release market_manager --overwrite` fails before the post-wrap steps, because the `web_interface` runtime config contains a regex that must be stored with the `/E` modifier.
- **ASDF in sandboxed shells:** sandboxed terminals hide `~/.asdf` while `~/.asdf/shims` stays on `PATH`, which produces a misleading `mix: command not found`. Run Mix unsandboxed.
- **Toolchain drift:** local OTP 28.3.2 vs CI OTP 28.5.x. Keep this in mind when behaviour differs between local and CI.
- **Dialyzer map specs** are treated as closed. For GenServer state helper specs that receive extra fields, add `optional(any()) => any()`.
- **`Manager.Saga.Activate.process_products/3`:** rollback failures carry `{:error, reason}` inside `{:failed_rollback_activation, ...}`, not the full `Store.Type.deactivate_syndicates_response()` union.
- **Resource Hacker under Wine** works when invoked with `-res <ico>` and `-mask ICONGROUP,1,1033`.

## Test Coverage: Completed

### `WebInterface.ActivateLive`

- Production: `apps/web_interface/lib/web_interface/live/activate_live.ex`
- Tests: `apps/web_interface/test/web_interface/live/activate_live_test.exs`
- Coverage: **89.4%**; **18 tests**; 8 relevant lines missed.
- Covered: mount; execute/change success and failures; normal backend progress; repeated and first-request recoverable errors; unknown-total progress; no free slots; completion/error paths; button state.
- Recovery uses `recalculate_progress/1`: the item counter advances, but displayed progress stays at `0%` until a positive total is known.

### `WebInterface.DeactivateLive`

- Production: `apps/web_interface/lib/web_interface/live/deactivate_live.ex`
- Tests: `apps/web_interface/test/web_interface/live/deactivate_live_test.exs`
- Coverage: **91.3%**; **18 tests**; 8 relevant lines missed.
- Covered: mount/render; execute success/failure; selection and empty-selection changes; deletion and reactivation progress; first-request recoverable errors; completion/error paths; unknown messages; button state.
- Delete-order, get-item-orders, and place-order recovery use the same guarded `recalculate_progress/1` behavior as `ActivateLive`.
- Form contract: `phx-change="change"`, `phx-submit="execute"`; unchecking the final checkbox can omit `syndicates` and reach the second change clause.

### Completed server suites

- `AuctionHouse.Runtime.Server`: **97.5%**, 15 tests. Only the globally registered `start_link/0` wrapper remains; leave it to supervisor/integration coverage.
- `Manager.Saga.Login`: **100.0%**, 9 tests. Complete unless behavior changes.

### `WebInterface.Persistence`

- Production: `apps/web_interface/lib/web_interface/persistence.ex`
- Tests: `apps/web_interface/test/web_interface/persistence_test.exs`
- Coverage: **83.3%**, 1 relevant line missed (2026-10-01).
- Covered: successful `init/4`; table creation options; and persistence of syndicates, strategies, and user values through injected, process-local callbacks.
- The test is asynchronous and does not create ETS tables, start processes, or access the filesystem.
- Intentionally excluded: failure-at-step tests that duplicate `with` short-circuit semantics and assertions over the static `default_table/0` map.

## Test Coverage: Backlog

Coverage numbers below were re-measured on 2026-10-01 and are unchanged from 2026-07-31. Next target: P1.

### P1: `Manager.Saga.Deactivate`

- Production: `apps/manager/lib/saga/deactivate.ex`
- Tests: `apps/manager/test/unit/saga/deactivate_test.exs`; **1 test**.
- Coverage: **86.6%**, 6 relevant lines missed.
- Covered: partial delete failures count as completed attempts and do not stall the saga.
- Excluded: zero matching orders; `orders_to_delete` is non-empty by functional invariant.
- Add boundary-focused tests for login recovery, active-syndicate order filtering, product/order retrieval failures, rollback, final persistence failures, and reactivation.

### P2: Rate limiter boundaries

- Production: `apps/rate_limiter/lib/rate_limiter/leaky_bucket.ex`, `rate_limiter.ex`
- Existing tests: `apps/rate_limiter/test/rate_limiter_test.exs`
- Coverage: `LeakyBucket` **77.7%** (6 missed); `RateLimiter` **75.0%** (1 missed).
- Test queue decrement, empty-queue rescheduling, task/monitor cleanup, normal and abnormal `:DOWN`, response-handler isolation, and `calculate_refresh_rate/1` boundaries. Decide and test the `calculate_refresh_rate(0)` contract.

### P3: Product domain edges

- Production: `apps/shared/lib/data/product.ex`, `product/arcane.ex`, `product/mod.ex`, `product/mod_without_rank.ex`
- Coverage: Product **42.8%**; Arcane **57.1%**; Mod **85.7%**; ModWithoutRank **75.0%**.
- Test `derankify_order/2`, `to_sell_order!/2`, malformed/unsupported products, invalid prices/quantities, Arcane ranks 1-5, rank 0/string/out-of-range inputs, and remaining constructor validation.
- Risk: these conversions affect order prices and posted orders.

### P4: Syndicate persistence errors

- Production: `apps/web_interface/lib/web_interface/persistence/syndicate.ex`
- Existing tests: `apps/web_interface/test/web_interface/persistence/syndicate_test.exs`
- Coverage: **82.4%**, 10 relevant lines missed.
- Test `recover`, `get`, and `put` failure propagation; non-`:ok` collection results; inactive/empty/nil active sets; and unknown/empty IDs.

### P5: Small user-facing gaps

- `logout_live.ex`: add tests for successful logout, manager/persistence failures, redirect, and flash.
- `profile_live.ex`: add tests for user-load success and failure.
- `page_controller.ex`: add root redirect tests with and without a user.
- `router.ex`: test route availability only when routing changes; current coverage is **50.0%**.
- `components/operation_progress.ex`: test nil and named current syndicate only when custom behavior changes.

## Test Coverage: Exclusions

- Do not add percentage-only tests for generated docs, type/spec modules, or framework wiring.
- Unclassified: `apps/shared/lib/utils/extra_guards.ex` is at **0%** (6 relevant lines). Ask before adding it to the backlog.

- `apps/manager/lib/runtime/worker.ex` is covered indirectly by `Manager.WorkerTest` in `apps/manager/test/integration/manager_test.exs`.
- Dedicated tests already cover `web_interface/persistence/{strategy,user}.ex`, AuctionHouse HTTP/use-case modules, Store file-system behavior, and shared data structs.
- Do not pursue percentage-only coverage for `apps/*/lib/type.ex`, `shared.ex`, Store type modules, Phoenix-generated `core_components.ex` code, standard endpoint/telemetry/supervisor wiring, `docs/`, or vendored assets.
- Test custom flash behavior in `core_components.ex` only when it changes; do not expand generated component coverage.

## Test Coverage: Guidance

- Read the production module, template, and nearest test before editing.
- Prefer deterministic mocks and direct callback/message tests over sleeps.
- Use Mock's `in_series/2` for repeated calls with sequential static responses; do not use process-dictionary call counters.
- Keep mock implementations as simple return stubs. Verify arguments and call counts with `assert_called/1`, `assert_called_exactly/2`, and `assert_not_called/1` outside mock functions.
- Tests using Mock must not run asynchronously because module mocks have global effect.
- Test user-visible behavior and module boundaries; do not rewrite assertions just to raise coverage.
- Coverage is a prioritization signal, not a quality score.
- The earlier `:not_purged` run with 51 tests and 67.4% coverage was stale; rerun coverage after compilation settles.

## Header-Based Authentication (2026-10-02)

> Status: **flow verified by hand with curl, nothing implemented.** This replaces the website-based v1 flow and makes Option B unnecessary.

### Context (from the warframe.market Discord)

- warframe.market was hit by a massive scraper wave, consistent with DDoS patterns. The admins enabled Cloudflare's "I'm Under Attack" mode.
- After the attack, the admins made the Cloudflare rules permanently more restrictive. The app is now treated as a bot on the website host.
- Authentication for third parties now goes only through `POST https://api.warframe.market/v1/auth/signin`, using header-based auth.

### Documentation status

- The v1 sign-in is **not documented** and will not be. The [Introduction](https://docs.warframe.market/docs/intro) says:
  - "The legacy v1 API is deprecated and unsupported. We do not plan to publish new v1 documentation."
  - "For now, integrations that require user authorization still need to rely on the existing v1 authorization flow."
- Risk: the only sign-in path open to third parties is deprecated and unsupported, so it can change without notice.
- It is the **same URL** the app already uses as step 2 (`api_signin_url` in `config/prod.exs`). What changes is dropping the website `GET`, the CSRF token, and the cookie.

### Verified flow

1. **Sign in:** `POST https://api.warframe.market/v1/auth/signin`
   - Headers: `Content-Type: application/json`, `Accept: application/json`, `Authorization: JWT`.
   - Body: `{"email": ..., "password": ..., "auth_type": "header"}`.
   - The `Authorization: JWT` request header is what removes the CSRF requirement; without it the response is `400 "CSRF: Token is not present in the request header"`.
   - **`auth_type: "header"` in the body is required to get the token back in a header.** Without it the sign-in still returns 200, but the token comes only in `Set-Cookie` and there is no `Authorization` response header.
2. **Response (200):**
   - The token is in the **`Authorization` response header** as `JWT <token>` (428 characters in the test). There is **no `Set-Cookie`** when `auth_type: "header"` is sent.
   - The body still has `payload.user` with `ingame_name`, `slug`, and `linked_accounts.patreon_profile`, so `parse_ingame_name/1`, `parse_slug/1`, and `parse_patreon/1` still apply.
3. **Authenticated v2 calls** send **`Authorization: Bearer <token>`**. Results for `GET /v2/orders/my`:

| `Authorization` header | Status | Result |
|---|---|---|
| none | 401 | `app.errors.unauthorized` |
| `JWT <token>` | 401 | `app.errors.unauthorized` |
| **`Bearer <token>`** | **200** | 9 orders |
| `<token>` (no scheme) | 401 | `app.errors.unauthorized` |

- Sign-in error bodies (fake credentials) match what `HttpAsyncClient.parse/1` already maps for status 400:
  - invalid email format: `{"error": {"email": ["app.form.invalid"]}}` → `:invalid_email`
  - unknown email: `{"error": {"email": ["app.account.email_not_exist"]}}` → `:wrong_email`
  - wrong password for an existing email: `{"error": {"password": ["app.account.password_invalid"]}}` → `:wrong_password`
- Sign-in credential errors are always **400**, never 401. A 401 has only been seen on authenticated calls with a missing or bad token, so "401 → log in again" applies to authenticated requests, not to sign-in.
- 403 (e.g. unverified account, banned user, not the order owner, per the docs' "Requires" lists) is a different case: logging in again would not help, so do not treat it as a session failure.

### Rework Plan (2026-10-02)

> Status: **Phase 1 implemented on 2026-10-02 (uncommitted).** `shared` (29 tests) and `store` (41 tests) compile with `--warnings-as-errors` and pass on their own. The umbrella build fails first at `apps/auction_house/lib/impl/use_case/login.ex:57` (`key :cookie not found`) until Phases 2-3 land. Phases 2-6 need explicit user approval.

Target flow:

1. `POST /v1/auth/signin` with header `Authorization: JWT` and body `{email, password, auth_type: "header"}`.
2. Read the token from the `Authorization` response header (`JWT <token>`) and `payload.user` from the body.
3. All authenticated v2 calls send `Authorization: Bearer <token>`.
4. Any 401 on an authenticated call means: delete the stored login and send the user back to login.

#### Phases

| Phase | Scope | Main files |
|---|---|---|
| 1 | Data model and storage | `shared/lib/data/authorization.ex`, `shared/lib/data/credentials.ex`, `store/lib/store/file_system.ex`, docs in `store/lib/store.ex` and `auction_house/lib/auction_house.ex` |
| 2 | HTTP layer | `auction_house/lib/impl/http_async_client.ex` |
| 3 | Login use case and config | `auction_house/lib/impl/use_case/login.ex`, `config/{dev,test,prod}.exs` (remove `market_signin_url`), `auction_house/README.md` |
| 4 | Session invalidation | `manager` (delete stored login on 401), `web_interface` (`LoginLive`, redirects) |
| 5 | Tests | see the per-phase test lists below |
| 6 | Validation | `mix compile --warnings-as-errors`, `mix test`, `mix credo --strict`, `mix dialyzer`; manual PROD check: log in, small activate and deactivate on the test account, log out, restart with "remember me" |

**Phase 1 does not compile on its own** (defect D1). It must land together with at least the Phase 2 `HttpAsyncClient` changes and the Phase 3 `Login` changes.

#### Decisions

| # | Decision | Status |
|---|---|---|
| A | Token field name | **Decided:** `access_token` |
| — | Old saved logins | **Decided:** no migration. Every release replaces old saves; `apps/store/priv/setup.json` is tracked and ships empty. |
| P1-a | Reject empty `access_token` in `Authorization.new/1` | **Decided:** yes |
| P1-b | `@derive {Inspect, except: [:access_token]}` on `Authorization` | **Decided:** yes |
| P1-c | Keyword form of `Authorization.new/1` | **Decided:** drop it |
| P1-d | Bad stored token in `Store.FileSystem.get_login_data/1` | **Decided:** never raise; return `{:ok, nil}`. Callers must handle that case (they already do; see Phase 1). |
| P1-e | Redact `Credentials.password` in `inspect/1` | **Decided:** bundle into Phase 1 |
| B | Error atom for 401, and the user-facing message | Open (e.g. `:unauthorized` / "Your session expired, please log in again.") |
| C | How sign-in sends `Authorization: JWT` | Open: extra-headers argument on `HttpAsyncClient.post`, a dedicated sign-in function, or other |
| D | Scope of Phase 4 | Open, but **effectively required** because of defect D3 |
| D6 | Where header names become case-insensitive | Open: lowercase all names in `HttpAsyncClient.handle_response/3`, or a case-insensitive lookup only in `Login` |
| E | Fix the `CaseClauseError` in `parse/1` (unmatched 400/403/404 JSON) in this change | Open |
| F | Add a descriptive `User-Agent` in this change | Open |
| G | Version bump (`mix.exs` and README badge) | Open |

#### Phase 1 spec (final)

`Shared.Data.Authorization`:

- One enforced field: `access_token :: String.t()`.
- Rule, stated in `@typedoc`: `access_token` is the **bare JWT**, with no `JWT ` or `Bearer ` prefix, and never empty. Phase 2 adds `Bearer `; Phase 3 removes `JWT `.
- `new/1`: one clause, `%{"access_token" => t}` when `is_binary(t) and t != ""`. Any other input raises `FunctionClauseError`.
- `@type authorization` is reduced to the map form.
- `@derive {Inspect, except: [:access_token]}`; keep `@derive Jason.Encoder`. Saved form: `{"authorization": {"access_token": "..."}}`.
- The commented-out old module at the bottom of the file is out of scope.

`Shared.Data.Credentials`:

- `@derive {Inspect, except: [:password]}`. `Jason.Encoder` keeps encoding `password`, because the sign-in body needs it.

`Store.FileSystem.get_login_data/1`:

- Never raises on bad stored data. Before calling `Authorization.new/1`, check that `access_token` is a non-empty binary; otherwise return `{:ok, nil}`.
- Return type unchanged: `{:ok, {Authorization.t(), User.t()} | nil} | {:error, :file.posix() | Jason.DecodeError.t()}`.
- Callers already handle `{:ok, nil}`:
  - `Manager.Saga.Login.handle_continue/2` signs in with the credentials the user typed.
  - `Manager.Runtime.Worker` (`:recover_login`) passes it through; the spec allows `User.t() | nil`.
  - `WebInterface.Application.start/2` calls `Persistence.init(..., nil)`; `Persistence.User.set_user/2` accepts `nil`, so the user lands on login.

Phase 1 tests:

| File | Cases |
|---|---|
| `apps/shared/test/data/authorization_test.exs` | valid map; `""` raises `FunctionClauseError`; `inspect/1` does not contain the token |
| `apps/shared/test/data/credentials_test.exs` | `inspect/1` does not contain the password |
| `apps/store/test/unit/file_system_test.exs` | exact saved JSON with `access_token`; load returns the struct; `null`, `""`, non-string, and missing `access_token` each return `{:ok, nil}` |
| `apps/store/test/integration/store_test.exs` | fixture and assertions use `access_token` |

#### Phases 2-4 outline

- **Phase 2 (`HttpAsyncClient`):**
  - `build_headers` sends `Authorization: Bearer <access_token>`, replacing `x-csrftoken` and `Cookie`. Fixed header order, e.g. `[{"Authorization", "Bearer " <> t} | @static_headers]`.
  - A sign-in path that sends `Authorization: JWT` without an `%Authorization{}` (decision C).
  - A 401 clause in `parse/1` returning a dedicated error (decision B).
  - Safe logging: log only the status code and response body, never the full `%HTTPoison.Response{}`.
- **Phase 3 (`Login`):**
  - One `POST` to `api_signin_url`. Remove the website `GET`, `find_xrfc_token/2`, `parse_cookie/1`, and the Floki dependencies.
  - `finish/1` reads the `Authorization` response header case-insensitively (D6), removes `JWT `, and builds `Authorization.new(%{"access_token" => token})`. `parse_ingame_name/1`, `parse_slug/1`, and `parse_patreon/1` are unchanged.
  - Remove `market_signin_url` from all configs and from the `auction_house` README.
- **Phase 4 (session invalidation):**
  - On 401 from an authenticated call, delete the stored login and send the user to `/login` with a clear message.
  - `LoginLive` handles any new error atoms.
  - Logout only discards the token locally, because sign-out does not revoke v1 tokens.
- **Phase 5 tests beyond Phase 1:** `http_async_client_test.exs` (Bearer header, 401, header-name case, sign-in headers), `use_case/login_test.exs` (single POST, prefix removal, 400 errors), `auction_house_test.exs` (remove the `GET /auth/signin` stub), `manager/test/unit/saga/login_test.exs` and `manager_test.exs` (new login stubs; 401 deletes the stored login), `login_live_test.exs` (new messages), and fixtures building `%Authorization{cookie:, token:}` in `server_test`, `delete_order_test`, `place_order_test`, and `activate_test`.
- Not in scope: `GetUserOrders` calls `/v2/orders/user/{slug}` without auth, so it sees only visible orders. Decide separately whether that should change.

#### Integration defects between Phases 1 and 2

| # | Defect | Effect if missed | Fix |
|---|---|---|---|
| D1 | `HttpAsyncClient` (`post/6`, `delete/5`, `get/5`), `Login`, and about 10 test fixtures match or build `%Authorization{cookie:, token:}` | Compile errors | Land Phases 1-3 together |
| D2 | The prefix rule is broken: Phase 3 stores `JWT eyJ...` and Phase 2 sends `Bearer JWT eyJ...` | 401 on every call | `@typedoc` rule; Phase 2 test asserts the exact `Bearer` header; Phase 3 test asserts `JWT ` is removed |
| D3 | `Manager.Saga.Login.handle_continue/2` uses stored login data and **ignores the typed credentials** whenever data exists | An empty, broken, or expired (60 days) token is reused forever; the user cannot log in even with the right password | P1-a/P1-d reject bad tokens on load; Phase 2 maps 401; **Phase 4 deletes stored data on 401** |
| D4 | The catch-all in `HttpAsyncClient.parse/1` logs `inspect(%HTTPoison.Response{})`. HTTPoison 2.x includes `request`, which holds the request headers (`Authorization: Bearer ...`) and, for sign-in, the body with email and password. Today every 401 goes through this clause. | Tokens and passwords in the terminal and logs | Phase 2 logs only status and body. P1-b/P1-e redact structs. Raw header lists in `Request.args.call` are plain strings, so Phase 2 must never log them. |
| D5 | `post/6` has no clause for a missing `%Authorization{}`, and `Login.start/2` runs inside the `AuctionHouse.Runtime.Server` process (`handle_cast/2`) | A `FunctionClauseError` crashes the server process, which loses its state and restarts | Phase 2 sign-in path (decision C) |
| D6 | `handle_response/3` builds `headers_map` with `Map.put`, keeping the server's header-name case; `curl` saw lowercase `authorization` over HTTP/2, hackney uses HTTP/1.1 | `finish/1` cannot find the token, so login fails | Decide where to make the lookup case-insensitive |
| D7 | `http_async_client_test.exs` asserts exact header lists | Brittle tests | Fixed header order in Phase 2 |
| D8 | With "remember me", `setup.json` stores the token in plain text | The file is a 60-day credential that cannot be revoked (sign-out does not revoke v1 tokens) | Already true with the cookie; document it in the README; out of scope |

### Additional verification (2026-10-02)

Non-mutating probes with a fresh `Bearer` token: an invalid order ID for `DELETE` and an empty body for `POST`, so nothing was created or deleted.

| Request | Status | Body | Meaning |
|---|---|---|---|
| `GET /v2/orders/my`, same `User-Agent` as sign-in | 200 | `data` array | Auth accepted |
| `GET /v2/orders/my`, **different** `User-Agent` | 200 | `data` array | Token is **not** tied to the `User-Agent` |
| `DELETE /v2/order/000000000000000000000000` | 404 | `app.order.notFound` | Auth accepted; already mapped to `:order_non_existent` |
| `POST /v2/order` with `{}` | 400 | `inputs`: `itemId`/`type` required, `quantity`/`platinum` too small | Auth accepted; reached validation |
| `DELETE` / `POST` above without auth | 401 | `app.errors.unauthorized` | Auth required |

- **Token lifetime: 60 days** (`exp - iat` = 5,184,000 s).
- Token claims: `aud`, `auth_type`, `exp`, `iat`, `iss`, `jwt_identity`, `login_ip`, `login_ua`, `secure`, `sid`. `login_ua` is recorded but not enforced (see table).
- No rate-limit headers (`x-ratelimit-*`, `ratelimit*`, `retry-after`) in authenticated responses. The documented limit is still 3 requests per second; the app's `rate_limiter` is configured for 1 per second in `config/prod.exs`.
- `POST /v2/order` validation errors use `{"error": {"inputs": {...}}}` with several fields at once. Existing bug, not caused by the auth change: the 400 clause of `HttpAsyncClient.parse/1` matches only `inputs.itemId == "app.field.invalid"` and the known email/password errors. Any other JSON that decodes has **no matching clause and raises `CaseClauseError`**; only decode failures return `:unable_to_decode_error`. The 403 and 404 clauses have the same shape.

### Order create and delete (2026-10-02)

User-approved test on the test account, which is in invisible mode. The order body matched `Shared.Data.Product.Mod.to_sell_order!/2`:

```json
{"itemId":"54e644ffe779897594fa68d2","type":"sell","visible":true,"platinum":14,"quantity":1,"rank":0}
```

| Step | Result |
|---|---|
| `POST /v2/order` with `Bearer` | 200, `data.id` = `6abf6cf890780835bc9e083d`, fields echoed back |
| Order listed in `GET /v2/orders/my` | yes |
| `DELETE /v2/order/6abf6cf890780835bc9e083d` with `Bearer` | 200, `data.id` echoed |
| Order listed after delete | no |

- `PlaceOrder.finish/1` reads `data.id`, which matches the response.
- The account was back to its original 9 orders afterwards.

### Sessions and token invalidation (2026-10-02)

| Check | Result |
|---|---|
| Two consecutive sign-ins | Two **different** tokens; the older one stays valid |
| `POST /v2/auth/signout` with a v1 token | 200, empty body |
| Same token after sign-out | **Still 200** on `GET /v2/orders/my` |
| Other session's token after the first sign-out | Still 200 |

- A new sign-in does not invalidate older tokens, and **`/v2/auth/signout` does not invalidate v1 tokens**. A v1 token stays usable until `exp` (60 days), whatever the client does.
- No `401` from a genuinely invalidated token was observed. Responses for missing or bad tokens on `GET /v2/orders/my`:

| `Authorization` | Status | `error.request` |
|---|---|---|
| none | 401 | `app.errors.unauthorized` |
| `Bearer garbage` | 401 | `app.jwt.invalid` |
| `Bearer <well-formed JWT, bad signature>` | 401 | `app.jwt.algorithmMismatch` |

- So the app should treat **any 401** as "session invalid, log in again", not match on specific error codes.

### Still unverified

- Response once a token passes its 60-day `exp`. Probably 401 with an `app.jwt.*` code, not observed. There is no v1 refresh flow; v2 `/auth/refresh` is documented for registered clients only.

## PROD Login Blocked by Cloudflare (2026-10-01)

> Status: **superseded on 2026-10-02.** The website path will not reopen; see **Header-Based Authentication (2026-10-02)**. Kept as background.

### Discovery

- Symptom: PROD login fails. Logs show `Failed to decode error message with status 403` (HTML body) followed by `Unknown message received: {:login, {:error, :unable_to_decode_error}}`.
- The 403 body is a Cloudflare **managed challenge** page ("Just a moment...", `cType: 'managed'`, response header `cf-mitigated: challenge`).
- Discord reports that warframe.market enabled Cloudflare **"I'm Under Attack" mode (UAM)** because of a wave of parsing crawlers. **Unconfirmed:** from outside, UAM looks the same as a custom WAF rule that challenges the website host.
- Probe results (one `GET` each, custom `User-Agent`):

| URL | Result |
|---|---|
| `warframe.market/` | 403, `cf-mitigated: challenge` |
| `warframe.market/auth/signin` | 403, `cf-mitigated: challenge` |
| `warframe.market/items/` | 403, `cf-mitigated: challenge` |
| `warframe.market/static/assets/` | 403, `cf-mitigated: challenge` |
| `api.warframe.market/v2/versions` | 200, no challenge |
| `POST api.warframe.market/v1/auth/signin` (no token) | 400 JSON `"CSRF: Token is not present in the request header"` |

- The whole website host is challenged, even static assets. The API host is not. Changing the `User-Agent` makes no difference.

Re-check command (run from any shell):

```sh
for u in https://warframe.market/auth/signin https://api.warframe.market/v2/versions; do printf "%-45s " "$u"; curl -s -o /dev/null -D - -A "MarketManager-diagnostic/1.0" "$u" | rg -i "^(HTTP/|cf-mitigated)" | tr -d '\r' | tr '\n' ' '; echo; done
```

If `/auth/signin` returns 200 without `cf-mitigated`, the v1 flow should work again unchanged.

### Why it affects us

- warframe.market's docs say third-party apps must keep using the **v1 authorization flow**:
  - v2 `POST /auth/signin` is "first-party only": it needs a registered first-party `clientId` plus Firebase App Check.
  - OAuth 2.0 registration is closed. [OAuth overview](https://docs.warframe.market/docs/oauth/overview) says: "Public client registration is not open, and third-party developers cannot register OAuth applications at this time."
- The v1 flow in `apps/auction_house/lib/impl/use_case/login.ex` has two steps:
  1. `GET https://warframe.market/auth/signin` (**website**). From the response it reads the CSRF token in `meta[name="csrf-token"]` (`find_xrfc_token/2`) and the anonymous `JWT` cookie in `Set-Cookie` (`parse_cookie/1`).
  2. `POST https://api.warframe.market/v1/auth/signin` with `Cookie: JWT=...`, `x-csrftoken`, and the credentials.
- Step 2 needs a CSRF token that **only step 1 provides**. Step 1 is now challenged.
  - The anonymous `JWT` that the API host sets has no `csrf_token` claim.
  - The website's `JWT` has one, and also records `login_ua` and `login_ip`.
- Browsers still work, because they pass the challenge, often invisibly. Non-browser clients (HTTPoison, `curl`) cannot.

### Consequences

- No user can sign in through the app while the challenge is active. `Manager.recover_login/0` may still work for already-stored sessions; this has not been verified.
- `HttpAsyncClient.parse/1`'s 403 clause expects JSON. It logs a decode error and returns `{:error, :unable_to_decode_error}`.
- `WebInterface.LoginLive` has no clause for that error, so the catch-all shows "Unknown message received, please check the logs and report it!".
- Any feature that loads from `warframe.market/static/assets/` is also blocked.

### Ruled out

- **Header changes**, including a browser `User-Agent`: still 403. The challenge needs JavaScript to run in a real browser environment.
- **Pasting `cf_clearance` into HTTPoison**:
  - Cloudflare documents the cookie as "securely tied to the specific visitor and device it was issued to", and it is continuously re-evaluated ("Precursor").
  - HTTPoison's TLS and HTTP/2 fingerprints and its lack of JavaScript make it a different client from the browser that earned the cookie.
  - Making it pass would require impersonating a browser, which warframe.market's [Rules](https://docs.warframe.market/docs/rules/overview) say may get the app blocked.
- **HTTPoison obtaining `cf_clearance` itself**: impossible without a challenge solver or headless browser. That is circumvention; out of scope.

### Options if UAM stays long-term

> Superseded on 2026-10-02 by header-based sign-in, which needs no website page. Option B is no longer needed.

#### Low-cost (independent of B)

- Detect Cloudflare challenge responses (403 with `cf-mitigated: challenge`) and show a clear message in `LoginLive` instead of "Unknown message received". Pending decisions:
  - the error atom name
  - the user-facing message
  - whether to detect by header or by status
- Send a descriptive `User-Agent` (e.g. `MarketManager/x.y.z (+repo-url)`), as warframe.market's Rules require. It does not fix the challenge.
- Ask the maintainers on Discord for a Cloudflare exception for the app, e.g. matching the `User-Agent`, a shared header, or an IP. This is the only fix that needs no client-side workaround.

#### Option B: sign in through the embedded webview

- Idea: a real browser engine (the `desktop` webview) loads the website. The user passes the challenge there as a person, and the app reuses the result for its API calls. `api.warframe.market` is not challenged.
- Webview engines: WebKitGTK on Linux, WebView2 (Edge) on Windows.
- What `:wxWebView` offers (OTP 28.3.2, `wx-2.5.3`):
  - `loadURL/2`, `getCurrentURL/1`
  - `getPageSource/1`, which can read the CSRF meta tag
  - `runScript/2`, which returns `{boolean(), charlist()}`
  - events: `webview_navigating`, `webview_navigated`, `webview_loaded`, `webview_error`, `webview_newwindow`, `webview_title_changed`
- **Blocker for the naive version:**
  - `:wxWebView` has **no cookie API**.
  - The `JWT` cookie is **`HttpOnly`**, so neither Elixir nor `document.cookie` can read it.
  - The CSRF token alone is useless without the matching `JWT`.
- UI impact: the app has one `Desktop.Window` showing the local Phoenix UI. Signing in means temporarily pointing it at warframe.market (`Desktop.Window.show(WebInterface, url)`) or opening a second window.

| Variant | Idea | Unknowns / risks | Effort |
|---|---|---|---|
| **B1: in-page sign-in** | After the challenge passes, `runScript` runs the v1 sign-in `fetch` from the warframe.market page; the browser attaches `JWT` and the CSRF token. The app requests a readable token (`auth_type: "header"`) and hands it to HTTPoison. | (a) `auth_type: "header"` comes from community usage and is **not in the current docs**. (b) CORS `Access-Control-Expose-Headers` may hide the `Authorization` header from the page. (c) The API may reject the token when HTTPoison uses a different `User-Agent` (`login_ua` is stored in the session). (d) `runScript` is synchronous and `fetch` is async, so the result must be polled for (e.g. via a global variable). | Medium |
| **B2: proxy all API calls through the webview** | Every warframe.market request runs as an in-page `fetch` instead of HTTPoison. | Rewrites `HttpAsyncClient` and the rate-limiter integration around a GUI component; hard to test; no headless or CI path. | High |
| **B3: native cookie access** | A NIF into the WebKitGTK or WebView2 cookie store. | Different per platform, fragile, a crash takes down the VM. | Very high, not recommended |

#### Manual verification for B1 (before any code)

1. **Does the challenge pass in the webview?** In dev `iex`, run `Desktop.Window.show(WebInterface, "https://warframe.market/auth/signin")` and check that the sign-in page loads, on both Linux and Windows.
2. **Is the token readable?** In a browser DevTools console on a warframe.market page, run the v1 sign-in `fetch` with real credentials and `auth_type: "header"`. Check whether the response `Authorization` header is readable from JavaScript.
3. **Is the token tied to the User-Agent?** Use that token with `curl` and the app's `User-Agent` against one authenticated API endpoint.

Proceed with B1 only if all three pass. Confirm with the maintainers that the undocumented `auth_type: "header"` is acceptable.

## Change Log

- **2026-10-02:**
  - Discord: Cloudflare restrictions on the website are permanent; third parties must use header-based v1 sign-in.
  - Verified header-based sign-in and `Bearer` usage on `GET /v2/orders/my`; added **Header-Based Authentication (2026-10-02)**.
  - Verified `Bearer` on `DELETE`/`POST /v2/order` (non-mutating probes), 60-day token lifetime, no `User-Agent` binding, no rate-limit headers, and that `auth_type: "header"` is required.
  - Verified a real order create and delete with `Bearer` (Abating Link, 14p), that tokens survive a new sign-in and `/v2/auth/signout`, and the 401 error codes for missing or bad tokens.
  - Verified the wrong-password response (400 `app.account.password_invalid`).
  - Added **Rework Plan**: phases, decisions (A and P1-a to P1-e decided; B-G and D6 open), the final Phase 1 spec, and integration defects D1-D8.
  - Implemented Phase 1: `Authorization` (`access_token`, non-empty, redacted `Inspect`), `Credentials` (redacted `password`), `Store.FileSystem.get_login_data/1` (`valid_authorization?/1`), doc examples in `Store` and `AuctionHouse`, and the Phase 1 tests.
  - Marked the Cloudflare section and Option B as superseded.
- **2026-10-01:**
  - Renamed from `test_evaluation.md` and restructured for agent use.
  - Added project state, map, working agreements, and known issues.
  - Re-measured coverage: 74 tests, 76.2%, unchanged.
  - Documented the PROD login Cloudflare investigation.
  - Switched to `master`; the `.gitignore` rename is committed in `92eb066` (not pushed).
- **2026-07-31:** Coverage snapshot (74 tests, 76.2%). Added `Manager.Saga.Deactivate` and `WebInterface.Persistence` tests.
