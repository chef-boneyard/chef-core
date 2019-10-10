placeholder

# Chef Core
[![Gem Version](https://badge.fury.io/rb/chef-chef-core.svg)](https://badge.fury.io/rb/chef-core)

Chef Core provides low-level tools for building Chef workflows. It contains the subset of
functionality that we extracted from `chef-run` for use across CLI tools.

This gem still has rough edges. Work is in progress on the following:

- Class/API documentation
- Reducing complexity of error handling
- Usage examples

For real-life usage of `chef-core` components, see the [chef-run](https://github.com/chef/chef-apply)
implementation.

## Connectivity

`chef-core` provides an interface to Train via `ChefCore::TargetHost`.  This is a light wrapper
around Train that encapsulates the process of setting up and acquiring the underlying connection. `chef-core` also has
platform-specific awareness of how to perform common operations on the
remote host, such as file delete, package installation, directory and tempdir creation.
It currently supports Linux and Windows platforms using ssh or winrm protocols.

Connection options can be found in the [train](https://github.com/inspec/train.git) repository.


## i18n

chef-core provides an i18n interface via `ChefCore::Text`.  This sits atop [r18n](https://github.com/r18n/r18n)
and allows you to define text definitions for your gem. To use this,
create a `i18n/LANG.yml` file where LANG is the language (eg 'en', 'fr') and ensure it
is distributed as part of your gem build.  During your application's
start-up, call `ChefCore::Text.add_gem_localization('your-gem-name')` to load the localizations.


The default language is English. If a translation is defined in the default language, but not in
the current language, it will fall back to the English version.


Example: 18n/en.yml
```yml
product_name: Chef Core
sample:
  text_element_1: |
    This text will be pulled in as-is
  pluralized_thing: !!pl
    1:
      Just one thing!
    n:
      Many things!
hello_something:
  Hello %1!

```

Usage:

```ruby
require 'chef_core/text'
T = ChefCore::Text
T.add_gem_localization("my-gem")
# ...

puts "Product: #{T.product_name}"
puts "Element 1: #{T.sample.text_element_1}"
puts "A thing: #{T.sample.pluralized_thing(1)}"
puts "Another thing: #{T.sample.pluralized_thing(100)}"
puts "Parameterized: #{T.hello_something('world')"
```

Produces:

```
Product: Chef Core
Element 1: This text will be pulled in as-is
A thing: Just one thing!
Another thing: Many things!
Parameterized: Hello world!
```

### Usage Notes

1. If a key is not found on any lookup, it will raise `ChefCore::Text::InvalidKey`.  The exception
   message will include the file and the line on which the invalid key was referenced, and the full key name.
2. If you define an entry in your `en.yml` file that is already defined (such as in another gem already loaded),
   the most recently loaded version of the entry will be used in all places that reference it, including
   other gems that loaded first.
3. The top-level key 'errors' is used by chef-core's error rendering. Do not add a top-level
   `errors` key in your `i18n/en.yml`.  Instead, errors should be added to `i18n/errors/en.yml`, under the key
   `errors`.


## Error Rendering

Any exception can be passed into `ChefCore::CLIUX::UI::ErrorPrinter.show_error`.

If the exception has a method `id`, that ID will be used to look up the error text and rendering
definition. See the 'error definitions' section below.

When you invoke `ChefCore::Text#add_gem_localization`, the error table in `i18n/errors/LANG.yml` will
also be loaded.

The interface described here may change as we discover new requirements in the process of
rolling out standardized error handling across repositories.

### Error Definitions

Error definitions in `errors/LANG.yml` contain error metadata that indicate how the error message
should be formatted. Defaults for all messages can be
found in [chef-core/i18n/errors/en.yml](https://github.com/chef/chef-core/blob/master/i18n/errors/en.yml#L54)
under the key `errors.display_defaults`.

Each error definition is located under the key 'errors' in your `i18n/errors/LANG.yml`, with
a name that matches the error ID.  It will have up to two sub-keys:

* `text`: the error message.
* `options`: optional quoted json strong with error message display options. If not provided,
             defaults taken from `chef-core/i18n/errors/en.yml`, `display_defaults`.
             Supported display options:
  *  `header` - boolean, when true the error ID is shown as the first line of the error, in bold if supported.
  *  `stack` - include a line indicating where a stack trace has been saved.
  *  `log` - include a line indicating where log file(s) have been saved.
  *  `footer` - include the default footer which will contain stack/log locations
  *  `decorations` - boolean, false means all decorations (header, footer, etc) are not shown.


`display_defaults` is defined in `chef-core/i18n/errors/en.yml` and controls
what display options are used when a given error message does not specify options. This
can be overridden in your errors/LANG.yml, for example:

```yml
errors:
  display_defaults: "{ decorations: true, stack: false, log: false, header: true, footer: false }"
```


Error message should be in the following format:

```yml
errors:
  YOURERRORID:
    options: options-json-string
    text: text to use for this message

```

Sample error definition (i18n/errors/en.yml):

```yml
errors:
  BADFILE001:
    options: " { decorations: true, stack: true, log: true, footer: true} "
    text: |
      File extension '%1' is unsupported. Currently recipes must be specified with a `.rb` extension.
```

```ruby
# Inheriting from ChefCore::Error is optional, but your exception must provide an `id` method. If your
# error does inherit from ChefCore::Error, argument handling will be done automatically.

class MyError < ChefCore::Error
  def initialize()
    super("BADFILE001", "exe")
  end
end

ChefCore::ErrorPrinter.show_error(MyError.new, {stack_trace_path: '/my/stack', log_location: 'my/log'})`
```

Output given the display defaults and the definition above:

```
BADFILE001

File extension 'exe' is unsupported. Use '.rb' instead.

If you are not able to resolve this issue, please contact Chef support
at workstation@chef.io and include the log file and stack trace from the locations
below:

  /my/stack
  my/log
```

As seen in the example, BADFILE001 takes a parameter. Your exception will need to provide a member 'parameters'
that returns a list of error message parameters. Exceptions derived from `ChefCore::Error` will take
care of this for you.  You may also note references to Chef support and email address - this is the default
message footer, which is described in the next section.


### Overriding Common Elements

Several common elements are defined in `chef-core/i18n/errors/en.yml`. It is likely that you'll want to
override these in your own `errors/LANG.yml`:

* `footer` - contains footers to show when decorations = true, footer = true.  Content
             will vary based on whether `stack` and `log` are true.  Contains separate subkeys:
  * `both` - footer to display when both stack and log are true
  * `log_only` - text when only log is true
  * `stack_only` - text when only stack is true
  * `neither` - text when neither one is true
* `header` - display the message header, which is the error ID.


## Actions

The gem `chef-core-actions` (same repository) includes pre-defined actions that can be run such as installing Chef
client on a remote system, or converging a remote system; and a light framework for defining
additional actions. Our intent with this component is to build a library of reusable actions
that are shared across Chef tooling and beyond.

Actions evolved out of some of our early `chef-run` work, when we were looking to provide
multiple new tools with common functionality. They were developed to provide self-contained
actions that have no direct interface to the user/terminal or any external configuration providers.
This makes them well-suited for use in any existing CLI tool, even if that tool is not making
use of Chef Core.

This framework is minimal - it defines a base class, and invokes provided overrides/callbacks.
Invoking the actions is left to the calling application.
A well-written, shareable Action...

* ...informs the listener of what it's doing via :notify, so that the listener can pass it along to the operator
in whatever way is appropriate for the application.
* ...does not perform any user-facing actions, such as requesting input or displaying results.
* ...has no knowledge of configuration options loaded from an external system. All configuration is pulled
in from the configuration provided to the constructor via instance method `#config`.  This allows the
action to be used in any application without concerns resulting from tying in to a given configuration method.
* ...does not expose a public interface other than `perform_action`. All other outputs are communicated via
notifications.
* ...will be named to describe an action and not a thing. For example, `FindFile` is preferable to `FileFinderAction`.
* ...does only what it says it will do.


Pre-defined actions in `chef-actions` are thread-safe, because they may be run in
a background thread depending on how your UI is structured.  `chef-apply` runs them in
background threads in order to manage multiple concurrent action executions.

Your actions need not adhere to these requirements, but only those that do adhere can be considered
for inclusion in `chef-actions`.

### Error Handling

Any unhandled exception in an action is re-raised, but only after invoking `notify(:error, exception)`.
This gives the caller a chance to perform any cleanup in the notification handler - particularly helpful
when the action is running on a different thread, in which case the exception may never be seen by
your main thread (depending on your Ruby configuration).

To define an action, create a class that inherits from `ChefCore::Actions::Base` and implement
`perform_action`. Here's an example:

### Simple Example
```ruby
require 'chef-core/actions'
module MyApp
  module Actions
    class FindSomething < ChefCore::Actions::Base

      def perform_action
        notify(:looking_for_something, config[:search_criteria])

        # Just sleep instead of doing anything. For future performance
        # improvement, reduce the sleep time.
        sleep(1)

        notify(:found, config[:search_criteria], "/home")

        raise "Ooops"
      end
    end
  end
end
```

To invoke the action:

```ruby
require 'my_app/actions/find_something'

criteria = gets("What should I search for?").chomp
action = LookForSomething.new(search_criteria: criteria)
action.run do |event, *args|
  case event
  when :looking
    puts "Searching for #{args[0]}"
  when :found
    puts "I found it! You can pick it up here: #{args[0]}
  when :error
    # Make sure we define :error - the framework notifies with this
    # an perform_action raises an unhandled exception
    puts "I'm sorry, something happened: #{args[0].to_s}
end

```

Output:

```
What should I search for?
blah

Searching for blah
I found it! You can pick it up here: /home
I'm sorry, something happened: Ooops
```


### Real-life Usage

[chef-apply](https://github.com/chef/chef-apply/blob/2a2b5d75641bc7fd0aaf3d12dd195a57cbdb9180/lib/chef_apply/cli.rb#L148) makes use
of actions in a multi-threaded CLI that can perform actions simultaneously across multiple hosts.


## CLI User Experience

More information coming here as we determine if what we have now is the right shape for future CLI tool
development.


## Contributing/Development

Please read our [Community Contributions Guidelines](https://docs.chef.io/community_contributions.html), and ensure you are signing all your commits with DCO sign-off.

The general development process is:

1. Fork this repo and clone it to your workstation.
2. Run `bundle install --with development`
2. Create a feature branch for your change.
3. Write code and tests.
4. Push your feature branch to GitHub and open a pull request against master.


# License

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Copyright:**       | Copyright 2018-2019, Chef Software, Inc.
| **License:**         | Apache License, Version 2.0

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
 
