module Nestoria
  module API
    def self.get_listings(location, property_type, listing_type, options={})
      parameters = {
            :country => "uk",
            :action => "search_listings",
            :encoding => "json",
            :number_of_results => "10",
            :listing_type => listing_type,
            :property_type => property_type,
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

      api_url = URI::HTTP.build(:host => "api.nestoria.co.uk",
                                      :port => 80,
                                      :path => "/api",
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
        backend_response_json = Net::HTTP.get(api_url).to_s.force_encoding("UTF-8")
      rescue => e
        STDERR.puts e
        return backend_response
      end

      # parse the response
      begin
        backend_response = JSON.parse(backend_response_json)
      rescue => e
        STDERR.puts e
        backend_response["application_response_text"] =
          "We got some unexpected data back from the server. Not much you can do about that right now, sorry :("
      end

      backend_response
    end
  end
end
