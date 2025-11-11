// TODO:
// - add a switch such that if someone is running without nvidia gpu the computations default to cpu
// - implement advect and project in cuda
// - probably should do something about the possibility when there are less threads than cells in the array
// - add more boundary cells, objects in the scene to interact with
// - currently, it defaults to cuda if not on mac, instead it should default to cuda if it has nvcc
// - could probably put the main game loop part of the scenes into a function
// and store a pointer to that function in the scene params struct

#define SINGLE_TU

#include "raylib.h"
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

#define N_ 200
#define ROWS 200
#define COLS 200
#define SIZE_ ((ROWS+2)*(COLS+2))
#define IX(i, j) ((j)+(ROWS+2)*(i))
#define ITERATIONS 20
#define MAX_FPS 60
#ifndef SWAP
#define SWAP(x0, x) {float *tmp=x0; x0=x; x=tmp;}
#endif

// change this value to 1 if you are on a machine with and NVIDIA graphics card and you have the CUDA tools downloaded
#define CUDA_AVAILABLE 0

// Scene selection - change this to switch scenes
#define SELECTED_SCENE SCENE_VORTEX_SHREDDING

// contains all the logic for the simulation
#include "engine.c"

// contains all the logic for setting up the predefined scenes
#include "scenes.c"

void keyboard_callback(SceneParams params);
void click_callback(float *dens_prev, float *u_prev, SceneParams params);
void drag_callback(SceneParams params, float *u_prev, float *v_prev);

int first_mouse = 1;
float last_x = 800.0f / 2;
float last_y = 800.0f / 2;
float force_magnitude = 0.8f;
int force_radius = 3;
int source_radius = 1;

int main(void) {
  SceneParams params;
  setup_scene(&params, SELECTED_SCENE);

  static float u[SIZE_], v[SIZE_], u_prev[SIZE_], v_prev[SIZE_];
  static float dens[SIZE_], dens_prev[SIZE_];
  static unsigned char solid[SIZE_];

  zero_all(params.rows, params.cols, dens, dens_prev, u, u_prev, v, v_prev);
  // Initialize solid mask and place a circular obstacle in the center
  for (int i = 0; i < SIZE_; i++) solid[i] = 0;
  {
    int cx = params.N / 2;
    int cy = params.N / 2;
    int r = params.N / 12;
    int r2 = r * r;
    for (int i = 1; i <= params.N; i++) {
      for (int j = 1; j <= params.N; j++) {
        int di = i - cx;
        int dj = j - cy;
        if (di*di + dj*dj <= r2) solid[IX(i, j)] = 1;
      }
    }
  }

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

  // convert red channel only color to something else
  Shader colorShader = LoadShader(NULL, "src/color_conversion.frag");


  SetTargetFPS(MAX_FPS);

  while (!WindowShouldClose()) {
    dt = GetFrameTime();

    // scalar_multiplier(dens_prev, params.rows+2, params.cols+2, 0.0f);
    zero_out(dens_prev, (params.rows+2) * (params.cols+2));
    
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
    } else if (SELECTED_SCENE == SCENE_VORTEX_SHREDDING) {
      // Left-to-right inflow: v is horizontal component in this codebase
      int band_center = params.N / 2;
      int band_half = params.N / 4;
      for (int i = 1; i <= params.N; i++) {
        // Uniform inflow across the height; could also restrict to a band
        v[IX(i, 1)] = params.initial_v_velocity;
      }
      // Seed density near the left boundary in a vertical band for visualization
      for (int i = band_center - band_half; i <= band_center + band_half; i++) {
        if (i >= 1 && i <= params.N) dens_prev[IX(i, 2)] = 2.0f;
      }
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
    click_callback(dens_prev, u_prev, params);

    vel_step(params.N, u, v, u_prev, v_prev, params.visc, dt, solid);
    dens_step(params.N, dens, dens_prev, u, v, params.diff, dt, solid);

    UpdateTexture(texture, dens);

    BeginDrawing();
    ClearBackground(BLACK);
    
    BeginShaderMode(colorShader);
    DrawTextureEx(texture, (Vector2){1, 1}, 0.0f, params.scale, WHITE);
    EndShaderMode();
    
    keyboard_callback(params);
    drag_callback(params, u_prev, v_prev);

    EndDrawing();
  }

  UnloadShader(colorShader);
  UnloadTexture(texture);
  CloseWindow();

  return 0;
}

void click_callback(float *dens_prev, float *u_prev, SceneParams params) {
  if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
    pos p = mouse_pos_to_index(params.rows+2, params.cols+2, params.scale);
    // add source to dens
    for (int ioff = -source_radius; ioff < source_radius; ioff++)
      for (int joff = -source_radius; joff < source_radius; joff++)
        dens_prev[IX(p.i + ioff, p.j + joff)] += 10.0f;
  }
}

void drag_callback(SceneParams params, float *u_prev, float *v_prev) {
  int xpos = GetMouseX();
  int ypos = GetMouseY();

  if (first_mouse) {
    last_x = xpos;
    last_y = ypos;
    first_mouse = 0;
  }
  float xoffset = xpos - last_x;
  float yoffset = ypos - last_y;

  if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
    // debug line
    // DrawLine(last_x, last_y, xpos, ypos, RED);

    pos p = mouse_pos_to_index(params.rows+2, params.cols+2, params.scale);
    // add source to dens
    for (int ioff = -force_radius; ioff < force_radius; ioff++)
      for (int joff = -force_radius; joff < force_radius; joff++) {
        u_prev[IX(p.i + ioff, p.j + joff)] += yoffset * force_magnitude;
        v_prev[IX(p.i + ioff, p.j + joff)] += xoffset * force_magnitude;
      }
  }

  last_x = xpos;
  last_y = ypos;

}

void keyboard_callback(SceneParams params) {
  char grid_size_buffer[100];
  sprintf(grid_size_buffer, "N=%d", params.N);
  char diff_buffer[100];
  sprintf(diff_buffer, "diff=%.0e", params.diff);
  char visc_buffer[100];
  sprintf(visc_buffer, "visc=%.0e", params.visc);

  char scene_buffer[100];
  sprintf(scene_buffer, "Scene: %s", scene_names[SELECTED_SCENE]);
  if (IsKeyDown(KEY_SPACE)) {
    DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), ColorAlpha(BLACK, 0.6f));

    DrawFPS(10, 10);
    DrawText(scene_buffer, 10, 40, 20, RAYWHITE);
    DrawText(grid_size_buffer, params.scale * params.cols - 60, 10, 20, RAYWHITE);
    DrawText(diff_buffer, params.scale * params.cols - 100, params.scale * params.cols - 35, 20, RAYWHITE);
    DrawText(visc_buffer, params.scale * params.cols - 100, params.scale * params.cols - 15, 20, RAYWHITE);
  }
}

