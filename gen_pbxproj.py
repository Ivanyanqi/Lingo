#!/usr/bin/env python3
"""生成 TranslatorBar.xcodeproj/project.pbxproj"""

import os, uuid, textwrap

def uid():
    return uuid.uuid4().hex[:24].upper()

# ── 固定 UUID ────────────────────────────────────────────────────────────────
PROJECT_UID         = uid()
MAIN_GROUP_UID      = uid()
PRODUCTS_GROUP_UID  = uid()
CORE_GROUP_UID      = uid()
VIEWS_GROUP_UID     = uid()
TESTS_GROUP_UID     = uid()

APP_TARGET_UID      = uid()
TEST_TARGET_UID     = uid()
APP_PRODUCT_UID     = uid()
TEST_PRODUCT_UID    = uid()

APP_SOURCES_PHASE   = uid()
APP_RESOURCES_PHASE = uid()
APP_FRAMEWORKS_PHASE= uid()
TEST_SOURCES_PHASE  = uid()

APP_DEBUG_CONFIG    = uid()
APP_RELEASE_CONFIG  = uid()
TEST_DEBUG_CONFIG   = uid()
TEST_RELEASE_CONFIG = uid()
PROJ_DEBUG_CONFIG   = uid()
PROJ_RELEASE_CONFIG = uid()
APP_CONFIG_LIST     = uid()
TEST_CONFIG_LIST    = uid()
PROJ_CONFIG_LIST    = uid()

# ── 源文件 ───────────────────────────────────────────────────────────────────
app_sources = [
    ("TranslatorBarApp.swift",          uid(), uid()),
    ("Core/TranslationService.swift",   uid(), uid()),
    ("Core/SpeechService.swift",        uid(), uid()),
    ("Core/HotkeyManager.swift",        uid(), uid()),
    ("Core/TranslationViewModel.swift", uid(), uid()),
    ("Views/MenuBarPanelView.swift",    uid(), uid()),
    ("Views/FloatingWindowController.swift", uid(), uid()),
    ("Views/FloatingResultView.swift",  uid(), uid()),
]

test_sources = [
    ("TranslationServiceTests.swift", uid(), uid()),
    ("SpeechServiceTests.swift",      uid(), uid()),
    ("HotkeyManagerTests.swift",      uid(), uid()),
]

INFO_PLIST_UID      = uid()
INFO_PLIST_BUILD    = uid()
ENTITLEMENTS_UID    = uid()
ASSETS_UID          = uid()
ASSETS_BUILD        = uid()

# ── helpers ──────────────────────────────────────────────────────────────────
def file_ref(uid, name, path, source_tree="<group>", file_type=None):
    if file_type is None:
        file_type = "sourcecode.swift" if name.endswith(".swift") else \
                    "text.plist.xml" if name.endswith(".plist") or name.endswith(".entitlements") else \
                    "folder.assetcatalog"
    return f'\t\t{uid} = {{isa = PBXFileReference; lastKnownFileType = {file_type}; name = "{name}"; path = "{path}"; sourceTree = "{source_tree}"; }};'

def build_file(build_uid, file_uid, name):
    return f'\t\t{build_uid} = {{isa = PBXBuildFile; fileRef = {file_uid}; }};'

# ── PBXFileReference section ─────────────────────────────────────────────────
file_refs = []
file_refs.append(f'\t\t{APP_PRODUCT_UID} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TranslatorBar.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
file_refs.append(f'\t\t{TEST_PRODUCT_UID} = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TranslatorBarTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};')
file_refs.append(file_ref(INFO_PLIST_UID, "Info.plist", "TranslatorBar/Info.plist", "<group>", "text.plist.xml"))
file_refs.append(file_ref(ENTITLEMENTS_UID, "TranslatorBar.entitlements", "TranslatorBar/TranslatorBar.entitlements", "<group>", "text.plist.entitlements"))
file_refs.append(f'\t\t{ASSETS_UID} = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "TranslatorBar/Assets.xcassets"; sourceTree = "<group>"; }};')

for name, fuid, buid in app_sources:
    short = name.split("/")[-1]
    file_refs.append(file_ref(fuid, short, f"TranslatorBar/{name}"))

for name, fuid, buid in test_sources:
    file_refs.append(file_ref(fuid, name, f"TranslatorBarTests/{name}"))

# ── PBXBuildFile section ──────────────────────────────────────────────────────
build_files = []
build_files.append(f'\t\t{ASSETS_BUILD} = {{isa = PBXBuildFile; fileRef = {ASSETS_UID}; }};')
for name, fuid, buid in app_sources:
    build_files.append(build_file(buid, fuid, name))
for name, fuid, buid in test_sources:
    build_files.append(build_file(buid, fuid, name))

# ── Groups ────────────────────────────────────────────────────────────────────
core_children = "\n".join(f"\t\t\t\t{fuid}," for name, fuid, _ in app_sources if name.startswith("Core/"))
views_children = "\n".join(f"\t\t\t\t{fuid}," for name, fuid, _ in app_sources if name.startswith("Views/"))
app_root_children = "\n".join(f"\t\t\t\t{fuid}," for name, fuid, _ in app_sources if "/" not in name)
test_children = "\n".join(f"\t\t\t\t{fuid}," for name, fuid, _ in test_sources)

# ── Sources build phases ──────────────────────────────────────────────────────
app_build_files = "\n".join(f"\t\t\t\t{buid}," for _, _, buid in app_sources)
test_build_files = "\n".join(f"\t\t\t\t{buid}," for _, _, buid in test_sources)

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{APP_FRAMEWORKS_PHASE} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{MAIN_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{CORE_GROUP_UID},
\t\t\t\t{VIEWS_GROUP_UID},
{app_root_children}
\t\t\t\t{INFO_PLIST_UID},
\t\t\t\t{ENTITLEMENTS_UID},
\t\t\t\t{ASSETS_UID},
\t\t\t\t{TESTS_GROUP_UID},
\t\t\t\t{PRODUCTS_GROUP_UID},
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{PRODUCTS_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{APP_PRODUCT_UID},
\t\t\t\t{TEST_PRODUCT_UID},
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{CORE_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{core_children}
\t\t\t);
\t\t\tname = Core;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{VIEWS_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{views_children}
\t\t\t);
\t\t\tname = Views;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{TESTS_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{test_children}
\t\t\t);
\t\t\tname = TranslatorBarTests;
\t\t\tpath = TranslatorBarTests;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{APP_TARGET_UID} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {APP_CONFIG_LIST};
\t\t\tbuildPhases = (
\t\t\t\t{APP_SOURCES_PHASE},
\t\t\t\t{APP_FRAMEWORKS_PHASE},
\t\t\t\t{APP_RESOURCES_PHASE},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = TranslatorBar;
\t\t\tproductName = TranslatorBar;
\t\t\tproductReference = {APP_PRODUCT_UID};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{TEST_TARGET_UID} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {TEST_CONFIG_LIST};
\t\t\tbuildPhases = (
\t\t\t\t{TEST_SOURCES_PHASE},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = TranslatorBarTests;
\t\t\tproductName = TranslatorBarTests;
\t\t\tproductReference = {TEST_PRODUCT_UID};
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{PROJECT_UID} = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{APP_TARGET_UID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{TEST_TARGET_UID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {APP_TARGET_UID};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {PROJ_CONFIG_LIST};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {MAIN_GROUP_UID};
\t\t\tproductRefGroup = {PRODUCTS_GROUP_UID};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{APP_TARGET_UID},
\t\t\t\t{TEST_TARGET_UID},
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{APP_RESOURCES_PHASE} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ASSETS_BUILD},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{APP_SOURCES_PHASE} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_build_files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{TEST_SOURCES_PHASE} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{test_build_files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{PROJ_DEBUG_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{PROJ_RELEASE_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{APP_DEBUG_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = TranslatorBar/TranslatorBar.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tDEVELOPMENT_TEAM = W9YMHSGLWM;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tINFOPLIST_FILE = TranslatorBar/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ivanqi.TranslatorBar";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{APP_RELEASE_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = TranslatorBar/TranslatorBar.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tDEVELOPMENT_TEAM = W9YMHSGLWM;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tINFOPLIST_FILE = TranslatorBar/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ivanqi.TranslatorBar";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{TEST_DEBUG_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tDEVELOPMENT_TEAM = W9YMHSGLWM;
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ivanqi.TranslatorBarTests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/TranslatorBar.app/Contents/MacOS/TranslatorBar";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{TEST_RELEASE_CONFIG} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tDEVELOPMENT_TEAM = W9YMHSGLWM;
\t\t\t\tMACOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ivanqi.TranslatorBarTests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/TranslatorBar.app/Contents/MacOS/TranslatorBar";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{PROJ_CONFIG_LIST} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{PROJ_DEBUG_CONFIG},
\t\t\t\t{PROJ_RELEASE_CONFIG},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{APP_CONFIG_LIST} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{APP_DEBUG_CONFIG},
\t\t\t\t{APP_RELEASE_CONFIG},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{TEST_CONFIG_LIST} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{TEST_DEBUG_CONFIG},
\t\t\t\t{TEST_RELEASE_CONFIG},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {PROJECT_UID};
}}
"""

out = "/Users/yanqi/Documents/onlyspace/TranslatorBar/TranslatorBar.xcodeproj/project.pbxproj"
with open(out, "w") as f:
    f.write(pbxproj)
print(f"✅ 生成 {out}")
