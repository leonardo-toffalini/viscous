#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // Current field (u or v)
uniform sampler2D texture1;  // Pressure field (p)
uniform sampler2D texture2;  // Divergence field (div) - only used in divergence calculation
uniform int gridSize;       // Grid size (N)
uniform float texelSize;    // 1.0 / texture_size
uniform float h;           // 1.0 / N
uniform int step;          // 0 = calculate divergence, 1 = pressure iteration, 2 = subtract gradient

out vec4 finalColor;

void main() {
    vec2 texCoord = fragTexCoord;
    vec2 gridCoord = texCoord * float(gridSize + 2);
    
    // Convert to integer grid coordinates
    int i = int(gridCoord.y);
    int j = int(gridCoord.x);
    
    float result = 0.0;
    
    if (step == 0) {
        // Calculate divergence
        if (i <= 0 || i >= gridSize + 1 || j <= 0 || j >= gridSize + 1) {
            finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
        
        // Get velocity gradients
        float u_right = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
        float u_left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
        float v_top = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
        float v_bottom = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
        
        // Calculate divergence: div = -0.5 * h * (u[i+1,j] - u[i-1,j] + v[i,j+1] - v[i,j-1])
        result = -0.5 * h * (u_right - u_left + v_bottom - v_top);
        
    } else if (step == 1) {
        // Pressure iteration (Gauss-Seidel)
        if (i <= 0 || i >= gridSize + 1 || j <= 0 || j >= gridSize + 1) {
            finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
        
        // Get divergence and neighboring pressure values
        float div = texture(texture2, texCoord).r;
        float p_left = texture(texture1, vec2(texCoord.x - texelSize, texCoord.y)).r;
        float p_right = texture(texture1, vec2(texCoord.x + texelSize, texCoord.y)).r;
        float p_top = texture(texture1, vec2(texCoord.x, texCoord.y - texelSize)).r;
        float p_bottom = texture(texture1, vec2(texCoord.x, texCoord.y + texelSize)).r;
        
        // Gauss-Seidel: p[i,j] = (div[i,j] + p[i-1,j] + p[i+1,j] + p[i,j-1] + p[i,j+1]) / 4
        result = (div + p_left + p_right + p_top + p_bottom) / 4.0;
        
    } else if (step == 2) {
        // Subtract pressure gradient from velocity
        if (i <= 0 || i >= gridSize + 1 || j <= 0 || j >= gridSize + 1) {
            finalColor = texture(texture0, texCoord);
            return;
        }
        
        // Get current velocity and pressure gradients
        float current_vel = texture(texture0, texCoord).r;
        float p_left = texture(texture1, vec2(texCoord.x - texelSize, texCoord.y)).r;
        float p_right = texture(texture1, vec2(texCoord.x + texelSize, texCoord.y)).r;
        float p_top = texture(texture1, vec2(texCoord.x, texCoord.y - texelSize)).r;
        float p_bottom = texture(texture1, vec2(texCoord.x, texCoord.y + texelSize)).r;
        
        // Calculate gradient components
        float grad_x = (p_right - p_left) / (2.0 * h);
        float grad_y = (p_bottom - p_top) / (2.0 * h);
        
        // Subtract gradient from velocity
        // For u velocity: u -= 0.5 * grad_x
        // For v velocity: v -= 0.5 * grad_y
        result = current_vel - 0.5 * grad_x;  // This will be set based on which velocity component we're updating
        
    } else {
        // Default case
        result = texture(texture0, texCoord).r;
    }
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
