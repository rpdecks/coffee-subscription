module ApplicationHelper
  include Pagy::Frontend

  def status_color_class(status)
    case status.to_s
    when 'active'
      'bg-green-100 text-green-800'
    when 'paused'
      'bg-yellow-100 text-yellow-800'
    when 'cancelled', 'expired'
      'bg-gray-100 text-gray-800'
    when 'past_due'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
