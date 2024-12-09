class ImportTask < ApplicationRecord
  include ImportFileUploader::Attachment(:file)

  enum :status, in_queue: 0, in_progress: 1, failed: 2, successful: 3
end
