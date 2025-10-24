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

// TODO:
// - add a switch such that if someone is running without nvidia gpu the computations default to cpu
// - implement jacobi iteration in cuda
// - implement advect in cuda
// - add ui input
// - probably should do something about the possibility when there are less threads than cells in the array
// - currently, it defaults to cuda if not on mac, instead it should default to cuda if it has nvcc

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

// CUDA function declarations - implemented in src/kernels.cu, when CUDA is available
// or in src/kernel_cpu_alternatives.c when it is not
extern void scalar_multiplier(float *A, size_t rows, size_t cols, float c);
extern void mat_add(float *A_h, float *B_h, size_t rows, size_t cols, float dt);
extern void diffuse_bad_host(float *A_h, float *B_h, size_t rows, size_t cols, float a);
extern void set_bnd_host(float *A_h, size_t rows, size_t cols, int b);
extern void diffuse_jacobi_host(float *A_h, const float *B_h, size_t rows, size_t cols, int b, const float a);

#ifdef __APPLE__
#include "kernel_cpu_alternatives.c"
#endif

// contains all the logic for the simulation
#include "engine.c"

// contains all the logic for setting up the predefined scenes
#include "scenes.c"

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

