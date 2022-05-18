⚠️ _The module is under active development. Not suitable for production usage_ 
# Dagger Anypoint package

A [dagger](https://dagger.io/) module for building, testing and deploying Api specification and Mule applications (Api Implementations) to Anypoint platform. The module internally uses [`anypoint-cli`](https://docs.mulesoft.com/anypoint-cli/3.x). 


## Description
_details yet to be added_

## Installation
_details yet to be added_

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

| name           | method/config                     | notes                                                                                                                                                                                                |
|----------------|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Authentication | `anypoint#Auth`                   | The main [config](https://github.com/foryouandyourcustomers/dagger-anypoint/blob/main/anypoint/cli.cue#L10) for authentication with anypoint, this is needed for any interactions with the platform. |
| PublishApiSpec | `anypoint#PublishApiSpec`         |                                                                                                                                                                                                      |
|                | `anypoint#BuildMuleApp`           |                                                                                                                                                                                                      |
|                | `anypoint#TestMuleApp`            |                                                                                                                                                                                                      |
|                | `anypoint#TestMuleApp`            |                                                                                                                                                                                                      |
|                | `anypoint#PublishMuleAppExchange` |                                                                                                                                                                                                      |
|                | `anypoint#PublishMuleAppCloudHub` |                                                                                                                                                                                                      |




#### Environment variables

| Variable               | Description       |
|------------------------|-------------------|
| ANYPOINT_CLIENT_ID     | client Id         |
| ANYPOINT_CLIENT_SECRET | client secret     |
| ANYPOINT_ORG           | organization Id   |
| ANYPOINT_ENV           | environment name  |
| ANYPOINT_BG_ID         | business group id |
