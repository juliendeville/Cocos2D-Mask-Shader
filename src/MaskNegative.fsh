#ifdef GL_ES
precision highp float;
#endif

varying vec2 v_texCoord;
uniform vec4 v_rectTexture;
uniform vec4 v_rectDrawMask;
uniform vec2 v_posStartMask;
uniform vec2 v_ratioMaskSprite;
uniform vec4 v_rectMask;
uniform sampler2D u_texture;
uniform sampler2D u_maskTexture;

void main()
{
    vec4 normalColor = texture2D(u_texture, v_texCoord).rgba;
    if( v_texCoord.x >= v_rectDrawMask.x && v_texCoord.y >= v_rectDrawMask.y && v_texCoord.x < v_rectDrawMask.x + v_rectDrawMask.z && v_texCoord.y < v_rectDrawMask.y + v_rectDrawMask.w ) {
        vec2 v_maskCoord = vec2( (v_texCoord.x - v_rectTexture.x) * v_ratioMaskSprite.x + v_posStartMask.x, ( v_texCoord.y - v_rectTexture.y ) * v_ratioMaskSprite.y + v_posStartMask.y );
        float maskColor = texture2D(u_maskTexture, v_maskCoord).a * normalColor.a;
        if(maskColor > 0.0 ) {
            gl_FragColor = vec4(normalColor.rgb/normalColor.a, maskColor);
        } else {
            gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
        }
        //for testing
//        gl_FragColor = vec4( 0.0, texture2D(u_maskTexture, v_maskCoord).a , 0.0, 1.0 );
//        gl_FragColor += vec4( 0.0, 0.0, normalColor.a, 1.0 );
    } else {
        gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
        //for testing
//        gl_FragColor = vec4( normalColor.a, 0.0, 0.0, 1.0 );
        
    }
}