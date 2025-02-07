#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

# -*- mode: jinja-shell -*-

set -xeuo pipefail
export FEEDSTOCK_ROOT="${FEEDSTOCK_ROOT:-/home/conda/feedstock_root}"
source ${FEEDSTOCK_ROOT}/.scripts/logging_utils.sh


( endgroup "Start Docker" ) 2> /dev/null

( startgroup "Configuring conda" ) 2> /dev/null

export PYTHONUNBUFFERED=1
export RECIPE_ROOT="${RECIPE_ROOT:-/home/conda/recipe_root}"
export CI_SUPPORT="${FEEDSTOCK_ROOT}/.ci_support"
export CONFIG_FILE="${CI_SUPPORT}/${CONFIG}.yaml"

cat >~/.condarc <<CONDARC

conda-build:
  root-dir: ${FEEDSTOCK_ROOT}/build_artifacts
pkgs_dirs:
  - ${FEEDSTOCK_ROOT}/build_artifacts/pkg_cache
  - /opt/conda/pkgs
solver: libmamba

CONDARC
mv /opt/conda/conda-meta/history /opt/conda/conda-meta/history.$(date +%Y-%m-%d-%H-%M-%S)
echo > /opt/conda/conda-meta/history
micromamba install --root-prefix ~/.conda --prefix /opt/conda \
    --yes --override-channels --channel conda-forge --strict-channel-priority \
    pip  python=3.12 conda-build conda-forge-ci-setup=4 "conda-build>=24.1"
export CONDA_LIBMAMBA_SOLVER_NO_CHANNELS_FROM_INSTALLED=1


# set up the condarc
setup_conda_rc "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"

source run_conda_forge_build_setup



# make the build number clobber
make_build_number "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"



( endgroup "Configuring conda" ) 2> /dev/null

if [[ -f "${FEEDSTOCK_ROOT}/LICENSE.txt" ]]; then
  cp "${FEEDSTOCK_ROOT}/LICENSE.txt" "${RECIPE_ROOT}/recipe-scripts-license.txt"
fi

if [[ "${BUILD_WITH_CONDA_DEBUG:-0}" == 1 ]]; then
    if [[ "x${BUILD_OUTPUT_ID:-}" != "x" ]]; then
        EXTRA_CB_OPTIONS="${EXTRA_CB_OPTIONS:-} --output-id ${BUILD_OUTPUT_ID}"
    fi
    conda debug "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml"

    # Drop into an interactive shell
    /bin/bash
else
    conda-build "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        --suppress-variables ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml" \
        --extra-meta flow_run_id="${flow_run_id:-}" remote_url="${remote_url:-}" sha="${sha:-}"
    ( startgroup "Inspecting artifacts" ) 2> /dev/null

    # inspect_artifacts was only added in conda-forge-ci-setup 4.9.4
    command -v inspect_artifacts >/dev/null 2>&1 && inspect_artifacts --recipe-dir "${RECIPE_ROOT}" -m "${CONFIG_FILE}" || echo "inspect_artifacts needs conda-forge-ci-setup >=4.9.4"

    ( endgroup "Inspecting artifacts" ) 2> /dev/null
    ( startgroup "Validating outputs" ) 2> /dev/null

    validate_recipe_outputs "${FEEDSTOCK_NAME}"

    ( endgroup "Validating outputs" ) 2> /dev/null

    ( startgroup "Uploading packages" ) 2> /dev/null

    if [[ "${UPLOAD_PACKAGES}" != "False" ]] && [[ "${IS_PR_BUILD}" == "False" ]]; then
        upload_package --validate --feedstock-name="${FEEDSTOCK_NAME}"  "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"
    fi

    ( endgroup "Uploading packages" ) 2> /dev/null
fi

( startgroup "Final checks" ) 2> /dev/null

touch "${FEEDSTOCK_ROOT}/build_artifacts/conda-forge-build-done-${CONFIG}"