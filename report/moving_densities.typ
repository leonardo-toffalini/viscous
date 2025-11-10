#import "@preview/cetz:0.4.2"

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

    caption: [Rough outline of the density solver]
  )<fig:moving-density>
]

== Adding sources
Possibly the simplest step of the simulation is to add new sources to the
density field, or to the velocity field for that matter. For a rectangular grid
this step can be simplified to a simple matrix addition $rho_h + S_h$, where
$rho_h$ is the density field on the discretized domain, and $S_h$ is the matrix
containing the sources at each grid cell.

== Diffusion
The diffusion step boils down to solving the simple Poisson equation
$
  (partial rho)/(partial t) = kappa Delta rho.
$

To solve this, we are going to employ the most intuitive method, known as the
finite difference method, where we think of the density moving outwards from
each cell to each of it's four neighbors, and density flowing in to it from
it's neighbors. @fig:5-point-stencil-matrix aids in visualizing the density
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
      line((-2, -0.1), (-0.5, -0.1), stroke: semi_red, mark: (end: ">", scale: 0.5))
      line((-0.5, 0.1), (-2, 0.1), stroke: semi_blue, mark: (end: ">", scale: 0.5))

      // right <-> middle
      line((2, -0.1), (0.5, -0.1), stroke: semi_red, mark: (end: ">", scale: 0.5))
      line((0.5, 0.1), (2, 0.1), stroke: semi_blue, mark: (end: ">", scale: 0.5))

      // top <-> middle
      line((-0.1, 2), (-0.1, 0.5), stroke: semi_red, mark: (end: ">", scale: 0.5))
      line((0.1, 0.5), (0.1, 2), stroke: semi_blue, mark: (end: ">", scale: 0.5))

      // bottom <-> middle
      line((-0.1, -2), (-0.1, -0.5), stroke: semi_red, mark: (end: ">", scale: 0.5))
      line((0.1, -0.5), (0.1, -2), stroke: semi_blue, mark: (end: ">", scale: 0.5))
    }),

    caption: [Five point stencil intuition]
  )<fig:5-point-stencil-intuition>
]

In numerical methods for partial differential equations theory this method is
often called a five point stencil finite difference method.

In a more mathematical sense, what this method does is it approximates the Laplacian $Delta u$ with two second order finite difference schemes, formally
$
  (Delta_h rho_h)_(i, j) = (rho_(i+1, j) + rho_(i-1, j) + rho_(i, j+1) + rho_(i, j-1) - 4rho_(i,j))/(h^2),
$
where $h$ is the mesh fineness, that is $h = 1/N$.

The above equations for $i$ and $j$ indices define a linear system of equations
$A_h rho_h = f_h$, where $A_h$ is the discretization of the Laplacian and $f_h$
is the right hand side of the original Poisson equation restricted on the
$h$-fine grid.

To solve a linear system of equations one can solve it exactly with various
approaches, however, this will not suffice for us, as all the exact methods are
too slow for our needs. One can prove sufficient properties of the
discretization matrix that imply that an iterative method, such as
Gauss--Seidel will converge rapidly to the exact solution, saving us precious
time at the cost of exactness. We present an illustration of the $A_h$ discretization matrix in @fig:5-point-stencil-matrix

#align(center)[

  #figure(
    cetz.canvas({
      import cetz.draw: *

      content((-5.3, 4), anchor: "east", [$n$])
      content((-4, 5.3), anchor: "south", [$n$])

      rect((-5, -5), (5, 5))
      rect((-5, 5), (-3, 3), name: "topleft")
      line((-4.95, 4.95), (-3.05, 3.05), stroke: 2pt + green)
      line((-4.75, 4.95), (-3.05, 3.25), stroke: 2pt + red)
      line((-4.95, 4.75), (-3.25, 3.05), stroke: 2pt + red)
      line((-4.95, 2.95), (-3.05, 1.05), stroke: 2pt + orange)

      rect((-3, 3), (-1, 1))
      line((-2.95, 2.95), (-1.05, 1.05), stroke: 2pt + green)
      line((-2.75, 2.95), (-1.05, 1.25), stroke: 2pt + red)
      line((-2.95, 2.75), (-1.25, 1.05), stroke: 2pt + red)
      line((-2.95, 0.95), (-1.05, -0.95), stroke: 2pt + orange)
      line((-2.95, 4.95), (-1.05, 3.05), stroke: 2pt + orange)

      rect((-1, 1), (1, -1))
      line((-0.95, 0.95), (0.95, -0.95), stroke: 2pt + green)
      line((-0.75, 0.95), (0.95, -0.75), stroke: 2pt + red)
      line((-0.95, 0.75), (0.75, -0.95), stroke: 2pt + red)
      line((-0.95, 0.95 - 2), (0.95, -0.95 - 2), stroke: 2pt + orange)
      line((-0.95, 0.95 + 2), (0.95, -0.95 + 2), stroke: 2pt + orange)

      rect((1, -1), (3, -3))
      line((1.05, -1.05), (2.95, -2.95), stroke: 2pt + green)
      line((1.25, -1.05), (2.95, -2.75), stroke: 2pt + red)
      line((1.05, -1.25), (2.75, -2.95), stroke: 2pt + red)
      line((1.05, -1.05 - 2), (2.95, -2.95 - 2), stroke: 2pt + orange)
      line((1.05, -1.05 + 2), (2.95, -2.95 + 2), stroke: 2pt + orange)

      rect((3, -3), (5, -5))
      line((3.05, -3.05), (4.95, -4.95), stroke: 2pt + green)
      line((3.25, -3.05), (4.95, -4.75), stroke: 2pt + red)
      line((3.05, -3.25), (4.75, -4.95), stroke: 2pt + red)
      line((3.05, -3.05 + 2), (4.95, -4.95 + 2), stroke: 2pt + orange)

    }),

    caption: [Five point stencil matrix, where #text(green)[green] $ = 4\/h^2$, #text(red)[red] $=-1\/h^2$, #text(orange)[orange] $=-1\/h^2$]
  )<fig:5-point-stencil-matrix>
]

Let us denote the Kronecker product of two matrices as $A times.circle B$ and
let $B = "tridiag"(-1, 2, -1)$. Then, the above discretization matrix of the
five point stencil an be achieved with the following succinct formula: $I
times.circle B + B times.circle I$.

However, this matrix is so sparse, that we need not even construct it, as we
can just solve the resulting linear system of equations with an iterative
method without constructing the full matrix.

For a more extensive treatment of the subject, the reader is advised to consult
section 2.2 of @karatsonelliptikus.

== Advection

#text(red)[*TODO*] Make it clear that this is the first crucial idea of the
method. The idea is that instead of the solving the advection equation as a
partial differential equation, we trace a path backwards to where a fluid
particle could have come from.

The problem with solving the advection equation is that it is dependent on the
velocity vector, in contrast to the diffusion step where it was only dependent
on the previous state of the density field.

After tracing back the possible locations where fluid particles could have come
from we might get a particle that came from not the exact center of a grid.
Remember, that we established that we shall think of the fluid as point masses
centered at the middle of the grid cells. If a particle came from not the dead
center then we must somehow give meaning to it too. In this case we will take
the linear interpolation of the four closes neighbors of where the particle
came from.

Fluid simulations methods that solve a partial differential equation on a
discretized space are called Lagrangian, whereas methods that simulate fluids
as a collection of particles are called Eulerian. For this reason this method
is sometimes called semi-Lagrangian.

#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

      let step = 1
      let start = -3
      let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)
      grid((start, start), (-start, -start), step: step)

      for i in values {
        for j in values {
          let y = i + step/2
          let x = j + step/2
          let u = y/4
          let v = -x/4
          line((x, y), (x + u, y + v),
            stroke: gray + 0.4pt,
            mark: (end: ">", scale: 0.6))
        }
      }

      let (a1, b1, c1) = ((-0.5, 2.5), (-1.7, 1.8), (-1.3, 2.6))
      let (a2, b2, c2) = ((-0.5, 1.5), (-1.4, 0.9), (-1.1, 1.6))
      let (a3, b3, c3) = ((-1.5, 1.5), (-2.1, 0.5), (-1.95, 1.3))

      bezier(a1, b1, c1,
        stroke: black + 1.5pt,
        mark: (start: "o", end: ">", scale: 0.6)
      )
      bezier(a2, b2, c2,
        stroke: black + 1.5pt,
        mark: (start: "o", end: ">", scale: 0.6)
      )
      bezier(a3, b3, c3,
        stroke: black + 1.5pt,
        mark: (start: "o", end: ">", scale: 0.6)
      )


    }),
    caption: [Tracing back the particle path along the velocity field]
  )<fig:path-trace-back>
]
