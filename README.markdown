# 3D Demo in Swift

This is a simple demo app for macOS that shows how to draw a 3D object without using shaders. It illustrates what happens behind the scenes when you use OpenGL or Metal to do 3D drawing.

*Want to know how it works?* Check out [Render.swift](ThreeDee/Render.swift). It has lots of explanations.

Also [read the accompanying blog post](http://machinethink.net/blog/3d-rendering-without-shaders/). It has pretty pictures!

The app doesn't use any 3D or math APIs: everything you see is done by the logic in the **Render.swift** source file. The only API used for drawing is a `setPixel()` function that writes a pixel RGBA value to a bitmap. The math used does not involve matrices, so you can see exactly what happens when and why.

Because this is only intended for educational purposes, there is some stuff that doesn't work super great:

- Triangles are not clipped against the field of view of the camera. This isn't really an issue, unless the z-position of camera comes too close to the vertices, in which case triangles may be drawn incorrectly (upside down or not at all).
- It is quite slow. But of course that's why you'd use a GPU for real 3D work.
