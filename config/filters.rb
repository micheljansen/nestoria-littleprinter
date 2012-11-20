#encoding: utf-8

module Nestoria
  @@nestoria_filter_settings = {}

  def self.generate_filter_settings
    bath_titles = {
      'en_AU'      => ['any','from 2','from 3','from 4','from 5','from 6'],
      'pt_BR'      => ['indiferente','a partir de 2','a partir de 3','a partir de 4','a partir de 5','a partir de 6'],
      'es_ES'      => ['todos','desde 2','desde 3','desde 4','desde 5','desde 6'],
      'fr_FR'      => ['indifférent','à partir de 2','à partir de 3','à partir de 4','à partir de 5','à partir de 6'],
      'it_IT'      => ['qualsiasi','da 2','da 3','da 4','da 5','da 6'],
      'en_IN'      => ['any','from 2','from 3','from 4','from 5','from 6'],
      'en_GB'      => ['any','from 2','from 3','from 4','from 5','from 6'],
    }

    bath_titles.each do |locale, titles|
      bath_mappings = []
      value = 1

      titles.each do |title|
        bath_mappings << [ value.to_s, title ]
        value += 1
      end

      @@nestoria_filter_settings[locale] ||= {}
      @@nestoria_filter_settings[locale][:bathrooms] = bath_mappings
    end


    bed_titles = {
      'en_AU' => ['studio','1','2','3','4','5','6'],
      'pt_BR' => ['1','2','3','4','5', '6'],
      'es_ES' => ['estudio','1','2','3','4','5','6'],
      'in' => ['1','2','3','4','5', '6'],
      'en_GB' => ['studio','1','2','3','4','5','6'],
    }

    #AU and UK support studio appartments with 0 beds
    ['en_AU','en_GB','es_ES'].each do |locale|
      bed_vals = (0..6)
      bed_mappings = []
      i = 0
      bed_vals.each do |val|
        bed_mappings << [val.to_s, bed_titles[locale][i]]
        i+= 1
      end
      @@nestoria_filter_settings[locale] ||= {}
      @@nestoria_filter_settings[locale][:bedrooms] = bed_mappings
    end
    # else {
      # @bed_vals = ('1','2','3','4','5','6');
    # }

    price_values_uk = ["0", "100", "150", "200", "250", "300", "350", "400", "450", "500", "550", "600", "650", "700", "750", "800", "900", "1000", "1100", "1200", "1300", "1400", "1500", "1600", "1700", "1800", "1900", "2000", "2250", "2500", "2750", "3000", "3500", "1000000000"]
    price_titles_uk = ["£0", "£100", "£150", "£200", "£250", "£300", "£350", "£400", "£450", "£500", "£550", "£600", "£650", "£700", "£750", "£800", "£900", "£1,000", "£1,100", "£1,200", "£1,300", "£1,400", "£1,500", "£1,600", "£1,700", "£1,800", "£1,900", "£2,000", "£2,250", "£2,500", "£2,750", "£3,000", "£3,500", "£1,000,000,000"]
    price_values_uk_london = ["0", "100", "125", "150", "175", "200", "225", "250", "275", "300", "325", "350", "375", "400", "425", "450", "475", "500", "525", "550", "575", "600", "625", "650", "675", "700", "725", "750", "800", "850", "900", "1000", "1100", "1250", "1000000000"]
    price_titles_uk_london = ["£0", "£100", "£125", "£150", "£175", "£200", "£225", "£250", "£275", "£300", "£325", "£350", "£375", "£400", "£425", "£450", "£475", "£500", "£525", "£550", "£575", "£600", "£625", "£650", "£675", "£700", "£725", "£750", "£800", "£850", "£900", "£1,000", "£1,100", "£1,250", "£1,000,000,000"]

    @@nestoria_filter_settings["en_GB"][:price] = price_values_uk_london.zip(price_titles_uk_london)
    @@nestoria_filter_settings["es_ES"][:price] = price_values_uk_london.zip(price_titles_uk_london)

    sl_templates = {
      'en_GB' => {
        morethan:"from LOWSLIDER",
        around:"around LOWSLIDER",
        between:"LOWSLIDER - HIGHSLIDER",
        lessthan:"up to HIGHSLIDER",
        exactly:"LOWSLIDER",
        any:"any",
        size_maximum:"massive",
        size_minimum:"tiny",
        price_minimum:"cheap as chips",
        price_maximum:"so expensive it hurts"
      },
      'es_ES' => {
        morethan:"desde LOWSLIDER",
        around:"circa LOWSLIDER",
        between:"LOWSLIDER - HIGHSLIDER",
        lessthan:"hasta HIGHSLIDER",
        exactly:"LOWSLIDER",
        any:"todos",
        size_maximum:"enorme",
        size_minimum:"pequeñito",
        price_minimum:"barato barato",
        price_maximum:"tan caro que duele"
      }
    }

    ["en_GB", "es_ES"].each do |locale|
      @@nestoria_filter_settings[locale][:sl_templates] = sl_templates[locale]
    end

  end

  def self.filter_settings
    @@nestoria_filter_settings
  end
end

Nestoria::generate_filter_settings
