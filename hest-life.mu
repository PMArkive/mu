# Conway's Game of Life in a Hestified way
#   https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
#   https://ivanish.ca/hest-podcast
#
# To build:
#   $ ./translate life.mu
# I run it on my 2.5GHz Linux laptop like this:
#   $ qemu-system-i386 -enable-kvm code.img
#
# If things seem too fast or too slow on your computer, adjust the loop bounds
# in the function `pause` at the bottom. Its value will depend on how you
# accelerate Qemu. Mu will eventually get a clock to obviate the need for this
# tuning.

fn main screen: (addr screen), keyboard: (addr keyboard), data-disk: (addr disk) {
  var env-storage: environment
  var env/esi: (addr environment) <- address env-storage
  initialize-environment env
  {
    render screen, env
    pause env
    edit keyboard, env
    step env
    loop
  }
}

type environment {
  data: (handle array handle array boolean)
  zoom: int  # 0 = 1024 px per cell; 5 = 4px per cell; each step adjusts by a factor of 4
  tick: int
}

fn render screen: (addr screen), _self: (addr environment) {
  clear-screen screen
  var self/esi: (addr environment) <- copy _self
  var zoom/eax: (addr int) <- get self, zoom
  compare *zoom, 0
  {
    break-if-!=
    render0 screen, self
    return
  }
  compare *zoom, 4
  {
    break-if-!=
    render4 screen, self
    return
  }
}

fn render0 screen: (addr screen), _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  # cell border
  draw-vertical-line   screen,  0xc0/x, 0/ymin, 0x300/ymax, 0x16/color=dark-grey
  draw-vertical-line   screen, 0x340/x, 0/ymin, 0x300/ymax, 0x16/color=dark-grey
  draw-horizontal-line screen,  0x40/y, 0/xmin, 0x400/xmax, 0x16/color=dark-grey
  draw-horizontal-line screen, 0x2c0/y, 0/xmin, 0x400/xmax, 0x16/color=dark-grey
  # neighboring inputs, corners
  draw-rect screen,  0x90/xmin   0x10/ymin,    0xb0/xmax   0x30/ymax,   0xf/alive
  draw-rect screen, 0x350/xmin   0x10/ymin,   0x370/xmax   0x30/ymax,  0x1a/dead
  draw-rect screen,  0x90/xmin  0x2d0/ymin,    0xb0/xmax  0x2f0/ymax,   0xf/alive
  draw-rect screen, 0x350/xmin  0x2d0/ymin,   0x370/xmax  0x2f0/ymax,   0xf/alive
  # neighboring inputs, edges
  draw-rect screen, 0x1f0/xmin   0x10/ymin,   0x210/xmax   0x30/ymax,   0xf/alive
  draw-rect screen,  0x90/xmin  0x170/ymin,    0xb0/xmax  0x190/ymax,  0x1a/dead
  draw-rect screen, 0x1f0/xmin  0x2d0/ymin,   0x210/xmax  0x2f0/ymax,   0xf/alive
  draw-rect screen, 0x350/xmin  0x170/ymin,   0x370/xmax  0x190/ymax,   0xf/alive
  # sum node
  draw-rect screen, 0x170/xsmin 0x140/ysmin,  0x190/xsmax 0x160/ysmax, 0x40/color
  set-cursor-position screen, 0x2d/scol, 0x13/srow
  draw-text-wrapping-right-then-down-from-cursor-over-full-screen screen, "+", 0xf/color, 0/bg
  # conveyors from neighboring inputs to sum node
  draw-monotonic-bezier screen,  0xa0/x0  0x20/y0,  0x100/x1 0x150/ys,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen,  0xa0/x0 0x180/y0,   0xc0/x1 0x150/ys,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen,  0xa0/x0 0x2e0/y0,  0x100/x1 0x150/ys,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen, 0x200/x0  0x20/y0,  0x180/x1  0x90/y1,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen, 0x200/x0 0x2e0/y0,  0x180/x1 0x200/y1,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen, 0x360/x0  0x20/y0,  0x180/x1  0xc0/y1,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen, 0x360/x0 0x180/y0,  0x35c/x1 0x150/ys,  0x180/x2 0x150/ys,  4/color
  draw-monotonic-bezier screen, 0x360/x0 0x2e0/y0,  0x180/x1 0x200/y1,  0x180/x2 0x150/ys,  4/color
  # filter node
  draw-rect screen, 0x200/xfmin, 0x1c0/yfmin, 0x220/xfmax, 0x1e0/yfmax, 0x31/color
  set-cursor-position screen, 0x40/fcol, 0x1b/frow
  draw-text-wrapping-right-then-down-from-cursor-over-full-screen screen, "?", 0xf/color, 0/bg
  # conveyor from sum node to filter node
  draw-line screen 0x180/xs, 0x150/ys, 0x210/xf, 0x1d0/yf, 0xa2/color
  # cell outputs at corners
  draw-rect screen,  0xd0/xmin  0x50/ymin,   0xf0/xmax  0x70/ymax, 0xf/alive
  draw-rect screen, 0x310/xmin  0x50/ymin,  0x330/xmax  0x70/ymax, 0xf/alive
  draw-rect screen,  0xd0/xmin 0x290/ymin,   0xf0/xmax 0x2b0/ymax, 0xf/alive
  draw-rect screen, 0x310/xmin 0x290/ymin,  0x330/xmax 0x2b0/ymax, 0xf/alive
  # cell outputs at edges
  draw-rect screen, 0x1f0/xmin  0x50/ymin, 0x210/xmax,  0x70/ymax, 0xf/alive
  draw-rect screen,  0xd0/xmin 0x170/ymin,  0xf0/xmax, 0x190/ymax, 0xf/alive
  draw-rect screen, 0x1f0/xmin 0x290/ymin, 0x210/xmax, 0x2b0/ymax, 0xf/alive
  draw-rect screen, 0x310/xmin 0x170/ymin, 0x330/xmax, 0x190/ymax, 0xf/alive
  # conveyors from filter to outputs
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x1c0/x1  0x60/y1,  0xe0/x2   0x60/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,   0xe0/x1 0x1c0/y1,  0xe0/x2  0x180/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x1c0/x1 0x2a0/y1,  0xe0/x2  0x2a0/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x210/x1  0x60/y1, 0x200/x2   0x60/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x210/x1 0x230/y1, 0x200/x2  0x2a0/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x320/x1 0x120/y1, 0x320/x2   0x60/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x320/x1 0x1c0/y1  0x320/x2  0x180/y2,  0x2a/color
  draw-monotonic-bezier screen, 0x210/xf 0x1d0/yf,  0x320/x1 0x230/y1, 0x320/x2  0x2a0/y2,  0x2a/color
  # clock
  var tick-a/eax: (addr int) <- get self, tick
  set-cursor-position screen, 0x78/x, 0/y
  draw-int32-decimal-wrapping-right-then-down-from-cursor-over-full-screen screen, *tick-a, 7/fg 0/bg
  # time-variant portion: 16 repeating steps
  var progress/eax: int <- copy *tick-a
  progress <- and 0xf
  # 7 time steps for getting inputs to sum
  {
    compare progress, 7
    break-if->=
    var u/xmm7: float <- convert progress
    var six/eax: int <- copy 6
    var six-f/xmm0: float <- convert six
    u <- divide six-f
    # points on conveyors from neighboring cells
    draw-bezier-point screen, u,  0xa0/x0  0x20/y0, 0x100/x1 0x150/ys, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u,  0xa0/x0 0x180/y0,  0xc0/x1 0x150/ys, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u,  0xa0/x0 0x2e0/y0, 0x100/x1 0x150/ys, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u, 0x200/x0  0x20/y0, 0x180/x1  0x90/y1, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u, 0x200/x0 0x2e0/y0, 0x180/x1 0x200/y1, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u, 0x360/x0  0x20/y0, 0x180/x1  0xc0/y1, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u, 0x360/x0 0x180/y0, 0x35c/x1 0x150/ys, 0x180/x2 0x150/ys, 7/color, 4/radius
    draw-bezier-point screen, u, 0x360/x0 0x2e0/y0, 0x180/x1 0x200/y1, 0x180/x2 0x150/ys, 7/color, 4/radius
    return
  }
  # two time steps for getting count to filter
  progress <- subtract 7
  {
    compare progress, 2
    break-if->=
    progress <- increment  # (0, 1) => (1, 2)
    var u/xmm7: float <- convert progress
    var three/eax: int <- copy 3
    var three-f/xmm0: float <- convert three
    u <- divide three-f
    draw-linear-point screen, u, 0x180/xs, 0x150/ys, 0x210/xf, 0x1d0/yf, 7/color, 4/radius
    set-cursor-position screen, 0x3a/scol, 0x18/srow
    draw-int32-decimal-wrapping-right-then-down-from-cursor-over-full-screen screen, 3, 0xf/fg 0/bg
    return
  }
  # final 7 time steps for updating output
  progress <- subtract 2
  # points on conveyors to outputs
  var u/xmm7: float <- convert progress
  var six/eax: int <- copy 6
  var six-f/xmm0: float <- convert six
  u <- divide six-f
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x1c0/x1  0x60/y1,  0xe0/x2   0x60/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,   0xe0/x1 0x1c0/y1,  0xe0/x2  0x180/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x1c0/x1 0x2a0/y1,  0xe0/x2  0x2a0/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x210/xf  0x60/y1, 0x200/x2   0x60/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x210/xf 0x230/y1, 0x200/x2  0x2a0/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x320/x1 0x120/y1, 0x320/x2   0x60/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x320/x1 0x1c0/y1  0x320/x2  0x180/y2, 7/color, 4/radius
  draw-bezier-point screen, u, 0x210/xf 0x1d0/yf,  0x320/x1 0x230/y1, 0x320/x2  0x2a0/y2, 7/color, 4/radius
}

fn draw-bezier-point screen: (addr screen), u: float, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, color: int, radius: int {
  var _cy/eax: int <- bezier-point u, y0, y1, y2
  var cy/ecx: int <- copy _cy
  var cx/eax: int <- bezier-point u, x0, x1, x2
  draw-disc screen, cx, cy, radius, color, 0xf/border-color=white
}

fn draw-linear-point screen: (addr screen), u: float, x0: int, y0: int, x1: int, y1: int, color: int, radius: int {
  var _cy/eax: int <- line-point u, y0, y1
  var cy/ecx: int <- copy _cy
  var cx/eax: int <- line-point u, x0, x1
  draw-disc screen, cx, cy, radius, color, 0xf/border-color=white
}

fn edit keyboard: (addr keyboard), _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  var key/eax: byte <- read-key keyboard
  # TODO: hotkeys
}

fn pause _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  var i/ecx: int <- copy 0
  {
    compare i, 0x10000000
    break-if->=
    i <- increment
    loop
  }
}

fn step _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  var tick-a/ecx: (addr int) <- get self, tick
  var zoom/edx: (addr int) <- get self, zoom
  compare *zoom, 0
  {
    break-if-!=
    increment *tick-a
    return
  }
  compare *zoom, 4
  {
    break-if-!=
    add-to *tick-a, 0x10
    return
  }
  var tick/eax: int <- copy *tick-a
  tick <- and 0xf
  compare tick, 0
  {
    break-if-!=
    step4 self
  }
}

fn initialize-environment _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  var zoom/eax: (addr int) <- get self, zoom
  copy-to *zoom, 4
  var data-ah/eax: (addr handle array handle array boolean) <- get self, data
  populate data-ah, 0x100
  var data/eax: (addr array handle array boolean) <- lookup *data-ah
  var y/ecx: int <- copy 0
  {
    compare y, 0xc0
    break-if->=
    var dest-ah/eax: (addr handle array boolean) <- index data, y
    populate dest-ah, 0x100
    y <- increment
    loop
  }
  set self, 0x80, 0x5f
  set self, 0x81, 0x5f
  set self, 0x7f, 0x60
  set self, 0x80, 0x60
  set self, 0x80, 0x61
}

fn set _self: (addr environment), _x: int, _y: int {
  var self/esi: (addr environment) <- copy _self
  var data-ah/eax: (addr handle array handle array boolean) <- get self, data
  var data/eax: (addr array handle array boolean) <- lookup *data-ah
  var y/ecx: int <- copy _y
  var row-ah/eax: (addr handle array boolean) <- index data, y
  var row/eax: (addr array boolean) <- lookup *row-ah
  var x/ecx: int <- copy _x
  var dest/eax: (addr boolean) <- index row, x
  copy-to *dest, 1/true
}

fn state _self: (addr environment), _x: int, _y: int -> _/eax: boolean {
  var self/esi: (addr environment) <- copy _self
  var data-ah/eax: (addr handle array handle array boolean) <- get self, data
  var data/eax: (addr array handle array boolean) <- lookup *data-ah
  var y/ecx: int <- copy _y
  var row-ah/eax: (addr handle array boolean) <- index data, y
  var row/eax: (addr array boolean) <- lookup *row-ah
  var x/ecx: int <- copy _x
  var src/eax: (addr boolean) <- index row, x
  return *src
}

fn render4 screen: (addr screen), _self: (addr environment) {
  var self/esi: (addr environment) <- copy _self
  var y/ecx: int <- copy 0
  {
    compare y, 0xc0/height
    break-if->=
    var x/edx: int <- copy 0
    {
      compare x, 0x100/width
      break-if->=
      var state/eax: boolean <- state self, x, y
      compare state, 0/false
      {
        break-if-=
        render4-cell screen, x, y, 0xf/alive
      }
      compare state, 0/false
      {
        break-if-!=
        render4-cell screen, x, y, 0x1a/dead
      }
      x <- increment
      loop
    }
    y <- increment
    loop
  }
}

fn render4-cell screen: (addr screen), x: int, y: int, color: int {
  var xmin/eax: int <- copy x
  xmin <- shift-left 2
  var xmax/ecx: int <- copy xmin
  xmax <- add 4
  var ymin/edx: int <- copy y
  ymin <- shift-left 2
  var ymax/ebx: int <- copy ymin
  ymax <- add 4
  draw-rect screen, xmin ymin, xmax ymax, color
}

fn step4 _self: (addr environment) {
}
