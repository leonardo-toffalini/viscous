#include "raylib.h"
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define N_ 200
#define ROWS 200
#define COLS 200
#define SIZE_ ((ROWS+2)*(COLS+2))
#define IX(i, j) ((j)+(ROWS+2)*(i))
#ifndef SWAP
#define SWAP(x0, x) {float *tmp=x0; x0=x; x=tmp;}
#endif

// TODO:
// - add a switch such that if someone is running without nvidia gpu the computations default to cpu
// - implement jacobi iteration in cuda
// - implement advect and project in cuda
// - probably should do something about the possibility when there are less threads than cells in the array
// - add more boundary cells, objects in the scene to interact with
// - currently, it defaults to cuda if not on mac, instead it should default to cuda if it has nvcc

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

  zero_all(params.rows, params.cols, dens, dens_prev, u, u_prev, v, v_prev);

  float dt;

  InitWindow(params.screenWidth, params.screenHeight, "Fluid!");

  Image img = {
      .data = dens,
      .width = params.imgWidth,
      .height = params.imgHeight,
      .format = PIXELFORMAT_UNCOMPRESSED_R32,  // x in [0.0f, 1.0f], 32 bit float, 1 channel
      .mipmaps = 1
  };

  Texture2D texture = LoadTextureFromImage(img);

  Shader colorShader = LoadShader(NULL, "src/color_conversion.frag");

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
    "Turbulent",
    "Smoke",
    "Empty",
    "R-B convection",
  };
  char scene_buffer[100];
  sprintf(scene_buffer, "Scene: %s", scene_names[SELECTED_SCENE]);

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    dt = GetFrameTime();

    scalar_multiplier(dens_prev, params.rows+2, params.cols+2, 0.0f);
    
    if (SELECTED_SCENE == SCENE_SMOKE) {
      int center = params.N / 2;
      
      dens_prev[IX(center, center)] = params.middle_source_value;
      
      static float time_accumulator = 0.0f;
      time_accumulator += dt;
      
      // even with no horizontal variation it looks smoke-like
      float horizontal_variation = 0.0f; // 0.1f * sinf(time_accumulator * 0.5f);
      u[IX(center, center)] = params.initial_u_velocity;
      v[IX(center, center)] = horizontal_variation;
      
      // Add some velocity to nearby cells for smoother flow
      u[IX(center, center-1)] = params.initial_u_velocity * 0.8f;
      u[IX(center, center+1)] = params.initial_u_velocity * 0.8f;
      v[IX(center-1, center)] = horizontal_variation * 0.5f;
      v[IX(center+1, center)] = horizontal_variation * 0.5f;
    } else if (SELECTED_SCENE == SCENE_RAYLEIGH_BENARD_CONVECTION) {
      static float time_accumulator = 0.0f;
      time_accumulator += dt;

      for (int i = 1; i <= params.cols + 1; i++) {
        if ((int)time_accumulator % 10 == 0)
          dens_prev[IX(params.rows, i)] = 0.1f;
        u[IX(params.rows, i)] = -time_accumulator * 0.1f;
      }
    } else {
      for (int ioff = -(int)params.source_radius; ioff <= (int)params.source_radius; ioff++) {
        for (int joff = -(int)params.source_radius; joff <= (int)params.source_radius; joff++) {
          dens_prev[IX(params.N/2 + ioff, params.N/2 + joff)] = params.middle_source_value;
        }
      }
      u[IX(params.N/2, params.N/2)] = params.initial_u_velocity;
      v[IX(params.N/2, params.N/2)] = params.initial_v_velocity;
    }

    if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
      pos p = mouse_pos_to_index(params.rows+2, params.cols+2, params.scale);
      // add source to dens
      for (int ioff = -1; ioff < 1; ioff++)
        for (int joff = -1; joff < 1; joff++)
          dens_prev[IX(p.i + ioff, p.j + joff)] += 10.0f;

      // add upward vel
      u_prev[IX(p.i, p.j)] += -2.7f;
    }

    vel_step(params.N, u, v, u_prev, v_prev, params.visc, dt);
    dens_step(params.N, dens, dens_prev, u, v, params.diff, dt);

    UpdateTexture(texture, dens);

    BeginDrawing();
    ClearBackground(BLACK);
    
    BeginShaderMode(colorShader);
    DrawTextureEx(texture, (Vector2){1, 1}, 0.0f, params.scale, WHITE);
    EndShaderMode();
    
    // Display parameters
    if (IsKeyDown(KEY_SPACE)) {
      DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), ColorAlpha(BLACK, 0.6f));

      DrawFPS(10, 10);
      DrawText(scene_buffer, 10, 40, 20, RAYWHITE);
      DrawText(grid_size_buffer, params.scale * params.cols - 60, 10, 20, RAYWHITE);
      DrawText(diff_buffer, params.scale * params.cols - 100, params.scale * params.cols - 35, 20, RAYWHITE);
      DrawText(visc_buffer, params.scale * params.cols - 100, params.scale * params.cols - 15, 20, RAYWHITE);
    }
    EndDrawing();
  }

  UnloadShader(colorShader);
  UnloadTexture(texture);
  CloseWindow();

  return 0;
}

