union exception = {
  error_not_implemented : string,
  error_internal_error  : unit,
  error_cycles_incorrectly_updated : (string, int, int)
}