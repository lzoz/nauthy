import sequtils, sugar, strutils, random
include "nauthy/utils"
import nauthy

proc testHotpValidRFC() =
  ## Test HOTP implementation using the valid test values provided in RFC4226.
  
  # Test by initializing a Hotp with a string.
  let secretStr: string = "12345678901234567890"
  let hotp = initHotp(secretStr)
  let correctValues = ["755224", "287082", "359152", "969429", "338314",
             "254676", "287922", "162583", "399871", "520489"]
  for i in 0..9:
    let counter = (uint64)(i)
    let correct = correctValues[i]
    let value = hotp.at(counter)
    let errMsg = "Test for Hotp.at($1) failed; result = $2, correct_value = $3" % [$counter, $value, $correct]
    doAssert value == correct, errMsg

  # Test by initializing a Hotp with a sequence of bytes.
  let secretBytes: Bytes = "12345678901234567890".map(c => (byte)(c))
  let hotp2 = initHotp(secretBytes)
  for i in 0..9:
    let counter = (uint64)(i)
    let correct = correctValues[i]
    let value = hotp2.at(counter)
    let errMsg = "Test for Hotp.at($1) failed; result = $2, correct_value = $3" % [$counter, $value, $correct]
    doAssert value == correct, errMsg
  
  # Test by initializing a Hotp with a base32 encoded string.
  let secretStrEncoded: string = base32Encode("12345678901234567890")
  let hotp3 = initHotp(secretStrEncoded, true)
  for i in 0..9:
    let counter = (uint64)(i)
    let correct = correctValues[i]
    let value = hotp3.at(counter)
    let errMsg = "Test for Hotp.at($1) failed; result = $2, correct_value = $3" % [$counter, $value, $correct]
    doAssert value == correct, errMsg
  
  # Test by initializing a Hotp with a sequence of bytes that is base32 encoded.
  let secretBytesEncoded: Bytes = secretStrEncoded.map(c => byte(c))
  let hotp4 = initHotp(secretBytesEncoded, true)
  for i in 0..9:
    let counter = (uint64)(i)
    let correct = correctValues[i]
    let value = hotp4.at(counter)
    let errMsg = "Test for Hotp.at($1) failed; result = $2, correct_value = $3" % [$counter, $value, $correct]
    doAssert value == correct, errMsg

proc testTotpValidRFC() =
  ## Test TOTP implementation using the valid test values provided in RFC6238.
  
  # Test by initializing a Totp with a sequence of bytes.
  let secretSha1: Bytes = cast[Bytes]("12345678901234567890")
  let secretSha256: Bytes = cast[Bytes]("12345678901234567890123456789012")
  let secretSha512: Bytes = cast[Bytes]("1234567890123456789012345678901234567890123456789012345678901234")
  let correctValues = [(59'u64, "94287082", "46119246", "90693936"),
             (1111111109'u64, "07081804", "68084774", "25091201"),
             (1111111111'u64, "14050471", "67062674", "99943326"),
             (1234567890'u64, "89005924", "91819424", "93441116"),
             (2000000000'u64, "69279037", "90698825", "38618901"),
             (20000000000'u64, "65353130", "77737706", "47863826")]
  for (time, correctSha1, correctSha256, correctSha512) in correctValues:
    let totpSha1 = initTotp(secretSha1, false, 8, hashFunc=sha1Hash)
    doAssert totpSha1.at(time) == correctSha1
    let totpSha256 = initTotp(secretSha256, false, 8, hashFunc=sha256Hash)
    doAssert totpSha256.at(time) == correctSha256
    let totpSha512 = initTotp(secretSha512, false, 8, hashFunc=sha512Hash)
    doAssert totpSha512.at(time) == correctSha512

  # Test by initializing a Totp with a string.
  let secretStr = "12345678901234567890"
  let totp2 = initTotp(secretStr, false, 8)
  for (time, correct, _, _) in correctValues:
    let value = totp2.at(time)
    doAssert value == correct, "Test for Totp.at() failed; result = $1, correct_value = $2" % [$value, $correct]

  # Test by initializing a Totp with a base32 encoded string.
  let secretStrEncoded = base32Encode("12345678901234567890")
  let totp3 = initTotp(key=secretStrEncoded, length=8)
  for (time, correct, _, _) in correctValues:
    let value = totp3.at(time)
    doAssert value == correct, "Test for Totp.at() failed; result = $1, correct_value = $2" % [$value, $correct]

  # Test by initializing a Totp with a base32 encoded sequence of bytes.
  let secretBytesEncoded: Bytes = base32Encode("12345678901234567890").map(c => byte(c))
  let totp4 = initTotp(key=secretBytesEncoded, length=8)
  for (time, correct, _, _) in correctValues:
    let value = totp4.at(time)
    doAssert value == correct, "Test for Totp.at() failed; result = $1, correct_value = $2" % [$value, $correct]

proc testHotpInvalid() =
  let hotp = initHotp("1234567890")
  doAssertRaises(AssertionDefect):
    discard hotp.at(-1)

proc testHotpVerify() =
  let hotp = initHotp("12345678901234567890")
  let correctValues = ["755224", "287082", "359152", "969429", "338314",
             "254676", "287922", "162583", "399871", "520489"]
  for i in 0..9:
    doAssert hotp.verify(correctValues[i], i)
    randomize()
    var r = $rand(999999)
    while r == correctValues[i]: r = $rand(999999)
    doAssert not hotp.verify(r, i)

proc testTotpVerify() =
  let totp = initTotp(key="12345678901234567890".base32Encode, length=8)
  let correctValues = [(59'u64, "94287082"), (1111111109'u64, "07081804"), (1111111111'u64, "14050471"),
             (1234567890'u64, "89005924"), (2000000000'u64, "69279037"), (20000000000'u64, "65353130")]
  for (time, correct) in correctValues:
    doAssert totp.verify(correct, time)
    randomize()
    var r = $rand(99999999)
    while r == correct: r = $rand(99999999)
    doAssert not totp.verify(r, time)

proc testRandomBase32() =
  let r1 = randomBase32()
  let r2 = randomBase32()

  doAssert r1.len == 16 and r2.len == 16, "randomBase32() generates Base32 encoded string of incorrect length"
  for i in r1.low..r1.high:
    doAssert r1[i] in b32Table, "randomBase32() generates invalid string"
    doAssert r2[i] in b32Table, "randomBase32() generates invalid string"

  doAssert r1 != r2, "randomBase32() might be producing the same string every time"

proc testOtpFromUri() =
  block:
    let otp = otpFromUri("otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30")
    doAssert otp.otpType == TotpT
    doAssert otp.totp.uri.getIssuer == "ACME%20Co"
    doAssert otp.totp.uri.getName == "john.doe%40email.com"
    doAssert otp.totp.key.base32Encode(ignorePadding=true) == "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    doAssert otp.totp.length == (OtpValueLen)(6)
    doAssert otp.totp.interval == (TimeInterval)(30)
    doAssert otp.totp.hashFunc.name == $SHA1
  block:
    let otp = otpFromUri("otpauth://totp/Big%20Corporation%3A%20alice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA256&digits=8&period=60")
    doAssert otp.otpType == TotpT
    doAssert otp.totp.uri.getIssuer == "Big%20Corporation"
    doAssert otp.totp.uri.getName == "alice%40bigco.com"
    doAssert otp.totp.key.base32Encode(ignorePadding=true) == "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    doAssert otp.totp.length == (OtpValueLen)(8)
    doAssert otp.totp.interval == (TimeInterval)(60)
    doAssert otp.totp.hashFunc.name == $SHA256
  block:
    let otp = otpFromUri("otpauth://totp/Big%20Corporation%3A%20alice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA512")
    doAssert otp.otpType == TotpT
    doAssert otp.totp.uri.getIssuer == "Big%20Corporation"
    doAssert otp.totp.uri.getName == "alice%40bigco.com"
    doAssert otp.totp.key.base32Encode(ignorePadding=true) == "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    doAssert otp.totp.length == (OtpValueLen)(6)
    doAssert otp.totp.interval == (TimeInterval)(30)
    doAssert otp.totp.hashFunc.name == $SHA512
  block:
    let otp = otpFromUri("otpauth://totp/Example:alice@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Example&algorithm=SHA1")
    doAssert otp.otpType == TotpT
    doAssert otp.totp.uri.getIssuer == "Example"
    doAssert otp.totp.uri.getName == "alice%40gmail.com"
    doAssert otp.totp.key.base32Encode(ignorePadding=true) == "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    doAssert otp.totp.length == (OtpValueLen)(6)
    doAssert otp.totp.interval == (TimeInterval)(30)
  block:
    doAssertRaises(KeyError):
      discard otpFromUri("otpauth://totp/alice@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&algorithm=SHA1&digits=8&period=60")
  block:
    let otp = otpFromUri("otpauth://hotp/Big%20Corporation%3A%20alice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA1&digits=8&period=60&counter=7")
    doAssert otp.otpType == HotpT
    doAssert otp.hotp.uri.getIssuer == "Big%20Corporation"
    doAssert otp.hotp.uri.getName == "alice%40bigco.com"
    doAssert otp.hotp.key.base32Encode(ignorePadding=true) == "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    doAssert otp.hotp.length == (OtpValueLen)(8)
    doAssert otp.hotp.initialCounter == 7
  block:
    doAssertRaises(KeyError):
      discard otpFromUri("otpauth://hotp/Big%20Corporation%3A%20alice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA1&digits=8&period=60")

proc testBuildUri() =
  block:
    var hotp = initHotp("12345678901234567890")
    doAssertRaises(AssertionDefect):
      discard hotp.buildUri()
  block:
    var hotp = initHotp("12345678901234567890")
    let uri = newUri("Example issuer", "foo@example.com")
    hotp.uri = uri
    doAssert hotp.buildUri() == "otpauth://hotp/Example%20issuer%3Afoo%40example.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example%20issuer&algorithm=SHA1&digits=6&counter=0"
  block:
    let uri = "otpauth://hotp/Big%20Corporation%3Aalice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA1&digits=8&counter=7"
    var hotp = otpFromUri(uri).hotp
    doAssert hotp.buildUri() ==  uri
  block:
    let uri = "otpauth://hotp/Big%20Corporation%3Aalice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA256&digits=8&counter=7"
    var hotp = otpFromUri(uri).hotp
    doAssert hotp.buildUri() ==  uri
  block:
    let uri = "otpauth://hotp/Big%20Corporation%3Aalice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA512&digits=8&counter=7"
    var hotp = otpFromUri(uri).hotp
    doAssert hotp.buildUri() ==  uri
  block:
    let totp = initTotp("12345678901234567890", b32Decode=false)
    doAssertRaises(AssertionDefect):
      discard totp.buildUri()
  block:
    var totp = initTotp("12345678901234567890", b32Decode=false)
    let uri = newUri("Example issuer", "foo@example.com")
    totp.uri = uri
    doAssert totp.buildUri() == "otpauth://totp/Example%20issuer%3Afoo%40example.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example%20issuer&algorithm=SHA1&digits=6&period=30"
  block:
    let uri = "otpauth://totp/Big%20Corporation%3Aalice%40bigco.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=Big%20Corporation&algorithm=SHA1&digits=8&period=60"
    let totp = otpFromUri(uri).totp
    doAssert totp.buildUri() == uri

testHotpValidRFC()
testTotpValidRFC()
testHotpInvalid()
testHotpVerify()
testTotpVerify()
testRandomBase32()
testOtpFromUri()
testBuildUri()
