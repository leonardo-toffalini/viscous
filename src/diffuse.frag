#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // Current iteration (x)
uniform sampler2D texture1;  // Source (x0)
uniform float alpha;         // dt * diff * N * N
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
    
    // Get neighboring values from current iteration
    float center = texture(texture0, texCoord).r;
    float left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
    float right = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
    float top = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
    float bottom = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
    
    // Get source value
    float source = texture(texture1, texCoord).r;
    
    // Gauss-Seidel iteration: x[i,j] = (x0[i,j] + a * (x[i-1,j] + x[i+1,j] + x[i,j-1] + x[i,j+1])) / (1 + 4*a)
    float result = (source + alpha * (left + right + top + bottom)) / (1.0 + 4.0 * alpha);
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
