sed -i '/static void do_stop_input_hook/a #endif' ./kernel/ksud.c
sed -i '/static void stop_vfs_read_hook/a #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/static void stop_vfs_read_hook/i #else\nksu_vfs_read_hook = false;\npr_info("stop vfs_read_hook\\n");\n#endif' ./kernel/ksud.c
sed -i '/static void stop_execve_hook/a #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/static void stop_execve_hook/i #endif' ./kernel/ksud.c
sed -i '/static void stop_input_hook/a #endif' ./kernel/ksud.c
sed -i '/static void stop_input_hook/i #else\nksu_input_hook = false;\npr_info("stop input_hook\\n");\n#endif' ./kernel/ksud.c
sed -i 's/void ksu_ksud_init()/int ksu_ksud_init()/' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&execve_kp)/i #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&execve_kp)/a #endif' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&vfs_read_kp)/i #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&vfs_read_kp)/a #endif' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&input_event_kp)/i #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/ret = register_kprobe(&input_event_kp)/a #endif' ./kernel/ksud.c
sed -i '/pr_info("ksud: input_event_kp: %d\\n", ret);/a return 0;' ./kernel/ksud.c
sed -i '/pr_info("ksud: input_event_kp: %d\\n", ret);/i pr_info("ksud: input_event_kp registered\\n");' ./kernel/ksud.c
sed -i '/pr_info("ksud: vfs_read_kp: %d\\n", ret);/i pr_info("ksud: vfs_read_kp registered\\n");' ./kernel/ksud.c
sed -i '/pr_info("ksud: execve_kp: %d\\n", ret);/i pr_info("ksud: execve_kp registered\\n");' ./kernel/ksud.c
sed -i '/void ksu_ksud_exit()/i #ifdef CONFIG_KPROBES' ./kernel/ksud.c
sed -i '/void ksu_ksud_exit()/a #endif' ./kernel/ksud.c
sed -i '/is_boot_phase = false;/a volumedown_pressed_count = 0;' ./kernel/ksud.c
sed -i '/is_boot_phase = false;/a #if LINUX_VERSION_CODE < KERNEL_VERSION(5, 10, 0)\nflush_scheduled_work();\n#else\ncancel_work_sync(&stop_vfs_read_work);\ncancel_work_sync(&stop_execve_hook_work);\ncancel_work_sync(&stop_input_hook_work);\n#endif' ./kernel/ksud.c
sed -i '/is_boot_phase = false;/a pr_info("ksud: module unloaded\\n");' ./kernel/ksud.c
