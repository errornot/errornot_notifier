require 'rack/utils'
RSpec::Matchers.define :have_content do |key, content|
  match do |document|
    document = Rack::Utils.parse_nested_query(document)
    key =~ /([^\[]+)(\[([^\]]+)\])?(\[([^\]]+)\])?(\[([^\]]+)\])?/
    one = $1
    two = $3
    three = $5
    four = $7
    if one
      @elements = document.send("[]", one)
    end
    if two
      @elements = @elements.send("[]", two)
    end
    if three
      @elements = @elements.send("[]", three)
    end
    if four
      @elements = @elements.send("[]", four)
    end
    unless @elements
      false
    else
      @elements == content
    end
  end

  failure_message_for_should do |document|
    unless @elements
      "In JSON:\n#{document}\nNo element at #{key}"
    else
      "In JSON:\n#{document}\nGot content #{@elements.inspect} at #{key} instead of #{content.inspect}"
    end
  end

  failure_message_for_should_not do |document|
    if @elements
      "In JSON:\n#{document}\nExpcted no content #{content.inspect} at #{key}"
    end
  end
end
