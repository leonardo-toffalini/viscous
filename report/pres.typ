#import "@preview/touying:0.6.1": *
#import themes.university: *
#import "@preview/cetz:0.3.2"
#import "@preview/fletcher:0.5.5" as fletcher: node, edge
#import "@preview/numbly:0.1.0": numbly
#import "@preview/theorion:0.3.2": *
#import cosmos.clouds: *
#show: show-theorion

// cetz and fletcher bindings for touying
#let cetz-canvas = touying-reducer.with(reduce: cetz.canvas, cover: cetz.draw.hide.with(bounds: true))
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)

#show: university-theme.with(
  aspect-ratio: "16-9",
  // align: horizon,
  // config-common(handout: true),
  // config-common(show-notes-on-second-screen: right),
  config-common(frozen-counters: (theorem-counter,)),  // freeze theorem counter for animation
  config-info(
    title: [Real time fluid dynamics],
    author: [Leonardo Toffalini],
    date: datetime.today(),
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

== Outline <touying:hidden>

#components.adaptive-columns(outline(title: none, indent: 1em))

= Notaion
== Differential operators
$
  nabla = (partial_1 u, partial_2 u, dots, partial_n u)
$

$
  u dot nabla = sum_(i=1)^n u_i partial_i
$

$
  (u dot nabla)u = sum_(i=1)^n u_i partial_i u.
$

*Laplacian*
$
  nabla dot nabla u = Delta u = sum_(i=1)^n (partial_i u)^2.
$

= Equations of fluids
== Navier--Stokes equations
$
  (partial bold(u))/(partial t) + (bold(u) dot nabla) bold(u) = nu Delta
bold(u) - 1/rho nabla p + 1/rho bold(f),
$

- $bold(u)$ is the velocity vector field.
- $bold(f)$ is the external forces.
- $rho$ is the scalar density field.
- $p$ is the pressure field.
- $nu$ is the kinematic viscosity.

---
$
  (partial bold(u))/(partial t) + overbrace((bold(u) dot nabla) bold(u),
  "Advection") = underbrace(nu Delta bold(u), "Diffusion") overbrace(- 1/rho
   nabla p, "Internal source") + underbrace(1/rho bold(f), "External source").
$

1. Advection -- How the velocity moves.
2. Diffusion -- How the velocity spreads out.
3. Internal source -- How the velocity points towards parts of lesser pressure.
4. External source -- How the velocity is changed subject to external
   intervention, like a fan blowing air.

= Equations for fluid simulations
== Navier--Stokes equations 2
$
  (partial bold(u))/(partial t) = - (bold(u) dot nabla)bold(u) + nu Delta
bold(u) + 1/rho bold(f).
$

$
  (partial rho)/(partial t) = -(bold(u) dot nabla)rho + kappa Delta rho + S,
$

$
  u|_(partial Omega) &= 0 \
  rho|_(partial Omega) &= 0,
$

= Simulating fluids
== Fluid in a box
#align(center + horizon)[
  #cetz.canvas({
    import cetz.draw: *

    let side = 5
    let cell = 0.5

    rect((-side, -side), (-side + cell, side), fill: gray, stroke: 0pt)
    rect((side, -side), (side - cell, side), fill: gray, stroke: 0pt)
    rect((-side, side), (side, side - cell), fill: gray, stroke: 0pt)
    rect((-side, -side), (side, -side + cell), fill: gray, stroke: 0pt)

    grid((-side, -side), (side, side), step: 0.5, stroke: 0.3pt)
    line((-side + cell, -side + cell), (-side + cell, side - cell))
    line((side - cell, side - cell), (-side + cell, side - cell))
    line((side - cell, side - cell), (side - cell, -side + cell))
    line((-side + cell, -side + cell), (side - cell, -side + cell))

    for (x, cnt) in ((0, $0$), (1, $1$), (2, $2$)) {
      content((-side + cell/2 + x/2, -side - 0.1), text(size: 16pt)[#cnt], anchor: "north")
      content((-side - 0.1, -side + cell/2 + x/2), text(size: 16pt)[#cnt], anchor: "east")
    }
    content((side - cell / 2, -side - 0.1), text(size: 20pt)[$N+1$], anchor: "north")
    content((cell/2, -side + 0.1),          text(size: 20pt)[$dots$], anchor: "north")
    content((-side - 0.1, side - cell/2),   text(size: 20pt)[$N+1$], anchor: "east")
    content((-side - 0.2, cell/2),          text(size: 20pt)[$dots.v$], anchor: "east")

    content((0, 0), text(size: 32pt)[$Omega$])
    content((side + 2 * cell, 0), text(size: 24pt)[$partial Omega$])
  })
]

== Moving densities
#align()[
  #let semi_gray = gray.transparentize(50%)

  #let c = cetz.canvas({
      import cetz.draw: *

      // initial density
      rect((-6.5, 0), (-5.5, 1), fill: gray, stroke: 0pt)

      // add source
      rect((-2.5, 0), (-1.5, 1), fill: gray, stroke: 0pt)
      rect((-1.5, 1), (-0.5, 1.5), fill: gray, stroke: 0pt)

      // diffusion
      rect((1.5, 0), (2.5, 1), fill: gray, stroke: 0pt)
      rect((1.0, 0), (3, 1), fill: semi_gray, stroke: 0pt)
      rect((1.5, -0.5), (2.5, 1.5), fill: semi_gray, stroke: 0pt)
      rect((2.5, 1), (3.5, 1.5), fill: gray, stroke: 0pt)
      rect((2.5, 0.5), (3.5, 2), fill: semi_gray, stroke: 0pt)
      rect((2, 1), (2.5, 1.5), fill: semi_gray, stroke: 0pt)

      // advection
      rect((5.5, -0.5), (6.5, 0.5), fill: gray, stroke: 0pt)
      rect((5.0, -0.5), (7, 0.5), fill: semi_gray, stroke: 0pt)
      rect((5.5, -1), (6.5, 1), fill: semi_gray, stroke: 0pt)
      rect((6.5, 0.5), (7.5, 1), fill: gray, stroke: 0pt)
      rect((6.5, 0), (7.5, 1.5), fill: semi_gray, stroke: 0pt)
      rect((6, 0.5), (6.5, 1), fill: semi_gray, stroke: 0pt)

      // velocity vectors
      line((6.75, 0.75), (6.75, 0.25), stroke: red.transparentize(50%), mark: (end: ">", scale: 0.5))
      line((5.25, 0.75), (5.25, 0.25), stroke: red.transparentize(50%), mark: (end: ">", scale: 0.5))

      // left to right
      grid((-7.5, -1), (-4.5, 2), step: 0.5, stroke: 0.3pt)
      grid((-3.5, -1), (-0.5, 2), step: 0.5, stroke: 0.3pt)
      grid((3.5, -1), (0.5, 2), step: 0.5, stroke: 0.3pt)
      grid((7.5, -1), (4.5, 2), step: 0.5, stroke: 0.3pt)

      content((-6, 2.05), text(size: 16pt)[Initial density], anchor: "south")
      content((-2, 2.1),  text(size: 16pt)[Add sources], anchor: "south")
      content((2, 2.1),   text(size: 16pt)[Diffusion], anchor: "south")
      content((6, 2.1),   text(size: 16pt)[Advection], anchor: "south")

      // for vertical alignment
      circle((0, 4), radius: 1pt, stroke: 0pt)
    })

  #place(
    context {
    let (width, height) = measure(c)
    scale(10cm / width * 250%, place(c))
  })
]


== Diffusion
$
  (partial rho)/(partial t) = kappa Delta rho.
$

$
  (rho_"next" - rho_"prev")/(Delta t) = kappa Delta rho_"prev" \
  rho_"next" = rho_"prev" + (Delta t) kappa Delta rho_"prev"
$

== Five point stencil
#align()[
  #let semi_gray = gray.transparentize(50%)

  #let c = cetz.canvas({
      import cetz.draw: *

      let semi_red = red.transparentize(40%)
      let semi_blue = blue.transparentize(40%)

      rect((-1, -1), (1, 1), name: "middle")
      rect((-3, -1), (-1, 1), name: "left")
      rect((1, -1), (3, 1), name: "right")
      rect((-1, 1), (1, 3), name: "top")
      rect((-1, -3), (1, -1), name: "bottom")

      // left <-> middle
      line((-2, -0.1), (-0.5, -0.1), stroke: semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
      line((-0.5, 0.1), (-2, 0.1), stroke: semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))

      // right <-> middle
      line((2, -0.1), (0.5, -0.1), stroke: semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
      line((0.5, 0.1), (2, 0.1), stroke: semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))

      // top <-> middle
      line((-0.1, 2), (-0.1, 0.5), stroke: semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
      line((0.1, 0.5), (0.1, 2), stroke: semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))

      // bottom <-> middle
      line((-0.1, -2), (-0.1, -0.5), stroke: semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
      line((0.1, -0.5), (0.1, -2), stroke: semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))

      // for alignment
      circle((0,0), radius: 1pt)
    })

  #place(
    center,
    context {
    let (width, height) = measure(c)
    scale(10cm / width * 120%, origin: center + horizon, place(c))
  })

]

= Animation

== Simple Animation

We can use `#pause` to #pause display something later.

#pause

Just like this.

#meanwhile

Meanwhile, #pause we can also use `#meanwhile` to #pause display other content synchronously.

#speaker-note[
  + This is a speaker note.
  + You won't see it unless you use `config-common(show-notes-on-second-screen: right)`
]


== Complex Animation

At subslide #touying-fn-wrapper((self: none) => str(self.subslide)), we can

use #uncover("2-")[`#uncover` function] for reserving space,

use #only("2-")[`#only` function] for not reserving space,

#alternatives[call `#only` multiple times \u{2717}][use `#alternatives` function #sym.checkmark] for choosing one of the alternatives.


== Callback Style Animation

#slide(
  repeat: 3,
  self => [
    #let (uncover, only, alternatives) = utils.methods(self)

    At subslide #self.subslide, we can

    use #uncover("2-")[`#uncover` function] for reserving space,

    use #only("2-")[`#only` function] for not reserving space,

    #alternatives[call `#only` multiple times \u{2717}][use `#alternatives` function #sym.checkmark] for choosing one of the alternatives.
  ],
)


== Math Equation Animation

Equation with `pause`:

$
  f(x) &= pause x^2 + 2x + 1 \
  &= pause (x + 1)^2 \
$

#meanwhile

Here, #pause we have the expression of $f(x)$.

#pause

By factorizing, we can obtain this result.


== CeTZ Animation

CeTZ Animation in Touying:

#cetz-canvas({
  import cetz.draw: *

  rect((0, 0), (5, 5))

  (pause,)

  rect((0, 0), (1, 1))
  rect((1, 1), (2, 2))
  rect((2, 2), (3, 3))

  (pause,)

  line((0, 0), (2.5, 2.5), name: "line")
})


== Fletcher Animation

Fletcher Animation in Touying:

#fletcher-diagram(
  node-stroke: .1em,
  node-fill: gradient.radial(blue.lighten(80%), blue, center: (30%, 20%), radius: 80%),
  spacing: 4em,
  edge((-1, 0), "r", "-|>", `open(path)`, label-pos: 0, label-side: center),
  node((0, 0), `reading`, radius: 2em),
  edge((0, 0), (0, 0), `read()`, "--|>", bend: 130deg),
  pause,
  edge(`read()`, "-|>"),
  node((1, 0), `eof`, radius: 2em),
  pause,
  edge(`close()`, "-|>"),
  node((2, 0), `closed`, radius: 2em, extrude: (-2.5, 0)),
  edge((0, 0), (2, 0), `close()`, "-|>", bend: -40deg),
)


= Theorems

== Prime numbers

#definition[
  A natural number is called a #highlight[_prime number_] if it is greater
  than 1 and cannot be written as the product of two smaller natural numbers.
]
#example[
  The numbers $2$, $3$, and $17$ are prime.
  @cor_largest_prime shows that this list is not exhaustive!
]

#theorem(title: "Euclid")[
  There are infinitely many primes.
]
#pagebreak(weak: true)
#proof[
  Suppose to the contrary that $p_1, p_2, dots, p_n$ is a finite enumeration
  of all primes. Set $P = p_1 p_2 dots p_n$. Since $P + 1$ is not in our list,
  it cannot be prime. Thus, some prime factor $p_j$ divides $P + 1$. Since
  $p_j$ also divides $P$, it must divide the difference $(P + 1) - P = 1$, a
  contradiction.
]

#corollary[
  There is no largest prime number.
] <cor_largest_prime>
#corollary[
  There are infinitely many composite numbers.
]

#theorem[
  There are arbitrarily long stretches of composite numbers.
]

#proof[
  For any $n > 2$, consider $
    n! + 2, quad n! + 3, quad ..., quad n! + n
  $
]


= Others

== Side-by-side

#slide(composer: (1fr, 1fr))[
  First column.
][
  Second column.
]


== Multiple Pages

#lorem(200)


#show: appendix

= Appendix

== Appendix

Please pay attention to the current slide number.
