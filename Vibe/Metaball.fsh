void main() {
    vec4 color = texture2D(u_texture, v_tex_coord);
    
    // Metaball thresholding
    // We assume the input is blurred alpha. We sharpen it.
    float alpha = smoothstep(0.45, 0.55, color.a);
    
    if (alpha <= 0.0) {
        discard;
    }
    
    // Simple metallic shading based on alpha gradient
    // We can simulate a "surface normal" from the alpha gradient
    vec2 size = vec2(1.0 / 100.0); // Rough approximation
    float aRight = texture2D(u_texture, v_tex_coord + vec2(size.x, 0.0)).a;
    float aUp = texture2D(u_texture, v_tex_coord + vec2(0.0, size.y)).a;
    vec2 normal = normalize(vec2(aRight - color.a, aUp - color.a));
    
    float spec = pow(max(0.0, dot(normal, vec2(0.707, 0.707))), 16.0);
    vec3 baseColor = color.rgb;
    
    gl_FragColor = vec4(baseColor + spec * 0.3, alpha);
}
