#include "sail.h"
#include "rts.h"
#include "elf.h"

// union option
enum kind_zoption { Kind_zNone };

struct zoption {
  enum kind_zoption kind;
  union {struct { unit zNone; };};
};

static void CREATE(zoption)(struct zoption *op)
{
  op->kind = Kind_zNone;

}

static void RECREATE(zoption)(struct zoption *op) {}

static void KILL(zoption)(struct zoption *op)
{
  if (op->kind == Kind_zNone){
    /* do nothing */
  };
}

static void COPY(zoption)(struct zoption *rop, struct zoption op)
{
  if (rop->kind == Kind_zNone){
    /* do nothing */
  };
  rop->kind = op.kind;
  if (op.kind == Kind_zNone){
    rop->zNone = op.zNone;
  }
}

static bool EQUAL(zoption)(struct zoption op1, struct zoption op2) {
  if (op1.kind == Kind_zNone && op2.kind == Kind_zNone) {
    return EQUAL(unit)(op1.zNone, op2.zNone);
  } else return false;
}

static void zNone(struct zoption *rop, unit op)
{
  if (rop->kind == Kind_zNone){
    /* do nothing */
  }
  rop->kind = Kind_zNone;
  rop->zNone = op;
}

// union exception
enum kind_zexception { Kind_zerror_internal_error, Kind_zerror_not_implemented };

struct zexception {
  enum kind_zexception kind;
  union {
    struct { unit zerror_internal_error; };
    struct { sail_string zerror_not_implemented; };
  };
};

static void CREATE(zexception)(struct zexception *op)
{
  op->kind = Kind_zerror_internal_error;

}

static void RECREATE(zexception)(struct zexception *op) {}

static void KILL(zexception)(struct zexception *op)
{
  if (op->kind == Kind_zerror_internal_error) {
    /* do nothing */
  } else if (op->kind == Kind_zerror_not_implemented){
    KILL(sail_string)(&op->zerror_not_implemented);
  };
}

static void COPY(zexception)(struct zexception *rop, struct zexception op)
{
  if (rop->kind == Kind_zerror_internal_error) {
    /* do nothing */
  } else if (rop->kind == Kind_zerror_not_implemented){
    KILL(sail_string)(&rop->zerror_not_implemented);
  };
  rop->kind = op.kind;
  if (op.kind == Kind_zerror_internal_error) {
    rop->zerror_internal_error = op.zerror_internal_error;
  } else if (op.kind == Kind_zerror_not_implemented){

  CREATE(sail_string)(&rop->zerror_not_implemented); COPY(sail_string)(&rop->zerror_not_implemented, op.zerror_not_implemented);
  }
}

static bool EQUAL(zexception)(struct zexception op1, struct zexception op2) {
  if (op1.kind == Kind_zerror_internal_error && op2.kind == Kind_zerror_internal_error) {
    return EQUAL(unit)(op1.zerror_internal_error, op2.zerror_internal_error);
  } else if (op1.kind == Kind_zerror_not_implemented && op2.kind == Kind_zerror_not_implemented) {
    return EQUAL(sail_string)(op1.zerror_not_implemented, op2.zerror_not_implemented);
  } else return false;
}

static void zerror_internal_error(struct zexception *rop, unit op)
{
  if (rop->kind == Kind_zerror_internal_error) {
    /* do nothing */
  } else if (rop->kind == Kind_zerror_not_implemented){
    KILL(sail_string)(&rop->zerror_not_implemented);
  }
  rop->kind = Kind_zerror_internal_error;
  rop->zerror_internal_error = op;
}

static void zerror_not_implemented(struct zexception *rop, sail_string op)
{
  if (rop->kind == Kind_zerror_internal_error) {
    /* do nothing */
  } else if (rop->kind == Kind_zerror_not_implemented){
    KILL(sail_string)(&rop->zerror_not_implemented);
  }
  rop->kind = Kind_zerror_not_implemented;
  CREATE(sail_string)(&rop->zerror_not_implemented);
  COPY(sail_string)(&rop->zerror_not_implemented, op);

}

struct zexception *current_exception = NULL;
bool have_exception = false;
sail_string *throw_location = NULL;



































unit zprint_string(sail_string, sail_string);

unit zprint_string(sail_string zs1, sail_string zs2)
{
  __label__ end_function_1, end_block_exception_2;

  unit zcbz30;
  {
    unit zgsz30;
    zgsz30 = print_endline(zs1);
  }
  zcbz30 = print_endline(zs2);
end_function_1: ;
  return zcbz30;
end_block_exception_2: ;

  return UNIT;
}

// register PC
uint64_t zPC;

// register AF
uint64_t zAF;

// register BC
uint64_t zBC;

// register DE
uint64_t zDE;

// register HL
uint64_t zHL;

// register SP
uint64_t zSP;

unit zloop(unit);

unit zloop(unit zgsz31)
{
  __label__ while_4, wend_5, end_function_6, end_block_exception_7;

  unit zcbz31;
  bool zgsz37;
  unit zgsz38;
while_4: ;
  {
    zgsz37 = true;
    if (!(zgsz37)) goto wend_5;
    {
      unit zgsz32;
      {
        lbits zgsz33;
        CREATE(lbits)(&zgsz33);
        CONVERT_OF(lbits, fbits)(&zgsz33, zPC, UINT64_C(16) , true);
        zgsz32 = print_bits("PC = ", zgsz33);
        KILL(lbits)(&zgsz33);
      }
    }
    {
      lbits zgsz34;
      CREATE(lbits)(&zgsz34);
      CONVERT_OF(lbits, fbits)(&zgsz34, zPC, UINT64_C(16) , true);
      sail_int zgsz35;
      CREATE(sail_int)(&zgsz35);
      CONVERT_OF(sail_int, mach_int)(&zgsz35, INT64_C(1));
      lbits zgsz36;
      CREATE(lbits)(&zgsz36);
      add_bits_int(&zgsz36, zgsz34, zgsz35);
      zPC = CONVERT_OF(fbits, lbits)(zgsz36, true);
      KILL(lbits)(&zgsz36);
      KILL(sail_int)(&zgsz35);
      KILL(lbits)(&zgsz34);
    }
    zgsz38 = UNIT;
    goto while_4;
  }
wend_5: ;
  zcbz31 = UNIT;
end_function_6: ;
  return zcbz31;
end_block_exception_7: ;

  return UNIT;
}

unit zmain(unit);

unit zmain(unit zgsz39)
{
  __label__ try_10, try_11, post_exception_handlers_9, end_function_12, end_block_exception_14;

  unit zcbz32;
  {
    {
      lbits zgsz310;
      CREATE(lbits)(&zgsz310);
      CONVERT_OF(lbits, fbits)(&zgsz310, UINT64_C(0x000), UINT64_C(12) , true);
      sail_int zgsz311;
      CREATE(sail_int)(&zgsz311);
      CONVERT_OF(sail_int, mach_int)(&zgsz311, INT64_C(16));
      lbits zgsz312;
      CREATE(lbits)(&zgsz312);
      zero_extend(&zgsz312, zgsz310, zgsz311);
      zPC = CONVERT_OF(fbits, lbits)(zgsz312, true);
      KILL(lbits)(&zgsz312);
      KILL(sail_int)(&zgsz311);
      KILL(lbits)(&zgsz310);
    }
    unit zgsz313;
    zgsz313 = UNIT;
  }
  unit zgsz314;
  { /* try */
    __label__ end_block_exception_13;

    zgsz314 = zloop(UNIT);
  end_block_exception_13: ;
  }
  if (!(have_exception)) goto post_exception_handlers_9;
  have_exception = false;
  {
    if ((*current_exception).kind != Kind_zerror_not_implemented) goto try_10;
    sail_string zs;
    CREATE(sail_string)(&zs);
    COPY(sail_string)(&zs, (*current_exception).zerror_not_implemented);
    /* end destructuring */
    zgsz314 = zprint_string("Error: Not implemented: ", zs);
    KILL(sail_string)(&zs);
    goto post_exception_handlers_9;
  }
try_10: ;
  {
    if ((*current_exception).kind != Kind_zerror_internal_error) goto try_11;
    /* end destructuring */
    zgsz314 = print_endline("Error: internal error");
    goto post_exception_handlers_9;
  }
try_11: ;
  have_exception = true;
post_exception_handlers_9: ;
  zcbz32 = zgsz314;
end_function_12: ;
  return zcbz32;
end_block_exception_14: ;

  return UNIT;
}

unit zinitializze_registers(unit);

unit zinitializze_registers(unit zgsz317)
{
  __label__ end_function_16, end_block_exception_17;

  unit zcbz33;
  {
    {
      sail_int zgsz318;
      CREATE(sail_int)(&zgsz318);
      CONVERT_OF(sail_int, mach_int)(&zgsz318, INT64_C(16));
      lbits zgsz319;
      CREATE(lbits)(&zgsz319);
      UNDEFINED(lbits)(&zgsz319, zgsz318);
      zPC = CONVERT_OF(fbits, lbits)(zgsz319, true);
      KILL(lbits)(&zgsz319);
      KILL(sail_int)(&zgsz318);
    }
    unit zgsz332;
    zgsz332 = UNIT;
  }
  {
    {
      sail_int zgsz320;
      CREATE(sail_int)(&zgsz320);
      CONVERT_OF(sail_int, mach_int)(&zgsz320, INT64_C(16));
      lbits zgsz321;
      CREATE(lbits)(&zgsz321);
      UNDEFINED(lbits)(&zgsz321, zgsz320);
      zAF = CONVERT_OF(fbits, lbits)(zgsz321, true);
      KILL(lbits)(&zgsz321);
      KILL(sail_int)(&zgsz320);
    }
    unit zgsz331;
    zgsz331 = UNIT;
  }
  {
    {
      sail_int zgsz322;
      CREATE(sail_int)(&zgsz322);
      CONVERT_OF(sail_int, mach_int)(&zgsz322, INT64_C(16));
      lbits zgsz323;
      CREATE(lbits)(&zgsz323);
      UNDEFINED(lbits)(&zgsz323, zgsz322);
      zBC = CONVERT_OF(fbits, lbits)(zgsz323, true);
      KILL(lbits)(&zgsz323);
      KILL(sail_int)(&zgsz322);
    }
    unit zgsz330;
    zgsz330 = UNIT;
  }
  {
    {
      sail_int zgsz324;
      CREATE(sail_int)(&zgsz324);
      CONVERT_OF(sail_int, mach_int)(&zgsz324, INT64_C(16));
      lbits zgsz325;
      CREATE(lbits)(&zgsz325);
      UNDEFINED(lbits)(&zgsz325, zgsz324);
      zDE = CONVERT_OF(fbits, lbits)(zgsz325, true);
      KILL(lbits)(&zgsz325);
      KILL(sail_int)(&zgsz324);
    }
    unit zgsz329;
    zgsz329 = UNIT;
  }
  {
    {
      sail_int zgsz326;
      CREATE(sail_int)(&zgsz326);
      CONVERT_OF(sail_int, mach_int)(&zgsz326, INT64_C(16));
      lbits zgsz327;
      CREATE(lbits)(&zgsz327);
      UNDEFINED(lbits)(&zgsz327, zgsz326);
      zHL = CONVERT_OF(fbits, lbits)(zgsz327, true);
      KILL(lbits)(&zgsz327);
      KILL(sail_int)(&zgsz326);
    }
    unit zgsz328;
    zgsz328 = UNIT;
  }
  {
    sail_int zgsz333;
    CREATE(sail_int)(&zgsz333);
    CONVERT_OF(sail_int, mach_int)(&zgsz333, INT64_C(16));
    lbits zgsz334;
    CREATE(lbits)(&zgsz334);
    UNDEFINED(lbits)(&zgsz334, zgsz333);
    zSP = CONVERT_OF(fbits, lbits)(zgsz334, true);
    KILL(lbits)(&zgsz334);
    KILL(sail_int)(&zgsz333);
  }
  zcbz33 = UNIT;
end_function_16: ;
  return zcbz33;
end_block_exception_17: ;

  return UNIT;
}

void model_init(void)
{
  setup_rts();
  current_exception = sail_malloc(sizeof(struct zexception));
  CREATE(zexception)(current_exception);
  throw_location = sail_malloc(sizeof(sail_string));
  CREATE(sail_string)(throw_location);
  zinitializze_registers(UNIT);
}

void model_fini(void)
{
  cleanup_rts();
  if (have_exception) {fprintf(stderr, "Exiting due to uncaught exception: %s\n", *throw_location);}
  KILL(zexception)(current_exception);
  sail_free(current_exception);
  KILL(sail_string)(throw_location);
  sail_free(throw_location);
  if (have_exception) {exit(EXIT_FAILURE);}
}

void model_pre_exit()
{
}

int model_main(int argc, char *argv[])
{
  model_init();
  if (process_arguments(argc, argv)) exit(EXIT_FAILURE);
  zmain(UNIT);
  model_fini();
  model_pre_exit();
  return EXIT_SUCCESS;
}

int main(int argc, char *argv[])
{
  return model_main(argc, argv);
}
