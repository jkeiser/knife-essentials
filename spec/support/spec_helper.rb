require 'support/file_system_support'

CHEF_SPEC_DATA = File.join(File.dirname(File.dirname(__FILE__)), 'data')

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

