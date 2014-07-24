/* Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *     http: *www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef leela_string_h__
#define leela_string_h__

#include "base.h"

LIBLEELA_HEAD

LIBLEELA_API char *leela_strdup (const char *);

LIBLEELA_API char *leela_strndup (const char *, size_t);

LIBLEELA_API char *leela_join (const char *, ...);

/*! Check if the string is a valid guid.
 *
 * \return 0 Ok;
 * \return x String is not a guid;
 */
LIBLEELA_API int leela_check_guid(const char *);

LIBLEELA_TAIL

#endif
