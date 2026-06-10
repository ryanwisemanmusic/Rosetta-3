#ifndef __WINE_SERVER_LIST_H
#define __WINE_SERVER_LIST_H

#include <stddef.h>

struct list
{
    struct list *next;
    struct list *prev;
};

#define LIST_INIT(head) { &(head), &(head) }

static inline void list_init(struct list *head)
{
    head->next = head;
    head->prev = head;
}

static inline void list_add_after(struct list *elem, struct list *to_add)
{
    to_add->next = elem->next;
    to_add->prev = elem;
    elem->next->prev = to_add;
    elem->next = to_add;
}

static inline void list_add_before(struct list *elem, struct list *to_add)
{
    to_add->next = elem;
    to_add->prev = elem->prev;
    elem->prev->next = to_add;
    elem->prev = to_add;
}

static inline void list_add_head(struct list *head, struct list *to_add)
{
    list_add_after(head, to_add);
}

static inline void list_add_tail(struct list *head, struct list *to_add)
{
    list_add_before(head, to_add);
}

static inline void list_remove(struct list *elem)
{
    elem->next->prev = elem->prev;
    elem->prev->next = elem->next;
    elem->next = NULL;
    elem->prev = NULL;
}

static inline int list_empty(struct list *head)
{
    return head->next == head;
}

static inline struct list *list_head(struct list *head)
{
    return head->next;
}

static inline struct list *list_tail(struct list *head)
{
    return head->prev;
}

static inline struct list *list_next(struct list *head, struct list *elem)
{
    struct list *next = elem->next;
    return next == head ? NULL : next;
}

static inline struct list *list_prev(struct list *head, struct list *elem)
{
    struct list *prev = elem->prev;
    return prev == head ? NULL : prev;
}

#define LIST_FOR_EACH(cursor, head) \
    for ((cursor) = (head)->next; (cursor) != (head); (cursor) = (cursor)->next)

#define LIST_FOR_EACH_SAFE(cursor, cursor2, head) \
    for ((cursor) = (head)->next, (cursor2) = (cursor)->next; \
         (cursor) != (head); \
         (cursor) = (cursor2), (cursor2) = (cursor)->next)

#define LIST_FOR_EACH_ENTRY(elem, head, type, field) \
    for ((elem) = LIST_ENTRY((head)->next, type, field); \
         &(elem)->field != (head); \
         (elem) = LIST_ENTRY((elem)->field.next, type, field))

#define LIST_FOR_EACH_ENTRY_SAFE(elem, elem2, head, type, field) \
    for ((elem) = LIST_ENTRY((head)->next, type, field), \
         (elem2) = LIST_ENTRY((elem)->field.next, type, field); \
         &(elem)->field != (head); \
         (elem) = (elem2), \
         (elem2) = LIST_ENTRY((elem)->field.next, type, field))

#define LIST_ENTRY(elem, type, field) \
    ((type *)((char *)(elem) - offsetof(type, field)))

#define CONTAINING_RECORD(addr, type, field) LIST_ENTRY(addr, type, field)

#endif
