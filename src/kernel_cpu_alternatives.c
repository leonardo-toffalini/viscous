#ifdef SINGLE_TU

// CPU implementations of CUDA functions
void scalar_multiplier(float *A, size_t rows, size_t cols, float c) {
  for (size_t i = 0; i < rows * cols; i++) {
    A[i] *= c;
  }
}

void mat_add(float *A_h, float *B_h, size_t rows, size_t cols, float dt) {
  for (size_t i = 0; i < rows * cols; i++) {
    A_h[i] += dt * B_h[i];
  }
}

void diffuse_bad_host(float *A_h, float *B_h, size_t rows, size_t cols, float a) {
  for (int i = 1; i <= rows-2; i++) {
    for (int j = 1; j <= cols-2; j++) {
      A_h[IX(i, j)] = B_h[IX(i, j)] + a * (B_h[IX(i-1, j)] + B_h[IX(i+1, j)] + B_h[IX(i, j-1)] + B_h[IX(i, j+1)] - 4 * B_h[IX(i, j)]);
    }
  }
}

void set_bnd_host(float *A_h, size_t rows, size_t cols, int b) {
  // Handle corners first
  A_h[IX(0, 0)] = 0.5f * (A_h[IX(1, 0)] + A_h[IX(0, 1)]);
  A_h[IX(0, cols-1)] = 0.5f * (A_h[IX(1, cols-1)] + A_h[IX(0, cols-2)]);
  A_h[IX(rows-1, 0)] = 0.5f * (A_h[IX(rows-2, 0)] + A_h[IX(rows-1, 1)]);
  A_h[IX(rows-1, cols-1)] = 0.5f * (A_h[IX(rows-2, cols-1)] + A_h[IX(rows-1, cols-2)]);
  
  // Handle edges
  for (int i = 1; i <= rows-2; i++) {
    A_h[IX(i, 0)] = b == 2 ? -A_h[IX(i, 1)] : A_h[IX(i, 1)];
    A_h[IX(i, cols-1)] = b == 2 ? -A_h[IX(i, cols-2)] : A_h[IX(i, cols-2)];
  }
  for (int j = 1; j <= cols-2; j++) {
    A_h[IX(0, j)] = b == 1 ? -A_h[IX(1, j)] : A_h[IX(1, j)];
    A_h[IX(rows-1, j)] = b == 1 ? -A_h[IX(rows-2, j)] : A_h[IX(rows-2, j)];
  }
}

void diffuse_jacobi_host(float *A_h, const float *B_h, size_t rows, size_t cols, int b, const float a) {
  const int size = rows * cols;
  float *A_new = (float*)malloc(size * sizeof(float));
  
  float *cur = A_h;
  float *next = A_new;
  
  for (int k = 0; k < 20; ++k) {
    for (int i = 1; i <= rows-2; ++i) {
      for (int j = 1; j <= cols-2; ++j) {
        next[IX(i,j)] = (B_h[IX(i,j)] + a * (cur[IX(i-1,j)] + cur[IX(i+1,j)] + cur[IX(i,j-1)] + cur[IX(i,j+1)])) / (1.0f + 4.0f * a);
      }
    }
    
    // Apply boundary conditions
    for (int i = 1; i <= rows-2; i++) {
      next[IX(i, 0)] = b == 2 ? -next[IX(i, 1)] : next[IX(i, 1)];
      next[IX(i, cols-1)] = b == 2 ? -next[IX(i, cols-2)] : next[IX(i, cols-2)];
    }
    for (int j = 1; j <= cols-2; j++) {
      next[IX(0, j)] = b == 1 ? -next[IX(1, j)] : next[IX(1, j)];
      next[IX(rows-1, j)] = b == 1 ? -next[IX(rows-2, j)] : next[IX(rows-2, j)];
    }
    
    // Handle corners
    next[IX(0, 0)] = 0.5f * (next[IX(1, 0)] + next[IX(0, 1)]);
    next[IX(0, cols-1)] = 0.5f * (next[IX(1, cols-1)] + next[IX(0, cols-2)]);
    next[IX(rows-1, 0)] = 0.5f * (next[IX(rows-2, 0)] + next[IX(rows-1, 1)]);
    next[IX(rows-1, cols-1)] = 0.5f * (next[IX(rows-2, cols-1)] + next[IX(rows-1, cols-2)]);
    
    // Swap buffers
    float *tmp = cur;
    cur = next;
    next = tmp;
  }
  
  // Make sure result ends up in A_h
  if (cur != A_h) {
    memcpy(A_h, cur, size * sizeof(float));
  }
  
  free(A_new);
}

#endif
