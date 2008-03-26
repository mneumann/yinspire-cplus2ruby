require 'Yinspire/Loaders/Loader'
require 'Yinspire/Loaders/YinScanner'

#
# This is a human readable data format for describing neural nets
# as well as stimulations.
#
# Note that it is a streaming scanner/parser, i.e. it's important
# to put the template definitions before you actually use them.
# The same applies to stimulations and connections!
#
class Loader_Yin < Loader
  require 'enumerator'

  def load(filename)
    @entities = Hash.new
    templates = {}
    hash = Hash.new
    YinScanner.new(File.read(filename)).scan do |cmd|
      case cmd.shift
      when :entity
        ids, type, prop_list = *cmd

        hash.clear
        if t = templates[type]
          type, template_data = *t
          hash.update(template_data) if template_data
        end
        hash.update(prop_list) if prop_list

        ids.each {|id| create_entity(type, id, hash) }
      when :connect
        cmd.each_cons(2) do |from, to|
          from.each {|f|
            entity = @entities[f] 
            to.each {|t| entity.connect(@entities[t]) }
          }
        end
      when :stimulate
        ids, stimuls = *cmd

        ids.map! {|id| @entities[id] }

        stimuls.each do |sti|
          at, weight = *sti
          weight ||= Infinity 
          ids.each {|entity|
            entity.stimulate(at, weight, nil)
          }
        end
      when :template
        ids, base_type, prop_list = *cmd
        ids.each do |id|
          raise if templates[id]
          templates[id] = [base_type, prop_list] 
        end
      else
        raise
      end
    end
  end

end
