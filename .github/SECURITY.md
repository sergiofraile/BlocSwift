# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | ✅        |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability, please report it privately via [GitHub's private vulnerability reporting](https://github.com/sergiofraile/BlocSwift/security/advisories/new).

Include as much detail as possible:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix, if you have one

You can expect an acknowledgement within 72 hours and a resolution or status update within 14 days.

## Scope

This library is a client-side state management framework with no network communication of its own. Security considerations are most relevant to:

- State serialization/deserialization in `HydratedBloc` (data written to and read from persistent storage)
- Dependencies introduced by the library consumer (Alamofire, etc. are not part of this library)
