require './models/nestoria/url'

mappings = {
  {
    location: "london",
    property_type: "property",
    listing_type: "rent"
  } => "/london/property/rent",
  {
    location: "london",
    property_type: "property",
    listing_type: "rent",
    offset: "10"
  } => "/london/property/rent/start-10",
  {
    location: "london",
    property_type: "property",
    listing_type: "rent",
    sort: "price_lowhigh"
  } => "/london/property/rent/sortby-price_lowhigh",
  {
    location: "london",
    property_type: "property",
    listing_type: "rent",
    sort: "price_lowhigh",
    offset: "10"
  } => "/london/property/rent/sortby-price_lowhigh/start-10"

}

describe Nestoria::URL do
  it "should match /london/property/rent" do
    matches = Nestoria::URL.match("/london/property/rent")
    matches[:location].should eq("london")
    matches[:property_type].should eq("property")
    matches[:listing_type].should eq("rent")
  end

  it "should match /london/property/rent/" do
    matches = Nestoria::URL.match("/london/property/rent/")
    matches[:location].should eq("london")
    matches[:property_type].should eq("property")
    matches[:listing_type].should eq("rent")
  end

  it "should match /london/property/rent/start-10" do
    matches = Nestoria::URL.match("/london/property/rent/start-10")
    matches[:location].should eq("london")
    matches[:property_type].should eq("property")
    matches[:listing_type].should eq("rent")
    matches[:offset].should eq("10")
  end

  it "should accept the sort parameter" do
    matches = Nestoria::URL.match("/london/property/rent/sortby-price_lowhigh")
    matches[:sort].should eq("price_lowhigh")
  end

  it "should accept the combination of sort and offset parameters" do
    matches = Nestoria::URL.match("/london/property/rent/sortby-price_lowhigh/start-10")
    matches[:sort].should eq("price_lowhigh")
    matches[:offset].should eq("10")
  end

  it "should ignore trailing crap" do
    matches = Nestoria::URL.match("/london/property/rent?bla=test")
    matches[:location].should eq("london")
    matches[:property_type].should eq("property")
    matches[:listing_type].should eq("rent")
  end

  it "should ignore style" do
    matches = Nestoria::URL.match("/style/test/file")
    matches.should eq(nil)
  end

  it "should ignore js" do
    matches = Nestoria::URL.match("/js/test/file")
    matches.should eq(nil)
  end

  it "should ignore images" do
    matches = Nestoria::URL.match("/images/test/file")
    matches.should eq(nil)
  end

  describe "pagination" do
    it "should know next page for first page" do
      url = Nestoria::URL.match("/london/property/rent")
      url.next_page.to_s.should eq("/london/property/rent/start-10")
    end

    it "should know next page for middle page" do
      url = Nestoria::URL.match("/london/property/rent/start-20")
      url.next_page.to_s.should eq("/london/property/rent/start-30")
    end
  end

 describe "generation" do
   mappings.each do |input, output|
     it "should generate #{output} from #{input}" do
       url = Nestoria::URL.new(input)
       url.to_s.should eq(output)
     end
   end
 end
end
