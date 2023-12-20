file_path = Rails.root + "config/build_version.yml"
raw_config = File.exists?(file_path) ? File.read(file_path) : ""
config = YAML.load(raw_config)
Rails.application.config.build_version = config ? config.symbolize_keys : nil