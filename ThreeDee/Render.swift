import Foundation

/*
  This app shows how to draw a 3D object without using shaders. It illustrates
  what happens behind the scenes when you use OpenGL or Metal to do 3D drawing.

  The only rendering primitive we have at our disposal is writing individual
  pixels to a bitmap.

  NOTE: Because it's a demo app, it skips a bunch of important details, but at
  least it should bring across the general idea.

  WARNING: It's pretty slow! This is not an example of how to make fast 3D gfx,
  only of how the underlying ideas work. ;-)

  To understand what happens when Metal or OpenGL draw 3D graphics, just read
  this source file from top to bottom (and run the app).

  ----------

  A high-level overview of how the app works:

  When you run the app you'll see a bouncing and spinning cube. The slider
  represents the x-position of the camera. Move the slider and the scene moves
  with it, because the camera is being repositioned in the 3D world.

  The important files in this project are:
  
  - ViewController.swift   handles the UI and animations
  - Primitives.swift       provides the setPixel() function
  - Render.swift           does all the cool stuff

  The interesting stuff happens in the function render() here in Render.swift. 
  This takes some 3D model data (a cube), transforms and projects it, and then 
  draws it by calling setPixel() over and over (which is why it is so slow).

  The ViewController has a view that is given a backing CALayer of size 800x600
  points. When you call setPixel() it draws a pixel into a 800x600 pixel bitmap
  (so drawing always happens at @1x even on Retina screens). To show this image
  on the screen, you call presentRenderBuffer(). That's all the infrastructure
  you need to know about in order to understand the rest.

  The ViewController also has a timer that calls render() every so often to 
  perform the animations. Those animations happen in its animate() method. 
  I did not want to put that animation code in Render.swift because it might
  be distracting, as it is not directly related to 3D drawing.

  So all you need to do is read through this file (Render.swift) and follow 
  along with the steps in render(). What happens in render() is roughly what 
  happens on the GPU when you tell Metal to draw 3D stuff on the screen. But
  instead of using shaders, we're doing it all by hand. :-)
*/


// MARK: - The 3D model

/*
  First we define the model, i.e. the 3D object that we want to show. 
  
  The model is made up of triangles because triangles are easy to draw. Each 
  triangle consists of 3 vertices.
  
  A vertex describes a position in 3D space (x, y, z), but also the color of
  the triangle at that vertex, and a normal vector for lighting calculations.
  You can also add extra information such as texture mapping coordinates, as
  well as any other data you want to associate with a vertex.
  
  The coordinate system we use looks like this:
  
      y  z
      | /
      |/
      +--- x
    
  So x is positive to the right, y is postive going up, and z is positive going
  into the screen. This is a so-called left-handed coordinate system. (To get a
  right-handed coordinate system, simply flip z to -z everywhere.)
*/

struct Vertex {
  var x: Float = 0   // coordinate in 3D space
  var y: Float = 0
  var z: Float = 0

  var r: Float = 0   // color
  var g: Float = 0
  var b: Float = 0
  var a: Float = 1

  var nx: Float = 0  // normal vector (using for lighting)
  var ny: Float = 0
  var nz: Float = 0
}

/*
  A triangle has three vertices. (Another common name for this is a "face".)

  The order of the vertices in the triangle is important when face culling is 
  used, so that triangles that are facing away from the camera are not drawn.
  Get the order wrong and triangles won't show up at all!
  
  However, in this demo app we don't do face culling and so the vertex order
  doesn't really matter.
*/
struct Triangle {
  var vertices = [Vertex](repeating: Vertex(), count: 3)
}

/*
  The model is just a list of triangles.

  The 3D model we're using in this app is a basic cube. The scale is -10 units 
  to +10 units. The units can be whatever you want, so let's say centimeters.

  You would typically load your models from a .obj file but because this is a 
  simple demo we define the geometry by hand.
*/
let model: [Triangle] = {
  var triangles = [Triangle]()

  var triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangle.vertices[1] = Vertex(x: -10, y:  10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangle.vertices[2] = Vertex(x:  10, y: -10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y:  10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangle.vertices[1] = Vertex(x:  10, y: -10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z:  10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: 1)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z: -10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 0, nz: -1)
  triangle.vertices[1] = Vertex(x:  10, y: -10, z: -10, r: 0, g: 1, b: 0, a: 1, nx: 0, ny: 0, nz: -1)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z: -10, r: 0, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: -1)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z: -10, r: 1, g: 1, b: 0, a: 1, nx: 0, ny: 0, nz: -1)
  triangle.vertices[1] = Vertex(x:  10, y:  10, z: -10, r: 0, g: 1, b: 1, a: 1, nx: 0, ny: 0, nz: -1)
  triangle.vertices[2] = Vertex(x: -10, y:  10, z: -10, r: 1, g: 0, b: 1, a: 1, nx: 0, ny: 0, nz: -1)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y:  10, z: -10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangle.vertices[1] = Vertex(x: -10, y:  10, z:  10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z: -10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y:  10, z:  10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangle.vertices[1] = Vertex(x:  10, y:  10, z: -10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z:  10, r: 1, g: 0, b: 0, a: 1, nx: 0, ny: 1, nz: 0)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z: -10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangle.vertices[1] = Vertex(x:  10, y: -10, z: -10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangle.vertices[2] = Vertex(x: -10, y: -10, z:  10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z:  10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangle.vertices[1] = Vertex(x:  10, y: -10, z:  10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangle.vertices[2] = Vertex(x:  10, y: -10, z: -10, r: 1, g: 1, b: 1, a: 1, nx: 0, ny: -1, nz: 0)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x:  10, y: -10, z: -10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangle.vertices[1] = Vertex(x:  10, y: -10, z:  10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z: -10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x:  10, y: -10, z:  10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangle.vertices[1] = Vertex(x:  10, y:  10, z: -10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangle.vertices[2] = Vertex(x:  10, y:  10, z:  10, r: 0, g: 1, b: 0, a: 1, nx: 1, ny: 0, nz: 0)
  triangles.append(triangle)

  // The yellow side has normal vectors that point in different directions,
  // which makes it appear rounded when lighting is applied. For the other
  // sides all vertices have the same normal vectors, making them appear flat.

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z: -10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny: -0.577, nz: -0.577)
  triangle.vertices[1] = Vertex(x: -10, y:  10, z: -10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny:  0.577, nz: -0.577)
  triangle.vertices[2] = Vertex(x: -10, y: -10, z:  10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny: -0.577, nz:  0.577)
  triangles.append(triangle)

  triangle = Triangle()
  triangle.vertices[0] = Vertex(x: -10, y: -10, z:  10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny: -0.577, nz:  0.577)
  triangle.vertices[1] = Vertex(x: -10, y:  10, z:  10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny:  0.577, nz:  0.577)
  triangle.vertices[2] = Vertex(x: -10, y:  10, z: -10, r: 1, g: 1, b: 0, a: 1, nx: -0.577, ny:  0.577, nz: -0.577)
  triangles.append(triangle)

  return triangles
}()

/* The model has a position in the 3D world, a scale, and an orientation that
   is given by 3 rotation angles. Because we're using a left-handed coordinate
   system, positive rotation is clockwise about the axis of rotation. */

var modelX: Float = 0
var modelY: Float = 0
var modelZ: Float = 0

var modelScaleX: Float = 1
var modelScaleY: Float = 1
var modelScaleZ: Float = 1

var modelRotateX: Float = 0
var modelRotateY: Float = 0
var modelRotateZ: Float = 0

/* Typically, the origin (0, 0, 0) is at the center of the model. If not, you
   can fix this with modelOriginX/Y/Z. Rotations happen about this origin, so
   if you want to rotate around one of the corners of the cube instead of the
   center, you can set modelOriginX and Z to 10. */

var modelOriginX: Float = 10
var modelOriginY: Float = 0
var modelOriginZ: Float = 10

/* 
  The position of the camera. You can change this using the slider in the UI.
  Initially, the world origin (0, 0, 0) is in the center of the screen but the
  position of the camera changes this.
  
  In a real app you'd also give the camera a direction (either using a "look at"
  vector or using rotation angles) but in this app you're always looking along
  the positive z axis.

  Note that we don't do any clipping in the z direction, so make sure cameraZ
  is far away enough from the vertices (or the app may act weird / crash).
*/

var cameraX: Float = 0
var cameraY: Float = 20
var cameraZ: Float = -20

/* The following options control the lighting of the scene. The calculations to
   apply the light happen in the "fragment shader". */

var ambientR: Float = 1
var ambientG: Float = 1
var ambientB: Float = 1
var ambientIntensity: Float = 0.2

var diffuseR: Float = 1
var diffuseG: Float = 1
var diffuseB: Float = 1
var diffuseIntensity: Float = 0.8

var diffuseX: Float = 0    // direction of the diffuse light
var diffuseY: Float = 0    // (this vector should have length 1)
var diffuseZ: Float = 1


// MARK: - Configuration options

/* To make sure far away triangles don't overlap closer triangles, we can use a
   depth buffer. If you disable this, the triangles will be sorted by z position
   instead, which doesn't always look good. */

fileprivate let useDepthBuffer = true

fileprivate var depthBuffer: [Float] = {
  return [Float](repeating: 0, count: Int(context!.width * context!.height))
}()


// MARK: - The cool stuff starts here

/* 
  This is where the magic happens!

  render() is called on every animation frame. This function takes the model's
  vertex data, its state (modelX, modelRotateY, etc), and the position of the
  camera, and draws a 2D rendition of the 3D scene.

  In a real game this would ideally be called 60 times per second (or more).
*/
func render() {

  // Erase what we drew last time.
  clearRenderBuffer(color: 0xff302010)

  // Also clear out the depth buffer, if enabled (fill with large values).
  if useDepthBuffer {
    for i in 0..<depthBuffer.count {
      depthBuffer[i] = Float.infinity
    }
  }

  // Take the 3D cube, place it in the 3D world, adjust the viewpoint for the
  // camera, and project everything to two-dimensional triangles...
  let projected = transformAndProject()

  // ...and draw these triangles on the screen.
  for triangle in projected {
    draw(triangle: triangle)

    // Use this if you just want to see the vertices, not whole triangles.
    //drawOnlyVertices(triangle: triangle)
  }
}


// MARK: - Triangle transformation

/*
  Each 3D model in the app (we only have one, the cube) is defined in its own,
  local space (aka "model space"). In order to draw these models on the screen,
  we have to make them undergo several "transformations":
  
  1. First we have to take the models and place them inside the larger 3D world. 
     This is a transformation to "world space". 
     
  2. Then we position the camera and look at the world through this camera, a
     transformation to "camera space". At this point we can already throw away
     some triangles that are not visible (culling). 
     
  3. Finally, we project this 3D view onto a 2D surface so that we can show it 
     on the screen; this projection is a transformation to "screen space" (also
     known as "viewport space").

  This is where all the math happens. To make clear what is going on, I used
  straightfoward math -- mostly addition, multiplication, the occasional sine
  and cosine. In a real 3D application you'd stick most of these calculations
  inside matrices, as they are much more efficient and easy to use. But those
  matrices will do the exact same things you see here!

  A lot of the stuff that happens in this function would normally be done by
  a vertex shader on the GPU. The vertex shader takes the model's vertices and
  transforms them from local 3D space to 2D space, and all the steps inbetween.
*/

private func transformAndProject() -> [Triangle] {
  let contextWidth = Int(context!.width)
  let contextHeight = Int(context!.height)

  /* We want the cube to spin around and bounce up and down. We do this by 
     taking the original vertices (which are centered around the cube's local
     origin) and move them from "model space" into "world space". */
     
  // We store the results in a new (temporary) array because we don't want to
  // overwrite the original cube data.
  var transformed = model

  // Look at each triangle...
  for (j, triangle) in transformed.enumerated() {
    var newTriangle = Triangle()

    // Look at each vertex of the triangle...
    for (i, vertex) in triangle.vertices.enumerated() {
      var newVertex = vertex

      // We may need to adjust the model's origin, which is a translation.
      newVertex.x -= modelOriginX
      newVertex.y -= modelOriginY
      newVertex.z -= modelOriginZ

      // Scale the vertex:
      newVertex.x *= modelScaleX
      newVertex.y *= modelScaleY
      newVertex.z *= modelScaleZ

      // Rotate about the X-axis. This rotates the vertex around the model's
      // adjusted origin.
      var tempA =  cos(modelRotateX)*newVertex.y + sin(modelRotateX)*newVertex.z
      var tempB = -sin(modelRotateX)*newVertex.y + cos(modelRotateX)*newVertex.z
      newVertex.y = tempA
      newVertex.z = tempB

      // Rotate about the Y-axis:
      tempA =  cos(modelRotateY)*newVertex.x + sin(modelRotateY)*newVertex.z
      tempB = -sin(modelRotateY)*newVertex.x + cos(modelRotateY)*newVertex.z
      newVertex.x = tempA
      newVertex.z = tempB

      // Rotate about the Z-axis:
      tempA =  cos(modelRotateZ)*newVertex.x + sin(modelRotateZ)*newVertex.y
      tempB = -sin(modelRotateZ)*newVertex.x + cos(modelRotateZ)*newVertex.y
      newVertex.x = tempA
      newVertex.y = tempB

      // Finally, perform translation to the model's position in the 3D world.
      newVertex.x += modelX
      newVertex.y += modelY
      newVertex.z += modelZ

      // We also need to rotate the normal vector so that it stays aligned with
      // the orientation of the vertex. Because in this demo app we only rotate
      // about the Y-axis, I've only included that rotation code, not the other
      // axes. If I had used a matrix for the vertex coordinates, then I simply
      // could've multiplied the normal vector with that same rotation matrix.
      tempA =  cos(modelRotateY)*newVertex.nx + sin(modelRotateY)*newVertex.nz
      tempB = -sin(modelRotateY)*newVertex.nx + cos(modelRotateY)*newVertex.nz
      newVertex.nx = tempA
      newVertex.nz = tempB

      // Store the new vertex into the new triangle.
      newTriangle.vertices[i] = newVertex
    }
    transformed[j] = newTriangle
  }

  /* As you can see, we're doing quite a few calculations here, and we do them
     for every vertex in our model. If we had multiple models, we'd need to do
     these calculations for each model. 
     
     That's why in practice you'd put these calculations into a matrix and then 
     you just have to multiply each vertex with that matrix. That's much simpler 
     and more efficient because it can be hardware accelerated -- either on the
     CPU by the simd framework or on the GPU by the vertex shader.
     
     It's common to compute the matrix on the CPU, then pass it to the vertex
     shader, which will use it to transform all the vertices. */

  /* Currently we're viewing the 3D world from (0, 0, 0), straight down the z
     axis. You can imagine there is a "camera" object, and we can place this
     camera anywhere we want and make it look anywhere we want.
     
     This means we need to transform the objects from "world space" into "camera
     space". This uses the same math as before, but in the opposite direction.
     In practice, you'd also use a matrix for this. (In fact, you'd combine the
     model matrix and the camera matrix into a single matrix.) */

  for (j, triangle) in transformed.enumerated() {
    var newTriangle = Triangle()
    for (i, vertex) in triangle.vertices.enumerated() {
      var newVertex = vertex

      // Move everything in the world opposite to the camera, i.e. if the
      // camera moves to the left, everything else moves to the right.
      newVertex.x -= cameraX
      newVertex.y -= cameraY
      newVertex.z -= cameraZ

      // Likewise, you can perform rotations as well. If the camera rotates
      // to the left with angle alpha, everything else rotates away from the
      // camera to the right with angle -alpha. (I did not implement that in
      // this demo.)

      newTriangle.vertices[i] = newVertex
    }
    transformed[j] = newTriangle
  }

  /* At this point you may want to throw away triangles that aren't going to
     be visible anyway, for example those that are behind the camera or those
     that are facing away from the camera. (Not implemented but it involves a
     bit more math. Metal or OpenGL will automatically do this for you.) */

  /* Now we have a set of triangles described in camera space. The units of 
     this camera space are whatever you want them to be (we chose centimeters) 
     but we need to convert this to pixels somehow.
     
     Also, we need to decide where on the screen to place the camera space's 
     origin (we'll put it in the center).
     
     And we have to project from 3D coordinates to 2D coordinates somehow, i.e.
     we need to get rid of the z-axis.

     That all happens in this final transformation step.

     Note that Metal does things in a slightly different order: the projection
     transform puts the vertices in "clip space" first, but we directly convert
     them to screen space. (It's the big picture that matters, not the details.)
     
     As before, I'm illustrating how to do this with basic math operations.
     Typically you'd combine all these operations into a projection matrix and
     pass that to your vertex shader, so applying it to the vertices happens
     on the GPU.
     
     Note that the output array still contains Triangle objects even though we
     no longer use the z position of the Vertex object. As it turns out, we can
     use this z-value for a depth buffer, i.e. to determine whether to overwrite
     any existing fragments later on when we attempt to draw the triangles. */

  for (j, triangle) in transformed.enumerated() {
    var newTriangle = Triangle()
    for (i, vertex) in triangle.vertices.enumerated() {
      var newVertex = vertex

      /* A simple way to do a 3D-to-2D projection is to divide x and y by z. 
         The larger z is, the smaller the result of this division. Which makes 
         sense because objects that are further away will appear smaller.

         In a real 3D app, you'd use a projection matrix that is a bit more 
         fancy but this is the general idea.
         
         Note that this calculation may crash the app if newVertex.z == -100,
         or give weird results (such as nan values). In this demo we avoid that
         by always placing the vertices far enough away from the camera. In a 
         real app, you'd clip the triangles against the view frustum first (as
         with so many things, Metal takes care of this for you). */

      newVertex.x /= (newVertex.z + 100) * 0.01
      newVertex.y /= (newVertex.z + 100) * 0.01

      // Let's say we want the camera / viewport to be about -40 to +40 of our
      // world units (centimeters). So we need to scale up by factor height/80 
      // in both x and y directions (so everything stays square).
      newVertex.x *= Float(contextHeight)/80
      newVertex.y *= Float(contextHeight)/80

      // We want (0, 0) to be in the center of the screen. Initially it is at
      // the bottom-right corner, so shift everything over.
      newVertex.x += Float(contextWidth/2)
      newVertex.y += Float(contextHeight/2)

      newTriangle.vertices[i] = newVertex
    }
    transformed[j] = newTriangle
  }

  /* Remember, the above stuff -- transformation to world space, camera space,
     screen space -- is what you can do in a vertex shader. The vertex shader 
     takes as input your model's vertices and transforms them into whatever
     you want. You can do basic stuff like we did here (rotations, 3D-to-2D 
     projection, etc) but anything goes (for example, turn a grid of vertices
     into a waving flag using a bit of trig). */

  /* Triangles that are further away (greater z value) need to be drawn before
     triangles that are closer to the camera. A simple way to do this is to
     sort the projected triangles on z-value. That's why the projected Vertex
     values still keep track of their original z position (from camera space).
     However, a much nicer way to do this is to use a depth buffer. */
  if !useDepthBuffer {
    transformed.sort { t1, t2 -> Bool in
      let avg1 = (t1.vertices[0].z + t1.vertices[1].z + t1.vertices[2].z) / 3
      let avg2 = (t2.vertices[0].z + t2.vertices[1].z + t2.vertices[2].z) / 3
      return avg2 < avg1
    }
  }

  return transformed
}


// MARK: - Triangle rasterization

/* OK, so far what we've done is put our 3D model into the world, adjusted for
   the camera's viewpoint, and converted to 2D space. What we have now is the 
   same list of triangles but their vertex coordinates now represent specific
   pixels on the screen (instead of points in some imaginary three-dimensional
   space).

   We can draw these pixels but that only gives us the vertices, not the entire
   triangle. You can use the following function for that: it just plots three
   pixels for each triangle. (It's useful for debugging but it doesn't really
   make things look very exciting...)
*/

fileprivate func drawOnlyVertices(triangle: Triangle) {
  for vertex in triangle.vertices {
    setPixel(x: Int(vertex.x), y: Int(vertex.y),
             r: vertex.r, g: vertex.g, b: vertex.b, a: vertex.a)
  }
}

/*
   To draw the triangles we have to connect these 3 projected vertex pixels
   somehow. This is called rasterizing.
   
   Metal takes care of most of this for you. Once it has figured out which 
   pixels belong to the triangle, the GPU will call the fragment shader for 
   each of these pixels -- and that lets you change how this pixel gets drawn.
   Still, it is useful to understand how rasterizing works under the hood.
   
   To rasterize a triangle, we'll draw horizontal strips. For example, if the 
   triangle has these vertices,
   
             b


                     c

        a
   
   then the horizontal strips will look like this:
   
             =
            ====
           ========
          ============
         ========
        ====
   
   There is one strip for every vertical line on the screen, so strips are 1
   pixel high. I call these "spans".
   
   To find out where each span starts and ends, we have to interpolate between
   the y-positions of the three vertices to find the corresponding starting and
   ending x-positions, represented by asterisks in the following image:

             b
            *  *
           *      *
          *          c
         *      *
        a   *

   I called these *'s "edges". An edge represents an x-coordinate. Each span has
   two edges, one on the left and one on the right. Once we've found these two
   edges, we simply draw a horizontal line between them. Repeat this for all
   the spans in the triangle, and we'll have filled up the triangle with pixels!

   The keyword in rasterization is interpolation. We interpolate all the things!
   As we calculate these spans and their edges, we not only interpolate the 
   x-positions of the vertices, but also their colors, their normal vectors,
   their z-values (for the depth buffer), their texture coordinates, and so on.
   And when we fill up the spans from left to right we interpolate again, across
   the surface of the triangle!

   So rasterization gives us the screen coordinates of each pixel that belongs
   to a given triangle. It also gives us an interpolated color, and this is what 
   we write into the framebuffer. That last step, writing the color into the
   framebuffer, is what the fragment shader does.
   
   Metal will do all the interpolation stuff for you, and then calls a fragment
   shader for each pixel in the triangle. Of course, you can decide to do lots
   of wild things to the pixel color before you write it into the framebuffer.
   Typically, you'd apply a texture or do lighting calculations, but only your
   imagination is the limit!
  */

/* A span describes a horizontal strip that we fill in with pixels. */
fileprivate struct Span {
  var edges = [Edge]()

  var leftEdge: Edge {
    return edges[0].x < edges[1].x ? edges[0] : edges[1]
  }

  var rightEdge: Edge {
    return edges[0].x > edges[1].x ? edges[0] : edges[1]
  }
}

/* An edge is one side of such a horizontal strip. */
fileprivate struct Edge {
  var x = 0          // start or end coordinate of horizontal strip

  var r: Float = 0   // color at this point
  var g: Float = 0
  var b: Float = 0
  var a: Float = 0

  var z: Float = 0   // for checking and filling in the depth buffer

  var nx: Float = 0  // interpolated normal vector
  var ny: Float = 0
  var nz: Float = 0
}

/* There are as many spans as there are vertical lines in screenspace. */
fileprivate var spans = [Span]()
fileprivate var firstSpanLine = 0
fileprivate var lastSpanLine = 0

fileprivate func draw(triangle: Triangle) {
  // Only draw the triangle if it is at least partially inside the viewport.
  guard partiallyInsideViewport(vertex: triangle.vertices[0])
     && partiallyInsideViewport(vertex: triangle.vertices[1])
     && partiallyInsideViewport(vertex: triangle.vertices[2]) else {
    return
  }

  // Reset the spans so that we're starting with a clean slate.
  spans = .init(repeating: Span(), count: context!.height)
  firstSpanLine = Int.max
  lastSpanLine = -1

  // Interpolate all the things!
  addEdge(from: triangle.vertices[0], to: triangle.vertices[1])
  addEdge(from: triangle.vertices[1], to: triangle.vertices[2])
  addEdge(from: triangle.vertices[2], to: triangle.vertices[0])

  // And finally, draw the horizontal strips. This is where the fragment
  // shader gets called.
  drawSpans()
}

/* Clipping is an important feature of a rasterizer. You don't want to draw
   pixels that are not visible anyway. We do some basic clipping in this demo
   app but nothing fancy. Metal does clipping for you. */
fileprivate func partiallyInsideViewport(vertex: Vertex) -> Bool {
  return vertex.x >= 0 || vertex.x < Float(context!.width) ||
         vertex.y >= 0 || vertex.y < Float(context!.height)
}

/* In this function we interpolate from vertex1 to vertex2. We step one vertical
   pixel at a time and calculate the x-position for each of those vertical lines.
   We also interpolate the other vertex properties, such as their colors. */
fileprivate func addEdge(from vertex1: Vertex, to vertex2: Vertex) {
  let yDiff = ceil(vertex2.y - 0.5) - ceil(vertex1.y - 0.5)

  guard yDiff != 0 else { return }      // degenerate edge

  let (start, end) = yDiff > 0 ? (vertex1, vertex2) : (vertex2, vertex1)
  let len = abs(yDiff)

  var yPos = Int(ceil(start.y - 0.5))   // y should be integer because it
  let yEnd = Int(ceil(end.y - 0.5))     // needs to fit on a 1-pixel line

  let xStep = (end.x - start.x)/len     // x can stay floating point for now
  var xPos = start.x + xStep/2

  let zStep = (end.z - start.z)/len
  var zPos = start.z + zStep/2

  let rStep = (end.r - start.r)/len
  var rPos = start.r

  let gStep = (end.g - start.g)/len
  var gPos = start.g

  let bStep = (end.b - start.b)/len
  var bPos = start.b

  let aStep = (end.a - start.a)/len
  var aPos = start.a

  let nxStep = (end.nx - start.nx)/len
  var nxPos = start.nx

  let nyStep = (end.ny - start.ny)/len
  var nyPos = start.ny

  let nzStep = (end.nz - start.nz)/len
  var nzPos = start.nz

  while yPos < yEnd {
    let x = Int(ceil(xPos - 0.5))       // now we make x an integer too

    // Don't want to go outside the visible area.
    if yPos >= 0 && yPos < Int(context!.height) {

      // This is to optimize drawSpans(), so it knows where to start
      // drawing and where to stop.
      if yPos < firstSpanLine { firstSpanLine = yPos }
      if yPos > lastSpanLine { lastSpanLine = yPos }

      // Add this edge to the span for this line.
      spans[yPos].edges.append(Edge(x: x,
                                    r: rPos, g: gPos, b: bPos, a: aPos,
                                    z: zPos,
                                    nx: nxPos, ny: nyPos, nz: nzPos))
    }

    // Move the interpolations one step forward.
    yPos += 1
    xPos += xStep
    zPos += zStep
    rPos += rStep
    gPos += gStep
    bPos += bStep
    aPos += aStep
    nxPos += nxStep
    nyPos += nyStep
    nzPos += nzStep
  }
}

/* Once we have calculated all the spans for the given triangle, we can draw
   those horizontal strips. We interpolate the x-position (step one pixel at
   a time to the right) and also the other properties such as the color. */
fileprivate func drawSpans() {
  if lastSpanLine != -1 {
    for y in firstSpanLine...lastSpanLine {
      if spans[y].edges.count == 2 {
        let edge1 = spans[y].leftEdge
        let edge2 = spans[y].rightEdge

        // How much to interpolate on each step.
        let step = 1 / Float(edge2.x - edge1.x)
        var pos: Float = 0

        for x in edge1.x ..< edge2.x {
          // Interpolate between the colors again.
          var r = edge1.r + (edge2.r - edge1.r) * pos
          var g = edge1.g + (edge2.g - edge1.g) * pos
          var b = edge1.b + (edge2.b - edge1.b) * pos
          let a = edge1.a + (edge2.a - edge1.a) * pos

          /* The depth buffer makes sure that a triangle that is further away
             does not obscure a triangle that is closer to the camera. This is
             done by storing the z-value of each triangle pixel into the depth
             buffer. To use the depth buffer we also interpolate between these
             z-positions to calculate the z-position each pixel corresponds with.
             We only draw the pixel if no "nearer" pixel has yet been drawn. 
             (This is also a feature that Metal provides for you already.) */
          var shouldDrawPixel = true
          if useDepthBuffer {
            let z = edge1.z + (edge2.z - edge1.z) * pos
            let offset = x + y * Int(context!.width)
            if depthBuffer[offset] > z {
              depthBuffer[offset] = z
            } else {
              shouldDrawPixel = false
            }
          }

          /* Also interpolate the normal vector. Note that for many triangles
             in the cube, all three vertices have the same normal vector. So
             all pixels in such a triangle get identical normal vectors. But
             this is not a requirement: I've also included a triangle whose
             vertices have different normal vectors, giving it a more "rounded"
             look. */
          let nx = edge1.nx + (edge2.nx - edge1.nx) * pos
          let ny = edge1.ny + (edge2.ny - edge1.ny) * pos
          let nz = edge1.nz + (edge2.nz - edge1.nz) * pos

          if shouldDrawPixel {
            /* This is where the fragment shader does its job. It is called 
               once for every pixel that we must draw, with interpolated values
               for the color, texture coordinates, and so on. Here you can do
               all kinds of fun things. We calculate the color of the pixel
               based on a very simple lighting model, but you can also sample
               from a texture, etc. */

            let factor = min(max(0, -1*(nx*diffuseX + ny*diffuseY + nz*diffuseZ)), 1)

            r *= (ambientR*ambientIntensity + factor*diffuseR*diffuseIntensity)
            g *= (ambientG*ambientIntensity + factor*diffuseG*diffuseIntensity)
            b *= (ambientB*ambientIntensity + factor*diffuseB*diffuseIntensity)

            setPixel(x: x, y: y, r: r, g: g, b: b, a: a)
          }

          pos += step
        }
      }
    }
  }
}
