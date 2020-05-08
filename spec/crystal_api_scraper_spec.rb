require 'crystal_api_scraper'

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.describe CrystalApiScraper, :vcr do
  let(:scraper) { CrystalApiScraper.new('Class') }

  it 'given a class, it scrapes the html' do
    html = scraper.html
    expect(html).to include "Returns the name of this class."
  end

  it 'generates a list of constructors' do
    constructors = scraper.constructors
    expect(constructors.count).to eq 1
  end

  it 'generates a list of class methods' do
    class_methods = scraper.class_methods
    expect(class_methods.count).to eq 14
  end

  it 'generates a list of instance methods' do
    instance_methods = scraper.instance_methods
    expect(instance_methods.count).to eq 15
  end
end
