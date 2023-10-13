stck segment para 'stack'

stck ends

data segment para 'data'
    time_aux   db 0      ; to check if time has elapsed

    border_x   dw 00h    ; helper var to draw border (x pos of pointer)
    border_y   dw 00h    ; helper var to draw border (y pos of pointer)

    max_width  dw 640
    max_height dw 480

    p1_x       dw 106    ; x position of player 1 (640 / 2 - 2 * (640 / 2 / 3))
    p1_y       dw 240    ; y position of player 1 (480 / 2)

    v1_x       dw 1      ; x velocity of player 1
    v1_y       dw 0      ; y velocity of player 1

    p2_x       dw 533    ; x position of player 2 (640 / 2 + 2 * (640 / 2 / 3))
    p2_y       dw 240    ; y position of player 2 (480 / 2)

    v2_x       dw -1     ; x velocity of player 2
    v2_y       dw 0      ; y velocity of player 2
data ends

code segment para 'code'
                 assume CS:code, DS:data, SS:stck
main proc far
    start:       
                 push   ds
                 xor    ax, ax                       ; clean ax

                 push   ax
                 mov    ax, data                     ; save data segment on ax
                 mov    ds, ax                       ; save ax register to ds

                 pop    ax
                 pop    ax

                 mov    ah, 00h                      ; set config mode to video mode
                 mov    al, 12h                      ; video mode 12 -> 640x480
                 int    10h

                 mov    ah, 0bh                      ; set config
                 mov    bh, 00h                      ; to bg color
                 int    10h

                 call   draw_border
    gameloop:    
                 mov    ah, 2ch                      ; get system time
                 int    21h                          ; ch = hour, cl = minute, dh = second, dl = 1/100 seconds

                 cmp    dl, time_aux                 ; is curr time = prev time (time_aux)?
                 je     gameloop                     ; if same, check again
    ; if different, continue
                 mov    time_aux, dl                 ; update time

                 call   move_player1
                 call   move_player2

                 call   draw_player1
                 call   draw_player2

                 loop   gameloop

                 ret

main endp

move_player1 proc near
    ; horizontal movement
                 mov    ax, p1_x
                 add    ax, v1_x                     ; new_pos = old_pos + velocity
                 mov    p1_x, ax                     ; update pos
    ; vertical movement
                 mov    ax, p1_y
                 add    ax, v1_y                     ; new_pos = old_pos + velocity
                 mov    p1_y, ax                     ; update pos

                 ret
move_player1 endp

move_player2 proc near
    ; horizontal movement
                 mov    ax, p2_x
                 add    ax, v2_x                     ; new_pos = old_pos + velocity
                 mov    p2_x, ax                     ; update pos
    ; vertical movement
                 mov    ax, p2_y
                 add    ax, v1_y                     ; new_pos = old_pos + velocity
                 mov    p2_y, ax                     ; update pos

                 ret
move_player2 endp

player1_wins proc near
                 ret
player1_wins endp

player2_wins proc near
                 ret
player2_wins endp

    ; procedure to draw border around map
draw_border proc near
    ; (0, 0) -> (max_width, 0)
    draw_top:    
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 04h                      ; red color
                 mov    bh, 00h                      ; set page number
                 mov    cx, border_x                 ; set col (x)
                 mov    dx, border_y                 ; set row (y)
                 int    10h

                 inc    border_x
                 mov    cx, border_x
                 cmp    cx, max_width
                 jnz    draw_top

                 mov    border_x, 0                  ; border_x = 0
                 mov    cx, max_height
                 dec    cx
                 mov    border_y, cx                 ; border_y = max_height
    ; (0, max_height) -> (max_width, max_height)
    draw_bottom: 
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 04h                      ; red color
                 mov    bh, 00h                      ; set page number
                 mov    cx, border_x                 ; set col (x)
                 mov    dx, border_y                 ; set row (y)
                 int    10h

                 inc    border_x
                 mov    cx, border_x
                 cmp    cx, max_width
                 jnz    draw_bottom

                 mov    border_x, 0                  ; border_x = 0
                 mov    border_y, 0                  ; border_y = 0
    ; (0, 0) -> (0, max_height)
    draw_left:   
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 04h                      ; red color
                 mov    bh, 00h                      ; set page number
                 mov    cx, border_x                 ; set col (x)
                 mov    dx, border_y                 ; set row (y)
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
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 04h                      ; red color
                 mov    bh, 00h                      ; set page number
                 mov    cx, border_x                 ; set col (x)
                 mov    dx, border_y                 ; set row (y)
                 int    10h

                 inc    border_y
                 mov    cx, border_y
                 cmp    cx, max_height
                 jnz    draw_right

                 ret
draw_border endp

draw_player1 proc near
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 0ah                      ; green color
                 mov    bh, 00h                      ; set page number
                 mov    cx, p1_x                     ; set col (x)
                 mov    dx, p1_y                     ; set row (y)
                 int    10h

                 ret
draw_player1 endp

draw_player2 proc near
                 mov    ah, 0ch                      ; set config to draw pixel
                 mov    al, 0dh                      ; purple color
                 mov    bh, 00h                      ; set page number
                 mov    cx, p2_x                     ; set col (x)
                 mov    dx, p2_y                     ; set row (y)
                 int    10h

                 ret
draw_player2 endp

code ends
end start
end