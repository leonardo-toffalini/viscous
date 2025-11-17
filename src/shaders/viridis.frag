#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main() {
  const vec3 viridis_colors[20] = vec3[20](
    vec3(253.0, 228.0, 33.0) / 255.0,
    vec3(215.0, 233.0, 23.0) / 255.0,
    vec3(175.0, 217.0, 36.0) / 255.0,
    vec3(137.0, 211.0, 56.0) / 255.0,
    vec3(105.0, 201.0, 75.0) / 255.0,
    vec3(76.0, 191.0, 92.0)  / 255.0,
    vec3(52.0, 180.0, 106.0) / 255.0,
    vec3(36.0, 165.0, 116.0) / 255.0,
    vec3(30.0, 152.0, 123.0) / 255.0,
    vec3(29.0, 139.0, 128.0) / 255.0,
    vec3(32.0, 127.0, 130.0) / 255.0,
    vec3(35.0, 113.0, 131.0) / 255.0,
    vec3(40.0, 101.0, 131.0) / 255.0,
    vec3(44.0, 89.0, 131.0)  / 255.0,
    vec3(50.0, 75.0, 129.0)  / 255.0,
    vec3(55.0, 62.0, 125.0)  / 255.0,
    vec3(61.0, 48.0, 118.0)  / 255.0,
    vec3(63.0, 34.0, 108.0)  / 255.0,
    vec3(63.0, 21.0, 93.0)   / 255.0,
    vec3(60.0, 15.0, 74.0)   / 255.0
  );

  vec4 texelColor = texture(texture0, fragTexCoord);
  float val = 1.0 - clamp(texelColor.r, 0.0, 1.0);

  const int colorCount = 20;
  const int lastColorIdx = colorCount - 1;
  const float segments = float(lastColorIdx);
  float scaled = val * segments;
  int index = int(floor(scaled));
  float t = fract(scaled);

  vec3 baseColor = viridis_colors[min(index, lastColorIdx)];
  vec3 nextColor = viridis_colors[min(index + 1, lastColorIdx)];
  finalColor = vec4(mix(baseColor, nextColor, t), texelColor.a);
}


