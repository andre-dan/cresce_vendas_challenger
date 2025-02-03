require 'rails_helper'

RSpec.describe RpInfoClient do
  let(:user) { double('User', code: 'test_user', api_credential: 'test_password') }
  let(:store) { double('Store', cnpj: '12345678901234') }
  let(:client) { RpInfoClient.new(user: user, store: store) }
  let(:conn) { client.instance_variable_get(:@conn) }
  let(:circuit_breaker) { client.instance_variable_get(:@circuit_breaker) }

  describe '#initialize' do
    it 'initializes with user and store and sets up Faraday connection and CircuitBreaker' do
      expect(client.instance_variable_get(:@code)).to eq(user.code)
      expect(client.instance_variable_get(:@api_credential)).to eq(user.api_credential)
      expect(client.instance_variable_get(:@cnpj)).to eq(store.cnpj)
      expect(conn).to be_a(Faraday::Connection)
      expect(circuit_breaker).to be_a(CircuitBreaker::CircuitHandler)
    end

    it 'authenticates session on initialization' do
      expect(client).to receive(:authenticate_session!).once
      RpInfoClient.new(user: user, store: store)
    end
  end

  describe '#authenticate_session!' do
    let(:auth_response_success) { double('Response', success?: true, status: 200, body: { response: { token: 'test_token', expiresIn: 3600 } }) }
    let(:auth_response_failure) { double('Response', success?: false, status: 401, body: { error: 'Authentication failed' }) }

    context 'when authentication is successful' do
      it 'sets token and token_expiration' do
        allow(conn).to receive(:post).and_return(auth_response_success)
        client.send(:authenticate_session!)
        expect(client.instance_variable_get(:@token)).to eq('test_token')
        expect(client.instance_variable_get(:@token_expiration)).to be_within(1).of(Time.now + 3600)
      end
    end

    context 'when authentication fails' do
      it 'raises an error' do
        allow(conn).to receive(:post).and_return(auth_response_failure)
        expect { client.send(:authenticate_session!) }.to raise_error("Erro de autenticação: 401")
      end
    end

    context 'when user or password is not provided' do
      it 'raises an error' do
        client_without_user = RpInfoClient.new(user: double('User', code: nil, api_credential: 'test_password'), store: store)
        client_without_password = RpInfoClient.new(user: double('User', code: 'test_user', api_credential: nil), store: store)

        expect { client_without_user.send(:authenticate_session!) }.to raise_error("Erro de autenticação: Usuário ou senha não informados")
        expect { client_without_password.send(:authenticate_session!) }.to raise_error("Erro de autenticação: Usuário ou senha não informados")
      end
    end
  end

  describe '#token_expired?' do
    context 'when token is expired' do
      it 'returns true' do
        client.instance_variable_set(:@token_expiration, Time.now - 3600)
        expect(client.send(:token_expired?)).to be_truthy
      end
    end

    context 'when token is not expired' do
      it 'returns false' do
        client.instance_variable_set(:@token_expiration, Time.now + 3600)
        expect(client.send(:token_expired?)).to be_falsey
      end

      it 'returns false if token_expiration is nil' do
        client.instance_variable_set(:@token_expiration, nil)
        expect(client.send(:token_expired?)).to be_falsey
      end
    end
  end

  describe '#headers' do
    let(:auth_response_success) { double('Response', success?: true, status: 200, body: { response: { token: 'test_token', expiresIn: 3600 } }) }

    it 'returns headers with token and content type' do
      allow(conn).to receive(:post).and_return(auth_response_success)
      client.send(:authenticate_session!)
      headers = client.send(:headers)
      expect(headers).to include("Content-Type" => "application/json", "token" => 'test_token')
    end

    context 'when token is expired' do
      it 'authenticates session again and returns new headers' do
        allow(conn).to receive(:post).and_return(auth_response_success)
        client.instance_variable_set(:@token_expiration, Time.now - 3600)
        expect(client).to receive(:authenticate_session!).once.and_call_original
        client.send(:headers)
      end
    end

    context 'when token is not expired' do
      it 'does not authenticate session again' do
        allow(conn).to receive(:post).and_return(auth_response_success)
        client.instance_variable_set(:@token_expiration, Time.now + 3600)
        client.send(:authenticate_session!) # Initial authentication
        expect(client).not_to receive(:authenticate_session!)
        client.send(:headers)
      end
    end
  end

  describe '#handle_request' do
    let(:successful_response) { double('Response', success?: true, status: 200, body: { key: 'value' }) }
    let(:unsuccessful_response) { double('Response', success?: false, status: 500, body: { error: 'Server error' }) }
    let(:connection_error) { Faraday::ConnectionFailed.new('Connection error') }
    let(:timeout_error) { Faraday::TimeoutError.new('Timeout error') }

    context 'when request is successful' do
      it 'returns response body' do
        allow(conn).to receive(:get).and_return(successful_response)
        response_body = client.send(:handle_request) { conn.get('/test') }
        expect(response_body).to eq({ key: 'value' })
      end
    end

    context 'when request is unsuccessful' do
      it 'raises an error for unsuccessful response' do
        allow(conn).to receive(:get).and_return(unsuccessful_response)
        expect { client.send(:handle_request) { conn.get('/test') } }.to raise_error("Erro na API: 500")
      end
    end

    context 'when connection error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).and_raise(connection_error)
        expect(Rails.logger).to receive(:error).with(/Erro na conexão: Connection error/)
        response_body = client.send(:handle_request) { conn.get('/test') }
        expect(response_body).to be_nil
      end
    end

    context 'when timeout error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).and_raise(timeout_error)
        expect(Rails.logger).to receive(:error).with(/Erro na conexão: Timeout error/)
        response_body = client.send(:handle_request) { conn.get('/test') }
        expect(response_body).to be_nil
      end
    end
  end

  describe '#circuit_breaker_execute' do
    it 'executes the block within the circuit breaker' do
      expect(circuit_breaker).to receive(:run).and_yield
      block = -> { 'block result' }
      expect(client.send(:circuit_breaker_execute, &block)).to eq('block result')
    end

    context 'when CircuitBreaker::OpenCircuitError is raised' do
      it 'logs a warning and returns nil' do
        allow(circuit_breaker).to receive(:run).and_raise(CircuitBreaker::OpenCircuitError, 'Circuit is open')
        expect(Rails.logger).to receive(:warn).with(/Circuito Aberto: Circuit is open. Retornando valor padrão ou nulo./)
        expect(client.send(:circuit_breaker_execute) { }).to be_nil
      end
    end
  end

  describe '#fetch_products' do
    let(:headers) { { "Content-Type" => "application/json", "token" => 'test_token' } }
    let(:product1) { { codigo: 1, nome: 'Product 1' } }
    let(:product2) { { codigo: 2, nome: 'Product 2' } }
    let(:products_response_page1) { double('Response', success?: true, status: 200, body: { produtos: [ product1 ] }) }
    let(:products_response_page2) { double('Response', success?: true, status: 200, body: { produtos: [ product2 ] }) }
    let(:empty_products_response) { double('Response', success?: true, status: 200, body: { produtos: [] }) }
    let(:error_response) { double('Response', success?: false, status: 500, body: { error: 'Server error' }) }

    before do
      allow(client).to receive(:headers).and_return(headers)
      allow(client).to receive(:handle_request).and_call_original # Ensure handle_request is used
      allow(circuit_breaker).to receive(:run).and_yield # Mock circuit breaker
    end

    context 'when products are fetched successfully in multiple pages' do
      it 'fetches and returns all products' do
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/0", headers).and_return(products_response_page1)
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/1", headers).and_return(products_response_page2)
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/2", headers).and_return(empty_products_response)

        products = client.fetch_products
        expect(products).to eq([ product1, product2 ])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 2/)
      end
    end

    context 'when no products are returned' do
      it 'returns empty array' do
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/0", headers).and_return(empty_products_response)
        products = client.fetch_products
        expect(products).to eq([])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 0/)
      end
    end

    context 'when API returns an error' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/0", headers).and_return(error_response)
        allow(client).to receive(:handle_request).and_raise("Erro na API: 500") # Mock handle_request to raise error

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar produtos \(RuntimeError\): Erro na API: 500/)
        expect(client.fetch_products).to be_nil
      end
    end

    context 'when connection error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.1/produto/listaprodutos/0", headers).and_raise(Faraday::ConnectionFailed.new("Connection error"))

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar produtos \(Faraday::ConnectionFailed\): Connection error/)
        expect(client.fetch_products).to be_nil
      end
    end
  end

  describe '#fetch_stocks' do
    let(:headers) { { "Content-Type" => "application/json", "token" => 'test_token' } }
    let(:stock1) { { codigo: 1, estoqueDisponivel: 10 } }
    let(:stock2) { { codigo: 2, estoqueDisponivel: 5 } }
    let(:stocks_response_success) { double('Response', success?: true, status: 200, body: { response: { produtos: [ stock1, stock2 ] } }) }
    let(:empty_stocks_response) { double('Response', success?: true, status: 200, body: { response: { produtos: [] } }) }
    let(:invalid_stocks_response) { double('Response', success?: true, status: 200, body: { response: { produtos: [ { codigo: nil, estoqueDisponivel: 10 } ] } }) }
    let(:error_response) { double('Response', success?: false, status: 500, body: { error: 'Server error' }) }

    before do
      allow(client).to receive(:headers).and_return(headers)
      allow(client).to receive(:handle_request).and_call_original
      allow(circuit_breaker).to receive(:run).and_yield
      allow(ProductService).to receive(:format_product_codes).and_return("1,2") # Mock ProductService
    end

    context 'when stocks are fetched successfully' do
      it 'fetches and returns stocks' do
        allow(conn).to receive(:get).with("/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=1,2", headers).and_return(stocks_response_success)

        stocks = client.fetch_stocks
        expect(stocks).to eq([ stock1, stock2 ])
        expect(Rails.logger).to receive(:debug).with(/Dados de estoque recebidos: 2/)
      end
    end

    context 'when no stocks are returned' do
      it 'returns empty array' do
        allow(conn).to receive(:get).with("/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=1,2", headers).and_return(empty_stocks_response)
        stocks = client.fetch_stocks
        expect(stocks).to be_empty
        expect(Rails.logger).to receive(:debug).with(/Dados de estoque recebidos: 0/)
      end
    end

    context 'when API returns an error' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=1,2", headers).and_return(error_response)
        allow(client).to receive(:handle_request).and_raise("Erro na API: 500")

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar estoque: Erro na API: 500/)
        expect(client.fetch_stocks).to be_nil
      end
    end

    context 'when connection error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=1,2", headers).and_raise(Faraday::ConnectionFailed.new("Connection error"))

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar estoque: Connection error/)
        expect(client.fetch_stocks).to be_nil
      end
    end

    context 'when API returns invalid stock data' do
      it 'logs error and returns nil if stocks data is invalid' do
        allow(conn).to receive(:get).with("/v1.0/produtounidade/unidade/#{@cnpj}/estoquedisponivel?codigos=1,2", headers).and_return(invalid_stocks_response)
        expect(Rails.logger).to receive(:error).with(/Resposta da API de estoque inválida: {:response=>{:produtos=>\[{:codigo=>nil, :estoqueDisponivel=>10}\]}}/)
        stocks = client.fetch_stocks
        expect(stocks).to be_nil
      end
    end
  end

  describe '#fetch_prices' do
    let(:headers) { { "Content-Type" => "application/json", "token" => 'test_token' } }
    let(:price1) { { Codigo: 1, PrecoVenda: 25.00 } }
    let(:price2) { { Codigo: 2, PrecoVenda: 50.00 } }
    let(:prices_response_page1) { double('Response', success?: true, status: 200, body: { response: { produtos: [ price1 ] } }) }
    let(:prices_response_page2) { double('Response', success?: true, status: 200, body: { response: { produtos: [ price2 ] } }) }
    let(:empty_prices_response) { double('Response', success?: true, status: 200, body: { response: { produtos: [] } }) }
    let(:error_response) { double('Response', success?: false, status: 500, body: { error: 'Server error' }) }

    before do
      allow(client).to receive(:headers).and_return(headers)
      allow(client).to receive(:handle_request).and_call_original
      allow(circuit_breaker).to receive(:run).and_yield
    end

    context 'when prices are fetched successfully in multiple pages' do
      it 'fetches and returns all prices' do
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/0/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_return(prices_response_page1)
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/1/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_return(prices_response_page2)
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/2/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_return(empty_prices_response)

        prices = client.fetch_prices
        expect(prices).to eq([ price1, price2 ])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 2/)
      end
    end

    context 'when no prices are returned' do
      it 'returns empty array' do
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/0/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_return(empty_prices_response)
        prices = client.fetch_prices
        expect(prices).to eq([])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 0/)
      end
    end

    context 'when API returns an error' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/0/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_return(error_response)
        allow(client).to receive(:handle_request).and_raise("Erro na API: 500")

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar estoque: Erro na API: 500/)
        expect(client.fetch_prices).to be_nil # Corrected expectation to be nil, as per method return on error
      end
    end

    context 'when connection error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v2.9/produtounidade/listaprodutos/0/unidade/#{@cnpj}/detalhado/ativos?outrosextras=false&loadtributacao=false&considerarcancelados=false&somentePreco2=false", headers).and_raise(Faraday::ConnectionFailed.new("Connection error"))

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar estoque: Connection error/)
        expect(client.fetch_prices).to be_nil # Corrected expectation to be nil, as per method return on error
      end
    end
  end


  describe '#fetch_orders' do
    let(:headers) { { "Content-Type" => "application/json", "token" => 'test_token' } }
    let(:order1) { { idPedido: 1, itens: [ { codigoProduto: 10 } ] } }
    let(:order2) { { idPedido: 2, itens: [ { codigoProduto: 20 } ] } }
    let(:orders_response_page1) { double('Response', success?: true, status: 200, body: { response: { pedidos: [ order1 ] } }) }
    let(:orders_response_page2) { double('Response', success?: true, status: 200, body: { response: { pedidos: [ order2 ] } }) }
    let(:empty_orders_response) { double('Response', success?: true, status: 200, body: { response: { pedidos: [] } }) }
    let(:error_response) { double('Response', success?: false, status: 500, body: { error: 'Server error' }) }

    before do
      allow(client).to receive(:headers).and_return(headers)
      allow(client).to receive(:handle_request).and_call_original
      allow(circuit_breaker).to receive(:run).and_yield
    end

    context 'when orders are fetched successfully in multiple pages' do
      it 'fetches and returns all orders' do
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/0?loadItens=true", headers).and_return(orders_response_page1)
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/10?loadItens=true", headers).and_return(orders_response_page2)
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/20?loadItens=true", headers).and_return(empty_orders_response)


        orders = client.fetch_orders
        expect(orders).to eq([ order1, order2 ])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 2/) # Log message is about products, should be orders or items
      end
    end

    context 'when no orders are returned' do
      it 'returns empty array' do
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/0?loadItens=true", headers).and_return(empty_orders_response)
        orders = client.fetch_orders
        expect(orders).to eq([])
        expect(Rails.logger).to receive(:debug).with(/Total de produtos recebidos: 0/) # Log message is about products, should be orders or items
      end
    end

    context 'when API returns an error' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/0?loadItens=true", headers).and_return(error_response)
        allow(client).to receive(:handle_request).and_raise("Erro na API: 500")

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar produtos \(RuntimeError\): Erro na API: 500/)
        expect(client.fetch_orders).to be_nil
      end
    end

    context 'when connection error occurs' do
      it 'logs error and returns nil' do
        allow(conn).to receive(:get).with("/v1.3/pedidos/listapedidos/0?loadItens=true", headers).and_raise(Faraday::ConnectionFailed.new("Connection error"))

        expect(Rails.logger).to receive(:error).with(/Erro ao buscar produtos \(Faraday::ConnectionFailed\): Connection error/)
        expect(client.fetch_orders).to be_nil
      end
    end
  end
end
