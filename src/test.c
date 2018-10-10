#include "gum.h"

#include <fcntl.h>
#include <unistd.h>

typedef struct _ExampleListener ExampleListener;
typedef enum _ExampleHookId ExampleHookId;

struct _ExampleListener
{
  GObject parent;

  guint num_calls;
};

enum _ExampleHookId
{
  EXAMPLE_HOOK_OPEN,
  EXAMPLE_HOOK_CLOSE
};

static void example_listener_iface_init (gpointer g_iface, gpointer iface_data);

#define EXAMPLE_TYPE_LISTENER (example_listener_get_type ())
G_DECLARE_FINAL_TYPE (ExampleListener, example_listener, EXAMPLE, LISTENER, GObject)
G_DEFINE_TYPE_EXTENDED (ExampleListener,
                        example_listener,
                        G_TYPE_OBJECT,
                        0,
                        G_IMPLEMENT_INTERFACE (GUM_TYPE_INVOCATION_LISTENER,
                            example_listener_iface_init))

typedef struct _GumFunctionContext GumFunctionContext;

int
main (int argc,
      char * argv[])
{
  GumInterceptor * interceptor;
  GumInvocationListener * listener;

  g_print ("main\n");

  gum_init_embedded ();
  g_print ("gum_init_embedded\n");


  interceptor = gum_interceptor_obtain ();
  g_print ("interceptor: %p\n", interceptor);

  listener = g_object_new (EXAMPLE_TYPE_LISTENER, NULL);
  g_print ("listener: %p\n", listener);

  (void)gum_interceptor_begin_transaction (interceptor);
  g_print ("gum_interceptor_begin_transaction\n");

  GumAddress open_addr = gum_module_find_export_by_name (NULL, "open");
  g_print ("gum_module_find_export_by_name(open): %p\n", open_addr);

  GumAttachReturn open_attach = gum_interceptor_attach_listener (interceptor,
      GSIZE_TO_POINTER (open_addr),
      listener,
      GSIZE_TO_POINTER (EXAMPLE_HOOK_OPEN));
  g_print ("gum_interceptor_attach_listener(open): %d\n", open_attach);

  GumAddress close_addr = gum_module_find_export_by_name (NULL, "close");
  g_print ("gum_module_find_export_by_name(close): %p\n", close_addr);

  GumAttachReturn close_attach = gum_interceptor_attach_listener (interceptor,
      GSIZE_TO_POINTER (close_addr),
      listener,
      GSIZE_TO_POINTER (EXAMPLE_HOOK_CLOSE));

  g_print ("gum_interceptor_attach_listener(close): %d\n", close_attach);

  (void)gum_interceptor_end_transaction (interceptor);

  close (open ("/etc/hosts", O_RDONLY));
  close (open ("/etc/fstab", O_RDONLY));

  g_print ("[*] listener got %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  (void) (interceptor, listener);

  close (open ("/etc/hosts", O_RDONLY));
  close (open ("/etc/fstab", O_RDONLY));

  g_print ("[*] listener still has %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  g_object_unref (listener);
  g_object_unref (interceptor);

  gum_deinit_embedded ();

  g_print ("done\n");

  return 0;
}

static void
example_listener_on_enter (GumInvocationListener * listener,
                           GumInvocationContext * ic)
{
  ExampleListener * self = EXAMPLE_LISTENER (listener);
  ExampleHookId hook_id = GUM_LINCTX_GET_FUNC_DATA (ic, ExampleHookId);

  switch (hook_id)
  {
    case EXAMPLE_HOOK_OPEN:
      g_print ("[*] open(\"%s\")\n", gum_invocation_context_get_nth_argument (ic, 0));
      break;
    case EXAMPLE_HOOK_CLOSE:
      g_print ("[*] close(%d)\n", (int) gum_invocation_context_get_nth_argument (ic, 0));
      break;
  }

  self->num_calls++;
}

static void
example_listener_on_leave (GumInvocationListener * listener,
                           GumInvocationContext * ic)
{
}

static void
example_listener_class_init (ExampleListenerClass * klass)
{
  (void) EXAMPLE_IS_LISTENER;
  (void) glib_autoptr_cleanup_ExampleListener;
}

static void
example_listener_iface_init (gpointer g_iface,
                             gpointer iface_data)
{
  GumInvocationListenerInterface * iface = g_iface;

  iface->on_enter = example_listener_on_enter;
  iface->on_leave = example_listener_on_leave;
}

static void
example_listener_init (ExampleListener * self)
{
}
