#DOM Functions

getRadius = () ->

  w = window.innerWidth
  h = window.innerHeight
  d2 = w*w + h*h
  (Math.sqrt d2)/2

# Temporal functions

class Timer

  constructor: (period) ->

    @time = new Date().getTime()
    @t = 0
    @period = period

  getT: () ->

    currentTime = new Date().getTime()
    deltaTime = currentTime - @time

    @time = currentTime
    @t += deltaTime
    @t = @period if @t > @period

    return @t/@period

class Curves

  constructor: (options) ->

    @fx = options.x
    @fy = options.y
    @timer = options.timer

  x: () ->

    t = @timer.getT()
    return @fx t

  y: () ->

    t = @timer.getT()
    return @fy t

# Different types of curves

linear = (begin, end) ->
  (t) ->
    (end - begin)*t + begin

triCubic = (begin, middle) ->
  (t) ->
    (2*t - 1)*(2*t - 1)*(begin - middle) + middle

ease = (begin, end) ->
  (t) ->
    t *= 2
    return (end - begin)/2*t*t*t*t + begin if (t < 1)
    t -= 2
    (begin - end)/2 * (t*t*t*t - 2) + begin


# Kaleidoscope
  
class Kaleidoscope
  
  HALF_PI: Math.PI / 2
  TWO_PI: Math.PI * 2
  
  constructor: ( @options = {} ) ->
    
    @defaults =
      offsetRotation: 0.0
      offsetScale: 1.0
      offsetX: 0.0
      offsetY: 0.0
      radius: getRadius()
      slices: 12
      zoom: 1.0
        
    @[ key ] = val for key, val of @defaults
    @[ key ] = val for key, val of @options
      
    @domElement ?= document.createElement 'canvas'
    @context ?= @domElement.getContext '2d'
    @image ?= document.createElement 'img'
    
  draw: ->
    
    @domElement.width = @domElement.height = @radius * 2
    @context.fillStyle = @context.createPattern @image, 'no-repeat'
    
    scale = @zoom * ( @radius / Math.min @image.width, @image.height )
    step = @TWO_PI / @slices
    cx = @image.width / 2

    for index in [ 0..@slices ]
      
      @context.save()
      @context.translate @radius, @radius
      @context.rotate index * step
      
      @context.beginPath()
      @context.moveTo -0.5, -0.5
      @context.arc 0, 0, @radius, step * -0.51, step * 0.51
      @context.lineTo 0.5, 0.5
      @context.closePath()
      
      @context.rotate @HALF_PI
      @context.scale scale, scale
      @context.scale [-1,1][index % 2], 1
      @context.translate @offsetX - cx, @offsetY
      @context.rotate @offsetRotation
      @context.scale @offsetScale, @offsetScale
      
      @context.fill()
      @context.restore()

# Drag & Drop
  
class DragDrop
  
  constructor: ( @callback, @context = document, @filter = /^image/i ) ->
    
    disable = ( event ) ->
      do event.stopPropagation
      do event.preventDefault
    
    @context.addEventListener 'dragleave', disable
    @context.addEventListener 'dragenter', disable
    @context.addEventListener 'dragover', disable
    @context.addEventListener 'drop', @onDrop, no
      
  onDrop: ( event ) =>
    
    do event.stopPropagation
    do event.preventDefault
      
    file = event.dataTransfer.files[0]
    
    if @filter.test file.type
      
      reader = new FileReader
      reader.onload = ( event ) => @callback? event.target.result
      reader.readAsDataURL file

# Init kaleidoscope
  
image = new Image
image.onload = => do kaleidoscope.draw
image.src = 'img1-small-transparent.png'

kaleidoscope = new Kaleidoscope
  image: image
  slices: 20

kaleidoscope.domElement.style.position = 'absolute'
kaleidoscope.domElement.style.marginLeft = -kaleidoscope.radius + 'px'
kaleidoscope.domElement.style.marginTop = -kaleidoscope.radius + 'px'
kaleidoscope.domElement.style.left = '50%'
kaleidoscope.domElement.style.top = '50%'
document.body.appendChild kaleidoscope.domElement

curves = new Curves
  x:
    linear -267, 166
  y:
    triCubic -900, -233
  timer: new Timer 5000

update = () ->

  kaleidoscope.offsetX = curves.x()
  kaleidoscope.offsetY = curves.y()

  console.log (parseInt kaleidoscope.offsetX), (parseInt kaleidoscope.offsetY)

  kaleidoscope.draw()

  window.requestAnimationFrame update

update()
  
### Init drag & drop

dragger = new DragDrop ( data ) -> kaleidoscope.image.src = data
  
# Mouse events
  
tx = kaleidoscope.offsetX
ty = kaleidoscope.offsetY
tr = kaleidoscope.offsetRotation
  
onMouseMoved = ( event ) =>

  cx = window.innerWidth / 2
  cy = window.innerHeight / 2
                
  dx = event.pageX / window.innerWidth
  dy = event.pageY / window.innerHeight
                
  hx = dx - 0.5
  hy = dy - 0.5
                
  tx = hx * kaleidoscope.radius * -2
  ty = hy * kaleidoscope.radius * 2
#  tr = Math.atan2 hy, hx

window.addEventListener 'mousemove', onMouseMoved, no
                
# Init
  
options =
  interactive: yes
  ease: 0.1
                
do update = =>
                
  if options.interactive

    delta = tr - kaleidoscope.offsetRotation
    theta = Math.atan2( Math.sin( delta ), Math.cos( delta ) )
                
    kaleidoscope.offsetX += ( tx - kaleidoscope.offsetX ) * options.ease
    kaleidoscope.offsetY += ( ty - kaleidoscope.offsetY ) * options.ease
    kaleidoscope.offsetRotation += ( theta - kaleidoscope.offsetRotation ) * options.ease
    
    do kaleidoscope.draw
  
  setTimeout update, 1000/60
    
# Init gui

gui = new dat.GUI
gui.add( kaleidoscope, 'zoom' ).min( 0.25 ).max( 2.0 )
gui.add( kaleidoscope, 'slices' ).min( 6 ).max( 32 ).step( 2 )
gui.add( kaleidoscope, 'radius' ).min( 200 ).max( 500 )
gui.add( kaleidoscope, 'offsetX' ).min( -kaleidoscope.radius ).max( kaleidoscope.radius ).listen()
gui.add( kaleidoscope, 'offsetY' ).min( -kaleidoscope.radius ).max( kaleidoscope.radius ).listen()
gui.add( kaleidoscope, 'offsetRotation' ).min( -Math.PI ).max( Math.PI ).listen()
gui.add( kaleidoscope, 'offsetScale' ).min( 0.5 ).max( 4.0 )
gui.add( options, 'interactive' ).listen()
gui.close()

onChange = =>

  kaleidoscope.domElement.style.marginLeft = -kaleidoscope.radius + 'px'
  kaleidoscope.domElement.style.marginTop = -kaleidoscope.radius + 'px'
    
  options.interactive = no
    
  do kaleidoscope.draw

( c.onChange onChange unless c.property is 'interactive' ) for c in gui.__controllers

###