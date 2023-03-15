#!/usr/bin/env bash
set -e

# The command that will be used to generate the list options
# kubectl config get-contexts -o=name | sort -n | grep -i dev

echoerr() { echo "$@" 1>&2; }

choose_context_interactive() {
    local choice
    choice="$(
        _KUBECTX_FORCE_COLOR=1 \
            FZF_DEFAULT_COMMAND="kubectl config get-contexts -o=name | sort -n | grep -i stg" \
            fzf --ansi --no-preview || true
    )"
    if [[ -z "${choice}" ]]; then
        echoerr "error: you did not choose any of the options"
        exit 1
    else
        echo "$choice"
    fi
}

get_repo_name() {
    echo $(basename "$PWD")
}

get_repo_deployment() {
    context=$1
    namespace=$2
    repo=$3

    regex_pattern="pageintegrity.azurecr.io/pi-core/$repo:.*"

    deployment=$(
        kubectl --context=$context --namespace=$namespace get deployment -o json |
            jq -r ".items[] | select(.spec.template.spec.containers[0].image | test(\"$regex_pattern\")).metadata.name"
    )

    if [[ -z $deployment ]]; then
        echoerr "No deployment for repo $repo was found"
        exit 1
    fi

    echo $deployment

}

get_deployment_label_selector() {
    context=$1
    namespace=$2
    deployment=$3
    selector_label=$4

    json_path=".spec.selector.matchLabels.$selector_label"
    selector=$(kubectl --context=$context --namespace=$namespace get deploy $deployment -o json | jq -r "$json_path")

    echo $selector
}

start_debugging_session() {
    context=$1
    namespace=$2
    deployment=$3
}

namespace="app"
selector_label="service"

context=$(choose_context_interactive)
repo=$(get_repo_name)
deployment=$(get_repo_deployment $context $namespace $repo)
echo "Deployment $deployment is matching your repo"

selector=$(get_deployment_label_selector $context $namespace $deployment $selector_label)
echo "You deployment selector is: $selector"

devspace print --var SERVICE=$selector
