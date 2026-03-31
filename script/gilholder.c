#include <Python.h>
#include <unistd.h>

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

static PyMethodDef gilholder_methods[] = {
    {"hold_gil", gilholder_hold_gil, METH_VARARGS,
     "Hold the GIL for N seconds without releasing it."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef gilholder_module = {
    PyModuleDef_HEAD_INIT,
    "gilholder",
    "C extension that holds the GIL to demonstrate contention.",
    -1,
    gilholder_methods
};

PyMODINIT_FUNC
PyInit_gilholder(void)
{
    return PyModule_Create(&gilholder_module);
}
