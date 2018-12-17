// on windows compile for win 32 only
// -g x86

#include <stdio.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifdef _WIN32
    #include <Windows.h>
#endif

#ifdef __APPLE__
    #include <termios.h>
    #include <sys/ioctl.h>
#endif

#ifdef __linux
    #include <termio.h>
    #include <sys/ioctl.h>
#endif


int stdinIsEmpty() {
#ifdef _WIN32
    DWORD numEvents;
    GetNumberOfConsoleInputEvents(GetStdHandle(STD_INPUT_HANDLE),&numEvents);
    return numEvents == 0;
#else
    int characters_buffered = 0;
    ioctl(STDIN_FILENO, FIONREAD, &characters_buffered);
    return characters_buffered == 0;
#endif
    return 35;
}


char* readStdinLine() {
    int c;
    size_t p4kB = 4096, i = 0;
    void *newPtr = NULL;
    char *ptrString = malloc(p4kB * sizeof (char));

    while (ptrString != NULL && (c = getchar()) != '\n' && c != EOF) {
        if (i == p4kB * sizeof (char)) {
            p4kB += 4096;
            if ((newPtr = realloc(ptrString, p4kB * sizeof (char))) != NULL) {
                ptrString = (char*) newPtr;
            } else {
                free(ptrString);
                return NULL;
            }
        }
        ptrString[i++] = c;
    }

    if (ptrString != NULL) {
        ptrString[i] = '\0';
        ptrString = realloc(ptrString, strlen(ptrString) + 1);
    } else {
        return NULL;
    }

    return ptrString;
}
