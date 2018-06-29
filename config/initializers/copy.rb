COPY = Module.new

json_obj = JSON.parse(File.read(File.join(Rails.root, "client", "COPY.json")))
json_obj.keys.each { |k| COPY.const_set(k, json_obj[k]) }
