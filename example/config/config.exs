import Config

if config_env() == :dev do
  config :francis, watcher: true
end
