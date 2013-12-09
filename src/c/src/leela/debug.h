// All rights reserved.
//  
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//  
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//  
// * Redistributions in binary form must reproduce the above copyright notice, this
//   list of conditions and the following disclaimer in the documentation and/or
//   other materials provided with the distribution.
//  
// * Neither the name of the {organization} nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.
//  
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef __leela_debug_h__
#define __leela_debug_h__

#define LEELA_DEBUG0(fmt) leela_debug("%s:%d: " #fmt , __FILE__, __LINE__)

#define LEELA_DEBUG(fmt, ...) leela_debug("%s:%d: " #fmt , __FILE__, __LINE__, __VA_ARGS__)

#ifdef LEELA_TRACING
# define LEELA_TRACE0(fmt) leela_debug("[TRACE] %s:%d: " #fmt, __FILE__, __LINE__)
# define LEELA_TRACE(fmt, ...) leela_debug("[TRACE] %s:%d: " #fmt, __FILE__, __LINE__, __VA_ARGS__)
#else
# define LEELA_TRACE0(fmt)
# define LEELA_TRACE(fmt, ...)
#endif

void leela_debug(const char *fmt, ...);

#endif
