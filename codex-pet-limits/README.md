# Codex Pet Limits Overlay

A tiny macOS overlay that anchors to the Codex desktop pet and shows the current Codex usage remaining as a compact status capsule.

It follows the pet position, reads Codex rate limits locally, and updates the visual state without modifying Codex.app.

## What It Reads

- `~/.codex/.codex-global-state.json` for the current pet position
- `codex app-server --stdio` with `account/rateLimits/read` for Codex rate limits

## Status Mapping

- 60-100% remaining: `满电`
- 30-59% remaining: `稳定`
- 10-29% remaining: `省用`
- 1-9% remaining: `低电`
- 0% or rate limit reached: `休息`

## Install

```sh
cd codex-pet-limits
./build.sh
./start-overlay.sh
```

## Stop

```sh
./stop-overlay.sh
```

## Launch At Login

```sh
./install-launch-agent.sh
```

## Notes

The overlay refreshes position every 0.2 seconds and refreshes Codex usage every 60 seconds. It is intentionally small so it does not cover the Codex conversation list.
