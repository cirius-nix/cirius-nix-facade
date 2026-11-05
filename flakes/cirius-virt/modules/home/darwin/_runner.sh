# Docker Desktop owns the VM and daemon. Never start or stop it from activation.
if [ ! -x "$docker" ]; then
  echo "Docker Desktop CLI not found at $docker" >&2
  exit 1
fi
if ! "$docker" --context "$context" info >/dev/null 2>&1; then
  echo "Start Docker Desktop and check context '$context' with docker context ls." >&2
  exit 1
fi
action=${1:-up}
if [ "$#" -gt 0 ]; then shift; fi
if [ "$#" -gt 0 ]; then
  echo "Usage: cnix-containers [up|down|logs|ps|config|build]" >&2
  exit 1
fi
case "$action" in
  up|build) ;;
  down|logs|ps|config)
    if [ ! -s "$state/runtime.env" ]; then
      echo "Run cnix-containers up once to prepare the runtime env file." >&2
      exit 1
    fi
    ;;
  *) echo "Usage: cnix-containers [up|down|logs|ps|config|build]" >&2; exit 1 ;;
esac
if [ "$action" = up ] || [ "$action" = build ]; then
  umask 077
  mkdir -p "$state"
  chmod 700 "$state"
  if [ ! -e "$state/runtime.env" ]; then
    temporary=$(mktemp "$state/runtime.env.XXXXXX")
    trap 'rm -f "$temporary"' EXIT
    {
      printf 'DOOP_AUTH_SECRET=%s\n' "$(openssl rand -hex 32)"
      printf 'DOOP_ENCRYPTION_KEYS=k1:%s\n' "$(openssl rand -base64 32)"
      printf 'PENPOT_SECRET_KEY=%s\n' "$(openssl rand -hex 32)"
      printf 'PENPOT_DATABASE_PASSWORD=%s\n' "$(openssl rand -hex 32)"
      printf 'DOCKHAND_DATABASE_PASSWORD=%s\n' "$(openssl rand -hex 32)"
    } > "$temporary"
    # Link without replacing an env file created by another invocation.
    if ! ln "$temporary" "$state/runtime.env"; then
      test -s "$state/runtime.env"
    fi
    rm -f "$temporary"
    trap - EXIT
  fi
fi
compose() {
  "$docker" --context "$context" compose --project-name cirius \
    --env-file "$state/runtime.env" --file "$compose_file" "$@"
}
case "$action" in
  up)
    if compose config --services | grep -qx doop; then
      if ! "$docker" --context "$context" image inspect cirius-doop:0.13.0 >/dev/null 2>&1; then
        compose build doop
      fi
    fi
    compose up -d
    ;;
  down) compose down ;; # Named volumes and runtime secrets remain intact.
  logs) compose logs --tail 100 --follow ;;
  ps) compose ps ;;
  config) compose config --quiet ;; # Do not print interpolated secrets.
  build) compose build ;;
esac
