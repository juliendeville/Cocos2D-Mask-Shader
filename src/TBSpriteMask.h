//
//  TBSpriteMask.h
//  ShaderMask
//
//  Created by Tony BELTRAMELLI on 26/01/13.
//
//

#import "cocos2d.h"

@interface TBSpriteMask : CCSprite
{
    GLuint _maskLocation;
    GLuint _rectTexture;
    GLuint _rectMask;
    GLuint _rectDrawMask;
    GLuint _maskCoord;
    GLuint _startMask;
    GLuint _ratioMaskSprite;
    
//    CGPoint _ratioMask;
//    CGPoint _startMask;
    
    CGPoint _startDrawMask;
    CGPoint _sizeDrawMask;
}

@property (nonatomic) CGPoint positionSpriteStart;
@property (nonatomic) CGPoint anchorPointMask;
@property (nonatomic) CGPoint positionMask;
@property (nonatomic) BOOL type;
@property (nonatomic,strong) CCSprite *sprite;
@property (nonatomic,strong) CCSprite *mask;

+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName;
+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask;
+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positiveMask:(BOOL)positive;
+(instancetype)spriteWithSprite:(CCSprite *)sprite maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask positiveMask:(BOOL)positive;

+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName;
+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask;
+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positiveMask:(BOOL)positive;
+(instancetype)spriteWithSpriteFrameName:(NSString *)spriteFrameName maskSpriteFrameName:(NSString *)maskSpriteFrameName positionMask:(CGPoint)positionMask positiveMask:(BOOL)positive;

-(void) buildMaskWithTexture:(CCSprite*)texture;
-(CCTexture2D *)getTexture;

@end
