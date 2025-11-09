#import "@preview/thmbox:0.3.0": *
#import "@preview/lilaq:0.5.0" as lq
#import "@preview/cetz:0.4.2"
#show: thmbox-init()

#set text(font: "New Computer Modern Math")
#set page(numbering: "1")

#show math.equation.where(block: false): box

#let exercise-counter = counter("exercise")
#show: sectioned-counter(exercise-counter, level: 1)
#let exercise = exercise.with(counter: exercise-counter)

#let solution = proof.with(
  title: "Solution",
)

#let todo(body) = [#text(red)[*TODO*] #body]

#align(center)[
  #text(size: 25pt)[*Technical Report*] \

  Toffalini Leonardo
]

#text(red)[*FIRST DRAFT*] \ at first i will ramble on about anything, then i
will trim the fat

All the code can be found at #link("https://github.com/leonardo-toffalini/viscous")

= Notation
In this report we are going to heavily rely on differential operators, as this
project is about solving a partial differential equation. Thus, before delving
into the details of the main topic at hand, we shall quickly remind the reader
of the notations that the following sections rely on. For a more complete
introduction to the notations, we refer the reader to consult Besenyei,
Komornik, Simon: Parciális differenciál egyenletek 4.5.

Let $nabla$ (formally) represent the $(partial_1, partial_2, dots, partial_n)$
vector, where $n$ is always deduced by the context.

With the help of this vector we can define the _gradient_ of a field
as
$
  nabla u = (partial_1 u, partial_2 u, dots, partial_n u).
$

Moreover, as $nabla$ is a vector, we can apply vector operations to it to get different operations, such as

$
  u dot nabla = sum_(i=1)^n u_i partial_i
$
or
$
  (u dot nabla)u = sum_(i=1)^n u_i partial_i u.
$

The $Delta$ operator, called the *Laplace operator*, sometimes written as
$nabla dot nabla$ or $nabla^2$, acts as follows:
$
  nabla dot nabla u = Delta u = sum_(i=1)^n (partial_i u)^2.
$


= The equations of fluids
The advective form of the *Navier-Stokes equations* for an incompressible fluid
with uniform viscosity are as follows:

#set math.equation(numbering: "(1)")
$
  (partial bold(u))/(partial t) + (bold(u) dot nabla) bold(u) = nu Delta
bold(u) - 1/rho nabla p + 1/rho bold(f).
$<eq:navier-stokes>
#set math.equation(numbering: none)
where
- $bold(u)$ is the velocity vector field.
- $bold(f)$ is the external forces.
- $rho$ is the scalar density field.
- $p$ is the pressure field.
- $nu$ is the kinematic viscosity.

We will not go into the details of deriving the above equations, instead we
will just take it as granted that they truly formulate the evolving velocity of
a viscous incompressible fluid.

The intrigued reader may find satisfaction in exploring the derivation of the
above equations in Chorin, Marsden: A mathematical introduction to fluid
mechanics.

For some, that have not yet encountered the differential operators used in the
above formulation, we give a short summary:


Explanation of the different parts of @eq:navier-stokes:
$
  (partial bold(u))/(partial t) + overbrace((bold(u) dot nabla) bold(u),
  "Advection") = underbrace(nu Delta bold(u), "Diffusion") overbrace(- 1/rho
   nabla p, "Internal source") + underbrace(1/rho bold(f), "External source").
$

In broad strokes the parts can be described as follows:
1. Advection -- How the velocity moves.
2. Diffusion -- How the velocity spreads out.
3. Internal source -- How the velocity points towards parts of lesser pressure.
4. External source -- How the velocity is changed subject to external
   intervention, like a fan blowing air.


= Equations for fluid simulation
It is best to mention here, in this section, that the described method will not
be exact. This, however, will not be to our detriment, as our aim here is to
show interesting and realistic visuals as opposed to precise measurements
useful for engineering efforts.

For our purposes we will rearrange @eq:navier-stokes such that we have only the
time derivate of the velocity on the left and omit the internal force part, as
we will recover this part later. So we arrive at the equation which we will solve:

$
  (partial bold(u))/(partial t) = - (bold(u) dot nabla)bold(u) + nu Delta
bold(u) + 1/rho bold(f).
$

The evolving of the velocity field in and of itself is not that interesting to
see, because in real life we do not see the velocity field, we only see it's
effect. To provide a more stimulating visual experience we must let the
velocity field act upon a density field and in term visualize said density
field. We present the equation for the density field
$
  (partial rho)/(partial t) = -(bold(u) dot nabla)rho + kappa Delta rho + S.
$

The astute reader might find this equation quite similar to that of the
velocity field, which is by no means a coincidence as the same broad strokes apply
to the density field too, which are: advection, diffusion, and external sources.
The only thing we must be careful of, is that the density is a scalar field, in
contrast to the velocity, which is a vector field.

The partial differential equation by itself does not result in a unique
solution for us to find, for this we must also specify a boundary condition.
In our endeavor to simulate a fluid, we will work with the Dirichlet-boundary
condition, which prescribes that the values on the boundary must vanish. We can
formulate the previous statement as follows:
$
  u|_(partial Omega) &= 0 \
  rho|_(partial Omega) &= 0,
$
where $Omega$ represents the domain on which we are searching for the solution.

= Simulating fluids
The equations presented in the previous sections hold on the entire
$n$-dimensional space in which the fluid resides. However, when numerically
solving a partial differential equation one often discretizes the space into
small rectangles and only bothers to calculate the solution on these
rectangles. For our purposes we will confine ourselves to the $2$-dimensional
plane, but everything mentioned hereafter can be easily extended to higher
dimensions.

We will make another simplification, which is to only consider a rectangular
domain. This makes the calculations easier to handle as matrix operations,
however, one is free to extend the domain to more complex shapes by exercising
proper caution when handling the boundary. @fig:fluid-in-a-box shows a
schematic diagram of how one must imagine a grid on a rectangular domain.
Notice, how we introduced a $0$th and an $(N+1)$th row and column to handle
the boundary, this way it is clear that we will be simulating the fluid on an
$N times N$ grid on the inside.

#align(center)[
  #figure(

  cetz.canvas({
    import cetz.draw: *
    rect((-2.5, -2.5), (-2, 2.5), fill: gray, stroke: 0pt)
    rect((2.5, -2.5), (2, 2.5), fill: gray, stroke: 0pt)
    rect((-2.5, 2.5), (2.5, 2), fill: gray, stroke: 0pt)
    rect((-2.5, -2.5), (2.5, -2), fill: gray, stroke: 0pt)

    grid((-2.5, -2.5), (2.5, 2.5), step: 0.5, stroke: 0.3pt)
    line((-2, -2), (-2, 2))
    line((2, 2), (-2, 2))
    line((2, 2), (2, -2))
    line((-2, -2), (2, -2))

    for (x, cnt) in ((0, $0$), (1, $1$), (2, $2$)) {
      content((-2.25 + x/2, -2.6), cnt, anchor: "north")
      content((-2.6, -2.25 + x/2), cnt, anchor: "east")
    }
    content((2.25, -2.6), $N+1$, anchor: "north")
    content((0.25, -2.6), $dots$, anchor: "north")
    content((-2.6, 2.25), $N+1$, anchor: "east")
    content((-2.7, 0.25), $dots.v$, anchor: "east")

    content((0, 0), text(size: 16pt)[$Omega$])
    content((3, 0), text(size: 12pt)[$partial Omega$])
  }),

    caption: [Discretization of the rectangular domain.]
  )<fig:fluid-in-a-box>
]

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
#align(center)[

  #let semi_gray = gray.transparentize(50%)

  #figure(
    cetz.canvas({
      import cetz.draw: *

      rect((-1, -1), (1, 1), name: "middle")
      rect((-3, -1), (-1, 1), name: "left")
      rect((1, -1), (3, 1), name: "right")
      rect((-1, 1), (1, 3), name: "top")
      rect((-1, -3), (1, -1), name: "bottom")

      // cell index labels
      // content("middle", [$i, j$])
      // content("left", [$i, j-1$])
      // content("right", [$i, j+1$])
      // content("top", [$i-1, j$])
      // content("bottom", [$i+1, j$])

      // left <-> middle
      line((-2, -0.1), (-0.5, -0.1), stroke: gray, mark: (end: ">", scale: 0.5))
      line((-0.5, 0.1), (-2, 0.1), stroke: gray, mark: (end: ">", scale: 0.5))

      // right <-> middle
      line((2, -0.1), (0.5, -0.1), stroke: gray, mark: (end: ">", scale: 0.5))
      line((0.5, 0.1), (2, 0.1), stroke: gray, mark: (end: ">", scale: 0.5))

      // top <-> middle
      line((-0.1, 2), (-0.1, 0.5), stroke: gray, mark: (end: ">", scale: 0.5))
      line((0.1, 0.5), (0.1, 2), stroke: gray, mark: (end: ">", scale: 0.5))

      // bottom <-> middle
      line((-0.1, -2), (-0.1, -0.5), stroke: gray, mark: (end: ">", scale: 0.5))
      line((0.1, -0.5), (0.1, -2), stroke: gray, mark: (end: ">", scale: 0.5))
    }),

    caption: [Five point stencil intuition]
  )<fig:5-point-stencil-intuition>
]

In essence this is just a finite difference method of a five point stencil.

Here is the discretization matrix $A_h$ for this five point stencil.

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

    caption: [Five point stencil matrix]
  )<fig:5-point-stencil-matrix>
]

Let us denote the Kronecker product of two matrices as $A times.circle B$ and
let $B = "tridiag"(-1, 2, -1)$. Then, the above discretization matrix of the
five point stencil an be achieved with the following succinct formula: $I
times.circle B + B times.circle I$.

However, this matrix is so sparse, that we need not even construct it, as we
can just solve the resulting linear system of equations with an iterative
method without constructing the full matrix.

== Advection

Make it clear that this is the first crucial idea of the method. The idea is
that instead of the solving the advection equation as a partial differential
equation, we trace a path backwards to where a fluid particle could have come
from.

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
      // line(a2, c2, b2, stroke: gray + 1.5pt)
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
    caption: [Semi Lagrange]
  )<fig:semi-lagrange>
]

= Evolving velocities
Recall, that the velocity equation is almost the same as the density equation.

This is where the second novel idea comes into play. Remember in the second
section we mentioned that we shall omit a part of the equation to make it
simpler and handle it later, now is the time to do so. The part we left out
made sure that the velocity field was divergence free, meaning that it was mass
conserving. This is intuitive about fluids, that a fluid can not just fluid
outward from a single point, if some fluid flows out from a point, then an
equal amount must flow into said point.

Since we did not take care to hold the divergence free property during the
diffusion and advection steps we quite possible end up with a velocity field
which has non zero divergence. To combat this we rely on a result from vector
calculus which states that a vector field can be decomposed as a sum of a field
with no divergence and one which is the gradient of a scalar potential. This
result is called the Helmholtz--Hodge decomposition.

#include "hodge.typ"

The Helmholtz--Hodge decomposition states that any vector field $bold(w)$ can
be uniquely decomposed into the sum of a divergence field and a rotation field,
more concisely
$
  bold(w) = bold(u) + nabla q,
$
where $nabla dot (bold(u)) = 0$, and $q$ is a scalar field. @fig:hodge
illustrates the idea of the decomposition.

Formally taking the dot product with the $nabla$ operator of both sides, we get
$
  nabla dot bold(w) &= nabla dot bold(u) + nabla dot nabla q \
  nabla dot bold(w) &= 0 + nabla dot nabla q \
  nabla dot bold(w) &= Delta q
$

The relation between $bold(w)$ and $q$ we just derived is a simple Poisson
equation for $q$, which can be solved with the finite difference method we
outlined in the previous section. After solving for $q$, we can extract
$bold(u)$ as
$
  bold(u) = bold(w) - nabla q.
$

With this result in our hands we can finally resolve the mass conserving
property of the velocity of the simulated fluid by decomposing the resulting
field after the last step into a divergence free field.

One can then imagine the simulation steps as follows:
$
  u_1 -->^"add source" u_2 -->^"diffusion" u_3 -->^"advection" u_4 -->^"projection" u_5
$

#include "projection.typ"


