#pragma once

#import "AP_Application.h"

#ifdef __cplusplus
extern "C" {
#endif

// Must be provided by application-specific code
extern id<AP_ApplicationDelegate> AP_GetDelegate();

#ifdef __cplusplus
}
#endif
