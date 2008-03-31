require 'Yinspire/Dumpers/Dumper'

#
# Dumper for the GraphViz[1] dot format.
#
# Only dumps the net, not the stimulis.
#
# [1]: http://www.graphviz.org/
#
class Dumper_Dot < Dumper

  #
  # NOTE: Unconnected synapses are not shown.
  #
  def dump(out)
    out << "digraph {\n"
    out << "node [shape = circle];\n"

    @entities.each_value {|entity|
      next unless entity.kind_of?(Neuron) 
      entity.each_connection do |syn|
        out << "#{entity.id.inspect} -> #{syn.post_neuron.id.inspect} [label = #{syn.id.inspect} ];\n"
      end
    }
    out << "}\n"
  end

end
