#import "@preview/cetz:0.4.2"

// #align(center)[
//   #figure(
//     cetz.canvas({
//       import cetz.draw: *
//
//       // debug axis
//       // line((0,0), (2,1), stroke: green)
//       // line((0,0), (2,-1), stroke: red)
//       // line((0,0), (0,2), stroke: blue)
//
//       let scale = 0.25
//
//       let values = range(-3, 5)
//
//       for i in range(-4, 5) {
//         let x_off = 2 * i * scale
//         let y_off = -i * scale
//         line((-2 + x_off, -1 + y_off), (2 + x_off, 1 + y_off), stroke: 0.5pt + gray)
//       }
//
//       for i in range(-4, 5) {
//         let x_off = 2 * i * scale
//         let y_off = i * scale
//         line((-2 + x_off, 1 + y_off), (2 + x_off, -1 + y_off), stroke: 0.5pt + gray)
//       }
//
//
//       circle((-1, -1), radius: 1pt, fill: black, stroke: black)
//       content((-1, -1), [$u_1$], anchor: "north-west")
//
//       line((-1, -1), (-1.3, 0.01), stroke: (dash: "dotted"))
//
//       circle((-1.3, 0.01), radius: 1pt, fill: black, stroke: black)
//       content((-1.4, 0.01), [$u_2$], anchor: "south-east")
//
//       line((-1.3, 0.01), (-0.3, 0.55), stroke: (dash: "dotted"))
//
//       circle((-0.3, 0.55), radius: 1pt, fill: black, stroke: black)
//       content((-0.3, 0.6), [$u_3$], anchor: "south")
//
//       line((-0.3, 0.55), (2.3, 0.55), stroke: (dash: "dotted"))
//
//       circle((2.3, 0.55), radius: 1pt, fill: black, stroke: black)
//       content((2.3, 0.6), [$u_4$], anchor: "south")
//
//       line((2.3, 0.55), (2.3, -0.35), stroke: (dash: "dotted"))
//
//       circle((2.3, -0.35), radius: 1pt, fill: black, stroke: black)
//       content((2.3, -0.35), [$u_5$], anchor: "north")
//
//       line((-1, -1), (2.3, -0.35), stroke: red + 0.8pt, mark: (end: ">", scale: 0.5))
//
//       line((-2, -1), (2, 1),  stroke: 1.2pt, mark: (end: ">", scale: 0.3))
//       line((-2, 1),  (2, -1), stroke: 1.2pt, mark: (end: ">", scale: 0.3))
//       line((0, 0),   (0, 3),  stroke: 1.2pt, mark: (end: ">", scale: 0.3))
//
//     }),
//     caption: [Projection]
//   )<fig:proj>
// ]


#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

      let x_dir = (2, -1)
      let y_dir = (5, 0)
      let z_dir = (0, 3)

      let scale = 0.25

      let values = range(-3, 5)

      for i in range(-4, 5) {
        let start = (-y_dir.at(0), -y_dir.at(1))
        let end = (y_dir.at(0), y_dir.at(1))
        let x1 = start.at(0) + x_dir.at(0) * i * scale
        let y1 = start.at(1) + x_dir.at(1) * i * scale
        let x2 = end.at(0) + x_dir.at(0) * i * scale
        let y2 = end.at(1) + x_dir.at(1) * i * scale
        line((x1, y1), (x2, y2), stroke: 0.5pt + gray)
      }

      for i in range(-4, 5) {
        let start = (-x_dir.at(0), -x_dir.at(1))
        let end = (x_dir.at(0), x_dir.at(1))
        let x1 = start.at(0) + y_dir.at(0) * i * scale
        let y1 = start.at(1) + y_dir.at(1) * i * scale
        let x2 = end.at(0) + y_dir.at(0) * i * scale
        let y2 = end.at(1) + y_dir.at(1) * i * scale
        line((x1, y1), (x2, y2), stroke: 0.5pt + gray)
      }

      let points = ((-2.7,-0.5), (-3.2,1.5), (-0.5,2), (2, 1.8), (2, -0.3))
      let names = ($u_1$, $u_2$, $u_3$, $u_4$, $u_4$)

      for (pt1, pt2) in points.slice(0, points.len() - 1).zip(points.slice(1, points.len())) {
        line(pt1, pt2, stroke: (dash: "dotted"))
      }

      line(points.first(), points.last(), stroke: 0.8pt + red, mark: (end: ">", scale: 0.5))

      for (pt, name) in points.zip(names) {
        content(pt, name, anchor: "north-east")
        circle(pt, radius: 1pt, stroke: black, fill: black)
      }


      line((-y_dir.at(0), -y_dir.at(1)), y_dir, mark: (end: ">", scale: 0.5))
      line((-x_dir.at(0), -x_dir.at(1)), x_dir, mark: (end: ">", scale: 0.5))
      line((0,0), z_dir, mark: (end: ">", scale: 0.5))

      content((3.5, -0.5), text(size: 12pt)[$nabla dot u = 0$])

    }),
    caption: [Illustrative steps of the simulation.]
  )<fig:proj2>
]
