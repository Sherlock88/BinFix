#include "dr_api.h"
#include <map>
#include <iostream>
#include <cstdlib>
#include <cstring>

using namespace std;

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
    app_pc pc_start, pc_end;
    file_t dump_instr_file_handle;
} app_info;


struct Parsed_Args
{
    char* exec_section = NULL;
};


static void event_exit(void);
static dr_emit_flags_t event_basic_block(void *drcontext, void *tag, instrlist_t *bb, bool for_trace, bool translating);


void show_usage()
{
    cout << "Usage: drrun -c libbinfault.so [--section <section_name>] -- <app>\n";
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
    struct Parsed_Args parsed_args;

    for(i = 1; i < argc; i++)
    {
        if(!strcmp(argv[i], "--section"))
        {
            i++;
            if(i >= argc)
                show_usage();
            else
            {
                parsed_args.exec_section = (char*)malloc(sizeof(argv[i]) + 1);
                if(!parsed_args.exec_section)
                    abort();
                strcpy(parsed_args.exec_section, argv[i]);
            }
        }        
    }

    if(!parsed_args.exec_section)
    {
        parsed_args.exec_section = (char*)malloc(6);
        if(!parsed_args.exec_section)
            abort();
        strcpy(parsed_args.exec_section, ".text");
    }

    return parsed_args;
}


int get_pc_range(char* exec_section)
{
    char cmd[BUFSIZE], cmd_output[BUFSIZE];
    snprintf(cmd, BUFSIZE, "size -A %s | grep %s | awk \'{ print $2, $3 }\' ", app_info.app_path, exec_section);

    FILE* pipe = popen(cmd, "r");
    if(!pipe)
        return FAILURE;

    if(fgets(cmd_output, BUFSIZE, pipe) != NULL)
    {
        unsigned int pc_range = atol(strtok(cmd_output, " "));
        app_info.pc_start = (app_pc)(atol(strtok(NULL, " ")));
        app_info.pc_end = app_info.pc_start + pc_range;
        if(DEBUG)
            dr_printf("pc_start: %x, pc_end: %x, pc_range: %x\n", app_info.pc_start, app_info.pc_end, pc_range);
    }

    pclose(pipe);
    return SUCCESS;
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
    struct Parsed_Args parsed_args = parse_cmd_line_args(argc, argv);
    app_info = get_app_info();
    get_pc_range(parsed_args.exec_section);
    gen_dump();
    register_hook();
}


static void event_exit(void)
{
}


static dr_emit_flags_t event_basic_block(void *drcontext, void *tag, instrlist_t *bb, bool for_trace, bool translating)
{
    app_pc pc_current = dr_fragment_app_pc(tag);
    if(pc_current >= app_info.pc_start && pc_current <= app_info.pc_end)
        instrlist_disassemble(drcontext, (app_pc)tag, bb, app_info.dump_instr_file_handle);
    
    /*for (instr = instrlist_first(bb); instr != instrlist_last(bb); instr = next)
    {
        next = instr_get_next(instr);
    }*/

    /*
    map<int,int> m;
    int i;
    bool success;
    for (i=0; i<5; i++) {
        m[i] = i;
    }

    for (i=0; i<5; i++) {
        cout << m[i];
        if (m[i] != i) {
            success = false;
        }
    }
    */

    return DR_EMIT_DEFAULT;
}

