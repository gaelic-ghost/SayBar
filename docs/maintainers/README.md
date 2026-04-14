# SayBar Maintainer Docs

This directory holds the architecture and product-shape notes for the standalone SayBar repository.

Use these docs in this order:

1. [adr-0001-keep-embedded-session-architecture.md](adr-0001-keep-embedded-session-architecture.md)
   This is the current accepted architecture decision. Read this first when you need the repo's current product-baseline stance.
2. [embedded-session-integration-plan.md](embedded-session-integration-plan.md)
   This is the current implementation record for the embedded-session architecture that the app actually ships today.
3. [accessibility-and-ui-automation-notes.md](accessibility-and-ui-automation-notes.md)
   This is the current reference note for menu bar accessibility inspection, XCUITest behavior, and comparison points with other macOS menu bar apps.
4. [controller-architecture-options.md](controller-architecture-options.md)
   This is the future-direction decision memo for possible controller-oriented or helper-backed pivots if product requirements change later.

## Reading Guide

- If you need to know what the app is supposed to be right now, start with the ADR.
- If you need to know how the implemented embedded model is structured, read the embedded-session integration plan next.
- If you need to understand current accessibility or menu bar UI automation behavior, read the accessibility and UI automation notes after the embedded-session plan.
- If you are evaluating a future architecture change, read the controller-options memo only after reading the ADR so you do not mistake future exploration for current repo direction.
