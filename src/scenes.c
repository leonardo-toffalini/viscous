typedef struct {
  int N;
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
  params->scale = 3.0f;
  params->screenWidth = params->scale * (params->N + 2) + 2;
  params->screenHeight = params->scale * (params->N + 2) + 2;
  params->imgWidth = params->N + 2;
  params->imgHeight = params->N + 2;
  
  params->diff = 2e-4f;
  params->visc = 1e-4f;
  
  params->middle_source_value = 4.0f;
  params->source_radius = 2;
  
  params->initial_u_velocity = 0.2f;
  params->initial_v_velocity = 1.5f;
}

void setup_scene_high_diffusion(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-3f;
  params->middle_source_value = 6.0f;
}

void setup_scene_low_viscosity(SceneParams *params) {
  setup_scene_default(params);
  params->visc = 1e-5f;
  params->initial_u_velocity = 0.5f;
  params->initial_v_velocity = 2.0f;
}

void setup_scene_multiple_sources(SceneParams *params) {
  setup_scene_default(params);
  params->middle_source_value = 8.0f;
  params->source_radius = 1;
}

void setup_scene_turbulent(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 5e-4f;
  params->visc = 5e-5f;
  params->initial_u_velocity = 1.0f;
  params->initial_v_velocity = 3.0f;
  params->middle_source_value = 8.0f;
}

void setup_scene_smoke(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-5f;
  params->visc = 1e-6f;
  params->middle_source_value = 12.0f;
  params->initial_u_velocity = 0.0f;
  params->initial_v_velocity = -0.7f;
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
    case SCENE_MULTIPLE_SOURCES:
      setup_scene_multiple_sources(params);
      break;
    case SCENE_TURBULENT:
      setup_scene_turbulent(params);
      break;
    case SCENE_SMOKE:
      setup_scene_smoke(params);
      break;
    default:
      setup_scene_default(params);
      break;
  }
}
