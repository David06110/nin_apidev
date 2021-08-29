class CashbacksController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'mime/types'
  def new
    @new_cashback = Cashback.new
  end

  def create
    @new_cashback = Cashback.new(user: current_user)

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
      # api /pause      @api_response = JSON.parse(response.body, object_class: OpenStruct)
      # File.write("response.json", response.body, mode: "a")
      static_response = File.read("response.json")
      @api_response = JSON.parse(static_response, object_class: OpenStruct)
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
      read_response()
    else
      redirect_to new_cashback_path, notice: "Ticket non reconnu"
    end
  end

  def read_response
      @tt_current = @api_response[:document][:inference][:prediction][:total][:values][0][:content].to_d
      # pry

      if @tt_current.present? #&& @tt_current.is_an_int
        @new_cashback.amount = @tt_current * 0.05
        @new_cashback.shop = Shop.first

        if @new_cashback.save!
          sleep(0.5)
          redirect_to '/dashboard'
        else
          render :new
        end
      else
        render :new
      end



  end
end # class