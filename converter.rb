require 'yaml'
require 'json_writer'

# format changes:
#
# * neuron/synapse type names changed
# * property names changed
# * no longer post_neuron, pre_neuron, instead connections.
# 

old = YAML.load(File.read('/tmp/gereon2005'))
new = {}
new['format'] = 'yinspire.1'
new['templates'] = {}
entities = new['entities'] = {}
connections = new['connections'] = {}
new['events'] = old['events']

#
# convert templates
#
old['templates'].each do |name, hash|

  type =
  case hash.delete("type") 
  when 'Synapse_Default' then 'Synapse'
  when 'Neuron_KernelBasedLIF' then 'Neuron_SRM_01'
  else
    raise
  end

  if abs_ref_duration = hash.delete('abs_ref_duration')
    hash['abs_refr_duration'] = abs_ref_duration
  end

  new['templates'][name] = [type, hash] 
end



#
# convert entities and connections
#
old['net'].each do |hash|
  template = hash.delete('_')
  post_neuron = hash.delete('post_neuron')
  pre_neuron = hash.delete('pre_neuron')
  id = hash.delete('id') || raise

  if post_neuron
    connections[id] ||= []
    connections[id] << post_neuron 
  end

  if pre_neuron
    connections[pre_neuron] ||= []
    connections[pre_neuron] << id 
  end

  if hash.empty?
    entities[id] = template
  else
    entities[id] = [template, hash]
  end
end

# new2 is efficient for jsonParser/jsonHash which
# is implemented as a linked list.
def to_new2(new)
  new2 = Hash.new
  new2['format'] = 'yinspire.2'
  new2['templates'] = new['templates']
  entities = new2['entities'] = [] 
  connections = new2['connections'] = []
  new['entities'].each do |id, v|
    entities << [id, v].flatten
  end

  new['connections'].each do |from, to|
    connections << [from, to].flatten
  end

  new2['events'] = new['events']

  return new2
end

#puts YAML.dump(new)
#new = to_new2(new)
json_pp(new)
