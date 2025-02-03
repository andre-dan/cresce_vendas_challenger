require "faraday"
require "json"
require "circuit_breaker"

class RpInfoClient
  BASE_URL = "http://servicosflex.rpinfo.com.br:9000"
  AUTH_PATH = "/v1.1/auth"

  def initialize(user:, store:)
    # Adicionando usuario e senha como argumentos
    @code = user.code # Armazenando usuario
    @api_credential = user.api_credential# Armazenando senha
    @cnpj = store.cnpj if store
    @conn = Faraday.new(url: BASE_URL) do |faraday|
    faraday.request :retry, max: 3, interval: 0.5, interval_randomness: 0.5
    faraday.request :json
    faraday.response :json, parser_options: { symbolize_names: true }
    faraday.adapter Faraday.default_adapter
    end

    @circuit_breaker = CircuitBreaker::CircuitHandler.new(
      failure_threshold: 5,
      recovery_timeout: 10,

      on_circuit_open: -> { Rails.logger.warn("Circuito aberto para RpInfo API") },
      on_circuit_close: -> { Rails.logger.info("Circuito fechado para RpInfo API") },
      on_circuit_half_open: -> { Rails.logger.info("Circuito em half-open para RpInfo API") }
    )
    authenticate_session!
  end

  def fetch_products
    all_products = []
    last_id = 0

    begin
      loop do
        url = "/v1.1/produto/listaprodutos/#{last_id}"
        products = handle_request { @conn.get(url, headers)  }
        products = products.dig(:produtos)
        break if products.nil? || products.empty?

        all_products.concat(products)
        last_id = products.last[:codigo]
      end

      Rails.logger.debug("Total de produtos recebidos: #{all_products.count}")
      all_products

    rescue => e
      Rails.logger.error("Erro ao buscar produtos (#{e.class}): #{e.message}")
      Rails.logger.error("Resposta da API: #{response.body}") if defined?(response) && response.respond_to?(:body)
      nil
    end
  end

  def fetch_stocks
    begin
      formatted_codes = ProductService.format_product_codes
      url = "/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=#{formatted_codes}"
      stocks_data = handle_request { @conn.get(url, headers) }
      stocks = stocks_data.dig(:response, :produtos).reject! { |item| item[:codigo].nil? }
      if stocks.nil?
        Rails.logger.error("Resposta da API de estoque inválida: #{stocks_data.inspect}")
        return nil
      end

      Rails.logger.debug("Dados de estoque recebidos: #{stocks.count}")
      stocks

    rescue => e
      Rails.logger.error("Erro ao buscar estoque: #{e.message}")
      nil
    end
  end

  def fetch_prices
    all_products = []
    last_id = 0

    begin
      loop do
        url = "/v2.9/produtounidade/listaprodutos/#{last_id}/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false" # URL correta para estoque
        products = handle_request { @conn.get(url, headers)  }
        products = products.dig(:response, :produtos)
        break if products.nil? || products.empty?

        all_products.concat(products)
        last_id = products.last[:Codigo]
      end

      Rails.logger.debug("Total de produtos recebidos: #{all_products.count}")
      all_products

    rescue => e
      Rails.logger.error("Erro ao buscar estoque: #{e.message}")
      nil
    end
  end

  def fetch_orders
    all_products = []
    last_id = 0

    begin
      loop do
        url = "/v1.3/pedidos/listapedidos/#{last_id}?loadItens=true"
        products = handle_request { @conn.get(url, headers) }
        products = products.dig(:response, :pedidos)

        break if products.nil? || products.empty?

        all_products.concat(products)
        last_id = products.last[:itens].last[:codigoProduto]
      end

      Rails.logger.debug("Total de produtos recebidos: #{all_products.count}")
      all_products


    rescue => e
      Rails.logger.error("Erro ao buscar produtos (#{e.class}): #{e.message}")
      Rails.logger.error("Resposta da API: #{response.body}") if defined?(response) && response.respond_to?(:body)
      nil
    end
  end

  private

  def circuit_breaker_execute(&block)
    @circuit_breaker.run { block.call }
  rescue CircuitBreaker::OpenCircuitError => e
    Rails.logger.warn("Circuito Aberto: #{e.message}. Retornando valor padrão ou nulo.")
    nil
  end

  def authenticate_session!
    raise "Erro de autenticação: Usuário ou senha não informados" if @code.nil? || @api_credential.nil?

    payload = { "usuario": @code, "senha": @api_credential }.to_json
    response = @conn.post("#{AUTH_PATH}", payload, { "Content-Type" => "application/json" })
    raise "Erro de autenticação: #{response.status}" unless response.success?

    auth_data = response.body[:response]
    @token = auth_data[:token]
    @token_expiration = Time.now + auth_data[:expiresIn] if auth_data[:expiresIn]
  end

  def token_expired?
    @token_expiration && Time.now >= @token_expiration
  end

  def headers
    authenticate_session! if token_expired?
    { "Content-Type" => "application/json", "token" => @token }
  end

  def handle_request
    response = yield
    raise "Erro na API: #{response.status}" unless response.success?

    response.body
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.error "Erro na conexão: #{e.message}"
    nil
  end
end
