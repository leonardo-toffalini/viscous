#import "@preview/cetz:0.4.2"

= Simulating fluids
The detailed methods are described in @stam2003real and @stam2023stable.

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

The equations, which we will be solving in our simulation are all of the form,
where the time dependent partial derivative of the field is on the left hand
side. To represent this time derivative of a field we will always keep two
fields for $rho$ and $bold(u)$, them being $rho_"prev", rho_"next"$ and
$bold(u)_"prev", bold(u)_"next"$. Then we will approximate the time derivative
with a simple forward difference scheme as
$
  (partial rho)/(partial t)  = (rho_"next" - rho_"prev")/(Delta t),
$
where $Delta t$ is the time between the two frames of the simulation, known as
the delta time. The notation is a bit confusing as we use $Delta$ for the
Laplacian too, but we believe the reader is conscious enough to see that $t$ is
a scalar value.

