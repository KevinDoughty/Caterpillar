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

#import "CaterpillarViewController.h"
#import "CaterpillarView.h"
#import "AtomicElementTableViewCell.h"
#import "PeriodicElements.h"
#import "AtomicElement.h"
#import "AtomicElementTileView.h"
#import "AtomicElementViewController.h"

@interface CaterpillarViewController()
@property (strong) UIScreenEdgePanGestureRecognizer *leftToRightRecognizer;
@property (strong) UIScreenEdgePanGestureRecognizer *rightToLeftRecognizer;
@property (assign) CGFloat previousLayoutState;
@end

@implementation CaterpillarViewController

-(CaterpillarView*)caterpillarView {
    return (CaterpillarView*)self.view;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {

    }
    return self;
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTitle: @"Caterpillar Scroll"];
    
    [self.view setBackgroundColor: [UIColor whiteColor]];
    [(CaterpillarView*)self.view reloadData];
    
    self.rightToLeftRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightToLeftPan:)];
    self.rightToLeftRecognizer.edges = UIRectEdgeRight;
    self.leftToRightRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftToRightPan:)];
    self.leftToRightRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:self.leftToRightRecognizer];
    
}

-(void)handleLeftToRightPan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    CGFloat progress = MAX(MIN((location.x / self.view.bounds.size.width), 1.0), 0.0);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (progress > 0.5) {
            [self updateLayoutWithProgress:1];
            [self.view removeGestureRecognizer:self.leftToRightRecognizer];
            [self.view addGestureRecognizer:self.rightToLeftRecognizer];
        } else [self updateLayoutWithProgress:0];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled) {
        [self updateLayoutWithProgress:0];
    } else if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self updateLayoutWithProgress:0];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self updateLayoutWithProgress:progress];
    }
}

-(void)handleRightToLeftPan:(UIScreenEdgePanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    CGFloat progress = MAX(MIN((location.x / self.view.bounds.size.width), 1.0), 0.0);
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (progress < 0.5) {
            [self updateLayoutWithProgress:0];
            [self.view removeGestureRecognizer:self.rightToLeftRecognizer];
            [self.view addGestureRecognizer:self.leftToRightRecognizer];
        } else [self updateLayoutWithProgress:1];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled) {
        [self updateLayoutWithProgress:1];
    } else if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self updateLayoutWithProgress:1];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self updateLayoutWithProgress:progress];
    }
}

-(void)updateLayoutWithProgress:(CGFloat)progress {
    self.layoutState = progress;
    [(CaterpillarView*)self.view updateLayout]; // I would prefer to use setNeedsLayout and layoutSubviews but for now it's giving me problems by being called too much
}

-(void)setLayoutState:(CGFloat)layoutState {
    self.previousLayoutState = self.layoutState;
    _layoutState = layoutState;
}

#pragma mark - data source and delegate

-(CGFloat)itemHeight {
    return 60;
}

-(CGFloat)minimumLineSpacing {
    return 10.0;
}

-(NSRange)caterpillarView:(CaterpillarView*)caterpillarView rangeOfItemsInRect:(CGRect)rect {
    CGFloat itemHeight = [self itemHeight]; //+ [self minimumLineSpacing];
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
    NSRange theRange = NSMakeRange(indexOrigin, indexMax - indexOrigin);
    NSRange fullRange = NSMakeRange(0, [self numberOfItemsInCaterpillarView:caterpillarView]);
    NSRange finalRange = NSIntersectionRange(theRange,fullRange);
    
    return finalRange;
}

-(NSUInteger)squaresPerRowInWidth:(CGFloat)width {
    CGFloat xPaddingPercentage = 0;
    CGFloat itemDimension = [self itemHeight];
	NSUInteger theSquaresPerRow = (NSUInteger)floor(width / (itemDimension + (xPaddingPercentage * itemDimension)));
	if (theSquaresPerRow < 1) return 1;
	return theSquaresPerRow;
}

-(CGRect)caterpillarView:(CaterpillarView*)caterpillarView rectOfItemAtIndex:(NSUInteger)index {
    return [self rectOfItemAtIndex:index width:caterpillarView.bounds.size.width state:self.layoutState];
}

-(CGRect)caterpillarView:(CaterpillarView*)caterpillarView previousRectOfItemAtIndex:(NSUInteger)index {
    return [self rectOfItemAtIndex:index width:caterpillarView.bounds.size.width state:self.previousLayoutState];
}

-(CGRect)rectOfItemAtIndex:(NSUInteger)index width:(CGFloat)width state:(CGFloat)state  {
    CGFloat height = [self itemHeight];
    if (state == 0) {
        CGRect rect = CGRectMake(0,index * (height + 0),width,height);
        return rect;
    } else {
        CGFloat xPaddingPercentage = 0;
        CGFloat yPaddingPercentage = 0;
        CGFloat itemDimension = height;
        NSUInteger sublayersPerRow = [self squaresPerRowInWidth:width * state];
        CGFloat x = (xPaddingPercentage * itemDimension) + ((CGFloat)(index % sublayersPerRow) * (itemDimension  + (xPaddingPercentage * itemDimension)));
        CGFloat y = (yPaddingPercentage * itemDimension) + (floor((CGFloat)index / (CGFloat)sublayersPerRow) * (itemDimension + (yPaddingPercentage * itemDimension)));
        CGFloat w =  (itemDimension  + (xPaddingPercentage * itemDimension));
        CGFloat h = (itemDimension  + (yPaddingPercentage * itemDimension));
        CGRect rect = CGRectMake(roundf(x),roundf(y),roundf(w),roundf(h));
        return rect;
    }
}

-(NSInteger)numberOfItemsInCaterpillarView:(CaterpillarView*)caterpillarView {
    NSUInteger count = [[[PeriodicElements sharedPeriodicElements] elementsSortedByNumber] count];
    return count;
}

-(CaterpillarCell*)caterpillarView:(CaterpillarView*)caterpillarView cellForItemAtIndex:(NSInteger)row {
    NSString *identifier = @"AtomicElementTableViewCell";
    AtomicElement *element = [[[PeriodicElements sharedPeriodicElements] elementsSortedByNumber] objectAtIndex:row];
	AtomicElementTableViewCell *cell = (AtomicElementTableViewCell *)[caterpillarView dequeueReusableCellWithIdentifier:identifier];
    if (!cell)  {
        cell = [[AtomicElementTableViewCell alloc] initWithReuseIdentifier:identifier];
        AtomicElementTileView *elementTileView = [[AtomicElementTileView alloc] initWithFrame:CGRectMake(8,8,48,48)];
        elementTileView.element = element;
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(80,0,caterpillarView.bounds.size.width-80,64)];
        [cell addSubview:elementTileView];
        [cell addSubview:label];
    }
    cell.element = element;
    cell.layer.anchorPoint = CGPointMake(.5, 0);
    [cell.layer setValue:element.name forKey:@"name"];
    [cell.layer setValue:element.atomicNumber forKey:@"number"];
	return cell;
}

-(void)caterpillarView:(CaterpillarView*)caterpillarView didSelectItemAtIndex:(NSUInteger)index {
    UINavigationController *navigationController = (UINavigationController*)caterpillarView.window.rootViewController;
    AtomicElementViewController *viewController = [[AtomicElementViewController alloc] init];
    AtomicElement *element = [[[PeriodicElements sharedPeriodicElements] elementsSortedByNumber] objectAtIndex:index];
    viewController.element = element;
    [navigationController pushViewController:viewController animated:YES];
    
}

@end
