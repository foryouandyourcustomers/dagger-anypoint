package anypoint

// The cue file for publishing API specs to Anypoint Platform
import (
	"dagger.io/dagger"
	"strings"
)

// Publishes Api Specficiation to Design center and Exchange
#PublishApiSpec: {
	// the container image
	cliVersion: *"3.10.0" | _#DefaultCLIVersion
	//
	auth: #Auth
	// specification name
	name: string
	// Path to the directory of the specification
	specSource: dagger.#FS
	// Sem version of the specification
	version: =~"^[0-9]+.[0-9]+.[0-9]+$"
	// Major version of the specification
	majorVersion: string
	// Type of the specification
	type: "raml" | "raml-fragment"
	// Publish this specification to the exchange
	publishToExchange: *true | false
	// Spec asset id
	exchangeAssetId: *_id | string
	// Internal fields
	_id: strings.Replace(strings.ToLower(name), " ", "-", -1)

	runCli: #_runCli & {
		cliVersion: cliVersion
		cliCommand: "publish_apispec_exchange"
		cliAuth:    auth
		cliEnv: {
			API_NAME:               name
			API_SPEC_ID:            exchangeAssetId
			API_SPEC_TYPE:          type
			API_SPEC_MAJOR_VERSION: majorVersion
			API_SPEC_SEM_VERSION:   version
			API_SPEC_PATH:          "/src"
			if (publishToExchange) {
				API_SPEC_PUBLISH: "1"
			}
		}
		source: specSource
	}
}
