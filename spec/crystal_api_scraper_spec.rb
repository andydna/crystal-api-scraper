require 'vcr'
require 'pry'
require 'fileutils'

require 'crystal_api_scraper'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.describe Crystal::ApiScraper, :vcr do
  context 'scraping summaries' do
    let(:scraper) { Crystal::ApiScraper.new('Class') }

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

    it 'spotcheck constructor: cast' do
      cast = scraper.constructors.find do |constructor|
        constructor.signature == ".cast(other) : self"
      end
      expect(cast).to be_an_instance_of(Crystal::Method)
      expect(cast).to include("Casts other to this class.")
    end

    it 'spotcheck class method: name' do
      name = scraper.class_methods.find do |class_method|
        class_method.signature == ".name : String"
      end
      expect(name).to be_an_instance_of(Crystal::Method)
      expect(name).to include("Returns the name of this class.")
    end

    it 'spotcheck instance method: dup' do
      dup = scraper.instance_methods.find do |instance_method|
        instance_method.signature == "#dup"
      end
      expect(dup).to be_an_instance_of(Crystal::Method)
      expect(dup).to include("Returns a shallow copy of this object.")
    end

    it "doesn't scrape if we've already cached it" do
      FileUtils.mkdir('cache') unless File.exists?('cache')
      FileUtils.touch('cache/Klass.html')

      uri = class_double('URI').as_stubbed_const

      expect(uri).not_to receive(:open)
      Crystal::ApiScraper.new('Klass').constructors

      FileUtils.rm('cache/Klass.html')
    end
  end

  context "scraping class names" do
    specify 'there are 136' do
      types = Crystal::ApiScraper.types
      expect(types.count).to eq 136
    end
  end

  context "filling the cache" do
    specify "all your types are belong to us" do
      cache_dir = 'cache/'

      Crystal::ApiScraper.fill_cache

      expect(Dir.children(cache_dir).count).to eq 136
    end
  end
end
