#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;
uniform vec2 v_sizeTexture;
uniform vec4 v_rectMask;
uniform sampler2D u_texture;
uniform sampler2D u_maskTexture;

void main()
{
    vec4 normalColor = texture2D(u_texture, v_texCoord).rgba;
    vec2 v_maskCoord = vec2( v_maskTexCoord.x + v_maskTexCoord.z * v_texCoord.x, v_maskTexCoord.y + v_maskTexCoord.w * v_texCoord.x );
    vec4 maskColor = texture2D(u_overlayTexture, v_maskCoord).rgba;
    float alpha = 1.0 - normalColor.a;
    gl_FragColor = vec4(maskColor.r, maskColor.g, maskColor.b, alpha);
    gl_FragColor = vec4(1.0,1.0,1.0,1.0);
    
    gl_FragColor = vec4( 0.0, 1.0, 0.0, 1.0 );
}