RSpec.describe "Retired legacy note pages", type: :request do
  %w[/notes/sections /notes/chapters/01/chapter_note /xi/notes/sections /xi/notes/chapters/01/chapter_note].each do |path|
    it "returns not found for #{path}" do
      get path

      expect(response).to have_http_status(:not_found)
    end
  end
end
