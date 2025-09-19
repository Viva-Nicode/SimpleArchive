#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"org.azurelight.SimpleArchive";

/// The "ComponentToolbarColor" asset catalog color resource.
static NSString * const ACColorNameComponentToolbarColor AC_SWIFT_PRIVATE = @"ComponentToolbarColor";

/// The "MyGray" asset catalog color resource.
static NSString * const ACColorNameMyGray AC_SWIFT_PRIVATE = @"MyGray";

/// The "file-plus" asset catalog image resource.
static NSString * const ACImageNameFilePlus AC_SWIFT_PRIVATE = @"file-plus";

/// The "folder-plus" asset catalog image resource.
static NSString * const ACImageNameFolderPlus AC_SWIFT_PRIVATE = @"folder-plus";

#undef AC_SWIFT_PRIVATE
