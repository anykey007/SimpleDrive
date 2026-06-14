Rails.autoloaders.main.ignore(Rails.root.join("app/storage"))

require_dependency Rails.root.join("app/storage/base").to_s
require_dependency Rails.root.join("app/storage/filesystem").to_s
require_dependency Rails.root.join("app/storage/s3").to_s
require_dependency Rails.root.join("app/storage/factory").to_s
