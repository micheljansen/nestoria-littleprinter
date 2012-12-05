module Nestoria
  module MobileAPI
    def self.get_listings(location, property_type, listing_type, options={})
      parameters = {
            :country => "uk",
            :number_of_results => "10",
            :listing_type => listing_type,
            :property_type => property_type,
            :output => "mobile_dyn"
          }.merge(options)

      if !Hash.try_convert(location).nil?
        #treat it as a coordinate pair or radius and pass it verbatim
        puts "COORDINATE SEARCH"
        p location
        parameters = parameters.merge(location)
      else
        #treat it as a word
        parameters[:place_name] = location.gsub(/ /, "-").gsub(/,/, '_')
      end

      # translate public API to private API
      {
        :place_name => :word,
        :price_min => :pmin,
        :price_max => :pmax

      }.each do |old,new|
        puts "#{old}, #{new}"
        parameters[new] = parameters[old]
        parameters.delete(old)
      end

      # http://m.nestoria.co.uk/mp/mobile/search?lt=rent&pt=flat&word=clerkenwell&output=mobile_dyn&s=relevancy&pmin=100&pmax=1100&bmin=1
      api_url = URI::HTTP.build(:host => "m.nestoria.co.uk",
                                      :port => 80,
                                      :path => "/mp/mobile/search",
                                      :query => parameters.map{|k,v|
                                            "#{URI.encode_www_form_component(k.to_s)}=#{URI.encode_www_form_component(v.to_s)}"
                                          }.join("&"))

      puts "API request: #{api_url}"

      backend_response = {
          "response" => {
              "application_response_code" => "500",
              "application_response_text" => "Could not get through to the Nestoria API. It could be a temporary thing, so please do try again later!",
              "listings" => [],
              "parsed_listings" => []
            },
      }

      # perform HTTP request
      begin
        req = Net::HTTP::Get.new(api_url.request_uri)
        req["X-Requested-With"] = "XMLHttpRequest"
        res = Net::HTTP.start(api_url.host, api_url.port) {|http| http.request(req)}
        backend_response_json = res.body.to_s.force_encoding("UTF-8")
      rescue => e
        # STDERR.puts e
        STDERR.puts "backend request failed"
        raise e
        return backend_response
      end

      # parse the response
      begin
        backend_response = JSON.parse(backend_response_json)
      rescue => e
        raise e
        STDERR.puts e
        backend_response["application_response_text"] =
          "We got some unexpected data back from the server. Not much you can do about that right now, sorry :("
      end

      backend_response
    end
  end
end
