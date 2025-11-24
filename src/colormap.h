#ifndef COLORMAP_H
#define COLORMAP_H

typedef enum {
  GRAYS = 0,
  HOTCOLD,
  PLASMA,
  MAGMA,
  INFERNO,
  VIRIDIS,
  GNBU,
  APPLE,
  FAKE_PARULA,
} Colormap;

typedef struct {
  float r, g, b;
} vec3;

#include "colormaps/gnbu.h"
#include "colormaps/inferno.h"
#include "colormaps/magma.h"
#include "colormaps/plasma.h"
#include "colormaps/viridis.h"
#include "colormaps/hot_cold.h"
#include "colormaps/apple.h"
#include "colormaps/fake_parula.h"

vec3 get_color(double v, double vmin, double vmax) {
  vec3 c = {1.0, 1.0, 1.0};
  double dv = vmax - vmin;
  v = fmin(fmax(v, vmin), vmax);

  if (v < (vmin + 0.25 * dv)) {
     c.r = 0;
     c.g = 4 * (v - vmin) / dv;
  } else if (v < (vmin + 0.5 * dv)) {
     c.r = 0;
     c.b = 1 + 4 * (vmin + 0.25 * dv - v) / dv;
  } else if (v < (vmin + 0.75 * dv)) {
     c.r = 4 * (v - vmin - 0.5 * dv) / dv;
     c.b = 0;
  } else {
     c.g = 1 + 4 * (vmin + 0.75 * dv - v) / dv;
     c.b = 0;
  }

  return c;
}

const vec3 grayscale_colors[2] = {
  (vec3){0.0f, 0.0f, 0.0f},
  (vec3){1.0f, 1.0f, 1.0f},
};

void get_colormap(Colormap cmap, const vec3 **colormap, int *colormap_size, int *reversed) {
  switch (cmap) {
  case GNBU:
    *colormap = gnbu_colors;
    *colormap_size = 9;
    *reversed = 1;
    break;
  case MAGMA:
    *colormap = magma_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  case PLASMA:
    *colormap = plasma_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  case INFERNO:
    *colormap = inferno_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  case HOTCOLD:
    *colormap = hot_cold_colors;
    *colormap_size = 5;
    *reversed = 0;
    break;
  case GRAYS:
    *colormap = grayscale_colors;
    *colormap_size = 2;
    *reversed = 0;
    break;
  case APPLE:
    *colormap = apple_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  case FAKE_PARULA:
    *colormap = fake_parula_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  default:
  case VIRIDIS:
    *colormap = viridis_colors;
    *colormap_size = 256;
    *reversed = 0;
    break;
  }
}

#endif // !COLORMAP_H
