// C library headers
#include <stdio.h>
#include <string.h>

// Linux headers
#include <fcntl.h> // Contains file controls like O_RDWR
#include <errno.h> // Error integer and strerror() function
#include <termios.h> // Contains POSIX terminal control definitions
#include <unistd.h> // write(), read(), close()

int serial_port = open("/dev/ttyUSB0", O_RDWR);

// Check for errors
if (serial_port < 0) {
    //Errno is error code, strerror(errno) returns pointer to string which describes the error described by error code
    printf("Error %i from open: %s\n", errno, strerror(errno));
}

// Create new termios struct, we call it 'tty' for convention
struct termios tty;

// Read in existing settings, and handle any error
// NOTE: This is important! POSIX states that the struct passed to tcsetattr()
// must have been initialized with a call to tcgetattr() overwise behaviour
// is undefined
if(tcgetattr(serial_port, &tty) != 0) {
    printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
}

tty.c_cflag &= ~PARENB; // Clear parity bit, disabling parity.
tty.c_cflag &= ~CSIZE; // Clear all the size bits
tty.c_cflag |= CS8; // 8 bits per byte (most common)

/*Disable RTS/CTS hardware flow control. RTS/CTS hardware flow control relies on
ready signalling between sender and receiver.*/
tty.c_cflag &= ~CRTSCTS; 
tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines (CLOCAL = 1)
tty.c_lflag &= ~ICANON;
tty.c_lflag &= ~ECHO; // Disable echo
tty.c_lflag &= ~ECHOE; // Disable erasure
tty.c_lflag &= ~ECHONL; // Disable new-line echo



