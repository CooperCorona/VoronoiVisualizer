#version 150

in vec4 v_Color;

out vec4 c_gl_FragColor;

void main(void) {
    c_gl_FragColor = v_Color;
}
