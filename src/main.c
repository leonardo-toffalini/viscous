#include "raylib.h"
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

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

int main(void) {
  const int N = N_;
  const float scale = 3.0f;
  const int screenWidth = scale * (N + 2) + 2;
  const int screenHeight = scale * (N + 2) + 2;
  const int imgWidth = N+2;
  const int imgHeight = N+2;

  static float u[SIZE_], v[SIZE_], u_prev[SIZE_], v_prev[SIZE_];
  static float dens[SIZE_], dens_prev[SIZE_];

  zero_all(N, dens, dens_prev, u, u_prev, v, v_prev);

  float dt;
  const float diff = 2e-4;
  const float visc = 1e-4;
  const float middle_source_value = 4.0f;

  InitWindow(screenWidth, screenHeight, "Fluid!");

  Image img = {
      .data = dens,
      .width = imgWidth,
      .height = imgHeight,
      .format = PIXELFORMAT_UNCOMPRESSED_R32,  // x in [0.0f, 1.0f], 32 bit float, 1 channel (red)
      .mipmaps = 1
  };

  Texture2D texture = LoadTextureFromImage(img);

  char grid_size_buffer[100];
  sprintf(grid_size_buffer, "N=%d", N);
  char diff_buffer[100];
  sprintf(diff_buffer, "diff=%.0e", diff);
  char visc_buffer[100];
  sprintf(visc_buffer, "visc=%.0e", visc);

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    dt = GetFrameTime();

    // dens_prev[IX(N/2, N/2)] += 0.1f;
    // set_all(N, dens_prev, 0.0f);
    scalar_multiplier(dens_prev, N+2, N+2, 0.0f);
    for (int ioff = -2; ioff <= 2; ioff++) {
      for (int joff = -2; joff <= 2; joff++) {
        dens_prev[IX(N/2 + ioff, N/2 + joff)] = middle_source_value;
      }
    }
    u[IX(N/2, N/2)] = 0.2f;
    v[IX(N/2, N/2)] = 1.5f;

    vel_step(N, u, v, u_prev, v_prev, visc, dt);
    dens_step(N, dens, dens_prev, u, v, diff, dt);

    UpdateTexture(texture, dens);

    BeginDrawing();
    ClearBackground(RAYWHITE);
    DrawTextureEx(texture,
                  (Vector2){1, 1},
                  0.0f, scale, WHITE);
    DrawFPS(10, 10);
    DrawText(grid_size_buffer, scale * N - 60, 10, 20, RAYWHITE);
    DrawText(diff_buffer, scale * N - 100, scale * N - 35, 20, RAYWHITE);
    DrawText(visc_buffer, scale * N - 100, scale * N - 15, 20, RAYWHITE);
    EndDrawing();
  }

  UnloadTexture(texture);
  CloseWindow();

  return 0;
}

