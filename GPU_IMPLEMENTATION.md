# GPU-Accelerated Fluid Simulation

This document describes the GPU shader implementation of the fluid simulation functions that were previously CPU-only.

## Overview

The fluid simulation has been enhanced with GPU shader implementations for the following core functions:

1. **Boundary Conditions (`set_bnd`)**
2. **Diffusion (`diffuse`)**
3. **Advection (`advect`)**
4. **Pressure Projection (`project`)**

## Shader Files

### Core Shaders

- `src/set_bnd.frag` - Boundary condition setting
- `src/diffuse.frag` - Diffusion step using Gauss-Seidel iteration
- `src/advect.frag` - Advection step with bilinear interpolation
- `src/divergence.frag` - Divergence calculation for pressure projection
- `src/pressure.frag` - Pressure field iteration
- `src/project_u.frag` - U velocity pressure gradient subtraction
- `src/project_v.frag` - V velocity pressure gradient subtraction

### Engine Files

- `src/engine_gpu_advanced.c` - Advanced GPU engine with full shader support
- `src/engine_gpu.c` - Basic GPU engine with fallback to CPU

## Performance Benefits

The GPU implementation provides significant performance improvements:

1. **Parallel Processing**: All grid cells are processed simultaneously on the GPU
2. **Memory Bandwidth**: GPU memory bandwidth is much higher than CPU
3. **Reduced CPU Load**: Frees up CPU for other tasks
4. **Scalability**: Performance scales with GPU power

## Usage

### Building

```bash
# Build with GPU support
./build_gpu.sh

# Or manually compile
gcc -o viscous_gpu src/main.c src/engine_gpu_advanced.c src/scenes.c src/kernel_cpu_alternatives.c -lraylib -lm -O3
```

### Running

```bash
./build/gpu/viscous_gpu
```

## Implementation Details

### Boundary Conditions

The `set_bnd.frag` shader handles different boundary condition types:
- Type 0: Density (no-slip)
- Type 1: U velocity (free-slip)
- Type 2: V velocity (free-slip)

### Diffusion

The `diffuse.frag` shader implements Gauss-Seidel iteration for solving the diffusion equation:
```
x[i,j] = (x0[i,j] + α * (x[i-1,j] + x[i+1,j] + x[i,j-1] + x[i,j+1])) / (1 + 4α)
```

### Advection

The `advect.frag` shader performs semi-Lagrangian advection with bilinear interpolation for stability.

### Pressure Projection

The pressure projection is split into multiple shaders:
1. `divergence.frag` - Calculate velocity divergence
2. `pressure.frag` - Solve pressure Poisson equation
3. `project_u.frag` and `project_v.frag` - Subtract pressure gradients

## Performance Measurement

To measure the performance improvement:

1. Run the original CPU version and note the FPS
2. Run the GPU version and compare FPS
3. The GPU version should show significantly higher FPS, especially at higher grid resolutions

## Fallback Behavior

If GPU shaders fail to load or render textures cannot be created, the system automatically falls back to CPU implementations, ensuring the simulation continues to work.

## Technical Notes

- Render textures are used for GPU computation
- Shader uniforms are set for each computation step
- Multiple iterations are performed on the GPU for convergence
- Boundary conditions are applied after each GPU computation step

## Future Improvements

1. **Full GPU Pipeline**: Complete GPU implementation without CPU fallbacks
2. **Texture Readback**: Efficient CPU-GPU data transfer
3. **Multi-pass Rendering**: Optimize shader passes
4. **Compute Shaders**: Use compute shaders for even better performance
