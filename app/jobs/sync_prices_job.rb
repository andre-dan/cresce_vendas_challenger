# app/jobs/sync_prices_job.rb
class SyncPricesJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_enqueues) # Renamed failed_items to failed_enqueues as this job mainly enqueues
    User.all.each do |user|
      Store.all.each do |store|
        Rails.logger.info("Iniciando busca de produtos para User ID: #{user.id}, Store ID: #{store.id}")
        client = RpInfoClient.new(user: user, store: store)
        products = client.fetch_prices

        if products.nil?
          Rails.logger.warn("Erro ao buscar produtos para User ID: #{user.id}, Store ID: #{store.id}. Verifique a API ou a conexão. Continuando com o próximo.")
          next # Skip to the next store for this user
        end

        if products.empty?
          Rails.logger.warn("Nenhum produto encontrado para User ID: #{user.id}, Store ID: #{store.id}. Continuando com o próximo.")
          next # Skip to the next store for this user
        end

        Rails.logger.info("Enfileirando #{products.count} produtos para User ID: #{user.id}, Store ID: #{store.id}...")
        products.each_with_index do |product_data, index|
          Rails.logger.info("Enfileirando produto #{index + 1}/#{products.count} (Código: #{product_data[:Codigo]}) para User ID: #{user.id}, Store ID: #{store.id}")
          product_data_strings = product_data.deep_stringify_keys
          begin
            CronPriceJob.perform_async(product_data_strings)
          rescue => e
            failed_enqueues << product_data[:Codigo] || "Unknown Product Code"
            Rails.logger.error("Erro ao enfileirar CronPriceJob para produto (Código: #{product_data[:Codigo] || 'desconhecido'}): #{e.message}")
          end
        end
      end
    end
    Rails.logger.info("Enfileiramento de jobs para preços concluído.") # More specific log message
  end
end
