void main() {
    vec4 color = texture2D(u_texture, v_tex_coord);
    
    // Extremely tight threshold for sharp, molten metallic edges
    // compsensates for the massive 25pt blur to ensure "surface tension" look
    float alpha = smoothstep(0.495, 0.505, color.a);
    
    if (alpha <= 0.0) {
        discard;
    }
    
    // Improved metallic shading with normal mapping from the blurred input
    vec2 size = vec2(1.8 / 100.0);
    float aRight = texture2D(u_texture, v_tex_coord + vec2(size.x, 0.0)).a;
    float aUp = texture2D(u_texture, v_tex_coord + vec2(0.0, size.y)).a;
    
    // Normal calculation simulates the "rounded" top of the mercury
    vec2 normal = normalize(vec2(aRight - color.a, aUp - color.a));
    
    // High-contrast specularity for "Liquid Chrome" look
    float spec1 = pow(max(0.0, dot(normal, vec2(0.4, 0.9))), 48.0) * 1.5; // Primary highlight
    float spec2 = pow(max(0.0, dot(normal, vec2(-0.8, -0.3))), 24.0) * 0.6; // Secondary bounce
    
    // Rim lighting for depth
    float rim = pow(1.0 - color.a, 6.0) * 0.5;
    
    vec3 baseColor = color.rgb;
    vec3 lightColor = vec3(1.0, 1.0, 1.2); 
    
    vec3 finalColor = baseColor * 0.9 + (spec1 + spec2) * lightColor + rim;
    
    gl_FragColor = vec4(finalColor, alpha);
}
