# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: ignore
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/activemodel/all/activemodel.rbi
#
# activemodel-6.1.4.4

module ActiveModel
  def self.eager_load!; end
  def self.gem_version; end
  def self.version; end
  extend ActiveSupport::Autoload
end
module ActiveModel::VERSION
end
module ActiveModel::Serializers
  extend ActiveSupport::Autoload
end
class ActiveModel::Attribute
  def ==(other); end
  def _original_value_for_database; end
  def assigned?; end
  def came_from_user?; end
  def changed?; end
  def changed_from_assignment?; end
  def changed_in_place?; end
  def encode_with(coder); end
  def eql?(other); end
  def forgetting_assignment; end
  def has_been_read?; end
  def hash; end
  def init_with(coder); end
  def initialize(name, value_before_type_cast, type, original_attribute = nil, value = nil); end
  def initialize_dup(other); end
  def initialized?; end
  def name; end
  def original_attribute; end
  def original_value; end
  def original_value_for_database; end
  def self.from_database(name, value_before_type_cast, type, value = nil); end
  def self.from_user(name, value_before_type_cast, type, original_attribute = nil); end
  def self.null(name); end
  def self.uninitialized(name, type); end
  def self.with_cast_value(name, value_before_type_cast, type); end
  def type; end
  def type_cast(*arg0); end
  def value; end
  def value_before_type_cast; end
  def value_for_database; end
  def with_cast_value(value); end
  def with_type(type); end
  def with_value_from_database(value); end
  def with_value_from_user(value); end
end
class ActiveModel::Attribute::FromDatabase < ActiveModel::Attribute
  def _original_value_for_database; end
  def type_cast(value); end
end
class ActiveModel::Attribute::FromUser < ActiveModel::Attribute
  def came_from_user?; end
  def type_cast(value); end
end
class ActiveModel::Attribute::WithCastValue < ActiveModel::Attribute
  def changed_in_place?; end
  def type_cast(value); end
end
class ActiveModel::Attribute::Null < ActiveModel::Attribute
  def initialize(name); end
  def type_cast(*arg0); end
  def with_cast_value(value); end
  def with_type(type); end
  def with_value_from_database(value); end
  def with_value_from_user(value); end
end
class ActiveModel::Attribute::Uninitialized < ActiveModel::Attribute
  def forgetting_assignment; end
  def initialize(name, type); end
  def initialized?; end
  def original_value; end
  def value; end
  def value_for_database; end
  def with_type(type); end
end
class ActiveModel::AttributeSet
  def ==(other); end
  def [](name); end
  def []=(name, value); end
  def accessed; end
  def attributes; end
  def deep_dup; end
  def default_attribute(name); end
  def each_value(**, &&); end
  def except(**, &&); end
  def fetch(**, &&); end
  def fetch_value(name, &block); end
  def freeze; end
  def initialize(attributes); end
  def initialize_clone(_); end
  def initialize_dup(_); end
  def key?(name); end
  def keys; end
  def map(&block); end
  def reset(key); end
  def to_h; end
  def to_hash; end
  def values_before_type_cast; end
  def write_cast_value(name, value); end
  def write_from_database(name, value); end
  def write_from_user(name, value); end
end
class ActiveModel::AttributeSet::Builder
  def build_from_database(values = nil, additional_types = nil); end
  def default_attributes; end
  def initialize(types, default_attributes = nil); end
  def types; end
end
class ActiveModel::LazyAttributeSet < ActiveModel::AttributeSet
  def additional_types; end
  def attributes; end
  def default_attribute(name, value_present = nil, value = nil); end
  def default_attributes; end
  def fetch_value(name, &block); end
  def initialize(values, types, additional_types, default_attributes, attributes = nil); end
  def key?(name); end
  def keys; end
  def types; end
  def values; end
end
class ActiveModel::LazyAttributeHash
  def ==(other); end
  def [](key); end
  def []=(key, value); end
  def additional_types; end
  def assign_default_value(name); end
  def deep_dup; end
  def default_attributes; end
  def delegate_hash; end
  def each_key(&block); end
  def each_value(**, &&); end
  def except(**, &&); end
  def fetch(**, &&); end
  def initialize(types, values, additional_types, default_attributes, delegate_hash = nil); end
  def initialize_dup(_); end
  def key?(key); end
  def marshal_dump; end
  def marshal_load(values); end
  def materialize; end
  def transform_values(**, &&); end
  def types; end
  def values; end
end
class ActiveModel::AttributeSet::YAMLEncoder
  def decode(coder); end
  def default_types; end
  def encode(attribute_set, coder); end
  def initialize(default_types); end
end
class ActiveModel::Error
  def ==(other); end
  def attribute; end
  def attributes_for_hash; end
  def base; end
  def detail; end
  def details; end
  def eql?(other); end
  def full_message; end
  def hash; end
  def i18n_customize_full_message; end
  def i18n_customize_full_message=(arg0); end
  def i18n_customize_full_message?; end
  def initialize(base, attribute, type = nil, **options); end
  def initialize_dup(other); end
  def inspect; end
  def match?(attribute, type = nil, **options); end
  def message; end
  def options; end
  def raw_type; end
  def self.full_message(attribute, message, base); end
  def self.generate_message(attribute, type, base, options); end
  def self.i18n_customize_full_message; end
  def self.i18n_customize_full_message=(value); end
  def self.i18n_customize_full_message?; end
  def strict_match?(attribute, type, **options); end
  def type; end
end
class ActiveModel::NestedError < ActiveModel::Error
  def initialize(base, inner_error, override_options = nil); end
  def inner_error; end
  def message(*args, &block); end
  extend Forwardable
end
class ActiveModel::Errors
  def [](attribute); end
  def add(attribute, type = nil, **options); end
  def add_from_legacy_details_hash(details); end
  def added?(attribute, type = nil, options = nil); end
  def any?(*args, &block); end
  def as_json(options = nil); end
  def attribute_names; end
  def blank?(*args, &block); end
  def clear(*args, &block); end
  def copy!(other); end
  def count(*args, &block); end
  def delete(attribute, type = nil, **options); end
  def deprecation_removal_warning(method_name, alternative_message = nil); end
  def deprecation_rename_warning(old_method_name, new_method_name); end
  def details; end
  def each(&block); end
  def empty?(*args, &block); end
  def errors; end
  def full_message(attribute, message); end
  def full_messages; end
  def full_messages_for(attribute); end
  def generate_message(attribute, type = nil, options = nil); end
  def group_by_attribute; end
  def has_key?(attribute); end
  def import(error, override_options = nil); end
  def include?(attribute); end
  def init_with(coder); end
  def initialize(base); end
  def initialize_dup(other); end
  def key?(attribute); end
  def keys; end
  def marshal_load(array); end
  def merge!(other); end
  def messages; end
  def messages_for(attribute); end
  def normalize_arguments(attribute, type, **options); end
  def objects; end
  def of_kind?(attribute, type = nil); end
  def size(*args, &block); end
  def slice!(*keys); end
  def to_a; end
  def to_h; end
  def to_hash(full_messages = nil); end
  def to_xml(options = nil); end
  def uniq!(*args, &block); end
  def values; end
  def where(attribute, type = nil, **options); end
  extend Forwardable
  include Enumerable
end
class ActiveModel::DeprecationHandlingMessageHash < SimpleDelegator
  def []=(attribute, value); end
  def delete(attribute); end
  def initialize(errors); end
  def prepare_content; end
end
class ActiveModel::DeprecationHandlingMessageArray < SimpleDelegator
  def <<(message); end
  def clear; end
  def initialize(content, errors, attribute); end
end
class ActiveModel::DeprecationHandlingDetailsHash < SimpleDelegator
  def initialize(details); end
end
class ActiveModel::StrictValidationFailed < StandardError
end
class ActiveModel::RangeError < RangeError
end
class ActiveModel::UnknownAttributeError < NoMethodError
  def attribute; end
  def initialize(record, attribute); end
  def record; end
end
class ActiveModel::MissingAttributeError < NoMethodError
end
module ActiveModel::AttributeMethods
  def _read_attribute(attr); end
  def attribute_method?(attr_name); end
  def attribute_missing(match, *args, &block); end
  def matched_attribute_method(method_name); end
  def method_missing(method, *args, &block); end
  def missing_attribute(attr_name, stack); end
  def respond_to?(method, include_private_methods = nil); end
  def respond_to_without_attributes?(*arg0); end
  extend ActiveSupport::Concern
end
module ActiveModel::AttributeMethods::ClassMethods
  def alias_attribute(new_name, old_name); end
  def attribute_alias(name); end
  def attribute_alias?(new_name); end
  def attribute_method_affix(*affixes); end
  def attribute_method_matchers_cache; end
  def attribute_method_matchers_matching(method_name); end
  def attribute_method_prefix(*prefixes); end
  def attribute_method_suffix(*suffixes); end
  def define_attribute_method(attr_name, _owner: nil); end
  def define_attribute_methods(*attr_names); end
  def define_proxy_call(include_private, code_generator, name, target, *extra); end
  def generated_attribute_methods; end
  def instance_method_already_implemented?(method_name); end
  def undefine_attribute_methods; end
end
class ActiveModel::AttributeMethods::ClassMethods::CodeGenerator
  def <<(source_line); end
  def execute; end
  def initialize(owner, path, line); end
  def rename_method(old_name, new_name); end
  def self.batch(owner, path, line); end
end
class ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher
  def initialize(options = nil); end
  def match(method_name); end
  def method_name(attr_name); end
  def prefix; end
  def suffix; end
  def target; end
end
class ActiveModel::AttributeMethods::ClassMethods::AttributeMethodMatcher::AttributeMethodMatch < Struct
  def attr_name; end
  def attr_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def target; end
  def target=(_); end
end
module ActiveModel::AttributeMethods::AttrNames
  def self.define_attribute_accessor_method(owner, attr_name, writer: nil); end
end
