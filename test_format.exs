# Test to see what's happening
Code.require_file("lib/mq.ex")
Code.require_file("lib/mq/options.ex")
Code.require_file("lib/mq/result.ex")
Code.require_file("lib/mq/native.ex")

options = %Mq.Options{input_format: :text}
map = Mq.Options.to_map(options)
IO.inspect(map, label: "Map sent to Rust")

result = Mq.run("select(contains(\"2\"))", "Line 1\nLine 2\nLine 3", options)
IO.inspect(result, label: "Result")
