# SayBar Maintainer Docs

This directory holds the architecture and product-shape notes for the standalone SayBar repository.

Use these docs in this order:

1. [adr-0001-keep-direct-embeddedserver-baseline.md](adr-0001-keep-direct-embeddedserver-baseline.md)
   This is the short architecture decision record for the accepted direct-`EmbeddedServer` app baseline.
2. [embedded-server-ui-architecture.md](embedded-server-ui-architecture.md)
   This is the current implementation note for SayBar's thin-shell architecture around one app-owned `EmbeddedServer`.
3. [embedded-session-api-coverage.md](embedded-session-api-coverage.md)
   This is the complete coverage matrix for the embedded session API surface SayBar can use, what is implemented, and what remains future-scope.
4. [test-coverage-expansion-plan.md](test-coverage-expansion-plan.md)
   This is the staged plan for expanding foundation, implemented embedded-session, and later UI coverage.
5. [accessibility-and-ui-automation-notes.md](accessibility-and-ui-automation-notes.md)
   This is the current reference note for menu bar accessibility inspection, XCUITest behavior, and menu-bar presentation constraints.

## Reading Guide

- If you need to know what product shape is settled, start with the ADR.
- If you need to know what the app is supposed to be right now in code, read the embedded-server architecture note next.
- If you need to see the full `SpeakSwiftlyServer` embedded session API coverage inventory, read the coverage matrix next.
- If you need to expand test coverage, use the test coverage expansion plan before adding new UI tests.
- If you need to understand current accessibility or menu bar UI automation behavior, read the accessibility and UI automation notes after the architecture note.
