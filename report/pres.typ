#import "@preview/touying:0.6.1": *
#import themes.university: *
#import "@preview/cetz:0.3.2"
#import "@preview/fletcher:0.5.5" as fletcher: node, edge
#import "@preview/numbly:0.1.0": numbly
#import "@preview/theorion:0.3.2": *
#import "@preview/intextual:0.1.0": flushr, intertext-rule
#show: intertext-rule
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

#components.adaptive-columns(outline(title: none, depth: 1))

= Notaion
== Differential operators
$
  nabla = (partial_1, partial_2, dots, partial_n) #flushr([(Nabla operator)])
$

#pause

$
  u dot nabla = sum_(i=1)^n u_i partial_i
$

#pause

$
  (u dot nabla)u = sum_(i=1)^n u_i partial_i u.
$

#pause

$
  nabla dot nabla u = Delta u = sum_(i=1)^n (partial_i u)^2 #flushr([(Laplace operator)])
$

= Equations of fluids
== Navier--Stokes equations
$
  (partial bold(u))/(partial t) + (bold(u) dot nabla) bold(u) = nu Delta
bold(u) - 1/rho nabla p + 1/rho bold(f)
$
#pause

- $bold(u)$ is the velocity vector field.
#pause
- $bold(f)$ is the external forces.
#pause
- $rho$ is the scalar density field.
#pause
- $p$ is the pressure field.
#pause
- $nu$ is the kinematic viscosity.

---

$
  (partial bold(u))/(partial t) + overbrace((bold(u) dot nabla) bold(u),
  "Advection") = underbrace(nu Delta bold(u), "Diffusion") overbrace(- 1/rho
   nabla p, "Internal source") + underbrace(1/rho bold(f), "External source").
$

#pause
1. Advection -- How the velocity moves.
#pause
2. Diffusion -- How the velocity spreads out.
#pause
3. Internal source -- How the velocity points towards parts of lesser pressure.
#pause
4. External source -- How the velocity is changed subject to external
   intervention, like a fan blowing air.

= Equations for fluid simulations
== Navier--Stokes equations 2
$
  (partial bold(u))/(partial t) &= - (bold(u) dot nabla)bold(u) + nu Delta
bold(u) + 1/rho bold(f) \
  #pause
  (partial rho)/(partial t) &= -(bold(u) dot nabla)rho + kappa Delta rho + S
$

#pause

$
  nabla dot u = 0
$

#pause

$
  u|_(partial Omega) &= 0 \
  rho|_(partial Omega) &= 0
$

= Simulating fluids
== Fluid in a box
#align(center + horizon)[
  #cetz.canvas({
    import cetz.draw: *

    let side = 5
    let cell = 1

    rect((-side, -side), (-side + cell, side), fill: gray, stroke: 0pt)
    rect((side, -side), (side - cell, side), fill: gray, stroke: 0pt)
    rect((-side, side), (side, side - cell), fill: gray, stroke: 0pt)
    rect((-side, -side), (side, -side + cell), fill: gray, stroke: 0pt)

    grid((-side, -side), (side, side), step: cell, stroke: 0.4pt)
    rect((-side + cell, -side + cell), (side - cell, side - cell), stroke: 3pt)

    for (x, cnt) in ((0, $0$), (2 * cell, $1$), (4 * cell, $2$)) {
      content((-side + cell/2 + x/2, -side - 0.1), text(size: 16pt)[#cnt], anchor: "north")
      content((-side - 0.1, -side + cell/2 + x/2), text(size: 16pt)[#cnt], anchor: "east")
    }
    content((side - cell / 2, -side - 0.1), text(size: 20pt)[$N+1$], anchor: "north")
    content((cell/2, -side + 0.1),          text(size: 20pt)[$dots$], anchor: "north")
    content((-side - 0.1, side - cell/2),   text(size: 20pt)[$N+1$], anchor: "east")
    content((-side - 0.2, cell/2),          text(size: 20pt)[$dots.v$], anchor: "east")

    content((0, 0), text(size: 32pt)[$Omega$])
    content((side + cell, 0), text(size: 24pt)[$partial Omega$])
  })
]

== Moving densities
#align(center + horizon)[
  #let semi_gray = gray.transparentize(50%)

  #cetz-canvas({
    import cetz.draw: *

    scale(x: 170%, y: 170%)

    let semi_red = red.transparentize(30%)

    // initial density
    rect((-6.5, 0), (-5.5, 1), fill: gray, stroke: 0pt)
    grid((-7.5, -1), (-4.5, 2), step: 0.5, stroke: 0.6pt)
    content((-6, 2.05), text(size: 16pt)[Initial density], anchor: "south")

    (pause,)

    // add source
    rect((-2.5, 0), (-1.5, 1), fill: gray, stroke: 0pt)
    rect((-1.5, 1), (-0.5, 1.5), fill: gray, stroke: 0pt)
    grid((-3.5, -1), (-0.5, 2), step: 0.5, stroke: 0.6pt)
    content((-2, 2.1),  text(size: 16pt)[Add sources], anchor: "south")

    (pause,)

    // diffusion
    rect((1.5, 0), (2.5, 1), fill: gray, stroke: 0pt)
    rect((1.0, 0), (3, 1), fill: semi_gray, stroke: 0pt)
    rect((1.5, -0.5), (2.5, 1.5), fill: semi_gray, stroke: 0pt)
    rect((2.5, 1), (3.5, 1.5), fill: gray, stroke: 0pt)
    rect((2.5, 0.5), (3.5, 2), fill: semi_gray, stroke: 0pt)
    rect((2, 1), (2.5, 1.5), fill: semi_gray, stroke: 0pt)
    grid((3.5, -1), (0.5, 2),   step: 0.5, stroke: 0.6pt)
    content((2, 2.1),   text(size: 16pt)[Diffusion], anchor: "south")

    (pause,)

    // advection
    rect((5.5, -0.5), (6.5, 0.5), fill: gray, stroke: 0pt)
    rect((5.0, -0.5), (7, 0.5), fill: semi_gray, stroke: 0pt)
    rect((5.5, -1), (6.5, 1), fill: semi_gray, stroke: 0pt)
    rect((6.5, 0.5), (7.5, 1), fill: gray, stroke: 0pt)
    rect((6.5, 0), (7.5, 1.5), fill: semi_gray, stroke: 0pt)
    rect((6, 0.5), (6.5, 1), fill: semi_gray, stroke: 0pt)
    grid((7.5, -1), (4.5, 2),   step: 0.5, stroke: 0.6pt)
    content((6, 2.1),   text(size: 16pt)[Advection], anchor: "south")

    (pause,)

    // velocity vectors
    line((6.75, 0.75), (6.75, 0.25), stroke: 1.5pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
    line((5.25, 0.75), (5.25, 0.25), stroke: 1.5pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
  })
]


= Diffusion
== Diffusion equation
$
  (partial rho)/(partial t) = kappa Delta rho.
$

#pause

$
  (rho_"next" - rho_"prev")/(Delta t) = kappa Delta rho_"prev" #flushr([(Forward difference)]) \
$
$
  #pause
  rho_"next" = rho_"prev" + (Delta t) kappa Delta rho_"prev" #flushr([(Helmholtz eq.)])
$

== Duffusion
#align(center + horizon)[
  #let semi_gray = gray.transparentize(50%)

  #cetz-canvas({
    import cetz.draw: *

    scale(x: 200%, y: 200%)

    let semi_red = red.transparentize(40%)
    let semi_blue = blue.transparentize(40%)

    rect((-1, -1), (1, 1),  stroke: 1.5pt, name: "middle")
    rect((-3, -1), (-1, 1), stroke: 1.5pt, name: "left")
    rect((1, -1), (3, 1),   stroke: 1.5pt, name: "right")
    rect((-1, 1), (1, 3),   stroke: 1.5pt, name: "top")
    rect((-1, -3), (1, -1), stroke: 1.5pt, name: "bottom")

    (pause,)

    line((0.1, -0.5), (0.1, -2), stroke: 2pt + semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))
    line((0.1, 0.5), (0.1, 2), stroke: 2pt + semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))
    line((0.5, 0.1), (2, 0.1), stroke: 2pt + semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))
    line((-0.5, 0.1), (-2, 0.1), stroke: 2pt + semi_blue, mark: (end: ">", scale: 0.5, fill: semi_blue))

    (pause,)

    line((-2, -0.1), (-0.5, -0.1), stroke: 2pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
    line((2, -0.1), (0.5, -0.1), stroke: 2pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
    line((-0.1, 2), (-0.1, 0.5), stroke: 2pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
    line((-0.1, -2), (-0.1, -0.5), stroke: 2pt + semi_red, mark: (end: ">", scale: 0.5, fill: semi_red))
  })
]

== Finite difference method
$
  partial_1^2 rho approx (u_(i+1, j) - 2 u_(i, j) + u_(i-1, j))/h^2
$

$
  partial_2^2 rho approx (u_(i, j+1) - 2 u_(i, j) + u_(i, j-1))/h^2
$

#pause

$
  (Delta_h rho_h)_(i, j) = (rho_(i+1, j) + rho_(i-1, j) + rho_(i, j+1) + rho_(i, j-1) - 4rho_(i,j))/(h^2)
$

== FDM matrix
#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    scale(x: 150%, y: 150%)

    let cell_size = 1.5
    let grid_size = cell_size * 4

    content((-grid_size / 2 -0.3, grid_size/2 - cell_size/2), anchor: "east", [$n$])
    content((-grid_size/2 + cell_size/2, grid_size/2 + 0.3), anchor: "south", [$n$])

    rect((-grid_size/2, -grid_size/2), (grid_size/2, grid_size/2))
    rect((-grid_size/2, grid_size/2), (-grid_size/2 + cell_size, grid_size/2 - cell_size), name: "topleft")

    let tiles = (
      (-grid_size/2, grid_size/2),
      (-grid_size/2 + cell_size, grid_size/2 - cell_size),
      (-grid_size/2 + 2 * cell_size, grid_size/2 - 2 * cell_size),
      (-grid_size/2 + 3 * cell_size, grid_size/2 - 3 * cell_size),
    )

    for (i, (x, y)) in tiles.enumerate() {
      if i > 0 {
        rect((x, y), (x + cell_size, y - cell_size))
      }
      
      line((x + 0.05, y - 0.05), (x + cell_size - 0.05, y - cell_size + 0.05), stroke: 2pt + green)
      
      line((x + 0.25, y - 0.05), (x + cell_size - 0.05, y - cell_size + 0.25), stroke: 2pt + red)
      line((x + 0.05, y - 0.25), (x + cell_size - 0.25, y - cell_size + 0.05), stroke: 2pt + red)
      
      if i >= 0 and i <= 2 {
        line((x + 0.05, y - 0.05 - cell_size), (x + cell_size - 0.05, y - cell_size + 0.05 - cell_size), stroke: 2pt + orange)
      }
      
      if i >= 1 and i <= 3 {
        line((x + 0.05, y - 0.05 + cell_size), (x + cell_size - 0.05, y - cell_size + 0.05 + cell_size), stroke: 2pt + orange)
      }
    }
  })

  #pause

  #text(green)[green] $ = 4\/h^2$, #text(red)[red] $=-1\/h^2$,
  #text(orange)[orange] $=-1\/h^2$
]

= Advection
== Advection equation
$
  (partial rho)/(partial t) = - (bold(u) dot nabla) rho.
$

#pause

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    let step = 1
    let start = -3
    let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)
    grid((start, start), (-start, -start), step: step)
    for i in values {
      for j in values {
        circle((i + step / 2, j + step / 2), radius: 2pt, fill: black)
      }
    }
  })
]

== Semi-Lagrange
#align(center + horizon)[
  #cetz-canvas({
    import cetz.draw: *

    scale(x: 150%, y: 150%)

    let step = 1
    let start = -3
    let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)
    grid((start, start), (-start, -start), step: step)

    (pause,)

    for i in values {
      for j in values {
        let y = i + step/2
        let x = j + step/2
        let u = y/4
        let v = -x/4
        line((x, y), (x + u, y + v),
          stroke: gray + 0.8pt,
          mark: (end: ">", scale: 0.6))
      }
    }

    (pause,)

    let (a1, b1, c1) = ((-0.5, 2.5), (-1.7, 1.8), (-1.3, 2.6))
    let (a2, b2, c2) = ((-0.5, 1.5), (-1.4, 0.9), (-1.1, 1.6))
    let (a3, b3, c3) = ((-1.5, 1.5), (-2.1, 0.5), (-1.95, 1.3))

    bezier(a1, b1, c1,
      stroke: black + 2.5pt,
      mark: (start: "o", end: ">", scale: 0.6)
    )
    bezier(a2, b2, c2,
      stroke: black + 2.5pt,
      mark: (start: "o", end: ">", scale: 0.6)
    )
    bezier(a3, b3, c3,
      stroke: black + 2.5pt,
      mark: (start: "o", end: ">", scale: 0.6)
    )
  })
]

= Evolving velocites
== Helmholtz--Hodge decomposition
#align(center + horizon)[
  #cetz-canvas({
    import cetz.draw: *

    scale(x: 170%, y: 170%)

    let step = 0.3
    let start = -3
    let field_scale = 0.2
    let zoom = 0.5
    let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)

    let rot_u(x, y, field_scale) = {calc.sin(y + calc.sin(x)) * field_scale}
    let rot_v(x, y, field_scale) = {-calc.sin(x + calc.sin(y)) * field_scale}
    let div_u(x, y, field_scale) = {calc.sin(x) * calc.cos(y) * field_scale * 0.6}
    let div_v(x, y, field_scale) = {calc.cos(x) * calc.sin(y) * field_scale * 0.6}
    let div_u_vis(x, y, field_scale) = {calc.sin(x) * calc.cos(y) * field_scale * 1.6}
    let div_v_vis(x, y, field_scale) = {calc.cos(x) * calc.sin(y) * field_scale * 1.6}
    let comb_u(x, y, field_scale) = {rot_u(x, y, field_scale) + div_u(x, y, field_scale)}
    let comb_v(x, y, field_scale) = {rot_v(x, y, field_scale) + div_v(x, y, field_scale)}

    let quiver(start_x, start_y, size, step, f_u, f_v) = {
      let values = range(0, int(size / step)).map(x => -size/2 + x * step)
      for i in values {
        for j in values {
        let cell_y = i + step/2
        let cell_x = j + step/2
        let y = cell_y / zoom
        let x = cell_x / zoom
        let u = f_u(x, y, field_scale)
        let v = f_v(x, y, field_scale)

        let pos_x = cell_x + size/2 + start_x
        let pos_y = cell_y

        // debug circles at the cell middle
        // circle((pos_x, pos_y), radius: 1.5pt, stroke: red)

        line((pos_x, pos_y), (pos_x + u, pos_y + v),
          stroke: black + 0.8pt,
          mark: (end: ">", scale: 0.2))

        }
      }
      rect((start_x, start_y), (start_x + size, start_y + size), stroke: 0.2pt)
    }

    let size = 4

    content((-6, 2.1), text(size: 16pt)[combined field], anchor: "south")
    quiver(-8, -2, size, step, comb_u, comb_v)
    content((-3, 0), text(size: 28pt)[$=$])
    (pause,)

    quiver(-2, -2, size, step, rot_u, rot_v)
    quiver(4, -2, size, step, div_u_vis, div_v_vis)

    content((0, 2.1),  text(size: 16pt)[rotation field], anchor: "south")
    content((6, 2.02), text(size: 16pt)[divergence field], anchor: "south")
    content((3, 0), text(size: 28pt)[$+$])
  })
]

---
$
  bold(w) &= bold(u) + nabla q \
  nabla dot bold(u) = 0&, quad q: RR^n -> RR
$
#pause

$
  nabla dot bold(w) &= nabla dot bold(u) + nabla dot nabla q \
  pause
  nabla dot bold(w) &= 0 + nabla dot nabla q \
  pause
  nabla dot bold(w) &= Delta q #flushr([(Poisson eq.)])
$
#pause

$
  bold(u) = bold(w) - nabla q
$

== Projection
#align(center + horizon)[
  #cetz-canvas({
    import cetz.draw: *

    scale(x: 150%, y: 150%)

    let x_dir = (2, -1)
    let y_dir = (5, 0)
    let z_dir = (0, 3)

    let scale = 0.25

    let values = range(-3, 5)

    for i in range(-4, 5) {
      let start = (-y_dir.at(0), -y_dir.at(1))
      let end = (y_dir.at(0), y_dir.at(1))
      let x1 = start.at(0) + x_dir.at(0) * i * scale
      let y1 = start.at(1) + x_dir.at(1) * i * scale
      let x2 = end.at(0) + x_dir.at(0) * i * scale
      let y2 = end.at(1) + x_dir.at(1) * i * scale
      line((x1, y1), (x2, y2), stroke: 1pt + gray)
    }

    for i in range(-4, 5) {
      let start = (-x_dir.at(0), -x_dir.at(1))
      let end = (x_dir.at(0), x_dir.at(1))
      let x1 = start.at(0) + y_dir.at(0) * i * scale
      let y1 = start.at(1) + y_dir.at(1) * i * scale
      let x2 = end.at(0) + y_dir.at(0) * i * scale
      let y2 = end.at(1) + y_dir.at(1) * i * scale
      line((x1, y1), (x2, y2), stroke: 1pt + gray)
    }

    line((-y_dir.at(0), -y_dir.at(1)), y_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))
    line((-x_dir.at(0), -x_dir.at(1)), x_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))
    line((0,0), z_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))

    content((5.5, -0.5), text(size: 24pt)[$nabla dot u = 0$])
    (pause,)

    let points = ((-2.7,-0.5), (-3.2,1.5), (-0.5,2), (2, 1.8), (2, -0.3))
    let names = ($u_1$, $u_2$, $u_3$, $u_4$, $u_4$)
    content(points.at(0), names.at(0), anchor: "north-east")
    circle(points.at(0), radius: 1.2pt, stroke: black, fill: black)

    for ((pt1, pt2), name) in points.slice(0, points.len() - 1).zip(points.slice(1, points.len())).zip(names) {
      line(pt1, pt2, stroke: (dash: "dotted"))
      content(pt2, name, anchor: "north-east")
      circle(pt2, radius: 1.2pt, stroke: black, fill: black)
      (pause,)
    }

    line(points.first(), points.last(), stroke: 1.5pt + red, mark: (end: ">", scale: 0.5))

    line((-y_dir.at(0), -y_dir.at(1)), y_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))
    line((-x_dir.at(0), -x_dir.at(1)), x_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))
    line((0,0), z_dir, stroke: 2pt, mark: (end: ">", scale: 0.5))
  })

  #meanwhile
  $
    u_1 -->^"add source" u_2 -->^"diffusion" u_3 -->^"advection" u_4 -->^"projection" u_5
  $
]


= Appendix

== Appendix
#link("https://github.com/leonardo-toffalini/viscous")

---

#figure(
  image("smoke_screenshot.png", width: 40%),
  caption: [Smoke emitting from the tip of a cigarette]
)

---

#figure(
  image("vortex_shredding.png", width: 42%),
  caption: [Vortex shredding]
)

#bibliography("refs.bib", full: true)
