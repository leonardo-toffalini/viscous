#include "raylib.h"
#include <stdlib.h>
#include <stdio.h>

#define N_ 100
#define SIZE_ ((N_+2)*(N_+2))
#define IX(i, j) ((i)+(N_+2)*(j))
// Stam: #define SWAP(x0, x) {float *tmp=x0; x0=x; x=tmp;}
#define SWAP(x, y) do { float *tmp = (x); (x) = (y); (y) = tmp; } while (0)

void add_source(int N, float *x, float *s, float dt) {
  int size = (N+2)*(N+2);
  for (int i = 0; i < size; i++)
    x[i] += dt * s[i];
}

void set_bnd(int N, int b, float *x) {
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
}

void diffuse_bad(int N, int b, float *x, float *x0, float diff, float dt) {
  float a = dt * diff * N * N;

  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      x[IX(i, j)] = x0[IX(i, j)] + a * (x0[IX(i-1, j)] + x0[IX(i+1, j)] + x0[IX(i, j-1)] + x0[IX(i, j+1)] - 4 * x0[IX(i, j)]);
    }
  }
  set_bnd(N, b, x);
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
  SWAP(x0, x); diffuse(N, 0, x, x0, diff, dt);
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
  for (int i = 0; i <= N+2; i++) {
    for (int j = 0; j <= N+2; j++) {
      x[IX(i, j)] = val;
    }
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

void swap_arrays(float *a, float *b, size_t n) {
    for (size_t i = 0; i < n; i++) {
        float tmp = a[i];
        a[i] = b[i];
        b[i] = tmp;
    }
}

int main(void) {
  const int N = N_;
  const float scale = 5.0f;
  const int screenWidth = scale * (N + 2);
  const int screenHeight = scale * (N + 2);
  const int imgWidth = N+2;
  const int imgHeight = N+2;

  static float u[SIZE_], v[SIZE_], u_prev[SIZE_], v_prev[SIZE_];

  static float dens[SIZE_], dens_prev[SIZE_];

  zero_all(N, dens, dens_prev, u, u_prev, v, v_prev);
  set_all(N, u, 0.02f);
  set_all(N, v, 0.04f);

  float dt;
  const float diff = 1e-4;
  const float visc = 0.01f;

  InitWindow(screenWidth, screenHeight, "Fluid!");

  Image img = {
      .data = dens,
      .width = imgWidth,
      .height = imgHeight,
      .format = PIXELFORMAT_UNCOMPRESSED_R32,  // x in [0.0f, 1.0f], 32 bit float, 1 channel
      .mipmaps = 1
  };

  Texture2D texture = LoadTextureFromImage(img);

  char grid_size_buffer[100];
  sprintf(grid_size_buffer, "N=%d", N);

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    double time = GetTime() * 100;
    dt = GetFrameTime();

    // dens_prev[IX(N/2, N/2)] += 0.1f;
    set_all(N, dens_prev, 0.0f);
    dens_prev[IX(N/2, N/2)] = 10.0f;

    // vel_step(N, u, v, u_prev, v_prev, visc, dt);
    dens_step(N, dens, dens_prev, u, v, diff, dt);
    
    // diffuse(N, 0, dens, dens_prev, diff, dt);
    // swap_arrays(dens, dens_prev, SIZE_);
    
    // test 
    // int i = ((int)rand()) % (N+2);
    // int j = ((int)rand()) % (N+2);
    // dens[IX(i, j)] = 1.0f;

    UpdateTexture(texture, dens);

    BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawTextureEx(texture,
                  (Vector2){0, 0},
                  0.0f, scale, WHITE);
    DrawFPS(10, 10);
    DrawText(grid_size_buffer, scale * N - 60, 10, 20, RAYWHITE);
    EndDrawing();
  }

  UnloadTexture(texture);
  CloseWindow();

  return 0;
}

