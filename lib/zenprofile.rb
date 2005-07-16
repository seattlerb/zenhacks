require 'inline'
require 'singleton'

require 'pp'

class ZenProfiler

  include Singleton

  @@start = @@stack = @@map = nil

  def self.start_profile
    @@start = self.instance.time_now
    @@stack = [[0, 0, [nil, :toplevel]], [0, 0, [nil, :dummy]]]
    @@map = {"#toplevel" => [1, 0.0, 0.0, [nil, "#toplevel"]]}
    self.instance.add_event_hook
  end

  def self.stop_profile
    self.instance.remove_event_hook
  end

  def self.print_profile(f)
    stop_profile
    total = self.instance.time_now - @@start
    if total == 0 then total = 0.01 end
    @@map["#toplevel"][1] = total
    data = @@map.values
    data.sort!{|a,b| b[2] <=> a[2]} # TODO: change to sort_by
    sum = 0

    f.printf "  %%   cumulative   self              self     total\n"           
    f.printf " time   seconds   seconds    calls  ms/call  ms/call  name\n"
    for d in data
      sum += d[2]
      klass = d[3].first
      meth  = d[3].last.to_s

      signature = if klass.nil?
                    meth
                  elsif klass.kind_of?(Class)
                    klass.to_s.sub(/#<\S+:(\S+)>/, '\\1') + "#" + meth
                  else
                    klass.class.name + "." + meth
                  end

      f.printf "%6.2f %8.2f  %8.2f %8d ", d[2]/total*100, sum, d[2], d[0]
      f.printf "%8.2f %8.2f  %s\n", d[2]*1000/d[0], d[1]*1000/d[0], signature
    end
  end

  ############################################################
  # Inlined Methods:

  inline(:C) do |builder|

    builder.add_type_converter("rb_event_t", '', '')
    builder.add_type_converter("ID", '', '')
    builder.add_type_converter("NODE *", '', '')

    builder.include '<time.h>'
    builder.include '"ruby.h"'
    builder.include '"node.h"'

    builder.prefix "
static VALUE profiler_klass = Qnil;
static VALUE stack = Qnil;
static VALUE map = Qnil;
"

    builder.c_raw <<-'EOF'
    VALUE time_now() {
      return rb_float_new(((double) clock() / CLOCKS_PER_SEC));
    }
    EOF

    builder.c_raw <<-'EOF'
    static void
    prof_event_hook(rb_event_t event, NODE *node,
                    VALUE self, ID mid, VALUE klass) {

      static int profiling = 0;

      if (mid == ID_ALLOCATOR) return;
      if (profiling) return;
      profiling++;

      if (NIL_P(profiler_klass))
        profiler_klass = rb_path2class("ZenProfiler");
      if (NIL_P(stack))
        stack = rb_cv_get(profiler_klass, "@@stack");
      if (NIL_P(map))
        map   = rb_cv_get(profiler_klass, "@@map");

      switch (event) {
      case RUBY_EVENT_CALL:
      case RUBY_EVENT_C_CALL:
        {
          VALUE signature;
          signature = rb_ary_new2(2);
          rb_ary_store(signature, 0, klass);
          rb_ary_store(signature, 1, ID2SYM(mid));
          VALUE time = rb_ary_new();
          rb_ary_push(time, time_now());
          rb_ary_push(time, rb_float_new(0.0));
          rb_ary_push(time, signature);
          rb_ary_push(stack, time);
        }
        break;
      case RUBY_EVENT_RETURN:
      case RUBY_EVENT_C_RETURN:
        {
        VALUE now = time_now();
        VALUE tick = rb_ary_pop(stack);

        VALUE signature = rb_ary_entry(tick, -1);
        
        VALUE data = Qnil;
        st_lookup(RHASH(map)->tbl, signature, &data);
        if (NIL_P(data)) {
          data = rb_ary_new();
          rb_ary_push(data, INT2FIX(0));
          rb_ary_push(data, rb_float_new(0.0));
          rb_ary_push(data, rb_float_new(0.0));
          rb_ary_push(data, signature);
          rb_hash_aset(map, signature, data);
        }

        rb_ary_store(data, 0, ULONG2NUM(NUM2ULONG(rb_ary_entry(data, 0)) + 1));

        double cost = NUM2DBL(now) - NUM2DBL(rb_ary_entry(tick, 0));

        rb_ary_store(data, 1, rb_float_new(NUM2DBL(rb_ary_entry(data, 1))
                                           + cost));
        rb_ary_store(data, 2, rb_float_new(NUM2DBL(rb_ary_entry(data, 2))
                                           + cost
                                           - NUM2DBL(rb_ary_entry(tick, 1))));

        VALUE toplevel = rb_ary_entry(stack, -1);
        VALUE tl_stats = rb_ary_entry(toplevel, 1);
        long n = NUM2DBL(tl_stats) + cost;
        rb_ary_store(toplevel, 1, rb_float_new(n));
        }
        break;
      }
      profiling--;
    }
    EOF

    builder.c <<-'EOF'
      void add_event_hook() {
        rb_add_event_hook(prof_event_hook,
                          RUBY_EVENT_CALL | RUBY_EVENT_RETURN |
                          RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN);
      }
    EOF

    builder.c <<-'EOF'
      void remove_event_hook() {
        rb_remove_event_hook(prof_event_hook);
      }
    EOF

  end

end

END {
  ZenProfiler::print_profile(STDOUT)
}
ZenProfiler::start_profile
