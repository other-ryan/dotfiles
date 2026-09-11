# 🐑 herdr aliases and functions

function _herdr_machine_remove () {
    # removes a herdr machine.
    # params:
    #     $1 - target machine's label (e.g. from herdr machine --label {LABEL})

    local machine_label="${1}"
    local machine_id=$(herdr machine list --json | jq -r ".[] | select(.label == \"${machine_label}\") | .id")
    herdr machine remove "${machine_id}"
}

function _herdr_machine_add () {
    # adds a herdr machine.
    # params:
    #     $1 - target machine's hostname
    #     $2 - target machine's label (optional, defaults to machine name)
    local machine_name="${1}"
    local machine_label="${2:-${machine_name}}"
    herdr machine add "${machine_name}" --label "${machine_label}"
}

function herdr () {
    case "$1" in
        rm)
            _herdr_machine_remove "$2"
            ;;
        add)
            shift
            _herdr_machine_add "$@"
            ;;
        *)
            command herdr "$@"
            ;;
    esac
}
