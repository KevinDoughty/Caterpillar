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

#import "KumamonLayoutManager.h"

@interface CaterpillarViewController()
@property (strong) UIScreenEdgePanGestureRecognizer *leftToRightRecognizer;
@property (strong) UIScreenEdgePanGestureRecognizer *rightToLeftRecognizer;
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
    
    KumamonLayoutManager *layoutManager = [[KumamonLayoutManager alloc] initWithProgress:0];
    [(CaterpillarView*)self.view setLayoutManager:layoutManager];
    
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
    KumamonLayoutManager *layoutManager = [[KumamonLayoutManager alloc] initWithProgress:progress];
    [(CaterpillarView*)self.view setLayoutManager:layoutManager];
    
}

#pragma mark - data source

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
    [cell.layer setValue:element.name forKey:@"name"];
    [cell.layer setValue:element.atomicNumber forKey:@"number"];
	return cell;
}

#pragma mark - delegate

-(void)caterpillarView:(CaterpillarView*)caterpillarView didSelectItemAtIndex:(NSUInteger)index {
    UINavigationController *navigationController = (UINavigationController*)caterpillarView.window.rootViewController;
    AtomicElementViewController *viewController = [[AtomicElementViewController alloc] init];
    AtomicElement *element = [[[PeriodicElements sharedPeriodicElements] elementsSortedByNumber] objectAtIndex:index];
    viewController.element = element;
    [navigationController pushViewController:viewController animated:YES];
    
}

@end
