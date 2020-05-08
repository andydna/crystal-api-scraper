require 'nokogiri'
require 'open-uri'

CrystalMethod = Struct.new(:signature, :summary, keyword_init: true)

class CrystalApiScraper
  def initialize(klass)
    @klass = klass
  end

  def html
    @html ||= URI.open(url).read
  end

  def constructors
    crystal_methods['Constructors']
  end

  def class_methods
    crystal_methods['Class Methods']
  end

  def instance_methods
    crystal_methods['Instance Methods']
  end

  private

  def url
    "https://crystal-lang.org/api/master/#{@klass}.html"
  end

  def crystal_methods
    list_summaries.each.with_object({}) do |list_summary, lists|
      scope = list_summary.previous_element.text.strip.sub(' Summary', 's')
      lists[scope] = Array.new unless lists[scope]

      list_summary.xpath('./li[@class="entry-summary"]').each do |method_summary|
        lists[scope] << CrystalMethod.new(
         signature: method_summary.xpath('./a').inner_text,
         summary:   method_summary.xpath('./div').inner_text)
      end
    end
  end

  def list_summaries
    noko.xpath('//ul[@class="list-summary"]')
  end

  def noko
    Nokogiri.HTML(html)
  end
end
