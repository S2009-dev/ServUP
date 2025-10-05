<!-- ###############################################
# ServUP  Copyright (C) 2025  S2009                #
# LICENSE: GPL-3.0                                 #
# Source Code: https://github.com/S2009-dev/ServUP #
#################################################### -->

# <center>[![ServUp Banner](./src/logo.png)](.)</center>

![GitHub Release](https://img.shields.io/github/v/release/S2009-dev/ServUP)
![GitHub last commit](https://img.shields.io/github/last-commit/S2009-dev/ServUP)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/S2009-dev/ServUP/total)
![GitHub forks](https://img.shields.io/github/forks/S2009-dev/ServUP)
![GitHub Repo stars](https://img.shields.io/github/stars/S2009-dev/ServUP)

## About

ServUP is a lightweight, open-source, and easy-to-use deployment tool designed to simplify the process of deploying artifact from GitHub Actions to remote servers. It provides a simple and efficient way to manage your deployments, ensuring that your applications are always up-to-date and running.

### Index

- [About](#about)
  - [Index](#index)
  - [Features](#features)
- [Installation](#installation)
  - [Server Configuration](#server-configuration)
  - [Repository Configuration](#repository-configuration)
- [Annexes](#annexes)
  - [Iptables Support](#iptables-support)
  - [Get a GitHub Token](#get-a-github-token)

### Features

ServUP uses SSH to securely transfer files from your GitHub Actions workflow to your remote server.

## Installation

In order to work with ServUP, you need to do some configuration on your server and your GitHub repository.

### Server Configuration

Install ServUP on your server via the command-line with curl:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/S2009-dev/ServUP/main/tools/install.sh)"
```

This will create a `servup` user on your server and open a specific port for SSH connections (`1424` by default).  
Ensure that you've copied the ServUP SSH Key given at the end of installation.

If you have a firewall, make sure to open the port given at the end of installation.  
You can trust only GitHub Actions IPs, they are listed in the `actions` section of the [GitHub meta API](https://api.github.com/meta).  
We provide a script to help you configure your firewall if you are using `iptables` or `ip6tables`. See [Iptables Support](#iptables-support) for more information.

### Repository Configuration

**1. Add the following secrets to your GitHub repository:**

- `GH_TOKEN`: A GitHub token with the `actions:read` permission.
- `SSH_HOST`: The IP address or domain name of your server.
- `SSH_PORT`: The port used by ServUP for SSH connections (default: `1424`).
- `SSH_PRIVATE_KEY`: The private key of the `servup` user on your server.

**2. Implement the ServUP Deployment workflow:**  
:warning: The documentation is not yet available.

## Annexes

Here you will find additional tools and resources to help you use ServUP effectively.

### Iptables Support

If you are using `iptables` or `ip6tables` as your firewall, you can use the following command to open the ServUP SSH port:

```sh
servup-firewall
```

Or if it's not working:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/S2009-dev/ServUP/main/tools/firewall.sh)"
```

### Get a GitHub Token

To get a GitHub token for ServUP, follow these steps:

- Go to [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)
- Choose a name for your token (e.g., `ServUP`).
- Add a description (optionnal, e.g., `ServUP Deployment Token`).
- Set the resource owner to your account or organization.
- Choose the expiration date (recommended: `90 days`).
- Set the repository access to `All repositories`.
- Click on `Add permissions` and check `Actions`.
- Click on `Generate token`.
- Copy the token and save it in a secure place.
