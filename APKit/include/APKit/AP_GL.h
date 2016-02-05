#pragma once

enum AP_GL {
    AP_GLES,
    AP_GL2,
    AP_GL3,
};

#ifdef __cplusplus
extern "C" {
#endif

extern enum AP_GL g_AP_GL;

#ifdef __cplusplus
} // extern "C"
#endif

#define AP_GLES_2_3(x,y,z) ((g_AP_GL == AP_GLES) ? (x) : ((g_AP_GL == AP_GL2) ? (y) : (z)))
