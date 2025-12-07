// An elementary program in Odin which renders a character from a
// font and moves it in a circle.
//
// Created by Benjamin Thompson. Available at:
// https://github.com/bg-thompson/OpenGL-Tutorials-In-Odin
// Last updated: 2022.11.13
//
// To compile and run the program, use the command
//
//     odin run Moving-Character
//
// Created for educational purposes. Used verbatim, it is probably
// unsuitable for production code.

package vocab 

import        "vendor:glfw"
import gl     "vendor:OpenGL"
import        "core:time"
import        "core:fmt"
import        "core:log"
import        "core:os"
import        "core:math"
import linalg "core:math/linalg/glsl"
import        "core:image"
import        "core:image/png"
import str    "core:strings"
import        "core:mem/virtual"
import        "base:runtime"
// import        "core:encoding/ansi"
import        "core:terminal/ansi"
import        "core:math/rand"

// Global variables.
// global_vao       : u32 
watch            : time.Stopwatch


win_main :: proc() 
{

  // setup context
  // context.temp_allocator = runtime.default_temp_allocator_init( 64 * 1024 )
  // runtime.default_temp_allocator_init( context.temp_allocator, 64 * 1024 )
  // init_global_temporary_allocator( 1 * 1024 )
  // init_global_temporary_allocator( 1 )
  
  // setup log
  // context.logger = log.create_console_logger()
  context.logger = create_console_logger()
  when ODIN_DEBUG // no need to as windows does it automatically
  { defer destroy_console_logger( context.logger ) }
  
  if !window_create( 1000, 800, "title", Window_Type.MINIMIZED, false )
  {
    panic( "failed to create window" )
  }
  
  data_init()
  input_init()

  // text_load_glyph( '#', 100 )

  // atlas_handle, atlas_w, atlas_h := text_make_atlas( "C:/Windows/Fonts/arialbd.ttf", 30 )
  atlas_handle, atlas_w, atlas_h := text_make_atlas( "assets/JetBrainsMonoNL-Regular.ttf", 30 )

  // opengl state
  // Texture blending options.
  gl.Enable(gl.BLEND)
  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

  voc := rand.choice( vocab_arr[:] )

  // Main loop.
  for !window_should_close()
  {
	  glfw.PollEvents()
	  // If a key press happens, .PollEvents calls callback_key, defined below.
          // Note: glfw.PollEvents blocks on window menu interaction selection or
	  // window resize. During window_resize, glfw.SetWindowRefreshCallback
	  // calls window_refresh to redraw the window.
    data_pre_updated()


    // @TODO: use context tempt-alloc https://odin-lang.org/docs/faq/#context-system
    title := fmt.tprintf( "fps: %.2f, frame: %v, text_draw_calls: %v", data.cur_fps, data.cur_frame, data.text.last_draw_calls )
    title_cstr := str.clone_to_cstring( title )
    window_set_title( title_cstr )
    
    if keystates[KEY.ESCAPE].pressed
    { break }
    if keystates[KEY.TAB].pressed
    { 
      data.wireframe_mode_enabled  = !data.wireframe_mode_enabled 
      data.text.draw_solid         = !data.text.draw_solid 
    }
    if keystates[KEY.ENTER].pressed
    { 
      data.text.draw_solid = !data.text.draw_solid 
    }
    // wireframe mode
    if ( data.wireframe_mode_enabled == true )
	  { gl.PolygonMode( gl.FRONT_AND_BACK, gl.LINE ) }
	  else
	  { gl.PolygonMode( gl.FRONT_AND_BACK, gl.FILL ) }

    // rendering -------------------------------------

    gl.ClearColor( 0.1, 0.1, 0.1, 1 )
    gl.Clear( gl.COLOR_BUFFER_BIT )

    // win_main_draw_string_test()
    display_vocab_question_win( voc )

    glfw.SwapBuffers( data.window )

    // -----------------------------------------------

    data_post_update()
    input_update()
    
    free_all( context.temp_allocator )
  }
}

win_main_draw_string_test :: proc()
{
  // text_draw_glyph( linalg.vec2{ -1.00, -0.5 }, 0 )
  // text_draw_glyph( linalg.vec2{ -0.75, -0.5 }, 1 )
  text_y_pos : f32 = 0.75
  str_len_total : i32 = 0
  // data.text.draw_solid = true
  str_len_total += text_draw_string( data.text.font_name,                          linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  str_len_total += text_draw_string( "._. ?!\"'#*/&%$(){}^`<>_-;:,",               linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  // str_len_total += text_draw_string( "",                                           linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  str_len_total += text_draw_string( "THE FOX JUMPS OVER THE FENCE OR SOMETHING",  linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  str_len_total += text_draw_string( "the fox jumps over the fence or something",  linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  str_len_total += text_draw_string( "abcdefghijklnmnopqrstuvwxyz àâæçèéêëîïôœùû", linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  str_len_total += text_draw_string( "ABCDEFGHIJKLNMNOPQRSTUVWXYZ ÀÂÆÇÈÉÊËÎÏÔŒÙÛ", linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 

  // print total amount of runes in drawn strings
  str_len_total += 29 
  str_len_total_str := fmt.tprintf( "glyphs / chars / runes: %5d", str_len_total )
  text_draw_string( str_len_total_str,                                            linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= 0.25 
  // fmt.println( "str_len_total: ", str_len_total )

  // @TODO:
  // text_draw_string( "text_draw_string()", linalg.vec2{ 0.0, -0.25 } ) 
  // text_draw_string( "X", linalg.vec2{ 0.0, -0.25 } ) 
  @static offs := vec2{ 0.0,  0.0 }
  SPEED :: 10.0
  if keystates[KEY.UP].down
  { offs.y += data.delta_t * SPEED }
  if keystates[KEY.DOWN].down
  { offs.y -= data.delta_t * SPEED }
  if keystates[KEY.LEFT].down
  { offs.x += data.delta_t * SPEED }
  if keystates[KEY.RIGHT].down
  { offs.x -= data.delta_t * SPEED }
  // text_bake_string( "text_bake_string()", vec2{ 0.0,  0.0 } /* + offs */ )  
  // text_bake_string( "X", vec2{ 0.0,  0.25 } /* + offs */ )  
  text_y_pos -= 0.25
}

util_mat4_mul_v :: #force_inline proc( m: mat4, v: vec4 ) -> ( out: vec4 )
{
  out.x = m[0][0] * v[0] + m[1][0] * v[1] + m[2][0] * v[2] + m[3][0] * v[3]
  out.y = m[0][1] * v[0] + m[1][1] * v[1] + m[2][1] * v[2] + m[3][1] * v[3]
  out.z = m[0][2] * v[0] + m[1][2] * v[1] + m[2][2] * v[2] + m[3][2] * v[3]
  out.w = m[0][3] * v[0] + m[1][3] * v[1] + m[2][3] * v[2] + m[3][3] * v[3]
  return out
}
util_mat2_mul_v :: #force_inline proc( m: mat2, v: vec4 ) -> ( out: vec4 )
{
  out.x = m[0][0] * v.x + m[1][0] * v.y 
  out.y = m[0][1] * v.x + m[1][1] * v.y 
  out.z = 0
  out.w = 1
  return out
}

draw_quad :: proc( pos, scl: linalg.vec2, texture_handle: u32 )
{
  gl.Disable( gl.CULL_FACE )
  gl.Disable( gl.DEPTH_TEST)

  // -- draw triangle --
  // gl.UseProgram( data.quad_shader )
  shader_use( data.quad_shader )
  gl.BindVertexArray( data.quad_vao )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "pos"), pos.x, pos.y )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "scl"), scl.x, scl.y )
  shader_act_set_vec2( "pos", pos )
  shader_act_set_vec2( "scl", scl )
  
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_2D, texture_handle )
  // gl.Uniform1i( gl.GetUniformLocation(data.quad_shader, "tex"), 0 )
  shader_act_set_i32( "tex", 0 )

  gl.DrawArrays( gl.TRIANGLES,    // Draw triangles.
                 0,               // Begin drawing at index 0.
                 6 )              // Use 3 indices.

  gl.Enable( gl.CULL_FACE )
  gl.Enable( gl.DEPTH_TEST)
}
gl_format_str :: proc( format: i32 ) -> string
{
  return format == gl.R8         ? "R8"         :
         format == gl.SRGB8      ? "SRGB8"      :
         format == gl.RED        ? "RED"        :
         format == gl.RGB        ? "RGB"        :
         format == gl.SRGB       ? "SRGB"       :
         format == gl.RGBA       ? "RGBA"       :
         format == gl.SRGB_ALPHA ? "SRGB_ALPHA" :
         "unknown" 
}
make_texture :: proc( path: string, srgb: bool ) -> ( handle: u32 )
{
  // Load image at compile time
  // image_file_bytes := #load( "../assets/texture_01.png" )
  image_file_bytes, ok := os.read_entire_file( path, context.allocator )
  if( !ok ) 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln("could not read texture file: ", path)
    os.exit(1)
  }
  defer delete( image_file_bytes, context.allocator )

  // Load image  Odin's core:image library.
  image_ptr :  ^image.Image
  err       :   image.Error
  // options   :=  image.Options { .alpha_add_if_missing }
  options   :=  image.Options { }

  image_ptr, err =  png.load_from_bytes( image_file_bytes, options )
  defer png.destroy( image_ptr )
  image_w := i32( image_ptr.width )
  image_h := i32( image_ptr.height )

  if ( err != nil )
  {
      fmt.println("ERROR: Image failed to load.")
  }

  // Copy bytes from icon buffer into slice.
  pixels := make( []u8, len(image_ptr.pixels.buf) )
  for b, i in image_ptr.pixels.buf 
  {
      pixels[i] = b
  }
  gl.GenTextures( 1, &handle )
  gl.BindTexture( gl.TEXTURE_2D, handle )

  // Texture wrapping options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  
  // Texture filtering options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)


  gl_internal_format : i32 = srgb ? gl.SRGB_ALPHA : gl.RGBA
  gl_format          : u32 = gl.RGBA
  switch image_ptr.channels
  {
    case 1:
      gl_internal_format = srgb ? gl.SRGB8 : gl.R8
      gl_format = gl.RED
      break;
    // case 2:
    //   gl_internal_format = gl.RG8
    //   gl_format = gl.RG
    //   // P_INFO("gl.RGB");
    //   break;
    case 3:
      gl_internal_format = srgb ? gl.SRGB : gl.RGB
      gl_format = gl.RGB
      break;
    case 4:
      gl_internal_format = srgb ? gl.SRGB_ALPHA : gl.RGBA
      gl_format = gl.RGBA
      break;
    case:
      fmt.eprintln( "texture has incorrect channel amount: ", image_ptr.channels )
      os.exit( 1 )
  }
  assert( image_ptr.channels >= 1 && image_ptr.channels <= 4, "texture has incorrect channel amount" )

  // Describe texture.
  gl.TexImage2D(
      gl.TEXTURE_2D,      // texture type
      0,                  // level of detail number (default = 0)
      gl_internal_format, // gl.RGBA, // texture format
      image_w,            // width
      image_h,            // height
      0,                  // border, must be 0
      gl_format,          // gl.RGBA, // pixel data format
      gl.UNSIGNED_BYTE,   // data type of pixel data
      &pixels[0],         // image data
  )

  // must be called after glTexImage2D
  gl.GenerateMipmap(gl.TEXTURE_2D);

  return handle
}

texture_free_handle :: proc( _handle: u32 )
{
  handle := _handle
  if handle == 0 { return }
	gl.DeleteTextures( 1, &handle )
  handle = 0;
}
