package vocab 

import        "core:fmt"
import gl     "vendor:OpenGL"
import linalg "core:math/linalg/glsl"

handle_act  : u32
tex_idx_act : u32 = 0


shader_make :: proc( vertex_src, fragment_src: cstring, name := "unnamed") -> ( handle: u32 )
{
  // // Compile vertex shader and fragment shader.
  // // Note how much easier this is in Odin than in C++!
  // program_ok      : bool
  // // vertex_shader   := string( #load( "../assets/basic.vert" ) )
  // // fragment_shader := string( #load( "../assets/basic.frag" ) )
  // // handle, program_ok = gl.load_shaders_source( vertex_shader, fragment_shader )
  // handle, program_ok = gl.load_shaders_source( vertex_src, fragment_src )

  // if ( !program_ok )
  // {
  //   fmt.println( "ERROR: Failed to load and compile shaders: ", name )
  //   panic( "shader comp failed" ) 
  // }

  vertex_src_copy := vertex_src
  vertex_src_ptr := &vertex_src_copy
  vertexShader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertexShader, 1, vertex_src_ptr, nil)
	gl.CompileShader(vertexShader)

	// check for shader compile errors
	success : i32
	infoLog : [512]byte
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success)
	if success == 0
	{
		gl.GetShaderInfoLog(vertexShader, 512, nil, &infoLog[0])
		fmt.eprintf("%s-!!!-> ERROR_VERTEX_COMPILATION: [%s]\n -> %s\n", vertex_src, name, infoLog)
    panic( "vertex shader comp failed" )
	}

	// fragment shader
  fragment_src_copy := fragment_src
  fragment_src_ptr := &fragment_src_copy
  fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragmentShader, 1, fragment_src_ptr, nil)
	gl.CompileShader(fragmentShader)

	// check for shader compile errors
	gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success)
	if success == 0
	{
		gl.GetShaderInfoLog(fragmentShader, 512, nil, &infoLog[0])
		fmt.eprintf("%s\n-!!!-> ERROR_FRAGMENT_COMPILATION: [%s]\n -> %s\n", fragment_src, name, infoLog)
    panic( "fragment shader comp failed" )
	}

	// link shaders
  shaderProgram := gl.CreateProgram()
	gl.AttachShader(shaderProgram, vertexShader)
	gl.AttachShader(shaderProgram, fragmentShader)
	gl.LinkProgram(shaderProgram)

	// check for linking errors
	gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success)
	if success == 0
  {
		gl.GetProgramInfoLog(shaderProgram, 512, nil, &infoLog[0])
		fmt.eprintf("-!!!-> ERROR_PROGRAM_LINKING: [%s]\n -> %s\n", name, infoLog)
    panic( "shader liking failed" )
	}

	// free the shaders
	gl.DeleteShader(vertexShader)
	gl.DeleteShader(fragmentShader)

  return shaderProgram
}


shader_use :: #force_inline proc( handle: u32 )
{
  gl.UseProgram( handle )
  handle_act  = handle
  tex_idx_act = 0
}
shader_delete :: #force_inline proc( handle: u32 )
{
	gl.DeleteProgram( handle )
  if handle == handle_act { handle_act = 0; tex_idx_act = 0 }
}

// shader set ---------------------------------------------------------------------------------

shader_set_bool :: #force_inline proc( handle: u32, name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), value )
}
// set an integer in the shader
shader_set_i32:: #force_inline proc( handle: u32, name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), value )
}
// set a float in the shader
shader_set_f32:: #force_inline proc( handle: u32, name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle, name ), value )
}
// set a vec2 in the shader
shader_set_vec2_f :: #force_inline proc( handle: u32, name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), x, y )
}
// set a vec2 in the shader
shader_set_vec2 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_set_vec3_f :: #force_inline proc( handle: u32, name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), x, y, z )
}
// set a vec3 in the shader
shader_set_vec3 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: linalg.mat4 )
shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle, name ), 1, gl.FALSE, value )
}
shader_set_mat2_transpose :: #force_inline proc( handle: u32, name : cstring, value : [^] f32) 
{
    gl.UniformMatrix2fv(gl.GetUniformLocation( handle, name ), 1, gl.TRUE, value )
}
shader_set_mat4_transpose :: #force_inline proc( handle: u32, name : cstring, value : [^] f32) {
    gl.UniformMatrix4fv(gl.GetUniformLocation( handle, name ), 1, gl.TRUE, value )
}

shader_bind_texture :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}
shader_bind_cube_map :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}

// shader act ---------------------------------------------------------------------------------

shader_act_set_bool :: #force_inline proc( name: cstring, value: bool )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(value) )
}
// set an integer in the shader
shader_act_set_i32:: #force_inline proc( name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), value )
}
// set a float in the shader
shader_act_set_f32:: #force_inline proc( name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle_act, name ), value )
}
// set a vec2 in the shader
shader_act_set_vec2_f :: #force_inline proc( name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), x, y )
}
// set a vec2 in the shader
shader_act_set_vec2 :: #force_inline proc( name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_act_set_vec3_f :: #force_inline proc( name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), x, y, z )
}
// set a vec3 in the shader
shader_act_set_vec3 :: #force_inline proc( name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_act_set_mat4 :: #force_inline proc( name: cstring, value: linalg.mat4 )
shader_act_set_mat4 :: #force_inline proc( name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle_act, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle_act, name ), 1, gl.FALSE, value )
}
shader_act_set_mat2_transpose :: #force_inline proc( name : cstring, value : [^] f32) 
{
    gl.UniformMatrix2fv(gl.GetUniformLocation( handle_act, name ), 1, gl.TRUE, value )
}
shader_act_set_mat4_transpose :: #force_inline proc( name : cstring, value : [^] f32) {
    gl.UniformMatrix4fv(gl.GetUniformLocation( handle_act, name ), 1, gl.TRUE, value )
}

shader_act_bind_cube_map :: #force_inline proc( name: cstring, tex_handle: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1
}
// shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32, tex_idx: u32 )
shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1
}
