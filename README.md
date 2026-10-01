# consultant-device-check-policy

`policy.json` sets which versions [Device Check](https://github.com/EqualExperts-Tech-Ops/consultant-device-check)
accepts. Every copy of the app fetches it at the start of each check, so changing it here
changes every device's next check, with no app release. It is data only: it can raise or
lower thresholds, never run code.

The app reads it from:

    https://raw.githubusercontent.com/EqualExperts-Tech-Ops/consultant-device-check-policy/main/policy.json

This repo is public so that the app can fetch it without signing in.

## Fields

| Field | Meaning |
| --- | --- |
| `version` | Format of this file. Must be `1`; the app ignores any other value. |
| `deviceCheckLatest` | The latest Device Check release, as `x.y.z`. Written by the release workflow in consultant-device-check, not by hand: an installed app older than this updates itself straight after its next check, instead of waiting for its six-hourly update check. |
| `gitMinimum` | Git older than this fails. A security floor, not "latest": raise it when Git ships a security release. On Linux, a distribution-packaged Git is judged by the package manager instead, because distributions backport fixes. |
| `dockerEngineMinimum` | Docker Engine (or the CLI, when the engine is not running) older than this fails. |
| `dotnetFrameworkMinimum` | Windows: .NET Framework older than this fails. |
| `visualCppFirstSupportedYear` | Windows: Visual C++ runtimes from before this year fail as end-of-life. |
| `windowsUpdateIgnore` | Windows: pending updates whose title contains any of these are not reported. Defender definitions are here because Defender installs them itself, several times a day. |

Every field is required. If the file is missing a field, has a malformed value, or cannot
be fetched, the app keeps using the last good copy it fetched, and before the first one, the
defaults built into it. A bad change therefore cannot loosen the checks; it is ignored.

## Changing it

Open a pull request. Say why in the description (for example the CVE a new minimum
fixes), because the history of this file is the record of what was required when.

`ci` rejects any file the app would ignore. To check a change locally (needs `jq`):

    bash scripts/validate-policy.sh
    bash scripts/validate-policy.test.sh
