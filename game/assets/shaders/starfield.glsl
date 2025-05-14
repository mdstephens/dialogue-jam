#ifdef GL_ES
precision mediump float;
#endif

uniform float time; // Time uniform to animate the stars
uniform vec2 resolution; // Screen resolution

// Random function to generate star positions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords.xy / resolution.xy; // Normalize coordinates
    uv.y *= resolution.y / resolution.x; // Maintain aspect ratio

    // Starfield parameters
    float speed = 0.003; // Speed of stars
    float density = 500.0; // Number of stars
    float baseBrightness = 0.8; // Base brightness of stars

    // Animate stars by shifting their y-coordinate
    float y = fract(uv.y + time * speed);

    // Generate random star positions
    float x = random(vec2(uv.x, floor(y * density))) * 2.0 - 1.0;

    // Calculate distance to the star
    float distanceToStar = length(uv - vec2(x, y));

    // Create stars with a smoother and wider appearance
    float star = smoothstep(0.94, 0.998, random(vec2(floor(x * density), floor(y * density))));

    // Add independent twinkling effect
    vec2 starPosition = vec2(floor(x * density), floor(y * density));
    float randomPhase = random(starPosition + vec2(1.0, 1.0)) * 6.283; // Add variation to random input
    float twinkle = 0.25 * sin(time * 5.0 + randomPhase) + 0.6;

    // Final star color (constant) and twinkling effect in alpha
    vec3 starColor = vec3(baseBrightness); // Keep the star color constant
    float starAlpha = star * twinkle; // Use twinkle to modulate opacity

    return vec4(starColor, starAlpha);
}