#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main() {
  vec4 texelColor = texture(texture0, fragTexCoord);
  float val = texelColor.r * 2.0f;
  if (val < 0.25f) {
    finalColor.r = 0.0f;
    finalColor.g = 4.0f * val;
  } else if (val < 0.5f) {
    finalColor.r = 0.0f;
    finalColor.b = 2.0f - 4.0f * val;
  } else if (val < 0.75f) {
    finalColor.r = 4.0f * (val - 0.5f);
    finalColor.b = 0.0f;
  } else {
    finalColor.g = 1.0f + 4.0f * (0.75f - val);
    finalColor.b = 0;
  }
  finalColor.a = texelColor.a;
}

