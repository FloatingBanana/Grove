# Gröve
Mini graphics libraries for love2d.

[animation.lua](./grove/animation.lua) Create animations using image sequences.

[chainshaders.lua](./grove/chainshaders.lua) Apply multiple shaders at once.

[color.lua](./grove/color.lua) Blend, convert and interpolate colors.

[draworder.lua](./grove/draworder.lua) Adds a layer system, allowing you to call functions in a specific order.

[resolution.lua](./grove/resolution.lua) Helps your game to fit in any window size.

***

## For non-love2d users
[color.lua](./grove/color.lua) is completely independent from love2d and should work in any lua >= 5.1 project. [draworder.lua](./grove/draworder.lua) should also work as long you don't pass a string in the function argument.

## Documentation
Documentation and examples are available in the [wiki](https://github.com/FloatingBanana/Grove/wiki) page.

## License
This library is released under the MIT License.