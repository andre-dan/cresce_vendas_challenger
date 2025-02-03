
class SyncOrdersJob
  include Sidekiq::Worker
  include CronResourceJob # Include the module
  queue_as :default

  private

  def process_items(failed_enqueues) # Implement abstract method (failed_orders will be unused in this case, or can track failed order fetches)
    User.all.each do |user|
      client = RpInfoClient.new(user:, store: nil)
      orders = client.fetch_orders

      if orders.nil?
        Rails.logger.warn("Nenhum pedido encontrado. Verifique a API ou a conexão.")
        return
      end

      Rails.logger.info("Enfileirando #{orders.count} pedidos...")
      orders.each_with_index do |order_data, index|
        Rails.logger.info("Enfileirando pedido #{index + 1}: #{order_data[:transacao]}")
        order_data_strings = order_data.deep_stringify_keys
        begin
          CronOrderJob.perform_async(order_data_strings)
        rescue => e
          failed_enqueues << order_data["transacao"] || "Unknown Product Code" # Capture product code if available
          Rails.logger.error("Erro ao enfileirar CronStockJob para produto (Transação: #{order_data["transacao"] || 'desconhecido'}): #{e.message}")
        end # Still uses perform_async for individual order jobs
      end
    end

    Rails.logger.info("Enfileiramento de jobs para pedidos concluído.")
  end
end
