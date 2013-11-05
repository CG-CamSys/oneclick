require 'spec_helper'
# include ServiceAdapters::IandrAdapter

describe ServiceAdapters::IandrAdapter do
  it "create example xml" do
    # p = Provider.new
    # s = Service.new
    # p.services << s
    # s.traveler_accommodations << TravelerAccommodation.new
    # s.traveler_characteristics << TravelerCharacteristic.new
    # s.schedules << Schedule.new
    # providers = [p]
    providers = Provider.all
    i = ServiceAdapters::IandrAdapter.new(providers)
    puts i.to_xml(indent: 2)
    # i.to_xml.should eq 'foo'
  end
end
