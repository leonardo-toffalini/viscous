= Notation
In this report we are going to heavily rely on differential operators, as this
project is about solving a partial differential equation. Thus, before delving
into the details of the main topic at hand, we shall quickly remind the reader
of the notations that the following sections use. For a more complete
introduction to the notations, we refer the reader to consult
@besenyei2013parcialis.

Let $nabla$ (formally) represent the $(partial_1, partial_2, dots, partial_n)$
vector, where $n$ is always deduced by the context the operator is used in.
With the help of this vector we can define the usual gradient of a field as
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
$nabla dot nabla$ or $nabla^2$, is defined as
$
  nabla dot nabla u = Delta u = sum_(i=1)^n (partial_i u)^2.
$
