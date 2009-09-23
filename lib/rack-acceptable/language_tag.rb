module Rack #:nodoc:
  module Acceptable #:nodoc:

    # inspired by the 'langtag' gem (author: Martin Dürst)
    # http://rubyforge.org/projects/langtag/
    # http://www.langtag.net/
    #
    class LanguageTag

      path = IO.read(::File.expand_path(::File.join(::File.dirname(__FILE__), 'data', 'grandfathered_language_tags.yml')))
      GRANDFATHERED_TAGS = YAML.load(path)

      attr_accessor :primary, :extlang, :script, :region, :variants, :extensions, :privateuse

      #--
      # RFC 5646, sec. 2.2.2:
      # Although the ABNF production 'extlang' permits up to three
      # extended language tags in the language tag, extended language
      # subtags MUST NOT include another extended language subtag in
      # their 'Prefix'.  That is, the second and third extended language
      # subtag positions in a language tag are permanently reserved and
      # tags that include those subtags in that position are, and will
      # always remain, invalid.
      #++

      language    = '([a-z]{2,8}|[a-z]{2,3}(?:-[a-z]{3})?)'
      script      = '(?:-([a-z]{4}))?'
      region      = '(?:-([a-z]{2}|\d{3}))?'
      variants    = '(?:-[a-z\d]{5,8}|-\d[a-z\d]{3})*'
      extensions  = '(?:-[a-wy-z\d]{1}(?:-[a-z\d]{2,8})+)*'
      privateuse  = '(?:-x(?:-[a-z\d]{1,8})+)?'

      LANGTAG_COMPOSITION_REGEX   = /^#{language}#{script}#{region}(?=#{variants}#{extensions}#{privateuse}$)/o.freeze
      LANGTAG_INFO_REGEX          = /^#{language}#{script}#{region}(#{variants})#{extensions}#{privateuse}$/o.freeze
      PRIVATEUSE_REGEX            = /^x(?:-[a-z\d]{1,8})+$/i.freeze

      PRIVATEUSE = 'x'.freeze
      GRANDFATHERED = 'i'.freeze

      class << self

        def privateuse?(tag)
          PRIVATEUSE_REGEX === tag
        end

        def grandfathered?(tag)
          GRANDFATHERED_TAGS.key?(tag) || GRANDFATHERED_TAGS.key?(tag.downcase)
        end

        # ==== Parameters
        # langtag<String>:: The Language-Tag snippet.
        #
        # ==== Returns
        # Array or nil::
        #   It returns +nil+, when the Language-Tag passed:
        #   * does not conform the Language-Tag ABNF (malformed)
        #   * grandfathered
        #   * starts with 'x' singleton ('privateuse').
        #
        #   Otherwise you'll get an +Array+ with:
        #   * primary subtag (as +String+, downcased),
        #   * extlang (as +String+, downcased) or +nil+,
        #   * script (as +String+, capitalized) or +nil+,
        #   * region (as +String+, upcased) or +nil+
        #   * downcased variants (+Array+) or nil.
        #
        # ==== Notes
        # In most cases, it's quite enough. Take a look, for example, at
        # {'35-character recomendation'}[http://tools.ietf.org/html/rfc5646#section-4.6].
        #
        def extract_language_info(langtag)
          tag = langtag.downcase
          return nil if GRANDFATHERED_TAGS.key?(tag)
          return nil unless LANGTAG_INFO_REGEX === tag

          primary     = $1
          extlang     = nil
          script      = $2
          region      = $3
          variants    = $4.split(Utils::HYPHEN_SPLITTER)[1..-1]

          primary, extlang = primary.split(Utils::HYPHEN_SPLITTER) if primary.include?(Const::HYPHEN)
          script.capitalize! if script
          region.upcase! if region

          [primary, extlang, script, region, variants]
        end

        def parse(thing)
          return nil unless thing
          return thing if thing.kind_of?(self)
          tag = self.allocate
          tag.recompose!(thing)
          tag
        end

      end

      def has_variant?(variant)
        return false unless @variants
        @variants.include?(variant) || @variants.include?(variant.downcase)
      end

      def has_singleton?(key)
        return false unless @extensions
        @extensions.key?(key) || @extensions.key?(key.downcase)
      end

      alias :extension? :has_singleton?

      def singletons
        return nil unless @extensions
        keys = @extensions.keys
        keys.sort!
        keys
      end

      def extended?
        raise NotImplementedError
      end

      def initialize(*components)
        raise ArgumentError, "Primary subtag could not be nil" if components.empty?
        @primary, @extlang, @script, @region, @variants, @extensions, @privateuse = *components
        #recompose!(to_s)
      end

      def to_s
        cs = [@primary]
        cs << @extlang if @extlang
        cs << @script if @script
        cs << @region if @region
        cs.concat @variants if @variants
        @extensions.keys.sort.each { |s| (cs << s).concat @extensions[s] } if @extensions
        (cs << PRIVATEUSE).concat @privateuse if @privateuse
        cs.join(Const::HYPHEN)
      end

      def candidates
        raise NotImplementedError
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        ss = self.to_s
        os = other.to_s
        ss == os || ss.downcase == os.downcase
      end

      def ===(other)
        if other.respond_to?(:to_s)
          ss = self.to_s
          os = other.to_s
          ss == os || ss.downcase == os.downcase
        else
          false
        end
      end

      # Validates self.
      #
      # ==== Notes
      # Validation is deferred by default, because the paranoid
      # check & dup of everything is not a good way (in this case).
      # So, you may create some tags, make them malformed/invalid,
      # and still be able to compare and modify them. But when you'll
      # try to get the composition of the invalid tag, or, for example,
      # a list of candidates to lookup, there'll be a proper exception.
      #
      def validate!
        recompose!
      end

      # ==== Parameters
      # thing<String, optional>::
      #   The Language-Tag snippet
      #
      # ==== Returns
      # +nil+
      #
      # ==== Raises
      # ArgumentError::
      #   The Language-Tag passed:
      #   * does not conform the Language-Tag ABNF (malformed)
      #   * grandfathered
      #   * starts with 'x' singleton ('privateuse').
      #   * contains duplicate variants
      #   * contains duplicate singletons
      #
      def recompose!(thing = nil)

        tag = if thing
          raise TypeError, "Can't convert #{thing.class} into String" unless thing.respond_to?(:to_str)
          thing.to_str
        else
          to_s
        end

        return if @composition == tag || @_composition == (tag = tag.downcase)

        if GRANDFATHERED_TAGS.key?(tag)
          raise ArgumentError, "Grandfathered Language-Tag: #{thing.inspect}"
          # TODO: optional support for grandfathered tags.
        end

        if LANGTAG_COMPOSITION_REGEX === tag

          @primary = $1
          @extlang    = nil
          @script     = $2
          @region     = $3
          components  = $'.split(Utils::HYPHEN_SPLITTER)
          components.shift

          @primary, @extlang = @primary.split(Utils::HYPHEN_SPLITTER) if @primary.include?(Const::HYPHEN)

          @script.capitalize! if @script
          @region.upcase! if @region

          @extensions = nil
          @variants   = nil
          singleton   = nil

          while c = components.shift
            if c.size == 1
              break if c == PRIVATEUSE
              @extensions ||= {}
              if @extensions.key?(c)
                raise ArgumentError, "Invalid Language-Tag (repeated singleton: #{c.inspect}): #{thing.inspect}"
              end
              @extensions[singleton = c] = []
            elsif singleton
              @extensions[singleton] << c # why Arrays? Because of truncate (lookup) algorithm.
            else
              @variants ||= []
              if @variants.include?(c)
                raise ArgumentError, "Invalid Language-Tag (repeated variant: #{c.inspect}): #{thing.inspect}"
              end
              @variants << c
            end
          end

          @privateuse = components.empty? ? nil : components
          @composition = to_s
          @_composition = @composition.downcase

        else
          raise ArgumentError, "Malformed or 'privateuse' Language-Tag: #{thing.inspect}"
        end

        nil
      end

    end

  end
end

# EOF