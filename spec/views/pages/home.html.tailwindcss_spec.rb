require 'rails_helper'

RSpec.describe "pages/home.html.tailwindcss", type: :view do
  before do
    assign(:hero_image, 'https://example.com/hero.jpg')

    allow(Product).to receive_message_chain(:coffee, :active, :limit).and_return([])
  end

  it 'renders the hero CTA container' do
    render template: 'pages/home'

    assert_select '#home-hero-ctas', 1
  end

  it 'renders equal-width hero CTA links without per-link padding overrides' do
    render template: 'pages/home'

    assert_select '#home-hero-ctas a.btn-hero-primary', text: 'Start a Subscription'
    assert_select '#home-hero-ctas a.btn-hero-secondary', text: 'Shop Single Bags'

    expect(rendered).to include('whitespace-nowrap')
    expect(rendered).to include('width: min(100%, 300px)')

    expect(rendered).not_to include('!px-4')
    expect(rendered).not_to include('!py-2')
    expect(rendered).not_to include('sm:!px-6')
    expect(rendered).not_to include('sm:!py-3')
  end
end
