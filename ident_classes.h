#ifdef ID_CLASS
ID_CLASS(I_OBJMACRO,    obj_macro)
ID_CLASS(I_FUNMACRO,    fun_macro)
ID_CLASS(I_TYPEDEF,     typedef)
ID_CLASS(I_STRUCTDECL,  struct_decl)
ID_CLASS(I_STRUCTDEF,   struct_def)
ID_CLASS(I_UNIONDECL,   union_decl)
ID_CLASS(I_UNIONDEF,    union_def)
ID_CLASS(I_ENUMDECL,    enum_decl) /* not allowed by ISO C, but still used in a few places in the kernel */
ID_CLASS(I_ENUMDEF,     enum_def)
ID_CLASS(I_INLINE_FUNC, inline_func)
ID_CLASS(I_STATIC_FUNC, static_func) /* shouldn't appear in headers */
ID_CLASS(I_EXTERN_FUNC, extern_func)
ID_CLASS(I_STATIC_VAR,  static_var) /* shouldn't appear in headers */
ID_CLASS(I_EXTERN_VAR,  extern_var)
ID_CLASS(I_ENUMCST,     enum_cst)
ID_CLASS(I_OTHER,       other)
#endif /* ID_CLASS */
