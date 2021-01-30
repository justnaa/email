#include "../Main.h"
void smtpServer() {
    // Creating file endpoint
    int socketStatus = socket(AF_INET, SOCK_STREAM, 0);
    if (socketStatus == -1) {
        printf("Error!");
        return;
    }
    // Binding
    struct sockaddr_in addr, clientAddr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(25);
    int bindStatus = bind(socketStatus, (struct sockaddr *) &addr, sizeof(addr));
    if (bindStatus == -1) {
        printf("Error! Unable to bind");
        return;
    }
    // Starting to listen
    int listenStatus = listen(socketStatus, 5);
    if (listenStatus == -1) {
        printf("Error! Unable to listen");
        return;
    }
    // Now lets start accepting!
    while (1) {
        int clientAddrLen = sizeof(clientAddr);
        int accepting = accept(socketStatus, (struct sockaddr *) &addr, &clientAddrLen);
        if (accepting == -1) {
            printf("Error! Unable to accept");
            continue;
        } else
            handleRequest(accepting);
    }
}

void handleRequest(int accepting) {
    // Creating a blank email
    Email email = {"unknown", "unknown", "unknown", false};
    char first[33] = "220 ESMTP Juliette's SMTP server\n";
    write(accepting, first, sizeof(first)); 
    // Reading connection
    while(1) {
        char buff[1000];
        int readStatus = read(accepting, buff, sizeof(buff));
        printf("Buffer : %s \n",  buff);
        // Handling non normal commands
        char firstFour[4]; // Each non normal command is 4 characters long so we're going to get the first four
        strncpy(firstFour, buff, sizeof(firstFour)); // Creating a sub string
        // Now checking
        if (strstr(firstFour, "EHLO") != NULL || strstr(firstFour, "HELO") != NULL) {
            helloCommand(accepting);
            continue;
        }
        if (strstr(firstFour, "DATA") != NULL) {
            dataCommand(accepting, &email);
            continue;
        }
        if (strstr(firstFour, "QUIT") != NULL) {
            close(accepting);
            printf("Email from : %s \n Email to : %s \n Email data : %s \n Email fromip : %s \n Email dataMode : %d", email.from, email.to, email.data, email.fromip, email.dataMode); 
            break;
        }
        // Spliting into command and args
        char splitter[] = ":";
        char *command = strtok(buff, splitter);
        char *args = strtok(NULL, splitter);
        // Now lets handle normal commands
        if (strstr(command, "MAIL FROM") != NULL)
            mailFromCommand(accepting, &email, args);
        else if (strstr(command, "RCPT TO") != NULL)
            rcptToCommand(accepting, &email, args);
    }
}

void helloCommand(int file) {
    char message[23] = "220 Hello, Im juliette\n";
    printf("Message %s \n Size: %lu \n", message, sizeof(message));
    write(file, message, sizeof(message));
}

void dataCommand(int file, Email *email) {
    email->dataMode = true;
    char message[36] = "354 End data with <CR><LF>.<CR><LF>\n";
    write(file, message, sizeof(message));
}

void mailFromCommand(int file, Email *email, char *args) {
    email->from = args;
    char message[7] = "250 Ok\n";
    write(file, message, sizeof(message));
}

void rcptToCommand(int file, Email *email, char *args) {
    strcat(email->to, args);
    char message[7] = "250 Ok\n";
    write(file, message, sizeof(message));

}
