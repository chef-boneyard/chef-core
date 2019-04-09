#
# Copyright:: Copyright (c) 2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef_core/target_host"
require "chef_core/error"

module ChefCore

  # This class will resolve a provided target host name to
  # one or more TargetHost instances.  The target host name passed in
  # to the constructor can contain up to two ranges in the form [0-9] and [a-z].
  # Multiple target host names can be passed in asa comma-separated list.
  #
  # Use resolver_inst.targets to get the expanded list of TargetHost instances.
  class TargetResolver
    MAX_EXPANDED_TARGETS = 24
    SUPPORTED_PROTOCOLS = %w{winrm ssh}
    def initialize(target, default_protocol, conn_options, max_expanded_targets: MAX_EXPANDED_TARGETS)
      @max_expanded_targets = max_expanded_targets
      @default_proto = default_protocol
      @unparsed_target = target
      @split_targets = @unparsed_target.split(",")
      @conn_options = conn_options.dup
      @default_password = @conn_options.delete(:password)
      @default_user = @conn_options.delete(:user)
    end

    # Returns the list of targets as an array of TargetHost instances
    def targets
      return @targets unless @targets.nil?
      expanded_urls = []
      @split_targets.each do |target|
        expand_targets(target).each { |t| expanded_urls << t }
      end

      # Apply max_expanded_targets to the total list of resolved
      # targets, since multiple targets can be comma-separated.
      # Limiting it only in the expression resolver could still
      # yield more than the maximum.
      if expanded_urls.length > @max_expanded_targets
        raise TooManyTargets.new(expanded_urls.length, @max_expanded_targets)
      end

      @targets = expanded_urls.map do |url|
        config = @conn_options.merge(config_for_target(url))
        TargetHost.new(config.delete(:url), config)
      end
    end

    def config_for_target(url)
      prefix, target = prefix_from_target(url)

      inline_password = nil
      inline_user = nil
      host = target
      # Default greedy-scan of the regex means that
      # $2 will resolve to content after the final "@"
      # URL credentials will take precedence over the default :user
      # in @conn_opts
      if target =~ /(.*)@(.*)/
        inline_credentials = $1
        host = $2
        # We'll use a non-greedy match to grab everthinmg up to the first ':'
        # as username if there is no :, credentials is just the username
        if inline_credentials =~ /(.+?):(.*)/
          inline_user = $1
          inline_password = $2
        else
          inline_user = inline_credentials
        end
      end
      user, password = make_credentials(inline_user, inline_password)
      { url: "#{prefix}#{host}",
        user: user,
        password: password }
    end

    # Merge the inline user/pass with the default user/pass, giving
    # precedence to inline.
    def make_credentials(inline_user, inline_password)
      user = inline_user || @default_user
      user = nil if user && user.empty?
      password = (inline_password || @default_password)
      password = nil if password && password.empty?
      [user, password]
    end

    def prefix_from_target(target)
      if target =~ /^(.+?):\/\/(.*)/
        # We'll store the existing prefix to avoid it interfering
        # with the check further below.
        if SUPPORTED_PROTOCOLS.include? $1.downcase
          prefix = "#{$1}://"
          target = $2
        else
          raise UnsupportedProtocol.new($1)
        end
      else
        prefix = "#{@default_proto}://"
      end
      [prefix, target]
    end

    def expand_targets(target)
      @current_target = target # Hold onto this for error reporting
      do_parse([target.downcase])
    end

    private

    # A string matching PREFIX[x:y]POSTFIX:
    # POSTFIX can contain further ranges itself
    # This uses a greedy match (.*) to get include every character
    # up to the last "[" in PREFIX
    # $1 - prefix; $2 - x, $3 - y, $4 unproccessed/remaining text
    TARGET_WITH_RANGE = /^(.*)\[([\p{Alnum}]+):([\p{Alnum}]+)\](.*)/.freeze

    def do_parse(targets, depth = 0)
      raise TooManyRanges.new(@current_target) if depth > 2
      new_targets = []
      done = false
      targets.each do |target|
        if TARGET_WITH_RANGE =~ target
          # $1 - prefix; $2 - x, $3 - y, $4 unprocessed/remaining text
          expand_range(new_targets, $1, $2, $3, $4)
        else
          # Nothing more to expand
          done = true
          new_targets << target
        end
      end
      if done
        new_targets
      else
        do_parse(new_targets, depth + 1)
      end
    end

    def expand_range(dest, prefix, start, stop, suffix)
      prefix ||= ""
      suffix ||= ""
      start_is_int = Integer(start) >= 0 rescue false
      stop_is_int = Integer(stop) >= 0 rescue false

      if (start_is_int && !stop_is_int) || (stop_is_int && !start_is_int)
        raise InvalidRange.new(@current_target, "[#{start}:#{stop}]")
      end

      # Ensure that a numeric range doesn't get created as a string, which
      # would make the created Range further below fail to iterate for some values
      # because of ASCII sorting.
      if start_is_int
        start = Integer(start)
      end

      if stop_is_int
        stop = Integer(stop)
      end

      # For range to iterate correctly, the values must
      # be low,high
      if start > stop
        temp = stop; stop = start; start = temp
      end
      Range.new(start, stop).each do |value|
        # Ranges will resolve only numbers and letters,
        # not other ascii characters that happen to fall between.
        if start_is_int || /^[a-z0-9]/ =~ value
          dest << "#{prefix}#{value}#{suffix}"
        end
        # Stop expanding as soon as we go over limit to prevent
        # making the user wait for a massive accidental expansion
        if dest.length > @max_expanded_targets
          raise TooManyTargets.new(@split_targets.length, @max_expanded_targets)
        end
      end
    end
    # Provide an error base for all targetresolver errors, to simplify
    # handling when caller is not concerned with the specific failure.
    class TargetResolverError  < ChefCore::Error; end

    class InvalidRange < TargetResolverError
      def initialize(unresolved_target, given_range)
        super("CHEFRANGE001", unresolved_target, given_range)
      end
    end

    class TooManyRanges < TargetResolverError
      def initialize(unresolved_target)
        super("CHEFRANGE002", unresolved_target)
      end
    end

    class TooManyTargets < TargetResolverError
      def initialize(num_top_level_targets, max_targets)
        super("CHEFRANGE003", num_top_level_targets, max_targets)
      end
    end

    class UnsupportedProtocol < TargetResolverError
      def initialize(attempted_protocol)
        super("CHEFVAL011", attempted_protocol,
              ChefCore::TargetResolver::SUPPORTED_PROTOCOLS.join(" "))
      end
    end
  end
end
