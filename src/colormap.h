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
} Colormap;

void get_cmap(Colormap cmap, char *cmap_buf) {
  switch (cmap) {
  case GRAYS:
    sprintf(cmap_buf, "src/shaders/grayscale.frag");
    break;
  case HOTCOLD:
    sprintf(cmap_buf, "src/shaders/hot_cold.frag");
    break;
  case PLASMA:
    sprintf(cmap_buf, "src/shaders/plasma.frag");
    break;
  case MAGMA:
    sprintf(cmap_buf, "src/shaders/magma.frag");
    break;
  case INFERNO:
    sprintf(cmap_buf, "src/shaders/inferno.frag");
    break;
  case VIRIDIS:
    sprintf(cmap_buf, "src/shaders/viridis.frag");
    break;
  case GNBU:
    sprintf(cmap_buf, "src/shaders/gnbu.frag");
    break;
  case APPLE:
    sprintf(cmap_buf, "src/shaders/apple.frag");
    break;
  default:
    sprintf(cmap_buf, "src/shaders/viridis.frag");
    break;
  }
}

#endif // !COLORMAP_H
