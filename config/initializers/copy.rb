Rails.application.config.before_initialize do
  COPY = Module.new

  json_obj = JSON.parse(File.read(File.join(Rails.root, "client", "COPY.json")))
  json_obj.each_key { |k| COPY.const_set(k, json_obj[k]) }
end
