#!/bin/bash


mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

exec mix phx.server