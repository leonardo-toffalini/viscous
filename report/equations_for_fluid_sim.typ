#import "@preview/cetz:0.4.2"

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
  (partial rho)/(partial t) = -(bold(u) dot nabla)rho + kappa Delta rho + S,
$
where $kappa$ is the diffusion coefficient of the fluid and $S$ is a scalar
field of external sources.

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

