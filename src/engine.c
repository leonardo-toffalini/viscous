#ifdef SINGLE_TU

// CUDA function declarations - implemented in src/kernels.cu, when CUDA is available
// or in src/kernel_cpu_alternatives.c when it is not
#if CUDA_AVAILABLE
extern void scalar_multiplier(float *A, size_t rows, size_t cols, float c);
extern void mat_add(float *A_h, float *B_h, size_t rows, size_t cols, float dt);
extern void diffuse_bad_host(float *A_h, float *B_h, size_t rows, size_t cols, float a);
extern void set_bnd_host(float *A_h, size_t rows, size_t cols, int b);
extern void diffuse_jacobi_host(float *A_h, const float *B_h, size_t rows, size_t cols, int b, const float a);
extern void advect_host(float *d_h, float *d0_h, float *u_h, float *v_h, size_t rows, size_t cols, int b, float dt);
#endif

typedef struct {
  int i;
  int j;
} pos;

pos mouse_pos_to_index(size_t rows, size_t cols, float scale) {
  int j = GetMouseX() / scale;
  int i = GetMouseY() / scale;
  return (pos){i, j};
}

void zero_out(float *x, size_t N) {
  for (int i = 0; i < N; i++)
    x[i] = 0;
}

void mat_add_cpu(size_t rows, size_t cols, float *x, float *s, float dt) {
  for (int i = 0; i < rows * cols; i++)
    x[i] += dt * s[i];
}

void add_source(size_t rows, size_t cols, float *x, float *s, float dt) {
  int add_source_type = 1 && CUDA_AVAILABLE;
  switch (add_source_type) {
    #if CUDA_AVAILABLE
    case 1:
      mat_add(x, s, rows+2, cols+2, dt);
      break;
    #endif

    case 0:
    default:
      mat_add_cpu(rows+2, cols+2, x, s, dt);
  }

}

void set_bnd_cpu(int rows, int cols, int b, float *x) {
  for (int i = 1; i <= rows; i++) {
    x[IX(i,      0)] = b == 2 ? -x[IX(i,    1)] :x[IX(i,    1)];
    x[IX(i, cols+1)] = b == 2 ? -x[IX(i, cols)] :x[IX(i, cols)];
  }
  for (int i = 1; i <= cols; i++) {
    x[IX(0,      i)] = b == 1 ? -x[IX(1,    i)] :x[IX(1,    i)];
    x[IX(rows+1, i)] = b == 1 ? -x[IX(rows, i)] :x[IX(rows, i)];
  }
  x[IX(0,           0)] = 0.5f * (x[IX(1,         0)] + x[IX(0,         1)]);
  x[IX(0,      cols+1)] = 0.5f * (x[IX(1,    cols+1)] + x[IX(0,      cols)]);
  x[IX(rows+1,      0)] = 0.5f * (x[IX(rows,      0)] + x[IX(rows+1,       1)]);
  x[IX(rows+1, cols+1)] = 0.5f * (x[IX(rows, cols+1)] + x[IX(rows+1, cols)]);
}

void set_bnd(int rows, int cols, int b, float *x) {
  // the CPU version is faster as the GPU version requires copying the array on to the GPUs global memory,
  // and it does not offset the computational benefit
  int set_bnd_type = 0 && CUDA_AVAILABLE;

  switch (set_bnd_type) {
    // gpu
    #if CUDA_AVAILABLE
    case 1:
      set_bnd_host(x, rows+2, cols+2, b);
      break;
    #endif

    // cpu
    case 0:
    default:
      set_bnd_cpu(rows, cols, b, x);
      break;
  }
}

#if CUDA_AVAILABLE
void diffuse_bad(int rows, int cols, int b, float *x, float *x0, float diff, float dt) {
  float a = dt * diff * rows * cols;

  diffuse_bad_host(x, x0, rows+2, cols+2, a);
  set_bnd(rows, cols, b, x);
}
#endif

#if CUDA_AVAILABLE
void diffuse_jacobi(int N, int b, float *x, const float *x0, float diff, float dt) {
  const float a = dt * diff * N * N;

  // the gpu version is magnitudes faster than the cpu version
  // for the gpu version the iteration number k does not change the fps that much
  // while for the cpu version, increasing k, the fps quickly drops
  diffuse_jacobi_host(x, x0, N+2, N+2, b, a);
}
#endif

// Gauss-Seidel is way harder to implement on gpu as the cells are not independent
// Jacobi iteration is easier on the gpu
void diffuse_cpu(int N, int b, float *x, float *x0, float diff, float dt) {
  float a = dt * diff * N * N;

  // Gauss-Seidel
  for (int k = 0; k < ITERATIONS; k++) {
    for (int i = 1; i <= N; i++) {
      for (int j = 1; j <= N; j++) {
        x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i-1, j)] + x[IX(i+1, j)] + x[IX(i, j-1)] + x[IX(i, j+1)])) / (1 + 4 * a);
      }
    }
    set_bnd(N, N, b, x);
  }
}

void diffuse(int N, int b, float *x, float *x0, float diff, float dt) {
  int diffuse_type = 1 && CUDA_AVAILABLE;

  switch (diffuse_type) {
    #if CUDA_AVAILABLE
    case 1:
      diffuse_jacobi(N, b, x, x0, diff, dt);
      break;
    #endif

    case 0:
    default:
      diffuse_cpu(N, b, x, x0, diff, dt);
      break;
  }
}

void advect_cpu(int N, int b, float *d, float *d0, float *u, float *v, float dt) {
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
  set_bnd(N, N, b, d);
}

void advect(int N, int b, float *d, float *d0, float *u, float *v, float dt) {
  int advect_type = 1 && CUDA_AVAILABLE;

  switch (advect_type) {
    // gpu
    #if CUDA_AVAILABLE
    case 1:
      advect_host(d, d0, u, v, N+2, N+2, b, dt);
      break;
    #endif

    // cpu
    case 0:
    default:
      advect_cpu(N, b, d, d0, u, v, dt);
      break;
  }
}

void project(int N, float *u, float *v, float *p, float *div) {
  float h = 1.0f / N;
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      div[IX(i, j)] = -0.5f * h * (u[IX(i+1, j)] - u[IX(i-1, j)] + v[IX(i, j+1)] - v[IX(i, j-1)]);
      p[IX(i, j)] = 0.0f;
    }
  }
  set_bnd(N, N, 0, div); set_bnd(N, N, 0, p);

  // Gauss-Seidel
  for (int k = 0; k < ITERATIONS; k++) {
    for (int i = 1; i <= N; i++) {
      for (int j = 1; j <= N; j++) {
        p[IX(i, j)] = (div[IX(i, j)] + p[IX(i-1, j)] + p[IX(i+1, j)] + p[IX(i, j-1)] + p[IX(i, j+1)]) / 4;
      }
    }
    set_bnd(N, N, 0, p);
  }

  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= N; j++) {
      u[IX(i, j)] -= 0.5f * (p[IX(i+1, j)] - p[IX(i-1, j)]) / h;
      v[IX(i, j)] -= 0.5f * (p[IX(i, j+1)] - p[IX(i, j-1)]) / h;
    }
  }
  set_bnd(N, N, 1, u); set_bnd(N, N, 2, v);
}

void dens_step(int N, float *x, float *x0, float *u, float *v, float diff, float dt) {
  add_source(N, N, x, x0, dt);
  SWAP(x0, x); diffuse(N, 0, x, x0, diff, dt);
  SWAP(x0, x); advect(N, 0, x, x0, u, v, dt);
}

void vel_step(int N, float *u, float*v, float *u0, float *v0, float visc, float dt) {
  add_source(N, N, u, u0, dt); add_source(N, N, v, v0, dt);
  SWAP(u0, u); diffuse(N, 1, u, u0, visc, dt);
  SWAP(v0, v); diffuse(N, 2, v, v0, visc, dt);
  project(N, u, v, u0, v0);
  SWAP(u0, u); SWAP(v0, v);
  advect(N, 1, u, u0, u0, v0, dt); advect(N, 2, v, v0, u0, v0, dt);
  project(N, u, v, u0, v0);
}

void zero_all(int rows, int cols, float *dens, float* dens_prev, float *u, float *u_prev, float *v, float *v_prev) {
  for (int i = 0; i <= rows+2; i++) {
    for (int j = 0; j <= cols+2; j++) {
      dens[IX(i, j)] = 0;
      dens_prev[IX(i, j)] = 0;
      u[IX(i, j)] = 0;
      u_prev[IX(i, j)] = 0;
      v[IX(i, j)] = 0;
      v_prev[IX(i, j)] = 0;
    }
  }
}

#endif
