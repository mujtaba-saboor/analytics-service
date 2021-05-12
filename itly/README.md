# Itly

Iteratively Ruby SDK

## Installation

Add this line to your application's Gemfile:

```ruby
# Gemfile
gem 'itly', path: './itly'
```

And then execute:
```markdown
~/my/project/$ bundle install
```

## Usage

```ruby
require 'itly'

Itly.load do |options|
  options.environment = ENV['APP_ENV'] || :development
  options.destinations.amplitude = {}
  options.destinations.mixpanel = {}
  options.destinations.segment = {}
  options.disabled = false
  options.logger = Logger.new(STDOUT) # or your custom Logger
  options.set_context(
    required_string: 'required_string',
    optional_enum: 'Context1'
  )
end

user_id = 'current-user-id'
group_id = 'user-group-id'

Itly.identify(user_id, required_float: 1.0)
Itly.group(user_id, group_id, required_boolean: true, optional_string: 'optional_string')

Itly.event_no_properties(user_id)

Itly.event_with_all_properties(user_id,
  required_array: [],
  required_boolean: true,
  required_const: 'some-const-value',
  required_enum: 'Enum1',
  required_float: 1.0,
  required_integer: 1,
  required_null: nil,
  required_string: 'required_string'
)
```