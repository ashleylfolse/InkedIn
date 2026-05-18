InkedIn TOTP Generator
======================

A command-line tool that generates Time-Based One Time Passwords (TOTP)
compatible with Google Authenticator, implementing the algorithm defined
in RFC 6238.

Requirements
------------
- Python 3.6+
- pip (Python package manager)

Setup
-----
Run the following to install dependencies and make the script executable:

    make

This installs the qrcode library (with Pillow for PNG output) and
sets the executable permission on the submission script.

Usage
-----

1. Generate a QR code:

    ./submission --generate-qr

   This creates a file called qrcode.png containing a QR code that
   Google Authenticator can scan. It also prints the secret key and
   the otpauth:// URI.

   Optional flags:
     --user USER       Set the account name (default: user@inkedin.com)
     --issuer ISSUER   Set the issuer name (default: InkedIn)
     --output FILE     Set output filename (default: qrcode.png)

2. Get the current OTP:

    ./submission --get-otp

   Prints the current 6-digit TOTP code. This code should match what
   Google Authenticator shows for the same 30-second window.

3. Continuous OTP mode:

    ./submission --get-otp --loop

   Prints the current OTP, waits until the 30-second window expires,
   then prints the next OTP. Repeats until interrupted with Ctrl+C.

How It Works
------------
The workflow is:

1. Run --generate-qr. This generates a random 160-bit secret (base32
   encoded) and saves it to .totp_secret. It builds an otpauth:// URI
   in the format Google Authenticator expects and encodes it as a QR
   code PNG image.

2. Scan the QR code with Google Authenticator on your phone.

3. Run --get-otp. This reads the same secret from .totp_secret and
   computes the TOTP using the current Unix time. The output should
   match what Google Authenticator displays.

Implementation Details
----------------------
The TOTP algorithm is implemented from scratch following RFC 6238:

1. The current Unix timestamp is divided by the period (30 seconds)
   to produce a time counter T.
2. T is encoded as an 8-byte big-endian integer.
3. HMAC-SHA1 is computed using the shared secret as the key and the
   counter bytes as the message.
4. Dynamic truncation extracts a 4-byte value from the HMAC output
   at an offset determined by the last nibble of the hash.
5. The truncated value is reduced modulo 10^6 to produce a 6-digit code.

The QR code encodes a URI in the format:
  otpauth://totp/InkedIn:user@inkedin.com?secret=...&issuer=InkedIn&algorithm=SHA1&digits=6&period=30

This follows the Google Authenticator Key URI format specification.

Libraries Used
--------------
- qrcode + Pillow: QR code generation and PNG image output
- hashlib, hmac, struct, base64, os, time: Python standard library
  modules used for the TOTP algorithm (no external TOTP library)

Assumptions
-----------
- The shared secret is stored in plaintext in .totp_secret in the same
  directory as the script. In a production system this would be stored
  securely, but for this assignment plaintext is acceptable.
- The system clock is reasonably accurate. TOTP relies on the client
  and server agreeing on the current time. If your system clock is
  significantly off, OTPs may not match.
- Default algorithm is SHA1, digits is 6, period is 30 seconds. These
  are the Google Authenticator defaults.
- Tested against Google Authenticator on Android. iOS should produce
  identical results.

Cleanup
-------
    make clean

Removes the generated QR code image and saved secret.
