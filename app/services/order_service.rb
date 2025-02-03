class OrderService
  def self.create_or_update_from_api(order_data)
    order = Order.find_or_initialize_by(transaction_identifier: order_data["transacao"])

    order.assign_attributes(
      unit: order_data["unidade"],
      origin: order_data["origem"],
      withdrawal_unit: order_data["unidadeRetirada"],
      date: order_data["dataMovimento"] ? Date.strptime(order_data["dataMovimento"], "%d/%m/%Y") : nil,
      client_code: order_data["codigoCliente"],
      payment_method: order_data["formaPagamento"],
      client_order_number: order_data["numeroPedidoCliente"],
      kind: order_data["especie"],
      discount: order_data["desconto"],
      name: order_data["nome"],
      email: order_data["email"],
      cpf: order_data["cpf"],
      rg: order_data["rg"],
      cnpj: order_data["cnpj"],
      state_registration: order_data["inscricaoEstadual"],
      address: order_data["endereco"],
      complement: order_data["complemento"],
      neighborhood: order_data["bairro"],
      city: order_data["cidade"],
      zip_code: order_data["cep"],
      phone: order_data["fone"],
      delivery_turn: order_data["turnoEntrega"],
      expected_date: Date.strptime(order_data["dataPrevista"], "%d/%m/%Y"),
      accessory_expense: order_data["despesaAcessoria"],
      carrier: order_data["transportador"],
      route: order_data["rota"],
      deliverer: order_data["entregador"],
      additional_data: order_data["dados_adicionais"],
      number: order_data["numero"],
      unit_code: order_data["codigoUnidade"],
      loading_number: order_data["numeroCarregamento"],
      status: order_data["status"],
      movement_date: Date.strptime(order_data["dataMovimento"], "%d/%m/%Y"),
      delivery_date: Date.strptime(order_data["dataEntrega"], "%d/%m/%Y"),
      lcto_time: Time.strptime(order_data["horaLcto"], "%H:%M:%S"),
      base_date: Date.strptime(order_data["dataBase"], "%d/%m/%Y"),
      lowering_date: order_data["dataBaixa"] ? Date.strptime(order_data["dataBaixa"], "%d/%m/%Y") : nil,
      seller_code: order_data["codigoVendedor"],
      route_code: order_data["codigoRota"],
      payment_code: order_data["codigoFpgto"],
      observation: order_data["observacao"],
      freight_value: order_data["valorFrete"],
      freight_percentage: order_data["percFrete"],
      discount_value: order_data["valorDesconto"],
      discount_percentage: order_data["percDesconto"],
      additional_expense_value: order_data["valorDespAc"],
      additional_expense_percentage: order_data["percDespAc"],
      commission_value: order_data["valorComissao"],
      lowering_transaction: order_data["transacaoBaixa"],
      coupon_number: order_data["numeroCupom"],
      lowering_pdv_code: order_data["codPDVBaixa"],
      lowering_pdv_unit: order_data["unidadePDVBaixa"],
      delivery_sequence: order_data["seqEntrega"],
      document_code: order_data["codigoDocumento"],
      user_code: order_data["codigoUsuario"],
      kind_code: order_data["codigoEspecie"],
      client_link_code: order_data["codigoVincCliente"],
      consolidated_number: order_data["numeroConsolidado"],
      production_transaction_number: order_data["numeroTransProducao"],
      estimated_date: order_data["dataPrevista"] ? Date.strptime(order_data["dataPrevista"], "%d/%m/%Y") : nil,
      delivery_shift: order_data["turnoEntrega"]
    )
    # Lidando com o array "itens"
    if order_data["itens"].present?
      order_data["itens"].each do |item_data|
        begin
          item = order.items.find_or_create_by(product_code: item_data["codigoProduto"]) do |item|
            item.unit_quantity = item_data["qtdUnitaria"]
            item.package_quantity = item_data["qtdEmbalagem"]
            item.product_value = item_data["valorProduto"]
            item.discount_percentage = item_data["percDesconto"]
            item.flex_product_value = item_data["valorProdFlex"]
            item.discount_value = item_data["valorDesconto"]
            item.increase_value = item_data["valorAcrescimo"]
            item.gross_total_value = item_data["valorBrutoTotal"]
            item.flex_base_value = item_data["valorFlexBase"]
            item.observation = item_data["observacao"]
            item.loading_number = item_data["numeroCarregamento"]
            item.unit_code = item_data["codigoUnidade"]
            item.status = item_data["status"]
            item.product_code = item_data["codigoProduto"]
            item.sequential = item_data["sequencial"]
            item.route_code = item_data["codigoRota"]
            item.movement_date = Date.strptime(item_data["dataMovimento"], "%d/%m/%Y")
            item.lowering_date = Date.strptime(item_data["dataBaixa"], "%d/%m/%Y")
            item.quantity = item_data["qtde"]
            item.package_quantity = item_data["qtdeEmbalagem"]
            item.discount_percentage = item_data["percDesconto"]
            item.total_value = item_data["valorTotal"]
            item.commission_value = item_data["valorComissao"]
            item.original_quantity = item_data["qtdeOriginal"]
            item.sale_price = item_data["precoVenda"]
            item.flex_value = item_data["valorFlex"]
            item.unit_value = item_data["valorUnitario"]
            item.client_order_item_number = item_data["numItemPedidoCliente"]
            item.order_number = item_data["numeroPedido"]
            item.icms_symbol = item_data["simbologIcms"]
            item.icms_aliquot = item_data["aliquotaIcms"]
            item.icms_reduction_base = item_data["percReducBcIcms"]
            item.stock_code = item_data["codigoEstoque"]
            item.series = item_data["serie"]
            item.wms_valid_date = item_data["dataValidWms"] ? Date.strptime(item_data["dataValidWms"], "%d/%m/%Y") : nil
          end
        rescue => e
          Rails.logger.error("Erro ao processar item do pedido #{order_data['numeroPedidoCliente']}: #{e.message}, #{order.errors.full_messages}")
        end
      end
    end

    # Lidando com o array "financeiro"
    if order_data["financeiro"].present?
      order_data["financeiro"].each do |payment_data|
        begin
          payment = order.payments.find_or_create_by(payment_method: payment_data["formaPagamento"]) do |payment|
            payment.nfe_flag_code = payment_data["indCodBandeiraNFe"]
            payment.payment_institution_cnpj = payment_data["cnpjInstPagamento"]
            payment.change_value = payment_data["valorTroco"]

            # Lidando com o array "itens" dentro de "financeiro"
            if payment_data["itens"].present?
              payment_data["itens"].each do |payment_item_data|
                begin
                  payment_item = payment.payment_items.find_or_create_by(nsu_host: payment_item_data["nsuHost"]) do |payment_item|
                    payment_item.lowering_account = payment_item_data["contaBaixa"]
                    payment_item.installment = payment_item_data["parcela"]
                    payment_item.sitef_nsu = payment_item_data["nsuSitef"]
                    payment_item.authorization_nsu = payment_item_data["nsuAutorizacao"]
                    payment_item.authorizer = payment_item_data["autorizador"]
                    payment_item.card_bin = payment_item_data["binCartao"]
                    payment_item.bank = payment_item_data["banco"]
                    payment_item.agency = payment_item_data["agencia"]
                    payment_item.value = payment_item_data["valor"]
                    payment_item.pix_id = payment_item_data["pixId"]
                    payment_item.ecomm_transaction_id = payment_item_data["transacaoIdEcomm"]
                    payment_item.card_flag = payment_item_data["bandeiraCartao"]
                    payment_item.payer_cnpj = payment_item_data["cnpjPag"]
                    payment_item.payer_state = payment_item_data["ufPag"]
                    payment_item.receiver_cnpj = payment_item_data["cnpjReceb"]
                    payment_item.payment_terminal_id = payment_item_data["idTermPag"]
                    payment_item.payment_date = payment_item_data["dataPag"]
                  end
                rescue => e
                  Rails.logger.error("Erro ao processar item de pagamento do pedido #{order_data['numeroPedidoCliente']}: #{e.message}, #{order.errors.full_messages}")
                end
              end
            end
          end
        rescue => e
          Rails.logger.error("Erro ao processar pagamento do pedido #{order_data['numeroPedidoCliente']}: #{e.message}, #{order.errors.full_messages}")
        end
      end
    end

    order
  end
end
