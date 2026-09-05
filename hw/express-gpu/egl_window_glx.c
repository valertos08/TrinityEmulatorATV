/**
 * @file egl_window_glx.c
 * @brief Linux/GLX implementation of the window/context abstraction
 *        that the original Windows code provided via WGL.
 */

#include "qemu/osdep.h"
#include "express-gpu/egl_window.h"
#include "express-gpu/egl_display.h"
#include "express-gpu/egl_config.h"
#include "direct-express/express_log.h"

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

extern GLFWwindow *express_gpu_glfw_window;

static void *g_dpy = NULL;
static void *g_ctx = NULL;

void init_configs(Egl_Display *display)
{
    if (display->egl_config_set == NULL)
    {
        display->egl_config_set = g_hash_table_new(g_direct_hash, g_direct_equal);
    }

    add_simple_config(display);
    add_window_independent_config(display, EGL_DEPTH_SIZE, depth_vals, NUM_DEPTH_VAL);
    add_window_independent_config(display, EGL_STENCIL_SIZE, stencil_vals, NUM_STENCILE_VAL);
    add_window_independent_config(display, EGL_SAMPLES, sample_vals, NUM_SAMPLE_VAL);
}

void init_display(Egl_Display **display_point)
{
    Egl_Display *display = g_malloc0(sizeof(Egl_Display));
    *display_point = display;

    express_printf("init display (glx)\n");
    init_configs(display);

    display->guest_ver_major = 1;
    display->guest_ver_minor = 5;

    display->is_init = true;
}

void egl_init(void *dpy, void *father_context)
{
    g_dpy = dpy;
    g_ctx = father_context;

    express_printf("egl_init dpy %p ctx %p\n", g_dpy, g_ctx);
}

void *egl_createContext()
{
    if (!express_gpu_glfw_window)
    {
        express_printf("egl_createContext: main window not ready\n");
        return NULL;
    }

    glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
    GLFWwindow *child = glfwCreateWindow(1, 1, "trinity-egl", NULL,
                                         express_gpu_glfw_window);
    if (!child)
    {
        const char *desc = NULL;
        int err = glfwGetError(&desc);
        express_printf("egl_createContext failed err %d %s\n", err,
                       desc ? desc : "");
        return NULL;
    }

    return (void *)child;
}

void egl_makeCurrent(void *context)
{
    if (context)
    {
        glfwMakeContextCurrent((GLFWwindow *)context);
    }
    else
    {
        glfwMakeContextCurrent(NULL);
    }
}

void egl_destroyContext(void *context)
{
    if (!context)
    {
        return;
    }

    glfwDestroyWindow((GLFWwindow *)context);
}