# Pagy Configuration
require 'pagy/extras/overflow'
require 'pagy/extras/tailwind'

Pagy::DEFAULT[:items] = 25
Pagy::DEFAULT[:overflow] = :last_page
Pagy::DEFAULT[:size] = [1, 2, 2, 1] # Shows: first page, 2 before current, 2 after current, last page
