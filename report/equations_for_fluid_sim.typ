#import "@preview/cetz:0.4.2"

= Equations for fluid simulation
It is best to mention here, that the described method will not be exact. This,
however, will not be to our detriment, as our aim here is to show interesting
and realistic visuals as opposed to precise measurements useful for engineering
efforts.

For our purposes we will rearrange @eq:navier-stokes such that we have only the
time derivate of the velocity on the left, and omit the internal force part, as
we will recover it later. So we arrive at the equation which we will solve:

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
velocity field, which is by no means a coincidence, as the derivation of the
density equation follows from the same physical laws, that resulted in the
velocity equation. The only part that we must be mindful of, is that the
density field's advection is dependent on the velocity field.

The previous system of partial differential equations by itself does not result in a unique
solution for us to find, for this we must also specify a boundary condition.
In our endeavor to simulate a fluid, we will work with the homogenous Neumann boundary
condition, which prescribes that the normal derivatives on the boundary must vanish. We can
formulate the previous statement as follows:
$
  partial_nu u|_(partial Omega) &= 0
$
where $Omega$ represents the domain on which we are searching for the solution.
Simply meaning that the fluid must not escape the domain.

