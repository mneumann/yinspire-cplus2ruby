#
# Load a neuronal net from GraphML format.
#
# Copyright (c) 2007, 2008 by Michael Neumann (mneumann@ntecs.de)
#

require 'Yinspire/Loaders/Loader'
require 'Yinspire/Loaders/GraphML'

class Loader_GraphML < Loader

  TYPE_MAP = {
    'NEURONTYPE_KBLIF' => 'Neuron_SRM01',
    'NEURONTYPE_EKERNEL' => 'Neuron_SRM02',
    'SYNAPSE_DEFAULT' => 'Synapse',
    'SYNAPSE_HEBB' => 'Synapse_Hebb'
  }

  PARAM_MAP = {
    'absRefPeriod' => ['abs_refr_duration', 'real'],
    'neuronLFT' => ['last_fire_time', 'real'],
    'neuronLSET' => ['last_spike_time', 'real'],
    'neuron_tauM' => ['tau_m', 'real'],
    'neuron_tauRef' => ['tau_ref', 'real'],
    'neuron_constThreshold' => ['const_threshold', 'real'],
    'neuron_refWeight' => ['ref_weight', 'real'],
    'neuron_arpTime' => ['abs_refr_duration', 'real'],
    'synapse_weight' => ['weight', 'real'],
    'synapse_delay' => ['delay', 'real'],
    'neuronPSP' => ['mem_pot', 'real'],
    'neuronReset' => ['reset', 'real'],
    'neuron_tauM' => ['tau_m', 'real'],
    'neuron_tauRecov' => ['tau_ref', 'real'],
    'neuron_uReset' => ['u_reset', 'real'],
    'neuron_threshold' => ['const_threshold', 'real']
  }

  def load(file)
    File.open(file) do |f|
      gml = GraphML.parse(f)
      g = gml.graphs.values.first
      default_neuron_type = g.data['graph_default_neuron_type']
      default_synapse_type = g.data['graph_default_synapse_type']

      #
      # Create Neurons
      #
      g.nodes.each_value {|node|
        create(node.id, node.data, default_neuron_type, 'neuron_type')
      }

      # 
      # Create Synapses
      #
      g.edges.each_value {|edge|
        create(edge.id, edge.data, default_synapse_type, 'synapse_type')
      }

      #
      # Create Connections between Neurons and Synapses.
      #
      g.edges.each_value {|edge|
        a = @entities[edge.source.id] || raise
        b = @entities[edge.id] || raise
        c = @entities[edge.target.id] || raise
        a.connect(b)
        b.connect(c)
      }
    end
  end

  protected

  #
  # Parameter +kind+ is either of "neuron_type" or "synapse_type".
  #
  def create(id, data, default_type, kind)
    entity_type = (TYPE_MAP[data[kind] || default_type] || raise)
    data.delete(kind)
    create_entity(entity_type, id, conv_params(data))
  end

  def conv_params(data)
    hash = {}
    data.each {|k,v|
      name, type = PARAM_MAP[k] || raise
      case type
      when 'real'
        hash[name] = v.strip.to_f
      else
        raise
      end
    }
    return hash
  end

end
