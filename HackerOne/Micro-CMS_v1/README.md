# Micro-CMS v1

## Overview

This directory contains the local materials and manual walkthrough for the `Micro-CMS v1` challenge from `Hacker101 / HackerOne CTF`. This level is useful because it is not built around one bug. It is built around a cluster of trust and validation failures in the same small application.

This folder documents four distinct flag paths, each revealing a different class of web weakness: predictable identifiers, route tampering, inconsistent escaping, and weak HTML sanitization.

## Challenge Profile

- Challenge: `Micro-CMS v1`
- Category: `Web`
- Collection: `HackerOne`
- Event or Platform: `Hacker101 / HackerOne CTF`

## Directory Contents

- `micro_cms_v1_poc.sh`

## First Commands To Run

This folder does not include original challenge files. Follow the walkthrough the same way you would read a public writeup: understand the target behavior first, then reproduce each manual step against a fresh instance until the flag is visible.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_v1"
ls -lah
printf 'Follow the manual walkthrough below against the live service.\n'
```

## Writeup Flow

This README follows a public-writeup style structure: start from the provided files or exposed service, confirm the key weakness or clue with manual commands, use that confirmed finding to move forward, and stop only when the final flag or recovered result is visible.

When you work through it, keep asking four questions:

1. What is the challenge giving me locally or remotely?
2. What exact behavior, bug, artifact, or hidden assumption matters?
3. How do I verify that with a command or inspection step?
4. How does that verified result lead to the final flag?

## Why This Level Is Good Practice

This challenge is a compact demonstration of how a single application can fail in several independent ways at once. That makes it closer to real-world testing than a toy challenge with only one clean bug.

The four paths are:

1. predictable identifiers expose a hidden page
2. malformed path input breaks backend assumptions
3. a title is escaped in one view but rendered unsafely in another
4. body HTML survives weak sanitization

The key lesson is that security consistency matters. A defense that works in one route, one page, or one rendering context is not enough if sibling paths are weaker.

## Flag 0: Hidden Page Through Predictable IDs

Creating a new page reveals that page identifiers follow a sequence. Once that is clear, earlier IDs can be probed even if they are not linked publicly.

In this instance:

- `/page/7` returned a protected response
- `/page/edit/7` exposed the private page content in the edit form

That is an access-control failure combined with guessable object references.

## Flag 1: Path Tampering

The application assumes the page ID path segment is always a normal integer. Appending a quote to the route:

```text
/page/edit/1'
```

breaks that assumption and causes the backend to leak a flag directly.

This is a reminder that URLs and route segments are still attacker-controlled input. Form fields are not the only place input validation matters.

## Flag 2: Title Escaping Is Inconsistent

A malicious title is rendered safely on the page view itself, but not on the homepage listing. That means the same user-controlled field is treated differently in different contexts.

This is one of the most common real XSS patterns: developers sanitize or escape in the “obvious” view but forget that the same field appears elsewhere in a different rendering context.

In this level, the homepage becomes the vulnerable surface.

## Flag 3: Weak Body Sanitization

The body renderer strips or rewrites some obvious script-related patterns, but dangerous HTML such as:

```html
<img src=x onerror=alert(1)>
```

still survives. The application then embeds the flag in an attribute on the surviving element, so the response itself leaks the token without requiring an actual browser popup or admin interaction.

That is a classic example of blacklist-based sanitization failing against the broader HTML attack surface.

## Manual Reproduction Flow

Use the walkthrough above as the authoritative solve path. The short command block below is only the setup phase before you execute the numbered manual steps in this README.

```bash
cd "/home/eliah/Desktop/CTF/HackerOne/Micro-CMS_v1"
ls -lah
```

## Final Flags

Following the manual path in this README leads to these recovered flags:

- `^FLAG^481befa1cf2357f7f6ea22d5e74ca15b12b3714b7d0dacafdb88d8211e23347e$FLAG$`
- `^FLAG^9ed632e91db3e8c2700cff8ca565e6341f4e10864a8cbd00b9d3fb1bce424520$FLAG$`
- `^FLAG^680c70842ddaf2233afb0dceb895b8c37d25bc04a764dd497aa94dd766adade2$FLAG$`
- `^FLAG^b688020e0f646d6a20457df946434b395d1ac1f9b60b21ea582e5a075cc2b2f6$FLAG$`

## Study Notes

This is one of the better folders in the archive for studying web testing mindset. It rewards thinking broadly about:

- object references
- path handling
- rendering context
- HTML sanitization

It is worth revisiting because it shows how several “small” trust mistakes can coexist in one app and each become a valid attack path.
