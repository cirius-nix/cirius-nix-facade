{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.wolf;
  backend = config.virtualisation.oci-containers.backend;
  socket = if backend == "podman" then "/run/podman/podman.sock" else "/run/docker.sock";
  service = "${backend}-wolf";
  tcpPorts = map (offset: cfg.port + offset) [
    (-5)
    0
    21
  ];
  udpPorts = map (offset: cfg.port + offset) [
    10
    111
    211
  ];
  sunshinePort = config.services.sunshine.settings.port;
  sunshineTCP = map (offset: sunshinePort + offset) [
    (-5)
    0
    1
    21
  ];
  sunshineUDP = map (offset: sunshinePort + offset) [
    9
    10
    11
    13
    21
  ];
in
{
  options.${namespace}.wolf = {
    enable = lib.mkEnableOption "Wolf virtual game-streaming sessions (separate from Sunshine)";
    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/games-on-whales/wolf:stable@sha256:47ce7a0b67ee6645d2c6fefd8fdda7fee49a00e327c39597a04e84a0cd052910";
      description = "Wolf image, pinned to the verified 2026-11-01 stable manifest. Custom images must support embedded audio and the same runtime paths.";
    };
    port = lib.mkOption {
      type = lib.types.ints.between 1029 65324;
      default = 48989;
      description = "HTTP base port; HTTPS -5, RTSP +21, control +10, video +111, audio +211.";
    };
    openFirewall = lib.mkEnableOption "Wolf ports in the host firewall (trusted networks only)";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/wolf";
      description = "Absolute host directory for writable configuration, pairing keys, profiles and app data.";
    };
    renderNode = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/renderD128";
      description = "DRM render node for Wolf; select the intended GPU on multi-GPU hosts.";
    };
    nvidia = {
      enable = lib.mkEnableOption "the NVIDIA userspace driver bundle for Wolf and its child containers";
      driverVolume = lib.mkOption {
        type = lib.types.package;
        default = inputs.wolf-nvidia-vol.lib.mkWolfNvidiaVol {
          inherit pkgs;
          nvidiaPackage = config.hardware.nvidia.package;
          extraLibs = [ pkgs.cudaPackages.cuda_nvrtc.lib ];
        };
        defaultText = lib.literalExpression "a Wolf driver bundle built from hardware.nvidia.package, including libnvrtc";
        description = "Container-compatible /usr/nvidia tree. The default build requires x86_64-linux and KVM.";
      };
      devices = lib.mkOption {
        type = with lib.types; listOf str;
        default = [
          "/dev/nvidia0"
          "/dev/nvidiactl"
          "/dev/nvidia-modeset"
          "/dev/nvidia-uvm"
          "/dev/nvidia-uvm-tools"
          "/dev/nvidia-caps/nvidia-cap1"
          "/dev/nvidia-caps/nvidia-cap2"
        ];
        description = "NVIDIA device nodes passed to Wolf; adjust for the selected GPU and driver.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.match "/[a-zA-Z0-9_./-]+" cfg.dataDir != null && cfg.dataDir != "/";
        message = "cnix-gaming.wolf.dataDir must be an absolute directory without whitespace or mount separators.";
      }
      {
        assertion =
          !config.services.sunshine.enable
          || (
            lib.intersectLists tcpPorts sunshineTCP == [ ] && lib.intersectLists udpPorts sunshineUDP == [ ]
          );
        message = "Wolf ports overlap Sunshine. Choose a different cnix-gaming.wolf.port; Sunshine is not changed automatically.";
      }
      {
        assertion =
          !cfg.nvidia.enable
          || (
            pkgs.stdenv.hostPlatform.system == "x86_64-linux"
            && lib.elem "nvidia" config.services.xserver.videoDrivers
            && config.hardware.nvidia.modesetting.enable
          );
        message = "Wolf NVIDIA support needs x86_64-linux, an existing NVIDIA host driver and hardware.nvidia.modesetting.enable.";
      }
    ];

    boot.kernelModules = [
      "uinput"
      "uhid"
    ]
    ++ lib.optional cfg.nvidia.enable "nvidia_uvm";

    # Do not grant desktop users access to the API or virtual input devices.
    # In particular, this host's Sunshine users may already belong to `input`.
    services.udev.packages = [
      (pkgs.runCommand "wolf-input-rules" { } ''
        install -Dm644 ${./85-wolf.rules} $out/lib/udev/rules.d/85-wolf.rules
      '')
    ];
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 root root -"
      "d /run/wolf 0700 root root -"
      "d /run/wolf-runtime 0700 root root -"
    ];

    virtualisation.oci-containers.containers.wolf = {
      inherit (cfg) image;
      environment = {
        WOLF_HTTP_PORT = toString cfg.port;
        WOLF_HTTPS_PORT = toString (cfg.port - 5);
        WOLF_CONTROL_PORT = toString (cfg.port + 10);
        WOLF_RTSP_SETUP_PORT = toString (cfg.port + 21);
        WOLF_VIDEO_PING_PORT = toString (cfg.port + 111);
        WOLF_AUDIO_PING_PORT = toString (cfg.port + 211);
        WOLF_RENDER_NODE = cfg.renderNode;
        WOLF_DOCKER_SOCKET = "/var/run/docker.sock";
        WOLF_SOCKET_PATH = "/var/run/wolf/wolf.sock";
        XDG_RUNTIME_DIR = "/run/wolf-runtime";
        WOLF_STOP_CONTAINER_ON_EXIT = "TRUE";
      }
      // lib.optionalAttrs cfg.nvidia.enable {
        NVIDIA_DRIVER_VOLUME_NAME = toString cfg.nvidia.driverVolume;
      };
      volumes = [
        "${cfg.dataDir}:/etc/wolf:rw"
        "${socket}:/var/run/docker.sock:rw"
        "/run/wolf:/var/run/wolf:rw"
        "/run/wolf-runtime:/run/wolf-runtime:rw"
        "/dev:/dev:rw"
        "/run/udev:/run/udev:rw"
      ]
      ++ lib.optional cfg.nvidia.enable "${cfg.nvidia.driverVolume}:/usr/nvidia:ro";
      devices = [
        "/dev/dri"
        "/dev/uinput"
        "/dev/uhid"
      ]
      ++ lib.optionals cfg.nvidia.enable cfg.nvidia.devices;
      extraOptions = [
        "--network=host"
        "--ipc=host"
        "--device-cgroup-rule=c 13:* rmw"
      ]
      ++ lib.optional (backend == "podman") "--security-opt=label=disable";
    };

    # OCI enables the chosen engine. Keep its existing backend/socket aliases.
    systemd.services.${service} = {
      requires = [ "${backend}.socket" ];
      after = [
        "${backend}.socket"
        "systemd-tmpfiles-setup.service"
        "systemd-modules-load.service"
      ];
      serviceConfig = {
        TimeoutStartSec = lib.mkForce 900;
        RuntimeDirectoryMode = "0700";
      };
    };
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = tcpPorts;
      allowedUDPPorts = udpPorts;
    };
  };
}
