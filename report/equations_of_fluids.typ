#import "@preview/cetz:0.4.2"

= The equations of fluids
The advective form of the *Navier-Stokes equations* for an incompressible fluid
with uniform viscosity are as follows:

#set math.equation(numbering: "(1)")
$
  (partial bold(u))/(partial t) + (bold(u) dot nabla) bold(u) &= nu Delta
  bold(u) - 1/rho nabla p + 1/rho bold(f) \
  nabla dot u &= 0
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

For us to later simulate @eq:navier-stokes we need to understand what each part
is responsible for.
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

The intrigued reader may find satisfaction in exploring the derivation of the
above equations in @chorin1990mathematical.

