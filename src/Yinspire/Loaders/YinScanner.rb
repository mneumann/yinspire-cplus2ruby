class YinScanner
  require 'strscan'

  def initialize(str)
    @s = StringScanner.new(str)
    @inf = 1.0/0.0
  end

  def scan
    while cmd = scan_command()
      yield cmd
    end
    skip_ws()
    raise "ParseError" unless @s.eos?
  end

  protected

  def skip_ws
    while @s.skip(/(\s+)/) or # skip whitespace
          @s.skip(/[#](.*)/) # skip comments
    end
  end

  def scan_property
    pos = @s.pos
    if name = scan_id()
      skip_ws()
      if @s.skip(/=/)
        value = scan_value()
        if value != nil
          return name, value
        end
      end
    end

    @s.pos = pos
    return nil
  end

  def scan_command
    skip_ws()
    type = nil
    if str = @s.scan(/(TEMPLATE|ENTITY|CONNECT|STIMULATE)\s+/)
      str.strip!
      str.downcase!
      type = str.to_sym
    end

    ids = scan_idlist()
    raise "ParseError" if type != nil and ids.empty?
    return nil if ids.empty?

    scanned_type = scan_type()

    raise "ParseError" if (type and type != scanned_type) or scanned_type.nil?

    case scanned_type
    when :entity, :template
      id = scan_id()
      raise "ParseError" unless id
      prop_list = scan_propertylist()
      return scanned_type, ids, id, prop_list  
    when :stimulate
      stimuls = scan_stimulationlist()
      raise "ParseError" unless stimuls
      return scanned_type, ids, stimuls
    when :connect
      conns = [] 
      conns << ids
      loop do
        l = scan_idlist()
        break if l.empty?
        conns << l

        skip_ws()
        break unless @s.skip(/->/)
      end
      raise "ParseError" if conns.size < 2
      return scanned_type, conns
    else
      nil
    end
  end

  def scan_propertylist
    pos = @s.pos
    skip_ws()
    props = {}
    if @s.skip(/[{]/)
      loop do
        name, value = scan_property() 
        break unless name
        props[name] = value
      end
      skip_ws()
      return props if @s.skip(/[}]/)
    end

    @s.pos = pos
    return nil
  end

  def scan_value
    skip_ws()
    if str = @s.scan(/[+-]?[0-9]+([.][0-9]+([eE][+-]?[0-9]+)?)?/)
      str.to_f
    elsif @s.skip(/[+]?Inf(inity)?/i)
      @inf
    elsif @s.skip(/[-]?Inf(inity)?/i)
      -@inf
    elsif @s.skip(/true/)
      true
    elsif @s.skip(/false/)
      false
    else
      nil
    end
  end

  # no skip_ws!
  def scan_float
    if str = @s.scan(/[+-]?[0-9]+([.][0-9]+([eE][+-]?[0-9]+)?)?/)
      str.to_f
    elsif @s.skip(/[+]?Inf(inity)?/i)
      @inf
    elsif @s.skip(/[-]?Inf(inity)?/i)
      -@inf
    else
      nil
    end
  end

  def scan_stimulationlist
    pos = @s.pos
    skip_ws()
    stimuls = [] 
    if @s.skip(/[{]/)
      loop do
        arr = scan_stimulation()
        break unless arr
        stimuls << arr
      end
      skip_ws()
      return stimuls if @s.skip(/[}]/)
    end

    @s.pos = pos
    return nil
  end

  # [weight@]at
  # no skip_ws!
  # 
  def scan_stimulation
    pos = @s.pos
    skip_ws()

    if at = scan_float()
      if @s.skip(/@/) 
        weight = at
        if at = scan_float()
          return at, weight
        end
      else
        return at
      end
    end

    @s.pos = pos
    return nil
  end

  def scan_id
    pos = @s.pos
    skip_ws()
    if @s.skip(/["]/)
      id = @s.scan(/[^"]+/)
      unless @s.skip(/["]/)
        @s.pos = pos
        id = nil
      end
    else
      id = @s.scan(/\w+/)
    end
    return id
  end

  def scan_idlist
    ids = []
    loop do
      id = scan_id()
      break unless id
      ids << id
      skip_ws()
      break unless @s.skip(/,/) # we expect a "," here
    end
    ids
  end

  def scan_type
    skip_ws()
    if    @s.skip(/[=]/) then :entity
    elsif @s.skip(/->/)  then :connect
    elsif @s.skip(/[!]/) then :stimulate
    elsif @s.skip(/[<]/) then :template
    else
      nil
    end
  end
end

if __FILE__ == $0
  s = YinScanner.new(<<-EOS)
  #
  # This is a comment
  # This also.
  #
  # Command names like "TEMPLATE", "ENTITY", "CONNECT" and "STIMULATE"
  # are optional.
  #

  TEMPLATE InputType < Neuron_Input {
    const_threshold = +1.2e+200
    last_spike_time = -Infinity
  }

  ENTITY Input1, "input2", Input2, Input3 = InputType
  ENTITY Input4 = InputType

  Input5, Input6 = Neuron_SRM01 {
    mem_pot = 10.0
  }

  Syn1, Syn2, Syn3 = Synapse {
    weight = 2.3
    delay = 0.4
  }

  CONNECT Input1 -> Syn1, Syn2 -> Input5 

  STIMULATE Input1, Input5 ! {
    123@4.4 Inf@23.3 4.5  # weight defaults to Infinity
  }
  EOS
  s.scan {|cmd| p cmd}
end
