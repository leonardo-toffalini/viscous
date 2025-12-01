#import "@preview/cetz:0.4.2"

#let numbered_eq(content) = math.equation(block: true, numbering: "(1)", content)

= Moving densities
In our simulation, we will solve the parts of the simplified Navier-Stokes
equations for the density field one by one. Starting with the simplest, adding
additional density, then diffusion, and lastly advection. The simulation steps
can be seen in @fig:moving-density, where one most imagine applying the steps
in order from left to right, and repeating the last three steps, while the
simulation is running.

#align(center)[

  #let semi_gray = gray.transparentize(50%)

  #figure(
    cetz.canvas({
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

      content((-6, 2.05), "Initial density", anchor: "south")
      content((-2, 2.1), "Add sources", anchor: "south")
      content((2, 2.1), "Diffusion", anchor: "south")
      content((6, 2.1), "Advection", anchor: "south")
    }),

    caption: [Outline of the density solver.]
  )<fig:moving-density>
]

== Adding sources
Possibly the simplest step of the simulation is to add new sources to the
density field. For a rectangular grid this step can be simplified to a simple
matrix addition $rho_h + S_h$, where $rho_h$ is the density field on the
discretized domain, and $S_h$ is the matrix containing the sources at each grid
cell.

== Diffusion
During the diffusion step of the simulation we must solve the following equation
$
  (partial rho)/(partial t) = kappa Delta rho.
$

As mentioned before, instead of $partial rho \/ partial t$ we will use the
forward difference scheme, changing the problem as follows
$
  (rho_"next" - rho_"prev")/(Delta t) = kappa Delta rho_"prev"
$
#numbered_eq(
  $
    rho_"next" = rho_"prev" + (Delta t) kappa Delta rho_"prev".
  $
)<eq:helmholtz>

// The resulting @eq:helmholtz is a Helmholtz equation, of the form
// $
//   Delta u + lambda u = f.
// $

To solve this, we are going to employ the most intuitive method, known as the
finite difference method, where we think of the density moving outwards from
each cell to each of it's four neighbors, and density flowing in to it from
it's neighbors. @fig:5-point-stencil-intuition aids in visualizing the density
exchange between the neighboring cells.

#align(center)[

  #let semi_gray = gray.transparentize(50%)

  #figure(
    cetz.canvas({
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
    }),

    caption: [Five point density exchange intuition.]
  )<fig:5-point-stencil-intuition>
]


In a more formal sense, what this method does is it approximates the Laplacian
$Delta rho$ with two second order finite difference schemes as
$
  (Delta_h rho_h)_(i, j) = (rho_(i+1, j) + rho_(i-1, j) + rho_(i, j+1) + rho_(i, j-1) - 4rho_(i,j))/(h^2),
$
where $h$ is the mesh fineness, that is $h = 1/N$. We present an illustration
of the $Delta_h$ discrete Laplacian in @fig:5-point-stencil-matrix.

#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

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
    }),

    caption: [Discretization matrix of the Laplacian, where \
    #text(green)[*green*] $ = 4\/h^2$, #text(red)[*red*] $=-1\/h^2$,
    #text(orange)[*orange*] $=-1\/h^2$.]
  )<fig:5-point-stencil-matrix>
]

The previous discretization reduces @eq:helmholtz to a linear system of
equations of the form $A_h rho_h = f_h$.

There are many ways to solve linear systems of this form, each of which has
it's advantages and disadvantages. Since our goal is to simulate realistic
fluid behavior in real time, at the expense of exactness, we will opt to use an
iterative method, like the Gauss--Seidel method, which is fast but not exact.

Note, that we only mentioned the matrix of the discrete Laplacian. However,
must not forget about the linear part of @eq:helmholtz, but this can be easily
taken care of with a slight modification of the discretization matrix $A_h$.

For a more extensive treatment of the subject, the reader is advised to consult
section 2.2 of @karatsonelliptikus for deeper theoretical background, or
#link("https://github.com/leonardo-toffalini/fishy") for implementation
details.

== Advection
For the advection step, we must solve the following equation
$
  (partial rho)/(partial t) = - (bold(u) dot nabla) rho.
$
The tricky part with solving the advection step is that it is dependent on the
velocity field, thus one must think of something clever to handle this difficulty.

The following novel idea that @stam2023stable and @stam2003real present, is to
think about fluid particles moving along the velocity field. We must think of
our density grid as point masses centered at the middle of each cell, then
tracing said point masses along the velocity field. The problem with this
method, is that it will be unstable for certain parameters. However, we can fix
this issue by instead of tracing the particles forwards along the velocity, we
trace them back through time. This simply means that we trace back the origin of
each particle that ended up in the center of a grid cell. @fig:path-trace-back
provides visual understanding for the backwards path tracing.

After tracing back the possible locations where fluid particles could have come
from we might get a particle that came from not the exact center of a cell.
Remember, that we established that we shall think of the fluid as point masses
centered at the middle of the grid cells. If a particle came from not the exact
center then we must somehow give meaning to it too. In this case we will take
the linear interpolation of the four closest neighbors of where the particle
came from.

// Fluid simulation methods that solve a partial differential equation on a
// discretized space are called Eulerian, whereas methods that simulate fluids
// as a collection of interacting particles are called Lagrangian. For this reason
// this method is sometimes called a semi-Lagrangian method.
#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

      let step = 1
      let start = -3
      let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)
      grid((start, start), (-start, -start), step: step, stroke: 0.6pt)

      for i in values {
        for j in values {
          let y = i + step/2
          let x = j + step/2
          let u = y/4
          let v = -x/4
          circle((x, y), radius: 1.5pt, stroke: 0pt, fill: blue)
          line((x, y), (x + u, y + v),
            stroke: gray + 0.5pt,
            mark: (end: ">", scale: 0.6))
        }
      }

      let (a1, b1, c1) = ((-0.5, 2.5), (-1.7, 1.8), (-1.3, 2.6))
      let (a2, b2, c2) = ((-0.5, 1.5), (-1.4, 0.9), (-1.1, 1.6))
      let (a3, b3, c3) = ((-1.5, 1.5), (-2.1, 0.5), (-1.95, 1.3))

      let c = orange

      bezier(a1, b1, c1,
        stroke: c + 1.5pt,
        mark: (end: ">", scale: 0.6)
      )
      bezier(a2, b2, c2,
        stroke: c + 1.5pt,
        mark: (end: ">", scale: 0.6)
      )
      bezier(a3, b3, c3,
        stroke: c + 1.5pt,
        mark: (end: ">", scale: 0.6)
      )


    }),
    caption: [Tracing back the particle path along the velocity field.]
  )<fig:path-trace-back>
]
