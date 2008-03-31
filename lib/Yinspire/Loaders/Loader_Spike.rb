require 'Yinspire/Loaders/Loader'

#
# Loader for spikes in the format:
#
#   Id1 weight1@time1 time2 time3 ...
#   Id2 time1 time2 time3 ...
#   ...
#
# Weight values (e.g. 1.0@time1) are optional. 
#
# Lines beginning with "#" are comments.
#
class Loader_Spike < Loader

  def load(filename)
    File.open(filename, 'r') do |f|
      while line = f.gets
        line.strip!
        next if line =~ /^#/ # comment

        #
        # The following code is to help Matlab to generate spike trains
        # more easily and allows spaces before and after the "@", e.g.
        # "123 @ 444".
        #
        line.gsub!(/\s+@\s+/, '')

        id, *spikes = line.split
        raise if spikes.empty?
        entity = @entities[id] || raise

        spikes.each do |spike|
          weight, at = spike.split("@") 
          weight, at = Infinity, weight if at.nil? # spike is a pure time-value
          entity.stimulate(at.to_f, weight.to_f, nil)
        end
      end
    end
  end

end
