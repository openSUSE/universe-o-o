# frozen_string_literal: true

require 'json'
require 'yaml'

# Generates api for sites in _data/sites.yml
class SitesApi < Jekyll::Page
  def initialize(site, lang)
    @site = site
    @ext = '.json'
    @name = '_data/sites.yml'
    @relative_path = "api/v0/#{lang}/sites.json"
    @lang = lang
    super(site, site.source, '', name)

    data['permalink'] = @relative_path
    self.content = generate_content(lang)
  end

  def generate_content(_lang)
    sites = YAML.load_file('_data/sites.yml')
    sites = assign_names(sites)
    sites.to_json
  end

  def assign_names(arr)
    arr.each_with_object([]) do |item, result|
      item['name'] = localized(item['id'])
      url = "#{item['id']}_url"
      item['url'] = localized(url) if localized(url)
      item['links'] = assign_names(item['links']) if item.key?('links')
      result << item
    end
  end

  def localized(string)
    default_locale = YAML.load_file('_data/locales/en.yml')
    localization = default_locale.merge(YAML.load_file("_data/locales/#{@lang}.yml"))
    localization[string] || default_locale[string]
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.locale_handler.available_locales.each do |lang|
    site.pages << SitesApi.new(site, lang)
  end
end
