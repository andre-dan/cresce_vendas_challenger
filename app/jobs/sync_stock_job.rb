# app/jobs/sync_stock_job.rb
class SyncStockJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_enqueues)
    User.all.each do |user|
      Store.all.each do |store|
        Rails.logger.info("Iniciando busca de estoque para User ID: #{user.id}, Store ID: #{store.id}")
        client = RpInfoClient.new(user:, store:)
        stocks = client.fetch_stocks

        if stocks.nil?
          Rails.logger.warn("Erro ao buscar estoque para User ID: #{user.id}, Store ID: #{store.id}. Verifique a API ou a conexão. Continuando com o próximo.")
          next
        end

        if stocks.empty?
          Rails.logger.warn("Nenhum estoque encontrado no Usuário ID: #{user.id}, na Loja: #{store.id}. Continuando com o próximo.")
          next
        end

        Rails.logger.info("Enfileirando jobs de estoque para #{stocks.count} produtos para User ID: #{user.id}, Store ID: #{store.id}...")
        stocks.each_with_index do |stock_info, index|
          Rails.logger.info("Enfileirando job de estoque #{index + 1}/#{stocks.count} (Código: #{stock_info[:codigo]}) para User ID: #{user.id}, Store ID: #{store.id}")
          stock_info_strings = stock_info.deep_stringify_keys
          begin
            CronStockJob.perform_async(stock_info_strings)
          rescue => e
            failed_enqueues << stock_info[:codigo] || "Unknown Product Code"
            Rails.logger.error("Erro ao enfileirar CronStockJob para produto (Código: #{stock_info[:codigo] || 'desconhecido'}): #{e.message}")
          end
        end
      end
    end
    Rails.logger.info("Enfileiramento de jobs para estoque concluído.")
  end
end
