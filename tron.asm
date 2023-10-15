stck segment para 'stack'

stck ends

data segment para 'data'
	; game & window-related
	prev_time           db 0                     	; to check if time has elapsed
	prev_time_countdown db 0                     	; to check if time has elapsed

	max_width           dw 320
	max_height          dw 200

	border_x            dw ?                     	; helper var to draw border (x pos of pointer)
	border_y            dw ?                     	; helper var to draw border (y pos of pointer)

	; player-related
	p1_x                dw ?                     	; x position of player 1
	p1_y                dw ?                     	; y position of player 1

	v1_x                dw ?                     	; x velocity of player 1
	v1_y                dw ?                     	; y velocity of player 1

	p2_x                dw ?                     	; x position of player 2
	p2_y                dw ?                     	; y position of player 2

	v2_x                dw ?                     	; x velocity of player 2
	v2_y                dw ?                     	; y velocity of player 2

	; default values for variables
	countdown_secs_def  db 3

	default_speed       dw 1

	border_x_def        dw 00h
	border_y_def        dw 00h

	p1_x_def            dw ?
	p1_y_def            dw ?

	v1_x_def            dw 1
	v1_y_def            dw 0

	p2_x_def            dw ?
	p2_y_def            dw ?

	v2_x_def            dw -1
	v2_y_def            dw 0

	; player scores
	p1_score            db 0                     	; # of wins for player1
	p2_score            db 0                     	; # of wins for player2

	; game state
	countdown_secs      db ?

	p1_won_flag         db 0
	p2_won_flag         db 0

	is_gameover_flag    db 0                     	; flag to check if game is over
	restart_flag        db 0                     	; flag to check is players want to play again

	player1_wins_text   db "Player 1 wins$"
	player2_wins_text   db "Player 2 wins$"
	tie_text            db "Tie$"

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
	                        xor    ax, ax                      	; clean ax

	                        push   ax
	                        mov    ax, data                    	; save data segment on ax
	                        mov    ds, ax                      	; save ax register to ds

	                        pop    ax
	                        pop    ax

	game_setup:             
	                        call   clear_screen

	                        call   reset_vars

	                        call   countdown                   	; countdown for players to get ready

	                        call   clear_screen

	                        xor    bx, bx
	                        mov    ah, 00h                     	; set config mode to video mode
	                        mov    al, 13h                     	; video mode 12 -> 640x480 (16 colors)
	                        int    10h

	                        mov    ah, 0bh                     	; set config
	                        mov    bh, 00h                     	; to bg color
	                        int    10h

	                        call   calc_start_pos              	; from video mode resolution

	                        call   reset_vars
	                        call   draw_border
	gameloop:               
	; handle input
	                        call   handle_input
                            
	; timing
	                        mov    ah, 2ch                     	; get system time
	                        int    21h                         	; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

	                        cmp    dl, prev_time               	; is curr time = prev time?
	                        je     gameloop                    	; if same, check again

	; time elapsed -> continue
	                        mov    prev_time, dl               	; prev_time = curr_time

	; update players
	                        call   move_player1
	                        call   move_player2

	; draw players
	                        call   draw_player1
	                        call   draw_player2

	; check if someone won
	                        call   check_game_over

	                        cmp    is_gameover_flag, 1         	; p1 won OR p2 won OR tie
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

clear_screen proc near
	                        mov    ax, 03h
	                        int    10h

	                        ret
clear_screen endp

countdown proc near
	second_loop:            
	; handle input
	                        mov    ah, 2ch                     	; get system time
	                        int    21h                         	; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

	                        cmp    dh, prev_time_countdown     	; is curr time = prev time?
	                        je     second_loop                 	; if same, check again

	; time elapsed -> continue
	                        mov    prev_time_countdown, dh     	; prev_time = curr_time

	; set cursor to center of screen
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 12
	                        mov    dl, 40
	                        int    10h

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
	                        shr    bx, 1

	                        mov    p1_y_def, bx                	; max_height / 2
	                        mov    p2_y_def, bx                	; max_height / 2

	                        mov    cx, max_width
	                        shr    cx, 1

	                        mov    ax, max_width
	                        mov    bx, 3
	                        cwd
	                        div    bx

	                        push   cx
	                        sub    cx, ax
	                        mov    p1_x_def, cx                	; max_width / 2 - (2/3) * (max_width / 2)

	                        pop    cx
	                        add    cx, ax
	                        mov    p2_x_def, cx                	; max_width / 2 + (2/3) * (max_width / 2)
	                        
	                        ret
calc_start_pos endp

reset_vars proc near
	; reset border 'pointers'
	                        mov    ax, border_x_def
	                        mov    border_x, ax

	                        mov    ax, border_y_def
	                        mov    border_y, ax

	; reset player1 settings
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
	                        mov    ah, countdown_secs_def
	                        mov    countdown_secs, ah

	                        mov    p1_won_flag, 0
	                        mov    p2_won_flag, 0

	                        mov    is_gameover_flag, 0
	                        mov    restart_flag, 0

	                        ret
reset_vars endp

ask_restart proc near
	; move cursor to (33, 14)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 14
	                        mov    dl, 33
	                        int    10h

	; print again? prompt
	                        mov    ah, 09h
	                        mov    dx, offset again_text
	                        int    21h

	ask_restart_input:      
	; move cursor to (47, 14)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 14
	                        mov    dl, 47
	                        int    10h

	; print input
	                        mov    ah, 00h
	                        int    16h

	                        mov    ah, 02h
	                        mov    dl, al
	                        int    21h

	                        cmp    al, 'y'                     	; do the users want to play again?
	                        jz     restart

	                        cmp    al, 'n'
	                        jz     no_restart

	                        jmp    ask_restart_input

	                        ret

	restart:                
	                        mov    restart_flag, 1             	; if so, set flag

	                        ret

	no_restart:             
	; move cursor to (30, 17)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 17
	                        mov    dl, 30
	                        int    10h

	; print game over text
	                        mov    ah, 09h
	                        mov    dx, offset gameover_text
	                        int    21h

	                        ret
ask_restart endp

print_scores proc near
	; move cursor to (30, 10)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 10
	                        mov    dl, 30
	                        int    10h

	; print player1 score text
	                        mov    ah, 09h
	                        mov    dx, offset p1_score_text
	                        int    21h

	; print player1 score
	                        mov    ah, 02h
	                        mov    bh, p1_score
	                        add    bh, '0'
	                        mov    dl, bh
	                        int    21h

	; move cursor to (30, 11)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 11
	                        mov    dl, 30
	                        int    10h

	; print player2 score text
	                        mov    ah, 09h
	                        mov    dx, offset p2_score_text
	                        int    21h

	; print player2 score
	                        mov    ah, 02h
	                        mov    bh, p2_score
	                        add    bh, '0'
	                        mov    dl, bh
	                        int    21h
print_scores endp

handle_input proc near
	; get input asynchronously
	                        mov    ah, 01h
	                        int    16h
	                        jz     no_input

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
	                        cmp    v1_y, 0                     	; W key is only valid if facing left or right
	                        jne    ignore_input1

	                        mov    ax, default_speed
	                        neg    ax
	                        mov    v1_y, ax                    	; face up
	                        mov    v1_x, 0                     	; cancel x vel

	                        ret

	key_is_a:               
	                        cmp    v1_x, 0                     	; A key is only valid if facing up or down
	                        jne    ignore_input1

	                        mov    ax, default_speed
	                        neg    ax
	                        mov    v1_x, ax                    	; face left
	                        mov    v1_y, 0                     	; cancel y vel

	                        ret

	key_is_s:               
	                        cmp    v1_y, 0                     	; S key is only valid if facing left or right
	                        jne    ignore_input1

	                        mov    ax, default_speed
	                        mov    v1_y, ax                    	; face down
	                        mov    v1_x, 0                     	; cancel x vel

	                        ret

	key_is_d:               
	                        cmp    v1_x, 0                     	; D key is only valid if facing up or down
	                        jne    ignore_input1

	                        mov    ax, default_speed
	                        mov    v1_x, ax                    	; face right
	                        mov    v1_y, 0                     	; cancel y vel

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
	                        cmp    v2_y, 0                     	; I key is only valid if facing left or right
	                        jne    ignore_input2

	                        mov    ax, default_speed
	                        neg    ax
	                        mov    v2_y, ax                    	; face up
	                        mov    v2_x, 0                     	; cancel x vel

	                        ret

	key_is_j:               
	                        cmp    v2_x, 0                     	; J key is only valid if facing up or down
	                        jne    ignore_input2

	                        mov    ax, default_speed
	                        neg    ax
	                        mov    v2_x, ax                    	; face left
	                        mov    v2_y, 0                     	; cancel y vel

	                        ret

	key_is_k:               
	                        cmp    v2_y, 0                     	; K key is only valid if facing left or right
	                        jne    ignore_input2

	                        mov    ax, default_speed
	                        mov    v2_y, ax                    	; face down
	                        mov    v2_x, 0                     	; cancel x vel

	                        ret

	key_is_l:               
	                        cmp    v2_x, 0                     	; L key is only valid if facing up or down
	                        jne    ignore_input2

	                        mov    ax, default_speed
	                        mov    v2_x, ax                    	; face right
	                        mov    v2_y, 0                     	; cancel y vel

	ignore_input2:          
	                        ret
handle_input endp

move_player1 proc near
	; update player1_x
	                        mov    ax, v1_x
	                        add    p1_x, ax                    	; new_x = old_x + vel_x

	; update player1_y
	                        mov    ax, v1_y
	                        add    p1_y, ax                    	; new_y = old_y + vel_y

	                        call   check_p1_oob                	; are we out of bounds?
	                        call   check_p1_collision          	; did we hit player2's trail?
	                        call   check_p1_self_collision     	; did we hit our own trail?

	                        ret
move_player1 endp

move_player2 proc near
	; update player2_x
	                        mov    ax, v2_x
	                        add    p2_x, ax                    	; new_x = old_x + vel_x

	; update player2_y
	                        mov    ax, v2_y
	                        add    p2_y, ax                    	; new_y = old_y + vel_y

	                        call   check_p2_oob                	; are we out of bounds?
	                        call   check_p2_collision          	; did we hit player2's trail?
	                        call   check_p2_self_collision     	; did we hit our own trail?

	                        ret
move_player2 endp

check_p1_self_collision proc near
	; check color of pixel at (p1_x, p1_y)
	                        mov    ah, 0dh
	                        mov    bh, 0
	                        mov    cx, [p1_x]
	                        mov    dx, [p1_y]
	                        int    10h                         	; al = color
	                        cmp    al, 0ah                     	; if color = green
	                        jz     player1_self_collided

	                        ret

	player1_self_collided:  
	                        mov    p2_won_flag, 1

	                        ret
check_p1_self_collision endp

check_p2_self_collision proc near
	; check color of pixel at (p1_x, p1_y)
	                        mov    ah, 0dh
	                        mov    bh, 0
	                        mov    cx, [p2_x]
	                        mov    dx, [p2_y]
	                        int    10h                         	; al = color
	                        cmp    al, 0dh                     	; if color = purple
	                        jz     player2_self_collided

	                        ret

	player2_self_collided:  
	                        mov    p1_won_flag, 1

	                        ret
check_p2_self_collision endp

check_p1_collision proc near
	; check color of pixel at (p1_x, p1_y)
	                        mov    ah, 0dh
	                        mov    bh, 0
	                        mov    cx, [p1_x]
	                        mov    dx, [p1_y]
	                        int    10h                         	; al = color
	                        cmp    al, 0dh                     	; if color = purple
	                        jz     player1_collided

	                        ret

	player1_collided:       
	                        mov    p2_won_flag, 1              	; player 2 won

	                        ret
check_p1_collision endp

check_p2_collision proc near
	; check color of pixel at (p2_x, p2_y)
	                        mov    ah, 0dh
	                        mov    bh, 0
	                        mov    cx, [p2_x]
	                        mov    dx, [p2_y]
	                        int    10h                         	; al = color
	                        cmp    al,0ah                      	; if color = red
	                        jz     player2_collided

	                        ret

	player2_collided:       
	                        mov    p1_won_flag, 1              	; player 1 won

	                        ret
check_p2_collision endp

check_p1_oob proc near
	; check player1_x
	                        cmp    p1_x, 00h                   	; if player1_x < 0 -> player2 wins
	                        jl     player1_oob

	                        mov    ax, max_width
	                        cmp    p1_x, ax                    	; if player1_x > max_width -> player2 wins
	                        jg     player1_oob

	; check player1_y
	                        cmp    p1_y, 00h                   	; if player1_y < 0 -> player2 wins
	                        jl     player1_oob

	                        mov    ax, max_height
	                        cmp    p1_y, ax                    	; if player1_y > max_height -> player2 wins
	                        jg     player1_oob

	                        ret                                	; player1 is not out of bounds

	player1_oob:            
	                        mov    p2_won_flag, 1              	; player 2 won

	                        ret
check_p1_oob endp

check_p2_oob proc near
	; check player2_x
	                        cmp    p2_x, 00h                   	; if player2_x < 0 -> player1 wins
	                        jl     player2_oob

	                        mov    ax, max_width
	                        cmp    p2_x, ax                    	; if player2_x > max_width -> player1 wins
	                        jg     player2_oob

	; check player2_y
	                        cmp    p2_y, 00h                   	; if player2_y < 0 -> player1 wins
	                        jl     player2_oob

	                        mov    ax, max_height
	                        cmp    p2_y, ax                    	; if player2_y > max_height -> player1 wins
	                        jg     player2_oob

	                        ret                                	; player2 is not out of bounds

	player2_oob:            
	                        mov    p1_won_flag, 1              	; player 1 won

	                        ret
check_p2_oob endp

check_game_over proc near
	                        mov    is_gameover_flag, 1         	; set it to true originally
	; states: nothing, p1 won, p2 won, tie
	                        mov    ah, p1_won_flag
	                        and    ah, p2_won_flag             	; tie
	                        jnz    tie

	                        cmp    p1_won_flag, 1              	; p1 won
	                        jz     player1_won

	                        cmp    p2_won_flag, 1              	; p2 won
	                        jz     player2_won

	                        mov    is_gameover_flag, 0         	; the game is not over
	                        ret                                	; nothing

	tie:                    
	                        call   change_to_text_mode

	                        mov    ah, 09h
	                        mov    dx, offset tie_text
	                        int    21h

	                        ret

	player1_won:            
	                        call   change_to_text_mode

	                        mov    ah, 09h
	                        mov    dx, offset player1_wins_text
	                        int    21h

	                        inc    p1_score

	                        ret

	player2_won:            
	                        call   change_to_text_mode

	                        mov    ah, 09h
	                        mov    dx, offset player2_wins_text
	                        int    21h

	                        inc    p2_score

	                        ret
check_game_over endp

change_to_text_mode proc near
	; change back to text mode
	                        mov    ax, 03h
	                        int    10h

	; move cursor to (35, 8)
	                        mov    ah, 02h
	                        mov    bh, 0
	                        mov    dh, 8
	                        mov    dl, 35
	                        int    10h

	                        ret
change_to_text_mode endp

draw_border proc near
	; (0, 0) -> (max_width, 0)
	draw_top:               
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 04h                     	; red color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, border_x                	; set col (x)
	                        mov    dx, border_y                	; set row (y)
	                        int    10h

	                        inc    border_x
	                        mov    cx, border_x
	                        cmp    cx, max_width
	                        jnz    draw_top

	                        mov    border_x, 0                 	; border_x = 0
	                        mov    cx, max_height
	                        dec    cx
	                        mov    border_y, cx                	; border_y = max_height

	; (0, max_height) -> (max_width, max_height)
	draw_bottom:            
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 04h                     	; red color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, border_x                	; set col (x)
	                        mov    dx, border_y                	; set row (y)
	                        int    10h

	                        inc    border_x
	                        mov    cx, border_x
	                        cmp    cx, max_width
	                        jnz    draw_bottom

	                        mov    border_x, 0                 	; border_x = 0
	                        mov    border_y, 0                 	; border_y = 0

	; (0, 0) -> (0, max_height)
	draw_left:              
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 04h                     	; red color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, border_x                	; set col (x)
	                        mov    dx, border_y                	; set row (y)
	                        int    10h

	                        inc    border_y
	                        mov    cx, border_y
	                        cmp    cx, max_height
	                        jnz    draw_left

	                        mov    border_y, 0
	                        mov    cx, max_width
	                        dec    cx
	                        mov    border_x, cx

	; (max_width, 0) -> (max_width, max_height)
	draw_right:             
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 04h                     	; red color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, border_x                	; set col (x)
	                        mov    dx, border_y                	; set row (y)
	                        int    10h

	                        inc    border_y
	                        mov    cx, border_y
	                        cmp    cx, max_height
	                        jnz    draw_right

	                        ret
draw_border endp

draw_player1 proc near
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 0ah                     	; green color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, p1_x                    	; set col (x)
	                        mov    dx, p1_y                    	; set row (y)
	                        int    10h

	                        ret
draw_player1 endp

draw_player2 proc near
	                        mov    ah, 0ch                     	; set config to draw pixel
	                        mov    al, 0dh                     	; purple color
	                        mov    bh, 00h                     	; set page number
	                        mov    cx, p2_x                    	; set col (x)
	                        mov    dx, p2_y                    	; set row (y)
	                        int    10h

	                        ret
draw_player2 endp

code ends

end start

end