const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (!target.isWindows()) {
        std.log.err("Target OS must be Windows, try zig build -Dtarget=x86_64-windows-gnu", .{});
        return;
    }

    const is_msvc = target.isWindows() and target.toTarget().abi == .msvc;

    var cflags = std.ArrayList([]const u8).init(b.allocator);
    cflags.appendSlice(&.{
        "-DCOBJMACROS",
        "-D_UNICODE",
        "-DUNICODE",
        "-fno-sanitize=undefined",
    }) catch @panic("OOM");
    if (is_msvc) {
        cflags.appendSlice(&.{
            "-D_OFF_T_DEFINED",
            "-D_off_t=__int64",
            "-Doff_t=_off_t",
            "-D_OFF_T_",
            "-D_CRTDBG_MAP_ALLOC",
        }) catch @panic("OOM");
    } else {
        cflags.appendSlice(&.{
            "-D_FILE_OFFSET_BITS=64",
            "-D_OFF_T_",
            "-D_off_t=off64_t",
            "-Doff_t=off64_t",
            "-Doff32_t=long",
            "-D__USE_MINGW_ANSI_STDIO=0",
            "-std=gnu99",
        }) catch @panic("OOM");
    }

    const libbled = b.addStaticLibrary(.{
        .name = "bled",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libbled.addCSourceFiles(.{
        .files = &.{
            "src/bled/bled.c",
            "src/bled/crc32.c",
            "src/bled/data_align.c",
            "src/bled/data_extract_all.c",
            "src/bled/data_skip.c",
            "src/bled/decompress_bunzip2.c",
            "src/bled/decompress_gunzip.c",
            "src/bled/decompress_uncompress.c",
            "src/bled/decompress_unlzma.c",
            "src/bled/decompress_unxz.c",
            "src/bled/decompress_unzip.c",
            "src/bled/decompress_vtsi.c",
            "src/bled/filter_accept_all.c",
            "src/bled/filter_accept_list.c",
            "src/bled/filter_accept_reject_list.c",
            "src/bled/find_list_entry.c",
            "src/bled/header_list.c",
            "src/bled/header_skip.c",
            "src/bled/header_verbose_list.c",
            "src/bled/init_handle.c",
            "src/bled/open_transformer.c",
            "src/bled/seek_by_jump.c",
            "src/bled/seek_by_read.c",
            "src/bled/xz_dec_bcj.c",
            "src/bled/xz_dec_lzma2.c",
            "src/bled/xz_dec_stream.c",
        },
        .flags = cflags.items,
    });
    libbled.addIncludePath(.{ .path = "src/bled" });
    libbled.addIncludePath(.{ .path = "src" });

    const libext2fs = b.addStaticLibrary(.{
        .name = "ext2fs",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    var libext2fs_flags = cflags.clone() catch @panic("OOM");
    libext2fs_flags.appendSlice(if (is_msvc) &.{} else &.{
        "-DEXT2_FLAT_INCLUDES=0",
        "-DHAVE_CONFIG_H",
    }) catch @panic("OOM");
    libext2fs.addCSourceFiles(.{
        .files = &.{
            "src/ext2fs/alloc.c",
            "src/ext2fs/alloc_sb.c",
            "src/ext2fs/alloc_stats.c",
            "src/ext2fs/alloc_tables.c",
            "src/ext2fs/badblocks.c",
            "src/ext2fs/bb_inode.c",
            "src/ext2fs/bitmaps.c",
            "src/ext2fs/bitops.c",
            "src/ext2fs/blkmap64_ba.c",
            "src/ext2fs/blkmap64_rb.c",
            "src/ext2fs/blknum.c",
            "src/ext2fs/block.c",
            "src/ext2fs/bmap.c",
            "src/ext2fs/closefs.c",
            "src/ext2fs/crc16.c",
            "src/ext2fs/crc32c.c",
            "src/ext2fs/csum.c",
            "src/ext2fs/dirblock.c",
            "src/ext2fs/dirhash.c",
            "src/ext2fs/dir_iterate.c",
            "src/ext2fs/extent.c",
            "src/ext2fs/ext_attr.c",
            "src/ext2fs/extent.c",
            "src/ext2fs/fallocate.c",
            "src/ext2fs/fileio.c",
            "src/ext2fs/freefs.c",
            "src/ext2fs/gen_bitmap.c",
            "src/ext2fs/gen_bitmap64.c",
            "src/ext2fs/get_num_dirs.c",
            "src/ext2fs/hashmap.c",
            "src/ext2fs/i_block.c",
            "src/ext2fs/ind_block.c",
            "src/ext2fs/initialize.c",
            "src/ext2fs/inline.c",
            "src/ext2fs/inline_data.c",
            "src/ext2fs/inode.c",
            "src/ext2fs/io_manager.c",
            "src/ext2fs/link.c",
            "src/ext2fs/lookup.c",
            "src/ext2fs/mkdir.c",
            "src/ext2fs/mkjournal.c",
            "src/ext2fs/namei.c",
            "src/ext2fs/mmp.c",
            "src/ext2fs/newdir.c",
            "src/ext2fs/nt_io.c",
            "src/ext2fs/openfs.c",
            "src/ext2fs/punch.c",
            "src/ext2fs/rbtree.c",
            "src/ext2fs/read_bb.c",
            "src/ext2fs/rw_bitmaps.c",
            "src/ext2fs/sha512.c",
            "src/ext2fs/symlink.c",
            "src/ext2fs/valid_blk.c",
        },
        .flags = libext2fs_flags.items,
    });
    libext2fs.addIncludePath(.{ .path = "src/ext2fs" });
    libext2fs.addIncludePath(.{ .path = "src" });
    if (is_msvc) {
        libext2fs.addIncludePath(.{ .path = "src/msvc-missing" });
    }

    // libcdio
    var libcdio_flags = cflags.clone() catch @panic("OOM");
    libcdio_flags.append("-DHAVE_CONFIG_H") catch @panic("OOM");
    const libdriver = b.addStaticLibrary(.{
        .name = "driver",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libdriver.addCSourceFiles(.{
        .files = &.{
            "src/libcdio/driver/disc.c",
            "src/libcdio/driver/ds.c",
            "src/libcdio/driver/logging.c",
            "src/libcdio/driver/memory.c",
            "src/libcdio/driver/read.c",
            "src/libcdio/driver/sector.c",
            "src/libcdio/driver/track.c",
            "src/libcdio/driver/util.c",
            "src/libcdio/driver/_cdio_stdio.c",
            "src/libcdio/driver/_cdio_stream.c",
            "src/libcdio/driver/utf8.c",
        },
        .flags = libcdio_flags.items,
    });
    libdriver.addIncludePath(.{ .path = "src/libcdio/driver" });
    libdriver.addIncludePath(.{ .path = "src/libcdio" });
    libdriver.addIncludePath(.{ .path = "src" });
    if (is_msvc) {
        libdriver.addIncludePath(.{ .path = "src/msvc-missing" });
    }

    const libiso9660 = b.addStaticLibrary(.{
        .name = "iso9660",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libiso9660.addCSourceFiles(.{
        .files = &.{
            "src/libcdio/iso9660/iso9660.c",
            "src/libcdio/iso9660/iso9660_fs.c",
            "src/libcdio/iso9660/rock.c",
            "src/libcdio/iso9660/xa.c",
        },
        .flags = libcdio_flags.items,
    });
    libiso9660.addIncludePath(.{ .path = "src/libcdio/iso9660" });
    libiso9660.addIncludePath(.{ .path = "src/libcdio/driver" });
    libiso9660.addIncludePath(.{ .path = "src/libcdio" });
    libiso9660.addIncludePath(.{ .path = "src" });
    if (is_msvc) {
        libiso9660.addIncludePath(.{ .path = "src/msvc-missing" });
    }

    const libudf = b.addStaticLibrary(.{
        .name = "udf",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libudf.addCSourceFiles(.{
        .files = &.{
            "src/libcdio/udf/udf.c",
            "src/libcdio/udf/udf_file.c",
            "src/libcdio/udf/udf_fs.c",
            "src/libcdio/udf/udf_time.c",
            "src/libcdio/udf/filemode.c",
        },
        .flags = libcdio_flags.items,
    });
    libudf.addIncludePath(.{ .path = "src/libcdio/udf" });
    libudf.addIncludePath(.{ .path = "src/libcdio/driver" });
    libudf.addIncludePath(.{ .path = "src/libcdio" });
    libudf.addIncludePath(.{ .path = "src" });
    if (is_msvc) {
        libudf.addIncludePath(.{ .path = "src/msvc-missing" });
    }

    // ms-sys
    const libmssys = b.addStaticLibrary(.{
        .name = "mssys",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libmssys.addCSourceFiles(.{
        .files = &.{
            "src/ms-sys/fat12.c",
            "src/ms-sys/fat16.c",
            "src/ms-sys/fat32.c",
            "src/ms-sys/ntfs.c",
            "src/ms-sys/partition_info.c",
            "src/ms-sys/br.c",
            "src/ms-sys/file.c",
        },
        .flags = cflags.items,
    });
    libmssys.addIncludePath(.{ .path = "src/ms-sys" });
    libmssys.addIncludePath(.{ .path = "src/ms-sys/inc" });

    // syslinux
    const libfat = b.addStaticLibrary(.{
        .name = "fat",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libfat.addCSourceFiles(.{
        .files = &.{
            "src/syslinux/libfat/cache.c",
            "src/syslinux/libfat/fatchain.c",
            "src/syslinux/libfat/open.c",
            "src/syslinux/libfat/searchdir.c",
            "src/syslinux/libfat/dumpdir.c",
        },
        .flags = cflags.items,
    });
    libfat.addIncludePath(.{ .path = "src/syslinux/libfat" });

    const libinstaller = b.addStaticLibrary(.{
        .name = "installer",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libinstaller.addCSourceFiles(.{
        .files = &.{
            "src/syslinux/libinstaller/fs.c",
            "src/syslinux/libinstaller/setadv.c",
            "src/syslinux/libinstaller/syslxmod.c",
        },
        .flags = cflags.items,
    });
    libinstaller.addIncludePath(.{ .path = "src/syslinux/libinstaller" });

    const libwin = b.addStaticLibrary(.{
        .name = "win",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libwin.addCSourceFiles(.{
        .files = &.{
            "src/syslinux/win/ntfssect.c",
        },
        .flags = cflags.items,
    });
    libwin.addIncludePath(.{ .path = "src/syslinux/win" });

    var libgetopt_flags = cflags.clone() catch @panic("OOM");
    libgetopt_flags.append("-DHAVE_STRING_H") catch @panic("OOM");
    const libgetopt = b.addStaticLibrary(.{
        .name = "getopt",
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    libgetopt.addCSourceFiles(.{
        .files = &.{
            "src/getopt/getopt.c",
            "src/getopt/getopt1.c",
        },
        .flags = libgetopt_flags.items,
    });

    // embedded.loc
    // The rufus build when using MinGW has a sed script that attempts to minify
    // the `.loc` by removing comments, etc, but it only removes ~45KiB (3% decrease)
    // so just copying it is fine (AFAICT copying without modification is what the
    // Visual Studio solution for rufus does)
    var copy_loc = b.addWriteFiles();
    copy_loc.addCopyFileToSource(.{ .path = "res/loc/rufus.loc" }, "res/loc/embedded.loc");

    // rufus
    const exe = b.addExecutable(.{
        .name = "rufus",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .win32_manifest = .{ .path = "src/rufus.manifest" },
    });
    exe.step.dependOn(&copy_loc.step);
    exe.addWin32ResourceFile(.{
        .file = .{ .path = "src/rufus.rc" },
        .flags = &.{ "/D_UNICODE", "/DUNICODE" },
    });
    exe.subsystem = .Windows;
    exe.linkLibrary(libbled);
    exe.linkLibrary(libext2fs);
    exe.linkLibrary(libdriver);
    exe.linkLibrary(libiso9660);
    exe.linkLibrary(libudf);
    exe.linkLibrary(libmssys);
    exe.linkLibrary(libfat);
    exe.linkLibrary(libinstaller);
    exe.linkLibrary(libwin);
    if (is_msvc)
        exe.linkLibrary(libgetopt);

    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("comctl32");
    exe.linkSystemLibrary("version");
    exe.linkSystemLibrary("dwmapi");
    exe.linkSystemLibrary("setupapi");
    exe.linkSystemLibrary("ole32");
    exe.linkSystemLibrary("shlwapi");
    exe.linkSystemLibrary("crypt32");
    exe.linkSystemLibrary("uuid");
    exe.linkSystemLibrary("wintrust");
    if (is_msvc) {
        exe.linkSystemLibrary("advapi32");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("dwmapi");
        exe.linkSystemLibrary("shell32");
        exe.linkSystemLibrary("shlwapi");
        exe.linkSystemLibrary("kernel32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("winspool");
        exe.linkSystemLibrary("comdlg32");
        exe.linkSystemLibrary("oleaut32");
        exe.linkSystemLibrary("odbc32");
        exe.linkSystemLibrary("odbccp32");
        // Necessary to avoid 'open', 'write', and 'read' symbols being undefined during linking
        // Typically this is automatically linked but Zig passes /NODEFAULTLIB which disables it from being linked.
        // See https://devblogs.microsoft.com/oldnewthing/20200730-00/?p=104021
        exe.linkSystemLibrary("oldnames");
    }

    var exe_flags = cflags.clone() catch @panic("OOM");
    if (!is_msvc) {
        // HACK: Clang advertises as 4.2.1 by default which the rufus source files reject as too old
        exe_flags.append("-fgnuc-version=5.0.0") catch @panic("OOM");
    }
    exe.addCSourceFiles(.{
        .files = &.{
            "src/badblocks.c",
            "src/cpu.c",
            "src/dev.c",
            "src/dos.c",
            "src/dos_locale.c",
            "src/drive.c",
            "src/format.c",
            "src/format_ext.c",
            "src/format_fat32.c",
            "src/hash.c",
            "src/icon.c",
            "src/iso.c",
            "src/localization.c",
            "src/net.c",
            "src/parser.c",
            "src/pki.c",
            "src/process.c",
            "src/re.c",
            "src/rufus.c",
            "src/smart.c",
            "src/stdfn.c",
            "src/stdio.c",
            "src/stdlg.c",
            "src/stdfn.c",
            "src/syslinux.c",
            "src/ui.c",
            "src/vhd.c",
            "src/wue.c",
        },
        .flags = exe_flags.items,
    });
    exe.addIncludePath(.{ .path = "src" });
    exe.addIncludePath(.{ .path = "src/ms-sys/inc" });
    exe.addIncludePath(.{ .path = "src/syslinux/libfat" });
    exe.addIncludePath(.{ .path = "src/syslinux/libinstaller" });
    exe.addIncludePath(.{ .path = "src/syslinux/win" });
    exe.addIncludePath(.{ .path = "src/libcdio" });
    if (is_msvc) {
        exe.addIncludePath(.{ .path = "src/msvc-missing" });
        exe.addIncludePath(.{ .path = "src/getopt" });
    }

    b.installArtifact(exe);
}
