class CronPriceJob
  include Sidekiq::Worker
  include CronResourceJob
  queue_as :default

  private

  def process_items(failed_products, product_data) # Implement abstract method
    Rails.logger.info("Sincronizando preço do produto: #{product_data['Codigo']}")
    product = PriceService.create_or_update_from_api(product_data)
    process_item(product_data, ->(data) { product }, failed_products, "Codigo")
  end
end
