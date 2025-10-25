#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // U velocity field
uniform sampler2D texture1;  // V velocity field
uniform int gridSize;       // Grid size (N)
uniform float texelSize;    // 1.0 / texture_size
uniform float h;           // 1.0 / N

out vec4 finalColor;

void main() {
    vec2 texCoord = fragTexCoord;
    vec2 gridCoord = texCoord * float(gridSize + 2);
    
    // Convert to integer grid coordinates
    int i = int(gridCoord.y);
    int j = int(gridCoord.x);
    
    // Skip boundary cells
    if (i <= 0 || i >= gridSize + 1 || j <= 0 || j >= gridSize + 1) {
        finalColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    // Get velocity gradients
    float u_right = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
    float u_left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
    float v_top = texture(texture1, vec2(texCoord.x, texCoord.y - texelSize)).r;
    float v_bottom = texture(texture1, vec2(texCoord.x, texCoord.y + texelSize)).r;
    
    // Calculate divergence: div = -0.5 * h * (u[i+1,j] - u[i-1,j] + v[i,j+1] - v[i,j-1])
    float result = -0.5 * h * (u_right - u_left + v_bottom - v_top);
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
