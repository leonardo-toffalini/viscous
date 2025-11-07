#import "@preview/cetz:0.4.2"

#align(center)[
  #figure(
    cetz.canvas({
      import cetz.draw: *

      let step = 0.3
      let start = -3
      let field_scale = 0.2
      let zoom = 0.5
      let values = range(0, int(2 * calc.abs(start) / step)).map(x => start + x * step)

      let rot_u(x, y, field_scale) = {calc.sin(y + calc.sin(x)) * field_scale}
      let rot_v(x, y, field_scale) = {-calc.sin(x + calc.sin(y)) * field_scale}
      let div_u(x, y, field_scale) = {calc.sin(x) * calc.cos(y) * field_scale * 0.6}
      let div_v(x, y, field_scale) = {calc.cos(x) * calc.sin(y) * field_scale * 0.6}
      let div_u_vis(x, y, field_scale) = {calc.sin(x) * calc.cos(y) * field_scale * 1.6}
      let div_v_vis(x, y, field_scale) = {calc.cos(x) * calc.sin(y) * field_scale * 1.6}
      let comb_u(x, y, field_scale) = {rot_u(x, y, field_scale) + div_u(x, y, field_scale)}
      let comb_v(x, y, field_scale) = {rot_v(x, y, field_scale) + div_v(x, y, field_scale)}

      let quiver(start_x, start_y, size, step, f_u, f_v) = {
        let values = range(0, int(size / step)).map(x => -size/2 + x * step)
        for i in values {
          for j in values {
          let cell_y = i + step/2
          let cell_x = j + step/2
          let y = cell_y / zoom
          let x = cell_x / zoom
          let u = f_u(x, y, field_scale)
          let v = f_v(x, y, field_scale)

          let pos_x = cell_x + size/2 + start_x
          let pos_y = cell_y

          // debug circles at the cell middle
          // circle((pos_x, pos_y), radius: 1.5pt, stroke: red)

          line((pos_x, pos_y), (pos_x + u, pos_y + v),
            stroke: black + 0.6pt,
            mark: (end: ">", scale: 0.2))

          }
        }
        rect((start_x, start_y), (start_x + size, start_y + size), stroke: 0.1pt)
      }

      let size = 4
      quiver(-8, -2, size, step, comb_u, comb_v)
      quiver(-2, -2, size, step, rot_u, rot_v)
      quiver(4, -2, size, step, div_u_vis, div_v_vis)

      content((-6, 2.1), [combined field], anchor: "south")
      content((0, 2.1), [rotation field], anchor: "south")
      content((6, 2.02), [divergence field], anchor: "south")
      content((-3, 0), text(size: 16pt)[$=$])
      content((3, 0), text(size: 16pt)[$+$])

    }),
    caption: [Helmholtz--Hodge decomposition]
  )<fig:hodge>
]

