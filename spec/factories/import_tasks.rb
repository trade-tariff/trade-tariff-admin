FactoryBot.define do
  factory :import_task do
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'search_references.csv'), 'text/csv') }
  end
end
