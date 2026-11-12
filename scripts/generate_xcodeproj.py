#!/usr/bin/env python3
"""Generate a deterministic Xcode project for DevPreview.

The generated project is checked in, so users do not need this script to build.
It exists to keep the project reproducible when files are added or removed.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PROJECT_DIR = ROOT / "DevPreview.xcodeproj"
PBXPROJ_PATH = PROJECT_DIR / "project.pbxproj"
SCHEME_PATH = PROJECT_DIR / "xcshareddata" / "xcschemes" / "DevPreview.xcscheme"

APP_BUNDLE_ID = "com.zhangzheng.DevPreview"
EXTENSION_BUNDLE_ID = "com.zhangzheng.DevPreview.Extension"


class Raw(str):
    pass


def oid(key: str) -> str:
    return hashlib.md5(key.encode("utf-8")).hexdigest().upper()[:24]


def quote(value: str) -> str:
    if (
        value
        and re.fullmatch(r"[A-Za-z0-9_./\-]+", value)
        and not value.startswith("-")
        and "$" not in value
    ):
        return value
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def ref(key: str, comment: str | None = None) -> Raw:
    value = oid(key)
    if comment:
        return Raw(f"{value} /* {comment} */")
    return Raw(value)


def value_text(value, indent: int) -> str:
    if isinstance(value, Raw):
        return str(value)
    if isinstance(value, bool):
        return "YES" if value else "NO"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return quote(value)
    if isinstance(value, list):
        if not value:
            return "()"
        return "(" + ", ".join(value_text(item, indent) for item in value) + ")"
    if isinstance(value, dict):
        lines = ["{"]
        for key, item in value.items():
            lines.append(
                "\t" * (indent + 1) + f"{key} = {value_text(item, indent + 1)};"
            )
        lines.append("\t" * indent + "}")
        return "\n".join(lines)
    raise TypeError(f"Unsupported value: {value!r}")


def object_text(identifier: str, isa: str, fields: dict, comment: str | None = None) -> str:
    header = f"\t\t{identifier}"
    if comment:
        header += f" /* {comment} */"
    lines = [header + " = {", f"\t\t\tisa = {isa};"]
    for key, value in fields.items():
        rendered = value_text(value, 3)
        if "\n" in rendered:
            lines.append(f"\t\t\t{key} = {rendered};")
        else:
            lines.append(f"\t\t\t{key} = {rendered};")
    lines.append("\t\t};")
    return "\n".join(lines)


FILE_DEFS = {
    "App/DevPreviewApp.swift": ("DevPreviewApp.swift", "sourcecode.swift", "App"),
    "App/ContentView.swift": ("ContentView.swift", "sourcecode.swift", "App"),
    "App/ExtensionStatusModel.swift": ("ExtensionStatusModel.swift", "sourcecode.swift", "App"),
    "App/SampleCode.swift": ("SampleCode.swift", "sourcecode.swift", "App"),
    "App/Resources/AppIcon.icns": ("AppIcon.icns", "image.icns", "App/Resources"),
    "App/Info.plist": ("Info.plist", "text.plist.xml", "App"),
    "Shared/SupportedFormats.swift": ("SupportedFormats.swift", "sourcecode.swift", "Shared"),
    "Shared/ArchiveFormats.swift": ("ArchiveFormats.swift", "sourcecode.swift", "Shared"),
    "Extension/PreviewViewController.swift": ("PreviewViewController.swift", "sourcecode.swift", "Extension"),
    "Extension/CodePreviewView.swift": ("CodePreviewView.swift", "sourcecode.swift", "Extension"),
    "Extension/PreviewChromeViews.swift": ("PreviewChromeViews.swift", "sourcecode.swift", "Extension"),
    "Extension/LineNumberRulerView.swift": ("LineNumberRulerView.swift", "sourcecode.swift", "Extension"),
    "Extension/DocumentLoader.swift": ("DocumentLoader.swift", "sourcecode.swift", "Extension"),
    "Extension/SyntaxHighlighter.swift": ("SyntaxHighlighter.swift", "sourcecode.swift", "Extension"),
    "Extension/LanguageProfile.swift": ("LanguageProfile.swift", "sourcecode.swift", "Extension"),
    "Extension/LanguageProfiles.swift": ("LanguageProfiles.swift", "sourcecode.swift", "Extension"),
    "Extension/LanguageCatalog.swift": ("LanguageCatalog.swift", "sourcecode.swift", "Extension"),
    "Extension/StructureModels.swift": ("StructureModels.swift", "sourcecode.swift", "Extension"),
    "Extension/ArchiveReader.swift": ("ArchiveReader.swift", "sourcecode.swift", "Extension"),
    "Extension/SQLiteReader.swift": ("SQLiteReader.swift", "sourcecode.swift", "Extension"),
    "Extension/StructurePreviewView.swift": ("StructurePreviewView.swift", "sourcecode.swift", "Extension"),
    "Extension/Info.plist": ("Info.plist", "text.plist.xml", "Extension"),
    "Extension/DevPreviewExtension.entitlements": (
        "DevPreviewExtension.entitlements",
        "text.plist.entitlements",
        "Extension",
    ),
    "Examples/sample.swift": ("sample.swift", "sourcecode.swift", "Examples"),
    "Examples/sample.py": ("sample.py", "text.script.python", "Examples"),
    "Examples/sample.go": ("sample.go", "sourcecode.go", "Examples"),
    "Examples/sample.json": ("sample.json", "text.json", "Examples"),
    "Examples/sample.yaml": ("sample.yaml", "text", "Examples"),
    "Examples/sample.md": ("sample.md", "net.daringfireball.markdown", "Examples"),
    "Examples/sample.diff": ("sample.diff", "text", "Examples"),
    "Examples/sample.toml": ("sample.toml", "text", "Examples"),
    "Examples/sample.dockerfile": ("sample.dockerfile", "text", "Examples"),
    "README.md": ("README.md", "net.daringfireball.markdown", "root"),
    "Makefile": ("Makefile", "text", "root"),
    "scripts/build.sh": ("build.sh", "text.script.sh", "scripts"),
    "scripts/install.sh": ("install.sh", "text.script.sh", "scripts"),
    "scripts/uninstall.sh": ("uninstall.sh", "text.script.sh", "scripts"),
    "scripts/generate_icon.py": ("generate_icon.py", "text.script.python", "scripts"),
    "scripts/generate_xcodeproj.py": (
        "generate_xcodeproj.py",
        "text.script.python",
        "scripts",
    ),
}

APP_SOURCES = [
    "App/DevPreviewApp.swift",
    "App/ContentView.swift",
    "App/ExtensionStatusModel.swift",
    "App/SampleCode.swift",
    "Shared/SupportedFormats.swift",
    "Shared/ArchiveFormats.swift",
]

EXTENSION_SOURCES = [
    "Extension/PreviewViewController.swift",
    "Extension/CodePreviewView.swift",
    "Extension/PreviewChromeViews.swift",
    "Extension/LineNumberRulerView.swift",
    "Extension/DocumentLoader.swift",
    "Extension/SyntaxHighlighter.swift",
    "Extension/LanguageProfile.swift",
    "Extension/LanguageProfiles.swift",
    "Extension/LanguageCatalog.swift",
    "Extension/StructureModels.swift",
    "Extension/ArchiveReader.swift",
    "Extension/SQLiteReader.swift",
    "Extension/StructurePreviewView.swift",
    "Shared/SupportedFormats.swift",
    "Shared/ArchiveFormats.swift",
]

GROUP_DEFS = {
    "root": ("", "Root", None),
    "App": ("App", "App", "App"),
    "App/Resources": ("Resources", "Resources", "App"),
    "Shared": ("Shared", "Shared", "Shared"),
    "Extension": ("Extension", "Extension", "Extension"),
    "Examples": ("Examples", "Examples", "Examples"),
    "scripts": ("scripts", "Scripts", "scripts"),
    "Products": ("", "Products", None),
    "Frameworks": ("", "Frameworks", None),
}


def generate() -> tuple[str, str]:
    project_id = oid("project:DevPreview")
    app_target_id = oid("target:DevPreview")
    extension_target_id = oid("target:DevPreviewExtension")
    project_config_list_id = oid("config-list:project")
    app_config_list_id = oid("config-list:DevPreview")
    extension_config_list_id = oid("config-list:DevPreviewExtension")

    app_product_id = oid("product:DevPreview.app")
    extension_product_id = oid("product:DevPreviewExtension.appex")

    sections: dict[str, list[str]] = {
        "PBXBuildFile": [],
        "PBXContainerItemProxy": [],
        "PBXCopyFilesBuildPhase": [],
        "PBXFileReference": [],
        "PBXFrameworksBuildPhase": [],
        "PBXGroup": [],
        "PBXNativeTarget": [],
        "PBXProject": [],
        "PBXResourcesBuildPhase": [],
        "PBXSourcesBuildPhase": [],
        "PBXTargetDependency": [],
        "XCBuildConfiguration": [],
        "XCConfigurationList": [],
    }

    file_ids: dict[str, str] = {}
    build_file_ids: dict[tuple[str, str], str] = {}

    for path, (filename, file_type, _group) in FILE_DEFS.items():
        file_key = f"file:{path}"
        file_id = oid(file_key)
        file_ids[path] = file_id
        sections["PBXFileReference"].append(
            object_text(
                file_id,
                "PBXFileReference",
                {
                    "lastKnownFileType": file_type,
                    "path": filename,
                    "sourceTree": Raw('"<group>"'),
                },
                filename,
            )
        )

    sections["PBXFileReference"].append(
        object_text(
            app_product_id,
            "PBXFileReference",
            {
                "explicitFileType": "wrapper.application",
                "includeInIndex": 0,
                "path": "DevPreview.app",
                "sourceTree": "BUILT_PRODUCTS_DIR",
            },
            "DevPreview.app",
        )
    )
    sections["PBXFileReference"].append(
        object_text(
            extension_product_id,
            "PBXFileReference",
            {
                "explicitFileType": "wrapper.app-extension",
                "includeInIndex": 0,
                "path": "DevPreviewExtension.appex",
                "sourceTree": "BUILT_PRODUCTS_DIR",
            },
            "DevPreviewExtension.appex",
        )
    )

    app_sources_phase_id = oid("phase:app-sources")
    app_frameworks_phase_id = oid("phase:app-frameworks")
    app_resources_phase_id = oid("phase:app-resources")
    app_embed_phase_id = oid("phase:app-embed")
    extension_sources_phase_id = oid("phase:extension-sources")
    extension_frameworks_phase_id = oid("phase:extension-frameworks")
    extension_resources_phase_id = oid("phase:extension-resources")

    def add_build_file(source_path: str, target: str, phase_name: str) -> Raw:
        key = (source_path, target)
        build_id = oid(f"build:{source_path}:{target}")
        build_file_ids[key] = build_id
        sections["PBXBuildFile"].append(
            object_text(
                build_id,
                "PBXBuildFile",
                {"fileRef": ref(f"file:{source_path}", Path(source_path).name)},
                f"{Path(source_path).name} in {phase_name}",
            )
        )
        return Raw(f"{build_id} /* {Path(source_path).name} in {phase_name} */")

    app_source_refs = [
        add_build_file(path, "DevPreview", "Sources") for path in APP_SOURCES
    ]
    extension_source_refs = [
        add_build_file(path, "DevPreviewExtension", "Sources")
        for path in EXTENSION_SOURCES
    ]
    app_icon_build_ref = add_build_file(
        "App/Resources/AppIcon.icns", "DevPreview", "Resources"
    )

    extension_embed_build_id = oid("build:embed-extension")
    sections["PBXBuildFile"].append(
        object_text(
            extension_embed_build_id,
            "PBXBuildFile",
            {
                "fileRef": ref(
                    "product:DevPreviewExtension.appex",
                    "DevPreviewExtension.appex",
                ),
                "settings": {
                    "ATTRIBUTES": Raw("(CodeSignOnCopy, RemoveHeadersOnCopy)"),
                },
            },
            "DevPreviewExtension.appex in Embed App Extensions",
        )
    )

    sections["PBXSourcesBuildPhase"].append(
        object_text(
            app_sources_phase_id,
            "PBXSourcesBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": app_source_refs,
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Sources",
        )
    )
    sections["PBXFrameworksBuildPhase"].append(
        object_text(
            app_frameworks_phase_id,
            "PBXFrameworksBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": [],
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Frameworks",
        )
    )
    sections["PBXResourcesBuildPhase"].append(
        object_text(
            app_resources_phase_id,
            "PBXResourcesBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": [app_icon_build_ref],
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Resources",
        )
    )
    sections["PBXCopyFilesBuildPhase"].append(
        object_text(
            app_embed_phase_id,
            "PBXCopyFilesBuildPhase",
            {
                "buildActionMask": 2147483647,
                "dstPath": "",
                "dstSubfolderSpec": 13,
                "files": [
                    Raw(
                        f"{extension_embed_build_id} /* DevPreviewExtension.appex in Embed App Extensions */"
                    )
                ],
                "name": "Embed App Extensions",
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Embed App Extensions",
        )
    )

    sections["PBXSourcesBuildPhase"].append(
        object_text(
            extension_sources_phase_id,
            "PBXSourcesBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": extension_source_refs,
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Sources",
        )
    )
    sections["PBXFrameworksBuildPhase"].append(
        object_text(
            extension_frameworks_phase_id,
            "PBXFrameworksBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": [],
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Frameworks",
        )
    )
    sections["PBXResourcesBuildPhase"].append(
        object_text(
            extension_resources_phase_id,
            "PBXResourcesBuildPhase",
            {
                "buildActionMask": 2147483647,
                "files": [],
                "runOnlyForDeploymentPostprocessing": 0,
            },
            "Resources",
        )
    )

    target_dependency_id = oid("dependency:extension")
    container_proxy_id = oid("proxy:extension")
    sections["PBXContainerItemProxy"].append(
        object_text(
            container_proxy_id,
            "PBXContainerItemProxy",
            {
                "containerPortal": ref("project:DevPreview", "Project object"),
                "proxyType": 1,
                "remoteGlobalIDString": ref("target:DevPreviewExtension", "DevPreviewExtension"),
                "remoteInfo": "DevPreviewExtension",
            },
        )
    )
    sections["PBXTargetDependency"].append(
        object_text(
            target_dependency_id,
            "PBXTargetDependency",
            {
                "target": ref("target:DevPreviewExtension", "DevPreviewExtension"),
                "targetProxy": ref("proxy:extension", "PBXContainerItemProxy"),
            },
        )
    )

    app_target_ref = ref("target:DevPreview", "DevPreview")
    extension_target_ref = ref("target:DevPreviewExtension", "DevPreviewExtension")
    sections["PBXNativeTarget"].append(
        object_text(
            app_target_id,
            "PBXNativeTarget",
            {
                "buildConfigurationList": ref(
                    "config-list:DevPreview", "Build configuration list for PBXNativeTarget \"DevPreview\""
                ),
                "buildPhases": [
                    ref("phase:app-sources", "Sources"),
                    ref("phase:app-frameworks", "Frameworks"),
                    ref("phase:app-resources", "Resources"),
                    ref("phase:app-embed", "Embed App Extensions"),
                ],
                "buildRules": [],
                "dependencies": [ref("dependency:extension", "PBXTargetDependency")],
                "name": "DevPreview",
                "productName": "DevPreview",
                "productReference": ref("product:DevPreview.app", "DevPreview.app"),
                "productType": "com.apple.product-type.application",
            },
            "DevPreview",
        )
    )
    sections["PBXNativeTarget"].append(
        object_text(
            extension_target_id,
            "PBXNativeTarget",
            {
                "buildConfigurationList": ref(
                    "config-list:DevPreviewExtension",
                    "Build configuration list for PBXNativeTarget \"DevPreviewExtension\"",
                ),
                "buildPhases": [
                    ref("phase:extension-sources", "Sources"),
                    ref("phase:extension-frameworks", "Frameworks"),
                    ref("phase:extension-resources", "Resources"),
                ],
                "buildRules": [],
                "dependencies": [],
                "name": "DevPreviewExtension",
                "productName": "DevPreviewExtension",
                "productReference": ref(
                    "product:DevPreviewExtension.appex",
                    "DevPreviewExtension.appex",
                ),
                "productType": "com.apple.product-type.app-extension",
            },
            "DevPreviewExtension",
        )
    )

    group_children: dict[str, list[Raw]] = {key: [] for key in GROUP_DEFS}
    for path, (_filename, _file_type, group) in FILE_DEFS.items():
        group_children[group].append(
            ref(f"file:{path}", Path(path).name)
        )

    group_children["App"].insert(
        len(group_children["App"]) - 2,
        ref("group:App/Resources", "Resources"),
    )
    group_children["root"].extend(
        [
            ref("group:App", "App"),
            ref("group:Shared", "Shared"),
            ref("group:Extension", "Extension"),
            ref("group:Examples", "Examples"),
            ref("group:scripts", "Scripts"),
            ref("group:Products", "Products"),
            ref("group:Frameworks", "Frameworks"),
        ]
    )
    group_children["Products"].extend(
        [
            ref("product:DevPreview.app", "DevPreview.app"),
            ref("product:DevPreviewExtension.appex", "DevPreviewExtension.appex"),
        ]
    )

    for group_key, (path, name, parent) in GROUP_DEFS.items():
        fields: dict = {"children": group_children[group_key]}
        if path:
            fields["path"] = path
        if name:
            fields["name"] = name
        fields["sourceTree"] = Raw('"<group>"')
        sections["PBXGroup"].append(
            object_text(
                oid(f"group:{group_key}"),
                "PBXGroup",
                fields,
                name if group_key != "root" else "Main group",
            )
        )

    project_debug_id = oid("config:project:Debug")
    project_release_id = oid("config:project:Release")
    app_debug_id = oid("config:app:Debug")
    app_release_id = oid("config:app:Release")
    extension_debug_id = oid("config:extension:Debug")
    extension_release_id = oid("config:extension:Release")

    project_common = {
        "ALWAYS_SEARCH_USER_PATHS": False,
        "CLANG_ANALYZER_NONNULL": True,
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": True,
        "CLANG_ENABLE_OBJC_ARC": True,
        "CLANG_ENABLE_OBJC_WEAK": True,
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": True,
        "CLANG_WARN_BOOL_CONVERSION": True,
        "CLANG_WARN_COMMA": True,
        "CLANG_WARN_CONSTANT_CONVERSION": True,
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": True,
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": True,
        "CLANG_WARN_EMPTY_BODY": True,
        "CLANG_WARN_ENUM_CONVERSION": True,
        "CLANG_WARN_INFINITE_RECURSION": True,
        "CLANG_WARN_INT_CONVERSION": True,
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": True,
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": True,
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": True,
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": True,
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": True,
        "CLANG_WARN_STRICT_PROTOTYPES": True,
        "CLANG_WARN_SUSPICIOUS_MOVE": True,
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": True,
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": True,
        "COPY_PHASE_STRIP": False,
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": True,
        "MACOSX_DEPLOYMENT_TARGET": "13.0",
        "SDKROOT": "macosx",
        "SWIFT_VERSION": "5.0",
    }

    project_debug_settings = dict(project_common)
    project_debug_settings.update(
        {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_STRICT_OBJC_MSGSEND": True,
            "ENABLE_TESTABILITY": True,
            "GCC_OPTIMIZATION_LEVEL": 0,
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "ONLY_ACTIVE_ARCH": True,
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        }
    )
    project_release_settings = dict(project_common)
    project_release_settings.update(
        {
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "ENABLE_NS_ASSERTIONS": False,
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        }
    )

    app_settings = {
        "CODE_SIGN_IDENTITY": "-",
        "CODE_SIGN_STYLE": "Manual",
        "COMBINE_HIDPI_IMAGES": True,
        "CURRENT_PROJECT_VERSION": 2,
        "DEVELOPMENT_TEAM": "",
        "ENABLE_APP_SANDBOX": False,
        "ENABLE_HARDENED_RUNTIME": True,
        "GENERATE_INFOPLIST_FILE": False,
        "INFOPLIST_FILE": "App/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": [
            "$(inherited)",
            "@executable_path/../Frameworks",
        ],
        "MARKETING_VERSION": "1.0.1",
        "PRODUCT_BUNDLE_IDENTIFIER": APP_BUNDLE_ID,
        "PRODUCT_MODULE_NAME": "DevPreview",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_STRICT_CONCURRENCY": "minimal",
        "SWIFT_VERSION": "5.0",
    }

    extension_settings = {
        "APPLICATION_EXTENSION_API_ONLY": True,
        "CODE_SIGN_ENTITLEMENTS": "Extension/DevPreviewExtension.entitlements",
        "CODE_SIGN_IDENTITY": "-",
        "CODE_SIGN_STYLE": "Manual",
        "COMBINE_HIDPI_IMAGES": True,
        "CURRENT_PROJECT_VERSION": 2,
        "DEVELOPMENT_TEAM": "",
        "ENABLE_APP_SANDBOX": True,
        "ENABLE_HARDENED_RUNTIME": True,
        "GENERATE_INFOPLIST_FILE": False,
        "INFOPLIST_FILE": "Extension/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": [
            "$(inherited)",
            "@executable_path/../Frameworks",
            "@executable_path/../../../../Frameworks",
        ],
        "MARKETING_VERSION": "1.0.1",
        "PRODUCT_BUNDLE_IDENTIFIER": EXTENSION_BUNDLE_ID,
        "PRODUCT_MODULE_NAME": "DevPreviewExtension",
        "PRODUCT_NAME": "DevPreviewExtension",
        "SKIP_INSTALL": True,
        "SWIFT_STRICT_CONCURRENCY": "minimal",
        "SWIFT_VERSION": "5.0",
    }

    settings_by_config = {
        project_debug_id: ("Debug", project_debug_settings),
        project_release_id: ("Release", project_release_settings),
        app_debug_id: ("Debug", app_settings),
        app_release_id: ("Release", app_settings),
        extension_debug_id: ("Debug", extension_settings),
        extension_release_id: ("Release", extension_settings),
    }
    for config_id, (name, settings) in settings_by_config.items():
        sections["XCBuildConfiguration"].append(
            object_text(
                config_id,
                "XCBuildConfiguration",
                {"buildSettings": settings, "name": name},
                name,
            )
        )

    sections["XCConfigurationList"].append(
        object_text(
            project_config_list_id,
            "XCConfigurationList",
            {
                "buildConfigurations": [
                    ref("config:project:Debug", "Debug"),
                    ref("config:project:Release", "Release"),
                ],
                "defaultConfigurationIsVisible": 0,
                "defaultConfigurationName": "Release",
            },
            "Build configuration list for PBXProject \"DevPreview\"",
        )
    )
    sections["XCConfigurationList"].append(
        object_text(
            app_config_list_id,
            "XCConfigurationList",
            {
                "buildConfigurations": [
                    ref("config:app:Debug", "Debug"),
                    ref("config:app:Release", "Release"),
                ],
                "defaultConfigurationIsVisible": 0,
                "defaultConfigurationName": "Release",
            },
            "Build configuration list for PBXNativeTarget \"DevPreview\"",
        )
    )
    sections["XCConfigurationList"].append(
        object_text(
            extension_config_list_id,
            "XCConfigurationList",
            {
                "buildConfigurations": [
                    ref("config:extension:Debug", "Debug"),
                    ref("config:extension:Release", "Release"),
                ],
                "defaultConfigurationIsVisible": 0,
                "defaultConfigurationName": "Release",
            },
            "Build configuration list for PBXNativeTarget \"DevPreviewExtension\"",
        )
    )

    project_fields = {
        "attributes": {
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 1500,
            "LastUpgradeCheck": 1500,
            "TargetAttributes": {
                oid("target:DevPreview"): {
                    "CreatedOnToolsVersion": "15.0",
                },
                oid("target:DevPreviewExtension"): {
                    "CreatedOnToolsVersion": "15.0",
                },
            },
        },
        "buildConfigurationList": ref(
            "config-list:project",
            "Build configuration list for PBXProject \"DevPreview\"",
        ),
        "compatibilityVersion": "Xcode 14.0",
        "developmentRegion": "en",
        "hasScannedForEncodings": 0,
        "knownRegions": ["en", "Base"],
        "mainGroup": ref("group:root", "Main group"),
        "productRefGroup": ref("group:Products", "Products"),
        "projectDirPath": "",
        "projectRoot": "",
        "targets": [
            ref("target:DevPreview", "DevPreview"),
            ref("target:DevPreviewExtension", "DevPreviewExtension"),
        ],
    }

    sections["PBXProject"].append(
        object_text(
            project_id,
            "PBXProject",
            project_fields,
            "Project object",
        )
    )

    section_order = [
        "PBXBuildFile",
        "PBXContainerItemProxy",
        "PBXCopyFilesBuildPhase",
        "PBXFileReference",
        "PBXFrameworksBuildPhase",
        "PBXGroup",
        "PBXNativeTarget",
        "PBXProject",
        "PBXResourcesBuildPhase",
        "PBXSourcesBuildPhase",
        "PBXTargetDependency",
        "XCBuildConfiguration",
        "XCConfigurationList",
    ]

    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
    ]
    for section in section_order:
        lines.append("")
        lines.append(f"/* Begin {section} section */")
        lines.extend(sections[section])
        lines.append(f"/* End {section} section */")
    lines.extend(
        [
            "\t};",
            f"\trootObject = {project_id} /* Project object */;",
            "}",
        ]
    )
    pbxproj = "\n".join(lines) + "\n"

    buildable_reference = (
        '                        <BuildableReference\n'
        f'                           BuildableIdentifier = "primary"\n'
        f'                           BlueprintIdentifier = "{app_target_id}"\n'
        '                           BuildableName = "DevPreview.app"\n'
        '                           BlueprintName = "DevPreview"\n'
        '                           ReferencedContainer = "container:DevPreview.xcodeproj">\n'
        "                        </BuildableReference>"
    )
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "DevPreview.app"
               BlueprintName = "DevPreview"
               ReferencedContainer = "container:DevPreview.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{buildable_reference}
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{buildable_reference}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    return pbxproj, scheme


def main() -> None:
    pbxproj, scheme = generate()
    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    SCHEME_PATH.parent.mkdir(parents=True, exist_ok=True)
    PBXPROJ_PATH.write_text(pbxproj, encoding="utf-8")
    SCHEME_PATH.write_text(scheme, encoding="utf-8")
    print(f"Wrote {PBXPROJ_PATH}")
    print(f"Wrote {SCHEME_PATH}")


if __name__ == "__main__":
    main()
