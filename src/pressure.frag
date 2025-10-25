#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // Current pressure field
uniform sampler2D texture1;  // Divergence field
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
        finalColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    // Get divergence and neighboring pressure values
    float div = texture(texture1, texCoord).r;
    float p_left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
    float p_right = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
    float p_top = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
    float p_bottom = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
    
    // Gauss-Seidel: p[i,j] = (div[i,j] + p[i-1,j] + p[i+1,j] + p[i,j-1] + p[i,j+1]) / 4
    float result = (div + p_left + p_right + p_top + p_bottom) / 4.0;
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
