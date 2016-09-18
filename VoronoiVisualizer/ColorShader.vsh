#version 150

uniform mat4 u_Projection;

in vec2 a_Position;
in vec4 a_Color;

out vec4 v_Color;

void main(void) {
    gl_Position = u_Projection * vec4(a_Position, 0.0, 1.0);
    v_Color = a_Color;
}
