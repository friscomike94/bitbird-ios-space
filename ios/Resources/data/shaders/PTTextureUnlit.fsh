varying vec2 texCoord;

void main() {
    vec4 color = texture2D(CC_Texture0, texCoord);
    // Subtle cool-blue tint for unlit surfaces (UI, backgrounds)
    color.r *= 0.85;
    color.g *= 0.92;
    color.b = min(color.b * 1.10, 1.0);
    gl_FragColor = color;
}
