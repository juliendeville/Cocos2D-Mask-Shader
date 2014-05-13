//
//  TBSpriteMask.m
//  ShaderMask
//
//  Created by Tony BELTRAMELLI on 26/01/13.
//
//

#import "TBSpriteMask.h"

#define DRAW_SETUP()                                                                \
do {                                                                                \
    ccGLEnable( self.sprite.glServerState );                                              \
    NSAssert1(self.sprite.shaderProgram, @"No shader program set for node: %@", self);   \
    [self.sprite.shaderProgram use];                                                      \
    [self.sprite.shaderProgram setUniformsForBuiltins];                                   \
} while(0)                                                                          \

@interface TBSpriteMask ()

@end

@implementation TBSpriteMask

+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName {
    return [self spriteWithSprite:sprite maskSpriteFrameName:maskSpriteFrameName positiveMask:NO];
}

+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask {
    return [self spriteWithSprite:sprite maskSpriteFrameName:maskSpriteFrameName positionMask:positionMask positiveMask:NO];
}

+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positiveMask:(BOOL)positive {
    return [self spriteWithSprite:sprite maskSpriteFrameName:maskSpriteFrameName positionMask:ccp( 0.5, 0.5 ) positiveMask:positive];
}

+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask positiveMask:(BOOL)positive {
    TBSpriteMask *tbSpriteMask = [super new];
    tbSpriteMask.sprite = sprite;
    tbSpriteMask.mask = [CCSprite spriteWithSpriteFrameName:maskSpriteFrameName];
    tbSpriteMask.type = positive;
    tbSpriteMask.positionMask = positionMask;
    [tbSpriteMask buildMaskWithTexture:tbSpriteMask.mask];
    
    tbSpriteMask.sprite.visible = NO;
    [tbSpriteMask addChild:tbSpriteMask.sprite];
    
    return tbSpriteMask;
}

+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName {
    return [self spriteWithSpriteFrameName:spriteFrameName maskSpriteFrameName:maskSpriteFrameName positiveMask:NO];
}

+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask {
    return [self spriteWithSpriteFrameName:spriteFrameName maskSpriteFrameName:maskSpriteFrameName positionMask:positionMask positiveMask:NO];
}

+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positiveMask:(BOOL)positive {
    return [self spriteWithSpriteFrameName:spriteFrameName maskSpriteFrameName:maskSpriteFrameName positionMask:ccp( 0.0, 0.0 ) positiveMask:positive];
}

+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask positiveMask:(BOOL)positive {
    return [self spriteWithSprite:[CCSprite spriteWithSpriteFrameName:spriteFrameName] maskSpriteFrameName:maskSpriteFrameName positionMask:ccp( 0.0, 0.0 ) positiveMask:positive];
}



-(void) buildMaskWithTexture:(CCSprite*)texture
{
    self.sprite.anchorPoint = CGPointZero;
    NSString *shaderName =  _type ? @"MaskPositive.fsh" : @"MaskNegative.fsh";
    const GLchar * fragmentSource = (GLchar*) [[NSString stringWithContentsOfFile:[[CCFileUtils sharedFileUtils] fullPathFromRelativePath:shaderName] encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    self.sprite.shaderProgram = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureA8Color_vert fragmentShaderByteArray:fragmentSource];
    [self.sprite.shaderProgram addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
    [self.sprite.shaderProgram addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
    [self.sprite.shaderProgram addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
    [self.sprite.shaderProgram link];
    [self.sprite.shaderProgram updateUniforms];
    
    _maskLocation = glGetUniformLocation(self.sprite.shaderProgram->_program, "u_maskTexture");
    [self.sprite.shaderProgram setUniformLocation:_maskLocation withI1:1];
    
    self.mask = texture;
    [self.mask.texture setAliasTexParameters];
    _rectTexture = glGetUniformLocation(self.sprite.shaderProgram->_program, "v_rectTexture");
    _rectMask = glGetUniformLocation(self.sprite.shaderProgram->_program, "v_rectMask");
    _rectDrawMask = glGetUniformLocation(self.sprite.shaderProgram->_program, "v_rectDrawMask");
    _startMask = glGetUniformLocation(self.sprite.shaderProgram->_program, "v_posStartMask");
    _ratioMaskSprite = glGetUniformLocation(self.sprite.shaderProgram->_program, "v_ratioMaskSprite");
    
    [self updateUniforms];
    
    [self.sprite.shaderProgram use];
    ccGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.mask.texture.name);
    glActiveTexture(GL_TEXTURE0);
    
}


- (void)updateUniforms {
    //L'idée ici c'est de trouver les coordonnées du masque sur le sprite pour les passer au shader qui affichera le sprite masqué
    //Je trouve ce rectangle à partir des coordonnées des quad et des size du sprite et du masque
    //On a besoin de trouver la position a laquelle on doit placer la texture du masque par rapport à celle du sprite
    //finalement dans le cas ou les deux textures seraient differentes on doit appliquer un ratio entre les coordonnées des deux textures
    
    // TODO : Prendre en charge l'anchorPoint de self
    // TODO : Corriger un bug de centrage sur les sprite plus petites que le masque
    
    //tailles en % dans leurs textures d'origine
    CGSize percentSpriteSize = CGSizeMake( self.sprite.quad.tr.texCoords.u - self.sprite.quad.bl.texCoords.u, self.sprite.quad.bl.texCoords.v - self.sprite.quad.tr.texCoords.v );
    CGSize percentMaskSize = CGSizeMake( self.mask.quad.tr.texCoords.u - self.mask.quad.bl.texCoords.u, self.mask.quad.bl.texCoords.v - self.mask.quad.tr.texCoords.v );
    //tailles en pixels affichés
    CGSize pixelSpriteSize = CGSizeMake( self.sprite.quad.tr.vertices.x-self.sprite.quad.bl.vertices.x, self.sprite.quad.tr.vertices.y-self.sprite.quad.bl.vertices.y );
    CGSize pixelMaskSize = CGSizeMake( self.mask.contentSize.width - ( self.mask.contentSize.width - self.mask.quad.tr.vertices.x ) - self.mask.quad.bl.vertices.x, self.mask.contentSize.height - ( self.mask.contentSize.height - self.mask.quad.tr.vertices.y ) - self.mask.quad.bl.vertices.y );
    //ratios
    CGSize ratioPixelPercentSprite = CGSizeMake(percentSpriteSize.width/pixelSpriteSize.width, percentSpriteSize.height/pixelSpriteSize.height);
    CGSize ratioPixelPercentMask = CGSizeMake(percentMaskSize.width/pixelMaskSize.width, percentMaskSize.height/pixelMaskSize.height);
    //les rects de sprite et masque
    CGRect pixelSpriteRect = CGRectMake( self.sprite.quad.tl.vertices.x, self.sprite.contentSize.height-self.sprite.quad.tl.vertices.y, pixelSpriteSize.width, pixelSpriteSize.height);
    CGRect percentSpriteRect = CGRectMake(self.sprite.quad.tl.texCoords.u-pixelSpriteRect.origin.x * ratioPixelPercentSprite.width,
                                          self.sprite.quad.tl.texCoords.v-pixelSpriteRect.origin.y * ratioPixelPercentSprite.height,
                                          self.sprite.contentSize.width * ratioPixelPercentSprite.width,// + (self.sprite.contentSize.width-self.sprite.quad.br.vertices.x)/pixelSpriteSize.width*percentSpriteSize.width,
                                          self.sprite.contentSize.height * ratioPixelPercentSprite.height);// + (self.sprite.contentSize.height-self.sprite.quad.br.vertices.y)/pixelSpriteSize.height*percentSpriteSize.height);
    //offset avec l'anchorpoint
    CGPoint anchoredOffset = ccp(((self.sprite.contentSize.width) * self.anchorPointMask.x ) - ((self.mask.contentSize.width) * self.anchorPointMask.x ) + self.positionMask.x,
                                 ((self.sprite.contentSize.height) * (self.anchorPointMask.y) ) - ((self.mask.contentSize.height) * (self.anchorPointMask.y) ) + self.positionMask.y);
    
    CGRect pixelMaskRect = CGRectMake( self.mask.quad.tl.vertices.x+anchoredOffset.x, self.mask.contentSize.height-self.mask.quad.tl.vertices.y+anchoredOffset.y, pixelMaskSize.width, pixelMaskSize.height );
    CGRect percentMaskRect = CGRectMake(self.mask.quad.tl.texCoords.u-pixelMaskRect.origin.x * ratioPixelPercentMask.width,
                                        self.mask.quad.tl.texCoords.v-pixelMaskRect.origin.y * ratioPixelPercentMask.height,
                                        self.mask.contentSize.width * ratioPixelPercentMask.width,// + (self.mask.contentSize.width-self.mask.quad.br.vertices.x)/pixelMaskSize.width*percentMaskSize.width,
                                        self.mask.contentSize.height * ratioPixelPercentMask.height);// + (self.mask.contentSize.height-self.mask.quad.br.vertices.y)/pixelMaskSize.height*percentMaskSize.height);
    //intersection des deux rects affichés
    CGRect anchoredMaskRect = CGRectMake( pixelMaskRect.origin.x, pixelMaskRect.origin.y, pixelMaskRect.size.width, pixelMaskRect.size.height );
    CGRect anchoredIntersect = CGRectIntersection( pixelSpriteRect, anchoredMaskRect);
    
    //rect pour la definir la zone autorisée à afficher la sprite ( en % de la texture de sprite )
    CGRect validSpriteRect = CGRectMake(( percentSpriteRect.origin.x + anchoredIntersect.origin.x * ratioPixelPercentSprite.width ),
                                        ( percentSpriteRect.origin.y + anchoredIntersect.origin.y * ratioPixelPercentSprite.height ) ,
                                        ( anchoredIntersect.size.width * ratioPixelPercentSprite.width ),
                                        ( anchoredIntersect.size.height * ratioPixelPercentSprite.height ));
    //position de debut d'affichage du masque en prenant en compte la position du masque sur la sprite ( en % de la texture du masque )
    CGPoint posStartMask = ccp(percentMaskRect.origin.x + (pixelSpriteRect.origin.x) * ratioPixelPercentMask.width,
                               percentMaskRect.origin.y + (pixelSpriteRect.origin.y) * ratioPixelPercentMask.height);
    //ratio entre les % de texture de sprite et de masque ( 1 si la meme texture )
    CGPoint ratioMaskSprite = ccp((pixelSpriteSize.width / pixelMaskSize.width) / (percentSpriteSize.width/percentMaskSize.width),
                                  (pixelSpriteSize.height / pixelMaskSize.height) / (percentSpriteSize.height/percentMaskSize.height));
//    NSLog(@"validSpriteRectPixel%@", NSStringFromCGRect(anchoredIntersect));
    //envoi des infos au shader
    [self.sprite.shaderProgram setUniformLocation:_rectTexture withF1:self.sprite.quad.tl.texCoords.u f2:self.sprite.quad.tl.texCoords.v f3:percentSpriteSize.width f4:percentSpriteSize.height];
    [self.sprite.shaderProgram setUniformLocation:_rectMask withF1:pixelMaskRect.origin.x f2:pixelMaskRect.origin.y f3:percentMaskSize.width f4:percentMaskSize.height];
    [self.sprite.shaderProgram setUniformLocation:_rectDrawMask
                                           withF1:validSpriteRect.origin.x
                                               f2:validSpriteRect.origin.y
                                               f3:validSpriteRect.size.width
                                               f4:validSpriteRect.size.height];
    [self.sprite.shaderProgram setUniformLocation:_startMask withF1:posStartMask.x f2:posStartMask.y];
    [self.sprite.shaderProgram setUniformLocation:_ratioMaskSprite withF1:ratioMaskSprite.x f2:ratioMaskSprite.y];
    
    self.texture.hasPremultipliedAlpha = YES;
    self.sprite.texture.hasPremultipliedAlpha = YES;
}

//- (void)updateUniforms {
//    //L'idée ici c'est de trouver les coordonnées du masque sur le sprite pour les passer au shader qui affichera le sprite masqué
//    //Je trouve ce rectangle à partir des coordonnées des quad et des size du sprite et du masque
//    //On a besoin de trouver la position a laquelle on doit placer la texture du masque par rapport à celle du sprite
//    //finalement dans le cas ou les deux textures seraient differentes on doit appliquer un ratio entre les coordonnées des deux textures
//    
//    // TODO : Prendre en charge l'anchorPoint de self
//    // TODO : Corriger un bug de centrage sur les sprite plus petites que le masque
//    
//    //tailles en % dans leurs textures d'origine
//    CGSize pixelSpriteSize = CGSizeMake( self.sprite.quad.tr.texCoords.u - self.sprite.quad.bl.texCoords.u, self.sprite.quad.bl.texCoords.v - self.sprite.quad.tr.texCoords.v );
//    CGSize pixelMaskSize = CGSizeMake( self.mask.quad.tr.texCoords.u - self.mask.quad.bl.texCoords.u, self.mask.quad.bl.texCoords.v - self.mask.quad.tr.texCoords.v );
//    //tailles en pixels affichés
//    CGSize drawSpriteSize = CGSizeMake( self.sprite.contentSize.width - ( self.sprite.contentSize.width - self.sprite.quad.tr.vertices.x ) - self.sprite.quad.bl.vertices.x, self.sprite.contentSize.height - ( self.sprite.contentSize.height - self.sprite.quad.tr.vertices.y ) - self.sprite.quad.bl.vertices.y );
//    CGSize drawMaskSize = CGSizeMake( self.mask.contentSize.width - ( self.mask.contentSize.width - self.mask.quad.tr.vertices.x ) - self.mask.quad.bl.vertices.x, self.mask.contentSize.height - ( self.mask.contentSize.height - self.mask.quad.tr.vertices.y ) - self.mask.quad.bl.vertices.y );
//    //les rects de sprite et masque
//    CGRect spriteRect = CGRectMake( self.sprite.quad.bl.vertices.x, self.sprite.quad.bl.vertices.y, drawSpriteSize.width, drawSpriteSize.height);
//    CGRect maskRect = CGRectMake( self.mask.quad.bl.vertices.x, self.mask.quad.bl.vertices.y, drawMaskSize.width, drawMaskSize.height );
//    //intersection des deux rects affichés
//    CGRect intersect = CGRectIntersection( spriteRect, maskRect);
//    //offset avec l'anchorpoint
//    CGPoint anchoredOffset = ccp(((self.sprite.contentSize.width) * self.anchorPointMask.x ) - ((self.mask.contentSize.width) * self.anchorPointMask.x ) + self.positionMask.x,
//                                 ((self.sprite.contentSize.height) * (1.0-self.anchorPointMask.y) ) - ((self.mask.contentSize.height) * (1.0-self.anchorPointMask.y) ) - self.positionMask.y);
//    CGRect anchoredMaskRect = CGRectMake( maskRect.origin.x+anchoredOffset.x, maskRect.origin.y+anchoredOffset.y, maskRect.size.width, maskRect.size.height );
//    CGRect anchoredIntersect = CGRectIntersection( spriteRect, anchoredMaskRect);
//    //rect pour la definir la zone autorisée à afficher la sprite ( en % de la texture de sprite )
//    CGRect validSpriteRectPixel = CGRectMake(( anchoredIntersect.origin.x - spriteRect.origin.x + (anchoredOffset.x - spriteRect.origin.x ) ),
//                                             ( anchoredIntersect.origin.y - spriteRect.origin.y + (anchoredOffset.y - ( self.sprite.contentSize.height - self.sprite.quad.tr.vertices.y )) ) ,
//                                             ( anchoredIntersect.size.width + spriteRect.origin.x ),
//                                             ( anchoredIntersect.size.height ));
//    CGRect validSpriteRect = CGRectMake(( validSpriteRectPixel.origin.x ) / ( drawSpriteSize.width / pixelSpriteSize.width ),
//                                        ( validSpriteRectPixel.origin.y ) / ( drawSpriteSize.height / pixelSpriteSize.height ),
//                                        ( validSpriteRectPixel.size.width ) / ( drawSpriteSize.width / pixelSpriteSize.width ),
//                                        ( validSpriteRectPixel.size.height ) / ( drawSpriteSize.height / pixelSpriteSize.height ));
//    //position de debut d'affichage du masque en prenant en compte la position du masque sur la sprite ( en % de la texture du masque )
//    CGPoint posStartMaskPixel = ccp((anchoredIntersect.origin.x - (anchoredOffset.x - maskRect.origin.x )),
//                                    (- (anchoredOffset.y - ( self.sprite.contentSize.height - self.sprite.quad.tr.vertices.y))));
//    CGPoint posStartMask = ccp(-(validSpriteRectPixel.origin.x)/drawMaskSize.width*pixelMaskSize.width+self.mask.quad.tl.texCoords.u,
//                               (-validSpriteRectPixel.origin.y)/(drawMaskSize.height/pixelMaskSize.height)+self.mask.quad.tl.texCoords.v);
//    //ratio entre les % de texture de sprite et de masque ( 1 si la meme texture )
//    CGPoint ratioMaskSprite = ccp((drawSpriteSize.width / drawMaskSize.width) / (pixelSpriteSize.width/pixelMaskSize.width),
//                                  (drawSpriteSize.height / drawMaskSize.height) / (pixelSpriteSize.height/pixelMaskSize.height));
//    NSLog(@"validSpriteRectPixel%@", NSStringFromCGRect(validSpriteRectPixel));
//    //envoi des infos au shader
//    [self.sprite.shaderProgram setUniformLocation:_rectTexture withF1:self.sprite.quad.tl.texCoords.u f2:self.sprite.quad.tl.texCoords.v f3:pixelSpriteSize.width f4:pixelSpriteSize.height];
//    [self.sprite.shaderProgram setUniformLocation:_rectMask withF1:maskRect.origin.x+self.mask.quad.tl.texCoords.u f2:maskRect.origin.y+self.mask.quad.tl.texCoords.v f3:pixelMaskSize.width f4:pixelMaskSize.height];
//    [self.sprite.shaderProgram setUniformLocation:_rectDrawMask
//                                           withF1:validSpriteRect.origin.x+self.sprite.quad.tl.texCoords.u
//                                               f2:validSpriteRect.origin.y+self.sprite.quad.tl.texCoords.v
//                                               f3:validSpriteRect.size.width
//                                               f4:validSpriteRect.size.height];
//    [self.sprite.shaderProgram setUniformLocation:_startMask withF1:posStartMask.x f2:posStartMask.y];
//    [self.sprite.shaderProgram setUniformLocation:_ratioMaskSprite withF1:ratioMaskSprite.x f2:ratioMaskSprite.y];
//    
//    self.texture.hasPremultipliedAlpha = YES;
//    self.sprite.texture.hasPremultipliedAlpha = YES;
//}

-(void) draw {
    DRAW_SETUP();
    
    [self updateUniforms];
    
    ccGLEnableVertexAttribs(kCCVertexAttribFlag_PosColorTex);
    ccGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    [self.sprite.shaderProgram setUniformsForBuiltins];
    
    [self.sprite.texture setAliasTexParameters];
    glActiveTexture(GL_TEXTURE1);
    glBindTexture( GL_TEXTURE_2D, self.mask.texture.name );
    [self.sprite.shaderProgram setUniformLocation:_maskLocation withI1:1];
    
#define kQuadSize sizeof(self.sprite.quad.bl)
//	long offset = (long)&_quad;
    ccV3F_C4B_T2F_Quad q = self.sprite.quad;
    long offset = (long)&q;

    NSInteger diff = offsetof( ccV3F_C4B_T2F, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
    
    diff = offsetof( ccV3F_C4B_T2F, texCoords);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*)(offset + diff));
    
    diff = offsetof( ccV3F_C4B_T2F, colors);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glActiveTexture(GL_TEXTURE0);
}

-(CCTexture2D *)getTexture
{
    CCRenderTexture *renderTexture = [CCRenderTexture renderTextureWithWidth:self.contentSize.width height:self.contentSize.height];
    [renderTexture begin];
    self.flipY = YES;
    [self draw];
    self.flipY = NO;
    [renderTexture end];
    
    return renderTexture.sprite.texture;
}

- (void)dealloc
{
    //[_mask release];
    //self = nil;
    
    //[_maskTexture release];
    _mask = nil;
    
    //[_mask.shaderProgram release];
    
    //[super dealloc];
}

@end
