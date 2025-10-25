#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;  // Input texture
uniform int boundaryType;    // Boundary condition type (1 for u, 2 for v, 0 for density)
uniform int gridSize;        // Grid size (N)
uniform float texelSize;    // 1.0 / texture_size

out vec4 finalColor;

void main() {
    vec2 texCoord = fragTexCoord;
    vec2 gridCoord = texCoord * float(gridSize + 2);
    
    // Convert to integer grid coordinates
    int i = int(gridCoord.y);
    int j = int(gridCoord.x);
    
    // Get current value
    float currentValue = texture(texture0, texCoord).r;
    
    // Check if we're on a boundary
    bool isLeftBoundary = (j == 0);
    bool isRightBoundary = (j == gridSize + 1);
    bool isTopBoundary = (i == 0);
    bool isBottomBoundary = (i == gridSize + 1);
    bool isCorner = (isLeftBoundary || isRightBoundary) && (isTopBoundary || isBottomBoundary);
    
    float result = currentValue;
    
    if (isCorner) {
        // Handle corners - average of adjacent cells
        if (i == 0 && j == 0) {
            // Top-left corner
            float right = texture(texture0, vec2(texelSize, texCoord.y)).r;
            float bottom = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
            result = 0.5 * (right + bottom);
        } else if (i == 0 && j == gridSize + 1) {
            // Top-right corner
            float left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
            float bottom = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
            result = 0.5 * (left + bottom);
        } else if (i == gridSize + 1 && j == 0) {
            // Bottom-left corner
            float right = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
            float top = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
            result = 0.5 * (right + top);
        } else if (i == gridSize + 1 && j == gridSize + 1) {
            // Bottom-right corner
            float left = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
            float top = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
            result = 0.5 * (left + top);
        }
    } else if (isLeftBoundary || isRightBoundary) {
        // Vertical boundaries
        if (boundaryType == 2) {
            // For v velocity, use negative reflection
            if (isLeftBoundary) {
                result = -texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
            } else {
                result = -texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
            }
        } else {
            // For u velocity and density, use same value
            if (isLeftBoundary) {
                result = texture(texture0, vec2(texCoord.x + texelSize, texCoord.y)).r;
            } else {
                result = texture(texture0, vec2(texCoord.x - texelSize, texCoord.y)).r;
            }
        }
    } else if (isTopBoundary || isBottomBoundary) {
        // Horizontal boundaries
        if (boundaryType == 1) {
            // For u velocity, use negative reflection
            if (isTopBoundary) {
                result = -texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
            } else {
                result = -texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
            }
        } else {
            // For v velocity and density, use same value
            if (isTopBoundary) {
                result = texture(texture0, vec2(texCoord.x, texCoord.y + texelSize)).r;
            } else {
                result = texture(texture0, vec2(texCoord.x, texCoord.y - texelSize)).r;
            }
        }
    }
    
    finalColor = vec4(result, 0.0, 0.0, 1.0);
}
