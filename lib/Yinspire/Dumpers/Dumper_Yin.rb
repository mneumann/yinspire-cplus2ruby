require 'Yinspire/Dumpers/Dumper'
require 'enumerator'

class Dumper_Yin < Dumper

  def initialize(*args)
    super
    @verbose = true
  end

  def dump(out)
    ekeys = @entities.keys.sort
    ekeys.each {|key|
      entity = @entities[key]
      out << "ENTITY " if @verbose
      out << to_yin_str(entity.id)
      out << " = #{to_yin_str(entity.entity_type)} "
      out << to_yin_str(entity.dump)
      out << "\n"
    }

    ekeys.each {|key|
      entity = @entities[key]
      targets = []; entity.each_connection {|t| targets << to_yin_str(t.id)}
      next if targets.empty?

      out << "CONNECT " if @verbose
      out << "#{to_yin_str(entity.id)} -> #{targets.join(', ')}\n"
    }

    ekeys.each {|key|
      entity = @entities[key]
      next unless entity.respond_to?(:stimuli_pq_to_a)
      stimuli = entity.stimuli_pq_to_a
      next if stimuli.empty?

      out << "\n"
      out << "STIMULATE " if @verbose
      out << "#{to_yin_str(entity.id)} ! {\n  "

      out << stimuli.to_enum(:each_slice, 2).
        map {|at, weight| 
          if weight == Infinity
            to_yin_str(at)
          else
            "#{to_yin_str(weight)}@#{to_yin_str(at)}"
          end
        }.to_enum(:each_slice, 5).map {|arr| arr.join(" ")}.join("\n  ")

      out << "\n}\n"
    }
  end

  def to_yin_str(obj)
    case obj
    when String
      if obj =~ /^\w+$/
        obj
      else
        '"' + obj + '"'
      end
    when Symbol
      to_yin_str(obj.to_s)
    when Hash
      out = ""
      out << "{\n"
      obj.keys.sort_by {|k| k.to_s}.each do |k|
        out << "  " if @verbose
        out << "#{to_yin_str(k)} = #{to_yin_str(obj[k])}\n"
      end
      out << "}\n"
      out
    when TrueClass, FalseClass, Float, Fixnum, Bignum
      obj.to_s
    else
      raise "#{obj.class}"
    end
  end

end
