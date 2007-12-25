#
# Cplus2Ruby
#
# Gluing C++ and Ruby together in an Object-oriented manner.  
#
# Author::    Michael Neumann
# Copyright:: (c) 2007 by Michael Neumann (mneumann@ntecs.de)
# License::   Released under the same terms as Ruby itself.
#

module Cplus2Ruby

  # 
  # Global code
  #
  def self.<<(code)
    model.code << code
  end

  def self.model
    @model ||= Cplus2Ruby::Model.new
  end

  def self.add_type_alias(h)
    model.add_type_alias(h)
  end

  #
  # Called when Cplus2Ruby is included in another module or a class.
  #
  def self.append_features(mod)
    super
    mod.extend(self)
    Cplus2Ruby.model[mod] # this will register the class
    # also register a subclass
    def mod.inherited(k)
      Cplus2Ruby.model[k]
    end
  end

  ###################################

  def public(*args)
    # FIXME
    super
  end

  def protected(*args)
    # FIXME
    super
  end

  def private(*args)
    # FIXME
    super
  end

  def property(name, type=Object, options={})
    Cplus2Ruby.model[self].add_property(name, type, options)
  end

  def method(name, params, body=nil, options={})
    Cplus2Ruby.model[self].add_method(name, params, body, options)
  end 

  def helper_header(body)
    Cplus2Ruby.model[self].add_helper_header(body)
  end

  def helper_code(body)
    Cplus2Ruby.model[self].add_helper_code(body)
  end

  def self.generate_code(mod)
    cg = Cplus2Ruby::CodeGenerator.new(Cplus2Ruby.model)
    cg.write(mod)
  end

  #
  # Compiles +file+ and loads it.
  #
  def self.compile_and_load(file, cflags="", libs="")
    require 'rbconfig'
    require 'win32/process' if RUBY_PLATFORM.match('mswin')
    require 'fileutils'

    base = File.basename(file)
    dir = File.dirname(file)
    mod, ext = base.split(".") 

    FileUtils.mkdir_p(dir)

    make = RUBY_PLATFORM.match('mswin') ? 'nmake' : 'make'

    Dir.chdir(dir) do
      self.generate_code(mod)
      system("#{make} clean") if File.exist?('Makefile')

      #pid = fork do
        require 'mkmf'
        $CFLAGS = cflags
        $LIBS << (" " + libs)
        create_makefile(mod)
        system "#{make}" # exec
      #end
      #_, status = Process.waitpid2(pid)

      #if RUBY_PLATFORM.match('mswin')
      #  raise if status != 0
      #else
      #  raise if status.exitstatus != 0
      #end
    end
    require "#{dir}/#{mod}.#{Config::CONFIG['DLEXT']}"
  end

end

class Cplus2Ruby::Model
  attr_reader :type_aliases, :type_map, :code

  def initialize
    @model_classes = Hash.new
    @type_aliases = Hash.new
    @type_map = get_type_map()
    @code = ""

    add_type_alias Object => 'VALUE'
  end

  def add_type_alias(h)
    @type_aliases.update(h)
  end

  def expand_type_map!
    @type_aliases.each do |from, to|
      @type_map[from] = @type_map[to]
    end

    each_model_class do |m|
      @type_map[m.klass] = object_type_map(m.klass.name)
    end
  end

  def [](klass)
    @model_classes[klass] ||= Cplus2Ruby::Model::ModelClass.new(klass)
  end

  def each_model_class(&block)
    @model_classes.each_value(&block)
  end

  # 
  # Returns a C++ declaration
  #
  def type_encode(type, name)
    if entry = @type_map[type]
      entry[:ctype].gsub("%s", name.to_s)
    else
      "#{type} #{name}"
    end
  end

  def get_type_entry(type)
    @type_map[type] || {}
  end

  protected

  def object_type_map(type)
    {
      default: '%s = NULL',
      mark:    'if (%s) rb_gc_mark(%s->__obj__)',
      ruby2c:  "(NIL_P(%s) ? NULL : (#{type}*)DATA_PTR(%s))",
      c2ruby:  '(%s ? %s->__obj__ : Qnil)', 
      ctype:   "#{type} *%s",
      ruby2c_checktype: 'if(!NIL_P(%s)) Check_Type(%s, T_DATA)'
    }
  end

  def get_type_map
    { 
      'VALUE' => {
        default: '%s = Qnil',
        mark:    'rb_gc_mark(%s)',
        ruby2c:  '%s',
        c2ruby:  '%s',
        ctype:   'VALUE %s' 
      },
      'float' => {
        default: '%s = 0.0',
        ruby2c:  '(float)NUM2DBL(%s)',
        c2ruby:  'rb_float_new(%s)',
        ctype:   'float %s'
      },
      'double' => {
        default: '%s = 0.0',
        ruby2c:  '(double)NUM2DBL(%s)',
        c2ruby:  'rb_float_new(%s)',
        ctype:   'double %s'
      },
      'int' => {
        default: '%s = 0',
        ruby2c:  '(int)NUM2INT(%s)',
        c2ruby:  'INT2NUM(%s)',
        ctype:   'int %s'
      },
      'unsigned int' => {
        default: '%s = 0',
        ruby2c:  '(unsigned int)NUM2INT(%s)',
        c2ruby:  'INT2NUM(%s)',
        ctype:   'unsigned int %s'
      },
      'bool' => { 
        default: '%s = false',
        ruby2c:  'RTEST(%s)',
        c2ruby:  '(%s ? Qtrue : Qfalse)',
        ctype:   'bool %s'
      },
      'void' => {
        c2ruby:  'Qnil',
        ctype:   'void'
      }
    }
  end
end

class Cplus2Ruby::Model::ModelClass
  attr_accessor :klass, :properties, :methods, :helper_headers, :helper_codes

  def initialize(klass)
    @klass = klass
    @properties = []
    @methods = []
    @helper_headers = []
    @helper_codes = []
  end

  def add_property(name, type, options)
    @properties << Cplus2Ruby::Model::ModelProperty.new(name, type, options) 
  end

  def add_helper_header(body)
    @helper_headers << body
  end

  def add_helper_code(body)
    @helper_codes << body
  end

  def add_method(name, params, body, options)
    @methods << Cplus2Ruby::Model::ModelMethod.new(name, params, body, options)
  end
end


class Cplus2Ruby::Model::ModelProperty
  attr_accessor :name, :type, :options
  def initialize(name, type, options)
    @name, @type, @options = name, type, options
  end
end

class Cplus2Ruby::Model::ModelMethod
  attr_accessor :name, :params, :body, :options
  def initialize(name, params, body, options)
    @name, @params, @body, @options = name, params, body, options
  end

  def arity
    n = @params.size
    n -= 1 if @params.include?(:returns)
    return n
  end
end

class Cplus2Ruby::CodeGenerator
  def initialize(model=Cplus2Ruby.model)
    @model = model
    @model.expand_type_map!
  end

  def write(mod_name)

    #
    # mod_name.h
    #
    File.open(mod_name + ".h", 'w+') do |out| 
      header(out)
      type_aliases(out)

      out << @model.code

      forward_class_declarations(out)
      helper_headers(out)
      class_declarations(out)
    end
    
    #
    # mod_name.cc
    #
    File.open(mod_name + ".cc", 'w+') do |out| 
      out << %{#include "#{mod_name}.h"\n\n}
      class_bodies(out)
    end
    
    #
    # mod_name_wrap.cc
    #
    File.open(mod_name + "_wrap.cc", 'w+') do |out| 
      out << %{#include "#{mod_name}.h"\n\n}

      ruby_method_wrappers(out)
      ruby_property_wrappers(out)

      ruby_alloc(out)
      ruby_init(mod_name, out)
    end
  end

  def ruby_alloc(out)
    @model.each_model_class do |mk|
      out << "static VALUE\n"
      out << "#{mk.klass.name}_alloc__(VALUE __klass__)\n"
      out << "{\n"

      # Declare C++ object
      out << @model.type_encode(mk.klass, "__cobj__")
      out << ";\n"

      out << "__cobj__ = new #{mk.klass.name}();\n"
      out << "__cobj__->__obj__ = "
      out << "Data_Wrap_Struct(__klass__, RubyObject::__mark, RubyObject::__free, __cobj__);\n"

      out << "return __cobj__->__obj__;\n"
      out << "}\n"
    end
  end

  def ruby_method_wrappers(out)
    @model.each_model_class do |mk|
      mk.methods.each do |meth|
        next if meth.options[:internal]

        params = meth.params.dup
        returns = params.delete(:returns) || 'void'

        out << "static VALUE\n"
        out << "#{mk.klass.name}_wrap__#{meth.name}"
        out << "("
        out << (["VALUE __self__"] + params.map {|n,_| "VALUE #{n}"}).join(", ")
        out << ")\n"
        out << "{\n"

        # declare C++ return value 
        if returns != 'void'
          out << @model.type_encode(returns, "__res__") 
          out << ";\n"
        end

        # declare C++ object
        out << @model.type_encode(mk.klass, "__cobj__")
        out << ";\n"
        
        # convert __self__ to C++ object pointer
        ## FIXME: can remove!
        out << "Check_Type(__self__, T_DATA);\n"
        out << "__cobj__ = (#{mk.klass.name}*) DATA_PTR(__self__);\n"

        # check argument types
        params.each { |n, t| check_type(n, t, out) }
        
        # call arguments 
        cargs = params.map {|n, t| @model.get_type_entry(t)[:ruby2c].gsub('%s', n.to_s) }

        # build method call
        out << "__res__ = " if returns != 'void'

        out << "__cobj__->#{meth.name}(#{cargs.join(', ')});\n"

        # convert return value
        retv = @model.get_type_entry(returns)[:c2ruby].gsub('%s', '__res__')

        out << "  return #{retv};\n"
        out << "}\n"
      end
    end
  end

  def ruby_mark(model_class, out)
    out << "void #{model_class.klass.name}::__mark__() {\n"

    model_class.properties.each do |prop|
      if mark = prop.options[:mark] || @model.get_type_entry(prop.type)[:mark]
        out << mark.gsub('%s', "@#{prop.name}")
        out << ";\n"
      end
    end

    out << "super::__mark__();\n"

    out << "}\n"
  end

  def ruby_property_wrappers(out)
    @model.each_model_class do |mk|
      mk.properties.each do |prop|
        next if prop.options[:internal]

        ## getter
        out << "static VALUE\n"
        out << "#{mk.klass.name}_get__#{prop.name}(VALUE __self__)\n"
        out << "{\n"

        # declare C++ object
        out << @model.type_encode(mk.klass, "__cobj__")
        out << ";\n"
        
        # convert __self__ to C++ object pointer
        ## FIXME: can remove!
        out << "Check_Type(__self__, T_DATA);\n"
        out << "__cobj__ = (#{mk.klass.name}*) DATA_PTR(__self__);\n"
       
        # convert return value
        retv = @model.get_type_entry(prop.type)[:c2ruby].gsub('%s', "__cobj__->#{prop.name}")

        out << "  return #{retv};\n"
        out << "}\n"

        ## setter
        out << "static VALUE\n"
        out << "#{mk.klass.name}_set__#{prop.name}(VALUE __self__, VALUE __val__)\n"
        out << "{\n"

        # declare C++ object
        out << @model.type_encode(mk.klass, "__cobj__")
        out << ";\n"
        
        # convert __self__ to C++ object pointer
        ## FIXME: can remove!
        out << "Check_Type(__self__, T_DATA);\n"
        out << "__cobj__ = (#{mk.klass.name}*) DATA_PTR(__self__);\n"
       
        check_type('__val__', prop.type, out)

        out << "__cobj__->#{prop.name} = "
        out << @model.get_type_entry(prop.type)[:ruby2c].gsub('%s', '__val__')
        out << ";\n"

        out << "  return Qnil;\n"
        out << "}\n"

      end
    end
  end

  #
  # Free is not required in most cases.
  #
  def ruby_free(model_class, out)
    out << "void #{model_class.klass.name}::__free__() {\n"

    model_class.properties.each do |prop|
      if free = prop.options[:free] || @model.get_type_entry(prop.type)[:free]
        out << mark.gsub('%s', "@#{prop.name}")
        out << ";\n"
      end
    end

    out << "super::__free__();\n"
    out << "}\n"
  end

  def ruby_init(mod_name, out)
    out << %{extern "C" void Init_#{mod_name}()\n}
    out << "{\n"
    out << "VALUE klass;"

    @model.each_model_class do |mk|
      out << %{klass = rb_eval_string("#{mk.klass.name}");\n}
      out << "rb_define_alloc_func(klass, #{mk.klass.name}_alloc__);\n"

      mp = mk.klass.name

      mk.methods.each do |meth| 
        next if meth.options[:internal]
        out << %{rb_define_method(klass, "#{meth.name}", } 
        out << %{(VALUE(*)(...))#{mp}_wrap__#{meth.name}, #{meth.arity});\n}
      end

      mk.properties.each do |prop|
        next if prop.options[:internal]

        # getter
        out << %{rb_define_method(klass, "#{prop.name}", } 
        out << %{(VALUE(*)(...))#{mp}_get__#{prop.name}, 0);\n}

        # setter
        out << %{rb_define_method(klass, "#{prop.name}=", } 
        out << %{(VALUE(*)(...))#{mp}_set__#{prop.name}, 1);\n}
      end
    end

    out << "}\n"
  end

  def check_type(name, type, out)
    if checktype = @model.get_type_entry(type)[:ruby2c_checktype]
      out << checktype.gsub('%s', name.to_s) 
      out << ";\n"
    end
  end

  def forward_class_declarations(out)
    @model.each_model_class do |m|
      out << "struct #{m.klass.name};\n"
    end
  end

  def helper_headers(out)
    @model.each_model_class do |m|
      next if m.helper_headers.empty?
      out << "// helper header for class: #{m.klass.name}\n"
      out << m.helper_headers.join("\n")
    end
  end

  def class_declarations(out)
    # TODO: order accordingly?
    @model.each_model_class do |m|
      class_declaration(m, out)
    end
  end

  def class_bodies(out)
    # TODO: order accordingly?
    @model.each_model_class do |m|
      class_body(m, out)
    end
  end

  def class_declaration(model_class, out)
    out << "struct #{model_class.klass.name} : "
    sc = model_class.klass.superclass
    if sc != Object
      sc = sc.name
    else
      sc = "RubyObject"
    end
    out << "#{sc}\n"

    out << "{\n"

    # superclass shortcut
    out << "typedef #{sc} super;\n"

    # declaration of constructor
    out << "// Constructor\n"
    out << "#{model_class.klass.name}();\n\n"

    # declaration of __mark__ and __free__ methods
    out << "// mark method\n"
    out << "virtual void __mark__();\n\n"

    out << "// free method\n"
    out << "virtual void __free__();\n\n"

    model_class.properties.each do |prop|
      property(prop, out)
    end

    model_class.methods.each do |meth|
      method_proto(meth, out)
    end

    out << "};\n"
  end

  def class_body(model_class, out)
    out << model_class.helper_codes.join("\n")

    constructor(model_class, out)
    ruby_mark(model_class, out)
    ruby_free(model_class, out)

    model_class.methods.each do |meth|
      method_body(meth, model_class, out)
    end
  end

  def constructor(model_class, out)
    n = model_class.klass.name
    out << "#{n}::#{n}() {\n"

    model_class.properties.each do |prop|
      next if prop.options[:internal] # FIXME???

      if dflt = prop.options[:default] || @model.get_type_entry(prop.type)[:default]
        out << dflt.gsub('%s', "@#{prop.name}")
        out << ";\n"
      end
    end

    out << "}\n"
  end
 
  def method_body(meth, model_class, out)
    params = meth.params.dup
    returns = params.delete(:returns) || "void"

    out << @model.type_encode(returns, "")
    out << " "
    out << model_class.klass.name
    out << "::"
    out << meth.name.to_s
    out << "("
    out << params.map do |k, v|
      @model.type_encode(v, k)
    end.join(", ")
    out << ")"

    out << " {\n"
    if meth.body.nil?
      out << %{rb_raise(rb_eRuntimeError, "abstract method #{meth.name} called");\n}
    else
      out << meth.body
    end
    out << "}\n"
  end

  def method_proto(meth, out)
    params = meth.params.dup
    returns = params.delete(:returns) || "void"

    out << "static " if meth.options[:static] 
    out << "inline " if meth.options[:inline]
    out << "virtual " if meth.options[:virtual]

    out << @model.type_encode(returns, "")
    out << " "
    out << meth.name.to_s
    out << "("
    out << params.map do |k, v|
      @model.type_encode(v, k)
    end.join(", ")
    out << ");\n"
  end

  def property(prop, out)
    out << @model.type_encode(prop.type, prop.name)
    out << ";\n"
  end

  def header(out)
    out << <<EOS
#include "ruby.h"
#ifndef NULL
#define NULL 0L
#endif 
struct RubyObject {
  VALUE __obj__;

  RubyObject() {
    __obj__ = Qnil;
  }

  virtual ~RubyObject() {};

  static void __free(void *ptr) {
    ((RubyObject*)ptr)->__free__();
  }

  static void __mark(void *ptr) {
    ((RubyObject*)ptr)->__mark__();
  }

  virtual void __free__() { delete this; }
  virtual void __mark__() { }
};
EOS
  end

  def type_aliases(out)
    @model.type_aliases.each do |from, to|
      out << "typedef #{to} #{from};"
    end
  end

end
