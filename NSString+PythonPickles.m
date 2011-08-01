#import "NSString+PythonPickles.h"
#include <Python/Python.h>

NSString* const SSYPythonPicklesErrorDomain = @"SSYPythonPicklesErrorDomain" ;
NSString* const SSYPythonPicklesUnderErrorDomain = @"SSYPythonPicklesUnderErrorDomain" ;

@implementation NSString (PythonPickles)

- (NSString*)pythonUnpickledError_p:(NSError**)error_p {
	NSString* answer = nil ;
	NSString* errorDesc = NULL ;
	NSInteger errorCode = 0 ;
	
	Py_Initialize() ;
	
    // Create Python Namespace (dictionary of variables)
	PyObject* pythonStringArg = PyString_FromString([self UTF8String]) ;
	if (!pythonStringArg) {
		errorDesc = @"Cannot convert string arg to Python\n" ;
		errorCode = 523001 ;
		goto end ;
	}
	PyObject* pythonVarsDic = PyDict_New();
	PyDict_SetItemString(
						 pythonVarsDic,
						 "__builtins__",
						 PyEval_GetBuiltins());	
	PyDict_SetItemString(
						 pythonVarsDic,
						 "x",
						 pythonStringArg) ;
	
    // Create "hard" source code string to unpickle
    // (For some strange reason, they call it loads()
    // The "s" in "loads" stands for "string".)
	char* pythonSource =
	"from pickle import loads\n\n"
	"y = loads(x)\n" ;
	
	// Run the python source code
	PyRun_String(pythonSource,
				 Py_file_input,
				 pythonVarsDic,
				 pythonVarsDic) ;
	PyObject* unpickledPythonString = PyDict_GetItemString(pythonVarsDic, "y") ;
	// unpickledPythonString is a borrowed ref, so don't DECREF it.
	if (!unpickledPythonString) {
		errorDesc = @"Unpickling returned NULL\n" ;
		errorCode = 523002 ;
		goto end ;
	}
	
	// Convert the unpickled Python string to a C string
	char* unpickledString = PyString_AsString(unpickledPythonString) ;
	if (!unpickledString) {
		errorDesc = @"Failed converting unpickled string to C string\n" ;
		errorCode = 523003 ;
		goto end ;
	}
	
	// Convert the C string into a string object
	answer = [NSString stringWithUTF8String:unpickledString] ;
	
end:
	if (error_p && (errorCode != 0)) {
		NSError* pythonErrorString = nil ;
		if (PyErr_Occurred()) {
			PyObject* errtype ;
			PyObject* errvalue ;
			PyObject* traceback ;
			PyErr_Fetch(&errtype, &errvalue, &traceback) ;
			if(errvalue != NULL) {
				PyObject *pythonPythonErrorString = PyObject_Str(errvalue) ;
				char* cPythonErrorString = PyString_AsString(pythonPythonErrorString) ;
				if (cPythonErrorString) {
					pythonErrorString = [NSString stringWithUTF8String:cPythonErrorString] ;
				}
				else {
					NSLog(@"Failed converting python error string to C") ;
				}
				Py_DECREF(pythonPythonErrorString) ;
			}
			Py_XDECREF(errvalue) ;
			Py_XDECREF(errtype) ;
			Py_XDECREF(traceback) ;
		}
		
		NSError* underlyingError = [NSError errorWithDomain:SSYPythonPicklesUnderErrorDomain
													   code:523000
												   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															 pythonErrorString, NSLocalizedDescriptionKey,
															 nil]] ;
		
		
		*error_p = [NSError errorWithDomain:SSYPythonPicklesErrorDomain
									   code:errorCode
								   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
											 errorDesc, NSLocalizedDescriptionKey,
											 underlyingError, NSUnderlyingErrorKey,
											 nil]] ;
	}
	
	Py_Finalize() ;
	
    return answer ;
}

@end