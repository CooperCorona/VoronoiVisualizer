#version 150
precision mediump float;
#define M_PI 3.14159265

uniform highp sampler2D u_Gradient;
uniform float u_Brightness;
uniform float u_Alpha;
uniform vec4 u_OutlineColor;

in vec2 v_Texture;
out vec4 c_gl_FragColor;

void main(void) {
    float z = v_Texture.x * v_Texture.x + v_Texture.y * v_Texture.y;
    
    if (z > 1.0) {
        discard;
    } else if (z > 0.98) {
        c_gl_FragColor = u_OutlineColor;
    } else {
        float angle = (atan(-v_Texture.y, -v_Texture.x) / M_PI + 1.0) / 2.0;
        vec4 color  = texture(u_Gradient, vec2(angle, 0.0));
        vec3 bright = vec3(u_Brightness);
        color       = vec4(mix(color.rgb * u_Brightness, bright, 1.0 - sqrt(z)), u_Alpha);
        
        c_gl_FragColor = color;
    }
}//main
