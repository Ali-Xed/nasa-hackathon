#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "APTimeZones.h"
#import "CLLocation+APTimeZones.h"
#import "CLPlacemark+APTimeZones.h"

FOUNDATION_EXPORT double APTimeZonesVersionNumber;
FOUNDATION_EXPORT const unsigned char APTimeZonesVersionString[];

