begin require 'rubygems'; rescue LoadError; end
require 'singleton'
require 'inline'
require 'pp'
require 'ruby_to_ansi_c'

class Class
  def optimize(*methods)
    methods.each do |method|
      src = RubyToAnsiC.translate(self, method)
      class_eval "alias :#{method}_slow :#{method}"
      class_eval "remove_method :#{method}"
      class_eval "inline(:C) { |b| b.c src }"
    end
  end
end

module Inline
  class Ruby < Inline::C
    def optimize(meth)
      src = RubyToAnsiC.translate(@mod, meth)
      if $DEBUG then
        STDERR.puts
        STDERR.puts src
        STDERR.puts
      end
      @mod.class_eval "alias :#{meth}_slow :#{meth}"
      @mod.class_eval "remove_method :#{meth}"
      c src
    end
  end
end

class ZenOptimizer

  include Singleton

  @@signature = :fuck
  @@threshold = 500
  @@sacred = {
    Sexp => true,
  }
  @@skip = Hash.new(false)
  @@data = Hash.new(0)

  def self.data; @@data; end
  def self.signature; @@signature; end

  def self.start_optimizing
    self.instance.add_event_hook
  end

  def self.stop_optimizing
    self.instance.remove_event_hook
    if $DEBUG then
      STDERR.puts @@skip.inspect
      STDERR.puts @@data.sort_by{|x,y| y}.reverse[0..4].inspect
    end
  end

  def self.optimize(signature)
    klass, meth = *signature

    unless @@sacred.include? klass then
      STDERR.puts "*** Optimizer threshold tripped!! Optimizing #{klass}.#{meth}"
      
      begin
        klass.module_eval "inline(:Ruby) { |b| b.optimize(#{meth.inspect}) }"
      rescue Exception => e
        STDERR.puts "Failed to optimize #{klass}.#{meth}"
        STDERR.puts "Exception = #{e.class}, message = #{e.message}"
      end
    end

    @@skip[signature] = true
  end

  ############################################################
  # Inlined Methods:

  inline(:C) do |builder|

    builder.add_type_converter("rb_event_t", '', '')
    builder.add_type_converter("ID", '', '')

    builder.include '"ruby.h"'
    builder.include '"node.h"'

    builder.prefix "static VALUE optimizer_klass = Qnil;
static VALUE data = Qnil;
static VALUE skip = Qnil;
static unsigned long threshold = 0;"

    builder.c_raw <<-'EOF'
    static void
    prof_event_hook(rb_event_t event, NODE *node,
                    VALUE self, ID mid, VALUE klass) {

      static int optimizing = 0;

      if (NIL_P(optimizer_klass))
        optimizer_klass = rb_path2class("ZenOptimizer");
      if (NIL_P(data))
        data = rb_cv_get(optimizer_klass, "@@data");
      if (NIL_P(skip))
        skip = rb_cv_get(optimizer_klass, "@@skip");
      if (threshold == 0)
        threshold = NUM2ULONG(rb_cv_get(optimizer_klass, "@@threshold"));
      if (optimizing) return;
      optimizing++;

      switch (event) {
      case RUBY_EVENT_CALL:
        {
          VALUE signature;
    
          signature = rb_ary_new2(2);
          rb_ary_store(signature, 0, klass);
          rb_ary_store(signature, 1, ID2SYM(mid));

          rb_cv_set(optimizer_klass, "@@signature", signature);
          unsigned long count = NUM2ULONG(rb_hash_aref(data, signature)) + 1;

          if (count > threshold) {
            if (! RTEST(rb_hash_aref(skip, signature))) {
              rb_funcall(optimizer_klass, rb_intern("optimize"), 1, signature);
            }
          }

          rb_hash_aset(data, signature, ULONG2NUM(count));
        }
        break;
      }
      optimizing--;
    }
    EOF

    builder.c <<-'EOF'
      void add_event_hook() {
        rb_add_event_hook(prof_event_hook, RUBY_EVENT_CALL);
      }
    EOF

    builder.c <<-'EOF'
      void remove_event_hook() {
        rb_remove_event_hook(prof_event_hook);
      }
    EOF
  end
end

END { ZenOptimizer::stop_optimizing }
ZenOptimizer::start_optimizing
