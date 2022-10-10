# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `kramdown-parser-gfm` gem.
# Please instead update this file by running `bin/tapioca gem kramdown-parser-gfm`.

module Kramdown
  class << self
    def data_dir; end
  end
end

module Kramdown::Options
  class << self
    def defaults; end
    def define(name, type, default, desc, &block); end
    def defined?(name); end
    def definitions; end
    def merge(hash); end
    def parse(name, data); end
    def simple_array_validator(val, name, size = T.unsafe(nil)); end
    def simple_hash_validator(val, name); end
    def str_to_sym(data); end
  end
end

Kramdown::Options::ALLOWED_TYPES = T.let(T.unsafe(nil), Array)

class Kramdown::Options::Definition < ::Struct
  def default; end
  def default=(_); end
  def desc; end
  def desc=(_); end
  def name; end
  def name=(_); end
  def type; end
  def type=(_); end
  def validator; end
  def validator=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

module Kramdown::Parser; end

class Kramdown::Parser::GFM < ::Kramdown::Parser::Kramdown
  def initialize(source, options); end

  def generate_gfm_header_id(text); end
  def paragraph_end; end
  def parse; end
  def parse_atx_header_gfm_quirk; end
  def parse_list; end
  def parse_strikethrough_gfm; end
  def update_elements(element); end
  def update_raw_text(item); end

  private

  def update_text_type(element, child); end
end

Kramdown::Parser::GFM::ATX_HEADER_START = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::ESCAPED_CHARS_GFM = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::FENCED_CODEBLOCK_MATCH = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::FENCED_CODEBLOCK_START = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::LIST_TYPES = T.let(T.unsafe(nil), Array)
Kramdown::Parser::GFM::NON_WORD_RE = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::PARAGRAPH_END_GFM = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::STRIKETHROUGH_DELIM = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::STRIKETHROUGH_MATCH = T.let(T.unsafe(nil), Regexp)
Kramdown::Parser::GFM::VERSION = T.let(T.unsafe(nil), String)
Kramdown::VERSION = T.let(T.unsafe(nil), String)