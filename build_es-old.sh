#!/bin/bash
# ©  Copyright IBM Corporation 2020.
# LICENSE: Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
#
# Instructions:
# Download build script: wget https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/Elasticsearch/7.9.1/build_elasticsearch.sh
# Execute build script: bash build_elasticsearch.sh    (provide -h for help)
#
set -e -o pipefail

PACKAGE_NAME="elasticsearch"
PACKAGE_VERSION="7.9.1"
CURDIR="$(pwd)"
PATCH_URL="https://raw.githubusercontent.com/Prabhav-Thali/logs/master"
ES_REPO_URL="https://github.com/elastic/elasticsearch"

LOG_FILE="$CURDIR/logs/${PACKAGE_NAME}-${PACKAGE_VERSION}-$(date +"%F-%T").log"
NON_ROOT_USER="$(whoami)"
FORCE="false"

trap cleanup 0 1 2 ERR

# Check if directory exists
if [ ! -d "$CURDIR/logs/" ]; then
        mkdir -p "$CURDIR/logs/"
fi

if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
fi

function prepare() {

        if command -v "sudo" >/dev/null; then
                printf -- 'Sudo : Yes\n' >>"$LOG_FILE"
        else
                printf -- 'Sudo : No \n' >>"$LOG_FILE"
                printf -- 'You can install sudo from repository using apt, yum or zypper based on your distro. \n'
                exit 1
        fi

        if [[ "$FORCE" == "true" ]]; then
                printf -- 'Force attribute provided hence continuing with install without confirmation message\n' |& tee -a "$LOG_FILE"
        else
                printf -- 'As part of the installation, dependencies would be installed/upgraded.\n'

                while true; do
                        read -r -p "Do you want to continue (y/n) ? :  " yn
                        case $yn in
                        [Yy]*)

                                break
                                ;;
                        [Nn]*) exit ;;
                        *) echo "Please provide Correct input to proceed." ;;
                        esac
                done
        fi
}

function cleanup() {
        rm -rf "${CURDIR}/adoptjdk.tar.gz"
        printf -- '\nCleaned up the artifacts.\n' >>"$LOG_FILE"
}

function configureAndInstall() {
        printf -- '\nConfiguration and Installation started \n'

        #Installing dependencies
        #printf -- 'User responded with Yes. \n'
        #printf -- 'Downloading OpenJDK 14 with HotSpot. \n'

        #curl -SLO https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.2%2B12/OpenJDK14U-jdk_s390x_linux_hotspot_14.0.2_12.tar.gz
        #sudo tar -C /usr/local -xzf OpenJDK14U-jdk_s390x_linux_hotspot_14.0.2_12.tar.gz
        #export PATH=/usr/local/jdk-14.0.2+12/bin:$PATH

        #java -version |& tee -a "$LOG_FILE"
        #printf -- 'OpenJDK 14 with HotSpot installed\n'

        echo "Java provided by user: $JAVA_PROVIDED" >> "$LOG_FILE"

    if [[ "$JAVA_PROVIDED" == "AdoptJDK11_openj9" ]]; then
        # Install AdoptOpenJDK 11 (With OpenJ9)
        cd "$CURDIR"
        sudo mkdir -p /opt/adopt/java

        curl -SL -o adoptjdk.tar.gz https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10_openj9-0.21.0/OpenJDK11U-jdk_s390x_linux_openj9_11.0.8_10_openj9-0.21.0.tar.gz
        # Everytime new jdk is downloaded, Ensure that --strip valueis correct
        sudo tar -zxvf adoptjdk.tar.gz -C /opt/adopt/java --strip-components 1

        export JAVA_HOME=/opt/adopt/java
        export JAVA11_HOME=/opt/adopt/java

        printf -- " export JAVA_HOME=/opt/adopt/java\n"
        printf -- "Install AdoptOpenJDK 11 (With OpenJ9) success\n" >> "$LOG_FILE"

    elif [[ "$JAVA_PROVIDED" == "AdoptJDK11_hotspot" ]]; then
        # Install AdoptOpenJDK 11 (With OpenJ9)
        cd "$CURDIR"
        sudo mkdir -p /opt/adopt/java

        curl -SL -o adoptjdk.tar.gz https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.8_10.tar.gz
        # Everytime new jdk is downloaded, Ensure that --strip valueis correct
        sudo tar -zxvf adoptjdk.tar.gz -C /opt/adopt/java --strip-components 1

        export JAVA_HOME=/opt/adopt/java
        export JAVA11_HOME=/opt/adopt/java

        printf -- " export JAVA_HOME=/opt/adopt/java\n"
        printf -- "Install AdoptOpenJDK 11 (With Hotspot) success\n" >> "$LOG_FILE"

    elif [[ "$JAVA_PROVIDED" == "OpenJDK11" ]]; then 
        if [[ "$VERSION_ID" == "18.04" ]]; then
	        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-11-jdk
                export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x
                export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk-s390x
	    elif [[ "${ID}" == "rhel" ]]; then
            sudo yum install -y java-11-openjdk java-11-openjdk-devel
	        if [[ $DISTRO == "rhel-8.1" ]]; then				
			# Inside rhel 8.1
			echo "Inside RHEL 8.1"
                	export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
                	export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
			java -version
		    elif [[ $DISTRO == "rhel-8.2" ]]; then
		        # Inside rhel 8.2      
			echo "Inside RHEL 8.2"
                	export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
                	export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
			java -version
		    else
			# Inside rhel 7.x
			echo "Inside RHEL 7x"
			export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
                	export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
                	java -version
		    fi
        elif [[ "${ID}" == "sles" ]]; then
		sudo zypper install -y java-11-openjdk java-11-openjdk-devel
		export JAVA_HOME=/usr/lib64/jvm/java-11-openjdk/
            	export JAVA11_HOME=/usr/lib64/jvm/java-11-openjdk/
        fi
    else
        err "$JAVA_PROVIDED is not supported, Please use valid java from {AdoptJDK, IBM} only"
        exit 1
    fi

        java -version |& tee -a "$LOG_FILE"
        printf -- 'JDK installation successful\n'

        export PATH=$JAVA_HOME/bin:$PATH
        printf -- 'export JAVA_HOME for "$ID"  \n'  >> "$LOG_FILE"

        cd "${CURDIR}"
        # Download and configure ElasticSearch
        printf -- 'Downloading Elasticsearch. Please wait.\n'
        git clone -b v$PACKAGE_VERSION $ES_REPO_URL

        # Download required files and apply patch
        cd "${CURDIR}/elasticsearch"
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/archives/linux-s390x-tar
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/archives/oss-linux-s390x-tar
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/packages/s390x-deb
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/packages/s390x-oss-deb
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/packages/s390x-oss-rpm
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/packages/s390x-rpm
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/docker/docker-s390x-export
	wget $PATCH_URL/build.gradle -P ${CURDIR}/elasticsearch/distribution/docker/oss-docker-s390x-export
	wget $PATCH_URL/docker_build_context_build.gradle -P ${CURDIR}/elasticsearch/distribution/docker/docker-s390x-build-context
	mv ${CURDIR}/elasticsearch/distribution/docker/docker-s390x-build-context/docker_build_context_build.gradle ${CURDIR}/elasticsearch/distribution/docker/docker-s390x-build-context/build.gradle
	wget $PATCH_URL/oss_docker_build_context_build.gradle -P ${CURDIR}/elasticsearch/distribution/docker/oss-docker-s390x-build-context
        mv ${CURDIR}/elasticsearch/distribution/docker/oss-docker-s390x-build-context/oss_docker_build_context_build.gradle ${CURDIR}/elasticsearch/distribution/docker/oss-docker-s390x-build-context/build.gradle
        wget -O - $PATCH_URL/diff.patch | git apply
        
        # Building Elasticsearch
        printf -- 'Building Elasticsearch \n'
        printf -- 'Build might take some time. Sit back and relax\n'
	./gradlew :distribution:archives:oss-linux-s390x-tar:assemble --parallel

        # Verifying Elasticsearch installation
        if [[ $(grep -q "BUILD FAILED" "$LOG_FILE") ]]; then
                printf -- '\nBuild failed due to some unknown issues.\n'
                exit 1
        fi
        printf -- 'Built Elasticsearch successfully. \n\n'
        
        printf -- 'Creating distributions as deb, rpm and docker: \n\n'
		./gradlew :distribution:packages:s390x-oss-deb:assemble
	printf -- 'Created deb distribution. \n\n'
	        ./gradlew :distribution:packages:s390x-oss-rpm:assemble
	printf -- 'Created rpm distribution. \n\n'
		./gradlew :distribution:docker:oss-docker-s390x-build-context:assemble
	printf -- 'Created docker distribution. \n\n'
      
	printf -- "\n\nInstalling Elasticsearch\n"

        cd "${CURDIR}/elasticsearch"
        sudo mkdir /usr/share/elasticsearch
        sudo tar -xzf distribution/archives/oss-linux-s390x-tar/build/distributions/elasticsearch-oss-"${PACKAGE_VERSION}"-SNAPSHOT-linux-s390x.tar.gz -C /usr/share/elasticsearch --strip-components 1
	sudo ln -sf /usr/share/elasticsearch/bin/* /usr/bin/

        if ([[ -z "$(cut -d: -f1 /etc/group | grep elastic)" ]]); then
                printf -- '\nCreating group elastic.\n'
                sudo /usr/sbin/groupadd elastic # If group is not already created
        fi
        sudo chown "$NON_ROOT_USER:elastic" -R /usr/share/elasticsearch

        # Verifying Elasticsearch installation
        if command -v "$PACKAGE_NAME" >/dev/null; then
                printf -- "%s installation completed.\n" "$PACKAGE_NAME"
        else
                printf -- "Error while installing %s, exiting with 127 \n" "$PACKAGE_NAME"
                exit 127
        fi
}

function runTest() {
    # Setting environment variable needed for testing
	#export LANG="en_US.UTF-8"
	export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
	#export JAVA_HOME=/usr/local/jdk-14.0.2+12
	#export JAVA14_HOME=/usr/local/jdk-14.0.2+12
	#export PATH=$JAVA_HOME/bin:$PATH
	#cd "${CURDIR}"
        #curl -SLO https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.8_10.tar.gz
        #sudo tar -C /usr/local -xzf OpenJDK11U-jdk_s390x_linux_hotspot_11.0.8_10.tar.gz
        #printf -- 'OpenJDK 11 with HotSpot installed for testing\n'

        #export JAVA11_HOME=/usr/local/jdk-11.0.8+10
    if [[ "$JAVA_PROVIDED" == "AdoptJDK11_openj9" ]]; then
        export JAVA_HOME=/opt/adopt/java
        export JAVA11_HOME=/opt/adopt/java
        export RUNTIME_JAVA_HOME=$JAVA_HOME
    elif [[ "$JAVA_PROVIDED" == "AdoptJDK11_hotspot" ]]; then
        export JAVA_HOME=/opt/adopt/java
        export JAVA11_HOME=/opt/adopt/java
        export RUNTIME_JAVA_HOME=$JAVA_HOME
    elif [[ "$JAVA_PROVIDED" == "OpenJDK11" ]]; then 
        if [[ "$VERSION_ID" == "18.04" ]]; then
                export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-s390x
                export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk-s390x
	    elif [[ "${ID}" == "rhel" ]]; then
	        if [[ $DISTRO == "rhel-8.1" ]]; then				
			# Inside rhel 8.1
			echo "Inside RHEL 8.1"
                	export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
                	export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
			java -version
		    elif [[ $DISTRO == "rhel-8.2" ]]; then
		        # Inside rhel 8.2      
			echo "Inside RHEL 8.2"
                	export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
			export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
			java -version
		    else 
			# Inside rhel 7.x
			echo "Inside RHEL 7x"
			export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
                	export JAVA11_HOME=/usr/lib/jvm/java-11-openjdk
			export PATH=$JAVA_HOME/bin:$PATH
                	java -version
		    fi
        elif [[ "${ID}" == "sles" ]]; then
		export JAVA_HOME=/usr/lib64/jvm/java-11-openjdk/
            	export JAVA11_HOME=/usr/lib64/jvm/java-11-openjdk/
        fi
    fi


    cd "${CURDIR}/elasticsearch"
	set +e
    # Run Elasticsearch test suite
    printf -- '\n Running Elasticsearch test suite.\n'
    ./gradlew --continue test -Dtests.haltonfailure=false -Dtests.jvm.argline="-Xss2m" |& tee -a ${CURDIR}/logs/test_results.log
	printf -- '***********************************************************************************************************************************'
    printf -- '\n Some X-Pack test cases will fail as X-Pack plugins are not supported on s390x, such as Machine Learning features.\n'
	printf -- '\n Certain test cases may require an individual rerun to pass. There may be false negatives due to seccomp not supporting s390x properly.\n'
    printf -- '***********************************************************************************************************************************\n'
	set -e
}

function installClient() {
        printf -- '\nInstalling Elasticsearch Curator client\n'
        if [[ "${ID}" == "sles" ]]; then
          sudo zypper install -y python3 python3-pip
        fi

        if [[ "${ID}" == "ubuntu" ]]; then
          sudo apt-get update
          sudo apt-get install -y python3-pip
        fi

        if [[ "${ID}" == "rhel" ]]; then
          sudo yum install -y python3-devel
        fi

        if [[ "${ID}" == "sles" ]]; then
          sudo -H env PATH=$PATH pip3 install elasticsearch-curator
        else
          sudo -H pip3 install elasticsearch-curator
        fi
		# Verifying Elasticsearch installation
        if command -v curator >/dev/null; then
                printf -- "\nInstalled Elasticsearch Curator client successfully\n"
        else
                printf -- "\nError occured in installation of Curator client\n"
                exit 127
        fi
}

function logDetails() {
        printf -- 'SYSTEM DETAILS\n' >"$LOG_FILE"
        if [ -f "/etc/os-release" ]; then
                cat "/etc/os-release" >>"$LOG_FILE"
        fi

        cat /proc/version >>"$LOG_FILE"
        printf -- "\nDetected %s \n" "$PRETTY_NAME"
        printf -- "Request details : PACKAGE NAME= %s , VERSION= %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" |& tee -a "$LOG_FILE"
}

# Print the usage message
function printHelp() {
        echo
        echo "Usage: "
        echo "  install.sh  [-d debug] [-y install-without-confirmation] [-t install-with-tests]"
        echo
}

while getopts "h?dytj:" opt; do
        case "$opt" in
        h | \?)
                printHelp
                exit 0
                ;;
        d)
                set -x
                ;;
        y)
                FORCE="true"
                ;;
        t)
                if command -v "$PACKAGE_NAME" >/dev/null; then
                        TESTS="true"
                        printf -- "%s is detected with version %s .\n" "$PACKAGE_NAME" "$PACKAGE_VERSION" |& tee -a "$LOG_FILE"
                        runTest |& tee -a "$LOG_FILE"
                        exit 0

                else
                        TESTS="true"
                fi
                ;;
        j)
            JAVA_PROVIDED="$OPTARG"
            ;;
        esac
done

function printSummary() {
        printf -- '\n***********************************************************************************************************************************\n'
        printf -- "\n* Getting Started * \n"
        printf -- '\nSet JAVA_HOME to start using Elasticsearch right away:'
        printf -- '\nexport JAVA_HOME=/usr/local/jdk-14.0.2+12/\n'
        printf -- '\nRestarting the session will apply changes automatically.'
        printf -- '\n\nStart Elasticsearch using the following command: elasticsearch '
        printf -- '\n\nFor more information on curator client visit: \nhttps://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html \n\n'
        printf -- '***********************************************************************************************************************************\n'
}

logDetails
prepare

DISTRO="$ID-$VERSION_ID"
case "$DISTRO" in
"ubuntu-18.04")
        printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" | tee -a "$LOG_FILE"
        printf -- "Installing dependencies... it may take some time.\n"
        sudo apt-get update
        sudo apt-get install -y curl git gzip tar wget patch locales |& tee -a "$LOG_FILE"
        sudo locale-gen en_US.UTF-8
        configureAndInstall |& tee -a "$LOG_FILE"
        installClient |& tee -a "$LOG_FILE"
        ;;

"rhel-7.6" | "rhel-7.7" | "rhel-7.8" | "rhel-8.1" | "rhel-8.2")
        printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" |& tee -a "$LOG_FILE"
        printf -- "Installing dependencies... it may take some time.\n"
        sudo yum install -y curl git gzip tar wget patch |& tee -a "$LOG_FILE"
        configureAndInstall |& tee -a "$LOG_FILE"
        installClient |& tee -a "$LOG_FILE"
        ;;

"sles-12.5")
        printf -- "Installing %s %s for %s \n" "$PACKAGE_NAME" "$PACKAGE_VERSION" "$DISTRO" |& tee -a "$LOG_FILE"
        printf -- "Installing dependencies... it may take some time.\n"
        sudo zypper install -y curl git gzip tar wget patch | tee -a "$LOG_FILE"
        configureAndInstall |& tee -a "$LOG_FILE"
        installClient |& tee -a "$LOG_FILE"
        ;;

*)
        printf -- "%s not supported \n" "$DISTRO" |& tee -a "$LOG_FILE"
        exit 1
        ;;
esac

# Run tests
if [[ "$TESTS" == "true" ]]; then
        runTest |& tee -a "$LOG_FILE"
fi

cleanup
printSummary |& tee -a "$LOG_FILE"