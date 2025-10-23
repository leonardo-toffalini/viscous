#include "raylib.h"
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define N_ 200
#define SIZE_ ((N_+2)*(N_+2))
#define IX(i, j) ((i)+(N_+2)*(j))
#ifndef SWAP
#define SWAP(x0, x) {float *tmp=x0; x0=x; x=tmp;}
#endif

typedef enum {
  SCENE_DEFAULT = 0,
  SCENE_HIGH_DIFFUSION = 1,
  SCENE_LOW_VISCOSITY = 2,
  SCENE_MULTIPLE_SOURCES = 3,
  SCENE_TURBULENT = 4,
  SCENE_SMOKE = 5,
  SCENE_COUNT
} SceneType;

// Scene selection - change this to switch scenes
#define SELECTED_SCENE SCENE_SMOKE

// TODO:
// - add a switch such that if someone is running without nvidia gpu the computations default to cpu
// - implement jacobi iteration in cuda
// - implement advect in cuda
// - add ui input
// - probably should do something about the possibility when there are less threads than cells in the array

// implemented in src/kernels.cu
extern void scalar_multiplier(float *A, size_t rows, size_t cols, float c);
extern void mat_add(float *A_h, float *B_h, size_t rows, size_t cols, float dt);
extern void diffuse_bad_host(float *A_h, float *B_h, size_t rows, size_t cols, float a);
extern void set_bnd_host(float *A_h, size_t rows, size_t cols, int b);
extern void diffuse_jacobi_host(float *A_h, const float *B_h, size_t rows, size_t cols, int b, const float a);

void add_source(int N, float *x, float *s, float dt) {
  mat_add(x, s, N+2, N+2, dt);
}

void set_bnd(int N, int b, float *x) {
  // the CPU version is faster as the GPU version requires copying the array on to the GPUs global memory,
  // and it does not offset the computational benefit
  int set_bnd_type = 1;

  switch (set_bnd_type) {
    // gpu
    case 0:
      set_bnd_host(x, N+2, N+2, b);
      break;

    // cpu
    case 1:
    default:
      for (int i = 1; i <= N; i++) {
        x[IX(0,   i  )] = b == 1 ? -x[IX(1, i)] :x[IX(1, i)];
        x[IX(N+1, i  )] = b == 1 ? -x[IX(N, i)] :x[IX(N, i)];
        x[IX(i,   0  )] = b == 2 ? -x[IX(i, 1)] :x[IX(i, 1)];
        x[IX(i,   N+1)] = b == 2 ? -x[IX(i, N)] :x[IX(i, N)];
      }
      x[IX(0,   0  )] = 0.5f * (x[IX(1,   0)] + x[IX(0,   1)]);
      x[IX(0,   N+1)] = 0.5f * (x[IX(1, N+1)] + x[IX(0,   N)]);
      x[IX(N+1, 0  )] = 0.5f * (x[IX(N,   0)] + x[IX(N+1, 1)]);
      x[IX(N+1, N+1)] = 0.5f * (x[IX(N, N+1)] + x[IX(N+1, N)]);
      break;
  }
}

void diffuse_bad(int N, int b, float *x, float *x0, float diff, float dt) {
  float a = dt * diff * N * N;

  diffuse_bad_host(x, x0, N+2, N+2, a);
  set_bnd(N, b, x);
}

void diffuse_jacobi(int N, int b, float *x, const float *x0, float diff, float dt) {
  const float a = dt * diff * N * N;

  // the gpu version is magnitudes faster than the cpu version
  // for the gpu version the iteration number k does not change the fps that much
  // while for the cpu version, increasing k, the fps quickly drops
  int diffuse_jacobi_type = 0;

  switch (diffuse_jacobi_type) {
    // gpu
    case 0:
      diffuse_jacobi_host(x, x0, N+2, N+2, b, a);
      break;

    // cpu
    case 1:
    default:
      const int size = (N + 2) * (N + 2);

      float *x_new = (float*)malloc(size * sizeof(float));

      float *cur   = x;      // read buffer (k-th iterate)
      float *next  = x_new;  // write buffer (k+1-th iterate)

      for (int k = 0; k < 20; ++k) {
        for (int i = 1; i <= N; ++i) {
          for (int j = 1; j <= N; ++j) {
            next[IX(i,j)] = (x0[IX(i,j)] + a * (cur[IX(i-1,j)] + cur[IX(i+1,j)] + cur[IX(i,j-1)] + cur[IX(i,j+1)])) / (1.0f + 4.0f * a);
          }
        }
        set_bnd(N, b, next);

        // swap read/write roles for next iteration
        SWAP(cur, next);
      }

      // make sure result ends up in the caller's x buffer
      if (cur != x) {
        memcpy(x, cur, size * sizeof(float));
      }
      free(x_new);
    break;
  }
}

void diffuse(int N, int b, float *x, float *x0, float diff, float dt) {
  float a = dt * diff * N * N;

  // Gauss-Seidel
  for (int k = 0; k < 20; k++) {
    for (int i = 1; i <= N; i++) {
      for (int j = 1; j <= N; j++) {
        x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i-1, j)] + x[IX(i+1, j)] + x[IX(i, j-1)] + x[IX(i, j+1)])) / (1 + 4 * a);
      }
    }
    set_bnd(N, b, x);
  }
}

void advect(int N, int b, float *d, float *d0, float *u, float *v, float dt) {
  float dt0 = dt * N;
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      float x = i - dt0 * u[IX(i, j)];
      float y = j - dt0 * v[IX(i, j)];
      if (x < 0.5f)
        x = 0.5f;
      if (x > N + 0.5f)
        x = N + 0.5f;
      int i0 = (int)x;
      int i1 = i0 + 1;
      if (y < 0.5f)
        y = 0.5f;
      if (y > N + 0.5f)
        y = N + 0.5f;
      int j0 = (int)y;
      int j1 = j0 + 1;

      float s1 = x - i0;
      float s0 = 1 - s1;
      float t1 = y - j0;
      float t0 = 1 - t1;

      d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) +
                    s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
    }
  }
  set_bnd(N, b, d);
}

void project(int N, float *u, float *v, float *p, float *div) {
  float h = 1.0f / N;
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      div[IX(i, j)] = -0.5f * h * (u[IX(i+1, j)] - u[IX(i-1, j)] + v[IX(i, j+1)] - v[IX(i, j-1)]);
      p[IX(i, j)] = 0.0f;
    }
  }
  set_bnd(N, 0, div); set_bnd(N, 0, p);

  // Gauss-Seidel
  for (int k = 0; k < 20; k++) {
    for (int i = 1; i <= N; i++) {
      for (int j = 1; j <= N; j++) {
        p[IX(i, j)] = (div[IX(i, j)] + p[IX(i-1, j)] + p[IX(i+1, j)] + p[IX(i, j-1)] + p[IX(i, j+1)]) / 4;
      }
    }
    set_bnd(N, 0, p);
  }

  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      u[IX(i, j)] -= 0.5f * (p[IX(i+1, j)] - p[IX(i-1, j)]) / h;
      v[IX(i, j)] -= 0.5f * (p[IX(i, j+1)] - p[IX(i, j-1)]) / h;
    }
  }
  set_bnd(N, 1, u); set_bnd(N, 2, v);
}

void dens_step(int N, float *x, float *x0, float *u, float *v, float diff, float dt) {
  add_source(N, x, x0, dt);
  SWAP(x0, x); diffuse_jacobi(N, 0, x, x0, diff, dt);
  SWAP(x0, x); advect(N, 0, x, x0, u, v, dt);
}

void vel_step(int N, float *u, float*v, float *u0, float *v0, float visc, float dt) {
  add_source(N, u, u0, dt); add_source(N, v, v0, dt);
  SWAP(u0, u); diffuse(N, 1, u, u0, visc, dt);
  SWAP(v0, v); diffuse(N, 2, v, v0, visc, dt);
  project(N, u, v, u0, v0);
  SWAP(u0, u); SWAP(v0, v);
  advect(N, 1, u, u0, u0, v0, dt); advect(N, 2, v, v0, u0, v0, dt);
  project(N, u, v, u0, v0);
}

void set_all(int N, float *x, float val) {
  for (int i = 0; i < N+2; i++) {
    for (int j = 0; j < N+2; j++) {
      x[IX(i, j)] = val;
    }
  }
}

void zero_boundary(int N, float *x) {
  for (int i = 0; i < N+2; i++) {
    x[IX(i, 0)] = 0;
    x[IX(0, i)] = 0;
    x[IX(i, N+1)] = 0;
    x[IX(N+1, i)] = 0;
  }
}

void zero_all(int N, float *dens, float* dens_prev, float *u, float *u_prev, float *v, float *v_prev) {
  for (int i = 0; i <= N+2; i++) {
    for (int j = 0; j <= N+2; j++) {
      dens[IX(i, j)] = 0;
      dens_prev[IX(i, j)] = 0;
      u[IX(i, j)] = 0;
      u_prev[IX(i, j)] = 0;
      v[IX(i, j)] = 0;
      v_prev[IX(i, j)] = 0;
    }
  }
}


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
  // Grid parameters
  params->N = N_;
  params->scale = 3.0f;
  params->screenWidth = params->scale * (params->N + 2) + 2;
  params->screenHeight = params->scale * (params->N + 2) + 2;
  params->imgWidth = params->N + 2;
  params->imgHeight = params->N + 2;
  
  // Simulation parameters
  params->diff = 2e-4f;
  params->visc = 1e-4f;
  
  // Source parameters
  params->middle_source_value = 4.0f;
  params->source_radius = 2;  // 5x5 grid around center
  
  // Initial velocity parameters
  params->initial_u_velocity = 0.2f;
  params->initial_v_velocity = 1.5f;
}

void setup_scene_high_diffusion(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 1e-3f;  // 5x higher diffusion
  params->middle_source_value = 6.0f;  // Stronger source to compensate
}

void setup_scene_low_viscosity(SceneParams *params) {
  setup_scene_default(params);
  params->visc = 1e-5f;  // 10x lower viscosity
  params->initial_u_velocity = 0.5f;  // Higher initial velocity
  params->initial_v_velocity = 2.0f;
}

void setup_scene_multiple_sources(SceneParams *params) {
  setup_scene_default(params);
  params->middle_source_value = 2.0f;  // Lower individual source strength
  params->source_radius = 1;  // Smaller sources
}

void setup_scene_turbulent(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 5e-4f;  // Higher diffusion
  params->visc = 5e-5f;  // Lower viscosity
  params->initial_u_velocity = 1.0f;  // Much higher initial velocity
  params->initial_v_velocity = 3.0f;
  params->middle_source_value = 8.0f;  // Stronger source
}

void setup_scene_smoke(SceneParams *params) {
  setup_scene_default(params);
  params->diff = 5e-5f;  // Very low diffusion - smoke spreads slowly
  params->visc = 1e-5f;  // Very low viscosity - smooth flow
  params->middle_source_value = 20.0f;  // Gentle, continuous source
  params->initial_u_velocity = 0.0f;  // No horizontal velocity initially
  params->initial_v_velocity = -1.0f;  // Strong upward velocity
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

int main(void) {
  SceneParams params;
  setup_scene(&params, SELECTED_SCENE);

  static float u[SIZE_], v[SIZE_], u_prev[SIZE_], v_prev[SIZE_];
  static float dens[SIZE_], dens_prev[SIZE_];

  zero_all(params.N, dens, dens_prev, u, u_prev, v, v_prev);

  float dt;

  InitWindow(params.screenWidth, params.screenHeight, "Fluid!");

  Image img = {
      .data = dens,
      .width = params.imgWidth,
      .height = params.imgHeight,
      .format = PIXELFORMAT_UNCOMPRESSED_R32,  // x in [0.0f, 1.0f], 32 bit float, 1 channel (red)
      .mipmaps = 1
  };

  Texture2D texture = LoadTextureFromImage(img);

  char grid_size_buffer[100];
  sprintf(grid_size_buffer, "N=%d", params.N);
  char diff_buffer[100];
  sprintf(diff_buffer, "diff=%.0e", params.diff);
  char visc_buffer[100];
  sprintf(visc_buffer, "visc=%.0e", params.visc);
  
  const char* scene_names[] = {
    "Default",
    "High Diffusion", 
    "Low Viscosity",
    "Multiple Sources",
    "Turbulent",
    "Smoke"
  };

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    dt = GetFrameTime();

    // dens_prev[IX(params.N/2, params.N/2)] += 0.1f;
    // set_all(params.N, dens_prev, 0.0f);
    scalar_multiplier(dens_prev, params.N+2, params.N+2, 0.0f);
    
    // Add sources based on scene type
    if (SELECTED_SCENE == SCENE_MULTIPLE_SOURCES) {
      // Multiple sources at different positions
      int center = params.N / 2;
      int quarter = params.N / 4;
      int three_quarter = 3 * params.N / 4;
      
      // Center source
      for (int ioff = -(int)params.source_radius; ioff <= (int)params.source_radius; ioff++) {
        for (int joff = -(int)params.source_radius; joff <= (int)params.source_radius; joff++) {
          dens_prev[IX(center + ioff, center + joff)] = params.middle_source_value;
        }
      }
      
      // Corner sources
      for (int ioff = -(int)params.source_radius; ioff <= (int)params.source_radius; ioff++) {
        for (int joff = -(int)params.source_radius; joff <= (int)params.source_radius; joff++) {
          dens_prev[IX(quarter + ioff, quarter + joff)] = params.middle_source_value;
          dens_prev[IX(three_quarter + ioff, three_quarter + joff)] = params.middle_source_value;
        }
      }
      
      // Add some velocity at the sources
      u[IX(center, center)] = params.initial_u_velocity;
      v[IX(center, center)] = params.initial_v_velocity;
      u[IX(quarter, quarter)] = -params.initial_u_velocity;
      v[IX(quarter, quarter)] = -params.initial_v_velocity;
      u[IX(three_quarter, three_quarter)] = params.initial_u_velocity;
      v[IX(three_quarter, three_quarter)] = -params.initial_v_velocity;
    } else if (SELECTED_SCENE == SCENE_SMOKE) {
      // Smoke: continuous point source with upward flow and slight variation
      int center = params.N / 2;
      
      dens_prev[IX(center, center)] = params.middle_source_value;
      
      // Add upward velocity with slight horizontal variation
      // Use time-based variation for natural smoke movement
      static float time_accumulator = 0.0f;
      time_accumulator += dt;
      
      float horizontal_variation = 0.1f * sinf(time_accumulator * 0.5f);
      u[IX(center, center)] = horizontal_variation;
      v[IX(center, center)] = params.initial_v_velocity;
      
      // Add some velocity to nearby cells for smoother flow
      u[IX(center-1, center)] = horizontal_variation * 0.5f;
      u[IX(center+1, center)] = horizontal_variation * 0.5f;
      v[IX(center, center-1)] = params.initial_v_velocity * 0.8f;
      v[IX(center, center+1)] = params.initial_v_velocity * 0.8f;
    } else {
      // Single source at center
      for (int ioff = -(int)params.source_radius; ioff <= (int)params.source_radius; ioff++) {
        for (int joff = -(int)params.source_radius; joff <= (int)params.source_radius; joff++) {
          dens_prev[IX(params.N/2 + ioff, params.N/2 + joff)] = params.middle_source_value;
        }
      }
      u[IX(params.N/2, params.N/2)] = params.initial_u_velocity;
      v[IX(params.N/2, params.N/2)] = params.initial_v_velocity;
    }

    vel_step(params.N, u, v, u_prev, v_prev, params.visc, dt);
    dens_step(params.N, dens, dens_prev, u, v, params.diff, dt);

    UpdateTexture(texture, dens);

    BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawTextureEx(texture,
                  (Vector2){1, 1},
                  0.0f, params.scale, WHITE);
    DrawFPS(10, 10);
    
    // Display current scene
    char scene_buffer[100];
    sprintf(scene_buffer, "Scene: %s", scene_names[SELECTED_SCENE]);
    DrawText(scene_buffer, 10, 40, 20, RAYWHITE);
    
    // Display parameters
    DrawText(grid_size_buffer, params.scale * params.N - 60, 10, 20, RAYWHITE);
    DrawText(diff_buffer, params.scale * params.N - 100, params.scale * params.N - 35, 20, RAYWHITE);
    DrawText(visc_buffer, params.scale * params.N - 100, params.scale * params.N - 15, 20, RAYWHITE);
    EndDrawing();
  }

  UnloadTexture(texture);
  CloseWindow();

  return 0;
}

