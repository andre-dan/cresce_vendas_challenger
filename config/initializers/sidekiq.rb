require "sidekiq/web"

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/0" } # Substitua pela sua URL do Redis
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/0" } # Substitua pela sua URL do Redis
end

# Configuração de autenticação (opcional, mas recomendado para o Sidekiq Web UI)
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [ user, password ] == [ "seu_usuario", "sua_senha" ] # Substitua por suas credenciais
end

# Carrega os jobs cron (se você usar um arquivo separado, como config/schedule_cron_jobs.rb)
Dir[Rails.root.join("config", "schedule_*.rb")].each { |file| require file }
