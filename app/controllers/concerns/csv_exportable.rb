module CsvExportable
  extend ActiveSupport::Concern

  private

  def send_csv_data(data, filename)
    send_data data,
              filename: "#{filename}_#{Date.today}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def render_csv(collection, filename, &block)
    require 'csv'
    
    csv_data = CSV.generate(headers: true) do |csv|
      yield csv, collection
    end
    
    send_csv_data(csv_data, filename)
  end
end
