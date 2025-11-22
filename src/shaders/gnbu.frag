#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float light_intensity;

out vec4 finalColor;

void main() {
  const vec3 gnbu_colors[9] = vec3[9](
    vec3(247.0, 252.0, 240.0) / 255.0,
    vec3(224.0, 243.0, 219.0) / 255.0,
    vec3(204.0, 235.0, 197.0) / 255.0,
    vec3(168.0, 221.0, 181.0) / 255.0,
    vec3(123.0, 204.0, 196.0) / 255.0,
    vec3( 78.0, 179.0, 211.0) / 255.0,
    vec3( 43.0, 140.0, 190.0) / 255.0,
    vec3(  8.0, 104.0, 172.0) / 255.0,
    vec3(  8.0,  64.0, 129.0) / 255.0
  );

  vec4 texelColor = texture(texture0, fragTexCoord);
  float val = 1 - clamp(texelColor.r, 0.0, 1.0);

  const int colorCount = 9;
  const int lastColorIdx = colorCount - 1;
  const float segments = float(lastColorIdx);
  float scaled = val * segments;
  int index = int(floor(scaled));
  float t = fract(scaled);

  vec3 baseColor = gnbu_colors[index];
  vec3 nextColor = gnbu_colors[min(index + 1, lastColorIdx)];
  vec3 color = mix(baseColor, nextColor, t);

  finalColor = vec4(color, texelColor.a);
}



