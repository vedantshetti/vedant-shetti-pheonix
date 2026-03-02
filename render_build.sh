#!/usr/bin/env bash
set -euo pipefail

mix local.hex --force
mix local.rebar --force
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
