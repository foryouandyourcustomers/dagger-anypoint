package apcli
// The cue file for maintaining the container image running anypoint-cli
import (
	"universe.dagger.io/alpine"
	"universe.dagger.io/docker"
)
// The default version of the anypoint-cli
_#DefaultCLIVersion: "latest"

// Build a docker image to run the anypoint client
#Container: {
	version: string
	_build: docker.#Build & {
		steps: [
			alpine.#Build & {
				packages: {
					bash: {}
					curl: {}
					jq: {}
					npm: {}
				}
			},
			// FIXME: make this an alpine custom package, that would be so cool.
			docker.#Run & {
				command: {
					name: "npm"
					args: ["-g", "install", "anypoint-cli@\(version)"]
				}
			},
		]
	}
	output: _build.output
}
