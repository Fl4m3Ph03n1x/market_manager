# Market Manager Handover

> Handover context for agents working on the `market_manager` Elixir umbrella.
> Local only (git-ignored). Last updated: **2026-10-01**.

## How to Use This File

- Read **Status** and **Active Blockers** first; they change most often.
- Every fact is dated. Re-verify anything older than the latest commit before relying on it.
- Precedence: user instructions > `AGENTS.md` > this file.
- After finishing work, update **Status**, the affected section, and **Change Log**. Replace stale facts instead of appending contradicting ones.
- Section headings are stable; refer to them by name.

## Status (2026-10-01)

| Item | Value |
|---|---|
| Branch | `master` at `92eb066 updating handover file`, 1 commit ahead of `origin/master` (`ba9cf26`) |
| Uncommitted | None |
| Version | `2.2.9` in `mix.exs`; latest tag `2.2.9`; README badge `v=2.2.9` |
| Local toolchain | Elixir 1.20.1, Erlang/OTP 28.3.2 (ASDF) |
| CI toolchain | Elixir 1.20.x, OTP 28.5.x on `windows-2022` (`.github/workflows/master.yml`) |
| Compile | `mix compile --warnings-as-errors`: clean |
| Tests | `mix coveralls -u`: **74 passed** |
| Coverage | **76.2%** total |
| Active blocker | PROD login broken by a Cloudflare challenge (see **Active Blockers**) |
| Release build | Last known to fail (see **Known Issues**); not re-verified on 2026-10-01 |

## Active Blockers

1. **PROD login blocked by Cloudflare on `warframe.market`.**
   - State: investigation complete; **nothing implemented**. The user is waiting to see whether warframe.market rolls the mitigation back.
   - Rule: do not implement any fix without explicit user approval.
   - Details: section **PROD Login Blocked by Cloudflare (2026-10-01)**.

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

## PROD Login Blocked by Cloudflare (2026-10-01)

> Status: **investigation only, nothing implemented.** Waiting to see whether warframe.market rolls the mitigation back.

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

- **2026-10-01:**
  - Renamed from `test_evaluation.md` and restructured for agent use.
  - Added project state, map, working agreements, and known issues.
  - Re-measured coverage: 74 tests, 76.2%, unchanged.
  - Documented the PROD login Cloudflare investigation.
  - Switched to `master`; the `.gitignore` rename is committed in `92eb066` (not pushed).
- **2026-07-31:** Coverage snapshot (74 tests, 76.2%). Added `Manager.Saga.Deactivate` and `WebInterface.Persistence` tests.
