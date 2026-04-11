void main() {
    vec4 color = texture2D(u_texture, v_tex_coord);
    
    // Liquid surface tension thresholding
    // A tighter smoothstep creates a more "viscous" look at the edges
    float alpha = smoothstep(0.48, 0.52, color.a);
    
    if (alpha <= 0.0) {
        discard;
    }
    
    // Improved metallic shading with normal mapping from the blurred input
    vec2 size = vec2(1.5 / 100.0);
    float aRight = texture2D(u_texture, v_tex_coord + vec2(size.x, 0.0)).a;
    float aUp = texture2D(u_texture, v_tex_coord + vec2(0.0, size.y)).a;
    
    // Normal calculation simulates the "rounded" top of the mercury
    vec2 normal = normalize(vec2(aRight - color.a, aUp - color.a));
    
    // Multi-point highlights for more realistic metallic luster
    float spec1 = pow(max(0.0, dot(normal, vec2(0.3, 0.9))), 24.0); // Top light
    float spec2 = pow(max(0.0, dot(normal, vec2(-0.8, -0.2))), 12.0) * 0.4; // Side bounce
    
    // Rim lighting for depth
    float rim = pow(1.0 - color.a, 4.0) * 0.3;
    
    vec3 baseColor = color.rgb;
    vec3 lightColor = vec3(1.0, 1.0, 1.1); // Slightly blue-tinted light
    
    vec3 finalColor = baseColor + (spec1 + spec2) * lightColor + rim;
    
    gl_FragColor = vec4(finalColor, alpha);
}
