#!/bin/bash
set -eEuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

source bash-buddy/lib/trap_error_info.sh
source bash-buddy/lib/common_utils.sh

################################################################################
# prepare
################################################################################

readonly default_build_jdk_version=11

# shellcheck disable=SC2034
readonly PREPARE_JDKS_INSTALL_BY_SDKMAN=(
    8
    "$default_build_jdk_version"
    17
)

source bash-buddy/lib/prepare_jdks.sh

source bash-buddy/lib/java_build_utils.sh

# shellcheck disable=SC2034
JVB_MVN_OPTS=(
    "${JVB_DEFAULT_MVN_OPTS[@]}"
    -DperformRelease -P'!gen-sign'
)

################################################################################
# ci build logic
################################################################################

cd ..

########################################
# default jdk 11, do build and test
########################################

prepare_jdks::switch_to_jdk "$default_build_jdk_version"

cu::head_line_echo "build and test with Java: $JAVA_HOME"

jvb::mvn_cmd clean install
(
    cd auto-pipeline-examples
    cu::log_then_run ./gradlew clean test
)

########################################
# test multi-version java
########################################
for jdk in "${PREPARE_JDKS_INSTALL_BY_SDKMAN[@]}"; do
    # already tested by above `mvn install`
    [ "$default_build_jdk_version" = "$jdk" ] && continue

    prepare_jdks::switch_to_jdk "$jdk"

    cu::head_line_echo "test with Java: $JAVA_HOME"

    # just test without build
    jvb::mvn_cmd surefire:test
    (
        cd auto-pipeline-examples
        cu::log_then_run ./gradlew clean test
    )
done
