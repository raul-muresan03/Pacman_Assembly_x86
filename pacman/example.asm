.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "PAC-MAN",0
area_width EQU 344
area_height EQU 410
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

pacman_size equ 24

pacman_x dd 150
pacman_y dd 200

pacman_x_init equ 150
pacman_y_init equ 200

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include pacman.inc
include alb.inc
include zid.inc
include red_ghost.inc
include blue_ghost.inc
include yellow_ghost.inc
include points.inc
include cherry.inc

matrice DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0      ;0 - zid, 1 - puncte, 2 - fantoma, 3 - pacman
		DB 0, 2, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0
		DB 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0
		DB 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0
		DB 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0
		DB 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
		DB 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0
		DB 0, 1, 0, 0, 1, 0, 3, 0, 1, 0, 1, 1, 1, 0
		DB 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0
		DB 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0
		DB 0, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 0
		DB 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0
		DB 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0
		DB 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0
		DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		
; pacman_x1 dd 7  ;pozitia lui pacman in matricea de coliziuni
; pacman_y1 dd 6

pacman_pos dd 104
pacman_pos_init equ 104
row_len equ 14

vieti dd 3

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	

	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;-------------------------------------------------------------------------------------------------------

make_pacman proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	lea esi, pacman

draw_pacman:
	mov ebx, pacman_size
	mul ebx
	mov ebx, pacman_size
	mul ebx
	shl eax, 2
	add esi, eax
	mov ecx, pacman_size
bucla_pacman_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, pacman_size
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, pacman_size
bucla_pacman_coloane:
pacman_pixel_next:
	push dword ptr [esi]
	pop dword ptr [edi]
	add esi, 4
	add edi, 4
	loop bucla_pacman_coloane
	pop ecx
	loop bucla_pacman_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_pacman endp

; un macro ca sa apelam mai usor desenarea simbolului
make_pacman_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_pacman
	add esp, 16
endm

;-------------------------------------------------------------------------------------------------------

;macro uri pentru desenarea liniilor orizontale si verticale
line_horizontal macro x, y, len, color
local bucla_line
	mov eax, y ;eax = y
	mov ebx, area_width
	mul ebx ;eax = y * area_width
	add eax, x  ;eax = y * area_width + x
	shl eax, 2 ;eax = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

line_vertical macro x, y, len, color
local bucla_line
	mov eax, y ;eax = y
	mov ebx, area_width
	mul ebx ;eax = y * area_width
	add eax, x  ;eax = y * area_width + x
	shl eax, 2 ;eax = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4 * area_width
	loop bucla_line
endm

square_macro macro x, y, len, color
    line_horizontal x, y, len, color 						;linia de sus
    line_horizontal x, y + len - 1, len, color 				;jos
    line_vertical x, y + 1, len - 2, color 					;stanga
    line_vertical x + len - 1, y + 1, len - 2, color 		;dreapta
endm

;-------------------------------------------------------------------------------------------------------

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha

draw_points:

	;punctele
	make_pacman_macro 6, area, 150, 152
	
	make_pacman_macro 6, area, 30, 80
	make_pacman_macro 6, area, 30, 104
	make_pacman_macro 6, area, 30, 128
	make_pacman_macro 6, area, 30, 152
	make_pacman_macro 6, area, 30, 176
	make_pacman_macro 6, area, 30, 200
	make_pacman_macro 6, area, 30, 224
	make_pacman_macro 6, area, 30, 248
	make_pacman_macro 6, area, 30, 272
	make_pacman_macro 6, area, 30, 296
	make_pacman_macro 6, area, 30, 320
	make_pacman_macro 6, area, 30, 344
	
	make_pacman_macro 6, area, 54, 344
	make_pacman_macro 6, area, 78, 344
	make_pacman_macro 6, area, 102, 344
	make_pacman_macro 6, area, 126, 344
	make_pacman_macro 6, area, 150, 344
	make_pacman_macro 6, area, 174, 344
	make_pacman_macro 6, area, 198, 344
	make_pacman_macro 6, area, 222, 344
	make_pacman_macro 6, area, 246, 344
	
	make_pacman_macro 6, area, 294, 320
	make_pacman_macro 6, area, 294, 296
	make_pacman_macro 6, area, 294, 272
	make_pacman_macro 6, area, 294, 248
	make_pacman_macro 6, area, 294, 224
	make_pacman_macro 6, area, 294, 200
	make_pacman_macro 6, area, 294, 176
	make_pacman_macro 6, area, 294, 152
	make_pacman_macro 6, area, 294, 128
	make_pacman_macro 6, area, 294, 104
	make_pacman_macro 6, area, 294, 80
	
	make_pacman_macro 6, area, 270, 56
	make_pacman_macro 6, area, 246, 56
	make_pacman_macro 6, area, 222, 56
	make_pacman_macro 6, area, 198, 56
	make_pacman_macro 6, area, 174, 56
	make_pacman_macro 6, area, 150, 56
	make_pacman_macro 6, area, 126, 56
	make_pacman_macro 6, area, 102, 56
	make_pacman_macro 6, area, 78, 56
	
	make_pacman_macro 6, area, 78, 80
	make_pacman_macro 6, area, 102, 80
	make_pacman_macro 6, area, 150, 80
	make_pacman_macro 6, area, 174, 80
	make_pacman_macro 6, area, 174, 104
	make_pacman_macro 6, area, 174, 128
	make_pacman_macro 6, area, 174, 152
	make_pacman_macro 6, area, 198, 152
	make_pacman_macro 6, area, 222, 152
	make_pacman_macro 6, area, 246, 152
	make_pacman_macro 6, area, 270, 152
	make_pacman_macro 6, area, 78, 104
	make_pacman_macro 6, area, 126, 152
	make_pacman_macro 6, area, 102, 152
	make_pacman_macro 6, area, 78, 152
	make_pacman_macro 6, area, 54, 152
	make_pacman_macro 6, area, 78, 176
	make_pacman_macro 6, area, 102, 176
	make_pacman_macro 6, area, 102, 200
	make_pacman_macro 6, area, 102, 224
	make_pacman_macro 6, area, 102, 248
	make_pacman_macro 6, area, 102, 272
	make_pacman_macro 6, area, 78, 296
	make_pacman_macro 6, area, 102, 296
	make_pacman_macro 6, area, 126, 296
	make_pacman_macro 6, area, 150, 296
	make_pacman_macro 6, area, 174, 296
	make_pacman_macro 6, area, 198, 296
	make_pacman_macro 6, area, 222, 296
	make_pacman_macro 6, area, 246, 296
	
	make_pacman_macro 6, area, 54, 248
	make_pacman_macro 6, area, 78, 248
	make_pacman_macro 6, area, 126, 248
	make_pacman_macro 6, area, 150, 248
	make_pacman_macro 6, area, 174, 248
	make_pacman_macro 6, area, 198, 248
	make_pacman_macro 6, area, 222, 248
	make_pacman_macro 6, area, 246, 248
	
	make_pacman_macro 6, area, 54, 272
	make_pacman_macro 6, area, 78, 272
	make_pacman_macro 6, area, 126, 272
	make_pacman_macro 6, area, 174, 272
	make_pacman_macro 6, area, 198, 272
	make_pacman_macro 6, area, 222, 272
	make_pacman_macro 6, area, 246, 272
	make_pacman_macro 6, area, 270, 272
	
	make_pacman_macro 6, area, 78, 320
	make_pacman_macro 6, area, 198, 320
	make_pacman_macro 6, area, 222, 320
	
	make_pacman_macro 6, area, 78, 224
	make_pacman_macro 6, area, 198, 224
	make_pacman_macro 6, area, 198, 200
	make_pacman_macro 6, area, 198, 176
	make_pacman_macro 6, area, 270, 176
	make_pacman_macro 6, area, 198, 152
	
	make_pacman_macro 6, area, 270, 200
	make_pacman_macro 6, area, 246, 200
	
	make_pacman_macro 6, area, 222, 104
	make_pacman_macro 6, area, 222, 128
	make_pacman_macro 6, area, 270, 128
	make_pacman_macro 6, area, 246, 104
	make_pacman_macro 6, area, 270, 104
	
	make_pacman_macro 6, area, 126, 128
	make_pacman_macro 6, area, 150, 128
	
	make_pacman_macro 6, area, 150, 176
	
	;cirese
	make_pacman_macro 7, area, 294, 344
	make_pacman_macro 7, area, 30, 344
	
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz final_draw
	cmp eax, 3
	jz move_pacman
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere

move_pacman:
	mov eax, [ebp+arg2]
	
	cmp eax, 57h ;W
	jz move_up
	cmp eax, 41h ;A
	jz move_left	
	cmp eax, 53h ;S
	jz move_down	
	cmp eax, 44h ;D
	jz move_right	
	
	jmp final_draw

move_up:
	make_pacman_macro 1, area, pacman_x_init, pacman_y_init

	mov eax, pacman_pos
	sub eax, row_len        ;eax contine noua pozitie dupa ce apasam W 
	cmp matrice[eax], 0  	;zid
	jz wall_cell
	cmp matrice[eax], 2
	jz ghost_cell
	
	mov ebx, pacman_pos
	mov matrice[ebx], 1
	mov matrice[eax], 3
	mov pacman_pos, eax
	
	sub pacman_y, 24
	make_pacman_macro 0, area, pacman_x, pacman_y

wall_cell:
	jmp final_draw
	
ghost_cell:
	dec vieti
	cmp vieti, 0
	jz game_over
	cmp vieti, 2
	jz vieti2
	cmp vieti, 1
	jz vieti1
	
	; mov ebx, pacman_pos
	; mov matrice[ebx], 1
	; mov ebx, pacman_pos_init    ;punem pozitia lui pacman sa fie cea initiala
	; mov pacman_pos, ebx
	; mov matrice[ebx], 3
	
	; mov eax, pacman_x_init
	; mov pacman_x, eax
	
	; mov ebx, pacman_y_init
	; mov pacman_y, ebx
	; make_pacman_macro 0, area, pacman_x_init, pacman_y_init
	
	; jmp final_draw
	
vieti2:
	make_pacman_macro 0, area, 104, 6
	make_pacman_macro 0, area, 130, 6
	make_pacman_macro 1, area, 154, 6
	
	jmp logic
	
vieti1:
	make_pacman_macro 0, area, 104, 6
	make_pacman_macro 1, area, 130, 6
	make_pacman_macro 1, area, 154, 6
	
	jmp logic
	
game_over:
	make_text_macro 'G', area, 206, 6
	make_text_macro 'A', area, 216, 6
	make_text_macro 'M', area, 226, 6
	make_text_macro 'E', area, 236, 6
	make_text_macro ' ', area, 246, 6
	make_text_macro 'O', area, 256, 6
	make_text_macro 'V', area, 266, 6
	make_text_macro 'E', area, 276, 6
	make_text_macro 'R', area, 286, 6
	
	make_pacman_macro 1, area, 104, 6
	make_pacman_macro 1, area, 130, 6
	make_pacman_macro 1, area, 154, 6
	
	jmp final_draw
	
logic:
	mov ebx, pacman_pos
	mov matrice[ebx], 1
	mov ebx, pacman_pos_init    ;punem pozitia lui pacman sa fie cea initiala
	mov pacman_pos, ebx
	mov matrice[ebx], 3
	
	mov eax, pacman_x_init
	mov pacman_x, eax
	
	mov ebx, pacman_y_init
	mov pacman_y, ebx
	make_pacman_macro 0, area, pacman_x_init, pacman_y_init
	
	jmp final_draw
	
move_left:
	make_pacman_macro 1, area, pacman_x_init, pacman_y_init

	mov eax, pacman_pos
	sub eax, 1       		;eax contine noua pozitie dupa ce apasam A
	cmp matrice[eax], 0  	;zid
	jz wall_cell1
	cmp matrice[eax], 2
	jz ghost_cell
	
	mov ebx, pacman_pos
	mov matrice[ebx], 1
	mov matrice[eax], 3
	mov pacman_pos, eax
	
	sub pacman_x, 24
	make_pacman_macro 0, area, pacman_x, pacman_y

wall_cell1:
	jmp final_draw

move_down:
	make_pacman_macro 1, area, pacman_x_init, pacman_y_init

	mov eax, pacman_pos
	add eax, row_len        ;eax contine noua pozitie dupa ce apasam S 
	cmp matrice[eax], 0  	;zid
	jz wall_cell2
	cmp matrice[eax], 2
	jz ghost_cell
	
	mov ebx, pacman_pos
	mov matrice[ebx], 1
	mov matrice[eax], 3
	mov pacman_pos, eax
	
	add pacman_y, 24
	make_pacman_macro 0, area, pacman_x, pacman_y

wall_cell2:
	jmp final_draw

move_right:
	make_pacman_macro 1, area, pacman_x_init, pacman_y_init

	mov eax, pacman_pos
	add eax, 1       		;eax contine noua pozitie dupa ce apasam D 
	cmp matrice[eax], 0  	;zid
	jz wall_cell3
	cmp matrice[eax], 2
	jz ghost_cell
	
	mov ebx, pacman_pos
	mov matrice[ebx], 1
	mov matrice[eax], 3
	mov pacman_pos, eax
	
	add pacman_x, 24
	make_pacman_macro 0, area, pacman_x, pacman_y

wall_cell3:
	jmp final_draw

evt_timer:
	make_pacman_macro 0, area, pacman_x, pacman_y
	
	inc counter
	
afisare_litere:
	
	;fantomele
	make_pacman_macro 3, area, 30, 56
	make_pacman_macro 4, area, 294, 56
	make_pacman_macro 5, area, 150, 272
	
	
	;desenam zidurile
	make_pacman_macro 2, area, 6, 32
	make_pacman_macro 2, area, 6, 56
	make_pacman_macro 2, area, 6, 80
	make_pacman_macro 2, area, 6, 104
	make_pacman_macro 2, area, 6, 128
	make_pacman_macro 2, area, 6, 152
	make_pacman_macro 2, area, 6, 176
	make_pacman_macro 2, area, 6, 200
	make_pacman_macro 2, area, 6, 224
	make_pacman_macro 2, area, 6, 248
	make_pacman_macro 2, area, 6, 272
	make_pacman_macro 2, area, 6, 296
	make_pacman_macro 2, area, 6, 320
	make_pacman_macro 2, area, 6, 344
	make_pacman_macro 2, area, 6, 368
	
	make_pacman_macro 2, area, 6, 368
	make_pacman_macro 2, area, 30, 368
	make_pacman_macro 2, area, 54, 368
	make_pacman_macro 2, area, 78, 368
	make_pacman_macro 2, area, 102, 368
	make_pacman_macro 2, area, 126, 368
	make_pacman_macro 2, area, 150, 368
	make_pacman_macro 2, area, 174, 368
	make_pacman_macro 2, area, 198, 368
	make_pacman_macro 2, area, 222, 368
	make_pacman_macro 2, area, 246, 368
	make_pacman_macro 2, area, 270, 368
	make_pacman_macro 2, area, 294, 368
	make_pacman_macro 2, area, 318, 368
	
	make_pacman_macro 2, area, 318, 32
	make_pacman_macro 2, area, 318, 56
	make_pacman_macro 2, area, 318, 80
	make_pacman_macro 2, area, 318, 104
	make_pacman_macro 2, area, 318, 128
	make_pacman_macro 2, area, 318, 152
	make_pacman_macro 2, area, 318, 176
	make_pacman_macro 2, area, 318, 200
	make_pacman_macro 2, area, 318, 224
	make_pacman_macro 2, area, 318, 248
	make_pacman_macro 2, area, 318, 272
	make_pacman_macro 2, area, 318, 296
	make_pacman_macro 2, area, 318, 320
	make_pacman_macro 2, area, 318, 344	
	
	make_pacman_macro 2, area, 30, 32
	make_pacman_macro 2, area, 54, 32
	make_pacman_macro 2, area, 78, 32
	make_pacman_macro 2, area, 102, 32
	make_pacman_macro 2, area, 126, 32
	make_pacman_macro 2, area, 150, 32
	make_pacman_macro 2, area, 174, 32
	make_pacman_macro 2, area, 198, 32
	make_pacman_macro 2, area, 222, 32
	make_pacman_macro 2, area, 246, 32
	make_pacman_macro 2, area, 270, 32
	make_pacman_macro 2, area, 294, 32
	
	;interior
	make_pacman_macro 2, area, 54, 56
	make_pacman_macro 2, area, 54, 80
	make_pacman_macro 2, area, 54, 104
	make_pacman_macro 2, area, 54, 128
	make_pacman_macro 2, area, 78, 128
	make_pacman_macro 2, area, 102, 128
	make_pacman_macro 2, area, 102, 104
	make_pacman_macro 2, area, 126, 104
	make_pacman_macro 2, area, 126, 80
	make_pacman_macro 2, area, 150, 104
	make_pacman_macro 2, area, 198, 104
	make_pacman_macro 2, area, 198, 80
	make_pacman_macro 2, area, 222, 80
	make_pacman_macro 2, area, 246, 80
	make_pacman_macro 2, area, 270, 80
	make_pacman_macro 2, area, 198, 128
	make_pacman_macro 2, area, 246, 128
	
	make_pacman_macro 2, area, 54, 176
	make_pacman_macro 2, area, 54, 200
	make_pacman_macro 2, area, 78, 200
	make_pacman_macro 2, area, 54, 224
	
	make_pacman_macro 2, area, 126, 224
	make_pacman_macro 2, area, 150, 224
	make_pacman_macro 2, area, 174, 224
	make_pacman_macro 2, area, 126, 200
	make_pacman_macro 2, area, 174, 200
	make_pacman_macro 2, area, 222, 200
	make_pacman_macro 2, area, 126, 176
	make_pacman_macro 2, area, 174, 176
	make_pacman_macro 2, area, 222, 176
	make_pacman_macro 2, area, 246, 176
	
	make_pacman_macro 2, area, 222, 224
	make_pacman_macro 2, area, 246, 224
	make_pacman_macro 2, area, 270, 224
	make_pacman_macro 2, area, 270, 248
	
	make_pacman_macro 2, area, 54, 296
	make_pacman_macro 2, area, 54, 320
	make_pacman_macro 2, area, 102, 320
	make_pacman_macro 2, area, 126, 320
	make_pacman_macro 2, area, 150, 320
	make_pacman_macro 2, area, 174, 320
	make_pacman_macro 2, area, 246, 320
	make_pacman_macro 2, area, 270, 320
	make_pacman_macro 2, area, 270, 296
	make_pacman_macro 2, area, 270, 344
	
	
	;fiecare celula a jocului e un patrat
	square_macro 6, 32, 24, 00000FFh
	square_macro 6, 56, 24, 00000FFh
	square_macro 6, 80, 24, 00000FFh
	square_macro 6, 104, 24, 00000FFh
	square_macro 6, 128, 24, 00000FFh
	square_macro 6, 152, 24, 00000FFh
	square_macro 6, 176, 24, 00000FFh
	square_macro 6, 200, 24, 00000FFh
	square_macro 6, 224, 24, 00000FFh
	square_macro 6, 248, 24, 00000FFh
	square_macro 6, 272, 24, 00000FFh
	square_macro 6, 296, 24, 00000FFh
	square_macro 6, 320, 24, 00000FFh
	square_macro 6, 344, 24, 00000FFh
	square_macro 6, 368, 24, 00000FFh
	
	square_macro 30, 32, 24, 00000FFh
	square_macro 30, 56, 24, 00000FFh
	square_macro 30, 80, 24, 00000FFh
	square_macro 30, 104, 24, 00000FFh
	square_macro 30, 128, 24, 00000FFh
	square_macro 30, 152, 24, 00000FFh
	square_macro 30, 176, 24, 00000FFh
	square_macro 30, 200, 24, 00000FFh
	square_macro 30, 224, 24, 00000FFh
	square_macro 30, 248, 24, 00000FFh
	square_macro 30, 272, 24, 00000FFh
	square_macro 30, 296, 24, 00000FFh
	square_macro 30, 320, 24, 00000FFh
	square_macro 30, 344, 24, 00000FFh
	square_macro 30, 368, 24, 00000FFh
	
	square_macro 54, 32, 24, 00000FFh
	square_macro 54, 56, 24, 00000FFh
	square_macro 54, 80, 24, 00000FFh
	square_macro 54, 104, 24, 00000FFh
	square_macro 54, 128, 24, 00000FFh
	square_macro 54, 152, 24, 00000FFh
	square_macro 54, 176, 24, 00000FFh
	square_macro 54, 200, 24, 00000FFh
	square_macro 54, 224, 24, 00000FFh
	square_macro 54, 248, 24, 00000FFh
	square_macro 54, 272, 24, 00000FFh
	square_macro 54, 296, 24, 00000FFh
	square_macro 54, 320, 24, 00000FFh
	square_macro 54, 344, 24, 00000FFh
	square_macro 54, 368, 24, 00000FFh
	
	square_macro 78, 32, 24, 00000FFh
	square_macro 78, 56, 24, 00000FFh
	square_macro 78, 80, 24, 00000FFh
	square_macro 78, 104, 24, 00000FFh
	square_macro 78, 128, 24, 00000FFh
	square_macro 78, 152, 24, 00000FFh
	square_macro 78, 176, 24, 00000FFh
	square_macro 78, 200, 24, 00000FFh
	square_macro 78, 224, 24, 00000FFh
	square_macro 78, 248, 24, 00000FFh
	square_macro 78, 272, 24, 00000FFh
	square_macro 78, 296, 24, 00000FFh
	square_macro 78, 320, 24, 00000FFh
	square_macro 78, 344, 24, 00000FFh
	square_macro 78, 368, 24, 00000FFh
	
	square_macro 102, 32, 24, 00000FFh
	square_macro 102, 56, 24, 00000FFh
	square_macro 102, 80, 24, 00000FFh
	square_macro 102, 104, 24, 00000FFh
	square_macro 102, 128, 24, 00000FFh
	square_macro 102, 152, 24, 00000FFh
	square_macro 102, 176, 24, 00000FFh
	square_macro 102, 200, 24, 00000FFh
	square_macro 102, 224, 24, 00000FFh
	square_macro 102, 248, 24, 00000FFh
	square_macro 102, 272, 24, 00000FFh
	square_macro 102, 296, 24, 00000FFh
	square_macro 102, 320, 24, 00000FFh
	square_macro 102, 344, 24, 00000FFh
	square_macro 102, 368, 24, 00000FFh
	
	square_macro 126, 32, 24, 00000FFh
	square_macro 126, 56, 24, 00000FFh
	square_macro 126, 80, 24, 00000FFh
	square_macro 126, 104, 24, 00000FFh
	square_macro 126, 128, 24, 00000FFh
	square_macro 126, 152, 24, 00000FFh
	square_macro 126, 176, 24, 00000FFh
	square_macro 126, 200, 24, 00000FFh
	square_macro 126, 224, 24, 00000FFh
	square_macro 126, 248, 24, 00000FFh
	square_macro 126, 272, 24, 00000FFh
	square_macro 126, 296, 24, 00000FFh
	square_macro 126, 320, 24, 00000FFh
	square_macro 126, 344, 24, 00000FFh
	square_macro 126, 368, 24, 00000FFh
	
	square_macro 150, 32, 24, 00000FFh
	square_macro 150, 56, 24, 00000FFh
	square_macro 150, 80, 24, 00000FFh
	square_macro 150, 104, 24, 00000FFh
	square_macro 150, 128, 24, 00000FFh
	square_macro 150, 152, 24, 00000FFh
	square_macro 150, 176, 24, 00000FFh
	square_macro 150, 200, 24, 00000FFh
	square_macro 150, 224, 24, 00000FFh
	square_macro 150, 248, 24, 00000FFh
	square_macro 150, 272, 24, 00000FFh
	square_macro 150, 296, 24, 00000FFh
	square_macro 150, 320, 24, 00000FFh
	square_macro 150, 344, 24, 00000FFh
	square_macro 150, 368, 24, 00000FFh
	
	square_macro 174, 32, 24, 00000FFh
	square_macro 174, 56, 24, 00000FFh
	square_macro 174, 80, 24, 00000FFh
	square_macro 174, 104, 24, 00000FFh
	square_macro 174, 128, 24, 00000FFh
	square_macro 174, 152, 24, 00000FFh
	square_macro 174, 176, 24, 00000FFh
	square_macro 174, 200, 24, 00000FFh
	square_macro 174, 224, 24, 00000FFh
	square_macro 174, 248, 24, 00000FFh
	square_macro 174, 272, 24, 00000FFh
	square_macro 174, 296, 24, 00000FFh
	square_macro 174, 320, 24, 00000FFh
	square_macro 174, 344, 24, 00000FFh
	square_macro 174, 368, 24, 00000FFh
	
	square_macro 198, 32, 24, 00000FFh
	square_macro 198, 56, 24, 00000FFh
	square_macro 198, 80, 24, 00000FFh
	square_macro 198, 104, 24, 00000FFh
	square_macro 198, 128, 24, 00000FFh
	square_macro 198, 152, 24, 00000FFh
	square_macro 198, 176, 24, 00000FFh
	square_macro 198, 200, 24, 00000FFh
	square_macro 198, 224, 24, 00000FFh
	square_macro 198, 248, 24, 00000FFh
	square_macro 198, 272, 24, 00000FFh
	square_macro 198, 296, 24, 00000FFh
	square_macro 198, 320, 24, 00000FFh
	square_macro 198, 344, 24, 00000FFh
	square_macro 198, 368, 24, 00000FFh
	
	square_macro 222, 32, 24, 00000FFh
	square_macro 222, 56, 24, 00000FFh
	square_macro 222, 80, 24, 00000FFh
	square_macro 222, 104, 24, 00000FFh
	square_macro 222, 128, 24, 00000FFh
	square_macro 222, 152, 24, 00000FFh
	square_macro 222, 176, 24, 00000FFh
	square_macro 222, 200, 24, 00000FFh
	square_macro 222, 224, 24, 00000FFh
	square_macro 222, 248, 24, 00000FFh
	square_macro 222, 272, 24, 00000FFh
	square_macro 222, 296, 24, 00000FFh
	square_macro 222, 320, 24, 00000FFh
	square_macro 222, 344, 24, 00000FFh
	square_macro 222, 368, 24, 00000FFh
	
	square_macro 246, 32, 24, 00000FFh
	square_macro 246, 56, 24, 00000FFh
	square_macro 246, 80, 24, 00000FFh
	square_macro 246, 104, 24, 00000FFh
	square_macro 246, 128, 24, 00000FFh
	square_macro 246, 152, 24, 00000FFh
	square_macro 246, 176, 24, 00000FFh
	square_macro 246, 200, 24, 00000FFh
	square_macro 246, 224, 24, 00000FFh
	square_macro 246, 248, 24, 00000FFh
	square_macro 246, 272, 24, 00000FFh
	square_macro 246, 296, 24, 00000FFh
	square_macro 246, 320, 24, 00000FFh
	square_macro 246, 344, 24, 00000FFh
	square_macro 246, 368, 24, 00000FFh
	
	square_macro 270, 32, 24, 00000FFh
	square_macro 270, 56, 24, 00000FFh
	square_macro 270, 80, 24, 00000FFh
	square_macro 270, 104, 24, 00000FFh
	square_macro 270, 128, 24, 00000FFh
	square_macro 270, 152, 24, 00000FFh
	square_macro 270, 176, 24, 00000FFh
	square_macro 270, 200, 24, 00000FFh
	square_macro 270, 224, 24, 00000FFh
	square_macro 270, 248, 24, 00000FFh
	square_macro 270, 272, 24, 00000FFh
	square_macro 270, 296, 24, 00000FFh
	square_macro 270, 320, 24, 00000FFh
	square_macro 270, 344, 24, 00000FFh
	square_macro 270, 368, 24, 00000FFh
	
	square_macro 294, 32, 24, 00000FFh
	square_macro 294, 56, 24, 00000FFh
	square_macro 294, 80, 24, 00000FFh
	square_macro 294, 104, 24, 00000FFh
	square_macro 294, 128, 24, 00000FFh
	square_macro 294, 152, 24, 00000FFh
	square_macro 294, 176, 24, 00000FFh
	square_macro 294, 200, 24, 00000FFh
	square_macro 294, 224, 24, 00000FFh
	square_macro 294, 248, 24, 00000FFh
	square_macro 294, 272, 24, 00000FFh
	square_macro 294, 296, 24, 00000FFh
	square_macro 294, 320, 24, 00000FFh
	square_macro 294, 344, 24, 00000FFh
	square_macro 294, 368, 24, 00000FFh
	
	square_macro 318, 32, 24, 00000FFh
	square_macro 318, 56, 24, 00000FFh
	square_macro 318, 80, 24, 00000FFh
	square_macro 318, 104, 24, 00000FFh
	square_macro 318, 128, 24, 00000FFh
	square_macro 318, 152, 24, 00000FFh
	square_macro 318, 176, 24, 00000FFh
	square_macro 318, 200, 24, 00000FFh
	square_macro 318, 224, 24, 00000FFh
	square_macro 318, 248, 24, 00000FFh
	square_macro 318, 272, 24, 00000FFh
	square_macro 318, 296, 24, 00000FFh
	square_macro 318, 320, 24, 00000FFh
	square_macro 318, 344, 24, 00000FFh
	square_macro 318, 368, 24, 00000FFh
	
	;scor
	make_text_macro 'S', area, 6, 6
	make_text_macro 'C', area, 16, 6
	make_text_macro 'O', area, 26, 6
	make_text_macro 'R', area, 36, 6
	

final_draw:
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
