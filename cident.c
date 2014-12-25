#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <assert.h>

#include <sparse/symbol.h>
#include <sparse/scope.h>

/*
 * Most of the code shamelessly stolen from the c2xml example from the
 * sparse repository.
 */

enum {
#define ID_CLASS(cst, short_name) cst ,
#include "ident_classes.h"
#undef ID_CLASS
	I__COUNT,
};

static const char *identclass_name[] = {
#define ID_CLASS(cst, short_name) [cst] = #short_name ,
#include "ident_classes.h"
#undef ID_CLASS
};

static bool report_class[I__COUNT] = {
	[0 ... (I__COUNT-1)] = true,
	[I_STRUCTDECL] = false,
	[I_UNIONDECL] = false,
	[I_ENUMDECL] = false,
};

static bool all_files = false;


static void
report_symbol(struct symbol *sym, int class)
{	
	const char *ident = show_ident(sym->ident);
	const char *name = identclass_name[class];

	if (!report_class[class])
		return;

	assert(name != NULL);
	assert(sym != NULL);
	assert(ident != NULL);

	printf("%s:%d\t%s\t%s\n",
		stream_name(sym->pos.stream),
		sym->pos.line,
		name,
		ident);
}



static void
examine_macro(struct symbol *sym)
{
	if (sym->arglist)
		report_symbol(sym, I_FUNMACRO);
	else
		report_symbol(sym, I_OBJMACRO);
}

static void
examine_typedef(struct symbol *sym)
{
	report_symbol(sym, I_TYPEDEF);
}

static void
examine_sue(struct symbol *sym)
{
	switch (sym->type) {
	case SYM_STRUCT:
		report_symbol(sym, sym->symbol_list ? I_STRUCTDEF : I_STRUCTDECL);
		break;
	case SYM_UNION:
		report_symbol(sym, sym->symbol_list ? I_UNIONDEF : I_UNIONDECL);
		break;
	case SYM_ENUM:
		report_symbol(sym, sym->symbol_list ? I_ENUMDEF : I_ENUMDECL);
		break;
	default:
		die("symbol type %d is none of SYM_{STRUCT,UNION,ENUM}", sym->type);
	}
}

static void
examine_symbol(struct symbol *sym)
{
	if (!sym)
		return;
	if (sym->aux)		/*already visited */
		return;

	if (sym->ident && sym->ident->reserved)
		return;

	if (sym->enum_member) {
		report_symbol(sym, I_ENUMCST);
		return;
	}

	if (sym->ctype.base_type && sym->ctype.base_type->type == SYM_FN) {
		if (sym->ctype.modifiers & MOD_INLINE)
			report_symbol(sym, I_INLINE_FUNC);
		else if (sym->ctype.modifiers & MOD_STATIC)
			report_symbol(sym, I_STATIC_FUNC);
		else
			report_symbol(sym, I_EXTERN_FUNC);
		return;
	}

	if (sym->type == SYM_NODE) {
		report_symbol(sym, sym->ctype.modifiers & MOD_STATIC ? I_STATIC_VAR : I_EXTERN_VAR);
		return;
	}

	report_symbol(sym, I_OTHER); /* ?? */
}

static void examine_namespace(struct symbol *sym)
{
	if (sym->ident && sym->ident->reserved)
		return;

	switch(sym->namespace) {
	case NS_MACRO:
		examine_macro(sym);
		break;
	case NS_TYPEDEF:
		examine_typedef(sym);
		break;
	case NS_STRUCT:
		examine_sue(sym);
		break;
	case NS_SYMBOL:
		examine_symbol(sym);
		break;
	case NS_NONE:
	case NS_LABEL:
	case NS_ITERATOR:
	case NS_UNDEF:
	case NS_PREPROCESSOR:
	case NS_KEYWORD:
		break;
	default:
		die("Unrecognised namespace type %d", sym->namespace);
	}

}

static int get_stream_id(const char *name)
{
	int i;

	for (i = 0; i < input_stream_nr; i++) {
		if (strcmp(name, stream_name(i)) == 0)
			return i;
	}
	return -1;
}

static void
examine_symbol_list(const char *file, struct symbol_list *list)
{
	struct symbol *sym;
	int stream_id = get_stream_id(file);

	if (!list)
		return;
	FOR_EACH_PTR(list, sym) {
		if (all_files || sym->pos.stream == stream_id)
			examine_namespace(sym);
	} END_FOR_EACH_PTR(sym);
}

static bool
str2bool(const char *str)
{
	if (!strcasecmp(str, "") || 
	    !strcasecmp(str, "0") || 
	    !strcasecmp(str, "n"))
		return false;
	return true;
}

static void
parse_env(void)
{
	const char *var;

#define ID_CLASS(cst, short_name) do {					\
		var = getenv("CIDENT_" #short_name);			\
		if (var)						\
			report_class[cst] = str2bool(var);		\
	} while (0);
#include "ident_classes.h"
#undef ID_CLASS
	
	var = getenv("CIDENT_all_files");
	if (var)
		all_files = str2bool(var);
}


int main(int argc, char *argv[])
{
	struct string_list *filelist = NULL;
	char *file;
	struct symbol_list *sl;

	/*
	 * For simplicity, we pass all command line arguments to
	 * sparse. But this means we can't easily implement our own
	 * options on top. Instead, pass options via the
	 * environment. Not pretty, but just as easy when used from a
	 * script.
	 */
	parse_env();

	sl = sparse_initialize(argc, argv, &filelist);
	FOR_EACH_PTR_NOTAG(filelist, file) {
		examine_symbol_list(file, sl);
		sparse_keep_tokens(file);
		examine_symbol_list(file, file_scope->symbols);
		examine_symbol_list(file, global_scope->symbols);
	} END_FOR_EACH_PTR_NOTAG(file);

	return die_if_error ? 1 : 0;
}


