module Mint
  class Parser
    syntax_error HereDocExpectedStart
    syntax_error HereDocExpectedEnd

    def here_doc_part(token : String)
      gather do
        while char != '\0' && !keyword_ahead?(token)
          break if char == '#' &&
                   next_char == '{' &&
                   prev_char != '\\'
          step
        end
      end
    end

    def here_doc(with_interpolation : Bool = true) : Ast::HereDoc?
      start do |start_position|
        next unless keyword "<<"
        next unless char!('~') || char!('#') || char!('-')

        modifier =
          prev_char

        head =
          gather { chars &.ascii_uppercase? }

        tail =
          gather { chars { |char| char.ascii_uppercase? || char.ascii_number? || char == '_' } }

        raise HereDocExpectedStart unless head || tail

        token =
          "#{head}#{tail}"

        value = many(parse_whitespace: false) { here_doc_part(token) || interpolation }

        raise HereDocExpectedEnd unless keyword(token)

        Ast::HereDoc.new(
          from: start_position,
          modifier: modifier,
          value: value,
          to: position,
          input: data,
          token: token)
      end
    end
  end
end
