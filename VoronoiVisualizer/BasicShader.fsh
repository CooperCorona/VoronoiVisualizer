#version 150

precision mediump float;

uniform highp sampler2D u_TextureInfo;
uniform float u_Alpha;
uniform vec3 u_TintColor;
uniform vec3 u_TintIntensity;
uniform vec3 u_ShadeColor;

in vec2 v_Texture;

out vec4 c_gl_FragColor;

void main(void) {
    
    vec4 texColor = texture(u_TextureInfo, v_Texture);
    
    texColor.rgb *= u_ShadeColor;
    texColor = vec4(mix(texColor.rgb, u_TintColor, u_TintIntensity), texColor.a * u_Alpha);
    
    c_gl_FragColor = texColor;
}//main
