kernelsu-objs := ksu.o
kernelsu-objs += allowlist.o
kernelsu-objs += apk_sign.o
kernelsu-objs += sucompat.o
kernelsu-objs += throne_tracker.o
kernelsu-objs += core_hook.o
kernelsu-objs += ksud.o
kernelsu-objs += embed_ksud.o
kernelsu-objs += kernel_compat.o

kernelsu-objs += selinux/selinux.o
kernelsu-objs += selinux/sepolicy.o
kernelsu-objs += selinux/rules.o

ccflags-y += -I$(srctree)/security/selinux -I$(srctree)/security/selinux/include
ccflags-y += -I$(objtree)/security/selinux -include $(srctree)/include/uapi/asm-generic/errno.h

ccflags-y += -Wno-implicit-function-declaration -Wno-strict-prototypes -Wno-int-conversion
ccflags-y += -Wno-declaration-after-statement -Wno-unused-function

obj-$(CONFIG_KSU) += kernelsu.o


# https://github.com/tiann/KernelSU/pull/2102/files#diff-3a325663233178293ee38b8161f3be511a466af7e0156b9d03d5aed0497564bfR19
IS_GKI := $(strip $(shell \
    if [ "$(VERSION)" -ge "5" -a "$(PATCHLEVEL)" -ge "10" ]; then \
      echo TRUE; \
    else \
      echo FALSE; \
    fi \
  ))

ifeq ($(IS_GKI),TRUE)
$(info -- KernelSU: Kernel version is GKI.)
# GKI manual hook checks
# https://github.com/Pzqqt/android_kernel_xiaomi_marble/commit/5b8596b5604bcd0e6e12697a01136a0bb9eb0257
ifeq ($(strip $(CONFIG_KSU_MANUAL_HOOK)),y)
$(info -- KernelSU: Hooks with Manual hook!)
ifeq ($(strip $(CONFIG_KSU)),m)
$(error CONFIG_KSU_MANUAL_HOOK cannot be enabled when compiling KernelSU as LKM!)
endif
else
ccflags-y += -DKSU_HOOK_WITH_KPROBES
endif
endif

KSU_MANUAL_VERSION := 12145

ifeq ($(strip $(KSU_MANUAL_VERSION)),)
    ifeq ($(shell test -e $(srctree)/$(src)/../.git; echo $$?),0)
        $(shell cd $(srctree)/$(src); /usr/bin/env PATH="$$PATH":/usr/bin:/usr/local/bin [ -f ../.git/shallow ] && git fetch --unshallow)
        KSU_GIT_VERSION := $(shell cd $(srctree)/$(src); /usr/bin/env PATH="$$PATH":/usr/bin:/usr/local/bin git rev-list --count HEAD)
        # ksu_version: major * 10000 + git version + 500 for historical reasons
        $(eval KSU_VERSION=$(shell expr 12000 + $(KSU_GIT_VERSION) + 500))
        $(info -- KernelSU version (Git-based): $(KSU_VERSION))
        ccflags-y += -DKSU_VERSION=$(KSU_VERSION)
    else
        # .git is a text file while the module is imported by 'git submodule add'.
        $(warning "KSU_GIT_VERSION not defined! Using default version.")
        KSU_VERSION := 12135
        $(info -- KernelSU version (Default): $(KSU_VERSION))
        ccflags-y += -DKSU_VERSION=$(KSU_VERSION)
    endif
else
    KSU_VERSION := $(KSU_MANUAL_VERSION)
    $(info -- KernelSU version (Manual): $(KSU_VERSION))
    ccflags-y += -DKSU_VERSION=$(KSU_VERSION)
endif

ifndef KSU_EXPECTED_SIZE
KSU_EXPECTED_SIZE := 384
endif

ifndef KSU_EXPECTED_HASH
KSU_EXPECTED_HASH := 7e0c6d7278a3bb8e364e0fcba95afaf3666cf5ff3c245a3b63c8833bd0445cc4
endif

ifdef KSU_MANAGER_PACKAGE
ccflags-y += -DKSU_MANAGER_PACKAGE=\"$(KSU_MANAGER_PACKAGE)\"
$(info -- KernelSU Manager package name: $(KSU_MANAGER_PACKAGE))
endif

$(info -- KernelSU Manager signature size: $(KSU_EXPECTED_SIZE))
$(info -- KernelSU Manager signature hash: $(KSU_EXPECTED_HASH))
$(info -- Supported Unofficial Manager: 5ec1cff (GKI and non-GKI and KPM)) 
KERNEL_VERSION := $(VERSION).$(PATCHLEVEL)

# 检查原子函数
ifeq ($(shell grep -q "atomic_inc_not_zero" $(srctree)/kernel/cred.c; echo $$?),0)
ATOMIC_INC_FUNC = atomic_inc_not_zero
else ifeq ($(shell grep -q "atomic_long_inc_not_zero" $(srctree)/kernel/cred.c; echo $$?),0)
ATOMIC_INC_FUNC = atomic_long_inc_not_zero
else
$(info -- KernelSU compat: Neither atomic_inc_not_zero nor atomic_long_inc_not_zero found in kernel/cred.c)
endif

# Inform which function is being patched
$(info -- KernelSU compat: Using $(ATOMIC_INC_FUNC) in get_cred_rcu patch.)

# 写入签名
ccflags-y += -DEXPECTED_SIZE=$(KSU_EXPECTED_SIZE)
ccflags-y += -DEXPECTED_HASH=\"$(KSU_EXPECTED_HASH)\"

# SELinux 驱动程序检查
ifeq ($(shell grep -q "current_sid(void)" $(srctree)/security/selinux/include/objsec.h; echo $$?),0)
ccflags-y += -DKSU_COMPAT_HAS_CURRENT_SID
endif

ifeq ($(shell grep -q "struct selinux_state " $(srctree)/security/selinux/include/security.h; echo $$?),0)
ccflags-y += -DKSU_COMPAT_HAS_SELINUX_STATE
endif

# 该功能在 linux 5.0-rc1 中引入
ifeq ($(shell grep -q "get_cred_rcu" $(srctree)/include/linux/cred.h; echo $$?),0)
ccflags-y += -DKSU_COMPAT_HAS_GET_CRED_RCU
else
ifeq ($(shell grep -q "atomic_long_t\s\+\usage" $(srctree)/include/linux/cred.h; echo $$?),0)
ccflags-y += -DKSU_COMPAT_ATOMIC_LONG
endif
ifeq ($(shell grep -q "int\s\+\non_rcu" $(srctree)/include/linux/cred.h; echo $$?),0)
ccflags-y += -DKSU_COMPAT_HAS_NONCONST_CRED
endif
endif

# 处理可选的backport
ifeq ($(shell grep -q "strncpy_from_user_nofault" $(srctree)/include/linux/uaccess.h; echo $$?),0)
ccflags-y += -DKSU_STRNCPY_FROM_USER_NOFAULT
endif

ifeq ($(shell grep -q "ssize_t kernel_read" $(srctree)/fs/read_write.c; echo $$?),0)
ccflags-y += -DKSU_KERNEL_READ
endif

ifeq ($(shell grep "ssize_t kernel_write" $(srctree)/fs/read_write.c | grep -q "const void" ; echo $$?),0)
ccflags-y += -DKSU_KERNEL_WRITE
endif

# 检查三星 UH 驱动程序
ifeq ($(shell grep -q "CONFIG_KDP_CRED" $(srctree)/kernel/cred.c; echo $$?),0)
ccflags-y += -DSAMSUNG_UH_DRIVER_EXIST
endif

ccflags-y += -DKSU_UMOUNT
ccflags-y += -DKSU_COMPAT_GET_CRED_RCU

# Add the get_cred_rcu function to cred.h if not already present
ifneq ($(shell grep -Eq "^static inline const struct cred \*get_cred_rcu" $(srctree)/include/linux/cred.h; echo $$?),0)
$(info -- KernelSU compat: adding function 'static inline const struct cred *get_cred_rcu(const struct cred *cred);' to $(srctree)/include/linux/cred.h)
GET_CRED_RCU = static inline const struct cred *get_cred_rcu(const struct cred *cred)\n\
{\n\t\
        struct cred *nonconst_cred = (struct cred *) cred;\n\t\
        if (!cred)\n\t\t\
                return NULL;\n\t\
        if (!$(ATOMIC_INC_FUNC)(&nonconst_cred->usage))\n\t\t\
                return NULL;\n\t\
        validate_creds(cred);\n\t\
        return cred;\n\
}\n
$(shell grep -qF "$(GET_CRED_RCU)" $(srctree)/include/linux/cred.h || sed -i '/^static inline void put_cred/i $(GET_CRED_RCU)' $(srctree)/include/linux/cred.h)

# Modify get_task_cred in cred.c
$(info -- KernelSU compat: modifying 'get_task_cred' function in $(srctree)/kernel/cred.c)
$(shell sed -i "s/!$(ATOMIC_INC_FUNC)(&((struct cred \*)cred)->usage)/!get_cred_rcu(cred)/g" $(srctree)/kernel/cred.c)
endif

ifneq ($(shell grep -Eq "^static int can_umount" $(srctree)/fs/namespace.c; echo $$?),0)
$(info -- KernelSU compat: adding function 'static int can_umount(const struct path *path, int flags);' to $(srctree)/fs/namespace.c)
CAN_UMOUNT = static int can_umount(const struct path *path, int flags)\n\
{\n\t\
        struct mount *mnt = real_mount(path->mnt);\n\t\
        if (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\t\
                return -EINVAL;\n\t\
        if (!may_mount())\n\t\t\
                return -EPERM;\n\t\
        if (path->dentry != path->mnt->mnt_root)\n\t\t\
                return -EINVAL;\n\t\
        if (!check_mnt(mnt))\n\t\t\
                return -EINVAL;\n\t\
        if (mnt->mnt.mnt_flags & MNT_LOCKED)\n\t\t\
                return -EINVAL;\n\t\
        if (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\t\
                return -EPERM;\n\t\
        return 0;\n\
}\n
$(shell sed -i '/^static bool is_mnt_ns_file/i $(CAN_UMOUNT)' $(srctree)/fs/namespace.c;)
endif

ifneq ($(shell grep -Eq "^int path_umount" $(srctree)/fs/namespace.c; echo $$?),0)
$(info -- KernelSU compat: adding function 'int path_umount(struct path *path, int flags);' to $(srctree)/fs/namespace.c)
PATH_UMOUNT = int path_umount(struct path *path, int flags)\n\
{\n\t\
        struct mount *mnt = real_mount(path->mnt);\n\t\
        int ret;\n\t\
        ret = can_umount(path, flags);\n\t\
        if (!ret)\n\t\t\
                ret = do_umount(mnt, flags);\n\t\
        dput(path->dentry);\n\t\
        mntput_no_expire(mnt);\n\t\
        return ret;\n\
}\n
$(shell sed -i '/^static bool is_mnt_ns_file/i $(PATH_UMOUNT)' $(srctree)/fs/namespace.c;)
endif

ifneq ($(shell grep -Eq "^int path_umount" $(srctree)/fs/internal.h; echo $$?),0)
$(shell sed -i '/^extern void __init mnt_init/a int path_umount(struct path *path, int flags);' $(srctree)/fs/internal.h;)
$(info -- KernelSU compat: adding 'int path_umount(struct path *path, int flags);' to $(srctree)/fs/internal.h)
endif

# Do checks before compile
ifeq ($(shell grep -q "int\s\+\path_umount" $(srctree)/fs/namespace.c; echo $$?),0)
$(info -- KernelSU: checks ok. Found path_umount)
else
$(info -- KernelSU: checks failed, abort.)
$(error -- Backporting path_umount is mandatory !! Read: https://kernelsu.org/guide/how-to-integrate-for-non-gki.html#how-to-backport-path-umount)
endif


## For susfs stuff ##
ifeq ($(shell test -e $(srctree)/fs/susfs.c; echo $$?),0)
$(eval SUSFS_VERSION=$(shell cat $(srctree)/include/linux/susfs.h | grep -E '^#define SUSFS_VERSION' | cut -d' ' -f3 | sed 's/"//g'))
$(info )
$(info -- SUSFS_VERSION: $(SUSFS_VERSION))
else
$(info -- You have not integrate susfs in your kernel.)
$(info -- Read: https://gitlab.com/simonpunk/susfs4ksu)
endif
# Keep a new line here!! Because someone may append config
