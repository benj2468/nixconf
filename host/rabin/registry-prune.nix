{ pkgs, ... }:
let
  registryUrl = "http://localhost:5001";

  # Prunes tags containing "dev" that are older than one week from the local
  # Docker registry, then garbage-collects the now-unreferenced blobs.
  #
  # "Age" is taken from each image's config blob `.created` timestamp (i.e. when
  # the image was built), which for CI-built dev images tracks the push time
  # closely enough.
  pruneScript = pkgs.writeShellApplication {
    name = "registry-prune-dev";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.podman pkgs.coreutils ];
    text = ''
      REGISTRY="${registryUrl}"
      MAX_AGE=$(( 7 * 24 * 60 * 60 ))   # one week, in seconds
      NOW=$(date +%s)
      ACCEPT="Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json"

      deleted=0

      while IFS= read -r repo; do
        [ -n "$repo" ] || continue

        while IFS= read -r tag; do
          [ -n "$tag" ] || continue

          # Only consider tags mentioning "dev".
          case "$tag" in
            *dev*) ;;
            *) continue ;;
          esac

          # Content digest of the manifest, needed to delete it.
          headers=$(curl -fsSI -H "$ACCEPT" "$REGISTRY/v2/$repo/manifests/$tag" || true)
          digest=$(printf '%s' "$headers" | grep -i '^docker-content-digest:' | awk '{print $2}' | tr -d '\r' || true)
          [ -n "$digest" ] || continue

          manifest=$(curl -fsS -H "$ACCEPT" "$REGISTRY/v2/$repo/manifests/$tag" || true)
          [ -n "$manifest" ] || continue

          # A multi-arch index has no `.config`; follow its first child manifest.
          config_digest=$(printf '%s' "$manifest" | jq -r '.config.digest // empty')
          if [ -z "$config_digest" ]; then
            child=$(printf '%s' "$manifest" | jq -r '.manifests[0].digest // empty')
            [ -n "$child" ] || continue
            child_manifest=$(curl -fsS -H "$ACCEPT" "$REGISTRY/v2/$repo/manifests/$child" || true)
            config_digest=$(printf '%s' "$child_manifest" | jq -r '.config.digest // empty')
          fi
          [ -n "$config_digest" ] || continue

          created=$(curl -fsS -H "$ACCEPT" "$REGISTRY/v2/$repo/blobs/$config_digest" | jq -r '.created // empty' || true)
          [ -n "$created" ] || continue

          created_epoch=$(date -d "$created" +%s 2>/dev/null || echo 0)
          [ "$created_epoch" -gt 0 ] || continue

          age=$(( NOW - created_epoch ))
          if [ "$age" -gt "$MAX_AGE" ]; then
            echo "Pruning $repo:$tag (age $(( age / 86400 ))d, digest $digest)"
            if curl -fsS -X DELETE "$REGISTRY/v2/$repo/manifests/$digest"; then
              deleted=$(( deleted + 1 ))
            else
              echo "  failed to delete $repo:$tag" >&2
            fi
          fi
        done < <(curl -fsS "$REGISTRY/v2/$repo/tags/list" | jq -r '.tags[]?')
      done < <(curl -fsS "$REGISTRY/v2/_catalog" | jq -r '.repositories[]?')

      echo "Deleted $deleted manifest(s); running garbage collection."

      # registry 3.x ships its config at /etc/distribution/config.yml; fall back
      # to the 2.x path just in case the image is ever pinned back.
      config=/etc/distribution/config.yml
      podman exec registry test -f "$config" || config=/etc/docker/registry/config.yml
      podman exec registry registry garbage-collect "$config"
    '';
  };
in
{
  # Manifest deletion via the registry API is off by default; the prune job
  # needs it enabled to remove old dev tags.
  virtualisation.oci-containers.containers.registry.environment.REGISTRY_STORAGE_DELETE_ENABLED = "true";

  systemd.services.registry-prune-dev = {
    description = "Prune old dev-tagged images from the Docker registry";
    after = [ "podman-registry.service" ];
    requires = [ "podman-registry.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pruneScript}/bin/registry-prune-dev";
    };
  };

  systemd.timers.registry-prune-dev = {
    description = "Nightly prune of old dev-tagged registry images";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Midnight, Los Angeles time (Pacific).
      OnCalendar = "*-*-* 00:00:00 America/Los_Angeles";
      Persistent = true;
    };
  };
}
