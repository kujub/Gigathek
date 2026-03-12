#!/bin/bash

set -e -u

cd "${0%/*}" # code/

zip_dir=$( realpath ../zip-matrix )

mkdir -p "${zip_dir}"

tmp_dir=""
trap_exit() { if [[ -d "${tmp_dir}" ]]; then rm -rf "${tmp_dir}"; fi; }
trap trap_exit EXIT

tmp_dir=$(mktemp --tmpdir -d "${0##*/}".XXXX)

re_id="([[:alnum:]._]+)"
re_vers="([[:alnum:]._+-]+)"
re_prov="([[:alnum:]._+,-]+)"

for dir in *
do
  [[ -d ${dir} ]] || continue

  file=${dir}/addon.xml
  if ! [[ -f ${file} ]]
  then
    echo "Skipping non addon dir: '${dir}'"
  elif [[ ${dir} == "Gigathek" ]]
  then
    echo "Skipping addon dir: '${dir}'"
  else
    while read line
    do
      b="[[:blank:]]*"
      if [[ ${line} =~ ^${b}'<addon id="'${re_id}'" name="'([^'"']*)'" version="'${re_vers}'" provider-name="'${re_prov}'">'${b}$ ]]
      then
        id=${BASH_REMATCH[1]} version=${BASH_REMATCH[3]//,/+} provider=${BASH_REMATCH[4]//,/+}
        (
          if [[ ${dir} != "${id}" ]]
          then
            cp -a -T "${dir}" "${tmp_dir}"/"${id}"
            cd "${tmp_dir}"
            dir=${id}
          fi
          zip=${zip_dir}/${id}-${version}-${provider}.zip
          [[ -f ${zip} ]] && mv -T "${zip}" "${zip}".old
          zip --quiet --recurse-paths "${zip}" "${dir}"
          echo "Created: '${zip}'"
          rm -f "${zip}".old
        )
        continue 2
      fi
    done <"${file}"
    echo "ERROR: Bad addon.xml: '${file}'"
  fi
done
