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
  EXAMPLE_HOOK_CLOSE,
  EXAMPLE_HOOK_TEST,
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

guint64 my_test(
    guint64 a0,
    guint64 a1,
    guint64 a2,
    guint64 a3,
    guint64 a4,
    guint64 a5,
    guint64 a6,
    guint64 a7,
    guint64 a8,
    guint64 a9,
    guint64 a10,
    guint64 a11
    )
{
  g_print("a00: 0x%016lx\n", a0);
  g_print("a01: 0x%016lx\n", a1);
  g_print("a02: 0x%016lx\n", a2);
  g_print("a03: 0x%016lx\n", a3);
  g_print("a04: 0x%016lx\n", a4);
  g_print("a05: 0x%016lx\n", a5);
  g_print("a06: 0x%016lx\n", a6);
  g_print("a07: 0x%016lx\n", a7);
  g_print("a08: 0x%016lx\n", a8);
  g_print("a09: 0x%016lx\n", a9);
  g_print("a10: 0x%016lx\n", a10);
  g_print("a11: 0x%016lx\n", a11);

  return 0xDEADFACEB00BCAFE;
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
  guint32 i = 0;

  switch (hook_id)
  {
    case EXAMPLE_HOOK_OPEN:
      g_print ("[^] open\n");
      g_print ("[*] open(\"%p\")\n", gum_invocation_context_get_nth_argument (ic, 0));
      g_print ("[*] open(\"%s\")\n", gum_invocation_context_get_nth_argument (ic, 0));
      g_print ("[$] open\n");
      break;
    case EXAMPLE_HOOK_CLOSE:
      g_print ("[^] close\n");
      g_print ("[*] close(%d)\n", (int) gum_invocation_context_get_nth_argument (ic, 0));
      g_print ("[$] close\n");
      break;
    case EXAMPLE_HOOK_TEST:

      for(i = 0; i < 12; i++)
      {
        g_print ("[*] test(\"arg%d: 0x%016lx\")\n", i, gum_invocation_context_get_nth_argument (ic, i));
      }
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

  printf ("main\n");

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

  GumAddress test_addr = gum_module_find_export_by_name (NULL, "my_test");
  g_print ("gum_module_find_export_by_name(my_test): %p\n", my_test);

  GumAttachReturn test_attach = gum_interceptor_attach_listener (interceptor,
      GSIZE_TO_POINTER (my_test),
      listener,
      GSIZE_TO_POINTER (EXAMPLE_HOOK_TEST));

  g_print ("gum_interceptor_attach_listener(my_test): %d\n", test_attach);

  gum_interceptor_end_transaction (interceptor);

  guint64 test = my_test(
    0x1010202030304040,
    0x1111212131314141,
    0x1212222232324242,
    0x1313232333334343,
    0x1414242434344444,
    0x1515252535354545,
    0x1616262636364646,
    0x1717272737374747,
    0x1818282838384848,
    0x1919292939394949,
    0x1a1a2a2a3a3a4a4a,
    0x1b1b2b2b3b3b4d4d);

  g_print("test: 0x%016lx\n", test);


  char* filename1 = "/etc/hosts";
  g_print("filename1: %s, @ %p\n", filename1, filename1);

  char* filename2 = "/etc/fstab";
  g_print("filename2: %s, @ %p\n", filename2, filename2);

  int fd1 = my_open (filename1, O_RDONLY);
  g_print("fd1: %d\n", fd1);
  my_close (fd1);

  int fd2 = my_open (filename2, O_RDONLY);
  g_print("fd2: %d\n", fd2);
  my_close (fd2);

  g_print ("[*] listener got %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  gum_interceptor_detach_listener(interceptor, listener);

  int fd3 = my_open (filename1, O_RDONLY);
  g_print("fd3: %d\n", fd3);
  my_close (fd3);

  int fd4 = my_open (filename2, O_RDONLY);
  g_print("fd4: %d\n", fd4);
  my_close (fd4);

  g_print ("[*] listener still has %u calls\n", EXAMPLE_LISTENER (listener)->num_calls);

  g_print ("[*] tidying up\n");

  g_object_unref (listener);
  g_print ("[*] deleted listener\n");

  g_object_unref (interceptor);
  g_print ("[*] deleted interceptor\n");

  gum_deinit_embedded ();
  printf ("[*] unintialized\n");


  printf ("done\n");

  return 0;
}

