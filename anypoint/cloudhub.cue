package anypoint
// The cue file for deploying, maintaining mule applications that are deployed to Anypoint cloudhub
import (
	"dagger.io/dagger"
	"list"
	"strings"
	"tool/http"
	)

// Publishes Mule App to cloudhub directly
#PublishMuleAppCloudHub: {
	// the container image
	cliVersion: *"3.10.0" | _#DefaultCLIVersion
	// the authentication for interacting with anytime platform
  auth: #Auth
  // Name and version of the runtime environment.
  runtime: *"4.4.0"| string
  // Number of workers. (This value is '1' by default)
  workers: *1 | number
  // Size of the workers in vCores
  workerSize: *1 | number
  // Name of the region to deploy to.
  region: *"eu-central-1"| "ap-northeast-1" | "ap-southeast-1" | "ap-southeast-2" | "ca-central-1" | "eu-west-1" | "eu-west-2" | "sa-east-1" | "us-east-1" | "us-east-2" | "us-west-1" | "us-west-2"
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
	// name of the jar file inside appJarDir
	targetName: *"muleapp-\(name)-\(version).jar" | string
	// properties that must be passed to the application
	properties: [string]: string | *_default_props
	// verify the deployed app
	verifyDeployment: *true | false
	// verification path
	healthCheckPath: *"/" | string


	// Internal flags
	_default_props: {}
  _encryptPersistentQueues: false | bool
  _enablePersistentQueues: false | bool

  if (persistentQueues == "enable") {
  	_enablePersistentQueues: true
  	_encryptPersistentQueues: false
	}
	if (persistentQueues == "enableEncrypt") {
  	_enablePersistentQueues: true
  	_encryptPersistentQueues: true
	}
	// combine the properties
	_properties: strings.Join(list.FlattenN([
				for k, v in properties {
				if (v & string) != _|_ && (k & string) != _|_ {
					["\(k):\(v)"]
				}
			},
		], 1),"\n")

	runCli: #_runCli & {
		cliVersion: cliVersion
		cliCommand: "publish_muleapp_cloudhub"
		cliAuth: auth
		// Force deployment, it could be that the external properites may have been changed
		// don't rely on cache
		ignoreCache: true
		cliEnv: {
			API_NAME: "\(name)-v\(strings.Replace(version,".","",-1))"
			APP_RUNTIME: runtime
			CH_WORKER_COUNT: "\(workers)"
			CH_WORKER_SIZE: "\(workerSize)"
			CH_REGION: region
			APP_ENABLE_PQ: "\(_enablePersistentQueues)"
			APP_ENABLE_PQ_ENC: "\(_encryptPersistentQueues)"
			CH_ENABLE_STATIC_IP: "\(enableStaticIPs)"
			CH_ENABLE_AUTORESTART: "\(!disableAutoRestart)"
			if (_properties != "_|_") {
				APP_PROPERTIES: "\(_properties)"
			}
			API_SPEC_IMPL_JAR_PATH: "/src/\(targetName)"
		}
		// the source here is mounted at /src
		source: appJarDir
	}

	if(verifyDeployment){
		_checkHealth: http.Get & {
			url: healthCheckPath
			response: statusCode: 200
			response: status: ""
		}
		_resultStatus: _checkHealth.response.statusCode
	}

}