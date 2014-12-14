
function add_world(){
    var worldWidth = 200, worldDepth = 200;
    var worldHalfWidth = worldWidth / 2, worldHalfDepth = worldDepth / 2;

    // sides
    var cSize = 25/2;

    var data = generateHeight( worldWidth, worldDepth);



    var light = new THREE.Color( 0xffffff );
    var shadow = new THREE.Color( 0x505050 );

    var matrix = new THREE.Matrix4();

    var pxGeometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    pxGeometry.faces[ 0 ].vertexColors.push( light, shadow, light );
    pxGeometry.faces[ 1 ].vertexColors.push( shadow, shadow, light );
    pxGeometry.faceVertexUvs[ 0 ][ 0 ][ 0 ].y = 0.5;
    pxGeometry.faceVertexUvs[ 0 ][ 0 ][ 2 ].y = 0.5;
    pxGeometry.faceVertexUvs[ 0 ][ 1 ][ 2 ].y = 0.5;
    pxGeometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
    pxGeometry.applyMatrix( matrix.makeTranslation( cSize, 0, 0 ) );

    var nxGeometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    nxGeometry.faces[ 0 ].vertexColors.push( light, shadow, light );
    nxGeometry.faces[ 1 ].vertexColors.push( shadow, shadow, light );
    nxGeometry.faceVertexUvs[ 0 ][ 0 ][ 0 ].y = 0.5;
    nxGeometry.faceVertexUvs[ 0 ][ 0 ][ 2 ].y = 0.5;
    nxGeometry.faceVertexUvs[ 0 ][ 1 ][ 2 ].y = 0.5;
    nxGeometry.applyMatrix( matrix.makeRotationY( - Math.PI / 2 ) );
    nxGeometry.applyMatrix( matrix.makeTranslation( - cSize, 0, 0 ) );

    var pyGeometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    pyGeometry.faces[ 0 ].vertexColors.push( light, light, light );
    pyGeometry.faces[ 1 ].vertexColors.push( light, light, light );
    pyGeometry.faceVertexUvs[ 0 ][ 0 ][ 1 ].y = 0.5;
    pyGeometry.faceVertexUvs[ 0 ][ 1 ][ 0 ].y = 0.5;
    pyGeometry.faceVertexUvs[ 0 ][ 1 ][ 1 ].y = 0.5;
    pyGeometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
    pyGeometry.applyMatrix( matrix.makeTranslation( 0, cSize, 0 ) );

    var py2Geometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    py2Geometry.faces[ 0 ].vertexColors.push( light, light, light );
    py2Geometry.faces[ 1 ].vertexColors.push( light, light, light );
    py2Geometry.faceVertexUvs[ 0 ][ 0 ][ 1 ].y = 0.5;
    py2Geometry.faceVertexUvs[ 0 ][ 1 ][ 0 ].y = 0.5;
    py2Geometry.faceVertexUvs[ 0 ][ 1 ][ 1 ].y = 0.5;
    py2Geometry.applyMatrix( matrix.makeRotationX( - Math.PI / 2 ) );
    py2Geometry.applyMatrix( matrix.makeRotationY( Math.PI / 2 ) );
    py2Geometry.applyMatrix( matrix.makeTranslation( 0, cSize, 0 ) );

    var pzGeometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    pzGeometry.faces[ 0 ].vertexColors.push( light, shadow, light );
    pzGeometry.faces[ 1 ].vertexColors.push( shadow, shadow, light );
    pzGeometry.faceVertexUvs[ 0 ][ 0 ][ 0 ].y = 0.5;
    pzGeometry.faceVertexUvs[ 0 ][ 0 ][ 2 ].y = 0.5;
    pzGeometry.faceVertexUvs[ 0 ][ 1 ][ 2 ].y = 0.5;
    pzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, cSize ) );

    var nzGeometry = new THREE.PlaneGeometry( cSize*2, cSize*2 );
    nzGeometry.faces[ 0 ].vertexColors.push( light, shadow, light );
    nzGeometry.faces[ 1 ].vertexColors.push( shadow, shadow, light );
    nzGeometry.faceVertexUvs[ 0 ][ 0 ][ 0 ].y = 0.5;
    nzGeometry.faceVertexUvs[ 0 ][ 0 ][ 2 ].y = 0.5;
    nzGeometry.faceVertexUvs[ 0 ][ 1 ][ 2 ].y = 0.5;
    nzGeometry.applyMatrix( matrix.makeRotationY( Math.PI ) );
    nzGeometry.applyMatrix( matrix.makeTranslation( 0, 0, - cSize ) );

    //

    var geometry = new THREE.Geometry();
    var dummy = new THREE.Mesh();

    for ( var z = 0; z < worldDepth; z ++ ) {

	for ( var x = 0; x < worldWidth; x ++ ) {

	    var h = getY(data, worldWidth, x, z );
	    console.log(h);
	    
	    dummy.position.x = x * cSize*2 - worldHalfWidth * cSize*2;
	    dummy.position.y = h * cSize*2;
	    dummy.position.z = z * cSize*2 - worldHalfDepth * cSize*2;
	    

	    var px = getY(data, worldWidth, x + 1, z );
	    var nx = getY(data, worldWidth, x - 1, z );
	    var pz = getY(data, worldWidth, x, z + 1 );
	    var nz = getY(data, worldWidth, x, z - 1 );

	    var pxpz = getY(data, worldWidth, x + 1, z + 1 );
	    var nxpz = getY(data, worldWidth, x - 1, z + 1 );
	    var pxnz = getY(data, worldWidth, x + 1, z - 1 );
	    var nxnz = getY(data, worldWidth, x - 1, z - 1 );

	    var a = nx > h || nz > h || nxnz > h ? 0 : 1;
	    var b = nx > h || pz > h || nxpz > h ? 0 : 1;
	    var c = px > h || pz > h || pxpz > h ? 0 : 1;
	    var d = px > h || nz > h || pxnz > h ? 0 : 1;

	    if ( a + c > b + d ) {

		dummy.geometry = py2Geometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = b === 0 ? shadow : light;
		colors[ 1 ] = c === 0 ? shadow : light;
		colors[ 2 ] = a === 0 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 0 ] = c === 0 ? shadow : light;
		colors[ 1 ] = d === 0 ? shadow : light;
		colors[ 2 ] = a === 0 ? shadow : light;

	    } else {

		dummy.geometry = pyGeometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = a === 0 ? shadow : light;
		colors[ 1 ] = b === 0 ? shadow : light;
		colors[ 2 ] = d === 0 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 0 ] = b === 0 ? shadow : light;
		colors[ 1 ] = c === 0 ? shadow : light;
		colors[ 2 ] = d === 0 ? shadow : light;

	    }

	    THREE.GeometryUtils.merge( geometry, dummy );

	    if ( ( px != h && px != h + 1 ) || x == 0 ) {

		dummy.geometry = pxGeometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = pxpz > px && x > 0 ? shadow : light;
		colors[ 2 ] = pxnz > px && x > 0 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 2 ] = pxnz > px && x > 0 ? shadow : light;

		THREE.GeometryUtils.merge( geometry, dummy );

	    }

	    if ( ( nx != h && nx != h + 1 ) || x == worldWidth - 1 ) {

		dummy.geometry = nxGeometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = nxnz > nx && x < worldWidth - 1 ? shadow : light;
		colors[ 2 ] = nxpz > nx && x < worldWidth - 1 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 2 ] = nxpz > nx && x < worldWidth - 1 ? shadow : light;

		THREE.GeometryUtils.merge( geometry, dummy );

	    }

	    if ( ( pz != h && pz != h + 1 ) || z == worldDepth - 1 ) {

		dummy.geometry = pzGeometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = nxpz > pz && z < worldDepth - 1 ? shadow : light;
		colors[ 2 ] = pxpz > pz && z < worldDepth - 1 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 2 ] = pxpz > pz && z < worldDepth - 1 ? shadow : light;

		THREE.GeometryUtils.merge( geometry, dummy );

	    }

	    if ( ( nz != h && nz != h + 1 ) || z == 0 ) {

		dummy.geometry = nzGeometry;

		var colors = dummy.geometry.faces[ 0 ].vertexColors;
		colors[ 0 ] = pxnz > nz && z > 0 ? shadow : light;
		colors[ 2 ] = nxnz > nz && z > 0 ? shadow : light;

		var colors = dummy.geometry.faces[ 1 ].vertexColors;
		colors[ 2 ] = nxnz > nz && z > 0 ? shadow : light;

		THREE.GeometryUtils.merge( geometry, dummy );

	    }

	}

    }

    var texture = THREE.ImageUtils.loadTexture( 'textures/minecraft/atlas.png' );
    texture.magFilter = THREE.NearestFilter;
    texture.minFilter = THREE.LinearMipMapLinearFilter;

//    var mesh = new THREE.Mesh( geometry, new THREE.MeshBasicMaterial({color: 'red'}));//new THREE.MeshLambertMaterial( { map: texture, ambient: 0xbbbbbb, vertexColors: THREE.VertexColors } ) );
    var mesh = new THREE.Mesh( geometry, new THREE.MeshLambertMaterial( { map: texture, ambient: 0xbbbbbb, vertexColors: THREE.VertexColors } ) );
    return mesh;
}



/*
function loadTexture( path, callback ) {

    var image = new Image();

    image.onload = function () { callback(); };
    image.src = path;

    return image;

}
*/

function generateHeight( width, height) {

    var data = [], perlin = new ImprovedNoise(),
    size = width * height, quality = 0.5, z = 100;

    for ( var j = 0; j < 4; j ++ ) {

	if ( j == 0 ) for ( var i = 0; i < size; i ++ ) data[ i ] = 0;

	for ( var i = 0; i < size; i ++ ) {

	    var x = i % width, y = ( i / width ) | 0;
	    data[ i ] += perlin.noise( x / quality, y / quality, z ) * quality;

	}

	quality *= 4

    }

    return data;

}

function getY(data, worldWidth, x, z ) {
    return ( data[ x + z * worldWidth ] * 0.2 ) | 0;
}
