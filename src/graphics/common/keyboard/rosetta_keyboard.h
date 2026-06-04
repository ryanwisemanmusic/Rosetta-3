#pragma once

#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*rosetta_key_push_fn)(int key);

#ifdef __OBJC__
void rosetta_keyboard_handle_key_down(NSEvent *event,
                                      volatile int *key_state,
                                      int key_state_size,
                                      rosetta_key_push_fn push_key);
void rosetta_keyboard_handle_key_up(NSEvent *event,
                                    volatile int *key_state,
                                    int key_state_size);
#endif

#ifdef __cplusplus
}
#endif
