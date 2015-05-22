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

  end: () ->

    @t == @period

class Curves

  constructor: (options) ->
    @fx = options.x
    @fy = options.y
    @fr = options.r
    @timer = options.timer

  x: () ->
    t = @timer.getT()
    return @fx t

  y: () ->
    t = @timer.getT()
    return @fy t

  r: () ->
    t = @timer.getT()
    return @fr t

# Different types of curves

linear = (begin, end, power) ->
  (t) ->
    (end - begin)*Math.pow(t, power) + begin

triCubic = (begin, middle) ->
  (t) ->
    (2*t - 1)*(2*t - 1)*(begin - middle) + middle

ease = (begin, end) ->
  (t) ->
    t *= 2
    return (end - begin)/2*t*t*t*t + begin if (t < 1)
    t -= 2
    (begin - end)/2 * (t*t*t*t - 2) + begin

# Global parameters for the animation

Parameters = () ->

  this.xBegin = -76
  this.xEnd = 93
  this.yBegin = 0.999
  this.yMiddle = 250
  this.rotationBegin = 0.001
  this.rotationMiddle = 0.001
  return


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
      #@context.scale scale, scale
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

document.body.onload = () ->
  
  image = new Image
  image.onload = => do kaleidoscope.draw
  image.src = 'img3-small.png'

  kaleidoscope = new Kaleidoscope
    image: image
    slices: 20

  parameters = new Parameters

  kaleidoscope.domElement.style.position = 'absolute'
  kaleidoscope.domElement.style.marginLeft = -kaleidoscope.radius + 'px'
  kaleidoscope.domElement.style.marginTop = -kaleidoscope.radius + 'px'
  kaleidoscope.domElement.style.left = '50%'
  kaleidoscope.domElement.style.top = '50%'
  kaleidoscope.domElement.style.zIndex = '-1'
  document.body.appendChild kaleidoscope.domElement
  document.querySelector('#start').addEventListener('click', () -> playAnimation());

  playAnimation = () ->

    update = () ->

      kaleidoscope.offsetX = curves.x()
      kaleidoscope.offsetY = curves.y()
      kaleidoscope.offsetRotation = curves.r()

      kaleidoscope.draw()

      if curves.timer.end()
        window.setTimeout (() -> document.querySelector('#image').classList.remove('next')), 1500
      else
        window.requestAnimationFrame update

    xSize = image.width/100
    ySize = -(kaleidoscope.radius + image.height)
    console.log xSize, ySize

    curves = new Curves
      x:
        linear parameters.xBegin*xSize, parameters.xEnd*xSize, 1.3
      y:
        triCubic parameters.yBegin*ySize, -parameters.yMiddle
      r:
        triCubic parameters.rotationBegin, parameters.rotationMiddle
      timer: new Timer 5000

    document.querySelector('#image').classList.add('next');
    update()

  # Init gui

  gui = new dat.GUI
  gui.add( parameters, 'xBegin' ).min( -100 ).max( 100 )
  gui.add( parameters, 'xEnd' ).min( -100 ).max( 100 )
  gui.add( parameters, 'yBegin' ).min( 0 ).max( 1 )
  gui.add( parameters, 'yMiddle' ).min( 0 ).max( kaleidoscope.radius )
  gui.add( parameters, 'rotationBegin' ).min( -3.14 ).max( 3.14 )
  gui.add( parameters, 'rotationMiddle' ).min( -3.14 ).max( 3.14 )
  gui.close()

###

  onChange = =>

  #	kaleidoscope.domElement.style.marginLeft = -kaleidoscope.radius + 'px'
  #	kaleidoscope.domElement.style.marginTop = -kaleidoscope.radius + 'px'
      
  #  options.interactive = no
      
    do kaleidoscope.draw

  ( c.onChange onChange ) for c in gui.__controllers

###