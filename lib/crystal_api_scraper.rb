require 'nokogiri'
require 'open-uri'

CrystalMethod = Struct.new(:signature, :summary, keyword_init: true)

class CrystalApiScraper
  XPATH = { 'MethodList' => '//ul[@class="list-summary"]',
            'Method'     => './li[@class="entry-summary"]',
            'Signature'  => './a',
            'Summary'    => './div' }

  def initialize(klass)
    @klass = klass
    @scopes = Hash.new {|hsh, key| hsh[key] = Array.new}
  end

  def constructors
    @constructors ||= summaries['Constructors'];
  end

  def class_methods
    @class_methods ||= summaries['Class Methods']
  end

  def instance_methods
    @instance_methods ||= summaries['Instance Methods']
  end

  private

  def summaries
    list_summaries.each.with_object({}) do |list, lists|
      scope = trim_h2(list.previous_element.text)
      lists[scope] = Array.new unless lists[scope]

      list.xpath(XPATH['Method']).each.with_object(scope, &extract_crystal_method)
    end
    @scopes
  end

  def list_summaries
    noko.xpath(XPATH['MethodList'])
  end

  def extract_crystal_method
    Proc.new do |method_summary, scope|
      @scopes[scope] << CrystalMethod.new(
       signature: method_summary.xpath(XPATH['Signature']).inner_text,
       summary:   method_summary.xpath(XPATH['Summary']).inner_text)
    end
  end

  def trim_h2(text)
    text.strip.sub(' Summary', 's')
  end

  def noko
    Nokogiri.HTML(html)
  end

  def html
    cached? ? cache : URI.open(url, &read_io)
  end

  def cached?
    File.exists? cache_path
  end

  def cache
    File.open(cache_path, "r", &read_io)
  end

  def read_io
    Proc.new { |io| next io.read }
  end

  def cache_path
    "cache/#{@klass}.html"
  end

  def url
    "https://crystal-lang.org/api/master/#{@klass}.html"
  end
end
