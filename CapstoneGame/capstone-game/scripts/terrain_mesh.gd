@tool
extends MeshInstance3D

@export_category("Terrain Size")
@export var verts_x: int = 80 : set = _set_regen
@export var verts_z: int = 80 : set = _set_regen
@export var cell_size: float = 1.0 : set = _set_regen

@export_category("Heights")
@export var height_scale: float = 8.0 : set = _set_regen

@export_category("Noise (FastNoiseLite)")
@export var noise_seed: int = 1337 : set = _set_regen
@export var frequency: float = 0.04 : set = _set_regen
@export var octaves: int = 4 : set = _set_regen
@export var lacunarity: float = 2.0 : set = _set_regen
@export var gain: float = 0.5 : set = _set_regen

@export_category("Material")
@export var generate_material: bool = true : set = _set_regen
@export var albedo: Color = Color(0.55, 0.62, 0.55, 1.0) : set = _set_regen
@export var double_sided: bool = true : set = _set_regen # fixes “missing” faces when viewing from different angles

@export_category("Editor")
@export var regenerate: bool = false : set = _toggle_regenerate

var _noise: FastNoiseLite

func _ready() -> void:
	_regen()

func _toggle_regenerate(v: bool) -> void:
	if Engine.is_editor_hint() and v:
		regenerate = false
		_regen()

func _set_regen(_v) -> void:
	if Engine.is_editor_hint():
		_regen()

func _regen() -> void:
	if verts_x < 2 or verts_z < 2:
		return

	_noise = FastNoiseLite.new()
	_noise.seed = noise_seed
	_noise.frequency = frequency
	_noise.fractal_octaves = octaves
	_noise.fractal_lacunarity = lacunarity
	_noise.fractal_gain = gain
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Precompute heights
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(verts_x * verts_z)

	for z in range(verts_z):
		for x in range(verts_x):
			var h := _noise.get_noise_2d(float(x), float(z)) * height_scale
			heights[z * verts_x + x] = h

	# Godot 4: no nested funcs. Use a lambda assigned to a variable.
	var vtx := func(ix: int, iz: int) -> Vector3:
		var h := heights[iz * verts_x + ix]
		return Vector3(ix * cell_size, h, iz * cell_size)

	# Build triangles (don’t share vertices -> flat/low-poly look)
	for z in range(verts_z - 1):
		for x in range(verts_x - 1):
			var a: Vector3 = vtx.call(x,     z)
			var b: Vector3 = vtx.call(x + 1, z)
			var c: Vector3 = vtx.call(x,     z + 1)
			var d: Vector3 = vtx.call(x + 1, z + 1)

			# Tri 1 (a, c, b)
			st.set_uv(Vector2(0, 0)); st.add_vertex(a)
			st.set_uv(Vector2(0, 1)); st.add_vertex(c)
			st.set_uv(Vector2(1, 0)); st.add_vertex(b)

			# Tri 2 (b, c, d)
			st.set_uv(Vector2(1, 0)); st.add_vertex(b)
			st.set_uv(Vector2(0, 1)); st.add_vertex(c)
			st.set_uv(Vector2(1, 1)); st.add_vertex(d)

	st.generate_normals()

	var arr_mesh := st.commit()
	mesh = arr_mesh

	if generate_material:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = albedo
		mat.roughness = 1.0
		mat.metallic = 0.0

		# This is the key “some faces disappear” fix:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED if double_sided else BaseMaterial3D.CULL_BACK

		set_surface_override_material(0, mat)
