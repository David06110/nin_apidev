class CashbacksController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'mime/types'
  def new
    @new_cashback = Cashback.new
  end

  def create


    if params[:cashback].present?
      @file = params[:cashback][:ticket]
      # api pause
        # url = URI("https://api.mindee.net/v1/products/David06110/niceinvoice/v1/predict")
        # http = Net::HTTP.new(url.host, url.port)
        # http.use_ssl = true
        # request = Net::HTTP::Post.new(url)
        # request["Authorization"] = 'Token d717296e81ad03964a801c72e476b3b1'
        # request.set_form([['document', File.open(@file)]], 'multipart/form-data')
        # response = http.request(request)
        # @api_response = JSON.parse(response.body, object_class: OpenStruct)
      # api /pause
      # File.write("response_#{Time.now}.json", response.body, mode: "a")
      static_response = File.read("responseanother.json")
      @api_response = JSON.parse(static_response, object_class: OpenStruct)
      @short_response = @api_response.document.inference.prediction

      # pry
      #private start
      api_status()
    else
      redirect_to new_cashback_path, notice: "Merci de choisir un ticket"
    end
  end

  private

  def api_status
    if @api_response.api_request.status == "success"
      valid = scan_valid?()
      valid == "ok" ? read_response() : (redirect_to new_cashback_path, notice: valid)
    else
      redirect_to new_cashback_path, notice: "Ticket non reconnu"
    end
  end

  def read_response
      @tt_current = @short_response.address.values[0].content.to_d

      @ad = []
      @ad_pieces = @short_response.address.values
      @ad_pieces.each do |ad_piece|
        @ad << ad_piece.content
      end
      @ad_current = @ad.join(' ')

      @nm = []
      @short_response
      .name
      .values
      .each do |nm|
        @nm << nm.content
      end
      @name_current = @nm.join(' ')
      # @date_current = DateTime.new( @short_response
      #                                .date
      #                                .values[0]
      #                                .content
      #                                .split('-')
      #                                .join(',')).strftime("%d/%m/%Y")
      # @date_current = @short_response
      #                   .date
      #                   .values[0]
      #                   .content
      #                   .split('-')
      #                   .join(',')




      if shop_valid?() && @vd_id.present? #@tt_current.present? #&& @tt_current.is_an_int
        @new_cashback = Cashback.new(user: current_user)
        @new_cashback.amount = @tt_current * 0.05
        @new_cashback.shop_id = @vd_id

        if @new_cashback.save!
          sleep(0.1)
          redirect_to '/dashboard'
        end
      else
        redirect_to new_cashback_path, notice: "#{@name_current} au #{@ad_current} n'est pas éligible"
      end
  end

  def shop_valid?
    vd_name = Shop.where(name: @name_current)
    vd_address = Shop.where(address: @ad_current)

    vd_name.each do |name|
      vd_address.each do |address|
        if name.id == address.id
          @vd_id = name.id
        else
          false
        end
      end
    end
  end

  def scan_valid?
    return "Date illisible" if @short_response.date.confidence.to_d < 0.7
    return "Nom illisible" if @short_response.name.confidence.to_d < 0.7
    return "Adresse illisible" if @short_response.address.confidence.to_d < 0.7
    return "Total illisible" if @short_response.total.confidence.to_d < 0.7
    return "ok"
  end
end # class
