require 'yaml'
require 'enumerator'

class String
  def to_yin_str
    if self =~ /^\w+$/
      self
    else
      '"' + self + '"'
    end
  end
end

class TrueClass; alias to_yin_str to_s end
class FalseClass; alias to_yin_str to_s end
class Float; alias to_yin_str to_s end
class Fixnum; alias to_yin_str to_s end
class Bignum; alias to_yin_str to_s end

class Hash
  def to_yin_str(out="")
    out << "{\n"
    self.keys.sort.each do |k|
      out << "  " if $verbose
      out << "#{k.to_yin_str} = #{self[k].to_yin_str}\n"
    end
    out << "}\n"
  end
end

data = YAML.load(STDIN.read)
out = STDOUT
$verbose = true

raise unless data['format'] == 'yinspire.c'

#data['entities'] = nil
#data['templates'] = nil
#data['connections'] = nil

#
# Write out templates
#

templates = data["templates"] || {}
if $verbose and !templates.empty?
  out << "#\n"
  out << "# Templates\n"
  out << "#\n\n"
end

templates.keys.sort.each do |key|
  base_type, base_data = *templates[key]

  out << "TEMPLATE " if $verbose
  out << "#{key.to_yin_str} < #{base_type.to_yin_str}"
  if base_data and not base_data.empty?
    out << " "
    base_data.to_yin_str(out)
  else
    out << "\n"
  end
  out << "\n" if $verbose
end


#
# Write out entities
#

entities = data["entities"] || [] 
if $verbose and !entities.empty?
  out << "#\n"
  out << "# Entities\n"
  out << "#\n\n"
end

group_by = {}
entities.each do |id, type, edata|
  key = [type, edata]
  group_by[key] ||= []
  group_by[key] << id
end


group_by.keys.sort_by {|type, _| type}.each do |key|
  type, edata = *key
  ids = group_by[key]
  out << "ENTITY " if $verbose
  out << ids.sort.map {|id| id.to_yin_str}.enum_for(:each_slice, 8).map {|sl|
    sl.join(", ")
  }.join(",\n  ")
   
  out << " = #{ type.to_yin_str }"


  if edata and not edata.empty?
    out << " "
    edata.to_yin_str(out)
  else
    out << "\n"
  end
  out << "\n" if $verbose
end

#
# Write out connections
#

connections = data["connections"] || []
if $verbose and !connections.empty?
  out << "#\n"
  out << "# Connections\n"
  out << "#\n\n"
end

connections.each do |arr|
  src, *targets = *arr
  out << "CONNECT " if $verbose
  out << "#{src.to_yin_str} -> "

  out << targets.map {|t| t.to_yin_str}.enum_for(:each_slice, 8).map {|sl|
    sl.join(", ")
  }.join(",\n  ")
  out << "\n"

  out << "\n" if $verbose
end

#
# Write out stimuli
#

events = data["events"] || {} 
if $verbose and !events.empty?
  out << "#\n"
  out << "# Stimulations\n"
  out << "#\n\n"
end

events.keys.sort.each do |key|
  ev = events[key]
  next if ev.empty?

  out << "STIMULATE " if $verbose
  out << "#{key.to_yin_str} ! {\n"

  out << " "
  char_pos = 1

  ev.each do |e|
    str = e.to_yin_str 
    if char_pos > 40 && char_pos+str.size > 75
      out << "\n "
      char_pos = 1
    end
    out << " "
    out << str 
    char_pos += 1 + str.size
  end

  out << "\n}\n"

  out << "\n" if $verbose
end
