Given /^Cuke4Lua started with no step definition modules$/ do
  # TODO
  run_in_background %{lua #{cuke4lua_server}}
end

Given /^Cuke4Lua started with a step definition module containing:$/ do |contents|
  # TODO
  module_path = build_step_definitions(contents)
  run_in_background %{lua #{cuke4lua_server} "#{module_path}"}
end

Given /^a step definition module containing:$/ do |contents|
  @last_module_path = build_step_definitions(contents)
end

When /^I run the cuke4lua wrapper$/ do
  ruby_path = Cucumber::RUBY_BINARY.gsub('/', '\\')
  run %{"#{ruby_path}" "#{cuke4lua_wrapper_path}" "#{@last_module_path}" -b --no-color -f progress features}
end
