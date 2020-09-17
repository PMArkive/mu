# rendering a tree with a single child
#
# To run (on Linux and x86):
#   $ git clone https://github.com/akkartik/mu
#   $ cd mu
#   $ ./translate_mu prototypes/tile/5.mu
#   $ ./a.elf
#
# You should see a single rectangle representing a singleton tree node.
# Press a key. You should see the tree grow a single child.
# It seems useful as a visual idiom to represent nodes with a single child as
# slightly larger than the child.
# Once we get to multiple children we'll start tiling more regularly.

type cell {
  val: int  # single chars only for now
  parent: (handle cell)
  first-child: (handle cell)
  next-sibling: (handle cell)
  prev-sibling: (handle cell)
}

fn main -> exit-status/ebx: int {
  var root-handle: (handle cell)
  var root/esi: (addr handle cell) <- address root-handle
  allocate root
  var cursor/edi: (addr handle cell) <- copy root
  enable-keyboard-immediate-mode
  var root-addr/eax: (addr cell) <- lookup *root
  render root-addr
$main:loop: {
    # process key
    {
      var c/eax: grapheme <- read-key-from-real-keyboard
      compare c, 4  # ctrl-d
      break-if-= $main:loop
      process c, root, cursor
    }
    # render tree
    root-addr <- lookup root-handle
    render root-addr
    loop
  }
  clear-screen 0
  enable-keyboard-type-mode
  exit-status <- copy 0
}

#######################################################
# Tree mutations
#######################################################

fn process c: grapheme, root: (addr handle cell), cursor: (addr handle cell) {
  var c1/eax: (addr handle cell) <- copy cursor
  var c2/eax: (addr cell) <- lookup *c1
  create-child c2
}

fn create-child node: (addr cell) {
  var n/ecx: (addr cell) <- copy node
  var first-child/esi: (addr handle cell) <- get n, first-child
  allocate first-child
}

#######################################################
# Tree drawing
#######################################################

fn render root: (addr cell) {
  clear-screen 0
  var depth/eax: int <- tree-depth root
  var viewport-width/ecx: int <- copy 0x64  # col2
  viewport-width <- subtract 5  # col1
  var column-width/eax: int <- try-divide viewport-width, depth
  render-tree root, column-width, 5, 5, 0x20, 0x64
}

fn render-tree c: (addr cell), column-width: int, row-min: int, col-min: int, row-max: int, col-max: int {
  var root-max/ecx: int <- copy col-min
  root-max <- add column-width
  draw-box row-min, col-min, row-max, root-max
  var c2/eax: (addr cell) <- copy c
  var child/eax: (addr handle cell) <- get c2, first-child
  var child-addr/eax: (addr cell) <- lookup *child
  {
    compare child-addr, 0
    break-if-=
    increment row-min
    decrement row-max
    render-tree child-addr, column-width, row-min, root-max, row-max, col-max
  }
}

fn tree-depth node-on-stack: (addr cell) -> result/eax: int {
  var tmp-result/edi: int <- copy 0
  var node/eax: (addr cell) <- copy node-on-stack
  var child/ecx: (addr handle cell) <- get node, first-child
  var child-addr/eax: (addr cell) <- lookup *child
  {
    compare child-addr, 0
    break-if-=
    {
      var tmp/eax: int <- tree-depth child-addr
      compare tmp, tmp-result
      break-if-<=
      tmp-result <- copy tmp
    }
    child <- get child-addr, next-sibling
    child-addr <- lookup *child
    loop
  }
  result <- copy tmp-result
  result <- increment
}

fn draw-box row1: int, col1: int, row2: int, col2: int {
  draw-horizontal-line row1, col1, col2
  draw-vertical-line row1, row2, col1
  draw-horizontal-line row2, col1, col2
  draw-vertical-line row1, row2, col2
}

fn draw-horizontal-line row: int, col1: int, col2: int {
  var col/eax: int <- copy col1
  move-cursor 0, row, col
  {
    compare col, col2
    break-if->=
    print-string 0, "-"
    col <- increment
    loop
  }
}

fn draw-vertical-line row1: int, row2: int, col: int {
  var row/eax: int <- copy row1
  {
    compare row, row2
    break-if->=
    move-cursor 0, row, col
    print-string 0, "|"
    row <- increment
    loop
  }
}
