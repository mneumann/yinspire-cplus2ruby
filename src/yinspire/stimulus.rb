# 
# The data structure used for storing a fire impluse or any other form
# of stimulation.
#
class Stimulus

  cplus2ruby :no_wrap => true
  cplus2ruby :order => -1 

  property :at, :simtime
  property :weight, :real

  static_method :less, {:a => 'const Stimulus&'}, {:b => 'const Stimulus&'}, {:returns => 'bool'}, %{
    return (a.at < b.at);
  }, :inline => true

  #
  # Appends +at+ and +weight+ to the Ruby array passed as +ary+.
  #
  static_method :dump_to_a, {:s => 'const Stimulus&'},{:ary => 'void*'}, %{
    rb_ary_push(*((VALUE*)ary), rb_float_new(s.at));
    rb_ary_push(*((VALUE*)ary), rb_float_new(s.weight));
  }

end
