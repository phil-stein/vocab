package vocab

import        "core:os"
import        "core:fmt"
import        "core:unicode/utf8"
import str    "core:strings"
import        "core:math/rand"
import win    "core:sys/windows"
import linalg "core:math/linalg/glsl"

vocab_t :: struct
{
  de : string,
  fr : string,
  en : string,

  error_rate: f32,
}


// vocab_arr := [?]vocab_t{ { de="sein", fr="être" }, { de="halldo", fr="salut" }, { de="Guten Tag", fr="bonne journée" }, { de="rot", fr="rouge" } }

Compare_Type :: enum
{
  Correct,
  Wrong,
  Case_Sensitivity,
  Wrong_Accent,
  Incorrect_Length,
}

compare_t :: struct
{
  type : Compare_Type,

  char_start : int,
  char_end   : int,
}

vocab_arr : [dynamic]vocab_t

sb_answer: str.Builder

read_vocab_files :: proc( file_name: string )
{
  data, ok := os.read_entire_file_from_filename( file_name )
	if !ok 
  {
    fmt.println( "[ERROR] could not read vocab file:", file_name )
		return
	}
	defer delete( data )
	
  it := string( data )
	for line in str.split_lines_iterator( &it ) 
  {
    // sp, err := str.split( line, " ", context.temp_allocator )
    // fmt.print( "len(sp):", len(sp) )
    // for s in sp { fmt.print( s, "#", sep="" ) }; fmt.print( "\n" )
	
    // ra, was_alloc := str.remove_all( line, " ", context.temp_allocator )
    // fmt.println( ra )
    
    Cur_State :: enum
    {
      French,
      German,
      English,
      End,
    }
    
    line_has_vocab := false
    cur_state      := Cur_State.French
    french_start   := 0
    french_end     := 0
    german_start   := 0
    german_end     := 0
    english_start  := 0
    english_end    := 0

    last_end := 0

    for c, i in line
    {
      // skip comments
      if i < len(line)-1 && c == '/' && line[i +1] == '/' { break }
      
      // found divider / end of line
      if c == '|' || i == len(line) -1
      {
        // walk back space chars after vocab
        walk_back_idx := 0 
        for walk_back_idx = i == len(line)-1 ? 0 : 1; 
            walk_back_idx < i && str.is_space( rune(line[i - walk_back_idx]) ); 
            walk_back_idx += 1
        {}
        walk_back_idx = walk_back_idx > 0 ? walk_back_idx -1 : 0
        // fmt.println( "walk_back_idx:", walk_back_idx, "i:", i, "i-walk_back_idx:", i-walk_back_idx, "len(line)", len(line) )

        // walk forwad over space chars since last |
        if last_end > 0
        {
          for i := last_end +1; i < len(line)-1; i += 1
          {
            if str.is_space( rune(line[i]) ) { last_end += 1 }
            else { last_end += 1; break }
          }
        }

        switch cur_state
        {
          case Cur_State.French:  
          { french_start = last_end; french_end = i-walk_back_idx;   cur_state = Cur_State.German }
          case Cur_State.German:  
          { german_start = last_end; german_end = i-walk_back_idx;   cur_state = Cur_State.English }
          case Cur_State.English: 
          { english_start = last_end; english_end = i-walk_back_idx; cur_state = Cur_State.End; line_has_vocab = true }
          case Cur_State.End: 
          { assert( cur_state != .End, "cur_state should not be end after getting another vocab" ) } 
        }
        last_end = i
      }
    }
    if line_has_vocab
    {
      // fmt.println( "has vocab, french:", line[french_start:french_end], ", german:", line[german_start:german_end], ", english:", line[english_start:english_end +1] )
      vocab : vocab_t 
      vocab.fr = str.clone( line[french_start:french_end] )
      vocab.de = str.clone( line[german_start:german_end] )
      vocab.en = str.clone( line[english_start:english_end +1] )
      vocab.error_rate = 1.0
      append( &vocab_arr, vocab )
    }

  }

}

main :: proc()
{
  when ODIN_OS == .Windows
  {
    // @NOTE: enable utf output to console, windows specific
    win.SetConsoleOutputCP( win.CODEPAGE(win.CP_UTF8) )
  }

  // -- flags ---
  use_window := false

  for arg in os.args[1:]
  {
    if arg == "-win"
    {
      use_window = true
    }
  }

  read_vocab_files( "assets/01.vocab" )

  if use_window
  {
    sb_answer = str.builder_make()
    voc := rand.choice( vocab_arr[:] )
    win_main( &voc )
  }
  else
  {
    running := true
    for running
    {
      fmt.print( "\n" )
      voc := rand.choice( vocab_arr[:] )
      display_vocab_question_terminal( voc )
      fmt.print( "\n" )
      fmt.println( "──────────────────────────────" )
    }
  }
}

display_vocab_question_terminal :: proc( voc: vocab_t )
{
  voc := voc
  // voc := rand.choice( vocab_arr[:] )

  fmt.println( pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.BLUE ), "E", pf_style_reset_str(),
               pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.BLUE ), "N", pf_style_reset_str(),
               pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.BLUE ), ":", pf_style_reset_str(), " ", voc.en, sep="" )
  // fmt.println( "DE:\"", voc.de, "\"", sep="" )
  fmt.println( pf_mode_str( PF_Mode.NORMAL, PF_Fg.WHITE, PF_Bg.BLACK ),  "D", pf_style_reset_str(),
               pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.RED ),    "E", pf_style_reset_str(),
               pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.YELLOW ), ":", pf_style_reset_str(), " ", voc.de, sep="" )

  // fmt.print( "FR: " )
  fmt.print( pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.BLUE ),  "F", pf_style_reset_str(),
             pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.WHITE ), "R", pf_style_reset_str(),
             pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.RED ),   ":", pf_style_reset_str(), " ", sep="" )
  // fmt.println( pf_mode_str( PF_Mode.NORMAL, PF_Fg.WHITE, PF_Bg.BLACK ),  " ", pf_style_reset_str(),
  //              pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.RED ),    " ", pf_style_reset_str(),
  //              pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.YELLOW ), " ", pf_style_reset_str(), "FR: ", voc.de, sep="" )
  //
  // fmt.print( pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.BLUE ),  " ", pf_style_reset_str(),
  //            pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.WHITE ), " ", pf_style_reset_str(),
  //            pf_mode_str( PF_Mode.NORMAL, PF_Fg.BLACK, PF_Bg.RED ),   " ", pf_style_reset_str(), "DE: ", sep="" )
  buf: [256]byte
  bytes_read, _ := os.read( os.stdin, buf[:] )
  for i := bytes_read -1; i >= 0; i -= 1
  {
    if str.is_space( rune(buf[i]) ) { bytes_read -= 1 }
    else do break
  }
  answer := string( buf[:bytes_read] )
  // fmt.println( "You typed:", answer )
  // fmt.print( "|" ); fmt.print( voc.fr ); fmt.print( "|" ); fmt.print( answer ); fmt.print( "|\n" )
  // for c, i in answer
  // {
  //   fmt.println( i, c )
  // }
  
  // if answer == voc.fr
  // {
  //   fmt.println( "correct" )
  // }
  // else 
  // {
  //   fmt.println( "false:", voc.fr )
  // }

  comp_arr, comp_flag, correct := vocab_compare( answer, &voc )

  pf_bracket := PF_Fg.WHITE
  if      Compare_Type.Wrong            in comp_flag { pf_bracket = PF_Fg.RED } 
  else if Compare_Type.Wrong_Accent     in comp_flag { pf_bracket = PF_Fg.YELLOW } 
  else if Compare_Type.Case_Sensitivity in comp_flag { pf_bracket = PF_Fg.CYAN } 
  else if Compare_Type.Incorrect_Length in comp_flag { pf_bracket = PF_Fg.PURPLE } 
  else                                               { pf_bracket = PF_Fg.GREEN } 
    
  // line01_sb := str.builder_make()
  fmt.println( pf_style_str( PF_Mode.NORMAL, pf_bracket ), "  ┌ ", pf_style_reset_str(), answer, sep="" )
  line02_sb := str.builder_make()
  str.write_string( &line02_sb, fmt.tprint( pf_style_str( PF_Mode.NORMAL, pf_bracket ), "  ├─", pf_style_reset_str(), sep="" ) ) // │

  incorrect_length_idx := -1
  for comp, i in comp_arr
  {
    switch comp.type
    {
      case Compare_Type.Incorrect_Length:
      {
        incorrect_length_idx = i
      }
      case Compare_Type.Correct:          { str.write_string( &line02_sb, fmt.tprint( pf_style_str( PF_Mode.NORMAL, pf_bracket ), "─", pf_style_reset_str(), sep="" ) ) }
      case Compare_Type.Wrong:            
      { str.write_string( &line02_sb, 
        fmt.tprint( pf_style_str( PF_Mode.NORMAL, PF_Fg.RED ), "", pf_style_reset_str(), sep="" ) ) 
      }
      case Compare_Type.Case_Sensitivity: 
      { str.write_string( &line02_sb, 
        fmt.tprint( pf_style_str( PF_Mode.NORMAL, PF_Fg.CYAN ), "", pf_style_reset_str(), sep="" ) ) 
      }
      case Compare_Type.Wrong_Accent:             // { str.write_string( &line02_sb, "^" ) }
      { str.write_string( &line02_sb, 
        fmt.tprint( pf_style_str( PF_Mode.NORMAL, PF_Fg.YELLOW ), "", pf_style_reset_str(), sep="" ) ) 
      }
    }
  }

  fmt.println( str.to_string( line02_sb ) )
  
  fmt.println( pf_style_str( PF_Mode.NORMAL, pf_bracket ), "  ├ ", pf_style_reset_str(), voc.fr, sep="" ) // └
  
  fmt.println( pf_style_str( PF_Mode.NORMAL, correct ? PF_Fg.GREEN : PF_Fg.RED ), "  └ ", voc.error_rate, " error rate", pf_style_reset_str(), sep="" )

}

input_active := true
// answer : string
display_vocab_question_win :: proc( voc: ^vocab_t )
{
  voc := voc
  // voc := rand.choice( vocab_arr[:] )

  // LINE_HEIGHT :: 0.075
  // text_y_pos : f32 = 0.75
  // text_draw_string( fmt.tprint( "EN:", voc.en ), linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= LINE_HEIGHT 
  // text_draw_string( fmt.tprint( "DE:", voc.de ), linalg.vec2{ -0.95, text_y_pos } ); text_y_pos -= LINE_HEIGHT
  // 
  // str_len : i32 = 0
  // str_len += text_draw_string( "FR:", linalg.vec2{ -0.95, text_y_pos } ); 
  //
  // str_len += text_draw_string( str.to_string( sb_answer ), linalg.vec2{ -0.84, text_y_pos } ); 
  // text_y_pos -= LINE_HEIGHT
  LINE_HEIGHT :: 32
  text_y_pos  := 80
  text_draw_string_px( fmt.tprint( "EN:", voc.en ), linalg.ivec2{ 50, text_y_pos } ); text_y_pos -= LINE_HEIGHT 
  text_draw_string_px( fmt.tprint( "DE:", voc.de ), linalg.ivec2{ 50, text_y_pos } ); text_y_pos -= LINE_HEIGHT
  
  str_len : i32 = 0
  str_len += text_draw_string_px( "FR:", linalg.vec2{ -0.95, text_y_pos } ); 

  str_len += text_draw_string_px( str.to_string( sb_answer ), linalg.vec2{ -0.84, text_y_pos } ); 
  text_y_pos -= LINE_HEIGHT

  if input_active
  {
    text_draw_glyph( linalg.vec2{ -0.95 + 0.0272 * ( f32(str_len) +0.5 ), text_y_pos + LINE_HEIGHT }, '|' )

    if keystates[KEY.BACKSPACE].pressed
    {
      s := str.to_string( sb_answer )
      str.builder_reset( &sb_answer )
      end := len(s)-1 >= 0 ? len(s)-1 : 0
      str.write_string( &sb_answer, s[:end] )
    }
    if data.text_input_new
    {
      str.write_rune( &sb_answer, data.text_input_rune )
    }

    if keystates[KEY.ENTER].pressed
    {
      // answer = str.to_string( sb_answer )
      input_active = false
    }
  }
  else
  {
    comp_arr, comp_flag, correct := vocab_compare( str.to_string( sb_answer ), voc )
    
    str_len += text_draw_string( fmt.tprint( correct ? "correct" : "false" ), linalg.vec2{ -0.95, text_y_pos } ); 
    text_y_pos -= LINE_HEIGHT
    
    str_len += text_draw_string( fmt.tprint( "answer:", str.to_string( sb_answer ) ), linalg.vec2{ -0.95, text_y_pos } ); 
    text_y_pos -= LINE_HEIGHT
    
    str_len += text_draw_string( fmt.tprint( "vocab: ", voc.fr ), linalg.vec2{ -0.95, text_y_pos } ); 
    text_y_pos -= LINE_HEIGHT
    
    text_y_pos -= LINE_HEIGHT
    str_len += text_draw_string( "press enter to continue", linalg.vec2{ -0.95, text_y_pos } ); 
    text_y_pos -= LINE_HEIGHT

    
    if keystates[KEY.ENTER].pressed
    {
      voc^ = rand.choice( vocab_arr[:] )
      input_active = true 
      str.builder_reset( &sb_answer )
    }
  }
}

vocab_compare :: proc( answer: string, voc: ^vocab_t ) -> ( comp_arr: [dynamic]compare_t, comp_flag: bit_set[Compare_Type], correct: bool )
{
  
  // defer delete( comp_arr )
  

  answer_r := utf8.string_to_runes( answer, context.temp_allocator )  
  voc_fr_r := utf8.string_to_runes( voc.fr, context.temp_allocator )  

  if len(answer_r) != len(voc_fr_r)
  {
    comp : compare_t
    comp.type = Compare_Type.Incorrect_Length
    comp.char_start = -1 
    comp.char_end   = -1 
    append( &comp_arr, comp )

    comp_flag += { Compare_Type.Incorrect_Length }
  }
  
  ERROR_RATE_MILD    :: 0.1
  ERROR_RATE_STRONG  :: 0.3
  ERROR_RATE_CORRECT :: 0.8

  for i := 0; i < len(answer_r) && i < len(voc_fr_r); i += 1
  {
    c := answer_r[i]

    if c == voc_fr_r[i] 
    { 
      comp : compare_t
      comp.type = Compare_Type.Correct
      comp.char_start = i
      comp.char_end   = i
      append( &comp_arr, comp )

      comp_flag += { Compare_Type.Correct }
    } 
    else if str.to_lower( fmt.tprint( c ) ) == str.to_lower( fmt.tprint( voc_fr_r[i] ) )
    {
      comp : compare_t
      comp.type = Compare_Type.Case_Sensitivity
      comp.char_start = i
      comp.char_end   = i
      append( &comp_arr, comp )

      comp_flag += { Compare_Type.Case_Sensitivity }

      voc.error_rate += ERROR_RATE_MILD
    }
    else if ( voc_fr_r[i] == 'à' && c == 'a' ) || ( voc_fr_r[i] == 'À' && c == 'A' ) ||
            ( voc_fr_r[i] == 'ä' && c == 'a' ) || ( voc_fr_r[i] == 'Ä' && c == 'A' ) ||
            ( voc_fr_r[i] == 'â' && c == 'a' ) || ( voc_fr_r[i] == 'Â' && c == 'A' ) ||
            ( voc_fr_r[i] == 'æ' && c == 'a' ) || ( voc_fr_r[i] == 'Æ' && c == 'A' ) ||

            ( voc_fr_r[i] == 'ç' && c == 'c' ) || ( voc_fr_r[i] == 'Ç' && c == 'C' ) ||             
            
            ( voc_fr_r[i] == 'é' && c == 'e' ) || ( voc_fr_r[i] == 'É' && c == 'E' ) ||
            ( voc_fr_r[i] == 'é' && c == 'è' ) || ( voc_fr_r[i] == 'É' && c == 'È' ) ||
            ( voc_fr_r[i] == 'é' && c == 'ê' ) || ( voc_fr_r[i] == 'É' && c == 'Ê' ) ||
            ( voc_fr_r[i] == 'è' && c == 'e' ) || ( voc_fr_r[i] == 'È' && c == 'E' ) ||
            ( voc_fr_r[i] == 'è' && c == 'é' ) || ( voc_fr_r[i] == 'È' && c == 'É' ) ||
            ( voc_fr_r[i] == 'è' && c == 'ê' ) || ( voc_fr_r[i] == 'È' && c == 'Ê' ) ||
            ( voc_fr_r[i] == 'ê' && c == 'e' ) || ( voc_fr_r[i] == 'Ê' && c == 'E' ) ||
            ( voc_fr_r[i] == 'ê' && c == 'é' ) || ( voc_fr_r[i] == 'Ê' && c == 'É' ) ||
            ( voc_fr_r[i] == 'ê' && c == 'è' ) || ( voc_fr_r[i] == 'Ê' && c == 'È' ) ||
            ( voc_fr_r[i] == 'ë' && c == 'e' ) || ( voc_fr_r[i] == 'Ë' && c == 'E' ) ||

            ( voc_fr_r[i] == 'î' && c == 'i' ) || ( voc_fr_r[i] == 'Î' && c == 'I' ) ||
            ( voc_fr_r[i] == 'ï' && c == 'i' ) || ( voc_fr_r[i] == 'Ï' && c == 'I' ) ||
            ( voc_fr_r[i] == 'ô' && c == 'o' ) || ( voc_fr_r[i] == 'Ô' && c == 'O' ) ||
            ( voc_fr_r[i] == 'œ' && c == 'o' ) || ( voc_fr_r[i] == 'Œ' && c == 'O' ) ||

            ( voc_fr_r[i] == 'ù' && c == 'u' ) || ( voc_fr_r[i] == 'Ù' && c == 'U' ) ||
            ( voc_fr_r[i] == 'û' && c == 'u' ) || ( voc_fr_r[i] == 'Û' && c == 'U' ) ||
            ( voc_fr_r[i] == 'ü' && c == 'u' ) || ( voc_fr_r[i] == 'Ü' && c == 'U' )
    {
      // @TODO: add rest: https://altcodesguru.com/french-alt-codes.html
      comp : compare_t
      comp.type = Compare_Type.Wrong_Accent
      comp.char_start = i
      comp.char_end   = i
      append( &comp_arr, comp )

      comp_flag += { Compare_Type.Wrong_Accent }

      voc.error_rate += ERROR_RATE_MILD
    }
    else     
    {
      comp : compare_t
      comp.type = Compare_Type.Wrong
      comp.char_start = i
      comp.char_end   = i
      append( &comp_arr, comp )

      comp_flag += { Compare_Type.Wrong }

      voc.error_rate += ERROR_RATE_STRONG
    }
  }
  // answer is longer than voc.fr
  for i := len(answer_r) - len(voc_fr_r); i > 0; i -= 1
  {
    comp : compare_t
    comp.type = Compare_Type.Wrong
    comp.char_start = len(answer_r) - i
    comp.char_end   = len(answer_r) - i
    append( &comp_arr, comp )

    comp_flag += { Compare_Type.Wrong }

    voc.error_rate += ERROR_RATE_STRONG
  }
  // voc.fr is longer than answer
  for i := len(voc_fr_r) - len(answer_r); i > 0; i -= 1
  {
    comp : compare_t
    comp.type = Compare_Type.Wrong
    comp.char_start = len(answer_r) - i
    comp.char_end   = len(answer_r) - i
    append( &comp_arr, comp )

    comp_flag += { Compare_Type.Wrong }

    voc.error_rate += ERROR_RATE_STRONG
  }

  // fmt.println( comp_flag )
  // fmt.println( comp_arr )

  correct = false
  if      Compare_Type.Wrong not_in comp_flag && 
          Compare_Type.Wrong_Accent not_in comp_flag && 
          Compare_Type.Case_Sensitivity not_in comp_flag && 
          Compare_Type.Incorrect_Length not_in comp_flag 
  { 
    voc.error_rate -= ERROR_RATE_CORRECT
    correct = true
  } 

  return comp_arr, comp_flag, correct
}
