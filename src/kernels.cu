#include <cuda_runtime.h>
#include <stddef.h>

__global__
void scalar_multiplier_kernel(float *A, size_t rows, size_t cols, float c) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  if (idx < rows * cols) {
    A[idx] *= c;
  }
}

extern "C"
void scalar_multiplier(float *A_h, size_t rows, size_t cols, float c) {
  float *A_d; size_t size = rows * cols * sizeof(float);
  cudaMalloc(&A_d, size);
  cudaMemcpy(A_d, A_h, size, cudaMemcpyHostToDevice);

  int threads = 256;
  int blocks = (rows * cols + threads - 1) / threads;
  scalar_multiplier_kernel<<<blocks, threads>>>(A_d, rows, cols, c);
  cudaDeviceSynchronize();

  cudaMemcpy(A_h, A_d, size, cudaMemcpyDeviceToHost);
  cudaFree(A_d);
}
