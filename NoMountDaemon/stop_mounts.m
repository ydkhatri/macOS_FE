/*
   (c) 2019 Yogesh Khatri 
    GPLv3 License
*/
#include <stdio.h>
#include <signal.h>
#import <CoreFoundation/CoreFoundation.h>
#import <DiskArbitration/DiskArbitration.h>

void clean_up_and_exit();
void desc_change_callback(DADiskRef disk, CFArrayRef keys, void *context);
DADissenterRef mount_permission_check_callback(DADiskRef disk, void *context);
DASessionRef session;

/* Signal Handler for SIGINT & SIGTERM */
void sig_int_term_handler(int sig_num) 
{ 
    printf("\nCtrl-C or SIGTERM sent, shutting down.. \n");
    fflush(stdout);
    clean_up_and_exit();
}

int main(int argc, const char *argv[]) {

    session = DASessionCreate(kCFAllocatorDefault);
    DARegisterDiskMountApprovalCallback(session,
                NULL, /* Match all disks */
                mount_permission_check_callback,
                NULL); /* No context */

    /* Schedule a disk arbitration session. */
    DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    DARegisterDiskDescriptionChangedCallback(session, NULL /* match all disks */, 
        NULL /* match all keys */, desc_change_callback, NULL);

    signal(SIGINT, sig_int_term_handler); // Register the signal handler before entering loop
    signal(SIGTERM, sig_int_term_handler); // Register the signal handler before entering loop

    CFRunLoopRun();
    
    clean_up_and_exit(); // should never go here

    return EXIT_SUCCESS;
}

/* Clean up a session. */
void clean_up_and_exit() {
    printf("Cleaning up session resources..\n");
    DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    printf("Unregistering callbacks..\n");
    DAUnregisterCallback(session, mount_permission_check_callback, NULL);
    DAUnregisterCallback(session, desc_change_callback, NULL);
    CFRelease(session);
    session = NULL;
    fflush(stdout);
    exit(EXIT_SUCCESS);
}

DADissenterRef mount_permission_check_callback(DADiskRef disk, void *context) {
    int allow = 0;
    int is_internal = 1;

    //printf("mount_permission_check_callback: DISK NAME = %s\n", DADiskGetBSDName(disk));
    CFDictionaryRef dict = DADiskCopyDescription(disk);
    printf("mount_permission_check_callback: Printing disk attributes\n");
    CFShow(dict);
    fflush(stderr);
    if (CFDictionaryContainsKey(dict, kDADiskDescriptionDeviceInternalKey)) {
        printf("Disk has DEVICEINTERNAL key *******\n");
        CFNumberRef is_internal_ref = (CFNumberRef) CFDictionaryGetValue(dict, kDADiskDescriptionDeviceInternalKey);
        CFNumberGetValue(is_internal_ref, kCFNumberIntType, &is_internal);
        printf("Disk has DEVICEINTERNAL value = %d ********\n", is_internal);
        allow = (is_internal == 0);
    }
    else allow = 1;

    if (allow) { /* Return NULL to allow */
        fprintf(stderr, "mount_permission_check_callback: allowing mount.\n");
        fflush(stdout);
        return NULL;
    } else { /* Return a dissenter to deny */
        fprintf(stderr, "mount_permission_check_callback: refusing mount.\n");
        fflush(stdout);
        return DADissenterCreate(kCFAllocatorDefault, kDAReturnExclusiveAccess,
            CFSTR("Internal disks can't be mounted!"));
    }
}

/* Code from https://opensource.apple.com/source/DiskArbitration/DiskArbitration-277/diskarbitrationd/DAInternal.c */
char * CFStringCopyCString( CFStringRef string ) {
    /*
     * Creates a C string buffer from a CFString object.  The string encoding is presumed to be
     * UTF-8.  The result is a reference to a C string buffer or NULL if there was a problem in
     * creating the buffer.  The caller is responsible for releasing the buffer with free().
     */

    char * buffer = NULL;

    if ( string ) {
        CFIndex length;
        CFRange range;

        range = CFRangeMake( 0, CFStringGetLength( string ) );
        if ( CFStringGetBytes( string, range, kCFStringEncodingUTF8, 0, FALSE, NULL, 0, &length ) ) {
            buffer = malloc( length + 1 );
            if ( buffer ) {
                CFStringGetBytes( string, range, kCFStringEncodingUTF8, 0, FALSE, ( void * ) buffer, length, NULL );
                buffer[length] = 0;
            }
        }
    }
    return buffer;
}
void desc_change_callback(DADiskRef disk, CFArrayRef keys, void *context) {
    //printf("in desc_change_callback: DISK NAME = %s\n", DADiskGetBSDName(disk));
    CFDictionaryRef dict = DADiskCopyDescription(disk);
    printf("desc_change_callback: Printing disk attributes\n");
    CFShow(dict);
    /* Read the keynames from the CFArrayRef */
    CFIndex nameCount = CFArrayGetCount(keys);
    if (nameCount) {
        printf("desc_change_callback: Changed properties are: ");
        for (int i = 0; i < nameCount ; ++i) {
            CFStringRef name_ref = (CFStringRef)CFArrayGetValueAtIndex(keys, i);
            char * key_name = CFStringCopyCString(name_ref);
            if (i == 0) printf("%s", key_name); else printf(", %s", key_name);
        }
        printf("\n");
    }

    CFURLRef fspath = CFDictionaryGetValue(dict, kDADiskDescriptionVolumePathKey);
 
    char buf[1024];
    if (CFURLGetFileSystemRepresentation(fspath, false, (UInt8 *)buf, sizeof(buf))) {
        printf("desc_change_callback: Disk %s is now at %s\n", DADiskGetBSDName(disk), buf);
    } else {
        printf("desc_change_callback: Disk %s is now being unmounted?\n", DADiskGetBSDName(disk));
    }
    fflush(stdout);
    fflush(stderr);
}
