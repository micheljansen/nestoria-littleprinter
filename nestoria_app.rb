#encoding utf-8

Encoding.default_external = 'UTF-8'

require 'net/http'
require 'sinatra/config_file'
require "sinatra/reloader" if development?

require './config/filters.rb'

require './models/listing'
require './models/nestoria/url'
require './models/nestoria/api'

class Nestoria::App < Sinatra::Base
  register Sinatra::StaticAssets
  register Sinatra::ConfigFile

  enable :sessions
  use Rack::Flash

  config_file 'config/nestoria.yml'

  helpers do
    include Rack::Utils
    include ActionView::Helpers::NumberHelper
    include FastGettext::Translation

    alias_method :h, :escape_html

    def partial(template, options = {})
      options[:layout] = false
      erb "_#{template}".to_sym, options
    end

    def formatted_price(price)
      #TODO i8n
      number_to_currency(price, unit: "\u00a3", separator: ".", delimiter: ",", format: "%u%n", precision: 0)
    end

    def formatted_number(number)
      #TODO i8n
      number_with_delimiter(number, :delimiter => ',')
    end

    def x_to_y_in_z(property_type, listing_type, location_nicename, num_results)
      pt_part = case property_type.downcase
                when "flat"  then n_("Flat", "Flats", num_results)
                when "house" then n_("House", "Houses", num_results)
                else n_("Property", "Properties", num_results)
                end

      lt_part = case listing_type.downcase
                when "rent" then _("to rent")
                else _("for sale")
                end

      _("%{pt_part} %{lt_part} in %{location_nicename}") % {pt_part: pt_part, lt_part: lt_part, location_nicename: location_nicename}
    end
  end

  configure do
    FastGettext.add_text_domain('nestoria',
                                :path => 'locale',
                                :type => :po,
                                :report_warning => true)
    FastGettext.default_text_domain = 'nestoria'
    FastGettext.default_locale = settings.locale
    Sprockets::Less.options[:compress] = true
    set :filter_settings, Nestoria::filter_settings[settings.locale]
  end

  configure :development do
    Sprockets::Less.options[:compress] = false
    register Sinatra::Reloader
    also_reload './models/listing.rb'
    also_reload './models/nestoria/url.rb'
    also_reload './models/nestoria/api.rb'
  end


  # do this dynamically so we generate it when fields change
  get '/meta.json' do
    content_type :json
    return {
      publication_api_version: '1.0',
      owner_email: "michel@lokku.com",
      name: "Nestoria",
      description: "New houses, flats etc. to rent or buy",
      delivered_on: "every day",
      external_configuration: false,
      send_timezone_info: true,
      send_delivery_count: false,
      config: {
        fields: [{
          type: "radio",
          name: "property_type",
          label: "Property Type",
          options: [
              ["Any","property"],
              ["Flat","flat"],
              ["House","house"]
            ]
        }, {
          type: "radio",
          name: "listing_type",
          label: "To",
          options: [
              ["Buy","buy"],
              ["Rent","rent"]
            ]
        }, {
          type: "text",
          name: "location",
          label: 'Location (e.g. "London", "Soho" or "W1")'
        }
      ]}
    }.to_json
  end

  get '/sample/' do
    params = {location: "london", property_type: "property", listing_type: "rent"}
    results = serp_request(params, Nestoria::URL.new(params))
    erb :serp, {locals: results}
  end


  post '/validate_config/' do
    content_type :json
    {valid: true}.to_json
  end


  get '/edition/' do
    # MD5 Hash today's date with two configuration options passed in from BERG Cloud
    etag Digest::MD5.hexdigest(Time.now.utc.strftime('%l%p, %d %b %Y %Z')) unless params[:debug]
    # validations
    if(!params[:location] or !params[:property_type] or !params[:listing_type])
      return ""
    end
    results = serp_request(params, Nestoria::URL.new(params))
    p results
    erb :serp, {locals: results}
  end

  def serp_request(params, current_url)
    raise "Something bad happened that caused us to search without a location. Please try again with a location." if !params[:location]

    filters = settings.filter_settings

    coord_location = nil
    location = params[:location].downcase
    location_nicename = params[:location]
    property_type = params[:property_type] || "property"
    listing_type = params[:listing_type] || "buy"
    min_beds = params[:min_beds] || filters[:bedrooms].first.first
    max_beds = params[:max_beds] || filters[:bedrooms].last.first
    min_price = params[:min_price] || filters[:price].first.first
    max_price = params[:max_price] || filters[:price].last.first

    offset = params[:offset].to_i
    page_no = (offset / 10).to_i + 1

    sort = params[:sort] || 'relevancy'

    # handle coord_ locations

    if location =~ /coord_/
      puts "coord search: #{location}"
      coords = location.gsub(/coord_/, '').split(',')
      ne = [coords[0], coords[1]]
      sw = [coords[2], coords[3]]
      coord_location = {
        north_east: ne.join(','),
        south_west: sw.join(',')
      }
    end

    #TODO use time zone to determine what's new
    new_cutoff = (Time.now - 1.day).to_i

    loc = coord_location.nil? ? location : coord_location
    backend_response = Nestoria::API.get_listings(loc, property_type, listing_type, {
      page: page_no,
      sort: sort,
      bedroom_min: min_beds,
      bedroom_max: max_beds,
      price_min: min_price,
      price_max: max_price,
      updated_min: new_cutoff,
      number_of_results: 5
    })

    if(backend_response["response"]["locations"] &&
       backend_response["response"]["locations"].length > 0)
      l = backend_response["response"]["locations"][0]
      location = l["place_name"]
      location_nicename = l["long_title"]
      center = {lat: l["center_lat"], long: l["center_long"]}
    else
      #this is actually really bad, and we don't know what to do yet
      STDERR.puts backend_response
      raise "Nestoria does not know this location. Sorry about that. Normally we would help you along here, but that part of the prototype is not finished yet. Please try another location."
    end

    # set url based on response
    current_url = current_url.with(location: location)

    # parse listings
    unparsed_listings = backend_response["response"]["listings"]
    listings = []
    if(!unparsed_listings.nil?)
      listings = backend_response["response"]["listings"].map do |listing_data|
        begin
          Listing.new(listing_data)
        rescue => e
          STDERR.puts e
        end
      end
    end

    num_results = backend_response["response"]["total_results"].to_i


    other_url = current_url.with(min_price: nil, max_price: nil, listing_type: listing_type == "rent" ? "buy" : "rent")
    pagination_line = _("Showing") + " " + (num_results <= 10 ?
                                    _("all") +" #{num_results}"
                                  : _("%{range} of %{total_results}") % { range: "#{offset+1}-#{[num_results, offset+10].min}",
                                                                          total_results: number_with_delimiter(num_results, :delimiter => ',') }
                                   ) + " "+ n_("result", "results", num_results)

    ###################
    # format the title
    ###################

    bare_verbose_title = x_to_y_in_z(property_type, listing_type, location_nicename, num_results)
    #TODO HACK!
    bare_verbose_title = bare_verbose_title.sub(/in /, "") if coord_location
    verbose_title = bare_verbose_title

    if params[:min_price] and params[:max_price]
      verbose_title += " " + _("costing between %{min_price} and %{max_price}" % {min_price: "#{formatted_price(min_price)}", max_price: formatted_price(max_price)}) 
      verbose_title += " per week" if listing_type == "rent"
    elsif params[:min_price]
      verbose_title += " " + _("costing more than %{min_price}" % {min_price: "#{formatted_price(min_price)}"})
      verbose_title += " per week" if listing_type == "rent"
    elsif params[:max_price]
      verbose_title += " " + _("costing less than %{max_price}" % {max_price: "#{formatted_price(max_price)}"})
      verbose_title += " per week" if listing_type == "rent"
    end

    verbose_title += "," if (params[:min_price] || params[:max_price]) && (params[:min_beds] || params[:max_beds])

    if params[:min_beds] and params[:max_beds]
      verbose_title += " " + _("with %{min_beds} - %{max_beds} bedrooms" % {min_beds: min_beds, max_beds: max_beds})
    elsif params[:min_beds]
      verbose_title += " " + _("with %{min_beds} or more bedrooms" % {min_beds: min_beds})
    elsif params[:max_beds]
      verbose_title += " " + _("with up to %{max_beds} bedrooms" % {max_beds: max_beds})
    end

    ###################

    page_classes = "debug" if params[:debug]


    vars =  {
              :page_classes => page_classes,
              :listings => listings,
              :num_results => num_results,
              :listings => listings,
              :location_nicename => location_nicename,
              :is_coord_search => !coord_location.nil?,
              :location => location,
              :listing_type => listing_type,
              :property_type => property_type,
              :other_url => other_url,
              :pagination_line => pagination_line,
              :page_no => page_no,
              :total_pages => backend_response["response"]["total_pages"].to_i,
              :next_page_url => current_url.next_page.to_s,
              :previous_page_url => current_url.previous_page.to_s,
              :backend_request => backend_response["request"],
              :response => backend_response["response"],
              :response_code => backend_response["response"]["application_response_code"],
              :filters => settings.filter_settings,
              :verbose_title => verbose_title,
              :bare_verbose_title => bare_verbose_title,
              :current_url => current_url,
              :min_beds => min_beds,
              :max_beds => max_beds,
              :min_price => min_price,
              :max_price => max_price,
              :other_urls => {
                  property: current_url.with(property_type: "property"),
                  house: current_url.with(property_type: "house"),
                  flat: current_url.with(property_type: "flat")
              },
              :center => center,
              :sort => sort
    }

  end


  get '/mp/as' do
    q = params['q'] || ""
    output = params["output"] || "json"
    n = params["n"] || "n"

    url = URI::HTTP.build(:host => "www.nestoria.co.uk",
                                  :path => "/mp/as",
                                  :query => params.map{|k,v| "#{k}=#{v}"}.join('&'))
    result = Net::HTTP.get(url)
    result
  end

  def params_without_defaults(params)
    params_without_defaults!(params.clone)
  end

  #modifies params in place
  def params_without_defaults!(params)
    filters = settings.filter_settings

    params.delete("min_price") if params[:min_price] == filters[:price].first.first
    params.delete("max_price") if params[:max_price] == filters[:price].last.first
    params.delete("min_beds") if params[:min_beds] == filters[:bedrooms].first.first
    params.delete("max_beds") if params[:max_beds] == filters[:bedrooms].last.first
    return params
  end

end
