#import "@preview/cetz:0.4.2"

= Evolving velocities
Recall, that the velocity equation is almost the same as the density equation,
thus, the method is almost complete as we can apply the previous diffusion and
advection steps to the velocity field too. However, we need to recover the
*internal source* part of the velocity equation, which we omitted in the second
section.

This is where the second novel idea comes into play. The part we left out made
sure that the velocity field was divergence free, that is $nabla dot u = 0$,
meaning that the velocity field was mass conserving. This is intuitive for
incompressible fluids, that if some fluid flows in to a point, then an
equal amount must flow out from that point.

Since we did not take care to hold the divergence free property during the
diffusion and advection steps we quite possibly ended up with a velocity field
which has non zero divergence. To combat this we rely on a result called the
Helmholtz--Hodge decomposition from vector calculus, which states that a vector
field can be decomposed as a sum of a field with no divergence and one which is
the gradient of a scalar potential.

Formally, the Helmholtz--Hodge decomposition states that any vector field $bold(w)$ can
be uniquely decomposed into the sum of a divergence field $nabla q$ and a
rotation field $bold(u)$, more concisely
$
  bold(w) = bold(u) + nabla q,
$
where $nabla dot bold(u) = 0$, and $q$ is a scalar field. @fig:hodge
illustrates the idea of the decomposition.

Finding such a decomposition is almost as simple as stating the result, we only
need to take the dot product with the $nabla$ operator of both sides, to get
$
  nabla dot bold(w) &= nabla dot bold(u) + nabla dot nabla q \
  nabla dot bold(w) &= 0 + nabla dot nabla q \
  nabla dot bold(w) &= Delta q.
$

Since $bold(w)$ is known to us, we can calculate it's divergence, making the
left hand side some fixed value. Thus, the relation between $bold(w)$ and $q$
we just derived is a simple Poisson equation for $q$, which can be solved with
the finite difference method we outlined in the diffusion section. After
solving for $q$, we can extract $bold(u)$ as
$
  bold(u) = bold(w) - nabla q.
$

#include "hodge.typ"

With this result in our hands we can finally resolve the mass conserving
property of the velocity of the simulated fluid by decomposing the resulting
field after the last step into a divergence free field.

In summary, one can then imagine the simulation steps for the velocity field as follows:
$
  u_1 -->^"add source" u_2 -->^"diffusion" u_3 -->^"advection" u_4 -->^"projection" u_5
$

#include "projection.typ"

