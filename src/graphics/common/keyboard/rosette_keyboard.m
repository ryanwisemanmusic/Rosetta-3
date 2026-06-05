#import <Cocoa/Cocoa.h>
#include "rosette_keyboard.h"

typedef struct {
    unsigned short keycode;
    int vk;
    int queue_code;
} RosetteSpecialKey;

static const RosetteSpecialKey g_special_keys[] = {
    { 0x7E, 0x26, 72 },  { 0x7D, 0x28, 80 },  { 0x7B, 0x25, 75 },  { 0x7C, 0x27, 77 },
    { 0x35, 0x1B, 27 },  { 0x24, 0x0D, 13 },  { 0x33, 0x08, 8 },   { 0x30, 0x09, 9 },
    { 0x31, 0x20, 32 },  { 0x73, 0x24, 71 },  { 0x77, 0x23, 79 },  { 0x74, 0x21, 73 },
    { 0x79, 0x22, 81 },  { 0x72, 0x2D, 82 },  { 0x75, 0x2E, 83 },
    { 0x7A, 0x70, 59 },  { 0x78, 0x71, 60 },  { 0x63, 0x72, 61 },  { 0x76, 0x73, 62 },
    { 0x60, 0x74, 63 },  { 0x61, 0x75, 64 },  { 0x62, 0x76, 65 },  { 0x64, 0x77, 66 },
    { 0x65, 0x78, 67 },  { 0x6D, 0x79, 68 },  { 0x67, 0x7A, 133 }, { 0x6F, 0x7B, 134 },
    { 0x52, 0x60, '0' }, { 0x53, 0x61, '1' }, { 0x54, 0x62, '2' }, { 0x55, 0x63, '3' },
    { 0x56, 0x64, '4' }, { 0x57, 0x65, '5' }, { 0x58, 0x66, '6' }, { 0x59, 0x67, '7' },
    { 0x5B, 0x68, '8' }, { 0x5C, 0x69, '9' }, { 0x41, 0x6E, '.' }, { 0x45, 0x6B, '+' },
    { 0x4E, 0x6D, '-' }, { 0x43, 0x6A, '*' }, { 0x4B, 0x6F, '/' },
};

static const RosetteSpecialKey *rosette_special_key_lookup(unsigned short keycode)
{
    for (size_t i = 0; i < sizeof(g_special_keys) / sizeof(g_special_keys[0]); i++) {
        if (g_special_keys[i].keycode == keycode) return &g_special_keys[i];
    }
    return NULL;
}

static unichar rosette_first_character(NSString *chars)
{
    if (!chars || [chars length] == 0) return 0;
    return [chars characterAtIndex:0];
}

static void rosette_key_state_set(volatile int *key_state, int key_state_size, int code, int value)
{
    if (!key_state || code < 0 || code >= key_state_size) return;
    key_state[code] = value;
}

static void rosette_set_character_states(volatile int *key_state, int key_state_size, unichar c, int value)
{
    if (c <= 0 || c >= key_state_size) return;
    rosette_key_state_set(key_state, key_state_size, (int)c, value);
    if (c >= 'a' && c <= 'z') rosette_key_state_set(key_state, key_state_size, (int)(c - 32), value);
    if (c >= 'A' && c <= 'Z') rosette_key_state_set(key_state, key_state_size, (int)(c + 32), value);
}

void rosette_keyboard_handle_key_down(NSEvent *event,
                                      volatile int *key_state,
                                      int key_state_size,
                                      rosette_key_push_fn push_key)
{
    if (!event) return;
    const unsigned short keyCode = [event keyCode];
    const unichar c = rosette_first_character([event charactersIgnoringModifiers]);
    const unichar c_shifted = rosette_first_character([event characters]);

    rosette_set_character_states(key_state, key_state_size, c, 0x8001);
    if (c_shifted != c) rosette_set_character_states(key_state, key_state_size, c_shifted, 0x8001);

    const RosetteSpecialKey *special = rosette_special_key_lookup(keyCode);
    if (special) {
        rosette_key_state_set(key_state, key_state_size, special->vk, 0x8001);
        if (push_key) push_key(special->queue_code);
        return;
    }

    if (push_key) {
        if (c_shifted > 0) push_key((int)c_shifted);
        else if (c > 0) push_key((int)c);
    }
}

void rosette_keyboard_handle_key_up(NSEvent *event,
                                    volatile int *key_state,
                                    int key_state_size)
{
    if (!event) return;
    const unsigned short keyCode = [event keyCode];
    const unichar c = rosette_first_character([event charactersIgnoringModifiers]);
    const unichar c_shifted = rosette_first_character([event characters]);

    rosette_set_character_states(key_state, key_state_size, c, 0);
    if (c_shifted != c) rosette_set_character_states(key_state, key_state_size, c_shifted, 0);

    const RosetteSpecialKey *special = rosette_special_key_lookup(keyCode);
    if (special) rosette_key_state_set(key_state, key_state_size, special->vk, 0);
}
