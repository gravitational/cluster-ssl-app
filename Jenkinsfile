#!/usr/bin/env groovy
def propagateParamsToEnv() {
  for (param in params) {
    if (env."${param.key}" == null) {
      env."${param.key}" = param.value
    }
  }
}


properties([
  disableConcurrentBuilds(),
  parameters([
    string(name: 'TAG',
           defaultValue: '',
           description: 'Git tag to build'),
    string(name: 'GRAVITY_VERSION',
           defaultValue: '7.0.30',
           description: 'gravity/tele binaries version'),
    string(name: 'EXTRA_GRAVITY_OPTIONS',
           defaultValue: '',
           description: 'Gravity options to add when calling tele'),
    booleanParam(name: 'ADD_GRAVITY_VERSION',
                 defaultValue: false,
                 description: 'Appends "-${GRAVITY_VERSION}" to the tag to be published'),
    string(name: 'S3_UPLOAD_PATH',
           defaultValue: '',
           description: 'S3 bucket and path to upload built application image. For example "builds.example.com/cluster-ssl-app".'),
    booleanParam(name: 'IMPORT_APP_PACKAGE',
                 defaultValue: false,
                 description: 'Import application to S3 bucket'),
    booleanParam(name: 'BUILD_GRAVITY_APP',
                 defaultValue: true,
                 description: 'Generate a Gravity App tarball'),
  ]),
])

node {
  skipDefaultCheckout()
  workspace {
    stage('checkout') {
      print 'Running stage Checkout source'

      def branches
      if (params.TAG == '') { // No tag specified
        branches = scm.branches
      } else {
        branches = [[name: "refs/tags/${params.TAG}"]]
      }

      checkout([
        $class: 'GitSCM',
        branches: branches,
        doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
        extensions: [[$class: 'CloneOption', noTags: false, shallow: false]],
        submoduleCfg: [],
        userRemoteConfigs: scm.userRemoteConfigs,
      ])
    }
    stage('params') {
      echo "${params}"
      propagateParamsToEnv()
    }
    stage('clean') {
      sh "make clean"
    }

    APP_VERSION = sh(script: 'make what-version', returnStdout: true).trim()
    APP_VERSION = params.ADD_GRAVITY_VERSION ? "${APP_VERSION}-${GRAVITY_VERSION}" : APP_VERSION
    STATEDIR = "${pwd()}/state/${APP_VERSION}"
    BINARIES_DIR = "${pwd()}/bin"
    MAKE_ENV = [
      "PATH+GRAVITY=${BINARIES_DIR}",
      "VERSION=${APP_VERSION}"
    ]

    stage('download gravity/tele binaries for login') {
      withEnv(MAKE_ENV + ["BINARIES_DIR=${BINARIES_DIR}"]) {
        sh 'make download-binaries'
      }
    }

    stage('export') {
      if (params.BUILD_GRAVITY_APP) {
        withEnv(MAKE_ENV) {
          sh """
            rm -rf ${STATEDIR} && mkdir -p ${STATEDIR}
            make export"""
          archiveArtifacts "build/application.tar"
        }
      } else {
        echo 'skipped application export'
      }
    }

    stage('upload application image to S3') {
      if (isProtectedBranch(env.TAG) && params.IMPORT_APP_PACKAGE && params.BUILD_GRAVITY_APP) {
        withCredentials([usernamePassword(credentialsId: "${AWS_CREDENTIALS}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          def S3_URL = "s3://${S3_UPLOAD_PATH}/cluster-ssl-app-${APP_VERSION}.tar"
          withEnv(MAKE_ENV + ["S3_URL=${S3_URL}"]) {
            sh 'aws s3 cp --only-show-errors build/cluster-ssl-app.tar ${S3_URL}'
          }
        }
      } else {
        echo 'skipped application import to S3'
      }
    }
  }
}

void workspace(Closure body) {
  timestamps {
    ws("${pwd()}-${BUILD_ID}") {
      body()
    }
  }
}

def isProtectedBranch(branchOrTagName) {
  String[] protectedBranches = ['master']

  protectedBranches.each { protectedBranch ->
    if (branchOrTagName == ${protectedBranch}) {
      return true;
    }
    def status = sh(script: "git branch --contains=${branchOrTagName} | grep '[*[:space:]]*${protectedBranch}\$'", returnStatus: true)
    if (status == 0) {
      return true
    }
  }
}
