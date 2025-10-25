#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // Output field (d)
uniform sampler2D texture1;  // Previous field (d0)
uniform sampler2D texture2;  // U velocity field
uniform sampler2D texture3;  // V velocity field
uniform float dt0;          // dt * N
uniform int gridSize;       // Grid size (N)
uniform float texelSize;    // 1.0 / texture_size

out vec4 finalColor;

void main() {
    vec2 texCoord = fragTexCoord;
    vec2 gridCoord = texCoord * float(gridSize + 2);
    
    // Convert to integer grid coordinates
    int i = int(gridCoord.y);
    int j = int(gridCoord.x);
    
    // Skip boundary cells
    if (i <= 0 || i >= gridSize + 1 || j <= 0 || j >= gridSize + 1) {
        finalColor = texture(texture0, texCoord);
        return;
    }
    
    // Get velocity at current position
    float u = texture(texture2, texCoord).r;
    float v = texture(texture3, texCoord).r;
    
    // Calculate back-traced position
    float x = float(i) - dt0 * u;
    float y = float(j) - dt0 * v;
    
    // Clamp to valid range
    x = max(0.5, min(float(gridSize) + 0.5, x));
    y = max(0.5, min(float(gridSize) + 0.5, y));
    
    // Convert back to texture coordinates
    vec2 backTracedTexCoord = vec2(y, x) * texelSize;
    
    // Get integer coordinates for interpolation
    int i0 = int(x);
    int i1 = i0 + 1;
    int j0 = int(y);
    int j1 = j0 + 1;
    
    // Calculate interpolation weights
    float s1 = x - float(i0);
    float s0 = 1.0 - s1;
    float t1 = y - float(j0);
    float t0 = 1.0 - t1;
    
    // Sample the four neighboring cells
    vec2 coord00 = vec2(float(j0), float(i0)) * texelSize;
    vec2 coord01 = vec2(float(j0), float(i1)) * texelSize;
    vec2 coord10 = vec2(float(j1), float(i0)) * texelSize;
    vec2 coord11 = vec2(float(j1), float(i1)) * texelSize;
    
    float d00 = texture(texture1, coord00).r;
    float d01 = texture(texture1, coord01).r;
    float d10 = texture(texture1, coord10).r;
    float d11 = texture(texture1, coord11).r;
    
    // Bilinear interpolation
    float result = s0 * (t0 * d00 + t1 * d01) + s1 * (t0 * d10 + t1 * d11);
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
