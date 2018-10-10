#include "gum.h"

#include <fcntl.h>
#include <unistd.h>

typedef struct _ExampleListener
{
  GObject parent;

  guint num_calls;
} ExampleListener;

typedef enum _ExampleHookId
{
  EXAMPLE_HOOK_OPEN,
  EXAMPLE_HOOK_CLOSE
} ExampleHookId;

int my_open(const char *path, int oflag)
{
  static int fd = STDERR_FILENO;
  return ++fd;
}

int my_close(int fd)
{
  return 0;
}

static void
example_listener_iface_init (gpointer g_iface,
                             gpointer iface_data);

G_DECLARE_FINAL_TYPE (ExampleListener, example_listener, EXAMPLE, LISTENER, GObject)
G_DEFINE_TYPE_EXTENDED (ExampleListener,
                        example_listener,
                        G_TYPE_OBJECT,
                        0,
                        G_IMPLEMENT_INTERFACE (GUM_TYPE_INVOCATION_LISTENER,
                            example_listener_iface_init))

static void
example_listener_on_enter (GumInvocationListener * listener,
                           GumInvocationContext * ic)
{
  ExampleListener * self = EXAMPLE_LISTENER (listener);
  ExampleHookId hook_id = GUM_LINCTX_GET_FUNC_DATA (ic, ExampleHookId);

  switch (hook_id)
  {
    case EXAMPLE_HOOK_OPEN:
      g_print ("[^] open\n");
      g_print ("[*] open(\"%s\")\n", gum_invocation_context_get_nth_argument (ic, 0));
      g_print ("[$] open\n");
      break;
    case EXAMPLE_HOOK_CLOSE:
      g_print ("[^] close\n");
      g_print ("[*] close(%d)\n", (int) gum_invocation_context_get_nth_argument (ic, 0));
      g_print ("[$] close\n");
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

  listener = g_object_new (example_listener_get_type(), NULL);
  g_print ("listener: %p\n", listener);

  (void)gum_interceptor_begin_transaction (interceptor);
  g_print ("gum_interceptor_begin_transaction\n");

  GumAddress open_addr = gum_module_find_export_by_name (NULL, "my_open");
  g_print ("gum_module_find_export_by_name(my_open): %p\n", open_addr);

  GumAttachReturn open_attach = gum_interceptor_attach_listener (interceptor,
      GSIZE_TO_POINTER (open_addr),
      listener,
      GSIZE_TO_POINTER (EXAMPLE_HOOK_OPEN));
  g_print ("gum_interceptor_attach_listener(my_open): %d\n", open_attach);

  GumAddress close_addr = gum_module_find_export_by_name (NULL, "my_close");
  g_print ("gum_module_find_export_by_name(my_close): %p\n", close_addr);

  GumAttachReturn close_attach = gum_interceptor_attach_listener (interceptor,
      GSIZE_TO_POINTER (close_addr),
      listener,
      GSIZE_TO_POINTER (EXAMPLE_HOOK_CLOSE));

  g_print ("gum_interceptor_attach_listener(my_close): %d\n", close_attach);

  gum_interceptor_end_transaction (interceptor);

  my_close (my_open ("/etc/hosts", O_RDONLY));
  my_close (my_open ("/etc/fstab", O_RDONLY));

  g_print ("[*] listener got %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  gum_interceptor_detach_listener(interceptor, listener);

  my_close (my_open ("/etc/hosts", O_RDONLY));
  my_close (my_open ("/etc/fstab", O_RDONLY));

  g_print ("[*] listener still has %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  g_object_unref (listener);
  g_object_unref (interceptor);

  gum_deinit_embedded ();

  g_print ("done\n");

  return 0;
}

