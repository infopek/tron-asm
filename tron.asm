stck segment para 'stack'

stck ends

data segment para 'data'
    time_aux          db 0                   ; to check if time has elapsed

    max_width         dw 640
    max_height        dw 480

    border_x          dw 00h                 ; helper var to draw border (x pos of pointer)
    border_y          dw 00h                 ; helper var to draw border (y pos of pointer)

    p1_x              dw 106                 ; x position of player 1 (640 / 2 - 2 * (640 / 2 / 3))
    p1_y              dw 240                 ; y position of player 1 (480 / 2)

    v1_x              dw 1                   ; x velocity of player 1
    v1_y              dw 0                   ; y velocity of player 1

    p2_x              dw 533                 ; x position of player 2 (640 / 2 + 2 * (640 / 2 / 3))
    p2_y              dw 240                 ; y position of player 2 (480 / 2)

    v2_x              dw -1                  ; x velocity of player 2
    v2_y              dw 0                   ; y velocity of player 2

    default_speed     dw 1

    p1_key_pressed    db 0                   ; store ASCII code of key pressed by player 1
    p2_key_pressed    db 0                   ; store ASCII code of key pressed by player 2

    player1_wins_text db "Player 1 wins$"
    player2_wins_text db "Player 2 wins$"
data ends

code segment para 'code'
                            assume CS:code, DS:data, SS:stck
main proc far
    start:                  
                            push   ds
                            xor    ax, ax                          ; clean ax

                            push   ax
                            mov    ax, data                        ; save data segment on ax
                            mov    ds, ax                          ; save ax register to ds

                            pop    ax
                            pop    ax

                            mov    ah, 00h                         ; set config mode to video mode
                            mov    al, 12h                         ; video mode 12 -> 640x480
                            int    10h

                            mov    ah, 0bh                         ; set config
                            mov    bh, 00h                         ; to bg color
                            int    10h

                            call   draw_border
    gameloop:               
    ; handle input
                            call   handle_input
    ; timing
                            mov    ah, 2ch                         ; get system time
                            int    21h                             ; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

                            cmp    dl, time_aux                    ; is curr time = prev time (time_aux)?
                            je     gameloop                        ; if same, check again

    ; time elapsed -> continue
                            mov    time_aux, dl                    ; update time

    ; update players
                            call   move_player1
                            call   move_player2

    ; draw players
                            call   draw_player1
                            call   draw_player2

                            jmp    gameloop

                            ret
main endp

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
                            cmp    v1_y, 0                         ; W key is only valid if facing left or right
                            jne    ignore_input1

                            mov    ax, default_speed
                            neg    ax
                            mov    v1_y, ax                        ; face up
                            mov    v1_x, 0                         ; cancel x vel

                            ret

    key_is_a:               
                            cmp    v1_x, 0                         ; A key is only valid if facing up or down
                            jne    ignore_input1

                            mov    ax, default_speed
                            neg    ax
                            mov    v1_x, ax                        ; face left
                            mov    v1_y, 0                         ; cancel y vel

                            ret

    key_is_s:               
                            cmp    v1_y, 0                         ; S key is only valid if facing left or right
                            jne    ignore_input1

                            mov    ax, default_speed
                            mov    v1_y, ax                        ; face down
                            mov    v1_x, 0                         ; cancel x vel

                            ret

    key_is_d:               
                            cmp    v1_x, 0                         ; D key is only valid if facing up or down
                            jne    ignore_input1

                            mov    ax, default_speed
                            mov    v1_x, ax                        ; face right
                            mov    v1_y, 0                         ; cancel y vel

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
                            cmp    v2_y, 0                         ; I key is only valid if facing left or right
                            jne    ignore_input2

                            mov    ax, default_speed
                            neg    ax
                            mov    v2_y, ax                        ; face up
                            mov    v2_x, 0                         ; cancel x vel

                            ret

    key_is_j:               
                            cmp    v2_x, 0                         ; J key is only valid if facing up or down
                            jne    ignore_input2

                            mov    ax, default_speed
                            neg    ax
                            mov    v2_x, ax                        ; face left
                            mov    v2_y, 0                         ; cancel y vel

                            ret

    key_is_k:               
                            cmp    v2_y, 0                         ; K key is only valid if facing left or right
                            jne    ignore_input2

                            mov    ax, default_speed
                            mov    v2_y, ax                        ; face down
                            mov    v2_x, 0                         ; cancel x vel

                            ret

    key_is_l:               
                            cmp    v2_x, 0                         ; L key is only valid if facing up or down
                            jne    ignore_input2

                            mov    ax, default_speed
                            mov    v2_x, ax                        ; face right
                            mov    v2_y, 0                         ; cancel y vel

                            ret

    ignore_input2:          
                            ret
handle_input endp

move_player1 proc near
    ; update player1_x
                            mov    ax, v1_x
                            add    p1_x, ax                        ; new_x = old_x + vel_x

    ; update player1_y
                            mov    ax, v1_y
                            add    p1_y, ax                        ; new_y = old_y + vel_y

                            call   check_p1_oob                    ; are we out of bounds?
                            call   check_p1_collision              ; did we hit player2's trail?
                            call   check_p1_self_collision         ; did we hit our own trail?

                            ret
move_player1 endp

move_player2 proc near
    ; update player2_x
                            mov    ax, v2_x
                            add    p2_x, ax                        ; new_x = old_x + vel_x

    ; update player2_y
                            mov    ax, v2_y
                            add    p2_y, ax                        ; new_y = old_y + vel_y

                            call   check_p2_oob                    ; are we out of bounds?
                            call   check_p2_collision              ; did we hit player2's trail?
                            call   check_p2_self_collision         ; did we hit our own trail?

                            ret
move_player2 endp

check_p1_self_collision proc near
    ; check color of pixel at (p1_x, p1_y)
                            mov    ah, 0dh
                            mov    bh, 0
                            mov    cx, [p1_x]
                            mov    dx, [p1_y]
                            int    10h                             ; al = color
                            cmp    al, 0ah                         ; if color = green
                            jz     player1_self_collided

                            ret

    player1_self_collided:  
                            call   player2_won

                            ret
check_p1_self_collision endp

check_p2_self_collision proc near
    ; check color of pixel at (p1_x, p1_y)
                            mov    ah, 0dh
                            mov    bh, 0
                            mov    cx, [p2_x]
                            mov    dx, [p2_y]
                            int    10h                             ; al = color
                            cmp    al, 0dh                         ; if color = purple
                            jz     player2_self_collided

                            ret

    player2_self_collided:  
                            call   player1_won

                            ret
check_p2_self_collision endp

check_p1_collision proc near
    ; check color of pixel at (p1_x, p1_y)
                            mov    ah, 0dh
                            mov    bh, 0
                            mov    cx, [p1_x]
                            mov    dx, [p1_y]
                            int    10h                             ; al = color
                            cmp    al, 0dh                         ; if color = purple
                            jz     player1_collided

                            ret

    player1_collided:       
                            call   player2_won

                            ret
check_p1_collision endp

check_p2_collision proc near
    ; check color of pixel at (p2_x, p2_y)
                            mov    ah, 0dh
                            mov    bh, 0
                            mov    cx, [p2_x]
                            mov    dx, [p2_y]
                            int    10h                             ; al = color
                            cmp    al,0ah                          ; if color = red
                            jz     player2_collided

                            ret

    player2_collided:       
                            call   player1_won

                            ret
check_p2_collision endp

check_p1_oob proc near
    ; check player1_x
                            cmp    p1_x, 00h                       ; if player1_x < 0 -> player2 wins
                            jl     player1_oob

                            mov    ax, max_width
                            cmp    p1_x, ax                        ; if player1_x > max_width -> player2 wins
                            jg     player1_oob

    ; check player1_y
                            cmp    p1_y, 00h                       ; if player1_y < 0 -> player2 wins
                            jl     player1_oob

                            mov    ax, max_height
                            cmp    p1_y, ax                        ; if player1_y > max_height -> player2 wins
                            jg     player1_oob

                            ret                                    ; player1 is not out of bounds

    player1_oob:            
                            call   player2_won

                            ret
check_p1_oob endp

check_p2_oob proc near
    ; check player2_x
                            cmp    p2_x, 00h                       ; if player2_x < 0 -> player1 wins
                            jl     player2_oob

                            mov    ax, max_width
                            cmp    p2_x, ax                        ; if player2_x > max_width -> player1 wins
                            jg     player2_oob

    ; check player2_y
                            cmp    p2_y, 00h                       ; if player2_y < 0 -> player1 wins
                            jl     player2_oob

                            mov    ax, max_height
                            cmp    p2_y, ax                        ; if player2_y > max_height -> player1 wins
                            jg     player2_oob

                            ret                                    ; player2 is not out of bounds

    player2_oob:            
                            call   player1_won

                            ret
check_p2_oob endp

player1_won proc near
                            call   game_over

    ; print player1 win text
                            mov    ah, 09h
                            mov    dx, offset player1_wins_text
                            int    21h

                            ret
player1_won endp

player2_won proc near
                            call   game_over

    ; print player2 win text
                            mov    ah, 09h
                            mov    dx, offset player2_wins_text
                            int    21h

                            ret
player2_won endp

game_over proc near
    ; change back to text mode
                            mov    ax, 03h
                            int    10h

    ; move cursor to center of the screen
                            mov    ah, 02h
                            mov    bh, 0
                            mov    dh, 12
                            mov    dl, 35
                            int    10h

                            ret
game_over endp

draw_border proc near
    ; (0, 0) -> (max_width, 0)
    draw_top:               
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 04h                         ; red color
                            mov    bh, 00h                         ; set page number
                            mov    cx, border_x                    ; set col (x)
                            mov    dx, border_y                    ; set row (y)
                            int    10h

                            inc    border_x
                            mov    cx, border_x
                            cmp    cx, max_width
                            jnz    draw_top

                            mov    border_x, 0                     ; border_x = 0
                            mov    cx, max_height
                            dec    cx
                            mov    border_y, cx                    ; border_y = max_height

    ; (0, max_height) -> (max_width, max_height)
    draw_bottom:            
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 04h                         ; red color
                            mov    bh, 00h                         ; set page number
                            mov    cx, border_x                    ; set col (x)
                            mov    dx, border_y                    ; set row (y)
                            int    10h

                            inc    border_x
                            mov    cx, border_x
                            cmp    cx, max_width
                            jnz    draw_bottom

                            mov    border_x, 0                     ; border_x = 0
                            mov    border_y, 0                     ; border_y = 0

    ; (0, 0) -> (0, max_height)
    draw_left:              
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 04h                         ; red color
                            mov    bh, 00h                         ; set page number
                            mov    cx, border_x                    ; set col (x)
                            mov    dx, border_y                    ; set row (y)
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
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 04h                         ; red color
                            mov    bh, 00h                         ; set page number
                            mov    cx, border_x                    ; set col (x)
                            mov    dx, border_y                    ; set row (y)
                            int    10h

                            inc    border_y
                            mov    cx, border_y
                            cmp    cx, max_height
                            jnz    draw_right

                            ret
draw_border endp

draw_player1 proc near
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 0ah                         ; green color
                            mov    bh, 00h                         ; set page number
                            mov    cx, p1_x                        ; set col (x)
                            mov    dx, p1_y                        ; set row (y)
                            int    10h

                            ret
draw_player1 endp

draw_player2 proc near
                            mov    ah, 0ch                         ; set config to draw pixel
                            mov    al, 0dh                         ; purple color
                            mov    bh, 00h                         ; set page number
                            mov    cx, p2_x                        ; set col (x)
                            mov    dx, p2_y                        ; set row (y)
                            int    10h

                            ret
draw_player2 endp

code ends

end start

end