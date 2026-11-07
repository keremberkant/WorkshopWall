# Security policy

## Supported versions

Only the [latest release](https://github.com/keremberkant/CanliDuvar/releases/latest) gets security fixes.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Report them privately through
[GitHub's private vulnerability reporting](https://github.com/keremberkant/CanliDuvar/security/advisories/new).

Useful details: the macOS version, the Canlı Duvar version, steps to reproduce, and, if it involves a wallpaper, a minimal example.

You should get a reply within a week. Once a fix is released, you'll be credited in the changelog unless you'd rather not be.

## Scope

Things we especially care about:

- A web wallpaper reading files outside its own folder, or escaping WebKit's sandbox
- Anything that could expose Steam credentials or the SteamCMD session
- Malicious `project.json` or Workshop content that makes the app run code or write outside the library
