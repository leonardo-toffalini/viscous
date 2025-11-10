#import "@preview/cetz:0.4.2"

= Evolving velocities
#text(red)[*TODO*] Make it clear that this is the second crucial idea of the
method.

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

