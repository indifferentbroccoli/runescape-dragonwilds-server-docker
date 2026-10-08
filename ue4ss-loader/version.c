#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define VERSION_EXPORTS(X) \
    X(GetFileVersionInfoA) \
    X(GetFileVersionInfoExA) \
    X(GetFileVersionInfoExW) \
    X(GetFileVersionInfoSizeA) \
    X(GetFileVersionInfoSizeExA) \
    X(GetFileVersionInfoSizeExW) \
    X(GetFileVersionInfoSizeW) \
    X(GetFileVersionInfoW) \
    X(VerFindFileA) \
    X(VerFindFileW) \
    X(VerInstallFileA) \
    X(VerInstallFileW) \
    X(VerLanguageNameA) \
    X(VerLanguageNameW) \
    X(VerQueryValueA) \
    X(VerQueryValueW)

/* Forward every export to the real version.dll, or the game fails to load this one */
#define DEFINE_STUB(name) \
    FARPROC real_##name; \
    __attribute__((naked)) void proxy_##name(void) { __asm__("jmp *real_" #name "(%rip)"); }
VERSION_EXPORTS(DEFINE_STUB)

static void load_real_version(void)
{
    wchar_t path[MAX_PATH];
    UINT len = GetSystemDirectoryW(path, MAX_PATH - 13);
    lstrcpyW(path + len, L"\\version.dll");

    HMODULE real = LoadLibraryW(path);
    if (!real)
        return;
#define RESOLVE(name) real_##name = GetProcAddress(real, #name);
    VERSION_EXPORTS(RESOLVE)
}

static void load_ue4ss(HMODULE self)
{
    wchar_t path[MAX_PATH];
    DWORD len = GetModuleFileNameW(self, path, MAX_PATH - 11);
    while (len > 0 && path[len - 1] != L'\\')
        len--;
    lstrcpyW(path + len, L"dwmapi.dll");

    LoadLibraryW(path);
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        DisableThreadLibraryCalls(instance);
        load_real_version();
        load_ue4ss(instance);
    }

    return TRUE;
}
