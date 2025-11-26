#set text(font: "New Computer Modern Math")
#set page(numbering: "1")
#set heading(numbering: "1.")

#show math.equation.where(block: false): box
#set figure(gap: 1.5em)

#let numbered_eq(content) = math.equation(block: true, numbering: "(1)", content)

#let todo(body) = [#text(red)[*TODO*] #body]

#align(center)[
  #text(size: 25pt)[*Real time fluid dynamics*] \

  Toffalini Leonardo
]

#include "notation.typ"

#include "equations_of_fluids.typ"

#include "equations_for_fluid_sim.typ"

#include "simulating_fluids.typ"

#include "moving_densities.typ"

#include "evolving_velocities.typ"

#pagebreak()

#include "appendix.typ"

#pagebreak()

#bibliography("refs.bib", full: true)

