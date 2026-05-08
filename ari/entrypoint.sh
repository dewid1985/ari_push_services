#!/bin/bash

set -e

mix deps.get
mix deps.compile
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

exec mix phx.server
