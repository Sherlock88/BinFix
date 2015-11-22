#include "dr_api.h"
#include <map>
#include <iostream>
#include <cstdlib>
#include <cstring>

using namespace std;

extern void inject_binfix_patch(void *drcontext, instr_t *next, instrlist_t *bb);

#define BUFSIZE 512
#define SUCCESS 0
#define FAILURE 1
#define DEBUG   0

#ifdef WINDOWS
#define DISPLAY_STRING(msg) dr_messagebox(msg)
#else
#define DISPLAY_STRING(msg) dr_printf("%x\n", msg)
#endif


struct App_Info
{
    const char* app_name;
    char* app_path;
    file_t dump_instr_file_handle;
} app_info;


struct Parsed_Args
{
    unsigned long patch_injection_address;
} parsed_args;


static void event_exit(void);
static dr_emit_flags_t event_basic_block(void *drcontext, void *tag, instrlist_t *bb, bool for_trace, bool translating);


void show_usage()
{
    cout << "Usage: drrun -c libbininject.so [--address <patch_injection_address>] -- <app>\n";
}


App_Info get_app_info()
{
    app_info.app_name = dr_get_application_name();
    module_data_t *app = dr_lookup_module_by_name(app_info.app_name);
    if(!app)
    {
        dr_printf("%s - No such module found!\n", app_info.app_name);
        dr_abort();
    }
    app_info.app_path = app->full_path;

    return app_info;
}


Parsed_Args parse_cmd_line_args(int argc, const char *argv[])
{
    int i;

    for(i = 1; i < argc; i++)
    {
        if(!strcmp(argv[i], "--address"))
        {
            i++;
            if(i >= argc)
                show_usage();
            else
                parsed_args.patch_injection_address = strtol(argv[i], NULL, 0);
        }        
    }

    return parsed_args;
}


void gen_dump()
{
    char dump_instr_file_name[BUFSIZE];
    strncpy(dump_instr_file_name, app_info.app_path, BUFSIZE - 6);
    strncat(dump_instr_file_name, ".dump", BUFSIZE);
    app_info.dump_instr_file_handle = dr_open_file(dump_instr_file_name, DR_FILE_WRITE_OVERWRITE);
    DR_ASSERT(app_info.dump_instr_file_handle != INVALID_FILE);
}


void register_hook()
{
    dr_register_exit_event(event_exit);
    dr_register_bb_event(event_basic_block);
}


DR_EXPORT void dr_client_main(client_id_t id, int argc, const char *argv[])
{
    parsed_args = parse_cmd_line_args(argc, argv);
    app_info = get_app_info();
    gen_dump();
    register_hook();
}


static void event_exit(void)
{
}


static dr_emit_flags_t event_basic_block(void *drcontext, void *tag, instrlist_t *bb, bool for_trace, bool translating)
{
    app_pc pc_current = dr_fragment_app_pc(tag);
    instr_t *in, *instr, *next;
    
    for (instr = instrlist_first(bb); instr != instrlist_last(bb); instr = next)
    {
        next = instr_get_next(instr);
        app_pc cur_pc = instr_get_app_pc(next);

        if(cur_pc == (app_pc)parsed_args.patch_injection_address)
            inject_binfix_patch(drcontext, next, bb);
    }

    if(DEBUG)
        instrlist_disassemble(drcontext, (app_pc)tag, bb, app_info.dump_instr_file_handle);

    return DR_EMIT_DEFAULT;
}

