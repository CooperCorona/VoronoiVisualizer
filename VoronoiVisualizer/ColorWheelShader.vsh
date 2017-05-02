#version 150
uniform mat4 u_Projection;

in vec2 a_Position;
in vec2 a_Texture;

out vec2 v_Texture;

void main(void) {
    
    vec4 pos = u_Projection * vec4(a_Position, 0.0, 1.0);
    gl_Position = pos;
    
    v_Texture = a_Texture;
    /*if (abs(u_Projection[0][0] - 0.00554017) <= 0.001) {
        v_Texture = vec2(1.0);
    } else {
        v_Texture = a_Texture;
    }*/
}//main
