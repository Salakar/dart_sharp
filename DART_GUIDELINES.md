# Dart & Flutter API Design — Compressed Reference

## Core Principles
1. **Least Surprise** — No hidden side effects. Name methods for everything they do.
2. **Pit of Success** — Use named params so the easiest path is the correct path.
3. **Progressive Disclosure** — Simple cases simple, advanced cases possible.
4. **Make Invalid States Unrepresentable** — Use sealed classes, not bool flags + nullables.

## Naming Rules
- Types: `UpperCamelCase`. Identifiers: `lowerCamelCase`. Files: `lowercase_with_underscores`.
- Acronyms >2 letters capitalized like words: `HttpClient`, not `HTTPClient`.
- Booleans: `isEmpty`, `hasElements`, `canClose`, `shouldRefresh` — non-imperative verb phrases.
- Actions: imperative verbs (`add`, `remove`, `clear`, `dispose`).
- Queries: nouns or non-imperative verbs (`indexOf`, `substring`).
- Conversions: `toXxx()` = new copy, `asXxx()` = view of original.
- Consistent verbs throughout: pick `get`/`delete` OR `fetch`/`remove`, don't mix.

## API Design Patterns

### Parameters & Defaults
- Prefer **required named parameters** for 2+ args. Prevents order mistakes, self-documents call sites.
- Provide sensible defaults to minimize boilerplate (`timeout = Duration(seconds: 30)`).
- Use factory constructors for named variants: `Button.primary()`, `Button.destructive()`.

### Error Handling — Result Pattern
```dart
sealed class Result<T> {}
final class Ok<T> extends Result<T> { final T value; const Ok(this.value); }
final class Err<T> extends Result<T> { final AppException error; const Err(this.error); }
```
Force callers to handle both cases via exhaustive `switch`. Create domain-specific exception hierarchies (`ValidationException`, `NetworkException`, `AuthException`).

### Streams & Async
- Default to **single-subscription** `StreamController`; use `.broadcast()` only for multiple listeners.
- **Always close** controllers and **cancel** subscriptions in `dispose()`.
- Handle stream errors explicitly: `stream.listen(onData, onError: handleError, onDone: cleanup)`.
- Use `Debouncer` (wait for pause) for search input; `Throttler` (limit frequency) for scroll.

### Extension Methods
Add functionality without modifying classes. Good for validation helpers, formatting, safe list access (`firstOrNull`).

### Avoid
- One-member abstract classes → use `typedef` function types instead.
- Static-only classes → use top-level library functions.

## Type Safety
- **Never return nullable collections.** Return empty `[]` or `{}` instead.
- **Avoid `dynamic`** — use generics or `Object?`.
- Use **bounded generics** when constraints needed: `class Stats<T extends num>`.
- Use `late` only when initialization is guaranteed before access.
- **Immutability**: `final` fields, `List.unmodifiable()`, defensive copies in getters, `copyWith()` for modifications.

## Widget Design
- **Composition over inheritance** — small focused widgets, not monolithic ones with 15 bool params.
- Use `const` constructors everywhere possible.
- Centralize design values in a tokens class (`AppTokens.spacing16`, `AppTokens.radiusMedium`).
- Integrate with `Theme.of(context)` for colors/styles.
- Accessibility: `Semantics` widget, min 48x48 touch targets.
- Split large `build()` methods into private sub-widgets (`_ProfileAvatar`, `_ProfileInfo`).

## Modern Dart 3.x

### Records — lightweight multiple returns
```dart
(bool success, String? error) validate(String input) { ... }
final (success, error) = validate(input);
```
Use records for simple bundling; classes for domain entities with behavior.

### Pattern Matching
```dart
String describe(Object obj) => switch (obj) {
  int n when n < 0 => 'negative',
  String s when s.isEmpty => 'empty string',
  _ => 'unknown',
};
```

### Sealed Classes — exhaustive type hierarchies
```dart
sealed class NetworkResult<T> {}
final class Success<T> extends NetworkResult<T> { final T data; Success(this.data); }
final class Loading<T> extends NetworkResult<T> {}
final class Error<T> extends NetworkResult<T> { final String message; Error(this.message); }
```
Compiler enforces all cases handled. Nest sealed classes for multi-level exhaustiveness.

### Class Modifiers
| Modifier    | Extend? | Implement? | Use Case              |
|-------------|---------|------------|-----------------------|
| `sealed`    | Same lib| No         | Exhaustive types      |
| `final`     | No      | No         | Stable implementations|
| `base`      | Yes     | No         | Require inheritance   |
| `interface` | No      | Yes        | Pure contracts        |
| `mixin`     | N/A     | Mixed in   | Reusable behavior     |

### Extension Types — zero-cost type wrappers
```dart
extension type UserId(String id) {}
extension type OrderId(String id) {}
void processOrder(OrderId orderId, UserId userId) { ... } // Can't swap at compile time
```

### Enhanced Enums
```dart
enum HttpMethod {
  get('GET', false), post('POST', true), put('PUT', true), delete('DELETE', false);
  final String value;
  final bool hasBody;
  const HttpMethod(this.value, this.hasBody);
}
```
Use enums for fixed sets with same shape; sealed classes when variants have different fields.

## Anti-Patterns to Avoid
1. **Boolean blindness** — `Future<bool> delete()` is ambiguous. Use enums: `DeleteResult { deleted, notFound, unauthorized }`.
2. **Stringly-typed APIs** — `setStatus('actve')` typo compiles. Use `UserStatus.active`.
3. **God objects** — Split `UserManager` into `AuthService`, `UserRepository`, `PermissionService`.
4. **Leaky abstractions** — Don't expose `getUserWithSqlQuery()`. Keep interfaces implementation-agnostic.
5. **Too many optional booleans** — Use config objects or composition instead.
6. **Callback hell** — Use `async/await`. Parallelize with `(futureA, futureB).wait`.
7. **Fighting null safety** — Don't scatter `!` assertions. Use `?.`, `??`, and `required`.
8. **String-based events** — Use typed streams (`Stream<TapEvent> get onTap`) not `addEventListener('tap', ...)`.
9. **Widget lifecycle bugs** — Check `mounted` after `await`. Cancel timers/subscriptions in `dispose()`.
10. **Mutable default args** — `tags = tags ?? []` can share instances. Use `List.of(tags ?? const [])`.

## Review Checklist

**Naming**: `UpperCamelCase` types, `lowerCamelCase` identifiers, `is/has/can/should` booleans, consistent verbs, no unnecessary abbreviations.

**Type Safety**: No `dynamic`, generics over casts, nullable only when truly optional, sealed classes for closed hierarchies, no stringly-typed APIs.

**API Usability**: Named params for config, sensible defaults, factory constructors for variants, `const` constructors, private by default.

**Error Handling**: Result types for expected failures, domain-specific exceptions, no silent failures, clear actionable messages.

**Widgets**: Composition over inheritance, small focused widgets, theme integration, `Semantics` + 48x48 touch targets, `const` where possible.

**Async/Lifecycle**: Controllers closed in `dispose()`, subscriptions cancelled in `dispose()`, timers cancelled in `dispose()`, `mounted` checked after `await`, stream errors handled.

**Modern Dart**: Records for multi-return, pattern matching for control flow, sealed classes for exhaustive hierarchies, appropriate class modifiers, extension types for zero-cost wrappers, enhanced enums over string constants.