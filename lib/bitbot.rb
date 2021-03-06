require 'mongoid'
require_relative 'models'
require_relative 'utility'
require_relative 'error'

module BitBot
  extend self

  def definitions
    @definitions ||= {}
  end

  def define(name, mod=nil, &block)
    definition_module = Module.new
    definition_module.send(:include, mod) unless mod.nil?
    definition_module.send(:include, Module.new(&block)) if block_given?
    adapters.delete(name.to_sym)
    definitions[name.to_sym] = definition_module
  end

  def adapters
    @adapters ||= {}
  end

  def [](name)
    adapters[name.to_sym] ||= get_adapter_instance(name)
  end

  private
  def get_adapter_instance(name)
    Class.new do
      attr_reader :logger
      attr_accessor :rate
      def initialize(options = {})
        @options = options
        @logger = options[:logger]
        @rate = options[:rate] || 1
        @key = options[:key] || ENV["#{name}_key"]
        @secret = options[:secret] || ENV["#{name}_secret"]
      end

      include BitBot.definitions[name.to_sym]

      def eql?(other)
        self.class.eql?(other.class) && client == other.client
      end
      alias == eql?

      ### Avoid to output key and secret to log files uncarefully
      def as_json(*); name end
      def to_s(*)
        "[BitBot:#{name}]"
      end
      alias_method :inspect, :to_s
      alias_method :to_json, :to_s

      def rate
        @rate.is_a?(Proc) ? @rate.call : @rate
      end

      class_eval "def name; :#{name} end"

      include BitBot::Utility
    end
  end
end
