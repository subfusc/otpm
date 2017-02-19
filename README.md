# otpm
A ruby library for storing OTP secrets

The goal of the project is be a high level library for managing and generating
OTP secrets. For version 1.0 atleas the following criteria should apply:

- Store secrets sufficently encrypted
- Ensure that corruption of the main file is not critical
- Generate tokes for use
- Give time for expiery of TOTP codes

Requirements:
 - Ruby >= 2.3
 - ROTP
 - OpenSSL
 - YAML