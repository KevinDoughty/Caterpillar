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

#import <UIKit/UIKit.h>

@class CaterpillarView;
@class CaterpillarCell;


@protocol CaterpillarDelegate <NSObject, UIScrollViewDelegate>
@required
-(NSRange)caterpillarView:(CaterpillarView*)caterpillarView rangeOfItemsInRect:(CGRect)rect;
-(CGRect)caterpillarView:(CaterpillarView*)caterpillarView rectOfItemAtIndex:(NSUInteger)index;
-(CGRect)caterpillarView:(CaterpillarView*)caterpillarView previousRectOfItemAtIndex:(NSUInteger)index;
@optional
-(void)caterpillarView:(CaterpillarView*)caterpillarView didSelectItemAtIndex:(NSUInteger)index;
@end



@protocol CaterpillarDataSource <NSObject>
@required
-(NSInteger)numberOfItemsInCaterpillarView:(CaterpillarView*)caterpillarView;
-(CaterpillarCell*)caterpillarView:(CaterpillarView*)caterpillarView cellForItemAtIndex:(NSInteger)row;
@end



@interface CaterpillarView : UIScrollView
@property (nonatomic, weak) IBOutlet id <CaterpillarDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id <CaterpillarDelegate> delegate;

-(CaterpillarCell*)dequeueReusableCellWithIdentifier:(NSString*)reuseIdentifier;
-(void)reloadData;
-(CaterpillarCell*)selectedCell;
-(void)updateLayout; // This should not be public. I would prefer to use setNeedsLayout and layoutSubviews but for now it's giving me problems by being called too much


@end
