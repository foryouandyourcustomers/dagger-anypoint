⚠️ _The module is under active development. Not suitable for production usage_ 
# Dagger Anypoint package

A [dagger](https://dagger.io/) module for building, testing and deploying Api specification and Mule applications (Api Implementations) to Anypoint platform. The module internally uses [`anypoint-cli`](https://docs.mulesoft.com/anypoint-cli/3.x). 


## Installation
You can install the latest release with

```shell
dagger project update github.com/foryouandyourcustomers/dagger-anypoint/anypoint@<release>
```
If you want to work directly with `release` change the version to `main` or use one of the tagged releases 

### Usage & Examples

```shell
import github.com/foryouandyourcustomers/dagger-anypoint/anypoint
```

List of supported actions and its relation to anypoint platform

| name                                  | method/config                                                                                                                      | notes                                                                                                                                                                                                                     |
|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Platform authentication               | [`anypoint#Auth`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/cli.cue#L10)                        | The main [config](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/cli.cue#L10) for authentication with anypoint, this is needed for any interactions with the platform.                      |
| Mulesoft EE Repository Authentication | [`anypoint#MavenRepoAuth`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/apiImpl.cue#L13)           | The [credentials](https://docs.mulesoft.com/mule-runtime/latest/maven-reference#configure-maven-to-access-mulesoft-enterprise-repository) to the Mulesoft Enterprise repository that was acquired via the support ticket. |
| Publish Api Specification             | [`anypoint#PublishApiSpec`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/apispec.cue#L8)           | Publishes the API specification to Design center and optionally, publish to Exchange.                                                                                                                                     |
| Build Mule Application(jar)           | [`anypoint#BuildMuleApp`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/apiImpl.cue#L52)            | Builds Mule application to the mule application                                                                                                                                                                           |
| Test Mule Application                 | [`anypoint#TestMuleApp`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/apiImpl.cue#L117)            | Tests Mule application by running MUnit test cases.                                                                                                                                                                       |
| Publish Mule Application (jar)        | [`anypoint#PublishMuleAppExchange`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/apiImpl.cue#L20)  | Publishes the the Mule application artifact (jar) to Exchange                                                                                                                                                             |
| Deploy Mule Application to CloudHub   | [`anypoint#PublishMuleAppCloudHub`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/cloudhub.cue#L11) | Deploys the Mule Application to CloudHub runtime.                                                                                                                                                                         |
| Promote Mule Application to CloudHub  | [`anypoint#PublishMuleAppCloudHub`](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/cloudhub.cue#L11) | Deploys the Mule Application to CloudHub runtime.                                                                                                                                                                         |

## Ongoing work

| Features                                   | Runtime Environment | ✅ 🔄 ⛔ | Notes |
|--------------------------------------------|---------------------|--------|-------|
| Build & Test MuleApplication               | Any                 | ✅      |       |
| Publish API specification                  | Any                 | ✅      |       |
| Create, Manage, Promote Api Manager        | Any                 | 🔄     |       |
| Create, Manage, Promote Automated Policies | Any                 | 🔄     |       |
| Create & Manage Api Contracts              | Any                 | 🔄     |       |
| Deploy Mule Application                    | Cloudhub            | ✅      |       |
| Mule Application Environment Promotion     | Cloudhub            | ✅      |       |
| Deploy Mule Application                    | Hybrid              | 🔄     |       |
| Mule Application Environment Promotion     | Hybrid              | 🔄     |       |
| Deploy Mule Application                    | RTF                 | 🔄     |       |
| Mule Application Environment Promotion     | RTF                 | 🔄     |       |
| Deploy Mule Application                    | PCE                 | ⛔      |       |
| Mule Application Environment Promotion     | PCE                 | ⛔      |       |

--

| Legend | Notes             |
|--------|-------------------|
| ✅      | Completed         |
| 🔄     | Considering       |
| ⛔      | Will not consider |
