stck segment para 'stack'

stck ends

data segment para 'data'
	; main menu
	curr_option         db ?                                                                             	; current option selected by user
	chosen_option       db ?                                                                             	; chosen option by user
	has_chosen_flag     db 0

	; window
	max_width           dw 320
	max_height          dw 200

	border_x            dw ?                                                                             	; helper var to draw border (x pos of pointer)
	border_y            dw ?                                                                             	; helper var to draw border (y pos of pointer)

	; player
	p1_x                dw ?                                                                             	; x position of player 1
	p1_y                dw ?                                                                             	; y position of player 1

	v1_x                dw ?                                                                             	; x velocity of player 1
	v1_y                dw ?                                                                             	; y velocity of player 1

	p2_x                dw ?                                                                             	; x position of player 2
	p2_y                dw ?                                                                             	; y position of player 2

	v2_x                dw ?                                                                             	; x velocity of player 2
	v2_y                dw ?                                                                             	; y velocity of player 2

	; default values for variables
	curr_option_def     db 0
	chosen_option_def   db 0

	countdown_secs_def  db 3

	default_speed       dw 1

	border_x_def        dw 0
	border_y_def        dw 0

	p1_x_def            dw ?
	p1_y_def            dw ?

	v1_x_def            dw ?
	v1_y_def            dw 0

	p2_x_def            dw ?
	p2_y_def            dw ?

	v2_x_def            dw ?
	v2_y_def            dw 0

	; player scores
	p1_score            db 0                                                                             	; # of wins for player1
	p2_score            db 0                                                                             	; # of wins for player2

	; game state
	prev_time           db 0                                                                             	; to check if time has elapsed
	prev_time_countdown db 0                                                                             	; to check if time has elapsed

	countdown_secs      db ?

	p1_won_flag         db 0
	p2_won_flag         db 0

	is_gameover_flag    db 0                                                                             	; flag to check if game is over
	restart_flag        db 0                                                                             	; flag to check is players want to play again

	; colors (from VGA 256-color palette)
	red                 db 28h
	green               db 0ah
	blue                db 37h
	light_blue          db 4ch
	orange              db 41h

	p1_head_color       db ?
	p2_head_color       db ?

	p1_trail_color      db ?
	p2_trail_color      db ?

	border_color        db ?

	; strings
	welcome_text        db "*****  Welcome to Tron!  *****$"
	play_game_text      db "[ Play Game ]$"
	show_controls_text  db "[ Show Controls ]$"

	pointer_symbol      db ">$"
	empty_space         db " $"

	selection_help_text db "Press [T] to cycle options, [C] to choose selected$"
	player1_controls    db "[W] - Up", 13, 10, "[A] - Left", 13, 10, "[S] - Down", 13, 10, "[D] - Right$"
	player2_controls    db "[I] - Up", 13, 10, "[J] - Left", 13, 10, "[K] - Down", 13, 10, "[L] - Right$"
	back_text           db "Press [B] to go back to main menu$"

	player1_wins_text   db "Player 1 wins!$"
	player2_wins_text   db "Player 2 wins!$"
	tie_text            db "Tie!$"

	p1_score_text       db "Player 1: $"
	p2_score_text       db "Player 2: $"

	again_text          db "Again? (y/n): $"

	gameover_text       db "Thanks for playing!$"
data ends

code segment para 'code'
	                      assume CS:code, DS:data, SS:stck
main proc far
	start:                
	                      push   ds
	                      xor    ax, ax                    	; clean ax

	                      push   ax
	                      mov    ax, data                  	; save data segment on ax
	                      mov    ds, ax                    	; save ax register to ds

	                      pop    ax

	; main menu
	                      call   clear_screen

	                      call   main_menu                 	; display main menu

	game_setup:           
	                      call   clear_screen
						
	; decided to move this out because I didn't want to initialize every var for a countdown
	                      mov    ah, countdown_secs_def
	                      mov    countdown_secs, ah
	                      call   countdown                 	; countdown for players to get ready

	                      call   clear_screen

	                      mov    ah, 00h                   	; set config mode to video mode
	                      mov    al, 13h                   	; video mode 13 -> 320x200 (256 colors)
	                      int    10h

	                      mov    ah, 0bh                   	; set config
	                      mov    bh, 00h                   	; to bg color
	                      int    10h

	                      call   calc_start_pos            	; from video mode resolution

	                      call   reset_game_state

	                      call   set_colors

	                      call   draw_border
	gameloop:             
	; handle input
	                      call   handle_input
                            
	; timing
	                      mov    ah, 2ch                   	; get system time
	                      int    21h                       	; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

	                      cmp    dl, prev_time             	; is curr time = prev time?
	                      je     gameloop                  	; if same, check again

	; time elapsed -> continue
	                      mov    prev_time, dl             	; prev_time = curr_time

	; draw trails
	                      call   draw_player1_trail
	                      call   draw_player2_trail

	; update players
	                      call   move_player1
	                      call   move_player2

	; draw heads
	                      call   draw_player1_head
	                      call   draw_player2_head

	; check if someone won
	                      call   evaluate_game_state

	                      cmp    is_gameover_flag, 1       	; p1 won OR p2 won OR tie
	                      jz     gameover

	                      jmp    gameloop

	gameover:             
	                      call   print_scores
	                      call   ask_restart

	; check if players want to play again
	                      cmp    restart_flag, 1
	                      jz     game_setup

	                      mov    ax, 4c00h
	                      int    21h

	                      ret
main endp

evaluate_option proc near
	                      cmp    chosen_option, 0          	; option 0: play game
	                      je     play_game

	                      cmp    chosen_option, 1          	; option 1: show controls
	                      je     display_controls

	                      ret

	display_controls:     
	                      call   show_player_controls

	                      mov    ah, 00h
	                      int    16h

	                      cmp    al, 'b'                   	; back to main menu?
	                      jz     back_to_menu

	                      jmp    display_controls

	back_to_menu:         
	                      call   clear_screen
	                      mov    has_chosen_flag, 0        	; reset chosen flag
	                      call   main_menu
	                      ret

	play_game:            
	                      ret
evaluate_option endp

show_player_controls proc near
	                      call   clear_screen

	; player1 controls
	                      push   0
	                      push   4
	                      push   offset player1_controls
	                      call   print_string_at

	; player2 controls
	                      push   0
	                      push   10
	                      push   offset player2_controls
	                      call   print_string_at

	; back to main menu text
	                      push   30
	                      push   15
	                      push   offset back_text
	                      call   print_string_at

	                      ret
show_player_controls endp

	; display main menu and polls options, exists when one is chosen
main_menu proc near
	; TODO: calculate relative positions: max_width / 2 - string_len / 2 (for options as well)
	; so that two pointer arrows can be displayed cleanly
	                      push   25
	                      push   4
	                      push   offset welcome_text
	                      call   print_string_at

	                      call   display_options

	                      call   display_options_guide     	; help for the user

	; init defaults
	                      mov    ah, curr_option_def
	                      mov    curr_option, ah
	                      call   move_ptr

	                      mov    ah, chosen_option_def
	                      mov    chosen_option, ah

	; loop until an option is chosen
	poll_options:         
	                      call   cycle_options

	                      cmp    has_chosen_flag, 1        	; have they chosen yet?
	                      jz     exit_main_menu

	                      jmp    poll_options              	; not yet

	exit_main_menu:       
	                      call   evaluate_option
	                      ret
main_menu endp

	; helper proc for main menu to display the user's options
display_options proc near
	; option 1: play game
	                      push   33
	                      push   8
	                      push   offset play_game_text
	                      call   print_string_at

	; option 2: show player controls
	                      push   31
	                      push   10
	                      call   move_cursor

	                      push   offset show_controls_text
	                      call   print_string

	                      ret
display_options endp

display_options_guide proc near
	                      push   15
	                      push   15
	                      push   offset selection_help_text
	                      call   print_string_at

	                      ret
display_options_guide endp

	; prompts the user to choose an option in main menu
cycle_options proc near
	choose_option:        
	                      mov    ah, 00h
	                      int    16h
	                      jmp    handle_choice

	handle_choice:        
	                      cmp    al, 't'
	                      je     change_selected1

	                      cmp    al, 'c'
	                      je     select_option

	                      ret

	change_selected1:     
	                      cmp    curr_option, 0            	; check if current selected option is the first one
	                      je     change_selected2

	                      mov    curr_option, 0            	; make current selected option the first one

	                      call   move_ptr

	                      ret

	change_selected2:     
	                      cmp    curr_option, 1            	; check if current selected option is the second one
	                      je     change_selected1

	                      mov    curr_option, 1            	; make current selected option the second one

	                      call   move_ptr

	                      ret

	select_option:        
	                      mov    has_chosen_flag, 1

	; current selected is the chosen option
	                      mov    ah, curr_option
	                      mov    chosen_option, ah

	                      ret
cycle_options endp

move_ptr proc near
	; check which option is selected
	                      cmp    curr_option, 0
	                      je     move_ptr_up

	                      cmp    curr_option, 1
	                      je     move_ptr_down

	                      ret

	move_ptr_up:          
	; erase previous arrow
	                      push   28
	                      push   10
	                      push   offset empty_space
	                      call   print_string_at
	; print current
	                      push   28
	                      push   8
	                      push   offset pointer_symbol
	                      call   print_string_at

	                      ret

	move_ptr_down:        
	; erase previous arrow
	                      push   28
	                      push   8
	                      push   offset empty_space
	                      call   print_string_at

	                      push   28
	                      push   10
	                      push   offset pointer_symbol     	; print little arrow
	                      call   print_string_at

	                      ret
move_ptr endp

countdown proc near
	second_loop:          
	; handle input
	                      mov    ah, 2ch                   	; get system time
	                      int    21h                       	; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

	                      cmp    dh, prev_time_countdown   	; is curr time = prev time?
	                      je     second_loop               	; if same, check again

	; time elapsed -> continue
	                      mov    prev_time_countdown, dh   	; prev_time = curr_time

	                      push   40
	                      push   12
	                      call   move_cursor

	; print timer
	                      mov    ah, 02h
	                      mov    dl, countdown_secs
	                      add    dl, '0'
	                      int    21h

	                      dec    countdown_secs

	                      cmp    countdown_secs, 0
	                      jl     start_game

	                      jmp    second_loop

	start_game:           
	                      ret
countdown endp

	; procedure to calculate starting position of players
calc_start_pos proc near
	                      mov    bx, max_height
	                      shr    bx, 1                     	; bx = max_height / 2

	                      mov    p1_y_def, bx              	; max_height / 2
	                      mov    p2_y_def, bx              	; max_height / 2

	                      mov    ax, max_width
	                      mov    bx, 6
	                      cwd
	                      div    bx                        	; ax = max_width / 6

	                      mov    p1_x_def, ax              	; max_width / 2 - (2/3) * (max_width / 2) = max_width / 6

	                      mov    bx, 5
	                      mul    bx                        	; ax = 5 * max_width / 6
	                      mov    p2_x_def, ax              	; max_width / 2 + (2/3) * (max_width / 2) = 5 * max_width / 6
	                        
	                      ret
calc_start_pos endp

	; sets border color, players and their trails' colors
set_colors proc near
	                      mov    ah, red
	                      mov    p1_head_color, ah

	                      mov    ah, orange
	                      mov    p1_trail_color, ah
							
	                      mov    ah, blue
	                      mov    p2_head_color, ah

	                      mov    ah, light_blue
	                      mov    p2_trail_color, ah

	                      mov    ah, green
	                      mov    border_color, ah

	                      ret
set_colors endp

reset_game_state proc near
	; reset border 'pointers'
	                      mov    ax, border_x_def
	                      mov    border_x, ax

	                      mov    ax, border_y_def
	                      mov    border_y, ax

	; reset player1 settings
	                      mov    ax, default_speed
	                      mov    v1_x_def, ax

	                      mov    ax, default_speed
	                      neg    ax
	                      mov    v2_x_def, ax

	                      mov    ax, p1_x_def
	                      mov    p1_x, ax

	                      mov    ax, p1_y_def
	                      mov    p1_y, ax

	                      mov    ax, v1_x_def
	                      mov    v1_x, ax

	                      mov    ax, v1_y_def
	                      mov    v1_y, ax

	; reset player2 settings
	                      mov    ax, p2_x_def
	                      mov    p2_x, ax

	                      mov    ax, p2_y_def
	                      mov    p2_y, ax

	                      mov    ax, v2_x_def
	                      mov    v2_x, ax

	                      mov    ax, v2_y_def
	                      mov    v2_y, ax

	; reset game state
	                      mov    p1_won_flag, 0
	                      mov    p2_won_flag, 0

	                      mov    is_gameover_flag, 0
	                      mov    restart_flag, 0

	                      ret
reset_game_state endp

ask_restart proc near
	                      push   33
	                      push   14
	                      push   offset again_text
	                      call   print_string_at

	ask_restart_input:    
	                      push   47
	                      push   14
	                      call   move_cursor

	; get input
	                      mov    ah, 00h
	                      int    16h

	; display keypress
	                      mov    ah, 02h
	                      mov    dl, al
	                      int    21h

	                      cmp    al, 'y'                   	; do the users want to play again?
	                      jz     restart

	                      cmp    al, 'n'
	                      jz     no_restart

	                      jmp    ask_restart_input

	                      ret

	restart:              
	                      mov    restart_flag, 1           	; if so, set flag

	                      ret

	no_restart:           
	                      push   30
	                      push   17
	                      push   offset gameover_text
	                      call   print_string_at

	                      ret
ask_restart endp

print_scores proc near
	; print player1's score
	                      push   30
	                      push   10
	                      call   move_cursor

	                      push   offset p1_score_text
	                      mov    bh, p1_score              	; use upper byte to store input
	                      push   bx
	                      call   print_score

	; print player2's score
	                      push   30
	                      push   11
	                      call   move_cursor

	                      push   offset p2_score_text
	                      mov    bh, p2_score              	; use upper byte to store input
	                      push   bx
	                      call   print_score

	                      ret
print_scores endp

	; prints "arg1: arg2", where arg1 is a string and arg2 is a number
print_score proc near
	                      push   bp
	                      mov    bp, sp

	                      push   [bp + 6]
	                      call   print_string

	                      mov    ax, [bp + 4]
	                      mov    bh, ah                    	; upper byte of contains input
	                      add    bh, '0'                   	; c + 48

	                      mov    ah, 02h                   	; print character
	                      mov    dl, bh
	                      int    21h

	                      pop    bp
	                      ret    4
print_score endp

handle_input proc near
	; get input asynchronously
	                      mov    ah, 01h
	                      int    16h
	                      jz     no_input

	; refresh buffer
	                      mov    ah, 00h
	                      int    16h
	                      jmp    check_input1

	no_input:             
	                      ret

	; check WASD keys
	check_input1:         
	                      cmp    al, 'w'
	                      je     key_is_w

	                      cmp    al, 'a'
	                      je     key_is_a

	                      cmp    al, 's'
	                      je     key_is_s

	                      cmp    al, 'd'
	                      je     key_is_d

	                      jmp    check_input2

	key_is_w:             
	                      cmp    v1_y, 0                   	; W key is only valid if facing left or right
	                      jne    ignore_input1

	                      mov    ax, default_speed
	                      neg    ax
	                      mov    v1_y, ax                  	; face up
	                      mov    v1_x, 0                   	; cancel x vel

	                      ret

	key_is_a:             
	                      cmp    v1_x, 0                   	; A key is only valid if facing up or down
	                      jne    ignore_input1

	                      mov    ax, default_speed
	                      neg    ax
	                      mov    v1_x, ax                  	; face left
	                      mov    v1_y, 0                   	; cancel y vel

	                      ret

	key_is_s:             
	                      cmp    v1_y, 0                   	; S key is only valid if facing left or right
	                      jne    ignore_input1

	                      mov    ax, default_speed
	                      mov    v1_y, ax                  	; face down
	                      mov    v1_x, 0                   	; cancel x vel

	                      ret

	key_is_d:             
	                      cmp    v1_x, 0                   	; D key is only valid if facing up or down
	                      jne    ignore_input1

	                      mov    ax, default_speed
	                      mov    v1_x, ax                  	; face right
	                      mov    v1_y, 0                   	; cancel y vel

	                      ret

	ignore_input1:        
	                      ret

	check_input2:         
	                      cmp    al, 'i'
	                      je     key_is_i

	                      cmp    al, 'j'
	                      je     key_is_j

	                      cmp    al, 'k'
	                      je     key_is_k

	                      cmp    al, 'l'
	                      je     key_is_l

	                      ret

	key_is_i:             
	                      cmp    v2_y, 0                   	; I key is only valid if facing left or right
	                      jne    ignore_input2

	                      mov    ax, default_speed
	                      neg    ax
	                      mov    v2_y, ax                  	; face up
	                      mov    v2_x, 0                   	; cancel x vel

	                      ret

	key_is_j:             
	                      cmp    v2_x, 0                   	; J key is only valid if facing up or down
	                      jne    ignore_input2

	                      mov    ax, default_speed
	                      neg    ax
	                      mov    v2_x, ax                  	; face left
	                      mov    v2_y, 0                   	; cancel y vel

	                      ret

	key_is_k:             
	                      cmp    v2_y, 0                   	; K key is only valid if facing left or right
	                      jne    ignore_input2

	                      mov    ax, default_speed
	                      mov    v2_y, ax                  	; face down
	                      mov    v2_x, 0                   	; cancel x vel

	                      ret

	key_is_l:             
	                      cmp    v2_x, 0                   	; L key is only valid if facing up or down
	                      jne    ignore_input2

	                      mov    ax, default_speed
	                      mov    v2_x, ax                  	; face right
	                      mov    v2_y, 0                   	; cancel y vel

	ignore_input2:        
	                      ret
handle_input endp

move_player1 proc near
	; update player1_x
	                      mov    ax, v1_x
	                      add    p1_x, ax                  	; new_x = old_x + vel_x

	; update player1_y
	                      mov    ax, v1_y
	                      add    p1_y, ax                  	; new_y = old_y + vel_y

	                      call   check_p1_collisions
	                      ret
move_player1 endp

move_player2 proc near
	; update player2_x
	                      mov    ax, v2_x
	                      add    p2_x, ax                  	; new_x = old_x + vel_x

	; update player2_y
	                      mov    ax, v2_y
	                      add    p2_y, ax                  	; new_y = old_y + vel_y

	                      call   check_p2_collisions

	                      ret
move_player2 endp

check_p1_collisions proc near
	; did we hit player2's trail?
	                      push   p1_x
	                      push   p1_y

	                      lea    ax, word ptr p2_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, p2_trail_color
	                      push   ax

	                      call   check_collision

	; are we out of bounds?
	                      push   p1_x
	                      push   p1_y

	                      lea    ax, word ptr p2_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, border_color
	                      push   ax

	                      call   check_collision

	; did we hit our own trail?
	                      push   p1_x
	                      push   p1_y

	                      lea    ax, word ptr p2_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, p1_trail_color
	                      push   ax

	                      call   check_collision

	                      ret
check_p1_collisions endp

check_p2_collisions proc near
	; did we hit player1's trail?
	                      push   p2_x
	                      push   p2_y

	                      lea    ax, word ptr p1_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, p2_trail_color
	                      push   ax

	                      call   check_collision

	; are we out of bounds?
	                      push   p2_x
	                      push   p2_y

	                      lea    ax, word ptr p1_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, border_color
	                      push   ax

	                      call   check_collision

	; did we hit our own trail?
	                      push   p2_x
	                      push   p2_y

	                      lea    ax, word ptr p1_won_flag  	; store address of flag in ax
	                      push   word ptr ax               	; pass by pointer

	                      mov    ah, p1_trail_color
	                      push   ax

	                      call   check_collision

	                      ret
check_p2_collisions endp

	; arg1 = player_x, arg2 = player_y, arg3 = other player's won flag, arg4 = color to check against
check_collision proc near
	                      push   bp
	                      mov    bp, sp

	                      push   [bp + 8]                  	; p_y
	                      push   [bp + 10]                 	; p_x
	                      call   get_pixel_color

	                      mov    bx, [bp + 4]
	                      cmp    al, bh                    	; upper byte contains input
	                      jz     player_collided
							
	                      pop    bp
	                      ret    8

	player_collided:      
	; set other player's won flag
	                      mov    bx, word ptr [[bp + 6]]
	                      mov    byte ptr [bx], 1

	                      pop    bp
	                      ret    8
check_collision endp

evaluate_game_state proc near
	                      mov    is_gameover_flag, 1       	; set it to true originally
						  
	; states: nothing, p1 won, p2 won, tie
	                      mov    ah, p1_won_flag
	                      and    ah, p2_won_flag           	; tie
	                      jnz    tie

	                      cmp    p1_won_flag, 1            	; p1 won
	                      jz     player1_won

	                      cmp    p2_won_flag, 1            	; p2 won
	                      jz     player2_won

	                      mov    is_gameover_flag, 0       	; the game is not over
	                      ret                              	; nothing

	tie:                  
	; display tie text, no scores affected
	                      call   move_cursor_to_center

	                      push   offset tie_text
	                      call   print_string

	                      ret

	player1_won:          
	                      call   move_cursor_to_center

	                      push   offset player1_wins_text
	                      call   print_string

	                      inc    p1_score

	                      ret

	player2_won:          
	                      call   move_cursor_to_center

	                      push   offset player2_wins_text
	                      call   print_string

	                      inc    p2_score

	                      ret
evaluate_game_state endp

	; changes to text mode and move cursor to center of console
move_cursor_to_center proc near
	; change to text mode
	                      mov    ax, 03h
	                      int    10h

	                      push   35
	                      push   8
	                      call   move_cursor

	                      ret
move_cursor_to_center endp

draw_border proc near
	; (0, 0) -> (max_width, 0)
	draw_top:             
	                      call   draw_border_pixel

	                      inc    border_x
	                      mov    ax, border_x
	                      cmp    ax, max_width
	                      jnz    draw_top

	; reset border pointers for next iter
	                      mov    border_x, 0
	                      mov    ax, max_height
	                      dec    ax
	                      mov    border_y, ax

	; (0, max_height) -> (max_width, max_height)
	draw_bottom:          
	                      call   draw_border_pixel

	                      inc    border_x
	                      mov    ax, border_x
	                      cmp    ax, max_width
	                      jnz    draw_bottom

	; reset border pointers for next iter
	                      mov    border_x, 0
	                      mov    border_y, 0

	; (0, 0) -> (0, max_height)
	draw_left:            
	                      call   draw_border_pixel

	                      inc    border_y
	                      mov    ax, border_y
	                      cmp    ax, max_height
	                      jnz    draw_left

	; reset border pointers for next iter
	                      mov    border_y, 0
	                      mov    ax, max_width
	                      dec    ax
	                      mov    border_x, ax

	; (max_width, 0) -> (max_width, max_height)
	draw_right:           
	                      call   draw_border_pixel
							
	                      inc    border_y
	                      mov    ax, border_y
	                      cmp    ax, max_height
	                      jnz    draw_right

	                      ret
draw_border endp

draw_player1_head proc near
	                      push   p1_y
	                      push   p1_x
	                      mov    bh, p1_head_color
	                      push   bx
	                      call   draw_pixel

	                      ret
draw_player1_head endp

draw_player2_head proc near
	                      push   p2_y
	                      push   p2_x
	                      mov    bh, p2_head_color
	                      push   bx
	                      call   draw_pixel

	                      ret
draw_player2_head endp

draw_player1_trail proc near
	                      push   p1_y
	                      push   p1_x
	                      mov    bh, p1_trail_color
	                      push   bx
	                      call   draw_pixel

	                      ret
draw_player1_trail endp

draw_player2_trail proc near
	                      push   p2_y
	                      push   p2_x
	                      mov    bh, p2_trail_color
	                      push   bx
	                      call   draw_pixel

	                      ret
draw_player2_trail endp


	; <------------------------------------ UTIL PROCEDURES ------------------------------------>


	; moves the cursor to (row = arg2, col = arg1)
move_cursor proc near
	                      push   bp
	                      mov    bp, sp

	                      mov    ah, 02h
	                      mov    bh, 0
	                      mov    dh, [bp + 4]
	                      mov    dl, [bp + 6]
	                      int    10h

	                      pop    bp
	                      ret    4
move_cursor endp

	; gets pixel color at (arg1 = row, arg2 = col), puts result in 'al' register
get_pixel_color proc near
	                      push   bp
	                      mov    bp, sp

	                      mov    ah, 0dh                   	; set config to get pixel
	                      mov    bh, 0                     	; page number
	                      mov    cx, [[bp + 4]]            	; col
	                      mov    dx, [[bp + 6]]            	; row
	                      int    10h                       	; al = result

	                      pop    bp
	                      ret    4
get_pixel_color endp

draw_border_pixel proc near
	                      push   border_y
	                      push   border_x
	                      mov    bh, border_color
	                      push   bx
	                      call   draw_pixel

	                      ret
draw_border_pixel endp

	; arg1 = row, arg2 = col, arg3 = color
draw_pixel proc near
	                      push   bp
	                      mov    bp, sp

	                      mov    bx, [bp + 4]              	; color

	                      mov    ah, 0ch                   	; set config to draw pixel
	                      mov    al, bh                    	; color is in upper byte
	                      mov    bh, 00h                   	; set page number
	                      mov    cx, [bp + 6]              	; set col (x)
	                      mov    dx, [bp + 8]              	; set row (y)
	                      int    10h

	                      pop    bp
	                      ret    6
draw_pixel endp

	; prints arg1
print_string proc near
	                      push   bp
	                      mov    bp, sp

	                      mov    ah, 09h
	                      mov    dx, [bp + 4]
	                      int    21h

	                      pop    bp
	                      ret    2
print_string endp

	; arg1 = col, arg2 = row, arg3 = string to print
print_string_at proc near
	                      push   bp
	                      mov    bp, sp

	                      push   [bp + 8]
	                      push   [bp + 6]
	                      call   move_cursor

	                      push   [bp + 4]
	                      call   print_string

	                      pop    bp
	                      ret    6
print_string_at endp

clear_screen proc near
	                      mov    ax, 03h
	                      int    10h

	                      ret
clear_screen endp

code ends

end start

end
