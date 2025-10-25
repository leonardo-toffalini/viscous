#include <cuda_runtime.h>
#include <stddef.h>

#define CEIL_DIV(x, y) ((x + y - 1) / y)
#define IDX(i, j, ldm) ((i) * ldm + (j))  // ldm = leading dimension (if the 2d array is row major, ldm = cols)
#ifndef SWAP
#define SWAP(x, y) {float *tmp=x; x=y; y=tmp;}
#endif

__global__
void scalar_multiplier_kernel(float *A, size_t rows, size_t cols, float c) {
  int x = blockIdx.x * blockDim.x + threadIdx.x;
  if (x < rows * cols)
    A[x] *= c;
}

__global__
void mat_add_kernel(float *A, float *B, size_t rows, size_t cols, float dt) {
  int x = blockIdx.x * blockDim.x + threadIdx.x;
  if (x < rows * cols)
    A[x] += (dt * B[x]);
}

__global__
void diffuse_bad_kernel(float *A, float *B, size_t rows, size_t cols, float a) {
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  int i = blockIdx.y * blockDim.y + threadIdx.y;

  // skip the first and last row and column
  if (1 <= i && i <= rows-2 && 1 <= j && j <= cols-2)
    A[IDX(i, j, cols)] = B[IDX(i, j, cols)] + a * (B[IDX(i-1, j, cols)] + B[IDX(i+1, j, cols)] + B[IDX(i, j-1, cols)] + B[IDX(i, j+1, cols)] - 4 * B[IDX(i, j, cols)]);
}

__global__
void set_bnd_kernel(float *A, size_t rows, size_t cols, int b) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;

  // skip the corners as they have already been taken care of be the host stub function
  if (1 <= i && i <= rows-2) {
    A[IDX(i,      0, cols)] = b == 2 ? -A[IDX(i,      1, cols)] : A[IDX(i,      1, cols)];
    A[IDX(i, cols-1, cols)] = b == 2 ? -A[IDX(i, cols-2, cols)] : A[IDX(i, cols-2, cols)];
  }
  if (1 <= i && i <= cols-2) {
    A[IDX(     0, i, cols)] = b == 1 ? -A[IDX(     1, i, cols)] : A[IDX(     1, i, cols)];
    A[IDX(rows-1, i, cols)] = b == 1 ? -A[IDX(rows-2, i, cols)] : A[IDX(rows-2, i, cols)];
  }
}

__global__
void diffuse_jacobi_kernel(float *A, float *B, const float *C, size_t rows, size_t cols, float a) {
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  int i = blockIdx.y * blockDim.y + threadIdx.y;

  if (1 <= i && i <= rows-2 && 1 <= j && j <= cols-2)
    A[IDX(i,j,cols)] = (C[IDX(i,j,cols)] + a * (B[IDX(i-1,j,cols)] + B[IDX(i+1,j,cols)] + B[IDX(i,j-1,cols)] + B[IDX(i,j+1,cols)])) / (1.0f + 4.0f * a);
}

__global__
void advect_kernel(float *d, float *d0, float *u, float *v, size_t rows, size_t cols, float dt0) {
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  int i = blockIdx.y * blockDim.y + threadIdx.y;

  if (1 <= i && i <= rows-2 && 1 <= j && j <= cols - 2) {
      float x = i - dt0 * u[IDX(i, j, cols)];
      float y = j - dt0 * v[IDX(i, j, cols)];
      if (x < 0.5f)
        x = 0.5f;
      if (x > rows + 0.5f)
        x = rows + 0.5f;
      int i0 = (int)x;
      int i1 = i0 + 1;
      if (y < 0.5f)
        y = 0.5f;
      if (y > cols + 0.5f)
        y = cols + 0.5f;
      int j0 = (int)y;
      int j1 = j0 + 1;

      float s1 = x - i0;
      float s0 = 1 - s1;
      float t1 = y - j0;
      float t0 = 1 - t1;

      d[IDX(i, j, cols)] = s0 * (t0 * d0[IDX(i0, j0, cols)] + t1 * d0[IDX(i0, j1, cols)]) +
                    s1 * (t0 * d0[IDX(i1, j0, cols)] + t1 * d0[IDX(i1, j1, cols)]);
  }
}

extern "C"
void scalar_multiplier(float *A_h, size_t rows, size_t cols, float c) {
  float *A_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);

  int threads = 256;
  int blocks = CEIL_DIV(rows * cols, threads);
  scalar_multiplier_kernel<<<blocks, threads>>>(A_d, rows, cols, c);
  cudaDeviceSynchronize();

  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
}

extern "C"
void mat_add(float *A_h, float *B_h, size_t rows, size_t cols, float dt) {
  float *A_d, *B_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMalloc(&B_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(B_d, B_h, size, cudaMemcpyHostToDevice);

  int threads = 256;
  int blocks = CEIL_DIV(rows * cols, threads);
  mat_add_kernel<<<blocks, threads>>>(A_d, B_d, rows, cols, dt);
  cudaDeviceSynchronize();

  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(B_h, B_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
  cudaFree(B_d);
}

extern "C"
void diffuse_bad_host(float *A_h, float *B_h, size_t rows, size_t cols, float a) {
  float *A_d, *B_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMalloc(&B_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(B_d, B_h, size, cudaMemcpyHostToDevice);

  dim3 blockDim(16, 16, 1);
  dim3 gridDim(CEIL_DIV(rows, 16), CEIL_DIV(cols, 16), 1);
  diffuse_bad_kernel<<<gridDim, blockDim>>>(A_d, B_d, rows, cols, a);
  cudaDeviceSynchronize();

  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(B_h, B_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
  cudaFree(B_d);
}

extern "C"
void set_bnd_host(float *A_h, size_t rows, size_t cols, int b) {
  // corners
  A_h[IDX(     0,      0, cols)] = 0.5f * (A_h[IDX(     1,      0, cols)] + A_h[IDX(     0,      1, cols)]);
  A_h[IDX(     0, cols-1, cols)] = 0.5f * (A_h[IDX(     1, cols-1, cols)] + A_h[IDX(     0, cols-2, cols)]);
  A_h[IDX(rows-1,      0, cols)] = 0.5f * (A_h[IDX(rows-2,      0, cols)] + A_h[IDX(rows-1,      1, cols)]);
  A_h[IDX(rows-1, cols-1, cols)] = 0.5f * (A_h[IDX(rows-2, cols-1, cols)] + A_h[IDX(rows-1, cols-2, cols)]);

  float *A_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);

  int threads = 256;
  int blocks = CEIL_DIV(fmax(rows, cols), threads);
  set_bnd_kernel<<<blocks, threads>>>(A_d, rows, cols, b);
  cudaDeviceSynchronize();

  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
}

extern "C"
void diffuse_jacobi_host(float *A_h, const float *B_h, size_t rows, size_t cols, int b, const float a) {
  float *A_d, *B_d, *C_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMalloc(&B_d, size);
  cudaMalloc(&C_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(B_d, B_h, size, cudaMemcpyHostToDevice);

  float *cur   = A_d;      // read buffer (k-th iterate)
  float *next  = C_d;      // write buffer (k+1-th iterate)

  dim3 blockDim(16, 16, 1);
  dim3 gridDim(CEIL_DIV(rows, 16), CEIL_DIV(cols, 16), 1);

  for (int k = 0; k < 20; ++k) {
    diffuse_jacobi_kernel<<<gridDim, blockDim>>>(next, cur, B_d, rows, cols, a);
    set_bnd_kernel<<<CEIL_DIV(fmax(rows, cols), 256), 256>>>(next, rows, cols, b);
    SWAP(cur, next);
  }

  cudaDeviceSynchronize();

  // make sure result ends up in the caller's A_h host buffer
  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
  cudaFree(B_d);
  cudaFree(C_d);
}

extern "C"
void advect_host(float *d_h, float *d0_h, float *u_h, float *v_h, size_t rows, size_t cols, int b, float dt) {
  float *d_d, *d0_d, *u_d, *v_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&d_d, size);
  cudaMalloc(&d0_d, size);
  cudaMalloc(&u_d, size);
  cudaMalloc(&v_d, size);
  cudaMemcpy(d_d, d_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d0_d, d0_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(u_d, u_h, size, cudaMemcpyHostToDevice);
  cudaMemcpy(v_d, v_h, size, cudaMemcpyHostToDevice);

  dim3 blockDim(16, 16, 1);
  dim3 gridDim(CEIL_DIV(rows, 16), CEIL_DIV(cols, 16), 1);

  float dt0 = dt * fmax(rows, cols);
  advect_kernel<<<gridDim, blockDim>>>(d_d, d0_d, u_d, v_d, rows, cols, dt0);
  set_bnd_kernel<<<CEIL_DIV(fmax(rows, cols), 256), 256>>>(d_d, rows, cols, b);
  cudaDeviceSynchronize();

  cudaMemcpy(d_h, d_d, size, cudaMemcpyDeviceToHost);
  cudaFree(d_d);
  cudaFree(d0_d);
  cudaFree(u_d);
  cudaFree(v_d);
}
