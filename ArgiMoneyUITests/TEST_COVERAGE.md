# UI acceptance-test coverage

Status is tied to the specification IDs. “Implemented — not run” means a test exists but has not been built or executed in this environment. UI tests use an in-memory SwiftData store, isolated UserDefaults suite, fixed clock and reusable `UITestFixtureCatalog` seeds.

| ID | Status | Notes |
|---|---|---|
| NAV-001 | Implemented — not run | Clean isolated launch |
| NAV-002 | Implemented — not run | Recording controls and balance identifiers |
| NAV-003 | Implemented — not run | Main tab navigation |
| NAV-004 | Blocked | Navigation-state restoration assertion not yet added |
| NAV-005 | Blocked | Category popover presentation/dismissal assertion not yet added |
| NAV-006 | Implemented — not run | Empty-state tab navigation |
| NAV-007 | Blocked | Test mode intentionally uses in-memory SwiftData; persistent isolated-store relaunch test remains to be added |
| NAV-008 | Blocked | Background/foreground simulator lifecycle assertion not yet added |
| TX-001 | Implemented — not run | Empty list and zero monthly totals |
| TX-002 | Implemented — not run | November fixture, six stable transaction IDs and month totals |
| TX-003 | Implemented — not run | Create income through the transaction form |
| TX-004 | Implemented — not run | Create expense through the transaction form |
| TX-005 | Implemented — not run | Edit seeded transaction and assert same row/count |
| TX-006 | Implemented — not run | Change category from transaction editor and assert row attribution |
| TX-007 | Implemented — not run | Swipe-delete seeded row |
| TX-008 | Blocked | No bulk-delete confirmation/cancel UI assertion yet |
| TX-009 | Implemented — not run | Search by detail |
| TX-010 | Blocked | Clear/hide search assertion not yet added |
| TX-011 | Implemented — not run | Set Day grouping |
| TX-012 | Implemented — not run | Set Month grouping |
| TX-013 | Not applicable | Transactions screen has no month-selection control; report-period selection is a separate flow |
| TX-014 | Implemented — not run | Large-amount fixture and visible balance control |
| TX-015 | Implemented — not run | Many-row fixture and fixed-header assertion |
| TX-016 | Blocked | Fractional amount fixture/assertion not yet added |
| INPUT-001 | Blocked | Real microphone-permission flow is intentionally bypassed by the deterministic transcriber |
| INPUT-002 | Blocked | Start/stop UI state assertion not yet added |
| INPUT-003 | Blocked | Permission denial is not injectable in this UI harness yet |
| INPUT-004 | Blocked | Speech-permission denial is not injectable in this UI harness yet |
| INPUT-005 | Implemented — not run | Injected transcript opens populated editor without real speech services |
| INPUT-006 | Implemented — not run | Injected salary transcript opens an income editor |
| INPUT-007 | Blocked | Ambiguous transcript handling assertion not yet added |
| INPUT-008 | Blocked | Cancel/exit recording assertion not yet added |
| INPUT-009 | Not applicable | No separate manual natural-language text-entry screen exists |
| INPUT-010 | Blocked | Numeric edge-case assertions not yet added |
| INPUT-011 | Blocked | Category selection assertion not yet added |
| INPUT-012 | Implemented — not run | Reusable expanded-category fixture, search and selection |
| CAT-001 | Blocked | Category contexts not yet asserted |
| CAT-002 | Implemented — not run | Create category with mock category-module entitlement |
| CAT-003 | Implemented — not run | Rename seeded category with mock category-module entitlement |
| CAT-004 | Blocked | Symbol-picker assertion not yet added |
| CAT-005 | Blocked | Color-picker assertion not yet added |
| CAT-006 | Blocked | Swipe-delete category assertion not yet added |
| CAT-007 | Not applicable | Category form has no Delete action |
| CAT-008 | Blocked | Unsaved category-edit dismissal assertion not yet added |
| CAT-009 | Blocked | Duplicate-name validation is not exposed in the current editor |
| CAT-010 | Implemented — not run | Verify category-management paywall without entitlement |
| ACC-001 | Implemented — not run | Seeded account list names with mock accounts-module entitlement |
| ACC-002 | Implemented — not run | Create account with mock accounts-module entitlement |
| ACC-003 | Blocked | Account edit assertion not yet added |
| ACC-004 | Blocked | Unused-account deletion assertion not yet added |
| ACC-005 | Implemented — not run | Deleting referenced account reports an error and keeps its row |
| ACC-006 | Not applicable | No account-transfer screen/action is integrated |
| ACC-007 | Not applicable | No account-transfer validation flow is integrated |
| ACC-008 | Not applicable | No account-transfer persistence flow is integrated |
| ACC-009 | Blocked | Account balance after transaction assertion not yet added |
| ACC-010 | Blocked | Locked account-module assertion not yet added |
| REP-001 | Implemented — not run | Reports dashboard free/premium entries |
| REP-002 | Implemented — not run | Income/expense/net report values from fixture |
| REP-003 | Implemented — not run | Expense-category report fixture categories |
| REP-004 | Implemented — not run | Current-month metric identifiers match November totals |
| REP-005 | Implemented — not run | This Year includes October and November totals |
| REP-006 | Blocked | Custom date-range assertion not yet added |
| REP-007 | Blocked | Invalid-range rejection assertion not yet added |
| REP-008 | Implemented — not run | Cash-flow report chart/net summary with mock entitlement |
| REP-009 | Implemented — not run | Spending trend and period breakdown with mock entitlement |
| REP-010 | Implemented — not run | Account activity report with mock entitlement |
| REP-011 | Not applicable | Smart Insights is not an active `ReportType`/purchase product in this checkout |
| REP-012 | Implemented — not run | Locked cash-flow report displays paywall and no report content |
| CSV-001 | Implemented — not run | Import/export entry points |
| CSV-002 | Blocked | Share/export file-content assertion not yet added |
| CSV-003 | Blocked | Header-only export assertion not yet added |
| CSV-004 | Blocked | CSV escaping assertion not yet added |
| CSV-005 | Blocked | Document-picker CSV import flow not yet automated |
| CSV-006 | Blocked | Malformed CSV UI flow not yet automated |
| CSV-007 | Blocked | Re-import duplicate UI flow not yet automated |
| CSV-008 | Blocked | Import cancellation UI flow not yet automated |
| CSV-009 | Not applicable | Flexible generic CSV import exists, but no interactive column-mapping screen is present |
| CSV-010 | Blocked | Advanced-import paywall assertion not yet added |
| IAP-001 | Implemented — not run | Debug UI launches inject the reusable mock purchase service |
| IAP-002 | Blocked | Purchase-to-report entitlement assertion not yet added |
| IAP-003 | Blocked | Independent spending entitlement assertion not yet added |
| IAP-004 | Blocked | Account-report entitlement assertion not yet added |
| IAP-005 | Not applicable | Smart Insights product is commented out/not configured in this checkout |
| IAP-006 | Blocked | Account-module entitlement assertion not yet added |
| IAP-007 | Blocked | Category-module entitlement assertion not yet added |
| IAP-008 | Not applicable | Themes product and theme-selection UI are not integrated |
| IAP-009 | Blocked | Advanced-import entitlement assertion not yet added |
| IAP-010 | Blocked | Full-bundle entitlement assertion not yet added |
| IAP-011 | Blocked | Mock purchase service does not yet expose deterministic cancel/failure outcomes |
| IAP-012 | Blocked | Restore-state injection/assertion not yet added |
| SET-001 | Blocked | Settings sections are visited by navigation smoke but not individually asserted |
| SET-002 | Implemented — not run | Group-by-month preference updates Transactions |
| SET-003 | Blocked | Relaunch persistence is incompatible with the current in-memory UI-test store |
| SET-004 | Not applicable | No theme-selection screen is integrated |
| SET-005 | Not applicable | No theme-selection screen is integrated |
| SET-006 | Not applicable | No locked-theme flow is integrated |
| SET-007 | Not applicable | No theme-selection persistence flow is integrated |
| ERR-001 | Blocked | Persistence-error injection is not available in the app launch harness |
| ERR-002 | Blocked | One-shot persistence-failure recovery is not available in the app launch harness |
| ERR-003 | Blocked | Corrupt-file UI import flow not yet automated |
| ERR-004 | Blocked | Very-large-value editor assertion not yet added |
| ERR-005 | Blocked | Dynamic Type launch configuration/assertion not yet added |
| ERR-006 | Implemented — not run | Stable identifiers checked on record and Transactions controls |
| ERR-007 | Blocked | Rapid repeated-action assertion not yet added |
| ERR-008 | Blocked | Background interruption recovery assertion not yet added |

## Runner/toolchain limitation

This environment has no `xcodebuild` or Swift compiler, so the required minimal UI smoke test could not be built or run here. `XCTestCompatibilityAdapter` is deliberately limited to runner discovery/smoke coverage; the acceptance scenarios use `import Testing`, `@Suite`, `@Test`, and `#expect`. Do not treat the Swift Testing + `XCUIApplication` combination as verified until the UI test target builds and the adapter plus one Swift Testing UI test run in the installed Xcode/SDK.
