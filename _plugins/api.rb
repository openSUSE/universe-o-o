require 'json'
require 'yaml'

# Generates api for sites in _data/sites.yml
class SitesApi < Jekyll::Page
  def initialize(site, lang)
    @site = site
    @ext = '.json'
    @name = "_data/sites.yml"
    @relative_path = "api/v0/#{lang}/sites.json"
    super(site, site.source, '', name)

    self.data['permalink'] = @relative_path
    self.content = generate_content(lang)
  end

  def generate_content(lang)
    default_locale = YAML.load_file("_data/locales/en.yml")
    localization = default_locale.merge(YAML.load_file("_data/locales/#{lang}.yml"))
    sites = YAML.load_file('_data/sites.yml')
    sites.each_with_index do |category, category_index|
      sites[category_index]['name'] = localization[category['id']]
      category['links'].each_with_index do |link, link_index|
        sites[category_index]['links'][link_index]['name'] = localization[link['id']]

        # We want to make sure that we don't serve content in other languages than selected to people
        url = "#{link['id']}_url"
        if %w(forums telegram_group wiki).include?(link['id'])
          if localization[url].nil? || localization[url] == default_locale[url]
            sites[category_index]['links'].delete_at(link_index)
          else
            sites[category_index]['links'][link_index]['url'] = localization[url]
          end
        end
      end
    end

    sites.to_json
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.locale_handler.available_locales.each do |lang|
    site.pages << SitesApi.new(site, lang)
  end
end
