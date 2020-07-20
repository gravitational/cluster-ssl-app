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
           defaultValue: 'master',
           description: 'Git tag to build'),
    string(name: 'OPS_URL',
           defaultValue: 'https://ci-ops.gravitational.io',
           description: 'Ops Center URL to download dependencies from'),
    string(name: 'OPS_CENTER_CREDENTIALS',
           defaultValue: 'CI_OPS_API_KEY',
           description: 'Jenkins\' key containing the Ops Center Credentials'),
    string(name: 'GRAVITY_VERSION',
           defaultValue: '7.0.12',
           description: 'gravity/tele binaries version'),
    string(name: 'EXTRA_GRAVITY_OPTIONS',
           defaultValue: '',
           description: 'Gravity options to add when calling tele'),
    booleanParam(name: 'ADD_GRAVITY_VERSION',
                 defaultValue: false,
                 description: 'Appends "-${GRAVITY_VERSION}" to the tag to be published'),
    booleanParam(name: 'IMPORT_APP',
                 defaultValue: false,
                 description: 'Import application to ops center'
    ),
  ]),
])

node {
  workspace {
    stage('checkout') {
      checkout([
        $class: 'GitSCM',
        branches: [[name: "${params.TAG}"]],
        doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
        extensions: scm.extensions,
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
    TELE_STATE_DIR = "${pwd()}/state/${APP_VERSION}"
    BINARIES_DIR = "${pwd()}/bin"
    EXTRA_GRAVITY_OPTIONS = "--state-dir=${TELE_STATE_DIR} ${params.EXTRA_GRAVITY_OPTIONS}"
    MAKE_ENV = [
      "EXTRA_GRAVITY_OPTIONS=${EXTRA_GRAVITY_OPTIONS}",
      "PATH+GRAVITY=${BINARIES_DIR}",
      "VERSION=${APP_VERSION}"
    ]

    stage('download gravity/tele binaries for login') {
      withEnv(MAKE_ENV + ["BINARIES_DIR=${BINARIES_DIR}"]) {
        sh 'make download-binaries'
      }
    }

    stage('build-app') {
      withCredentials([
        string(credentialsId: params.OPS_CENTER_CREDENTIALS, variable: 'API_KEY'),
      ]) {
        withEnv(MAKE_ENV) {
          sh """
  rm -rf ${TELE_STATE_DIR} && mkdir -p ${TELE_STATE_DIR}
  tele logout ${EXTRA_GRAVITY_OPTIONS}
  tele login ${EXTRA_GRAVITY_OPTIONS} -o ${OPS_URL} --token=${API_KEY}
  make build-app"""
        }
      }
    }

    stage('push') {
      if (params.IMPORT_APP) {
        withCredentials([
          string(credentialsId: params.OPS_CENTER_CREDENTIALS, variable: 'API_KEY'),
        ]) {
          withEnv(MAKE_ENV) {
            sh 'make import'
          }
        }
      } else {
        echo 'skipped application import'
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
