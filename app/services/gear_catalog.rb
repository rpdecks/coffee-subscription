class GearCatalog
  CONFIG_PATH = Rails.root.join("config", "gear.yml").freeze

  def self.load
    raw = File.read(CONFIG_PATH)

    data = YAML.safe_load(
      raw,
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    ) || {}

    normalize(data)
  end

  def self.normalize(data)
    {
      "title" => data["title"].presence || "Tools & Gear I Use",
      "meta_description" => data["meta_description"].presence,
      "intro" => Array(data["intro"]).map(&:to_s).reject(&:blank?),
      "sections" => Array(data["sections"]).map do |section|
        {
          "title" => section["title"].to_s,
          "items" => Array(section["items"]).map do |item|
            {
              "name" => item["name"].to_s,
              "description" => item["description"].to_s,
              "note" => item["note"].presence,
              "why_useful" => item["why_useful"].to_s,
              "why_this_one" => item["why_this_one"].to_s,
              "why_it_matters" => item["why_it_matters"].presence,
              "personal_note" => item["personal_note"].presence,
              "image" => item["image"].presence,
              "image_alt" => item["image_alt"].presence,
              "image_size" => item["image_size"].to_s.presence,
              "url" => item["url"].presence,
              "hide_link" => item["hide_link"] == true,
              "tags" => Array(item["tags"]).map(&:to_s).reject(&:blank?)
            }
          end
        }
      end
    }
  end

  private_class_method :normalize
end
