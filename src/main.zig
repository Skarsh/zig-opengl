const std = @import("std");
const windows = @import("std").os.windows;
const user32 = windows.user32;
const kernel32 = windows.kernel32;

const u8to16le = std.unicode.utf8ToUtf16LeStringLiteral;

extern "user32" fn MessageBoxA(hWnd: ?windows.HANDLE, lpText: ?windows.LPCSTR, lpCaption: ?windows.LPCSTR, uType: windows.UINT) callconv(windows.WINAPI) windows.INT;

extern "kernel32" fn AllocConsole() callconv(windows.WINAPI) windows.BOOL;

extern "kernel32" fn WriteConsoleA(
    hConsoleOutput: ?windows.HANDLE,
    lpBuffer: [*]const u8,
    nNumberOfCharsToWrite: u32,
    lpNumberOfCharsToWritten: ?*u32,
    lpReserved: ?*anyopaque,
) callconv(windows.WINAPI) windows.BOOL;

pub const STD_HANDLE = enum(u32) {
    INPUT_HANDLE = 4294967286,
    OUTPUT_HANDLE = 4294967285,
    ERROR_HANDLE = 4294967284,
};

pub const STD_INPUT_HANDLE = STD_HANDLE.INPUT_HANDLE;
pub const STD_OUTPUT_HANDLE = STD_HANDLE.OUTPUT_HANDLE;
pub const STD_ERROR_HANDLE = STD_HANDLE.ERROR_HANDLE;

extern "kernel32" fn GetStdHandle(
    nStdHandle: STD_HANDLE,
) callconv(windows.WINAPI) windows.HANDLE;

extern "opengl32" fn wglCreateContext(hdc: windows.HDC) callconv(windows.WINAPI) ?windows.HGLRC;

extern "opengl32" fn wglMakeCurrent(hdc: windows.HDC, hglrc: windows.HGLRC) callconv(windows.WINAPI) windows.BOOL;

const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: windows.WORD,
    nVersion: windows.WORD,
    dwFlags: windows.DWORD,
    iPixelType: u8,
    cColorBits: u8,
    cRedBits: u8,
    cRedShift: u8,
    cGreenBits: u8,
    cGreenShift: u8,
    cBlueBits: u8,
    cBlueShift: u8,
    cAlphaBits: u8,
    cAlphaShift: u8,
    cAccumBits: u8,
    cAccumRedBits: u8,
    cAccumGreenBits: u8,
    cAccumBlueBits: u8,
    cAccumAlphaBits: u8,
    cDepthBits: u8,
    cStencilBits: u8,
    cAuxBuffers: u8,
    iLayerType: u8,
    bReserved: u8,
    dwLayerMask: windows.DWORD,
    dwVisibleMask: windows.DWORD,
    dwDamageMask: windows.DWORD,
};

const PFD_TYPE_RGBA: u8 = 0;
const PFD_DOUBLEBUFFER: u32 = 0x00000001;
const PFD_DRAW_TO_WINDOW: u32 = 0x00000004;
const PFD_SUPPORT_OPENGL: u32 = 0x00000020;

extern "gdi32" fn ChoosePixelFormat(hdc: windows.HDC, ppfd: ?*PIXELFORMATDESCRIPTOR) callconv(windows.WINAPI) windows.INT;

extern "gdi32" fn SetPixelFormat(
    hdc: windows.HDC,
    iPixelFormat: i32,
    ppfd: ?*PIXELFORMATDESCRIPTOR,
) callconv(windows.WINAPI) windows.BOOL;

extern "opengl32" fn glGetString(name: u32) callconv(.C) [*]u8;

pub export fn WindowProc(
    hWnd: windows.HWND,
    message: windows.UINT,
    wParam: windows.WPARAM,
    lParam: windows.LPARAM,
) callconv(windows.WINAPI) windows.LRESULT {
    switch (message) {
        user32.WM_CREATE => {
            var pfd = PIXELFORMATDESCRIPTOR{
                .nSize = @sizeOf(PIXELFORMATDESCRIPTOR),
                .nVersion = 1,
                .dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
                .iPixelType = PFD_TYPE_RGBA,
                .cColorBits = 32,
                .cRedBits = 0,
                .cRedShift = 0,
                .cGreenBits = 0,
                .cGreenShift = 0,
                .cBlueBits = 0,
                .cBlueShift = 0,
                .cAlphaBits = 0,
                .cAlphaShift = 0,
                .cAccumBits = 0,
                .cAccumRedBits = 0,
                .cAccumGreenBits = 0,
                .cAccumBlueBits = 0,
                .cAccumAlphaBits = 0,
                .cDepthBits = 24, // Number of bits for the depthbuffer
                .cStencilBits = 8, // Number of bits for the stencilbuffer
                .cAuxBuffers = 0, // Number of Aux buffers in the framebuffer
                .iLayerType = 0, // NOTE: This is PFD_MAIN_PLANE in the Khronos example https://www.khronos.org/opengl/wiki/Creating_an_OpenGL_Context_(WGL), but this is suppposed to not be needed anymore?
                .bReserved = 0,
                .dwLayerMask = 0,
                .dwVisibleMask = 0,
                .dwDamageMask = 0,
            };

            const our_window_handle_to_device_context = user32.GetDC(hWnd);

            const let_windows_choose_pixel_format = ChoosePixelFormat(our_window_handle_to_device_context.?, &pfd);

            // TODO: handle return value
            _ = SetPixelFormat(our_window_handle_to_device_context.?, let_windows_choose_pixel_format, &pfd);

            const our_opengl_rendering_context = wglCreateContext(our_window_handle_to_device_context.?);

            // TODO: handle return value
            _ = wglMakeCurrent(our_window_handle_to_device_context.?, our_opengl_rendering_context.?);

            //user32.MessageBoxA(0, );
            const gl_version = glGetString(7938);
            const version_slice = gl_version[0..20];
            std.debug.print("OpenGL Version: {s}\n", .{version_slice});

            //_ = MessageBoxA(null, "version: " ++ gl_version, "OPENGL VERSION", 0);
        },
        else => {},
    }

    return user32.DefWindowProcW(hWnd, message, wParam, lParam);
}

pub export fn wWinMain(
    hInstance: ?windows.HINSTANCE,
    hPrevInstance: ?windows.HINSTANCE,
    lpCmdLine: ?windows.LPWSTR,
    nShowCmd: windows.INT,
) callconv(windows.WINAPI) windows.INT {
    _ = nShowCmd;
    _ = lpCmdLine;
    _ = hPrevInstance;

    var wc = user32.WNDCLASSEXW{
        .style = 0,
        .lpfnWndProc = WindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance.?,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = u8to16le("Test Window"),
        .hIconSm = null,
    };

    // TODO: Have a better way of checking this
    if (user32.RegisterClassExW(&wc) == 0) {
        return 1;
    }

    const hwnd = user32.CreateWindowExW(
        0,
        wc.lpszClassName,
        u8to16le("OpenGL Version Check"),
        user32.WS_OVERLAPPED | user32.WS_VISIBLE,
        0,
        0,
        640,
        480,
        null,
        null,
        hInstance.?,
        null,
    );

    var msg = user32.MSG{
        .hWnd = hwnd,
        .message = 0,
        .wParam = 0,
        .lParam = 0,
        .time = 0,
        .pt = windows.POINT{
            .x = 0,
            .y = 0,
        },
        .lPrivate = 0,
    };

    const hdc = user32.GetDC(hwnd);

    if (hdc == null) {
        std.log.err("Failed to get device context.\n", .{});
        return 1;
    }

    while (user32.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = user32.DispatchMessageW(&msg);
    }

    //if (hwnd) |window| {
    //    _ = user32.ShowWindow(window, nShowCmd);
    //    _ = user32.MessageBoxW(window, u8to16le("hello"), u8to16le("title"), 0);
    //} else {
    //    const err_code = kernel32.GetLastError();
    //    std.log.err("{}", .{err_code});
    //}

    return 0;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
