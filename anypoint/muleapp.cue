package anypoint

// The cue file for publishing API specs to Anypoint Platform
import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

_#MavenVersion: "3.8.5-openjdk-11"

// The credentials for accessing mulesoft enterprise repositories
#MavenRepoAuth: {
	muleRepoUser: dagger.#Secret
	muleRepoPass: dagger.#Secret
}

// Publishes Api Implementation to Exchange
#PublishMuleAppExchange: {
	// the container image
	cliVersion: *"3.10.0" | _#DefaultCLIVersion
	// the authentication for interacting with anytime platform
	auth: #Auth
	// source fs of the file
	appJarDir: dagger.#FS
	// name of the app
	name: string
	// Sem version of the specification
	version: =~"^[0-9]+.[0-9]+.[0-9]+$"
	// optionally, mention the name of the jarfile name inside the source
	targetName: string | *" "

	_deployableJarFile: string | *targetName

	if ( targetName == " ") {
		_deployableJarFile: "muleapp-\(name)-\(version).jar"
	}

	runCli: #_runCli & {
		cliVersion: cliVersion
		cliCommand: "publish_muleapp_exchange"
		cliAuth:    auth
		cliEnv: {
			API_NAME:                  name
			API_SPEC_IMPL_SEM_VERSION: version
			API_SPEC_IMPL_JAR_PATH:    "/src/\(_deployableJarFile)"
		}
		// the source here is mounted at /src
		source: appJarDir
	}

	// The url where the app is published on Exchange
	exchangeUrl: runCli.output
}

// Builds maven based project
#BuildMuleApp: {
	// maven version
	mavenVersion: *_#MavenVersion | string
	// source of the app
	appSource: dagger.#FS
	// Anypoint authentication
	auth: #Auth
	// The credentials for accessing mulesoft enterprise repositories
	mavenRepoAuth: #MavenRepoAuth
	// name of the app
	name: string
	// Sem version of the specification
	version: =~"^[0-9]+.[0-9]+.[0-9]+$"
	// optionally, mention the name of the jarfile name inside the source
	targetName: string | *" "

	_deployableJarFile: string | *targetName

	if ( targetName == " ") {
		_deployableJarFile: "muleapp-\(name)-\(version).jar"
	}

	_maven: docker.#Pull & {
		source: "maven:\(mavenVersion)"
	}

	runBuild: bash.#Run & {
		input: _maven.output
		script: {
			contents:
				"""
							cd /src
							mvn clean package -s /config/maven-auth.xml
							mkdir /output
							mv $(ls target/*.jar) /output/\(_deployableJarFile)
					"""
		}
		env: {
			ANYPOINT_CLIENT_ID:     auth.clientId
			ANYPOINT_CLIENT_SECRET: auth.clientSecret
			ANYPOINT_BG_ID:         auth.businessGroupId
			MULESOFT_EE_REPO_USER:  mavenRepoAuth.muleRepoUser
			MULESOFT_EE_REPO_PASS:  mavenRepoAuth.muleRepoPass
		}
		workdir: "/"
		mounts: {
			_load: core.#Source & {
				path: "."
				include: ["*.xml"]
			}
			"maven repo": {
				dest:     "/root/.m2"
				type:     "cache"
				contents: core.#CacheDir & {
					id: "mavenrepo"
				}
			}
			"source": {
				dest:       "/src"
				"contents": appSource
			}
			"config": {
				dest:       "/config"
				"contents": _load.output
			}
		}
		export: directories: "/output": _
	}
	output: runBuild.export.directories."/output"
}

#TestMuleApp: {
	// maven version
	mavenVersion: *_#MavenVersion | string
	// source of the app
	appSource: dagger.#FS
	// Anypoint authentication
	auth: #Auth
	// The credentials for accessing mulesoft enterprise repositories
	mavenRepoAuth: #MavenRepoAuth

	_maven: docker.#Pull & {
		source: "maven:\(mavenVersion)"
	}

	runBuild: bash.#Run & {
		input: _maven.output
		script: {
			contents:
				"""
							cd /src
							mvn clean test -s /config/maven-auth.xml
							mkdir /reports && cd target
							if [ -d "surefire-reports" ]; then
								mv surefire-reports /reports
							fi
					"""
		}
		env: {
			ANYPOINT_CLIENT_ID:     auth.clientId
			ANYPOINT_CLIENT_SECRET: auth.clientSecret
			ANYPOINT_BG_ID:         auth.businessGroupId
			MULESOFT_EE_REPO_USER:  mavenRepoAuth.muleRepoUser
			MULESOFT_EE_REPO_PASS:  mavenRepoAuth.muleRepoPass
		}
		workdir: "/"
		mounts: {
			_load: core.#Source & {
				path: "."
				include: ["*.xml"]
			}
			"maven repo": {
				dest:     "/root/.m2"
				type:     "cache"
				contents: core.#CacheDir & {
					id: "mavenrepo"
				}
			}
			"source": {
				dest:       "/src"
				"contents": appSource
			}
			"config": {
				dest:       "/config"
				"contents": _load.output
			}
		}
		export: directories: "/reports": dagger.#FS
	}
	testReportDir: runBuild.export.directories."/reports"
}
