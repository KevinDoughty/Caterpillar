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

@property (assign) NSRange visibleRange;
@property (assign) NSRange animatedRange;

@property (strong) id <NSCopying, CaterpillarDelegate> previousLayoutManager;
@property (assign) NSUInteger fixedIndex;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
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
    //[self determineFixedIndex];
    self.selectedCaterpillarCell = nil;
}

-(CaterpillarCell*)selectedCell {
    return self.selectedCaterpillarCell;
}
#pragma mark - misc


-(CaterpillarCell*)cachedCellForRow:(NSInteger) row {
    return [self.cellCache objectForKey:@(row)];
}

-(void)setCachedCell:(CaterpillarCell*)cell forRow:(NSInteger)row {
    if (cell == nil) [self.cellCache removeObjectForKey:@(row)];
    else [self.cellCache setObject:cell forKey:@(row)];
}

-(void)determineFixedIndex { // Fixed index should be replaced. Instead of finding vertical center, should be fixed at the row under the edge pan gesture location.
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

-(void)didReceiveMemoryWarning:(NSNotification*)notification {
    NSLog(@"memory warning");
    [self reloadData];
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

-(double(^)(double))scrollBlock {
    return ^ (double progress) {
        double omega = 30.0;
        double zeta = 0.8;
        double beta = sqrt(1.0 - zeta * zeta);
        progress = 1.0 / beta * expf(-zeta * omega * progress) * sinf(beta * omega * progress + atanf(beta / zeta));
        return 1-progress;
    };
    return [RelativeAnimation perfectBezier];
}

-(double(^)(double))layoutBlock {
    double (^roundBlock)(double) = [RelativeAnimation perfectBezier];
    double (^pullBlock)(double) = [self elasticBlock];
    return ^(double progress) {
        return roundBlock(pullBlock(progress));
    };
}

-(CGFloat)animationDuration {
    return 2.5;
}

-(CGFloat)animationTimespan {
    return .5;
}

-(CGFloat)layoutDuration {
    return 2.5;
}

-(NSString*)animationKey:(NSString*)key {
    static NSUInteger animationCounter = 0;
    NSString *result = [NSString stringWithFormat:@"%@_%lu",key,(unsigned long)animationCounter++];
    return result;
}


#pragma mark - layout

-(void)updateLayout { // This should not be public. I would prefer to use setNeedsLayout and layoutSubviews but for now it's giving me problems by being called too much. Setting the bounds complicates things.
    NSUInteger middleIndex = self.fixedIndex;
    CGFloat oldMiddle = [self.delegate caterpillarView:self previousRectOfItemAtIndex:middleIndex].origin.y;
    CGFloat newMiddle = [self.delegate caterpillarView:self rectOfItemAtIndex:middleIndex].origin.y;
    if (oldMiddle != newMiddle) {
        //NSLog(@"oldMiddle:%f; newMiddle:%f;",oldMiddle,newMiddle);
        CGRect newBounds = self.bounds;
        CGFloat deltaY = oldMiddle - newMiddle;
        newBounds.origin.y -= deltaY;
        if (newBounds.origin.y < self.contentInset.top * -1) newBounds.origin.y = self.contentInset.top * -1;
        self.bounds = newBounds;
    } else [self syncSubviews];
}

-(void)setBounds:(CGRect)bounds {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setBounds:bounds];
    [self syncSubviews];
    [CATransaction commit];
}

-(void)syncSubviews {
    
    if (self.dataSource && self.delegate) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        NSRange originalRange = self.animatedRange;
        
        NSRange visibleRange = [[self delegate] caterpillarView:self rangeOfItemsInRect:self.bounds];
        self.visibleRange = visibleRange;
        if (self.animatedRange.length == 0) self.animatedRange = visibleRange;
        else self.animatedRange = NSUnionRange(self.animatedRange, visibleRange);
        
        [self clipCellsCleanUp]; // remove non animated cells outside of visible range
        [self addCellsToRange:originalRange]; // insert new cells and copy animations
        [self layoutAllCells];
        
        NSUInteger count = [self.dataSource numberOfItemsInCaterpillarView:self];
        if (count) {
            CGRect lastRect = [[self delegate] caterpillarView:self rectOfItemAtIndex:count-1];
            self.contentSize = CGSizeMake(lastRect.origin.x+lastRect.size.width, lastRect.origin.y + lastRect.size.height);
        } else self.contentSize = self.bounds.size;
        
        
        
        [self animateLayout];
        [CATransaction commit];
    }
}

-(void)copyAnimationsFrom:(CaterpillarCell*)fromCell to:(CaterpillarCell*)toCell {
   
    CALayer *originalLayer = fromCell.layer;
    NSArray *keys = [originalLayer animationKeys];
    
    NSString *incrementString = [self incrementString];
    CALayer *layer = toCell.layer;
    //NSLog(@"[%lu %@] copy:%lu; from:(%lu %@) %lu-%lu (%lu)",[[layer valueForKey:@"number"] unsignedIntegerValue],[layer valueForKey:@"name"],keys.count,[[originalLayer valueForKey:@"number"] unsignedIntegerValue],[originalLayer valueForKey:@"name"],self.animatedRange.location,NSMaxRange(self.animatedRange)-1,self.animatedRange.length);
    for (NSString *key in keys) {
        CAAnimation *animation = [originalLayer animationForKey:key];
        
        if ([key hasPrefix:@"stretching"] || [key hasPrefix:@"scrolling"]) {
            NSNumber *value = [animation valueForKey:incrementString];
            if (value != nil) {
                CGFloat increment = [value floatValue];
                animation = animation.copy;
                animation.beginTime += increment;
            }
        }
        [layer addAnimation:animation forKey:key];
    }
}

-(void)layoutAllCells {
    for (NSUInteger row = self.animatedRange.location; row < NSMaxRange(self.animatedRange); row++) {
        CGRect frame = [[self delegate] caterpillarView:self rectOfItemAtIndex:row];
        CaterpillarCell *cell = [self cachedCellForRow:row];
        if (!cell) {
            cell = [[self dataSource] caterpillarView:self cellForItemAtIndex:row];
            [self setCachedCell:cell forRow:row];
            [self addSubview:cell];
        }
        cell.frame = frame;
    }
}

-(void)addCellsToRange:(NSRange)originalRange {
    if (!self.visibleRange.length) return;
    
    if (self.animatedRange.location < originalRange.location) {
        NSUInteger visibleLoc = NSMaxRange(self.visibleRange);
        NSUInteger animatedLoc = self.animatedRange.location;
        CaterpillarCell *previousCell = [self cachedCellForRow:visibleLoc];
        while (visibleLoc-- > animatedLoc) {
            CaterpillarCell *cell = [self cachedCellForRow:visibleLoc];
            if (!cell) {
                //NSLog(@"- row:%ld; vis:%@; anim:%@; orig:%@;",visibleLoc,NSStringFromRange(self.visibleRange),NSStringFromRange(self.animatedRange),NSStringFromRange(originalRange));
                cell = [[self dataSource] caterpillarView:self cellForItemAtIndex:visibleLoc];
                [self setCachedCell:cell forRow:visibleLoc];
                [self addSubview:cell];
                [self copyAnimationsFrom:previousCell to:cell];
            }
            previousCell = cell;
        }
    }
    if (NSMaxRange(self.animatedRange) > NSMaxRange(originalRange)) {
        CaterpillarCell *previousCell = previousCell = [self cachedCellForRow:self.visibleRange.location];
        for (NSUInteger row = self.visibleRange.location; row < NSMaxRange(self.animatedRange); row++) {
            CaterpillarCell *cell = [self cachedCellForRow:row];
            if (!cell) {
                //NSLog(@"+ row:%ld; vis:%@; anim:%@; orig:%@;",row,NSStringFromRange(self.visibleRange),NSStringFromRange(self.animatedRange),NSStringFromRange(originalRange));
                cell = [[self dataSource] caterpillarView:self cellForItemAtIndex:row];
                [self setCachedCell:cell forRow:row];
                [self addSubview:cell];
                [self copyAnimationsFrom:previousCell to:cell];
            }
            previousCell = cell;
        }
    }
}

-(void)clipCellsCleanUp {
    
    NSRange newRange = self.animatedRange;
    NSUInteger animatedTop = NSMaxRange(self.animatedRange);
    NSUInteger animatedBottom = self.animatedRange.location;
    const NSUInteger visibleTop = NSMaxRange(self.visibleRange);
    const NSUInteger visibleBottom = self.visibleRange.location;
    
    while (animatedTop-- > visibleTop) {
        CaterpillarCell *view = [self cachedCellForRow:animatedTop];
        if (view) {
            CALayer *layer = view.layer;
            if (layer.animationKeys.count == 0) {
                [[self reusePool] addObject:view];
                [view removeFromSuperview];
                [self setCachedCell:nil forRow:animatedTop];
                newRange.length--;
            } else break;
        }
    }
    while (animatedBottom < visibleBottom) {
        CaterpillarCell *view = [self cachedCellForRow:animatedBottom];
        if (view) {
            CALayer *layer = view.layer;
            if (layer.animationKeys.count == 0) {
                [[self reusePool] addObject:view];
                [view removeFromSuperview];
                [self setCachedCell:nil forRow:animatedBottom];
                newRange.location++;
                newRange.length--;
            } else break;
        }
        animatedBottom++;
    }
    self.animatedRange = newRange;
}

-(NSString*)incrementString {
    return @"caterpillarIncrement";
}
-(void)animateLayout {
    
    BOOL scroll = YES;
    BOOL stretch = YES;
    BOOL layout = YES;
    BOOL adjust = YES;
    
    CGFloat oldY = self.previousOffset.y;
    CGFloat newY = self.contentOffset.y;
    CGFloat deltaY = newY - oldY;
    BOOL isScrolling = CGSizeEqualToSize(self.previousSize, self.contentSize);
    
    CGFloat timespan = [self animationTimespan];
    CGFloat duration = [self animationDuration];
    
    NSString *incrementString = [self incrementString];
    
    if (isScrolling) {
        adjust = NO;
        layout = NO;
    } else {
        scroll = NO;
        stretch = NO;
    }
    
    NSRange animatedRange = self.animatedRange;
    NSRange visibleRange = self.visibleRange;
    NSUInteger animatedMax = NSMaxRange(animatedRange);
    NSUInteger visibleMax = NSMaxRange(visibleRange);
    NSUInteger animatedLoc = animatedRange.location;
    NSUInteger visibleLoc = visibleRange.location;
    NSUInteger animatedLength = animatedRange.length;
    NSUInteger visibleLength = visibleRange.length;
    
    CGFloat space = (timespan / visibleLength);
    CGFloat longer = duration + space;
    
    double (^scrollTimingBlock)(double) = [self scrollBlock];
    
    RelativeAnimation *scrolling = [RelativeAnimation animationWithKeyPath:@"position.y"];
    scrolling.fromValue = @(newY);
    scrolling.toValue = @(oldY);
    scrolling.duration = duration;
    scrolling.timingBlock = scrollTimingBlock;
    [scrolling setValue:@(space) forKey:incrementString];
    
    RelativeAnimation *stretching = [RelativeAnimation animationWithKeyPath:@"transform.scale.y"];
    stretching.absolute = YES;
    [stretching setValue:@(space) forKey:incrementString];
    
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
        index = animatedLength-1;
    }
    
    CGFloat addTime = CACurrentMediaTime();
    
    for (NSUInteger row = animatedLoc; row < animatedMax; row++) {
        
        CaterpillarCell *view = [self cachedCellForRow:row];
        if (view == nil) NSLog(@"no view at row:%lu; index:%lu; length:%lu;",(unsigned long)row,(unsigned long)index,(unsigned long)animatedLength);
        else {
            
            double delay = ((double)index) * space;
            double late = (((double)index) + 1) * space;
            
            double scrollTime = addTime + delay;
            double stretchTime = addTime + delay;
            double waveTime = addTime + delay;
            double shrinkTime = addTime + delay;
            
            double layoutTime = addTime;
            double adjustTime = addTime;
            
            if (direction > 0) {
                if (animatedLoc < visibleLoc) {
                    double adjust = space * (visibleLoc - animatedLoc);
                    scrollTime -= adjust;
                    stretchTime -= adjust;
                    shrinkTime -= adjust;
                    waveTime -= adjust;
                }
            } else if (direction < 0) {
                
                scrollTime = addTime + late;
                
                if (visibleMax < animatedMax) {
                    double adjust = space * (animatedMax - visibleMax);
                    scrollTime -= adjust;
                    stretchTime -= adjust;
                    shrinkTime -= adjust;
                    waveTime -= adjust;
                }
            }
            
            scrolling.beginTime = scrollTime;
            stretching.beginTime = stretchTime;
            stretching.duration = longer;
            
            sizing.beginTime = layoutTime;
            positioning.beginTime = layoutTime;
            adjusting.beginTime = adjustTime;
            
            
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
            
            if (scroll) {
                NSString *scrollString = [self animationKey:@"scrolling"];
                [view.layer addAnimation:scrolling forKey:scrollString];
            }
            
            if (stretch) {
                CGFloat height = view.bounds.size.height;
                CGFloat full = height + abs(deltaY);
                CGFloat ratio = full / height;
                stretching.fromValue = @0.0f;
                stretching.toValue = @(ratio-1.0f);
                stretching.timingBlock = differenceTimingBlock;
                NSString *stretchString = [self animationKey:@"stretching"];
                [view.layer addAnimation:stretching forKey:stretchString];
            }
            
            if (adjust) {
                NSString *adjustString = [self animationKey:@"adjusting"];
                [view.layer addAnimation:adjusting forKey:adjustString];
            }
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
                NSString *sizeString = [self animationKey:@"sizing"];
                [view.layer addAnimation:sizing forKey:sizeString];
                
                positioning.beginTime = layoutTime;
                positioning.fromValue = [NSValue valueWithCGPoint:oldPosition];
                positioning.toValue = [NSValue valueWithCGPoint:newPosition];
                NSString *positionString = [self animationKey:@"positioning"];
                [view.layer addAnimation:positioning forKey:positionString];
            }
        }
        index+=direction;
    }
    
    self.previousSize = self.contentSize;
    self.previousOffset = self.contentOffset;
    if (isScrolling) [self determineFixedIndex];
}

@end

