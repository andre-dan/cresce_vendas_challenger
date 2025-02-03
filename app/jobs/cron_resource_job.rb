# module job_with_standard_error_handling.rb
module CronResourceJob
  def perform(*args)
    failed_items = []

    begin
      Rails.logger.info("Iniciando job: #{self.class.name}")
      process_items(failed_items, *args)
      Rails.logger.info("Job concluído: #{self.class.name}")
    rescue => e
      Rails.logger.error("Erro geral no job #{self.class.name}: #{e.message}")
    end

    log_failed_items(failed_items)
  end

  private

  def process_items(failed_items, *args)
    raise NotImplementedError, "process_items deve ser implementado na classe que incluir este módulo"
  end

  def process_item(item_data, processing_logic, failed_items, item_identifier_key)
    begin
      item = processing_logic.call(item_data)

      if item.respond_to?(:save!)
        if item.save!
          Rails.logger.info("Item processado com sucesso: #{item_data[item_identifier_key]}")
        else
          failed_items << item_data[item_identifier_key]
          Rails.logger.error("Erro ao salvar/atualizar item #{item_data[item_identifier_key]}: #{item.errors.full_messages.join(', ')}")
        end
      else
        Rails.logger.info("Item processado com sucesso: #{item_data[item_identifier_key]}")
      end

    rescue => e
      failed_items << item_data[item_identifier_key]
      Rails.logger.error("Erro ao processar item #{item_data[item_identifier_key]}: #{e.message}")
    end
  end

  def log_failed_items(failed_items)
    if failed_items.present?
      Rails.logger.error("Falha ao processar os seguintes itens: #{failed_items.join(', ')}")
    end
  end
end
