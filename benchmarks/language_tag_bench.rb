# encoding: binary

require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
begin
  require 'langtag'

  TAGS = []

  TAGS << 'de'
  TAGS << 'de-DE'
  TAGS << 'zh-Hant'
  TAGS << 'zh-Hans-CN'
  TAGS << 'sl-rozaj'
  TAGS << 'sl-rozaj-biske'
  TAGS << 'de-CH-1901'
  TAGS << 'sl-IT-nedis'
  TAGS << 'sl-Latn-IT-nedis'
  TAGS << 'sl-Latn-IT-rozaj-biske-x-it-sl'
  TAGS << 'zh-cmn-Hans-CN'
  TAGS << 'zh-yue-HK'
  TAGS << 'zh-yue'
  TAGS << 'zh-yue-x-yue'

  TIMES = ARGV[0] ? ARGV[0].to_i : 10_000

  RBench.run(TIMES) do

    column :times
    column :one,  :title => 'LangTag'
    column :two,  :title => 'RA'
    column :diff, :title => '#2/#1', :compare => [:two, :one]

    group "Langtag.new vs RA::LanguageTag.parse" do
      TAGS.each do |tag|
        report tag.inspect do
          one { Langtag.new(tag) }
          two { Rack::Acceptable::LanguageTag.parse(tag) }
        end
      end

      summary ''
    end

    group "Langtag.new vs RA::LanguageTag.extract_language_info" do
      TAGS.each do |tag|
        report tag.inspect do
          one { Langtag.new(tag) }
          two { Rack::Acceptable::LanguageTag.extract_language_info(tag) }
        end
      end

      summary ''
    end

  end
rescue LoadError
  STDERR.puts "you need the 'langtag' gem to run this bench"
end

# EOF