/*
 * Rosetta 3 macOS platform layer for win32/windows.h.
 *
 * On macOS this file is included by the Win32 shim (windows.h) to
 * provide the platform-specific implementation layer: extern
 * declarations for the ObjC GDI bridge, console redirection helpers,
 * static window/timer state, and the &lt;system&gt; → cls mapping.
 *
 * On non‑macOS platforms this file is not in the include path.
 */
#ifndef ROSETTA3_MACOS_SHIM_WIN32_WINDOWS_H
#define ROSETTA3_MACOS_SHIM_WIN32_WINDOWS_H

#include "windows_base.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ── Console redirection helpers (window_gdi.m / window_main.m) ── */

void *rosetta_get_std_handle(unsigned long nStdHandle);
void  rosetta_set_console_text_attribute(void *hConsole,
                                         unsigned short wAttributes);
void  rosetta_set_console_cursor_position(void *hConsole,
                                          int x, int y);
void  rosetta_set_console_cursor_info(void *hConsole,
                                      void *lpConsoleCursorInfo);
int   rosetta_kbhit(void);
int   rosetta_getch(void);

extern void rosetta_cout_redirect(void);
extern void rosetta_cout_restore(void);

extern void rosetta_console_clear_screen(void);

#ifndef ROSETTA_NO_SYSTEM_CLS
#include <stdlib.h>

static inline int rosetta_system(const char *cmd)
{
    if (cmd && cmd[0] == 'c' && cmd[1] == 'l' && cmd[2] == 's' && cmd[3] == '\0') {
        rosetta_console_clear_screen();
        return 0;
    }
    return (system)(cmd);
}
#define system rosetta_system
#endif

/* ── GDI bridge — extern declarations for Objective‑C window_gdi.m ── */

extern uint32_t rosetta_gdi_get_dc(void *hwnd);
extern uint32_t rosetta_gdi_create_compatible_dc(uint32_t hdc);
extern uint32_t rosetta_gdi_select_object(uint32_t hdc, uint32_t hgdiobj);
extern int      rosetta_gdi_bitblt(uint32_t hdc_dest, int x_dest, int y_dest,
                                   int w, int h, uint32_t hdc_src,
                                   int x_src, int y_src, uint32_t dw_rop);
extern int      rosetta_gdi_delete_object(uint32_t hgdiobj);
extern uint32_t rosetta_gdi_load_image_a(void *hInst, const char *name,
                                          uint32_t type, int cx, int cy,
                                          uint32_t fuLoad);
extern uint32_t rosetta_gdi_load_image_w(void *hInst, const unsigned short *name,
                                          uint32_t type, int cx, int cy,
                                          uint32_t fuLoad);
extern void    *rosetta_gdi_get_console_window(void);
extern void     rosetta_gdi_set_console_title(const char *title);
extern void     rosetta_gdi_set_window_pos(void *hwnd, void *insert_after,
                                            int x, int y, int cx, int cy,
                                            unsigned int flags);
extern int      rosetta_gdi_get_console_screen_buffer_info(void *handle,
                                                            void *lpInfo);
extern int      rosetta_gdi_set_console_screen_buffer_size(void *handle,
                                                            short x, short y);
extern short    rosetta_gdi_get_async_key_state(int vKey);
extern void    *rosetta_gdi_get_foreground_window(void);
extern void    *rosetta_gdi_monitor_from_window(void *hwnd, unsigned long flags);
extern int      rosetta_gdi_get_monitor_info_a(void *hMonitor, void *lpmi);
extern int      rosetta_gdi_get_monitor_info_w(void *hMonitor, void *lpmi);
extern int      rosetta_gdi_enum_display_settings_a(const char *device_name,
                                                     unsigned int mode_num,
                                                     void *lpDevMode);
extern int      rosetta_gdi_enum_display_settings_w(const unsigned short *dev,
                                                     unsigned int mode_num,
                                                     void *lpDevMode);
extern int      rosetta_gdi_play_sound_a(const char *pszSound, void *hmod,
                                          unsigned long fdwSound);
extern int      rosetta_gdi_play_sound_w(const unsigned short *pszSound,
                                          void *hmod, unsigned long fdwSound);
extern int      rosetta_gdi_mci_send_string_a(const char *command,
                                               char *ret_str,
                                               unsigned int ret_len,
                                               void *callback);
extern int      rosetta_gdi_mci_send_string_w(const unsigned short *command,
                                               unsigned short *ret_str,
                                               unsigned int ret_len,
                                               void *callback);
extern uint32_t rosetta_gdi_create_compatible_bitmap(int width, int height);
extern void     rosetta_gdi_fill_rect(uint32_t hdc, int left, int top,
                                        int right, int bottom, uint32_t color);

/* ── Line / edge drawing (added for Minesweeper rendering) ── */
extern void     rosetta_gdi_move_to_ex(uint32_t hdc, int x, int y);
extern int      rosetta_gdi_line_to(uint32_t hdc, int x, int y, uint32_t color);
extern int      rosetta_gdi_draw_edge(uint32_t hdc, int left, int top,
                                        int right, int bottom,
                                        uint32_t edge, uint32_t flags);
extern uint32_t rosetta_gdi_get_selected_pen(uint32_t hdc);

/* ── Mouse input (tracked in GDIView) ── */
extern int rosetta_gdi_get_mouse_x(void);
extern int rosetta_gdi_get_mouse_y(void);
extern int rosetta_gdi_get_mouse_buttons(void);

/* ── Font / text rendering (Core Text bridge) ── */
extern uint32_t rosetta_gdi_create_font(int height, int weight, int italic,
                                         const uint16_t *faceName);
extern void     rosetta_gdi_register_color_object(uint32_t handle, uint32_t color);
extern void     rosetta_gdi_register_object_kind(uint32_t handle, uint32_t kind);
extern void     rosetta_gdi_delete_font(uint32_t handle);
extern uint32_t rosetta_gdi_set_text_color(uint32_t hdc, uint32_t color);
extern uint32_t rosetta_gdi_set_bk_color(uint32_t hdc, uint32_t color);
extern int      rosetta_gdi_set_bk_mode(uint32_t hdc, int mode);
extern int      rosetta_gdi_get_text_extent_point_32w(uint32_t hdc,
                     const uint16_t *str, int len, int *out_cx, int *out_cy);
extern int      rosetta_gdi_text_out_w(uint32_t hdc, int x, int y,
                     const uint16_t *str, int len);

/* ── Shape drawing ── */
extern int      rosetta_gdi_ellipse(uint32_t hdc, int left, int top,
                     int right, int bottom);
extern int      rosetta_gdi_arc(uint32_t hdc, int left, int top,
                     int right, int bottom,
                     int xStart, int yStart, int xEnd, int yEnd);
extern int      rosetta_gdi_polygon(uint32_t hdc, const void *points, int count);
extern void    *rosetta_gdi_load_menu_a(void *hInst, const char *name);
extern void    *rosetta_gdi_load_menu_w(void *hInst, const unsigned short *name);
extern int      rosetta_gdi_set_menu(void *hwnd, void *menu);
extern unsigned long rosetta_gdi_check_menu_item(void *menu, unsigned int item, unsigned int check);
extern int      rosetta_gdi_get_menu_item_rect(void *hwnd, void *menu, unsigned int item, void *rect);
extern int      rosetta_gdi_post_message(void *hwnd, unsigned int msg, uintptr_t wParam, intptr_t lParam);
extern int      rosetta_gdi_pop_message(void *msg_out);

/* ── GDI object tracking (static) ── */

#define GDI_MAX_OBJECTS 64
#define GDI_HANDLE_BASE 0xDE00

/* Forward struct declarations used by GDI bridge typedefs */
struct _CONSOLE_SCREEN_BUFFER_INFO;
typedef struct _CONSOLE_SCREEN_BUFFER_INFO *PCONSOLE_SCREEN_BUFFER_INFO;
struct HMONITOR__;
typedef struct HMONITOR__ *HMONITOR;
struct tagMONITORINFO;
typedef struct tagMONITORINFO *LPMONITORINFO;
struct _devicemodeA;
typedef struct _devicemodeA *LPDEVMODEA;
struct _devicemodeW;
typedef struct _devicemodeW *LPDEVMODEW;

#ifdef __cplusplus
}
#endif

#endif /* ROSETTA3_MACOS_SHIM_WIN32_WINDOWS_H */
