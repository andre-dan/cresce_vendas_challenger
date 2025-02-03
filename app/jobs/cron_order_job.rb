class CronOrderJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  def perform(order_data)
    begin
      Rails.logger.info("Iniciando importação do pedido: #{order_data['transacao']}")

      order = OrderService.create_or_update_from_api(order_data)

      if order.save!
        Rails.logger.info("Pedido #{order_data['transacao']} importado/atualizado com sucesso.")
      else
        Rails.logger.error("Erro ao salvar/atualizar pedido #{order_data['transacao']}: #{order.errors.full_messages.join(', ')}")
      end

    rescue => e
      Rails.logger.error("Erro ao importar/atualizar pedido #{order_data['transacao']}: #{e.message}")
    end
  end
end
