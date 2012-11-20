# encoding: utf-8

require 'active_support'
require 'action_view/helpers/number_helper'

class Listing < Hash
  include ActionView::Helpers::NumberHelper

  def initialize(options = {})
    super()
    self.merge!(options)

    self["beds_string"] = if    self["bedroom_number"] == ""
                            ""
                          elsif self["bedroom_number"] == "0"
                            "studio"
                          else
                            self["bedroom_number"].to_i == 1 ? "#{self['bedroom_number']} bed" : "#{self['bedroom_number']} beds"
                          end

    self["baths_string"] = if    self["bathroom_number"].to_i == 0
                            ""
                          else
                            self["bathroom_number"].to_i == 1 ? "#{self['bathroom_number']} bath" : "#{self['bathroom_number']} baths"
                          end

    self["keywords_a"] = self["keywords"].nil? ? [] : self["keywords"].split(",")

    self["nice_price"] = number_to_currency(self["price"], {:precision => 0, :unit => "£"})

    self
  end

end
