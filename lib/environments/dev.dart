import 'package:essentiel/env.dart';

void main() {
  Dev().init();
}

class Dev extends Env {
  final String saEmail = "my-sa@my-dcp-project.iam.gserviceaccount.com";
  final String saId = "12345678901234567890";
  // Fake key
  final String saPK = r'''-----BEGIN RSA PRIVATE KEY-----
MIICXwIBAAKBgQCK1n1lX8gx3U73uZgprPfIwaHk9iFDNfXVl6RYsyaHp5P1ODcL
M5xS35XaugiFzPezPQm3BfsCuZoZlw1hYq5/i0pfpKiDrkWkk3SKX4SEcqs6ZEaI
TwX/LPMCiCaA3XYixN4y7u3H+GMzsj53XkyJ57URsdQQ2cpqgAT+hQWPmwIDAQAB
AoGBAIlN2FNiJ01RLaCGVnqYybAr9tzFoV2jxsyGnIzwF6G+0++GucEFOIso/T2E
D5ureigzrCDp9DTcsw6tuRjfi+uvjwAXPJlirmoAK88lsfq4W7OqeX8IutzRQYL/
8Jh/bEumpMFA8pDPEgc19HecfTmHdnIvO9Ik8XQH+INxM2MhAkEA6eYwCWiDCRG3
FkV74QfNEIWnWAAKW0I34i94MNeeEOZWl204g+3k48y+y/fY6KCJDhb1Ta0LNkGb
TtDMW1wfawJBAJf02oe9NaKTtlLMivN5/kcHkUcZdkTW2p457W+5Pr42etnRZteC
hkXXufRRmejdf53ynWbTkZH3mRwJ4DqMTJECQQDXWeyYfPVIgFsF0mvAQKJ5t9Tf
nQnsBAfX5MTQk3UhMjI/sXv7XCkF5Bk3SrcXV9dYdaLdJZnRFo6b/nppE2SJAkEA
iwhKJiYVe+IA0LM7c1gsMlsXLmF6l7OppVnFCBMK+EiqkL8KhKZ1KlQeXQ+Ibcqz
6BVCtQFg0Jgla8URdyBFMQJBALuc5P/eUS/mZyN9bize7NNtEj6PsbAi6oSpWtqT
/fzQarIEUO3Bqr7QMBCqxiPPuI6aSgCZDtri2xEqoG0tty8=
-----END RSA PRIVATE KEY-----
''';
}
