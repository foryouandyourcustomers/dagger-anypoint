#!/usr/bin/env bash
# a wrapper script to facilitate running anypoint cli

# these are already expected to be present - no need for verification again
ANYPOINT_CLIENT_ID="$(cat /run/secrets/clientId)"
ANYPOINT_CLIENT_SECRET="$(cat /run/secrets/clientSecret)"
export ANYPOINT_CLIENT_ID
export ANYPOINT_CLIENT_SECRET

## Environment variables expected
# ANYPOINT_ORG
# ANYPOINT_ENV
# ANYPOINT_BG_ID
# API_SPEC_ID
# API_SPEC_TYPE
# API_SPEC_MAJOR_VERSION
# API_SPEC_SEM_VERSION
# API_SPEC_PATH

# dump env variables
env
publish_apispec_exchange(){

  projects=$(anypoint-cli designcenter project list "${API_NAME}" -o json | jq '. | length')

  if [[ -n $projects ]]; then
    # we need check the exact project here but we skip that for another day
    # TODO: search more precisely
    echo "${projects} found with name matching ${API_NAME}, not creating the project"
  else
    echo "No projects named ${API_NAME} found, creating one"
    anypoint-cli designcenter project create --type "${API_SPEC_TYPE}" "${API_NAME}"
  fi
  echo "Uploading project to Design center"
  anypoint-cli designcenter project upload "${API_NAME}" "${API_SPEC_PATH}"

  if [[ -n ${API_SPEC_PUBLISH} ]]; then
    echo "Publishing the project to the exchange"
    anypoint-cli designcenter project publish "${API_NAME}" \
          --name "${API_NAME}" \
          --apiVersion "${API_SPEC_MAJOR_VERSION}" \
          --assetId "${API_SPEC_ID}" \
          --groupId "${ANYPOINT_BG_ID}" \
          --version "${API_SPEC_SEM_VERSION}"

  else
    echo "Skipping publishing the project to the exchange"
  fi

  echo "https://anypoint.mulesoft.com/exchange/${ANYPOINT_BG_ID}/${API_NAME}/${API_SPEC_SEM_VERSION}" > /output
}

# API_NAME
# API_SPEC_IMPL_SEM_VERSION
# API_SPEC_IMPL_JAR_PATH
publish_muleapp_exchange(){
  echo "Publishing ${API_SPEC_IMPL_JAR_PATH} to the exchange"

  anypoint-cli exchange asset uploadv2 \
       --client_id ${ANYPOINT_CLIENT_ID} \
       --client_secret ${ANYPOINT_CLIENT_SECRET} \
       --organization "${ANYPOINT_ORG}" \
       --environment "${ANYPOINT_ENV}" \
       --files.mule-application.jar "${API_SPEC_IMPL_JAR_PATH}" \
       --type "app"  \
       --name "${API_NAME}" "${ANYPOINT_BG_ID}/${API_NAME}/${API_SPEC_IMPL_SEM_VERSION}"

    # Url of the published app
    echo "https://anypoint.mulesoft.com/exchange/${ANYPOINT_BG_ID}/${API_NAME}/${API_SPEC_IMPL_SEM_VERSION}" > /output
}

# API_NAME
# APP_RUNTIME
# CH_WORKER_COUNT
# CH_WORKER_SIZE
# CH_REGION
# APP_ENABLE_PQ
# APP_ENABLE_PQ_ENC
# APP_PROPERTIES
# CH_ENABLE_STATIC_IP
# CH_ENABLE_AUTORESTART
# API_SPEC_IMPL_JAR_PATH
publish_muleapp_cloudhub(){
  echo "Checking if Muleapp ${API_NAME} already exists"\
  # When there's no app, the command exist 255 barrrr...
  anypoint-cli runtime-mgr cloudhub-application describe-json "${API_NAME}" > /init-status || true
  init_status=$(cat /init-status)

  if [[ "${init_status}" == *"No application"* ]]; then
    echo "Deploying ${API_SPEC_IMPL_JAR_PATH} to the cloudhub @${CH_REGION} "
    echo "${APP_PROPERTIES}" > /deploy-properties

    anypoint-cli runtime-mgr cloudhub-application deploy  \
           --client_id ${ANYPOINT_CLIENT_ID} \
           --client_secret ${ANYPOINT_CLIENT_SECRET} \
           --organization "${ANYPOINT_ORG}" \
           --environment "${ANYPOINT_ENV}" \
           --runtime "${APP_RUNTIME}" \
           --workers "${CH_WORKER_COUNT}" \
           --workerSize "${CH_WORKER_SIZE}" \
           --region "${CH_REGION}" \
           --persistentQueues "${APP_ENABLE_PQ}" \
           --persistentQueuesEncrypted "${APP_ENABLE_PQ_ENC}" \
           --staticIPsEnabled "${CH_ENABLE_STATIC_IP}" \
           --autoRestart "${CH_ENABLE_AUTORESTART}" \
           --propertiesFile /deploy-properties \
           "${API_NAME}" "${API_SPEC_IMPL_JAR_PATH}"

    anypoint-cli runtime-mgr cloudhub-application describe-json "${API_NAME}" > /init-deploy-status.json
    app_url=$(cat /init-deploy-status.json | jq -r .fullDomain)
    deploy_status=$(cat /init-deploy-status.json | jq -r .status)

    echo "Application will be available at: '${app_url}' waiting to be deployed; status: ${deploy_status}"
    still_deploying=true

    while ${still_deploying}; do
        sleep 30
        anypoint-cli runtime-mgr cloudhub-application describe-json "${API_NAME}" > /deploy-status.json
        deploy_status=$(cat /deploy-status.json | jq -r .status)

        echo "status: ${deploy_status}"
        if [[ "${deploy_status}" == "STARTED" || "${deploy_status}" == "FAILED" ]]; then
            still_deploying=false
        fi
    done

  else
     echo "Muleapp '${API_NAME}' is already running; won't redeploy;"
     echo ${init_status} | jq > deploy-status.json
  fi

  mv /init-status /output
  mv /deploy-status.json /output
  cat /output
}


# Set default target if none given as argument
target=${1}
echo "Executing ${target}"
# Execute target
${target}
