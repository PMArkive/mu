fn main args-on-stack: (addr array addr array byte) -> _/ebx: int {
  var args/eax: (addr array addr array byte) <- copy args-on-stack
  var len/ecx: int <- length args
  compare len, 2
  {
    break-if-!=
    # if single arg is 'test', run tests
    var tmp/ecx: (addr addr array byte) <- index args, 1
    var tmp2/eax: boolean <- string-equal? *tmp, "test"
    compare tmp2, 0  # false
    {
      break-if-=
      run-tests
      return 0  # TODO: get at Num-test-failures somehow
    }
    # if single arg is 'screen', run in full-screen mode
    tmp2 <- string-equal? *tmp, "screen"
    compare tmp2, 0  # false
    {
      break-if-=
      interactive
      return 0
    }
    # if single arg is 'type', run in typewriter mode
    tmp2 <- string-equal? *tmp, "type"
    compare tmp2, 0  # false
    {
      break-if-=
      repl
      return 0
    }
    # if single arg is 'test' ...
    tmp2 <- string-equal? *tmp, "test2"
    compare tmp2, 0  # false
    {
      break-if-=
      test
      return 0
    }
  }
  # otherwise error message
  print-string-to-real-screen "usage:\n"
  print-string-to-real-screen "  to run tests: tile test\n"
  print-string-to-real-screen "  full-screen mode: tile screen\n"
  print-string-to-real-screen "  regular REPL: tile type\n"
  return 1
}

fn interactive {
  enable-screen-grid-mode
  enable-keyboard-immediate-mode
  var env-storage: environment
  var env/esi: (addr environment) <- address env-storage
  initialize-environment env
  draw-screen env
  {
    var key/eax: grapheme <- read-key-from-real-keyboard
    compare key, 0x11  # 'ctrl-q'
    break-if-=
    process env, key
    render env
    loop
  }
  enable-keyboard-type-mode
  enable-screen-type-mode
}

fn test {
  var env-storage: environment
  var env/esi: (addr environment) <- address env-storage
  initialize-environment-with-fake-screen env, 0x20, 0xa0
  process-all env, "3 3 fake-screen =s"
  process env, 0xc  # ctrl-l
  process-all env, "s 1 down "
  render env
#?   var fake-screen-ah/eax: (addr handle screen) <- get env, screen
#?   var fake-screen/eax: (addr screen) <- lookup *fake-screen-ah
#?   render-screen 0, 1, 1, fake-screen
}

fn process-all env: (addr environment), cmds: (addr array byte) {
  var cmds-stream: (stream byte 0x100)
  var cmds-stream-a/esi: (addr stream byte) <- address cmds-stream
  write cmds-stream-a, cmds
  {
    var done?/eax: boolean <- stream-empty? cmds-stream-a
    compare done?, 0  # false
    break-if-!=
    var g/eax: grapheme <- read-grapheme cmds-stream-a
    process env, g
    loop
  }
}

fn repl {
  {
    # prompt
    print-string-to-real-screen "> "
    # read
    var line-storage: (stream byte 0x100)
    var line/ecx: (addr stream byte) <- address line-storage
    clear-stream line
    read-line-from-real-keyboard line
    var done?/eax: boolean <- stream-empty? line
    compare done?, 0  # false
    break-if-!=
    # parse
    var env-storage: environment
    var env/esi: (addr environment) <- address env-storage
    initialize-environment env
    {
      var done?/eax: boolean <- stream-empty? line
      compare done?, 0  # false
      break-if-!=
      var g/eax: grapheme <- read-grapheme line
      process env, g
      loop
    }
    # eval
    var stack-storage: value-stack
    var stack/edi: (addr value-stack) <- address stack-storage
    initialize-value-stack stack, 0x10
    evaluate-environment env, stack
    # print
    var empty?/eax: boolean <- value-stack-empty? stack
    {
      compare empty?, 0  # false
      break-if-!=
      var result/eax: int <- pop-int-from-value-stack stack
      print-int32-decimal-to-real-screen result
      print-string-to-real-screen "\n"
    }
    #
    loop
  }
}
