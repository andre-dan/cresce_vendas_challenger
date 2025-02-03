# app/jobs/cron_stock_job.rb
class CronStockJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_stocks, stock_data)
    Rails.logger.info("Iniciando importação do estoque: #{stock_data['codigo']}")
    stock = ProductService.set_stock_per_product(stock_data)
    process_item(stock_data, ->(data) { stock }, failed_stocks, "codigo")
  end
end
