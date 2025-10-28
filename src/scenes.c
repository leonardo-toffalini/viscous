#ifdef SINGLE_TU

typedef enum {
  SCENE_DEFAULT = 0,
  SCENE_HIGH_DIFFUSION = 1,
  SCENE_LOW_VISCOSITY = 2,
  SCENE_TURBULENT = 3,
  SCENE_SMOKE = 4,
  SCENE_EMPTY = 5,
  SCENE_RAYLEIGH_BENARD_CONVECTION = 6, // https://en.wikipedia.org/wiki/Rayleigh%E2%80%93B%C3%A9nard_convection
  SCENE_COUNT
} SceneType;

  const char* scene_names[] = {
    "Default",
    "High Diffusion",
    "Low Viscosity",
    "Turbulent",
    "Smoke",
    "Empty",
    "R-B convection",
  };

typedef struct {
  int N;
  int rows;
  int cols;
  float scale;
  int screenWidth;
  int screenHeight;
  int imgWidth;
  int imgHeight;
  float diff;
  float visc;
  float middle_source_value;
  float source_radius;
  float initial_u_velocity;
  float initial_v_velocity;
  SceneType current_scene;
} SceneParams;

void setup_scene_default(SceneParams *params) {
  params->N = N_;
  params->rows = ROWS;
  params->cols = COLS;
  params->scale = 3.0f;
  params->screenWidth = params->scale * (params->N + 2) + 2;
  params->screenHeight = params->scale * (params->N + 2) + 2;
  params->imgWidth = params->N + 2;
  params->imgHeight = params->N + 2;
  
  params->diff = 2e-4f;
  params->visc = 1e-4f;
  
  params->middle_source_value = 4.0f;
  params->source_radius = 2;
  
  params->initial_u_velocity = 1.5f;
  params->initial_v_velocity = 0.2f;
}

void setup_scene_high_diffusion(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-3f;
  params->middle_source_value = 6.0f;
}

void setup_scene_low_viscosity(SceneParams *params) {
  setup_scene_default(params);
  params->visc = 1e-5f;
  params->initial_u_velocity = 2.0f;
  params->initial_v_velocity = 0.5f;
}

void setup_scene_turbulent(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 5e-4f;
  params->visc = 5e-5f;
  params->initial_u_velocity = 3.0f;
  params->initial_v_velocity = 1.0f;
  params->middle_source_value = 8.0f;
}

void setup_scene_smoke(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-5f;
  params->visc = 1e-7f;
  params->middle_source_value = 15.0f;
  params->initial_u_velocity = -0.25f;
  params->initial_v_velocity = 0.f;
}

void setup_scene_empty(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-5f;
  params->visc = 1e-6f;
  params->middle_source_value = 0.0f;
  params->initial_u_velocity = 0.0f;
  params->initial_v_velocity = 0.0f;
}

void setup_scene(SceneParams *params, SceneType scene_type) {
  params->current_scene = scene_type;
  
  switch (scene_type) {
    case SCENE_DEFAULT:
      setup_scene_default(params);
      break;
    case SCENE_HIGH_DIFFUSION:
      setup_scene_high_diffusion(params);
      break;
    case SCENE_LOW_VISCOSITY:
      setup_scene_low_viscosity(params);
      break;
    case SCENE_TURBULENT:
      setup_scene_turbulent(params);
      break;
    case SCENE_SMOKE:
      setup_scene_smoke(params);
      break;
    case SCENE_EMPTY:
      setup_scene_empty(params);
      break;
    case SCENE_RAYLEIGH_BENARD_CONVECTION:
      setup_scene_empty(params);
      break;
    default:
      setup_scene_default(params);
      break;
  }
}

#endif
