package vocab

import        "core:fmt"
import linalg "core:math/linalg/glsl"
import        "vendor:glfw"
import gl     "vendor:OpenGL"


// "typedefs" for linalg/glsl package
vec2 :: linalg.vec2
vec3 :: linalg.vec3
vec4 :: linalg.vec4
mat2 :: linalg.mat2
mat3 :: linalg.mat3
mat4 :: linalg.mat4


Window_Type :: enum { MINIMIZED, MAXIMIZED, FULLSCREEN };

mesh_t :: struct
{
  vao, vbo, ebo : u32,
}

data_t :: struct
{
  delta_t_real      : f32,
  delta_t           : f32,
  total_t           : f32,
  cur_fps           : f32,
  time_scale        : f32,
  cur_frame         : i32,

  window         : glfw.WindowHandle,
  window_width   : int,
  window_height  : int,
  monitor        : glfw.MonitorHandle,
  monitor_width  : int,
  monitor_height : int,
  window_title   : string,
  vsync_enabled  : bool,
  window_type    : Window_Type,

  quad_vao : u32,
  quad_vbo : u32,
  

  quad_shader            : u32,
  wireframe_mode_enabled : bool,
  
  mouse_x           : f32,
  mouse_y           : f32,  
  mouse_delta_x     : f32,
  mouse_delta_y     : f32, 

  mouse_sensitivity : f32,

  text_input_rune   : rune,
  text_input_new    : bool,

  cam : struct
  {
    pos       : linalg.vec3,
    target    : linalg.vec3,
    pitch_rad : f32, 
    yaw_rad   : f32, 
    view_mat  : linalg.mat4,
    pers_mat  : linalg.mat4,
  },

  text : struct
  {
    atlas_tex_handle  : u32,
    glyph_size        : i32,
    last_draw_calls   : i32,
    draw_calls        : i32,
    font_name         : string,
    draw_solid        : bool,

    shader            : u32,
    baked_shader      : u32,

    mesh              : mesh_t,
  }
}
data : data_t =
{
  delta_t_real      = 0.0,
  delta_t           = 0.0,
  total_t           = 0.0,
  cur_fps           = 0.0,
  time_scale        = 1.0,
  
  wireframe_mode_enabled = false,
  
  mouse_x           = 0.0,
  mouse_y           = 0.0, 
  mouse_delta_x     = 0.0,
  mouse_delta_y     = 0.0, 

  mouse_sensitivity = 0.5,

  cam = 
  {
    pos       = { 0, 5, -6 },
    target    = {  0, 0, 0 },
    pitch_rad = -0.4,
    yaw_rad   = 14.2,
  },

  text = 
  {
    font_name  = "empty",
    draw_solid = false,
  }
}

data_init :: proc()
{
  // screen quad 
	quad_verts := [?]f32{ 
	  // pos       // uv 
	  -1.0,  1.0,  0.0, 1.0,
	  -1.0, -1.0,  0.0, 0.0,
	   1.0, -1.0,  1.0, 0.0,

	  -1.0,  1.0,  0.0, 1.0,
	   1.0, -1.0,  1.0, 0.0,
	   1.0,  1.0,  1.0, 1.0
	}

	// screen quad VAO
	gl.GenVertexArrays( 1, &data.quad_vao )
	gl.GenBuffers( 1, &data.quad_vbo )
	gl.BindVertexArray( data.quad_vao )
	gl.BindBuffer( gl.ARRAY_BUFFER, data.quad_vbo);
	gl.BufferData( gl.ARRAY_BUFFER, size_of(quad_verts), &quad_verts, gl.STATIC_DRAW); // quad_verts is 24 long
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer( 0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 )
	gl.EnableVertexAttribArray( 1 )
	gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32) )

  // shaders --------------------------------------------------------------------------------------------------

  data.quad_shader       = shader_make( #load( "../assets/quad.vert", cstring ), 
                                        #load( "../assets/quad.frag", cstring ), "quad_shader" )

  data.text.shader       = shader_make( #load( "../assets/text.vert", cstring ),
                                        #load( "../assets/text.frag", cstring ), "text_shader" )

  data.text.baked_shader = shader_make( #load( "../assets/text_baked.vert", cstring ),
                                        #load( "../assets/text.frag",       cstring ), "text_baked_shader" )
  
  // text -----------------------------------------------------------------------------------------------------

}

data_pre_updated :: proc()
{
  @(static) first_frame := true
  // ---- time ----
	data.delta_t_real = f32(glfw.GetTime()) - data.total_t
	data.total_t      = f32(glfw.GetTime())
  data.cur_fps      = 1 / data.delta_t_real
  if ( first_frame ) 
  { data.delta_t_real = 0.016; first_frame = false; } // otherwise dt first frame is like 5 seconds
  data.delta_t = data.delta_t_real * data.time_scale

  data.text.last_draw_calls = data.text.draw_calls
  data.text.draw_calls = 0
}

data_post_update :: proc()
{
  data.mouse_delta_x = 0.0
  data.mouse_delta_y = 0.0
  data.cur_frame += 1
  // fmt.println( "data.cur_frame: ", data.cur_frame )
}

