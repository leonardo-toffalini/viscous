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

#align(center)[
  #text(size: 25pt)[*Technical Report*] \

  Toffalini Leonardo
]

#text(red)[*FIRST DRAFT*] \ at first i will ramble on about anything, then i will trim the fat

All the code can be found at #link("https://github.com/leonardo-toffalini/viscous")

= Introduction to the equations of fluids
The advective form of the *Navier-Stokes equations* for an incompressible fluid
with uniform viscosity are as follows:

#set math.equation(numbering: "(1)")
$
  (partial bold(u))/(partial t) + (bold(u) dot nabla) bold(u) = nu Delta bold(u) - 1/rho nabla p + 1/rho bold(f).
$<eq:navier-stokes>
#set math.equation(numbering: none)

Meaning of the variables:
1. $bold(u)$ is the velocity vector field.
2. $bold(f)$ is the external forces.
3. $rho$ is the scalar density field.
4. $p$ is the pressure field.
5. $nu$ is the kinematic viscosity.

We will not go into the details of deriving the above equations, instead we
will just take it as granted that they truly formulate the evolving velocity of
a viscous incompressible fluid.


For some, that have not yet encountered the differential operators used in the
above formulation, we give a short summary:

The $nabla$ operator represents the vector $(partial_1, partial_2, dots, partial_n)$, thus
$
  nabla u = (partial_1 u, partial_2 u, dots, partial_n u)
$

$
  u dot nabla = sum_(i=1)^n u_i partial_i
$

$
  (u dot nabla)u = sum_(i=1)^n u_i partial_i u
$

The $Delta$ operator, called the *Laplace operator*, sometimes written as
$nabla dot nabla = nabla^2$, acts as follows:
$
  nabla dot nabla u = Delta u = sum_(i=1)^n (partial_i u)^2
$

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
4. External source -- How the velocity is changed subject to external intervention, like a fan blowin air.


= Equations for fluid simulation
It is best to mention here, in this section, that the described method is not exact.
This, however, will not be to our detriment, as our aim here is to show interesting and
realistic visuals as opposed to precise measurements.

For our purposes we will rearrange @eq:navier-stokes such that we have only the
time derivate of the velocity on the left and omit the internal force part, as
we will recover this part later. So we arrive at the equation which we will solve:

$
  (partial bold(u))/(partial t) = - (bold(u) dot nabla)bold(u) + nu Delta bold(u) + 1/rho bold(f).
$

The evolving of the velocity field in and of itself is not that interesting to
see, because in real life we do not see the velocity field, we only see it's
effect. To provide a more stimulating visual experience we must let the
velocity field act upon a density field and in term visualize said density
field. We present the equation for the density field
$
  (partial rho)/(partial t) = -(bold(u) dot nabla)rho + kappa Delta rho + S.
$

The astute reader might find this equation offly similar to that of the
velocity field, which is by no means a coincidence as the same broad strokes apply
to the density field too, which are: advection, diffusion, and external sources.
The only thing we must be careful of, is that the density is a scalar field, in
contrast to the velocity, which is a vector field.

The problem in this state is incomplete, we must also specify a boundary
condtion. In our endevour to simulate a fluid, we will work with the
Dirichlet-boundary condition, which prescribes that the values on the boundary
must vanish. We can formulate the previous statement as follows:
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
rectangles. For our purposes we will confine ourselves to the $2$-dimensianal
plane, but everything mentioned hereafter can be easily extended to higher
dimensions.

We will make another simplification, which is to only consider a rectangulare
domain. This makes the calculations easier to handle as matrix operations,
however, one is free to extend the domain to more complex shapes by exercising
proper caution when handling the boundary. @fig:fluid-in-a-box shows a
schematic diagram of how one must imagine a grid on a rectangular domain.
Notice, how we introduced a $0$-th and an $(N+1)$-th row and column to handle
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

    caption: [Discretization of the domain.]
  )<fig:fluid-in-a-box>
]

As mentioned in the previous sections, to simulate the change in time of both
the velocity and the density, we must simulate three steps: advection,
diffusion, and external sources.

= Moving densities

In our simulation, we will solve the parts of the simplyfied Navier-Stokes
equations for the density field one by one. Starting with the simplest, adding
additional density, then diffusion, and lastly advectiong. The simulation steps
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


