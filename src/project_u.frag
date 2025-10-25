#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // U velocity field
uniform sampler2D texture1;  // Pressure field (p)
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
        finalColor = texture(texture0, texCoord);
        return;
    }
    
    // Get current velocity and pressure gradients
    float current_u = texture(texture0, texCoord).r;
    float p_left = texture(texture1, vec2(texCoord.x - texelSize, texCoord.y)).r;
    float p_right = texture(texture1, vec2(texCoord.x + texelSize, texCoord.y)).r;
    
    // Calculate pressure gradient in x direction
    float grad_x = (p_right - p_left) / (2.0 * h);
    
    // Subtract gradient from u velocity: u -= 0.5 * grad_x
    float result = current_u - 0.5 * grad_x;
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
