
require 'inline'

class Perl

  def self.runtime
    perl = Perl.new("-e", "0", *ARGV)
  end

  inline(:C) do |builder|

    builder.add_compile_flags `perl -MExtUtils::Embed -e ccopts`.chomp
    builder.add_link_flags `perl -MExtUtils::Embed -e ldopts`.chomp
    # TODO:
    # shrplib = `perl -MConfig -e 'print $Config{"useshrplib"}'` == 'true'
    
    builder.prefix %(
      #include "ruby.h"
      #include "rubyio.h"
      #include "st.h"
      #include "env.h"
      #include "version.h"
      
      #include <stdio.h>
      #include <stdlib.h>
      #include <EXTERN.h>
      #include <perl.h>
      
      #if defined(SHRPLIB) && defined(LIBPERL)
      #  include <dlfcn.h>
      #endif
      
      /* for Perl 5.6 */
      #if PATCHLEVEL >= 6
      #  define PERL_POLLUTE 1
      #  include "embedvar.h"
      #endif
      
      /* For the earlier versions of Perl */
      #ifndef ERRSV
      #  define ERRSV GvSV(errgv)
      #endif
      #ifndef PL_na
      #  define PL_na na
      #endif
      #ifndef PL_sv_undef
      #  ifdef sv_undef
      #    define PL_sv_undef sv_undef
      #  endif
      #endif
      
      static VALUE cPerl;
      static VALUE cPerlObject;
      static VALUE ePerlError;
      static VALUE perl__instance = Qnil;
      
      static VALUE perl__Sv2Object(SV* sv);
      static SV* perl__Object2Sv(VALUE val);
      extern void boot_DynaLoader _((CV* cv));

static void
perl__xs_init()
{
#ifdef dTHX
  dTHX;
#endif
#if defined(SHRPLIB) && defined(LIBPERL)
  void *h;

  h = dlopen(LIBPERL, RTLD_GLOBAL | RTLD_LAZY);
#endif
 
  newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, __FILE__);

#if defined(SHRPLIB) && defined(LIBPERL)
  dlclose(h);
#endif
}

static void
perl__end(PerlInterpreter* myperl)
{
#ifdef dTHX
  dTHX;
#endif
  if (perl__instance != Qnil) {
    /* fprintf(stderr, "free perl: %p\n", myperl); */
    perl_destruct(myperl);
    perl_free(myperl);
    perl__instance = Qnil;
  }
}

static VALUE
perl__new(int argc, VALUE* argv, VALUE klass)
{
#ifdef dTHX
  dTHX;
#endif
  PerlInterpreter* myperl;
  VALUE obj = Qnil;
  char** s_argv;
  int i;
  int err;

  if (perl__instance != Qnil) {
    rb_raise(ePerlError, "cannot create multiple instance");
  }
  if (argc == 0) {
    argc = 2;
    s_argv = (char**)xmalloc(sizeof(char*) * 4);
    s_argv[0] = "";
    s_argv[1] = "-e";
    s_argv[2] = "0";
    s_argv[3] = NULL;
  }
  else {
    s_argv = (char**)xmalloc(sizeof(char*) * (argc + 2));
    s_argv[0] = "";
    for (i = 0; i < argc; i++) {
      Check_Type(argv[i], T_STRING);
      s_argv[i + 1] = RSTRING(argv[i])->ptr;
    }
    s_argv[argc + 1] = NULL;
  }
  myperl = perl_alloc();
  perl_construct(myperl);
  err = perl_parse(myperl, perl__xs_init, argc + 1, s_argv, (char **)NULL);
  if (err != 0) {
    free(s_argv);
    perl_destruct(myperl);
    perl_free(myperl);
    rb_raise(ePerlError, "cannot parse");
  }
  err = perl_run(myperl);
  if (err != 0) {
    free(s_argv);
    perl_destruct(myperl);
    perl_free(myperl);
    rb_raise(ePerlError, "cannot run");
  }

  free(s_argv);
  obj = Data_Wrap_Struct(klass, NULL, perl__end, myperl);
  rb_obj_call_init(obj, argc, argv);
  perl__instance = obj;

  return obj;
}

static VALUE
perl__initialize(VALUE obj)
{
  return Qnil;
}

static enum st_retval
__hash_iter(VALUE key, VALUE val, HV* hv)
{
#ifdef dTHX
  dTHX;
#endif
  /* Perl hash key must be a string */
  VALUE vkey = rb_obj_as_string(key);
  hv_store(hv, RSTRING(vkey)->ptr, RSTRING(vkey)->len,
	   perl__Object2Sv(val), 0);
  return ST_CONTINUE;
}

/* Create Perl value from Ruby value */
static SV*
perl__Object2Sv(VALUE val)
{
#ifdef dTHX
  dTHX;
#endif
  int type = TYPE(val);

  switch (type) {
  case T_NIL:
    {
      return &PL_sv_undef;
    }
  case T_FIXNUM:
    {
      return newSViv(FIX2INT(val));
    }
  case T_FLOAT:
    {
      return newSVnv(RFLOAT(val)->value);
    }
  case T_STRING:
    {
      return newSVpv(RSTRING(val)->ptr, RSTRING(val)->len);
    }
  case T_ARRAY:
    {
      AV* av = newAV();
      int len = RARRAY(val)->len;
      int i;
      for (i = 0; i < len; i++) {
	av_push(av, perl__Object2Sv(RARRAY(val)->ptr[i]));
      }
      return newRV_inc((SV*)av);
    }
  case T_HASH:
    {
      HV* hv = newHV();
      st_table* table = RHASH(val)->tbl;
      st_foreach(table, __hash_iter, hv);
      return newRV_inc((SV*)hv);
    }
  case T_DATA:
    {
      if (rb_obj_is_kind_of(val, cPerlObject)) {
	SV* sv;
	Data_Get_Struct(val, SV, sv);
	return newSVsv(sv);
      }
      break;
    }
  }

  val = rb_obj_as_string(val);
#ifdef MOD_DEBUG
  rb_warn("VALUE (%d) is converted into String: %s\n", type, RSTRING(val)->ptr);
#endif
  return newSVpv(RSTRING(val)->ptr, RSTRING(val)->len);
}

static void
perl__object_free(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  /* fprintf(stderr, "free SV: %p\n", sv); */
  SvREFCNT_dec(sv);
}

static void
perl__object_mark(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  /* fprintf(stderr, "mark: %p\n", perl__instance); */
  if (perl__instance != Qnil)
    rb_gc_mark(perl__instance);
}

/* Create Ruby value from Perl value */
static VALUE
perl__Sv2Object(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  int type;
  VALUE obj;

  if (sv == NULL)
    return Qnil;

  type = SvTYPE(sv);
  switch (type) {
  case SVt_NULL:
    {
      return Qnil;
    }
  case SVt_IV:
    {
      return INT2NUM(SvIV(sv));
    }
  case SVt_NV:
    {
      return rb_float_new(SvNV(sv));
    }
  case SVt_PV:
    {
      int len;
      char* ptr = SvPV(sv, len);
      return rb_str_new(ptr, len);
    }
  }

#ifdef MOD_DEBUG
  rb_warn("SV (%d) is converted into PerlObject\n", SvTYPE(sv));
#endif
  obj = Data_Wrap_Struct(cPerlObject, perl__object_mark,
			 perl__object_free, sv);
  rb_obj_call_init(obj, 0, NULL);
  SvREFCNT_inc(sv);
  return obj;
}

static VALUE
perl__eval(VALUE obj, VALUE pv)
{
#ifdef dTHX
  dTHX;
#endif
#ifdef dTHR
  dTHR;
#endif
  SV* ret;

  Check_Type(pv, T_STRING);

  ret = perl_eval_pv(RSTRING(pv)->ptr, Qfalse);
  if (SvTRUE(ERRSV)) {
    rb_raise(ePerlError, SvPVx(ERRSV, PL_na));
  }

  return perl__Sv2Object(ret);
}

static VALUE
perl__get_sv(VALUE obj, VALUE name)
{
#ifdef dTHX
  dTHX;
#endif
  int len;
  SV* ret;

  Check_Type(name, T_STRING);
  ret = perl_get_sv(RSTRING(name)->ptr, Qfalse);
  if (!ret)
    return Qnil;

  return perl__Sv2Object(ret);
}


static VALUE
perl__call(int argc, VALUE* argv, VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  dSP;
  int err;
  int i;
  VALUE ret;

  if (argc < 1) {
    rb_raise(rb_eArgError, "Wrong # of arguments (0 for 1)");
  }
  Check_Type(argv[0], T_STRING);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  for (i = 1; i < argc; i++) {
    XPUSHs(sv_2mortal(perl__Object2Sv(argv[i])));
  }
  PUTBACK;
  err = perl_call_pv(RSTRING(argv[0])->ptr, G_EVAL);
  SPAGAIN;
  ret = perl__Sv2Object(POPs);
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (SvTRUE(ERRSV)) {
    rb_raise(ePerlError, SvPVx(ERRSV, PL_na));
  }

  return ret;
}


static VALUE
perl__call_static_method(int argc, VALUE* argv, VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  dSP;
  SV* sv;
  int err;
  int i;
  VALUE ret;

  if (argc < 2) {
    rb_raise(rb_eArgError, "Wrong # of arguments (%d for 2)", argc);
  }
  Check_Type(argv[0], T_STRING); /* class name */
  Check_Type(argv[1], T_STRING); /* method name */

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(perl__Object2Sv(argv[0])));
  for (i = 2; i < argc; i++) {
    XPUSHs(sv_2mortal(perl__Object2Sv(argv[i])));
  }
  PUTBACK;
  err = perl_call_method(RSTRING(argv[1])->ptr, G_EVAL);
  SPAGAIN;
  ret = perl__Sv2Object(POPs);
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (SvTRUE(ERRSV)) {
    rb_raise(ePerlError, SvPVx(ERRSV, PL_na));
  }

  return ret;
}


static VALUE
perl__destroy(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  int len;
  PerlInterpreter* myperl;

  if (perl__instance != Qnil) {
    Data_Get_Struct(obj, PerlInterpreter, myperl);
    perl__end(myperl);
  }

  return Qnil;
}

void
Init_perl()
{
  cPerl = rb_define_class("Perl", rb_cObject);
  cPerlObject = rb_define_class("PerlObject", rb_cObject);
  ePerlError = rb_define_class("PerlError", rb_eException);

  rb_define_singleton_method(cPerl, "new", perl__new, -1);
  rb_define_method(cPerl, "initialize", perl__initialize, -1);
  rb_define_alias(cPerl, "eval_", "eval");
  rb_define_alias(cPerl, "send_", "send");
  rb_define_method(cPerl, "eval", perl__eval, 1);
  rb_define_method(cPerl, "get_sv", perl__get_sv, 1);
  rb_define_method(cPerl, "call", perl__call, -1);
  rb_define_method(cPerl, "send", perl__call_static_method, -1);
  rb_define_method(cPerl, "destroy", perl__destroy, 0);
}
    )

    builder.add_to_init('Init_perl();') # yes... we cheat

  end

end

class PerlObject

  inline(:C) do |builder|

    builder.add_compile_flags `perl -MExtUtils::Embed -e ccopts`.chomp
    builder.add_compile_flags '-Wunused-function'
    builder.add_link_flags `perl -MExtUtils::Embed -e ldopts`.chomp
    # TODO:
    # shrplib = `perl -MConfig -e 'print $Config{"useshrplib"}'` == 'true'
    
    builder.prefix %(
      #include "ruby.h"
      #include "rubyio.h"
      #include "st.h"
      #include "env.h"
      #include "version.h"
      
      #include <stdio.h>
      #include <stdlib.h>
      #include <EXTERN.h>
      #include <perl.h>
      
      #if defined(SHRPLIB) && defined(LIBPERL)
      #  include <dlfcn.h>
      #endif
      
      /* for Perl 5.6 */
      #if PATCHLEVEL >= 6
      #  define PERL_POLLUTE 1
      #  include "embedvar.h"
      #endif
      
      /* For the earlier versions of Perl */
      #ifndef ERRSV
      #  define ERRSV GvSV(errgv)
      #endif
      #ifndef PL_na
      #  define PL_na na
      #endif
      #ifndef PL_sv_undef
      #  ifdef sv_undef
      #    define PL_sv_undef sv_undef
      #  endif
      #endif
      
      static VALUE cPerl;
      static VALUE cPerlObject;
      static VALUE ePerlError;
      static VALUE perl__instance = Qnil;
      
      static VALUE perl__Sv2Object(SV* sv);
      static SV* perl__Object2Sv(VALUE val);
      extern void boot_DynaLoader _((CV* cv));

static enum st_retval
__hash_iter(VALUE key, VALUE val, HV* hv)
{
#ifdef dTHX
  dTHX;
#endif
  /* Perl hash key must be a string */
  VALUE vkey = rb_obj_as_string(key);
  hv_store(hv, RSTRING(vkey)->ptr, RSTRING(vkey)->len,
	   perl__Object2Sv(val), 0);
  return ST_CONTINUE;
}

/* Create Perl value from Ruby value */
static SV*
perl__Object2Sv(VALUE val)
{
#ifdef dTHX
  dTHX;
#endif
  int type = TYPE(val);

  switch (type) {
  case T_NIL:
    {
      return &PL_sv_undef;
    }
  case T_FIXNUM:
    {
      return newSViv(FIX2INT(val));
    }
  case T_FLOAT:
    {
      return newSVnv(RFLOAT(val)->value);
    }
  case T_STRING:
    {
      return newSVpv(RSTRING(val)->ptr, RSTRING(val)->len);
    }
  case T_ARRAY:
    {
      AV* av = newAV();
      int len = RARRAY(val)->len;
      int i;
      for (i = 0; i < len; i++) {
	av_push(av, perl__Object2Sv(RARRAY(val)->ptr[i]));
      }
      return newRV_inc((SV*)av);
    }
  case T_HASH:
    {
      HV* hv = newHV();
      st_table* table = RHASH(val)->tbl;
      st_foreach(table, __hash_iter, hv);
      return newRV_inc((SV*)hv);
    }
  case T_DATA:
    {
      if (rb_obj_is_kind_of(val, cPerlObject)) {
	SV* sv;
	Data_Get_Struct(val, SV, sv);
	return newSVsv(sv);
      }
      break;
    }
  }

  val = rb_obj_as_string(val);
#ifdef MOD_DEBUG
  rb_warn("VALUE (%d) is converted into String: %s\n", type, RSTRING(val)->ptr);
#endif
  return newSVpv(RSTRING(val)->ptr, RSTRING(val)->len);
}

static void
perl__object_free(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  /* fprintf(stderr, "free SV: %p\n", sv); */
  SvREFCNT_dec(sv);
}

static void
perl__object_mark(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  /* fprintf(stderr, "mark: %p\n", perl__instance); */
  if (perl__instance != Qnil)
    rb_gc_mark(perl__instance);
}

/* Create Ruby value from Perl value */
static VALUE
perl__Sv2Object(SV* sv)
{
#ifdef dTHX
  dTHX;
#endif
  int type;
  VALUE obj;

  if (sv == NULL)
    return Qnil;

  type = SvTYPE(sv);
  switch (type) {
  case SVt_NULL:
    {
      return Qnil;
    }
  case SVt_IV:
    {
      return INT2NUM(SvIV(sv));
    }
  case SVt_NV:
    {
      return rb_float_new(SvNV(sv));
    }
  case SVt_PV:
    {
      int len;
      char* ptr = SvPV(sv, len);
      return rb_str_new(ptr, len);
    }
  }

#ifdef MOD_DEBUG
  rb_warn("SV (%d) is converted into PerlObject\n", SvTYPE(sv));
#endif
  obj = Data_Wrap_Struct(cPerlObject, perl__object_mark,
			 perl__object_free, sv);
  rb_obj_call_init(obj, 0, NULL);
  SvREFCNT_inc(sv);
  return obj;
}

static VALUE
perl__call_method(int argc, VALUE* argv, VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  dSP;
  SV* sv;
  int err;
  int i;
  VALUE ret;

  if (argc < 1) {
    rb_raise(rb_eArgError, "Wrong # of arguments (0 for 1)");
  }
  Check_Type(argv[0], T_STRING);
  Data_Get_Struct(obj, SV, sv);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv);
  for (i = 1; i < argc; i++) {
    XPUSHs(sv_2mortal(perl__Object2Sv(argv[i])));
  }
  PUTBACK;
  err = perl_call_method(RSTRING(argv[0])->ptr, G_EVAL);
  SPAGAIN;
  ret = perl__Sv2Object(POPs);
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (SvTRUE(ERRSV)) {
    rb_raise(ePerlError, SvPVx(ERRSV, PL_na));
  }

  return ret;
}

static VALUE
perl__call_sv(int argc, VALUE* argv, VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  dSP;
  SV* sv;
  int err;
  int i;
  VALUE ret;

  Data_Get_Struct(obj, SV, sv);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  for (i = 0; i < argc; i++) {
    XPUSHs(sv_2mortal(perl__Object2Sv(argv[i])));
  }
  PUTBACK;
  err = perl_call_sv(sv, G_EVAL);
  SPAGAIN;
  ret = perl__Sv2Object(POPs);
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (SvTRUE(ERRSV)) {
    rb_raise(ePerlError, SvPVx(ERRSV, PL_na));
  }

  return ret;
}

/* dereference the reference */
static VALUE
perl__value(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* rv;
  char* ptr;
  int len;

  Data_Get_Struct(obj, SV, rv);

  /* Whether RV or not. */
  if (!SvROK(rv)) {
    rb_raise(rb_eTypeError, "wrong argument type (expected RV)");
  }

  return perl__Sv2Object(SvRV(rv));
}

static VALUE
perl__to_s(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  char* ptr;
  int len;

  Data_Get_Struct(obj, SV, sv);
  ptr = SvPV(sv, len);

  return rb_str_new(ptr, len);
}

static VALUE
perl__to_f(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  double f;

  Data_Get_Struct(obj, SV, sv);
  f = SvNV(sv);

  return rb_float_new(f);
}

static VALUE
perl__to_i(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  int i;

  Data_Get_Struct(obj, SV, sv);
  i = SvIV(sv);

  return INT2FIX(i);
}

static VALUE
perl__to_a(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  AV* av;
  VALUE ret;

  Data_Get_Struct(obj, SV, sv);

  ret = rb_ary_new();

  if (SvROK(sv)) {
    av = (AV*)SvRV(sv);
    if (SvTYPE(av) == SVt_PVAV) {
      int len = av_len(av);
      int i;
      for (i = 0; i <= len; i++) {
	rb_ary_push(ret, perl__Sv2Object(*av_fetch(av, i, 0)));
      }
      return ret;
    }
    else if (SvTYPE(av) == SVt_PVHV) {
      HE* he;
      
      for (hv_iterinit((HV*)av); he = hv_iternext((HV*)av);) {
	char* key;
	I32 klen;
	SV* val;
	VALUE tmp;
	key = hv_iterkey(he, &klen);
	val = hv_iterval((HV*)av, he);
	tmp = rb_ary_new();
	rb_ary_push(tmp, rb_str_new(key, klen));
	rb_ary_push(tmp, perl__Sv2Object(val));
	rb_ary_push(ret, tmp);
      }
      return ret;
    }
  }

  rb_ary_push(ret, obj);

  return ret;
}

static VALUE
perl__to_hash(VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  HV* hv;
  VALUE ret;

  Data_Get_Struct(obj, SV, sv);

  if (SvROK(sv)) {
    hv = (HV*)SvRV(sv);
    if (SvTYPE(hv) == SVt_PVHV) {
      HE* he;

      ret = rb_hash_new();
      for (hv_iterinit(hv); he = hv_iternext(hv);) {
	char* key;
	I32 klen;
	SV* val;
	key = hv_iterkey(he, &klen);
	val = hv_iterval(hv, he);
	rb_hash_aset(ret, rb_str_new(key, klen), perl__Sv2Object(val));
      }
      return ret;
    }
  }
  rb_raise(rb_eTypeError, "wrong argument type");
  return Qnil;
}

static VALUE
perl__aref(VALUE obj, VALUE offset)
{
#ifdef dTHX
  dTHX;
#endif
  SV* rv;
  SV* pv;
  SV** ret = NULL;

  Data_Get_Struct(obj, SV, rv);

  /* Whether RV or not. */
  if (!SvROK(rv)) {
    rb_raise(rb_eTypeError, "wrong argument type (expected RV)");
  }

  pv = SvRV(rv);
  /* Hash */
  if (SvTYPE(pv) == SVt_PVHV && TYPE(offset) == T_STRING) {
    ret = hv_fetch((HV*)pv, RSTRING(offset)->ptr, RSTRING(offset)->len, 0);
  }
  /* Array */
  else if (SvTYPE(pv) == SVt_PVAV && TYPE(offset) == T_FIXNUM) {
    ret = av_fetch((AV*)pv, FIX2INT(offset), 0);
  }
  else {
    rb_raise(rb_eTypeError, "wrong argument type");
  }
  if (ret == NULL)
    return Qnil;
  return perl__Sv2Object(*ret);
}


static VALUE
perl__aset(VALUE obj, VALUE offset, VALUE val)
{
#ifdef dTHX
  dTHX;
#endif
  SV* rv;
  SV* pv;
  SV* svval;
  SV** ret = NULL;

  Data_Get_Struct(obj, SV, rv);

  /* Whether RV or not. */
  if (!SvROK(rv)) {
    rb_raise(rb_eTypeError, "wrong argument type (expected RV)");
  }

  pv = SvRV(rv);
  /* Hash */
  if (SvTYPE(pv) == SVt_PVHV && TYPE(offset) == T_STRING) {
    svval = perl__Object2Sv(val);
    ret = hv_store((HV*)pv, RSTRING(offset)->ptr,
		   RSTRING(offset)->len, svval, 0);
  }
  /* Array */
  else if (SvTYPE(pv) == SVt_PVAV && TYPE(offset) == T_FIXNUM) {
    svval = perl__Object2Sv(val);
    ret = av_store((AV*)pv, FIX2INT(offset), svval);
  }
  else {
    rb_raise(rb_eTypeError, "wrong argument type (expected HV or AV)");
  }

  return val;
}

static VALUE
perl__missing(int argc, VALUE* argv, VALUE obj)
{
#ifdef dTHX
  dTHX;
#endif
  SV* sv;
  int i;
    extern VALUE ruby_errinfo;
    VALUE errat = Qnil;

  if (argc < 1) {
    rb_raise(rb_eArgError, "Wrong # of arguments (0 for 1)");
  }
#if defined(RUBY_VERSION_CODE) && RUBY_VERSION_CODE >= 160
  ruby_frame->last_func = SYM2ID(argv[0]);
  argv[0] = rb_str_new2(rb_id2name(SYM2ID(argv[0])));
#else
  ruby_frame->last_func = FIX2INT(argv[0]);
  argv[0] = rb_str_new2(rb_id2name(FIX2INT(argv[0])));
#endif
  return perl__call_method(argc, argv, obj);
}

void
Init_perl()
{
  cPerlObject = rb_define_class("PerlObject", rb_cObject);

  rb_define_alias(cPerlObject, "eval_", "eval");
  rb_define_alias(cPerlObject, "send_", "send");
  rb_define_method(cPerlObject, "send", perl__call_method, -1);
  rb_define_method(cPerlObject, "call", perl__call_sv, -1);
  rb_define_method(cPerlObject, "value", perl__value, 0);
  rb_define_method(cPerlObject, "to_s", perl__to_s, 0);
  rb_define_method(cPerlObject, "to_f", perl__to_f, 0);
  rb_define_method(cPerlObject, "to_i", perl__to_i, 0);
  rb_define_method(cPerlObject, "to_a", perl__to_a, 0);
  rb_define_method(cPerlObject, "to_hash", perl__to_hash, 0);
  rb_define_method(cPerlObject, "[]", perl__aref, 1);
  rb_define_method(cPerlObject, "[]=", perl__aset, 2);

  rb_define_method(cPerlObject, "method_missing", perl__missing, -1);
}
)

    builder.add_to_init('Init_perl();') # yes... we cheat
end
end

class PerlError < Exception; end
