class CoffeePreference < ApplicationRecord
  belongs_to :user

  enum roast_level: { light: 0, medium_roast: 1, dark: 2, variety: 3 }
  enum grind_type: { whole_bean: 0, coarse: 1, medium_grind: 2, fine: 3, espresso: 4 }

  validates :roast_level, :grind_type, presence: true
end
