#
# Pretty print Ruby objects as JSON
#
# Copyright (c) 2007 by Michael Neumann (mneumann@ntecs.de)
#

require 'prettyprint'

class Hash
  def to_json(pp)
    ks = keys
    pp.group(1, '{', '}') {
      ks.each_with_index do |k, i|
        v = self[k]

        pp.group {
	  pp.text k.to_s.to_json(true) 
	  pp.text ':'
	  pp.group(1) {
	    pp.breakable ' '
	    case v
	    when Hash, Array
	      v.to_json(pp)
	    else
	      pp.text v.to_json
	    end
	  }

	  if i < ks.size-1
	    pp.text ","
	    pp.breakable
	  end
	}
      end
    }
  end
end

class Array
  def to_json(pp)
    pp.group(1, "[", "]") {
      each_with_index do |v, i|
        pp.group {
	  case v
	  when Hash, Array
	    v.to_json(pp)
	  else
	    pp.text v.to_json
	  end

	  if i < size()-1
	    pp.text ","
	    pp.breakable ' '
	  end
	}
      end
    }
  end
end

class TrueClass
  TRUE = "true".freeze
  def to_json
    TRUE
  end
end

class FalseClass
  FALSE = "false".freeze
  def to_json
    FALSE
  end
end

class NilClass
  NULL = "null".freeze
  def to_json
    NULL
  end
end

class Fixnum
  alias to_json to_s
end

class Bignum
  alias to_json to_s
end

class Float
  alias to_json to_s
end

class String
  def to_json(label=false)
    label = false # FIXME
    if label and self =~ /^[A-Za-z_][A-Za-z0-9_]*$/
      self
    else
      inspect
    end
  end
end

class Symbol
  def to_json(label=false)
    to_s.to_json(label)
  end
end

def json_pp(obj, out=STDOUT, width=79)
  case obj
  when Array, Hash
    q = PrettyPrint.new(out, width)
    obj.to_json(q)
    q.flush
  else
    out << obj.to_json
  end
  out << "\n"
  return out
end
