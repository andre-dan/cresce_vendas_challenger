# app/services/price_service.rb
class PriceService
  def self.create_or_update_from_api(product_data)
    product = Product.find_or_initialize_by(code: product_data["Codigo"])
    product.tap do
      product.assign_attributes(
        price: product_data["Preco"],
        normal_price: product_data["PrecoNormal"],
        list_price: product_data["PrecoLista"],
        pdv_price: product_data["PrecoPDV"],
        pdv_price3: product_data["PrecoPDV3"],
        pdv_price4: product_data["PrecoPDV4"],
        pdv_price5: product_data["PrecoPDV5"],
        label_price: product_data["PrecoEtiqueta"],
        poster_price: product_data["PrecoCartaz"],
        sale_price2: product_data["PrecoVenda2"],
        sale_price3: product_data["PrecoVenda3"],
        sale_price4: product_data["PrecoVenda4"],
        sale_price5: product_data["PrecoVenda5"],
        unit_price_measure: product_data["PrecoUnidadeMedida"],
        previous_offer_price: product_data["PrecoOfertaAnt"],
        previous_normal_price: product_data["PrecoNormalAnt"],
        previous_offer_price2: product_data["PrecoOfertaAnt2"],
        previous_normal_price2: product_data["PrecoNormalAnt2"],
        normal_price3: product_data["PrNormal3"],
        normal_price4: product_data["PrNormal4"],
        normal_price5: product_data["PrNormal5"],
        previous_normal_price3: product_data["PrecoNormalAnt3"],
        previous_normal_price4: product_data["PrecoNormalAnt4"],
        previous_normal_price5: product_data["PrecoNormalAnt5"],
        previous_offer_price3: product_data["PrecoOfertaAnt3"],
        previous_offer_price4: product_data["PrecoOfertaAnt4"],
        previous_offer_price5: product_data["PrecoOfertaAnt5"],
        default_sale_price: product_data["PrVdaPadrao"],
        previous_sale_price2: product_data["PrVenda2Ant"],
        previous_sale_price2_2: product_data["PrVenda2Ant2"],
        price_code: product_data["CodigoPreco"],
        agpr_price1: product_data["AgprPreco1"],
        agpr_price2: product_data["AgprPreco2"],
        agpr_price3: product_data["AgprPreco3"],
        agpr_price4: product_data["AgprPreco4"],
        agpr_price5: product_data["AgprPreco5"],
        agof_price1: product_data["AgofPreco1"],
        agof_price2: product_data["AgofPreco2"],
        agof_price3: product_data["AgofPreco3"],
        agof_price4: product_data["AgofPreco4"],
        agof_price5: product_data["AgofPreco5"]
      )
    end
  end
end
