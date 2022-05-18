package anypoint
// main cue file for maintaining common configurations for anypoint-cli
import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"dagger.io/dagger/core"
	)

// The Anypoint Authentication config for interacting with anypoint platform
#Auth: {
	// Anypoint client id
	clientId: dagger.#Secret
	// Anypoint client secret
	clientSecret: dagger.#Secret
	// The environment where where the specification needs to be deployed
	environment: string | *"Sandbox"
	// The Business Group name
	businessGroupId: string
	// The Business Group name
	businessGroupName: string
}


#_runCli: {
	cliEnv: [string]: string
	cliVersion: *"3.10.0" | _#DefaultCLIVersion | string
	cliCommand: "publish_apispec_exchange" | "publish_muleapp_exchange" | "publish_muleapp_cloudhub"
	cliAuth: #Auth
	source: dagger.#FS
	// Normally the layers are cached, the command won't be re-runed.
	ignoreCache: *false | bool

	_image: #Container & {
			version: cliVersion
		}
	// Deploy the API spec
	run: bash.#Run & {
			input: _image.output
			script: {
				_load: core.#Source & {
					path: "."
					include: ["*.sh"]
				}
				directory: _load.output
				filename:  "wrapper.sh"
			}
			always: ignoreCache
			args: [cliCommand]
			env: {
				ANYPOINT_ORG: cliAuth.businessGroupName
				ANYPOINT_BG_ID: cliAuth.businessGroupId
				ANYPOINT_ENV: cliAuth.environment
				cliEnv
			}
			workdir: "/"
			mounts: {
				"payload": {
					dest:       "/src"
					"contents": source
				}
				"Client Id": {
					dest:     "/run/secrets/clientId"
					contents: cliAuth.clientId
				}
				"Client Secret": {
					dest:     "/run/secrets/clientSecret"
					contents: cliAuth.clientSecret
				}
			}
			// Default output file, use it or not
			export: files: "/output": _
		}
	output: run.export.files."/output"
}
