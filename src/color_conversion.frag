#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0;

out vec4 finalColor;

void main() {
    float c = texture(texture0, fragTexCoord).r;
    finalColor = vec4(c, c, c, 1.0);
}
