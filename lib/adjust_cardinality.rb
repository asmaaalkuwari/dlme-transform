# frozen_string_literal: true

require 'active_support/core_ext/hash/except'

# Given a data structure from traject, transform it into a valid IR by changing
# some values from arrays to scalars
class AdjustCardinality
  def self.call(attributes)
    new(attributes).call
  end

  def initialize(attributes)
    @source = attributes
  end

  attr_reader :source

  def call
    flatten_web_resources(flatten_top_level(source))
  end

  def flatten_top_level(attributes)
    fields_to_flatten = Settings.fields.to_flatten.top_level
    attributes.except(*fields_to_flatten).tap do |output|
      fields_to_flatten.each do |field|
        next unless attributes.key?(field)

        value = attributes.fetch(field).first
        output[field] = value
      end
    end
  end

  def flatten_web_resources(attributes)
    fields_to_flatten = Settings.fields.to_flatten.web_resources
    attributes.except(*fields_to_flatten).tap do |output|
      fields_to_flatten.each do |field|
        value = attributes[field]
        next unless value

        output[field] = flatten_web_resource(value)
      end
    end
  end

  def flatten_web_resource(web_resource)
    # For handling agg_has_view, which is an array.
    if web_resource.is_a?(Array)
      web_resource.map { |wr| process_web_resource(wr) }
    else
      process_web_resource(web_resource)
    end
  end

  def process_web_resource(web_resource)
    res = process_node(web_resource, %w[wr_id])
    res.except('wr_has_service').tap do |resource|
      resource['wr_has_service'] = flatten_services(res.fetch('wr_has_service')) if res.key?('wr_has_service')
    end
  end

  def flatten_services(services)
    services.map { |svc| process_service(svc) }
  end

  def process_service(service)
    process_node(service, %w[service_id service_implements])
  end

  def process_node(original, fields)
    original.except(*fields).tap do |corrected|
      fields.each do |field|
        corrected[field] = original.fetch(field).first
      end
    end
  end
end
