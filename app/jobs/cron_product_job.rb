# app/jobs/cron_product_job.rb
class CronProductJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_products, product_data)
    Rails.logger.info("Iniciando importação do produto: #{product_data['codigo']}")
    product = ProductService.create_or_update_from_api(product_data)
    process_item(product_data, ->(data) { product }, failed_products, "codigo")
  end
end
