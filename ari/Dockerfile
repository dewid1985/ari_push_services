FROM elixir:1.14-alpine

# Установить необходимые зависимости
RUN apk add --no-cache build-base nodejs npm git inotify-tools bash postgresql-client

# Установить переменные окружения для Erlang
ENV ERL_MAXIMUM_ERL_MEMORY=2G
ENV MIX_ENV=dev

WORKDIR /app

# Копирование файлов конфигурации Mix
COPY mix.exs mix.lock ./
COPY entrypoint.sh ./
COPY config config

# Установка Hex и зависимостей
RUN mix do local.hex --force, local.rebar --force, deps.get, deps.compile

# Копирование оставшихся файлов
COPY . .

# Опционально: очистка кэша npm
RUN npm cache clean --force || true
RUN rm -rf ./assets/node_modules || true

# Установка зависимостей npm, если необходимо
# RUN npm install --prefix ./assets

# Компиляция проекта
RUN mix compile

# Открыть порт 4000
EXPOSE 4000

# Запуск скрипта entrypoint
CMD ["bash", "/app/entrypoint.sh"]
