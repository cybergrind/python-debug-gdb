#include <Python.h>
#include <unistd.h>

/* ── GIL-holding demo ──────────────────────────────────────────────── */

static PyObject *
gilholder_hold_gil(PyObject *self, PyObject *args)
{
    int seconds;
    if (!PyArg_ParseTuple(args, "i", &seconds))
        return NULL;

    /* Intentionally do NOT release the GIL — this is the whole point.
       All other Python threads will block in take_gil(). */
    sleep(seconds);

    Py_RETURN_NONE;
}

/* ── GC demo: breakpoint target called from __del__ ────────────────── */

static volatile int _gc_signal_flag = 0;

static PyObject *
gilholder_finalizer_signal(PyObject *self, PyObject *Py_UNUSED(ignored))
{
    /* Called from a __del__ finalizer during GC.
       Set a breakpoint here in GDB to catch a collection in progress. */
    _gc_signal_flag = 1;
    Py_RETURN_NONE;
}

/* ── module definition ─────────────────────────────────────────────── */

static PyMethodDef gilholder_methods[] = {
    {"hold_gil", gilholder_hold_gil, METH_VARARGS,
     "Hold the GIL for N seconds without releasing it."},
    {"finalizer_signal", gilholder_finalizer_signal, METH_NOARGS,
     "No-op called from __del__; exists as a GDB breakpoint target."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef gilholder_module = {
    PyModuleDef_HEAD_INIT,
    "gilholder",
    "C extension for Python debugging demos.",
    -1,
    gilholder_methods
};

PyMODINIT_FUNC
PyInit_gilholder(void)
{
    return PyModule_Create(&gilholder_module);
}
