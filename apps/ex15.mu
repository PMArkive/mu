# Demo of combining-character support in Mu, which can be summarized as, "the
# old typewriter-based approach of backing up one character and adding the
# accent or _matra_ in."
#   https://en.wikipedia.org/wiki/Combining_character
#
# Mu uses this approach for both accents in Latin languages and vowel
# diacritics in Abugida scripts.
#   https://en.wikipedia.org/wiki/Diacritic
#   https://en.wikipedia.org/wiki/Abugida
#
# Steps for trying it out:
#   1. Translate this example into a disk image code.img.
#       ./translate apps/ex15.mu
#   2. Run:
#       qemu-system-i386 -hda code.img -hdb data.img
#
# Expected output:
#   'à' in green in a few places near the top-left corner of screen, showing off
#   what this approach can and cannot do.
#
#   A few Devanagari letter combinations.
#
#   Others? (Patches welcome.) I suspect Tibetan in particular will not work
#   well with this approach. But I need native readers to assess quality.

fn main screen: (addr screen), keyboard: (addr keyboard), data-disk: (addr disk) {
  # at the top of screen, the accent is almost cropped
  var dummy/eax: int <-    draw-code-point-on-real-screen   0x61/a,                       0/x 0/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0300/combining-grave-accent,  0/x 0/y, 3/fg 0/bg

  # below a grapheme with a descender, the accent uglily overlaps
  #   https://en.wikipedia.org/wiki/Descender
  var dummy/eax: int <-    draw-code-point-on-real-screen   0x67/g,                       4/x 3/y, 3/fg 0/bg
  var dummy/eax: int <-    draw-code-point-on-real-screen   0x61/a,                       4/x 4/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0300/combining-grave-accent,  4/x 4/y, 3/fg 0/bg

  # beside a grapheme with a descender, it becomes more obvious that monowidth fonts can't make baselines line up
  #   https://en.wikipedia.org/wiki/Baseline_(typography)
  var dummy/eax: int <-    draw-code-point-on-real-screen   0x67/g,                       8/x 3/y, 3/fg 0/bg
  var dummy/eax: int <-    draw-code-point-on-real-screen   0x61/a,                       9/x 3/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0300/combining-grave-accent,  9/x 3/y, 3/fg 0/bg

  # a single devanagari letter combined with different vowel _matras_
  # ka
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 4/x 8/y, 3/fg 0/bg
  # kaa
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 7/x 8/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x093e/devanagari-vowel-aa, 7/x 8/y, 3/fg 0/bg
  # ki
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0xa/x 8/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x093f/devanagari-vowel-i, 0xa/x 8/y, 3/fg 0/bg
  # kee
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0xd/x 8/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0940/devanagari-vowel-ii, 0xd/x 8/y, 3/fg 0/bg
  # ku
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0x10/x 8/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0941/devanagari-vowel-u, 0x10/x 8/y, 3/fg 0/bg
  # koo
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0x13/x 8/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0942/devanagari-vowel-oo, 0x13/x 8/y, 3/fg 0/bg
  # kay
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 4/x 9/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0947/devanagari-vowel-E, 4/x 9/y, 3/fg 0/bg
  # kai
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 7/x 9/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0948/devanagari-vowel-ai, 7/x 9/y, 3/fg 0/bg
  # ko
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0xa/x 9/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x094b/devanagari-vowel-o, 0xa/x 9/y, 3/fg 0/bg
  # kow
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0xd/x 9/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x094f/devanagari-vowel-aw, 0xd/x 9/y, 3/fg 0/bg
  # kan
  # bump this letter down to show the letter without overlap; we've already established above that overlap is an issue
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0x10/x 0xa/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0902/devanagari-anusvara, 0x10/x 0xa/y, 3/fg 0/bg
  # kaha
  var dummy/eax: int <- draw-code-point-on-real-screen 0x0915/devanagari-letter-ka, 0x13/x 9/y, 3/fg 0/bg
  var dummy/eax: int <- overlay-code-point-on-real-screen 0x0903/devanagari-visarga, 0x13/x 9/y, 3/fg 0/bg
}
