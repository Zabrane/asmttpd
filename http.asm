;asmttpd - Web server for Linux written in amd64 assembly.
;Copyright (C) 2014  Nat <nemasu@gmail.com>
;
;This file is part of asmttpd.
;
;asmttpd is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 2 of the License, or
;(at your option) any later version.
;
;asmttpd is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with asmttpd.  If not, see <http://www.gnu.org/licenses/>.

;This writes the text after "Content-Type: " at rsi
detect_content_type: ;rdi - pointer to buffer that contains request, ret - rax: type flag
	stackpush

	mov rsi, qword extension_htm
	call string_ends_with
	mov r10, CONTENT_TYPE_HTML
	cmp rax, 1
	je detect_content_type_ret

	mov rsi, qword extension_html
	call string_ends_with
	mov r10, CONTENT_TYPE_HTML 
	cmp rax, 1
	je detect_content_type_ret
	
	mov rsi, qword extension_css
	call string_ends_with
	mov r10, CONTENT_TYPE_CSS
	cmp rax, 1
	je detect_content_type_ret
	
	mov rsi, qword extension_javascript
	call string_ends_with
	mov r10, CONTENT_TYPE_JAVASCRIPT
	cmp rax, 1
	je detect_content_type_ret

	mov rsi, qword extension_xhtml
	call string_ends_with
	mov r10, CONTENT_TYPE_XHTML
	cmp rax, 1
	je detect_content_type_ret

	mov rsi, qword extension_xml
	call string_ends_with
	mov r10, CONTENT_TYPE_XML
	cmp rax, 1
	je detect_content_type_ret

	mov rsi, qword extension_gif
	call string_ends_with
	mov r10, CONTENT_TYPE_GIF
	cmp rax, 1
	je detect_content_type_ret
	
	mov rsi, qword extension_png
	call string_ends_with
	mov r10, CONTENT_TYPE_PNG
	cmp rax, 1
	je detect_content_type_ret
	
	mov rsi, qword extension_jpeg
	call string_ends_with
	mov r10, CONTENT_TYPE_JPEG
	cmp rax, 1
	je detect_content_type_ret
	
	mov rsi, qword extension_jpg
	call string_ends_with
	mov r10, CONTENT_TYPE_JPEG
	cmp rax, 1
	je detect_content_type_ret

	mov r10, CONTENT_TYPE_OCTET_STREAM ; default to octet-stream
	detect_content_type_ret:
	mov rax, r10
	stackpop
	ret

add_content_type_header: ;rdi - pointer to buffer, rsi - type
	stackpush

	mov r10, rsi

	mov rsi, qword content_type
	call string_concat

	cmp r10, CONTENT_TYPE_HTML
	je add_response_html
	cmp r10, CONTENT_TYPE_OCTET_STREAM
	je add_response_octet_stream
	cmp r10, CONTENT_TYPE_CSS
	je add_response_css
	cmp r10, CONTENT_TYPE_JAVASCRIPT
	je add_response_javascript
	cmp r10, CONTENT_TYPE_XHTML
	je add_response_xhtml
	cmp r10, CONTENT_TYPE_XML
	je add_response_xml
	cmp r10, CONTENT_TYPE_GIF
	je add_response_gif
	cmp r10, CONTENT_TYPE_PNG
	je add_response_png
	cmp r10, CONTENT_TYPE_JPEG
	je add_response_jpeg
	
	jmp add_response_octet_stream

	add_response_html:
	mov rsi, qword content_type_html
	call string_concat
	jmp add_response_cont
	
	add_response_octet_stream:
	mov rsi, qword content_type_octet_stream
	call string_concat
	jmp add_response_cont
	
	add_response_css:
	mov rsi, qword content_type_css
	call string_concat
	jmp add_response_cont

	add_response_javascript:
	mov rsi, qword content_type_javascript
	call string_concat
	jmp add_response_cont

	add_response_xhtml:
	mov rsi, qword content_type_xhtml
	call string_concat
	jmp add_response_cont

	add_response_xml:
	mov rsi, qword content_type_xml
	call string_concat
	jmp add_response_cont

	add_response_gif:
	mov rsi, qword content_type_gif
	call string_concat
	jmp add_response_cont

	add_response_png:
	mov rsi, qword content_type_png
	call string_concat
	jmp add_response_cont

	add_response_jpeg:
	mov rsi, qword content_type_jpeg
	call string_concat

	add_response_cont:
	stackpop
	ret

create_httpError_response: ;rdi - pointer, rsi - error code: 400, 416, 413
	stackpush

	cmp rsi, 416
	je create_httpError_response_416
	cmp rsi, 413
	je create_httpError_response_413
	
	;garbage/default is 400
	mov rsi, qword http_400
	mov rdx, http_400_len
	call string_copy
	jmp create_httpError_response_cont

	create_httpError_response_416:
	mov rsi, qword http_416
	mov rdx, http_416_len
	call string_copy
	jmp create_httpError_response_cont

	create_httpError_response_413:
	mov rsi, qword http_413
	mov rdx, http_413_len
	call string_copy
	jmp create_httpError_response_cont
	
	create_httpError_response_cont:
	mov rsi, qword server_header
	call string_concat

	mov rsi, qword connection_header
	call string_concat

	mov rsi, qword crlfx2
    call string_concat

	call get_string_length

	stackpop
	ret
	

create_http206_response: ;rdi - pointer, rsi - from, rdx - to, r10 - total r9 - type
					     ; looks like Content-Length: `rdx subtract rsi add 1`
						 ;            Content-Range: bytes rsi-rdx/r10
	stackpush

	push rsi
	push rdx

	mov rsi, qword http_206 ; copy first one
	mov rdx, http_206_len
	call string_copy

	mov rsi, qword server_header
	call string_concat

	mov rsi, qword connection_header
	call string_concat

	mov rsi, qword range_header
	call string_concat
	
	mov rsi, r9
	call add_content_type_header

	mov rsi, qword content_length
	call string_concat
	
	pop rdx
	pop rsi
	push rsi

	mov r8, rdx
	sub r8, rsi
	inc r8 ; inc cause 'to' is zero based
	mov rsi, r8

	call string_concat_int
	
	mov rsi, qword crlf
	call string_concat
	
	mov rsi, qword content_range
	call string_concat
	
	pop rsi
	call string_concat_int

	mov rsi, qword char_hyphen
	call string_concat

	mov rsi, rdx
	call string_concat_int

	mov rsi, qword char_slash
	call string_concat

	mov rsi, r10 ; val 
	call string_concat_int
	
	mov rsi, qword crlfx2
	call string_concat

	call get_string_length
	jmp create_http206_response_ret

	create_http206_response_fail:
	mov rax, 0
	stackpop
	ret

	create_http206_response_ret:
	stackpop
	ret

create_http200_response: ;rdi - pointer to buffer, rsi - type, rdx - length
	stackpush

	push rdx ; save length

	mov r10, rsi ;type
	
	mov rsi, qword http_200  ;First one we copy
	mov rdx, http_200_len
	call string_copy

	mov rsi, qword server_header
	call string_concat

	;mov rsi, connection_header
	;call string_concat

	mov rsi, qword range_header
	call string_concat
	
	mov rsi, qword content_length
	call string_concat

	pop rsi ; length
	call string_concat_int
	
	mov rsi, qword crlf
	call string_concat

	mov rsi, r10
	call add_content_type_header
	
	mov rsi, qword crlf
	call string_concat

	call get_string_length

	stackpop
	ret

create_http404_response: ;rdi - pointer to buffer
	stackpush

	mov rsi, qword http_404  ;First one we copy
	mov rdx, http_404_len
	call string_copy

	mov rsi, qword server_header
	call string_concat

	mov rsi, qword connection_header
	call string_concat

	mov rsi, qword crlf
	call string_concat

	mov rsi, qword http_404_text
	call string_concat

	mov rsi, qword crlf
	call string_concat

	call get_string_length

	stackpop
	ret
