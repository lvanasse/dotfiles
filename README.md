# Dotfiles Nix Flake

This repository contains NixOS configurations and Home Manager setups
maintained as a flake. Two hosts are provided:

- `pc`
- `laptop`

## Prerequisites

- Nix 2.4 or later with flakes enabled

## Building

Switch the system configuration on the target machine with:

```bash
nh os switch -H pc
```

or for the laptop:

```bash
nh os switch -H pc
```

The Home Manager configuration can be applied separately:

```bash
home-manager switch --flake .#ludovic@pc
```

or

```bash
home-manager switch --flake .#ludovic@laptop
```

## Repository Layout

- `hosts/` – machine-specific NixOS modules
- `home/` – Home Manager modules
- `modules/` – common NixOS module code
- `flake.nix` – flake entrypoint
