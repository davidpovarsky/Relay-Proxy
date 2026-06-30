# Relay Proxy

Relay Proxy is a tiny iPad/iOS SwiftUI utility app for using Apple Shortcuts as an automation bridge.

The flow is:

```text
Source app / Safari / Scripting
  -> relay://run?input=...&x-success=...
  -> Relay Proxy opens and stores the payload instantly
  -> Relay Proxy immediately opens x-success and returns to the source app
  -> Personal Automation: When Relay Proxy is opened -> Run Shortcut
  -> Shortcut reads the payload using the app's App Intent
  -> Shortcut does its work
```

## What is included

- Custom URL schemes: `relay://` and `relayproxy://`
- Deep-link parser for `input`, `text`, `q`, `payload`, `payload_json`, and `payload_b64`
- Callback parser for `x-success`, `x_success`, `callback`, `return`, `return_url`
- Automatic callback return from inside the app
- Optional callback delay using `returnDelayMs`, `return_delay_ms`, `callbackDelayMs`, `callback_delay_ms`, or `delay_ms`
- App Intent: **Get Latest Relay Payload**
- App Intent: **Clear Relay Payloads**
- Local payload history, limited to 50 items
- GitHub Actions workflow for building an unsigned IPA and uploading build logs

## Example URLs

Simple input:

```text
relay://run?input=Hello
```

Input with callback:

```text
relay://run?input=Hello&x-success=sourceapp%3A%2F%2Fcallback
```

Input with callback and faster/slower return delay:

```text
relay://run?input=Hello&x-success=sourceapp%3A%2F%2Fcallback&returnDelayMs=250
```

Hebrew example:

```text
relay://run?input=%D7%A9%D7%9C%D7%95%D7%9D&x-success=scripting%3A%2F%2Fcallback
```

Base64URL payload:

```text
relay://run?payload_b64=eyJ0ZXh0IjoiSGVsbG8ifQ
```

Important: `x-success` must be percent-encoded if it contains `:`, `/`, `?`, `&`, or `=`.

## Shortcuts setup

1. Build and install the app on the iPad.
2. Open the app once so Shortcuts indexes the App Intents.
3. Open Shortcuts.
4. Go to **Automation**.
5. Create a personal automation:
   - Trigger: **App**
   - App: **Relay Proxy**
   - Event: **Is Opened**
   - Run: **Immediately**
   - Turn off notify/confirmation if iOS offers it.
6. Add the action from Relay Proxy:
   - **Get Latest Relay Payload**
   - Output Format: **JSON**
   - Consume Payload: **Yes**
   - Max Age Seconds: `20`
   - Wait Milliseconds: `1200`
7. Parse the returned JSON in Shortcuts.
8. Do your automation work.

The Shortcut does **not** need to open `payload.callbackURL`. Relay Proxy now handles the callback return itself.

Returned JSON shape:

```json
{
  "ok": true,
  "payload": {
    "id": "UUID",
    "input": "Hello",
    "callbackURL": "sourceapp://callback",
    "action": "run",
    "source": null,
    "rawURL": "relay://run?...",
    "parameters": {
      "input": "Hello",
      "x-success": "sourceapp://callback"
    },
    "timestamp": "2026-06-30T...Z",
    "consumedAt": null
  },
  "error": null
}
```

If no fresh payload is found:

```json
{
  "ok": false,
  "payload": null,
  "error": "No fresh unconsumed relay payload was found."
}
```

## Why the wait parameter exists

The app-open automation can sometimes begin almost at the same time as the app receives the deep link. The App Intent polls briefly so it can catch the new payload instead of accidentally reading too early.

## Callback delay

Relay Proxy returns to `x-success` automatically after saving the payload. The default delay is 250 ms.

You can override it with one of these parameters:

```text
returnDelayMs=0
returnDelayMs=250
returnDelayMs=1000
```

The accepted range is 0-5000 ms.

## Bundle ID

Default bundle ID:

```text
com.example.RelayProxy
```

Before installing on a real device, change it to your own unique bundle ID in Xcode:

```text
RelayProxy target -> Signing & Capabilities -> Bundle Identifier
```

You can also edit it directly in:

```text
RelayProxy.xcodeproj/project.pbxproj
```

Search for:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.example.RelayProxy;
```

## URL scheme

Default schemes are defined in `RelayProxy/Info.plist`:

```text
relay://
relayproxy://
```

You can rename them there if another app already uses `relay://`.

## GitHub Actions build

A workflow is included at:

```text
.github/workflows/ios-build.yml
```

It builds an unsigned device app, packages it as an IPA, and uploads build logs:

```text
RelayProxy-unsigned-ipa
RelayProxy-build-logs
```

For a real installable `.ipa`, you may need signing credentials or manual build/export from Xcode/Xcode Cloud.

## Limitations

- This does not run Apple Shortcuts silently from inside Swift. It uses a Shortcuts personal automation triggered by opening the app.
- iPadOS still has control over focus, Stage Manager and app switching behavior.
- Relay Proxy handles the callback return, not the Shortcut.
