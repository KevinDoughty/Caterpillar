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

#import "CaterpillarView.h"
#import "CaterpillarCell.h"
#import "RelativeAnimation.h"


@interface CaterpillarView ()


@property (nonatomic, strong) NSMutableSet *reusePool;
@property (strong) NSMutableDictionary *cellCache;

@property (strong) CaterpillarCell *leadingCell;
@property (strong) CaterpillarCell *trailingCell;

@property (assign) NSRange visibleRange;
@property (assign) NSRange animatedRange;

@property (strong) id <NSCopying, CaterpillarDelegate> previousLayoutManager;
@property (assign) CGPoint previousContentOffset;
@property (assign) CGRect previousBounds;
@property (assign) NSUInteger fixedIndex;
@property (assign) CGRect previousFrame;
@property (assign) CGSize previousSize;
@property (assign) CGPoint previousOffset;

@property (strong) CaterpillarCell *selectedCaterpillarCell;

@end

@implementation CaterpillarView


#pragma mark - init and dealloc



-(id)initWithCoder:(NSCoder*)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self prepareView];
    }
    return self;
}


-(id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self prepareView];
    }
    return self;
}

-(void)prepareView {
    self.cellCache = [NSMutableDictionary dictionary];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}


#pragma mark - public

-(CaterpillarCell*)dequeueReusableCellWithIdentifier:(NSString*)reuseIdentifier {
    CaterpillarCell *cell = nil;
    for (CaterpillarCell *queued in [self reusePool]) {
        if ([[queued reuseIdentifier] isEqualToString:reuseIdentifier]) {
            cell = queued;
            break;
        }
    }
    if (cell) {
        [[self reusePool] removeObject:cell];
        [cell.layer removeAllAnimations];
    }
    return cell;
}

-(void)reloadData {
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[CaterpillarCell class]]) {
            [view removeFromSuperview];
        }
    }
    [self.cellCache removeAllObjects];
    [[self reusePool] removeAllObjects];
    [self syncSubviews];
    [self determineFixedIndex];
    self.selectedCaterpillarCell = nil;
}

-(CaterpillarCell*)selectedCell {
    return self.selectedCaterpillarCell;
}

#pragma mark - layout

-(void)updateLayout { // This should not be public. I would prefer to use setNeedsLayout and layoutSubviews but for now it's giving me problems by being called too much    
    NSUInteger middleIndex = self.fixedIndex;
    CGRect oldMiddle = [self.delegate caterpillarView:self previousRectOfItemAtIndex:middleIndex];
    CGRect newMiddle = [self.delegate caterpillarView:self rectOfItemAtIndex:middleIndex];
    if (oldMiddle.origin.y != newMiddle.origin.y) {
        CGRect newBounds = self.bounds;
        CGFloat deltaY = oldMiddle.origin.y - newMiddle.origin.y;
        newBounds.origin.y -= deltaY;
        if (newBounds.origin.y < self.contentInset.top * -1) newBounds.origin.y = self.contentInset.top * -1;
        self.bounds = newBounds;
    } else [self syncSubviews];
}

-(void)syncSubviews {
    
    if (self.dataSource && self.delegate) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        NSRange visibleRange = [[self delegate] caterpillarView:self rangeOfItemsInRect:self.bounds];
        self.visibleRange = visibleRange;
        if (self.animatedRange.length == 0) self.animatedRange = visibleRange;
        else self.animatedRange = NSUnionRange(self.animatedRange, visibleRange);
        
        [self cleanUp];
        
        for (NSUInteger row = self.animatedRange.location; row < NSMaxRange(self.animatedRange); row++) {
            CGRect frame = [[self delegate] caterpillarView:self rectOfItemAtIndex:row];
            CaterpillarCell *cell = [self cachedCellForRow:row];
            if (!cell) {
                cell = [[self dataSource] caterpillarView:self cellForItemAtIndex:row];
                [self setCachedCell:cell forRow:row];
                [self addSubview:cell];
            }
            cell.layer.anchorPoint = CGPointMake(.5, 0);
            cell.frame = frame;
        }
        
        NSUInteger count = [self.dataSource numberOfItemsInCaterpillarView:self];
        if (count) {
            CGRect lastRect = [[self delegate] caterpillarView:self rectOfItemAtIndex:count-1];
            self.contentSize = CGSizeMake(lastRect.origin.x+lastRect.size.width, lastRect.origin.y + lastRect.size.height);
        } else self.contentSize = self.bounds.size;
        
        
        
        [self animateLayout];
        [CATransaction commit];
    }
}

-(void)cleanUp {
    
    NSRange newRange = self.animatedRange;
    NSUInteger above = NSMaxRange(self.animatedRange);
    NSUInteger top = NSMaxRange(self.visibleRange);
    NSUInteger below = self.animatedRange.location;
    NSUInteger bottom = self.visibleRange.location;
    while (above-- > top) {
        CaterpillarCell *view = [self cachedCellForRow:above];
        if (view) {
            CALayer *layer = view.layer;
            if (layer.animationKeys.count == 0) {
                [[self reusePool] addObject:view];
                [view removeFromSuperview];
                [self setCachedCell:nil forRow:above];
                newRange.length--;
            } else break;
        }
    }
    while (below < bottom) {
        CaterpillarCell *view = [self cachedCellForRow:below];
        if (view) {
            CALayer *layer = view.layer;
            if (layer.animationKeys.count == 0) {
                [[self reusePool] addObject:view];
                [view removeFromSuperview];
                [self setCachedCell:nil forRow:below];
                newRange.location++;
                newRange.length--;
            } else break;
        }
        below++;
    }
    self.animatedRange = newRange;
}

-(CaterpillarCell*)cachedCellForRow:(NSInteger) row {
    return [self.cellCache objectForKey:@(row)];
}

-(void)setCachedCell:(CaterpillarCell*)cell forRow:(NSInteger)row {
    if (cell == nil) [self.cellCache removeObjectForKey:@(row)];
    else [self.cellCache setObject:cell forKey:@(row)];
}

-(void)determineFixedIndex {
    NSRange range = [self.delegate caterpillarView:self rangeOfItemsInRect:self.bounds];
    self.fixedIndex = roundf(range.length/2.0) + range.location;
}

-(void)handleTap:(UITapGestureRecognizer*)recognizer {
    if ([self.delegate respondsToSelector:@selector(caterpillarView:didSelectItemAtIndex:)]) {
        CGPoint location = [recognizer locationInView:self];
        NSArray *keys = [self.cellCache allKeys];
        for (NSNumber *key in keys) {
            NSUInteger index = [key unsignedIntegerValue];
            UIView *view = [self.cellCache objectForKey:key];
            CGRect frame = view.frame;
            if ([view isKindOfClass:[CaterpillarCell class]] && CGRectContainsPoint(frame, location)) {
                self.selectedCaterpillarCell = (CaterpillarCell*)view;
                [self.delegate caterpillarView:self didSelectItemAtIndex:index];
                break;
            }
        }
    }
}

-(NSMutableSet*)reusePool {
    if (!_reusePool) _reusePool = [[NSMutableSet alloc] init];
    return _reusePool;
}


#pragma mark - seamless

-(double(^)(double))elasticBlock {
    return ^ (double progress) {
        double omega = 10.0;
        double zeta = 0.7;
        double beta = sqrt(1.0 - zeta * zeta);
        progress = 1.0 / beta * expf(-zeta * omega * progress) * sinf(beta * omega * progress + atanf(beta / zeta));
        return 1-progress;
    };
}

-(double(^)(double))timingBlock {
    return [RelativeBezier perfectBezier];
}

-(double(^)(double))layoutBlock {
    double (^roundBlock)(double) = [RelativeBezier perfectBezier];
    double (^pullBlock)(double) = [self elasticBlock];
    return ^(double progress) {
        return roundBlock(pullBlock(progress));
    };
}

-(CGFloat)animationDuration {
    return .25;
}

-(CGFloat)animationTimespan {
    return .5;
}

-(CGFloat)layoutDuration {
    return 2.5;
}

-(NSString*)animationKey:(NSString*)key {
    static NSUInteger animationCounter = 0;
    NSString *result = [NSString stringWithFormat:@"%@%lu",key,(unsigned long)animationCounter];
    animationCounter++;
    return result;
}

-(void)setBounds:(CGRect)bounds {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setBounds:bounds];
    [self syncSubviews];
    [CATransaction commit];
}

-(void)animateLayout {
    
    CGFloat oldY = self.previousOffset.y;
    CGFloat newY = self.contentOffset.y;
    CGFloat deltaY = newY - oldY;
    
    CGFloat oldH = self.previousSize.height;
    CGFloat newH = self.contentSize.height;
    CGFloat deltaH = newH - oldH;
    
    CGFloat timespan = [self animationTimespan];
    CGFloat duration = [self animationDuration];
    
    BOOL scroll = YES;
    BOOL stretch = YES;
    BOOL layout = YES;
    BOOL adjust = YES;
    BOOL compensateForDelay = YES;
    BOOL copyAnimations = YES;
    
    
    BOOL isScrolling = (deltaH == 0);
    if (isScrolling) {
        adjust = NO;
        layout = NO;
    } else {
        scroll = NO;
        stretch = NO;
    }
    
    NSArray *oldVisible = self.subviews;
    
    NSArray *newVisible = self.subviews;
    NSMutableArray *insertedCells = newVisible.mutableCopy;
    [insertedCells removeObjectsInArray:oldVisible];
    
    NSArray *cells = [self subviews];
    
    if (cells.count) {
        
        CGFloat topInset = self.contentInset.top;
        CGRect adjustedBounds = self.bounds;
        adjustedBounds.size.height -= topInset;
        adjustedBounds.origin.y += topInset;
        NSUInteger length = self.animatedRange.length;
        NSUInteger visible = self.visibleRange.length;
        
        CGFloat space = (timespan / length);
        if (compensateForDelay) space = (timespan / visible);
        CGFloat longer = duration + space;
        
        double (^scrollTimingBlock)(double) = [self timingBlock];
        
        RelativeAnimation *scrolling = [RelativeAnimation animationWithKeyPath:@"position.y"];
        scrolling.fromValue = @(newY);
        scrolling.toValue = @(oldY);
        scrolling.duration = duration;
        scrolling.timingBlock = scrollTimingBlock;
        
        RelativeAnimation *stretching = [RelativeAnimation animationWithKeyPath:@"transform.scale.y"];
        stretching.absolute = YES;
        
        RelativeAnimation *sizing = [RelativeAnimation animationWithKeyPath:@"bounds.size"];
        sizing.duration = [self layoutDuration];
        sizing.timingBlock = [self layoutBlock];
        
        RelativeAnimation *positioning = [RelativeAnimation animationWithKeyPath:@"position"];
        positioning.duration = [self layoutDuration];
        positioning.timingBlock = [self layoutBlock];
        
        RelativeAnimation *adjusting = [RelativeAnimation animationWithKeyPath:@"position.y"];
        adjusting.timingBlock = [self layoutBlock];
        adjusting.duration = [self layoutDuration];
        adjusting.toValue = @(oldY);
        adjusting.fromValue = @(newY);
        
        NSUInteger index = 0;
        NSInteger direction = 1;
        if (deltaY < 0) {
            direction = -1;
            index = length-1;
        }
        
        CGFloat addTime = CACurrentMediaTime();
        
        if (copyAnimations) {
            
            
            CALayer *originalLayer = nil;
            if (deltaY < 0) originalLayer = self.leadingCell.layer;
            else originalLayer = self.trailingCell.layer;
            
            NSArray *keys = [originalLayer animationKeys];
            
            for (CaterpillarCell *insertedCell in insertedCells) {
                CALayer *layer = insertedCell.layer;
                for (NSString *key in keys) {
                    CAAnimation *animation = [originalLayer animationForKey:key];
                    [layer addAnimation:animation forKey:key];
                }
            }
            self.leadingCell = newVisible.firstObject;
            self.trailingCell = newVisible.lastObject;
        }
        
        NSRange range = self.animatedRange;
        
        for (NSUInteger row = range.location; row < NSMaxRange(range); row++) {
            
            CaterpillarCell *view = [self cachedCellForRow:row];
            if (view == nil) NSLog(@"no view at row:%lu; index:%lu; length:%lu;",(unsigned long)row,(unsigned long)index,(unsigned long)length);
            else {
                
                double delay = ((double)index) * space;
                double late = (((double)index) + 1) * space;
                
                double scrollTime = addTime + delay;
                double stretchTime = addTime + delay;
                double waveTime = addTime + delay;
                double shrinkTime = addTime + delay;//late;
                
                NSInteger layoutIncrement = self.fixedIndex - index;
                layoutIncrement = abs(layoutIncrement);
                
                double layoutTime = addTime;
                double adjustTime = addTime;
                
                if (direction < 0) {
                    scrollTime = addTime + late;
                }
                if (compensateForDelay) {
                    if (direction > 0) {
                        if (self.animatedRange.location < self.visibleRange.location) {
                            double adjust = space * (self.visibleRange.location - self.animatedRange.location);
                            scrollTime -= adjust;
                            stretchTime -= adjust;
                            shrinkTime -= adjust;
                            waveTime -= adjust;
                        }
                    } else if (direction < 0) {
                        if (NSMaxRange(self.visibleRange) < NSMaxRange(self.animatedRange)) {
                            double adjust = space * (NSMaxRange(self.animatedRange) - NSMaxRange(self.visibleRange));
                            scrollTime -= adjust;
                            stretchTime -= adjust;
                            shrinkTime -= adjust;
                            waveTime -= adjust;
                        }
                    }
                }
                scrolling.beginTime = scrollTime;
                stretching.beginTime = stretchTime;
                
                sizing.beginTime = layoutTime;
                positioning.beginTime = layoutTime;
                adjusting.beginTime = adjustTime;
                
                stretching.duration = longer;
                
                double timeDiff = longer/duration;
                
                double (^earlyTimingBlock)(double) = ^double (double progress) {
                    return MIN(1, progress * timeDiff);
                };
                double (^lateTimingBlock)(double) = ^double (double progress) {
                    return MAX(0,(progress * timeDiff) - (timeDiff-1));
                };
                double (^differenceTimingBlock)(double) = ^double (double progress) {
                    double earlier = scrollTimingBlock(earlyTimingBlock(progress));
                    double later = scrollTimingBlock(lateTimingBlock(progress));
                    double final = earlier - later;
                    return final;
                };
                
                if (scroll) [view.layer addAnimation:scrolling forKey:[self animationKey:@"scrolling"]];
                
                if (stretch) {
                    CGFloat height = view.bounds.size.height;
                    CGFloat full = height + abs(deltaY);
                    CGFloat ratio = full / height;
                    stretching.fromValue = @0.0f;
                    stretching.toValue = @(ratio-1.0f);
                    stretching.timingBlock = differenceTimingBlock;
                    [view.layer addAnimation:stretching forKey:[self animationKey:@"stretching"]];
                }
                
                if (adjust) [view.layer addAnimation:adjusting forKey:[self animationKey:@"adjusting"]];
                
                if (layout) {
                    CGRect oldRect = [self.delegate caterpillarView:self previousRectOfItemAtIndex:row];
                    CGSize oldSize = oldRect.size;
                    CGPoint oldPosition = CGPointMake(oldRect.origin.x, oldRect.origin.y);
                    CGRect newRect = [self.delegate caterpillarView:self rectOfItemAtIndex:row];
                    CGSize newSize = newRect.size;
                    CGPoint newPosition = CGPointMake(newRect.origin.x, newRect.origin.y);
                    
                    sizing.beginTime = layoutTime;
                    sizing.fromValue = [NSValue valueWithCGSize:oldSize];
                    sizing.toValue = [NSValue valueWithCGSize:newSize];
                    [view.layer addAnimation:sizing forKey:[self animationKey:@"sizing"]];
                    
                    positioning.beginTime = layoutTime;
                    positioning.fromValue = [NSValue valueWithCGPoint:oldPosition];
                    positioning.toValue = [NSValue valueWithCGPoint:newPosition];
                    [view.layer addAnimation:positioning forKey:[self animationKey:@"positioning"]];
                }
            }
            index+=direction;
        }
    }
    
    self.previousBounds = self.bounds;
    self.previousFrame = self.frame;
    self.previousSize = self.contentSize;
    self.previousOffset = self.contentOffset;
    if (isScrolling) [self determineFixedIndex];
}

@end

