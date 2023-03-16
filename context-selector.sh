#!/usr/bin/env bash
set -e

echoerr() { echo "$@" 1>&2; }

select_interactive() {
    question=$1
    var=$2
    options="${@:3}"

    image=idogakamai/remote-debugging-tools:0.1
    tmpfile=$(mktemp)

    docker run --rm -it -v $tmpfile:/app/selection.txt $image -q "$question" -o $options
    choice=$(cat $tmpfile)

    if [[ -z $choice ]]; then
        echoerr "No choice has been selected"
        exit 1
    fi

    # Cleanup
    rm $tmpfile

    # Set variable value
    printf -v "$var" "%s" "$choice"
}

get_repo_name() {
    echo $(basename "$PWD")
}

get_repo_deployment() {
    context=$1
    namespace=$2
    repo=$3

    regex_pattern="pageintegrity.azurecr.io/pi-core/$repo:.*"
    json_path='{range .items[*]}{.metadata.name}{"$"}{.spec.template.spec.containers[0].image}{"\n"}{end}'

    # Using grep and cut because we can't rely on jq being installed the users machines
    deployment=$(
        kubectl --context=$context --namespace=$namespace get deployment -o jsonpath="$json_path" |
            grep "$regex_pattern" |
            cut -d "$" -f 1
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

    json_path="{.spec.selector.matchLabels.$selector_label}"
    selector=$(kubectl --context=$context --namespace=$namespace get deploy $deployment -o jsonpath=$json_path)

    echo $selector
}

start_debugging_session() {
    context=$1
    namespace=$2
    deployment=$3
}

NAMESPACE="app"
SELECTOR_LABEL="service"

# Get the cluster name
select_interactive \
    "Please select the cluster to debug" \
    "CONTEXT" \
    $(kubectl config get-contexts -o=name | sort -n | grep -i dev)

REPO=$(get_repo_name)

DEPLOYMENT=$(get_repo_deployment $CONTEXT $NAMESPACE $REPO)
if [[ $DEPLOYMENT =~ " " ]]; then
    echo "More than 1 matching deployment for your repo have been found."
    select_interactive \
        "Please select the one you wish to dubug" \
        "DEPLOYMENT" \
        $DEPLOYMENT
fi

echo "Deployment $DEPLOYMENT is matching your repo"

SELECTOR=$(get_deployment_label_selector $CONTEXT $NAMESPACE $DEPLOYMENT $SELECTOR_LABEL)
echo "You deployment selector is: $SELECTOR"

echo "Starting dev container, run reset-pods.sh in your current directory to resume the deployment."
echo "devspace --kube-context $CONTEXT --namespace $NAMESPACE reset pods" >reset-pods.sh
chmod +x reset-pods.sh

devspace --kube-context $CONTEXT --namespace $NAMESPACE run-pipeline debug --service $SELECTOR
