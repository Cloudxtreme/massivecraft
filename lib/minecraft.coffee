# Imports
{Object3D, Matrix4, Scene, Mesh, WebGLRenderer, PerspectiveCamera} = THREE
{CubeGeometry, PlaneGeometry, MeshLambertMaterial, MeshNormalMaterial} = THREE
{AmbientLight, DirectionalLight, PointLight, Raycaster, Vector3, Vector2} = THREE
{MeshLambertMaterial, MeshNormalMaterial, Projector} = THREE
{Texture, UVMapping, RepeatWrapping, RepeatWrapping, NearestFilter} = THREE
{LinearMipMapLinearFilter, ClampToEdgeWrapping, Clock} = THREE

vec = (x, y, z) -> new Vector3 x, y, z

CubeSize = 25

class Player
    width: CubeSize * 0.3
    depth: CubeSize  * 0.3
    height: CubeSize  * 1.63

    constructor: ->
        @halfHeight = @height / 2
        @halfWidth = @width / 2
        @halfDepth = @depth / 2
        @pos = vec()
        @eyesDelta = @halfHeight * 0.9

    eyesPosition: ->
        ret = @pos.clone()
        ret.y += @eyesDelta
        return ret


    position: (axis) ->
        return @pos unless axis?
        return @pos[axis]

    incPosition: (axis, val) ->
        @pos[axis] += val
        return

    setPosition: (axis, val) ->
        @pos[axis] = val
        return


    collidesWithGround: -> @position('y') < @halfHeight

    vertex: (vertexX, vertexY, vertexZ) ->
        vertex = @position().clone()
        vertex.x += vertexX * @halfWidth
        vertex.y += vertexY * @halfHeight
        vertex.z += vertexZ * @halfDepth
        return vertex

    boundingBox: ->
        vmin = @vertex(-1, -1, -1)
        vmax = @vertex 1, 1, 1
        return {vmin: vmin, vmax: vmax}


class Grid
    constructor: (@size = 5) ->
        @matrix = {}

    insideGrid: (x, y, z) -> true


    get_all:->
        res = []
        for own k, v of @matrix
            res.push(v)
        res
        
            
    get: (x, y, z) ->
        key = x+'-'+y+'-'+z
        if not @matrix[key]?
            return null
        return @matrix[key]

    put: (x, y, z, val) ->
        key = x+'-'+y+'-'+z
        @matrix[key] = val        

    gridCoords: (x, y, z) ->
        x = Math.floor(x / CubeSize)
        y = Math.floor(y / CubeSize)
        z = Math.floor(z / CubeSize)
        return [x, y, z]


class CollisionHelper
    constructor: (@player, @grid)-> return
    rad: CubeSize
    halfRad: CubeSize / 2

    collides: ->
        return true if @player.collidesWithGround()
        ###
        return true if @beyondBounds()
        ###
        playerBox = @player.boundingBox()
        for cube in @possibleCubes()
            return true if @_collideWithCube playerBox, cube
        return false

    beyondBounds: ->
        p = @player.position()
        [x, y, z] = @grid.gridCoords p.x, p.y, p.z
        return true unless @grid.insideGrid x, 0, z


    _addToPosition: (position, value) ->
        pos = position.clone()
        pos.x += value
        pos.y += value
        pos.z += value
        return pos

    collideWithCube: (cube) -> @_collideWithCube @player.boundingBox(), cube

    _collideWithCube: (playerBox, cube) ->
        vmin = @_addToPosition cube.position, -@halfRad
        vmax = @_addToPosition cube.position, @halfRad
        cubeBox = {vmin, vmax}
        return CollisionUtils.testCubeCollision playerBox, cubeBox

    possibleCubes: ->
        cubes = []
        grid = @grid
        @withRange (x, y, z) ->
            cube = grid.get x, y, z
            cubes.push cube if cube?
        return cubes

    withRange: (func) ->
        {vmin, vmax} = @player.boundingBox()
        minx = @toGrid(vmin.x)
        miny = @toGrid(vmin.y)
        minz = @toGrid(vmin.z)

        maxx = @toGrid(vmax.x + @rad)
        maxy = @toGrid(vmax.y + @rad)
        maxz = @toGrid(vmax.z + @rad)

        x = minx
        while x <= maxx
            y = miny
            while y <= maxy
                z = minz
                while z <= maxz
                    func x, y, z
                    z++
                y++
            x++
        return


    toGrid: (val) ->
        ret = Math.floor(val / @rad)
        return ret


TextureHelper =
    loadTexture: (path) ->
        image = new Image()
        image.src = path
        texture = new Texture(image, new UVMapping(), ClampToEdgeWrapping, ClampToEdgeWrapping, NearestFilter, LinearMipMapLinearFilter)
        image.onload = -> texture.needsUpdate = true
        new THREE.MeshLambertMaterial(map: texture, ambient: 0xbbbbbb, vertexColors: THREE.VertexColors)


    tileTexture: (path, repeatx, repeaty) ->
        image = new Image()
        image.src = path
        texture = new Texture(image, new UVMapping(), RepeatWrapping,
        RepeatWrapping, NearestFilter, LinearMipMapLinearFilter)
        texture.repeat.x = repeatx
        texture.repeat.y = repeaty
        image.onload = -> texture.needsUpdate = true
        new THREE.MeshLambertMaterial(map: texture, ambient: 0xbbbbbb, vertexColors: THREE.VertexColors)



class Floor
    constructor: (width, height) ->
        repeatX = width / CubeSize
        repeatY = height / CubeSize
        material = TextureHelper.tileTexture("./textures/bedrock.png", repeatX, repeatY)
        planeGeo = new PlaneGeometry(width, height, 1, 1)
        plane = new Mesh(planeGeo, material)
        plane.position.y = -1
        plane.rotation.x = -Math.PI / 2
        plane.name = 'floor'
        @plane = plane

    addToScene: (scene) -> scene.add @plane


class Game
    constructor: (@populateWorldFunction) ->
        @ze = true
        @chunk = []
        @chunks = {}
        @rad = CubeSize
        @createMaterials()
        @currentMeshSpec = @createGrassGeometry()
        @cubeBlocks = @createBlocksGeometry()
        @selectCubeBlock 'cobblestone'
        @move = {x: 0, z: 0, y: 0}
        @keysDown = {}
        @grid = new Grid(100)
        @onGround = true
        @pause = off
        @fullscreen = off
        @camera = @createCamera()
        @ray_camera = @createCamera()
        @scene = new Scene()
        @scene.fog = new THREE.FogExp2( 0xffffff, 0.00015 );        
        @renderer = @createRenderer()
        @rendererPosition = $("#minecraft-container canvas").offset()
        THREEx.WindowResize @renderer, @camera
        @canvas = @renderer.domElement
        @controls = new Controls @camera, @canvas
        @player = new Player()
        @ray_scene = new Scene()        
        new Floor(50000, 50000).addToScene @scene
        @scene.add @camera
        @ray_scene.add @ray_camera
        
        @addLights @scene
        @projector = new Projector()
        @castRay = null
        @moved = false
        @toDelete = null
        @collisionHelper = new CollisionHelper(@player, @grid)
        @clock = new Clock()
        @world_size = 10
        @populateWorld()
        @defineControls()

        @stats = new Stats()
        @stats.setMode(0) # 0: fps, 1: ms

        # Align top-left
        @stats.domElement.style.position = 'absolute';
        @stats.domElement.style.left = '0px';
        @stats.domElement.style.top = '0px';
        @stats.domElement.style.zindex = '9';
        $('#app').append(@stats.domElement )




    width: -> window.innerWidth
    height: -> window.innerHeight

    createMaterials: ->
        @materials = MTexture({
                texturePath: './textures/',
                materialType: THREE.MeshLambertMaterial,
                materialParams: {},
                materialFlatColor: false
        })
        materialNames = [['grass', 'dirt', 'grass_dirt'], 'brick', 'dirt']
        @materials.load(materialNames)


    createBlocksGeometry: ->
        cubeBlocks = {}
        for b in Blocks
            geo = new THREE.CubeGeometry @rad, @rad, @rad, 1, 1, 1
            geo.computeFaceNormals()
            t = @texture(b)
            cubeBlocks[b] = @meshSpec geo, [t, t, t, t, t, t]
        return cubeBlocks

    createGrassGeometry: ->
        [grass_dirt, grass, dirt] = @textures "grass_dirt", "grass", "dirt"
        materials = [grass_dirt, #right
            grass_dirt, # left
            grass, # top
            dirt, # bottom
            grass_dirt, # back
            grass_dirt]  #front
        geo = new THREE.CubeGeometry( @rad, @rad, @rad, 1, 1, 1)
        geo.computeFaceNormals()
        @meshSpec geo, materials

    texture: (name) -> TextureHelper.loadTexture "./textures/#{name}.png"

    textures: (names...) -> return (@texture name for name in names)

    gridCoords: (x, y, z) -> @grid.gridCoords x, y, z

    meshSpec: (geometry, material) -> {geometry, material}


    intoGrid: (x, y, z, val) ->
        args = @gridCoords(x, y, z).concat(val)
        return @grid.put args...


    generateHeight: ->
        size = 64
        data = []
        size.times (i) ->
            data[i] = []
            size.times (j) ->
                data[i][j] = 0
        perlin = new ImprovedNoise()
        quality = 0.05
        z = 100 #Math.random() * 100
        4.times (j) ->
            size.times (x) ->
                size.times (y) ->
                    noise = perlin.noise(x / quality, y / quality, z)
                    data[x][y] += noise * quality
            quality *= 4
        data


    populateWorld: ->
      for i in [-1 .. 1]
         for j in [-1..1]
             t0 = new Date().getTime();
             @createChunk(i,j)
             diff = new Date().getTime() - t0
             console.log('CHUNK GENERATION IN '+diff)

      ###
      t0 = new Date().getTime()
      mesh = add_world()
      diff = new Date().getTime() - t0
      console.log('GENERATED MESH in '+diff)
      console.log(mesh)
      @scene.add(mesh)
      ###
      

    createChunk: (px, pz) ->
      @chunks[''+px+'-'+pz] = []
      middle = px * 32 / 2 + 1
      xoffset = px*32
      zoffset = pz*32
      px32 = px*32 * CubeSize
      pz32 = pz*32 * CubeSize

      middle = 1
      t0 = new Date().getTime();      
      data = @generateHeight()
      diff = new Date().getTime() - t0
      console.log('GenerateHeght '+diff)      
      playerHeight = null
      @world_size = 32
      for i in [0..31]
        for j in [0..31]
          height = (Math.abs Math.floor(data[i + @world_size][j + @world_size])) + 1
          playerHeight = (height + 1) * CubeSize if i == 0 and j == 0
          playerHeight = 300
          # height.times (k) =>
          for k in [0..height]
            cmesh = @cubeAt xoffset + middle + i , k, zoffset + middle + j
            @chunks[''+px+'-'+pz].push(cmesh)            
          for k in [0..31]
            idx = j*32*32 + k*32 + i
            if k < height
              @chunk[idx] = 1
            else
              @chunk[idx] = 0
      # console.log(@chunk)
      middlePos = middle * CubeSize
      @player.pos.set middlePos, playerHeight, middlePos
      t0 = new Date().getTime();
      @createMesh middle, px32, pz32, @chunk
      diff = new Date().getTime() - t0
      console.log('CREATE MESH '+diff)

      bigMesh = new THREE.Geometry();
      for mesh in @chunks[''+px+'-'+pz]
          THREE.GeometryUtils.merge(bigMesh, mesh)
      group = new THREE.Mesh(bigMesh, new THREE.MeshFaceMaterial(@currentMeshSpec.material))#new THREE.MeshBasicMaterial({color : 0x3D3D3D, wireframe : true }) )
      group.matrixAutoUpdate = false;
      group.updateMatrix();
      @scene.add(group)


    createMesh: (middle, px32, pz32, voxels) ->      
      mmesh = new MMesh({voxels:voxels, dims:[32,32,32]}, CubeSize)
      mat =  new THREE.MeshFaceMaterial(@currentMeshSpec.material)
      ###
      wireMaterial = new THREE.MeshBasicMaterial({color : 0x3D3D3D, wireframe : true })
      ###
      mmesh.createSurfaceMesh(@materials.material)
      ###
      mmesh.createSurfaceMesh(wireMaterial)
      ###
      mmesh.surfaceMesh.position.set CubeSize * middle - (CubeSize/2) + px32, 0, CubeSize * middle - (CubeSize/2) + pz32

      mmesh.surfaceMesh.name = "greedy"
      
      @materials.paint(mmesh.surfaceMesh)
      
      #mmesh.addToScene(@scene)



    populateWorld2: ->
        middle = @grid.size / 2
        ret = if @populateWorldFunction?
            setblockFunc = (x, y, z, blockName) =>
                @cubeAt x, y, z, @cubeBlocks[blockName]
            @populateWorldFunction setblockFunc, middle
        else
            [middle, 3, middle] 
        pos = (i * CubeSize for i in ret)
        @player.pos.set pos...


    cubeAt: (x, y, z, meshSpec, visible, validatingFunction) ->
        meshSpec or=@currentMeshSpec
        if not visible?
           visible = false
        #        console.log('VISIBLE?'+visible)
        if visible
            wireMaterial = new THREE.MeshBasicMaterial({color : 0xffffff, wireframe : true, doubleSide:true })
        else
            wireMaterial = new THREE.MeshBasicMaterial( { visible: false } )

        geometry = new THREE.CubeGeometry( @rad, @rad, @rad, 1, 1, 1)
        geometry.computeFaceNormals()

        mesh = new Mesh(geometry, wireMaterial)
        mesh.geometry.dynamic = false
        halfcube = CubeSize / 2
        mesh.position.set CubeSize * x, y * CubeSize + halfcube, CubeSize * z
        mesh.name = "block"
        visible = true
        mesh.visible = visible

        if validatingFunction?
            return unless validatingFunction(mesh)

        @grid.put x, y, z, mesh
        # always add the mesh to a special scene done for raycasting
        @ray_scene.add mesh
        # if visible
        #    @scene.add mesh

        shadow = new THREE.Color( 0x505050 )
        light = new THREE.Color( 0xffffff );
        ###
        colors = mesh.geometry.faces[ 0 ].vertexColors
        colors[ 0 ] = shadow
        colors[ 2 ] = shadow
        colors = mesh.geometry.faces[ 1 ].vertexColors
        colors[ 0 ] = shadow
        colors[ 2 ] = shadow
        ###

        if @ze
            console.log(mesh.geometry.faces)
            for face in mesh.geometry.faces
                    face.vertexColors.push( light, shadow, shadow )
                    #mesh.geometry.faces[ 1 ].vertexColors.push( shadow, light, shadow );            
            @ze = false

        mesh.updateMatrix()
        mesh.matrixAutoUpdate = false

                
        return mesh
        

    createCamera: ->
        camera = new PerspectiveCamera(45, @width() / @height(), 1, 10000)
        camera.lookAt vec 0, 0, 0
        camera

    createRenderer: ->
        renderer = new WebGLRenderer({antialias: false})
        renderer.setSize @width(), @height()
        renderer.setClearColorHex(0xBFD1E5, 1.0)
        renderer.clear()
        $('#minecraft-container').append(renderer.domElement)

        @composer = new THREE.EffectComposer( renderer);
        effectSSAO = new THREE.ShaderPass( THREE.SSAOShader );
        @composer.addPass(new THREE.RenderPass( @scene, @camera ))
        @composer.addPass( effectSSAO );
        renderTargetParametersRGBA = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBAFormat };
        renderTargetParametersRGB  = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat };
        depthTarget = new THREE.WebGLRenderTarget( 0.75 * window.innerWidth, 0.75*(window.innerHeight - 2 * 100), renderTargetParametersRGBA )
        effectSSAO.uniforms[ 'tDepth' ].value = depthTarget
        effectSSAO.uniforms[ 'size' ].value.set( 0.75 * window.innerWidth, 0.75*(window.innerHeight - 2 * 100))
        effectSSAO.uniforms[ 'cameraNear' ].value = @camera.near;
        effectSSAO.uniforms[ 'cameraFar' ].value = @camera.far;
        effectSSAO.uniforms[ 'fogNear' ].value = @scene.fog.near;
        effectSSAO.uniforms[ 'fogFar' ].value = @scene.fog.far;
        effectSSAO.uniforms[ 'fogEnabled' ].value = 1;
        effectSSAO.uniforms[ 'aoClamp' ].value = 0.5;
        effectSSAO.material.defines = { "RGBA_DEPTH": true, "ONLY_AO_COLOR": "1.0, 0.7, 0.5" };
        
        renderer

    addLights: (scene) ->
        ambientLight = new AmbientLight(0xaaaaaa)
        scene.add ambientLight
        directionalLight = new DirectionalLight(0xffffff, 1)
        directionalLight.position.set 1, 1, 0.5
        directionalLight.position.normalize()
        scene.add directionalLight

    defineControls: ->
        bindit = (key) =>
            $(document).bind 'keydown', key, =>
                @keysDown[key] = true
                return false
            $(document).bind 'keyup', key, =>
                @keysDown[key] = false
                return false
        for key in "zqsd".split('').concat('space', 'up', 'down', 'left', 'right')
            bindit key
        $(document).bind 'keydown', 'p', => @togglePause()
        for target in [document, @canvas]
            $(target).mousedown (e) => @onMouseDown e
            $(target).mouseup (e) => @onMouseUp e
            $(target).mousemove (e) => @onMouseMove e

    togglePause: ->
        @pause = !@pause
        @clock.start() if @pause is off
        return

    relativePosition: (x, y) ->
        [x - @rendererPosition.left, y - @rendererPosition.top]

    onMouseUp: (e) ->
        if not @moved and MouseEvent.isLeftButton e
            @toDelete = @_targetPosition(e)
        @moved = false

    onMouseMove: (event) -> @moved = true

    onMouseDown: (e) ->
        @moved = false
        return unless MouseEvent.isRightButton e
        console.log('RIGHT BUTTON')
        @castRay = @_targetPosition(e)

    _targetPosition: (e) ->
        return @relativePosition(@width() / 2, @height() / 2) if @fullscreen
        @relativePosition(e.pageX, e.pageY)

    deleteBlock: ->
        return unless @toDelete?
        [x, y] = @toDelete
        x = (x / @width()) * 2 - 1
        y = (-y / @height()) * 2 + 1
        vector = vec x, y, 1
        @projector.unprojectVector vector, @camera
        todir = vector.sub(@camera.position).normalize()
        @deleteBlockInGrid new Raycaster @camera.position, todir
        @toDelete = null
        return

    findBlock: (ray) ->
        ###
        for o in ray.intersectObjects(@scene.children)
        ###
        cubes = @grid.get_all()
        console.log('CUBES')

        for o in ray.intersectObjects(cubes)
            console.log('WHAT IS?')
            console.log(o)
            return o unless o.object.name is 'floor'
        return null


    deleteBlockInGrid: (ray) ->
        target = @findBlock ray
        return unless target?
        
        return unless @withinHandDistance target.object.position
        
        mesh = target.object
        @scene.remove mesh
        @ray_scene.remove mesh        
        {x, y, z} = mesh.position
        @intoGrid x, y, z, null
        return


    placeBlock: ->
        if not @castRay?
           return
        [x, y] = @castRay
        x = (x / @width()) * 2 - 1
        y = (-y / @height()) * 2 + 1
        vector = vec x, y, 1
        cam = @camera
        @ray_camera.position = @camera.position
        @ray_camera.fov = @camera.fov
        @ray_camera.rotation = @camera.rotation
        @ray_camera.projectionMatrix = @camera.projectionMatrix
        console.log(@ray_camera)
        console.log(@camera)        
        ###
        @projector.unprojectVector vector, @camera
        todir = vector.sub(@camera.position).normalize()
        @placeBlockInGrid new Raycaster @camera.position, todir
        ###
        @projector.unprojectVector vector, cam
        todir = vector.sub(cam.position).normalize()
        @placeBlockInGrid new Raycaster cam.position, todir
                                
        @castRay = null
        return

    getAdjacentCubePosition: (target) ->
        normal = target.face.normal.clone()
        p = target.object.position.clone().add normal.multiplyScalar(CubeSize)
        return p

    addHalfCube: (p) ->
        p.y += CubeSize / 2
        p.z += CubeSize / 2
        p.x += CubeSize / 2
        return p

    getCubeOnFloorPosition: (raycast) ->
        ray = raycast.ray
        return null if ray.direction.y >= 0
        ret = vec()
        o = ray.origin
        v = ray.direction
        t = (-o.y) / v.y
        ret.y = 0
        ret.x = o.x + t * v.x
        ret.z = o.z + t * v.z
        return @addHalfCube ret

    selectCubeBlock: (name) ->
        @currentCube = @cubeBlocks[name]

    getNewCubePosition: (ray) ->
        target = @findBlock ray
        if not target?
            return @getCubeOnFloorPosition ray
        dist = target.distance
        if dist > CubeSize * @handLength
            return null

        return @getAdjacentCubePosition target

    createCubeAt: (x, y, z) ->
        console.log('CREATING NEW CUBE AT'+x+ ' '+y+' '+z)
        @cubeAt x, y, z,  @currentCube, true, (cube) => not @collisionHelper.collideWithCube cube

    handLength: 7

    withinHandDistance: (pos) ->
        dist = pos.distanceTo @player.position()
        console.log('DIST '+dist)
        return dist <= CubeSize * @handLength

    placeBlockInGrid: (ray) ->
        p = @getNewCubePosition ray
        console.log('P?'+p)
        console.log(p)
        return unless p?
        gridPos = @gridCoords p.x, p.y, p.z
        [x, y, z] = gridPos
        console.log('withinHandDistance'+@withinHandDistance p)
        ###
        return unless @withinHandDistance p
        ###
        return unless @grid.insideGrid x, y, z
        return if @grid.get(x, y, z)?
        @createCubeAt x, y, z
        return


    collides: -> @collisionHelper.collides()

    goFullScreen: ->
        PointerLock.init onEnable: @enablePointLock, onDisable: @disablePointLock
        PointerLock.fullScreenLock($("#app").get(0))
        

    start: ->
        animate = =>
            @tick() unless @pause
            requestAnimationFrame animate, @renderer.domElement
        animate()
        @goFullScreen()
        ###PointerLock.init onEnable: @enablePointLock, onDisable: @disablePointLock
        PointerLock.fullScreenLock($("#app").get(0))###


    enablePointLock: =>
        $("#cursor").show()
        @controls.enableMouseLocked()
        @fullscreen = on

    disablePointLock: =>
        ###$("#cursor").hide()###
        @controls.disableMouseLocked()
        @fullscreen = off


    axes: ['x', 'y', 'z']
    iterationCount: 10

    moveCube: (speedRatio) ->
        @defineMove()
        iterationCount = Math.round(@iterationCount * speedRatio)
        while iterationCount-- > 0
            @applyGravity()
            for axis in @axes when @move[axis] isnt 0
                originalpos = @player.position(axis)
                @player.incPosition axis, @move[axis]
                if @collides()
                    @player.setPosition axis, originalpos
                    @onGround = true if axis is 'y' and @move.y < 0
                else if axis is 'y' and @move.y <= 0
                    @onGround = false
        return


    playerKeys:
        z: 'z+'
        up: 'z+'
        s: 'z-'
        down: 'z-'
        q: 'x+'
        left: 'x+'
        d: 'x-'
        right: 'x-'

    shouldJump: -> @keysDown.space and @onGround

    defineMove: ->
        baseVel = .4
        jumpSpeed = .8
        @move.x = 0
        @move.z = 0
        for key, action of @playerKeys
            [axis, operation] = action
            vel = if operation is '-' then -baseVel else baseVel
            @move[axis] += vel if @keysDown[key]
        if @shouldJump()
            @onGround = false
            @move.y = jumpSpeed
        @garanteeXYNorm()
        @projectMoveOnCamera()
        return

    garanteeXYNorm: ->
        if @move.x != 0 and @move.z != 0
            ratio = Math.cos(Math.PI / 4)
            @move.x *= ratio
            @move.z *= ratio
        return

    projectMoveOnCamera: ->
        {x, z} = @controls.viewDirection()
        frontDir = new Vector2(x, z).normalize()
        rightDir = new Vector2(frontDir.y, -frontDir.x)
        frontDir.multiplyScalar @move.z
        rightDir.multiplyScalar @move.x
        @move.x = frontDir.x + rightDir.x
        @move.z = frontDir.y + rightDir.y


    applyGravity: -> @move.y -= .005 unless @move.y < -1

    setCameraEyes: ->
        pos = @player.eyesPosition()
        @controls.move pos
        eyesDelta = @controls.viewDirection().normalize().multiplyScalar(20)
        eyesDelta.y = 0
        pos.sub eyesDelta
        return

    idealSpeed: 1 / 60

    tick: ->
        speedRatio = @clock.getDelta() / @idealSpeed
        @placeBlock()
        @deleteBlock()
        @moveCube speedRatio
        @renderer.clear()
        @controls.update()
        @setCameraEyes()
        @renderer.render @scene, @camera

        @renderer.shadowMapEnabled = false;
        # do postprocessing
        @composer.render( 0.1 );
        
        @stats.update()
        return

@Minecraft =
    start: ->
        $("#blocks").hide()
        $('#instructions').hide()
        $(document).bind "contextmenu", -> false
        return Detector.addGetWebGLMessage() unless Detector.webgl
        startGame = ->
            game = new Game()
            new BlockSelection(game).insert()

            $("#minecraft-blocks").show()
            window.game = game
            game.start()
        new Instructions(startGame).insert()

    goFullScreen: ->
        window.game.goFullScreen()
