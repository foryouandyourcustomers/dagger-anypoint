package cloudhub

// The cue file for deploying, maintaining mule applications that are deployed to Anypoint cloudhub
import (
	"dagger.io/dagger"
	"list"
	"strings"
	"tool/http"
	"encoding/base64"
	"github.com/foryouandyourcustomers/dagger-anypoint/anypoint"
)
_default_props: {}

// Publishes Mule App to cloudhub directly
#PublishMuleApp: {
	// the container image
	cliVersion: *"3.10.0" | anypoint._#DefaultCLIVersion
	// the authentication for interacting with anytime platform
	auth: anypoint.#Auth
	// Name and version of the runtime environment.
	runtime: *"4.4.0" | string
	// Number of workers. (This value is '1' by default)
	workers: *1 | number
	// Size of the workers in vCores
	workerSize: *0.1 | number
	// Name of the region to deploy to.
	region: *"eu-central-1" | "ap-northeast-1" | "ap-southeast-1" | "ap-southeast-2" | "ca-central-1" | "eu-west-1" | "eu-west-2" | "sa-east-1" | "us-east-1" | "us-east-2" | "us-west-1" | "us-west-2"
	// Configuration of persistent queues
	persistentQueues: *"disable" | "enable" | "enableEncrypt"
	// Enable or disable static IPs
	enableStaticIPs: *false | true
	// Automatically restart app when not responding.
	disableAutoRestart: *false | true
	// source fs of the file
	appJarDir: dagger.#FS
	// name of the application
	name: string
	// Sem version of the specification
	version: =~"^[0-9]+.[0-9]+.[0-9]+$"
	// optionally, mention the name of the jarfile name inside the source
	targetName: string | *" "
	// properties that must be passed to the application
	properties: [string]: string | *_default_props
	// verify the deployed app
	verifyDeployment: *true | false
	// verification path
	healthCheckPath: *"/" | string

	// Internal fields

	// yeah, this need not be unique always but meh, its ok for now
	_env:  strings.Replace(strings.ToLower(base64.Encode(null, auth.environment)), "=", "", -1)
	_name: strings.Replace(strings.ToLower(name), " ", "-", -1)
	_id:   "\(_name)-\(_env)"
	_encryptPersistentQueues: false | bool
	_enablePersistentQueues:  false | bool
	_deployableJarFile:       string | *targetName

	if ( targetName == " ") {
		_deployableJarFile: "muleapp-\(_name)-\(version).jar"
	}

	if (persistentQueues == "enable") {
		_enablePersistentQueues:  true
		_encryptPersistentQueues: false
	}
	if (persistentQueues == "enableEncrypt") {
		_enablePersistentQueues:  true
		_encryptPersistentQueues: true
	}

	// combine the properties
	_properties: strings.Join(list.FlattenN(
			[
				["Version:\(version)"],
				for k, v in properties {
				if (v & string) != _|_ && (k & string) != _|_ {
					["\(k):\(v)"]
				}
			},
		],
		1), "\n")

	runCli: anypoint.#_runCli & {
		cliVersion: cliVersion
		cliCommand: "publish_muleapp_cloudhub"
		cliAuth:    auth
		// Force deployment, it could be that the external properites may have been changed
		// don't rely on cache
		ignoreCache: true
		cliEnv: {
			API_NAME:              "\(_id)"
			APP_RUNTIME:           runtime
			CH_WORKER_COUNT:       "\(workers)"
			CH_WORKER_SIZE:        "\(workerSize)"
			CH_REGION:             region
			APP_ENABLE_PQ:         "\(_enablePersistentQueues)"
			APP_ENABLE_PQ_ENC:     "\(_encryptPersistentQueues)"
			CH_ENABLE_STATIC_IP:   "\(enableStaticIPs)"
			CH_ENABLE_AUTORESTART: "\(!disableAutoRestart)"
			if (_properties != "_|_") {
				APP_PROPERTIES: "\(_properties)"
			}
			API_SPEC_IMPL_JAR_PATH: "/src/\(_deployableJarFile)"
		}
		// the source here is mounted at /src
		source: appJarDir
	}

	if (verifyDeployment) {
		_checkHealth: http.Get & {
			url: healthCheckPath
			response: statusCode: 200
			response: status:     ""
		}
		_resultStatus: _checkHealth.response.statusCode
	}

}

#PromoteMuleApp: {
	// the container image
	cliVersion: *"3.10.0" | anypoint._#DefaultCLIVersion
	// the authentication for interacting with anytime platform
	auth: anypoint.#Auth
	// the "from" environment
	fromEnv: *auth.environment | string
	// the "to" environment
	toEnv: string
	// name of the application in the "from" environment - this is different from appName
	// we expect either fromEnvApiName or fromEnvAppName to be provided
	{
		fromEnvApiName:  string
		_fromEnvApiName: strings.Replace(strings.ToLower(fromEnvApiName), " ", "-", -1)
		_fromEnvEncoded: strings.Replace(strings.ToLower(base64.Encode(null, fromEnv)), "=", "", -1)
		// this is the actual app name
		_fromEnvAppName: "\(_fromEnvApiName)-\(_fromEnvEncoded)"
		_toEnvAppName:   "\(_fromEnvApiName)-\(_toEnvEncoded)"
	} | {
		// the name of the app "as is" in the environment
		fromEnvAppName:  string
		_fromEnvAppName: fromEnvAppName
		_toEnvAppName:   "\(_fromEnvAppName)-\(_toEnvEncoded)"
	}

	// name of the application in the "to" environment
	toEnvAppName: *null | string
	// properties that must be passed to the application
	properties: [string]: string | *_default_props
	// Internal fields
	_fromEnvAppName: string
	_toEnvAppName:   string
	_toEnvEncoded: strings.Replace(strings.ToLower(base64.Encode(null, toEnv)), "=", "", -1)

	if (toEnvAppName != null ) {
		_toEnvAppName: toEnvAppName
	}
	// combine the properties
	_properties: strings.Join(list.FlattenN(
			[
				for k, v in properties {
				if (v & string) != _|_ && (k & string) != _|_ {
					["--property \"\(k):\(v)\""]
				}
			},
		],
		1), " ")

	runCli: anypoint.#_runCli & {
		cliVersion:  cliVersion
		cliCommand:  "promote_muleapp_cloudhub"
		cliAuth:     auth
		ignoreCache: true
		cliEnv: {
			API_NAME:        "\(_fromEnvAppName)"
			API_NAME_TARGET: "\(_toEnvAppName)"
			FROM_ENV:        "\(fromEnv)"
			TO_ENV:          "\(toEnv)"
			if (_properties != "_|_") {
				OVERRIDING_PROPS: "\(_properties)"
			}
		}
	}

}
