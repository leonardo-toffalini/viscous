#import "@preview/cetz:0.4.2"

#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

      // debug axis
      // line((0,0), (2,1), stroke: green)
      // line((0,0), (2,-1), stroke: red)
      // line((0,0), (0,2), stroke: blue)


      let scale = 0.25

      let values = range(-3, 5)

      for i in range(-4, 5) {
        let x_off = 2 * i * scale
        let y_off = -i * scale
        line((-2 + x_off, -1 + y_off), (2 + x_off, 1 + y_off), stroke: 0.5pt + gray)
      }

      for i in range(-4, 5) {
        let x_off = 2 * i * scale
        let y_off = i * scale
        line((-2 + x_off, 1 + y_off), (2 + x_off, -1 + y_off), stroke: 0.5pt + gray)
      }


      circle((-1, -1), radius: 1pt, fill: black, stroke: black)
      content((-1, -1), [$u_1$], anchor: "north-west")

      line((-1, -1), (-1.3, 0.01), stroke: (dash: "dotted"))

      circle((-1.3, 0.01), radius: 1pt, fill: black, stroke: black)
      content((-1.4, 0.01), [$u_2$], anchor: "south-east")

      line((-1.3, 0.01), (-0.3, 0.55), stroke: (dash: "dotted"))

      circle((-0.3, 0.55), radius: 1pt, fill: black, stroke: black)
      content((-0.3, 0.6), [$u_3$], anchor: "south")

      line((-0.3, 0.55), (2.3, 0.55), stroke: (dash: "dotted"))

      circle((2.3, 0.55), radius: 1pt, fill: black, stroke: black)
      content((2.3, 0.6), [$u_4$], anchor: "south")

      line((2.3, 0.55), (2.3, -0.35), stroke: (dash: "dotted"))

      circle((2.3, -0.35), radius: 1pt, fill: black, stroke: black)
      content((2.3, -0.35), [$u_5$], anchor: "north")

      line((-1, -1), (2.3, -0.35), stroke: red + 0.8pt, mark: (end: ">", scale: 0.5))

      line((-2, -1), (2, 1),  stroke: 1.2pt, mark: (end: ">", scale: 0.3))
      line((-2, 1),  (2, -1), stroke: 1.2pt, mark: (end: ">", scale: 0.3))
      line((0, 0),   (0, 3),  stroke: 1.2pt, mark: (end: ">", scale: 0.3))
    }),
    caption: [Projection]
  )<fig:proj>
]

