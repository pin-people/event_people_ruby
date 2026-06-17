# EventPeople — Ruby Implementation

Spec version target: see `.event_people.yml` → `spec_version`
Spec contract: `spec/contract.yml` in the main `event_people` repository
GitHub: <https://github.com/pin-people/event_people_ruby>

## Project Structure

```
lib/event_people/
├── config.rb
├── event.rb
├── listener.rb
├── emitter.rb
├── daemon.rb
├── broker/
│   ├── base.rb          ← BaseBroker interface
│   ├── context.rb       ← Context interface
│   └── rabbit/
│       ├── rabbit_context.rb
│       ├── topic.rb
│       └── queue.rb
└── listeners/
    ├── base.rb          ← BaseListener
    └── manager.rb       ← ListenersManager
```

## Critical Rule — Spec Conformance

**Before implementing any new feature or changing existing behavior:**

1. Check `spec/contract.yml` in the main repo for the expected interface definition

2. Check `.event_people.yml` for known deviations already accepted in this implementation

If the change **aligns with the spec**: implement and update `.event_people.yml` status accordingly.

If the change **would deviate from the spec** (different method name, different signature,
different attribute, different behavior):

→ **STOP and ask the user:**

> "This change deviates from spec/contract.yml. Should we:
>
> 1. Update the spec first (via /update-spec in the main repo), then implement here?
>
> 2. Conform to the current spec instead?"

Never implement a deviation silently.

## Known Deviations

See `.event_people.yml` → `deviations` section. Currently clean.

> The bang-method deviation (DEV-RB-001) was resolved — `success`, `fail`, `reject` are now the
> primary interface. The `success!`, `fail!`, `reject!` aliases remain but emit deprecation warnings.

## Known Bugs

See `.event_people.yml` → `bugs` section. Currently clean.

## Pending Features

None — all spec v1.2.0 components are implemented.
