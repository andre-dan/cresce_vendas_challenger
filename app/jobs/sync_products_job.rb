# app/jobs/sync_products_job.rb
class SyncProductsJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_enqueues)
    User.all.each do |user|
      Rails.logger.info("Iniciando busca de produtos para User ID: #{user.id}")
      client = RpInfoClient.new(user: user, store: nil)
      products = client.fetch_products

      if products.nil?
        Rails.logger.warn("Erro ao buscar produtos para User ID: #{user.id}. Verifique a API ou a conexão. Continuando com o próximo.")
        next
      end

      if products.empty?
        Rails.logger.warn("Nenhum produto encontrado para User ID: #{user.id}. Continuando com o próximo.")
        next
      end

      Rails.logger.info("Enfileirando #{products.count} produtos para User ID: #{user.id}...")
      products.each_with_index do |product_data, index|
        Rails.logger.info("Enfileirando produto #{index + 1}/#{products.count} (Código: #{product_data[:codigo]}) para User ID: #{user.id}")
        product_data_strings = product_data.deep_stringify_keys
        begin
          CronProductJob.perform_async(product_data_strings)
        rescue => e
          failed_enqueues << product_data[:codigo] || "Unknown Product Code"
          Rails.logger.error("Erro ao enfileirar CronProductJob para produto (Código: #{product_data[:codigo] || 'desconhecido'}): #{e.message}")
        end
      end
    end
    Rails.logger.info("Enfileiramento de jobs para produtos concluído.")
  end
end
