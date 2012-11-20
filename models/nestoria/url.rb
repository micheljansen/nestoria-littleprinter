module Nestoria
  class URL
    @@pattern = %r{
                  ^/
                  (?<location>       [^/?]+ ) # e.g. london
                  /
                  (?<property_type>  [^/?]+ ) # e.g. flat
                  /
                  (?<listing_type>   [^/?]+ ) # e.g. rent
                  (/bedrooms-
                   (?<min_beds> [^/]+ )       # e.g. 1
                  )?
                  (/maxprice-
                   (?<max_price> [^/]+ )     # e.g. 5000
                  )?
                  (/minprice-
                   (?<min_price> [^/]+ )     # e.g. 1000
                  )?
                  (/maxbed-
                   (?<max_beds> [^/]+ )       # e.g. 5
                  )?
                  (/sortby-
                   (?<sort> [^/]+ )           # e.g. price_lowhigh
                  )?
                  (/start-
                   (?<offset> [^/]+ )         # e.g. 10
                  )?
                  (?<rest> .*)$
                }x

    @@blacklist = /(style|images|js)/

    # options: a hash with all parameters
    #          expects the key 0 to refer to the whole url
    def initialize(options)
      @options = options
    end

    def [](key)
      @options[key]
    end

    # redirect this to the internal MatchData object, if any
    # Sinatra expects this
    def captures
      @options.respond_to?(:captures) ? @options.captures : []
    end

    # Match method that complies to Sinatra's expected behaviour.
    # Returns nil if the string does not match
    # and a new Nestoria::URL object if it does
    def self.match(str)
      matches = @@pattern.match(str)
      return nil if matches.nil?
      return nil if @@blacklist.match(matches[:location])
      return Nestoria::URL.new(matches)
    end

    # The keys that Sinatra uses to populate the params hash
    def self.keys
      @@pattern.names
    end

    def self.pattern
      @@pattern
    end

    # The options as a mutable hash
    def mutable_options
      if @options.respond_to?(:[]=)
      then @options.clone
      else @options.names.reduce({}) do |new_options, name|
          new_options[name.to_sym] = @options[name]
          new_options
        end
      end
    end

    # return a copy of this URL with options changed
    def with(options)
      Nestoria::URL.new(mutable_options.merge(options))
    end

    def next_page
      self.with({:offset => self[:offset].to_i + 10})
    end

    def previous_page
      self.with({:offset => [0, self[:offset].to_i - 10].max})
    end


    def to_s
      # todo url encoding
      url = "/#{self[:location]}/#{self[:property_type]}/#{self[:listing_type]}"
      url += "/bedrooms-#{self[:min_beds]}" if self[:min_beds]
      url += "/maxprice-#{self[:max_price]}" if self[:max_price]
      url += "/minprice-#{self[:min_price]}" if self[:min_price]
      url += "/maxbed-#{self[:max_beds]}" if self[:max_beds]
      url += "/sortby-#{self[:sort]}" if self[:sort] and self[:sort] != "relevancy"
      url += "/start-#{self[:offset]}" if self[:offset].to_i > 0
      url += self[:rest] if self[:rest]
      url
    end

  end
end
