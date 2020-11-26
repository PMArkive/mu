# quick-n-dirty way to print out floats

######## In hex, following C's %a format
# https://www.exploringbinary.com/hexadecimal-floating-point-constants

# examples:
#   0.5 = 0x3f000000 = 0011| 1111 | 0000 | 0000 | 0000 | 0000 | 0000 | 0000
#                    = 0 | 01111110 | 00000000000000000000000
#                      +   exponent   mantissa
#                    = 0 | 00000000000000000000000 | 01111110
#                          mantissa                  exponent
#                    = 0 | 000000000000000000000000 | 01111110
#                          zero-pad mantissa          exponent
#                   =   +1.000000                   P -01
fn test-print-float-normal {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var half/xmm0: float <- rational 1, 2
  print-float screen, half
  check-screen-row screen, 1, "1.000000P-01 ", "F - test-print-float-normal"
}

fn test-print-float-normal-2 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var quarter/xmm0: float <- rational 1, 4
  print-float screen, quarter
  check-screen-row screen, 1, "1.000000P-02 ", "F - test-print-float-normal-2"
}

fn test-print-float-normal-3 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var three-quarters/xmm0: float <- rational 3, 4
  print-float screen, three-quarters
  check-screen-row screen, 1, "1.800000P-01 ", "F - test-print-float-normal-3"
}

fn test-print-float-normal-4 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var tenth/xmm0: float <- rational 1, 0xa
  print-float screen, tenth
  check-screen-row screen, 1, "1.99999aP-04 ", "F - test-print-float-normal-4"
}

fn test-print-float-integer {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var one-f/xmm0: float <- rational 1, 1
  print-float screen, one-f
  check-screen-row screen, 1, "1.000000P00 ", "F - test-print-float-integer"
}

fn test-print-float-zero {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var zero: float
  print-float screen, zero
  check-screen-row screen, 1, "0 ", "F - test-print-float-zero"
}

fn test-print-float-negative-zero {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0x80000000
  var negative-zero/xmm0: float <- reinterpret n
  print-float screen, negative-zero
  check-screen-row screen, 1, "-0 ", "F - test-print-float-negative-zero"
}

fn test-print-float-infinity {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  #          0|11111111|00000000000000000000000
  #          0111|1111|1000|0000|0000|0000|0000|0000
  copy-to n, 0x7f800000
  var infinity/xmm0: float <- reinterpret n
  print-float screen, infinity
  check-screen-row screen, 1, "Inf ", "F - test-print-float-infinity"
}

fn test-print-float-negative-infinity {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0xff800000
  var negative-infinity/xmm0: float <- reinterpret n
  print-float screen, negative-infinity
  check-screen-row screen, 1, "-Inf ", "F - test-print-float-negative-infinity"
}

fn test-print-float-not-a-number {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0xffffffff  # exponent must be all 1's, and mantissa must be non-zero
  var negative-infinity/xmm0: float <- reinterpret n
  print-float screen, negative-infinity
  check-screen-row screen, 1, "NaN ", "F - test-print-float-not-a-number"
}

fn print-float screen: (addr screen), n: float {
  # - special names
  var bits/eax: int <- reinterpret n
  compare bits, 0
  {
    break-if-!=
    print-string screen, "0"
    return
  }
  compare bits, 0x80000000
  {
    break-if-!=
    print-string screen, "-0"
    return
  }
  compare bits, 0x7f800000
  {
    break-if-!=
    print-string screen, "Inf"
    return
  }
  compare bits, 0xff800000
  {
    break-if-!=
    print-string screen, "-Inf"
    return
  }
  var exponent/ecx: int <- copy bits
  exponent <- shift-right 0x17  # 23 bits of mantissa
  exponent <- and 0xff
  exponent <- subtract 0x7f
  compare exponent, 0x80
  {
    break-if-!=
    print-string screen, "NaN"
    return
  }
  # - regular numbers
  var sign/edx: int <- copy bits
  sign <- shift-right 0x1f
  {
    compare sign, 1
    break-if-!=
    print-string screen, "-"
  }
  $print-float:leading-digit: {
    # check for subnormal numbers
    compare exponent, -0x7f
    {
      break-if-!=
      print-string screen, "0."
      exponent <- increment
      break $print-float:leading-digit
    }
    # normal numbers
    print-string screen, "1."
  }
  var mantissa/ebx: int <- copy bits
  mantissa <- and 0x7fffff
  mantissa <- shift-left 1  # pad to whole nibbles
  print-int32-hex-bits screen, mantissa, 0x18
  # print exponent
  print-string screen, "P"
  compare exponent, 0
  {
    break-if->=
    print-string screen, "-"
  }
  var exp-magnitude/eax: int <- abs exponent
  print-int32-hex-bits screen, exp-magnitude, 8
}

#? fn main -> _/ebx: int {
#?   run-tests
#? #?   test-print-float-negative-zero
#? #?   print-int32-hex 0, 0
#? #?   test-print-float-normal
#?   return 0
#? }

######## In decimal
# Try to keep it short.

fn test-print-float-decimal-approximate-normal {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var half/xmm0: float <- rational 1, 2
  print-float-decimal-approximate screen, half
  check-screen-row screen, 1, "0.5 ", "F - test-print-float-decimal-approximate-normal"
}

fn test-print-float-decimal-approximate-normal-2 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var quarter/xmm0: float <- rational 1, 4
  print-float-decimal-approximate screen, quarter
  check-screen-row screen, 1, "0.25 ", "F - test-print-float-decimal-approximate-normal-2"
}

fn test-print-float-decimal-approximate-normal-3 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var three-quarters/xmm0: float <- rational 3, 4
  print-float-decimal-approximate screen, three-quarters
  check-screen-row screen, 1, "0.75 ", "F - test-print-float-decimal-approximate-normal-3"
}

# 3 decimal places = ok
fn test-print-float-decimal-approximate-normal-4 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var eighth/xmm0: float <- rational 1, 8
  print-float-decimal-approximate screen, eighth
  check-screen-row screen, 1, "0.125 ", "F - test-print-float-decimal-approximate-normal-4"
}

# Start truncating past 3 decimal places.
fn test-print-float-decimal-approximate-normal-5 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var sixteenth/xmm0: float <- rational 1, 0x10
  print-float-decimal-approximate screen, sixteenth
  check-screen-row screen, 1, "0.062 ", "F - test-print-float-decimal-approximate-normal-5"
}

# print whole integers without decimals
fn test-print-float-decimal-approximate-integer {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var one-f/xmm0: float <- rational 1, 1
  print-float-decimal-approximate screen, one-f
  check-screen-row screen, 1, "1 ", "F - test-print-float-decimal-approximate-integer"
}

fn test-print-float-decimal-approximate-integer-2 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var two-f/xmm0: float <- rational 2, 1
  print-float-decimal-approximate screen, two-f
  check-screen-row screen, 1, "2 ", "F - test-print-float-decimal-approximate-integer-2"
}

fn test-print-float-decimal-approximate-integer-3 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var ten/eax: int <- copy 0xa
  var ten-f/xmm0: float <- rational 0xa, 1
  print-float-decimal-approximate screen, ten-f
  check-screen-row screen, 1, "10 ", "F - test-print-float-decimal-approximate-integer-3"
}

fn test-print-float-decimal-approximate-integer-4 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var minus-ten-f/xmm0: float <- rational -0xa, 1
  print-float-decimal-approximate screen, minus-ten-f
  check-screen-row screen, 1, "-10 ", "F - test-print-float-decimal-approximate-integer-4"
}

fn test-print-float-decimal-approximate-integer-5 {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var hundred-thousand/eax: int <- copy 0x186a0
  var hundred-thousand-f/xmm0: float <- convert hundred-thousand
  print-float-decimal-approximate screen, hundred-thousand-f
  check-screen-row screen, 1, "100000 ", "F - test-print-float-decimal-approximate-integer-5"
}

fn test-print-float-decimal-approximate-zero {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var zero: float
  print-float-decimal-approximate screen, zero
  check-screen-row screen, 1, "0 ", "F - test-print-float-decimal-approximate-zero"
}

fn test-print-float-decimal-approximate-negative-zero {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0x80000000
  var negative-zero/xmm0: float <- reinterpret n
  print-float-decimal-approximate screen, negative-zero
  check-screen-row screen, 1, "-0 ", "F - test-print-float-decimal-approximate-negative-zero"
}

fn test-print-float-decimal-approximate-infinity {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  #          0|11111111|00000000000000000000000
  #          0111|1111|1000|0000|0000|0000|0000|0000
  copy-to n, 0x7f800000
  var infinity/xmm0: float <- reinterpret n
  print-float-decimal-approximate screen, infinity
  check-screen-row screen, 1, "Inf ", "F - test-print-float-decimal-approximate-infinity"
}

fn test-print-float-decimal-approximate-negative-infinity {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0xff800000
  var negative-infinity/xmm0: float <- reinterpret n
  print-float-decimal-approximate screen, negative-infinity
  check-screen-row screen, 1, "-Inf ", "F - test-print-float-decimal-approximate-negative-infinity"
}

fn test-print-float-decimal-approximate-not-a-number {
  var screen-on-stack: screen
  var screen/esi: (addr screen) <- address screen-on-stack
  initialize-screen screen, 5, 0x20  # 32 columns should be more than enough
  var n: int
  copy-to n, 0xffffffff  # exponent must be all 1's, and mantissa must be non-zero
  var negative-infinity/xmm0: float <- reinterpret n
  print-float-decimal-approximate screen, negative-infinity
  check-screen-row screen, 1, "NaN ", "F - test-print-float-decimal-approximate-not-a-number"
}

fn print-float-decimal-approximate screen: (addr screen), n: float {
  # - special names
  var bits/eax: int <- reinterpret n
  compare bits, 0
  {
    break-if-!=
    print-string screen, "0"
    return
  }
  compare bits, 0x80000000
  {
    break-if-!=
    print-string screen, "-0"
    return
  }
  compare bits, 0x7f800000
  {
    break-if-!=
    print-string screen, "Inf"
    return
  }
  compare bits, 0xff800000
  {
    break-if-!=
    print-string screen, "-Inf"
    return
  }
  var exponent/ecx: int <- copy bits
  exponent <- shift-right 0x17  # 23 bits of mantissa
  exponent <- and 0xff
#?   print-string 0, "exponent0: "
#?   print-int32-hex 0, exponent
#?   print-string 0, "\n"
  exponent <- subtract 0x7f
  compare exponent, 0x80
  {
    break-if-!=
    print-string screen, "NaN"
    return
  }
  # - regular numbers
  var sign/edx: int <- copy bits
  sign <- shift-right 0x1f
  {
    compare sign, 1
    break-if-!=
    print-string screen, "-"
  }
  var mantissa/ebx: int <- copy bits
  mantissa <- and 0x7fffff
#?   print-string 0, "mantissa0: "
#?   print-int32-hex 0, mantissa
#?   print-string 0, "\n"
  # whole integers
  compare exponent, 0
  {
    break-if-<
#?     print-string 0, "mantissa: "
#?     print-int32-hex 0, mantissa
#?     print-string 0, "\n"
#?     print-string 0, "exponent: "
#?     print-int32-hex 0, exponent
#?     print-string 0, "\n"
    var tmp/eax: int <- copy mantissa
    tmp <- shift-left 9  # move to MSB
    tmp <- repeated-shift-left tmp, exponent
    compare tmp, 0
    break-if-!=
    var result/eax: int <- copy mantissa
    result <- or 0x00800000  # insert implicit 1
#?     print-string 0, "mantissa2: "
#?     print-int32-hex 0, result
#?     print-string 0, "\n"
    var all-but-exponent/edx: int <- copy 0x17  # 23 bits for mantissa treated as a whole number
    all-but-exponent <- subtract exponent
    result <- repeated-shift-right result, all-but-exponent
#?     print-string 0, "result: "
#?     print-int32-hex 0, result
#?     print-string 0, "\n"
    print-int32-decimal screen, result
    return
  }
  $print-float-decimal-approximate:leading-digit: {
    # check for subnormal numbers
    compare exponent, -0x7f
    {
      break-if-!=
      print-string screen, "0"
      exponent <- increment
      break $print-float-decimal-approximate:leading-digit
    }
    # normal numbers
    print-string screen, "1"
  }
  var mantissa/ebx: int <- copy bits
  mantissa <- and 0x7fffff
  compare mantissa, 0
  {
    break-if-=
    print-string screen, "."
    # TODO
    mantissa <- shift-left 1  # whole number of nibbles
    print-int32-hex-bits screen, mantissa, 0x18
  }
  # print exponent if necessary
  compare exponent, 0
  break-if-=
  print-string screen, "P"
  print-int32-decimal screen, exponent
}

#? fn main -> _/ebx: int {
#? #?   run-tests
#?   test-print-float-decimal-approximate-integer-5
#?   return 0
#? }
