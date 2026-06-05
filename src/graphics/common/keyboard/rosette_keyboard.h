#pragma once

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*rosette_key_push_fn)(int key);

#ifdef __OBJC__
void rosette_keyboard_handle_key_down(NSEvent *event,
                                      volatile int *key_state,
                                      int key_state_size,
                                      rosette_key_push_fn push_key);
void rosette_keyboard_handle_key_up(NSEvent *event,
                                    volatile int *key_state,
                                    int key_state_size);
#endif

#ifdef __cplusplus
}
#endif
