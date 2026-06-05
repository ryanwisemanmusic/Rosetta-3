#import <Cocoa/Cocoa.h>
#include <stdatomic.h>

#include <game/debug_runtime.h>
#import "fb_logger.h"

static dispatch_queue_t rosette_fb_logger_queue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("rosette.fb_logger", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

void rosette_fb_logger_capture_view(NSView *view)
{
    if (!view || !rosette_fb_logger_enabled()) return;

    static atomic_uint_fast64_t frame_index = 0;
    static atomic_int pending_jobs = 0;

    if (atomic_load(&pending_jobs) > 2) return;

    NSRect bounds = [view bounds];
    if (bounds.size.width <= 0.0 || bounds.size.height <= 0.0) return;

    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:bounds];
    if (!rep) return;
    [view cacheDisplayInRect:bounds toBitmapImageRep:rep];

    CGImageRef cg_image = [rep CGImage];
    if (!cg_image) return;

    NSBitmapImageRep *copy = [[NSBitmapImageRep alloc] initWithCGImage:cg_image];
    if (!copy) return;

    uint64_t frame = atomic_fetch_add(&frame_index, 1);
    atomic_fetch_add(&pending_jobs, 1);

    NSString *dir = [NSString stringWithUTF8String:rosette_fb_logger_directory()];
    dispatch_async(rosette_fb_logger_queue(), ^{
        @autoreleasepool {
            NSDictionary *props = @{
                NSImageCompressionFactor: @0.85f,
            };
            NSData *jpg = [copy representationUsingType:NSBitmapImageFileTypeJPEG properties:props];
            if (jpg && dir) {
                NSString *file = [dir stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"frame_%06llu.jpg", frame]];
                [jpg writeToFile:file atomically:YES];
            }
        }
        atomic_fetch_sub(&pending_jobs, 1);
    });
}
