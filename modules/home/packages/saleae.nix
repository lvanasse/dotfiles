{ ... }:
{
  flake.modules.homeManager."packages.saleae" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ruleName = "99-SaleaeLogic.rules";
      rulePath = ".local/share/udev/rules.d/${ruleName}";
      homeRule = "${config.home.homeDirectory}/${rulePath}";
      systemRule = "/etc/udev/rules.d/${ruleName}";
      installCommand = "cat \"${homeRule}\" | sudo tee \"${systemRule}\" > /dev/null && echo \"finished installing ${systemRule}\"";
    in
    {
      home.file.${rulePath}.source = "${pkgs.saleae-logic-2}/etc/udev/rules.d/${ruleName}";

      home.activation.installSaleaeUdevRules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if [ -e "${systemRule}" ] && ${pkgs.diffutils}/bin/cmp -s "${homeRule}" "${systemRule}"; then
                  :
                elif [ -w /etc/udev/rules.d ] || { [ -e "${systemRule}" ] && [ -w "${systemRule}" ]; }; then
                  ${pkgs.coreutils}/bin/install -D -m 0644 "${homeRule}" "${systemRule}"
                  if command -v udevadm >/dev/null 2>&1; then
                    udevadm control --reload-rules || true
                    udevadm trigger || true
                  fi
                else
                  cat <<EOF
        Saleae udev rule is managed by Home Manager but needs root to install:
          ${installCommand}
          sudo udevadm control --reload-rules
          sudo udevadm trigger
        EOF
                fi
      '';
    };
}
