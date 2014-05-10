Caterpillar
===========

Relative scrolling animation in a fake collection view for iOS.

The animation class `RelativeAnimation` is a simple alternative to Facebook POP animations,
good for animating rapid events and continuous gestures.


### `RelativeAnimation`

Subclass of `CAKeyframeAnimation`. 
You may not set keyframe `values` or `keyTimes`.
Instead you set the `fromValue` and `toValue`,
with an optional `timingBlock`.
This does not work with implicit animation,
instead animations must be explicit.
For implicit animation, there is the `Seamless.framework`.
Opacity animation does not work and rect animation must be broken up into components,
for example position and bounds.size.

#### `@property (strong) id fromValue;`

Required. The animation's apparent start value.

#### `@property (strong) id toValue;`

Required. The animation's apparent end value.

#### `@property (copy) double (^timingBlock)(double);`

A block that takes as an argument animation progress from 0 to 1,
and returns animation progress that can be below 0 and above 1.

#### `@property (assign) BOOL absolute;`

Animations run relative to the underlying model value.
Behind the scenes, animations are additive,
and the from and to values are converted to 
the old value minus the new value to zero.
If absolute is YES, this conversion is not done.

#### `@property (assign) NSUInteger steps;`

The timingBlock is converted to keyframes.
This determines how many are used.
The default is 50.

#### `+(double(^)(double))bezierWithControlPoints:(double)p1x :(double)p1y :(double)p2x :(double)p2y;

A convenience constructor that returns a block that can be used as the `timingBlock`.

#### `+(double(^)(double))perfectBezier;`

Equivalent to `[RelativeAnimation bezierWithControlPoints:0.5 :0.0 :0.5 :1.0];`
This is gives nice blending for interrupted animations.


