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

#text(red)[*FIRST DRAFT*]

#include "notation.typ"

#include "equations_of_fluids.typ"

#include "equations_for_fluid_sim.typ"

#include "simulating_fluids.typ"

#include "moving_densities.typ"

#include "evolving_velocities.typ"

#include "appendix.typ"

#pagebreak()

#bibliography("refs.bib")

