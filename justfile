default:
  @just --list

smoke:
  make CMAP=GRAYS SELECTED_SCENE=SCENE_SMOKE SOURCE_RADIUS=1 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

fire:
  make CMAP=APPLE SELECTED_SCENE=SCENE_FIRE SOURCE_RADIUS=3 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

empty:
  make CMAP=APPLE SELECTED_SCENE=SCENE_EMPTY SOURCE_RADIUS=3 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

turbulent:
  make CMAP=INFERNO SELECTED_SCENE=SCENE_TURBULENT SOURCE_RADIUS=3 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

low_viscosity:
  make CMAP=PLASMA SELECTED_SCENE=SCENE_LOW_VISCOSITY SOURCE_RADIUS=3 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

rb_convection:
  make CMAP=INFERNO SELECTED_SCENE=SCENE_RAYLEIGH_BENARD_CONVECTION SOURCE_RADIUS=3 CUDA_AVAILABLE=0 config=release_arm64 target=viscous -j8 && ./bin/Release/viscous

