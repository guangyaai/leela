#!/bin/sh

leela_root=${leela_root:-$(pwd)}
bin_sed=${bin_sed:-/bin/sed}

major=$1
minor=$2
patch=$3

. src/scripts/read-version.sh

print_usage () {
  echo "[usage] version.sh MAJOR MINOR PATCH"
}

update_version () {
  local name
  name=$(basename $1)
  echo " updating file: $1"
  [ "$name" = project.clj     ] && $bin_sed -i '/^(defproject blackbox/c\(defproject blackbox "'$version'"' $1
  [ "$name" = warpdrive.cabal ] && $bin_sed -i -r 's/^version:( *).*/version:\1'$version'/' $1
  [ "$name" = setup.py        ] && $bin_sed -i -r 's/^( *)version( *)= *".*"(.*)/\1version\2= "'$version'"\3/' $1
}

write_c_hversion () {
  echo " creating file: $1"
  mkdir -p $(dirname $1)
  cat <<EOF >"$1"
/* Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]
 */

#ifndef leela_version__
#define leela_version__

extern int LEELA_MAJOR;
extern int LEELA_MINOR;
extern int LEELA_PATCH;

extern const char * LEELA_VERSION;

#endif

EOF
}

write_c_cversion () {
  echo " creating file: $1"
  cat <<EOF >"$1"
/* Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]
 */

#include "version.h"

int LEELA_MAJOR = $major;
int LEELA_MINOR = $minor;
int LEELA_PATCH = $patch;

const char * LEELA_VERSION = "$major.$minor.$patch";

EOF
}

write_hsversion () {
  echo " creating file: $1"
  mkdir -p $(dirname $1)
  cat <<EOF >"$1"
-- Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]

module Leela.Version where

major :: Int
major   = $major

minor :: Int
minor   = $minor

patch :: Int
patch   = $patch

version :: String
version = "$major.$minor.$patch"

EOF
}

write_pyversion () {
  echo " creating file: $1"
  cat <<EOF >$1
#!/usr/bin/python

# Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]

major   = $major
minor   = $minor
patch   = $patch
version = "$major.minor.patch"
EOF
}

write_clversion () {
  echo " creating file: $1"
  mkdir -p $(dirname $1)
  cat <<EOF >"$1"
;; Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;
;; [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]

(ns leela.version)

(def major $major)

(def minor $minor)

(def patch $patch)

(def version "$major.$minor.$patch")

EOF
}

write_rbversion () {
  echo " creating file: $1"
  mkdir -p $(dirname $1)
  cat <<EOF >$1
# Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]

module Leela

  module Version
    MAJOR   = $major
    MINOR   = $minor
    PATCH   = $patch
    VERSION = "$major.$minor.$patch"
  end

end

EOF
}

write_rbmetriksversion () {
  echo " creating file: $1"
  mkdir -p $(dirname $1)
  cat <<EOF >$1
# Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# [DO NOT EDIT, AUTOMATICALLY GENERATED BY ($0 $@)]

module Metriks
  module Reporter
    module Leela
     
      module Version
        MAJOR   = $major
        MINOR   = $minor
        PATCH   = $patch
        VERSION = "$major.$minor.$patch"
      end
     
    end
  end
end

EOF
}

unset major minor patch
component=.leela-lib
read_version
check_environ
write_c_hversion $leela_root/src/c/src/leela/version.h
write_c_cversion $leela_root/src/c/src/leela/version.c
update_version $leela_root/src/python/setup.py

unset major minor patch
component=.leela-warpdrive
read_version
check_environ
write_hsversion $leela_root/src/warpdrive/src/Leela/Version.hs
update_version $leela_root/src/warpdrive/warpdrive.cabal

unset major minor patch
component=.leela-blackbox
read_version
check_environ
write_clversion $leela_root/src/blackbox/src/leela/version.clj
update_version $leela_root/src/blackbox/project.clj

unset major minor patch
component=.leela-ruby
read_version
check_environ
write_rbversion $leela_root/src/ruby/leela_ruby/lib/leela_ruby/version.rb

unset major minor patch
component=.leela-metriks
read_version
check_environ
write_rbmetriksversion $leela_root/src/metriks/lib/metriks/reporter/leela//version.rb
