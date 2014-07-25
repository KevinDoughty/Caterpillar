/*
 Copyright (c) 2014, Kevin Doughty
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "KumamonLayoutManager.h"
#import "PeriodicElements.h"
#import "AtomicElementTableViewCell.h"
#import "AtomicElementTileView.h"
#import "AtomicElementViewController.h"

@interface KumamonLayoutManager()
@property (assign) CGFloat layoutState;
@end

@implementation KumamonLayoutManager

-(instancetype)initWithProgress:(CGFloat)progress {
    if ((self = [super init])) {
        _layoutState = progress;
    }
    return self;
}
-(instancetype)copyWithZone:(NSZone*)zone {
    KumamonLayoutManager *copy = [[self class] allocWithZone:zone];
    if (copy) {
        copy->_layoutState = _layoutState;
    }
    return copy;
}

-(CGFloat)itemHeight {
    return 60;
}

-(CGFloat)minimumLineSpacing {
    return 10.0;
}

-(NSRange)caterpillarView:(CaterpillarView*)caterpillarView rangeOfItemsInRect:(CGRect)rect {
    CGFloat itemHeight = [self itemHeight];
    CGRect bounds = caterpillarView.bounds;
    
    NSUInteger sublayersPerRow = [self squaresPerRowInWidth:bounds.size.width * self.layoutState];
    NSUInteger indexOrigin = 0;
    CGFloat yPaddingPercentage = 0;
    CGFloat xPaddingPercentage = 0;
    CGFloat itemDimension = itemHeight;
    CGRect visibleRect = caterpillarView.bounds;
    CGFloat y = (yPaddingPercentage * itemDimension) + (itemDimension + (xPaddingPercentage * itemDimension));
    
    while (y < visibleRect.origin.y) {
        indexOrigin += sublayersPerRow;
        y += (itemDimension + (xPaddingPercentage * itemDimension));
    }
    NSUInteger indexMax = indexOrigin + sublayersPerRow;
    while (y < visibleRect.origin.y + visibleRect.size.height) {
        indexMax += sublayersPerRow;
        y += (itemDimension + (xPaddingPercentage * itemDimension));
    }
    return NSMakeRange(indexOrigin, indexMax - indexOrigin);
}


-(NSUInteger)squaresPerRowInWidth:(CGFloat)width {
    CGFloat xPaddingPercentage = 0;
    CGFloat itemDimension = [self itemHeight];
	NSUInteger theSquaresPerRow = (NSUInteger)floor(width / (itemDimension + (xPaddingPercentage * itemDimension)));
	if (theSquaresPerRow < 1) return 1;
	return theSquaresPerRow;
}

-(CGRect)caterpillarView:(CaterpillarView*)caterpillarView rectOfItemAtIndex:(NSUInteger)index {
    CGFloat height = [self itemHeight];
    CGFloat xPaddingPercentage = 0;
    CGFloat yPaddingPercentage = 0;
    CGFloat itemDimension = height;
    NSUInteger sublayersPerRow = [self squaresPerRowInWidth:caterpillarView.bounds.size.width * self.layoutState];
    CGFloat x = (xPaddingPercentage * itemDimension) + ((CGFloat)(index % sublayersPerRow) * (itemDimension  + (xPaddingPercentage * itemDimension))); // + ((layerWidth /2) + X_PADDING);
    CGFloat y = (yPaddingPercentage * itemDimension) + (floor((CGFloat)index / (CGFloat)sublayersPerRow) * (itemDimension + (yPaddingPercentage * itemDimension))); // + ((layerHeight/2) + Y_PADDING);
    CGFloat w =  (itemDimension  + (xPaddingPercentage * itemDimension));
    CGFloat h = (itemDimension  + (yPaddingPercentage * itemDimension));
    CGRect rect = CGRectMake(roundf(x),roundf(y),roundf(w),roundf(h));
    return rect;
}

@end
