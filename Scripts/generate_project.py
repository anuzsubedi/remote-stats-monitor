#!/usr/bin/env python3
"""Generate the standard Xcode project using only Python's standard library."""
from pathlib import Path
from hashlib import sha1
import json

ROOT = Path(__file__).resolve().parent.parent
objects = {}


def identifier(key):
    return sha1(key.encode()).hexdigest()[:24].upper()


def add(key, isa, **values):
    reference = identifier(key)
    objects[reference] = dict(isa=isa, **values)
    return reference


def encode(value, depth=0):
    if isinstance(value, dict):
        return "{\n" + "".join("\t" * (depth + 1) + encode(k) + " = " + encode(v, depth + 1) + ";\n" for k, v in value.items()) + "\t" * depth + "}"
    if isinstance(value, list):
        return "(" + ", ".join(encode(v, depth + 1) for v in value) + ")"
    if isinstance(value, int):
        return str(value)
    return json.dumps(value)


file_refs = {}


def source_group(folder):
    children = []
    for entry in sorted(folder.iterdir(), key=lambda path: path.name):
        if entry.is_dir():
            nested_group = source_group(entry)
            if nested_group is not None:
                children.append(nested_group)
            continue
        if entry.suffix not in [".swift", ".plist", ".entitlements"]:
            continue
        path = str(entry.relative_to(ROOT))
        kind = "sourcecode.swift" if entry.suffix == ".swift" else "text.plist.xml"
        file_refs[path] = add("file:" + path, "PBXFileReference", lastKnownFileType=kind, path=path, sourceTree="SOURCE_ROOT")
        children.append(file_refs[path])
    if not children:
        return None
    key = str(folder.relative_to(ROOT))
    return add("group:" + key, "PBXGroup", children=children, name=folder.name, sourceTree="<group>")


groups = [source_group(ROOT / folder) for folder in ["App", "Core", "Shared", "Widget"]]

products = {}
for target, name, kind in [("RemoteStatsMonitor", "Remote Stats Monitor.app", "wrapper.application"),
                            ("RemoteStatsMonitorWidget", "RemoteStatsMonitorWidget.appex", "wrapper.app-extension")]:
    products[target] = add("product:" + target, "PBXFileReference", explicitFileType=kind, path=name, sourceTree="BUILT_PRODUCTS_DIR")
product_group = add("products", "PBXGroup", children=list(products.values()), name="Products", sourceTree="<group>")
asset = add("assets", "PBXFileReference", lastKnownFileType="folder.assetcatalog", path="App/Assets.xcassets", sourceTree="SOURCE_ROOT")
objects[identifier("group:App")]["children"].append(asset)
icon = add("icon-composer", "PBXFileReference", lastKnownFileType="folder.icon", path="AppIcon.icon", sourceTree="SOURCE_ROOT")
root_group = add("root", "PBXGroup", children=groups + [icon, product_group], sourceTree="<group>")

base = dict(SDKROOT="macosx", MACOSX_DEPLOYMENT_TARGET="26.0", SWIFT_VERSION="6.0",
            SWIFT_STRICT_CONCURRENCY="complete", CODE_SIGN_IDENTITY="Apple Development", CODE_SIGN_STYLE="Manual", DEVELOPMENT_TEAM="8UV7A5D64G",
            ENABLE_HARDENED_RUNTIME="YES", CLANG_ENABLE_MODULES="YES", GCC_WARN_INHIBIT_ALL_WARNINGS="NO")


def configurations(key, settings):
    refs = []
    for name in ["Debug", "Release"]:
        values = base | settings | dict(SWIFT_OPTIMIZATION_LEVEL="-Onone" if name == "Debug" else "-O",
                                       DEBUG_INFORMATION_FORMAT="dwarf" if name == "Debug" else "dwarf-with-dsym")
        if name == "Debug":
            values["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
        refs.append(add(key + ":" + name, "XCBuildConfiguration", buildSettings=values, name=name))
    return add(key + ":configs", "XCConfigurationList", buildConfigurations=refs, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")


target_ids = {name: identifier("target:" + name) for name in products}
project_id = identifier("project")
shared = sorted(p for p in file_refs if p.startswith("Shared/") and p.endswith(".swift"))
core = sorted(p for p in file_refs if p.startswith("Core/") and p.endswith(".swift"))
app = sorted(p for p in file_refs if p.startswith("App/") and p.endswith(".swift"))
widget = sorted(p for p in file_refs if p.startswith("Widget/") and p.endswith(".swift"))
widget_core = [
    "Core/Models/MonitorSnapshot.swift",
    "Core/Models/RemoteProcess.swift",
    "Core/Models/MonitorError.swift",
    "Core/Persistence/SnapshotStore.swift",
    "Core/WidgetIntegration/WidgetServerSource.swift",
    "Core/Persistence/DebugSnapshotStore.swift",
    "Core/Debug/SyntheticServers.swift",
]
# Widget button intents need to be available to both the widget extension and its host app.
widget_app_intents = ["Widget/Configuration/WidgetServerAction.swift"]
sources = {
    "RemoteStatsMonitor": core + shared + app + widget_app_intents,
    "RemoteStatsMonitorWidget": shared + widget_core + widget,
}
for target in products:
    builds = [add("source:" + target + ":" + p, "PBXBuildFile", fileRef=file_refs[p]) for p in sources[target]]
    phases = [add("sources:" + target, "PBXSourcesBuildPhase", buildActionMask=2147483647, files=builds, runOnlyForDeploymentPostprocessing=0),
              add("frameworks:" + target, "PBXFrameworksBuildPhase", buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)]
    dependencies = []
    if target == "RemoteStatsMonitor":
        resource = add("resource:icons", "PBXBuildFile", fileRef=asset)
        phases.append(add("resources:RemoteStatsMonitor", "PBXResourcesBuildPhase", buildActionMask=2147483647, files=[resource, add("resource:icon-composer", "PBXBuildFile", fileRef=icon)], runOnlyForDeploymentPostprocessing=0))
        for child, destination in [("RemoteStatsMonitorWidget", 13)]:
            proxy = add("proxy:" + child, "PBXContainerItemProxy", containerPortal=project_id, proxyType=1, remoteGlobalIDString=target_ids[child], remoteInfo=child)
            dependencies.append(add("dependency:" + child, "PBXTargetDependency", target=target_ids[child], targetProxy=proxy))
            embed = add("embed:" + child, "PBXBuildFile", fileRef=products[child], settings=dict(ATTRIBUTES=["CodeSignOnCopy"]))
            phases.append(add("copy:" + child, "PBXCopyFilesBuildPhase", buildActionMask=2147483647, dstPath="", dstSubfolderSpec=destination,
                              files=[embed], name="Embed " + child, runOnlyForDeploymentPostprocessing=0))
    settings = dict(PRODUCT_NAME="Remote Stats Monitor" if target == "RemoteStatsMonitor" else target,
                    PRODUCT_BUNDLE_IDENTIFIER="dev.anuz." + target, SKIP_INSTALL="NO" if target == "RemoteStatsMonitor" else "YES")
    if target != "RemoteStatsMonitorSSHAskpass":
        folder = "App" if target == "RemoteStatsMonitor" else "Widget"
        settings.update(INFOPLIST_FILE=folder + "/Info.plist", CODE_SIGN_ENTITLEMENTS=folder + "/" + target + ".entitlements",
                        LD_RUNPATH_SEARCH_PATHS="$(inherited) @executable_path/../Frameworks", ENABLE_APP_SANDBOX="YES" if target == "RemoteStatsMonitorWidget" else "NO")
    if target == "RemoteStatsMonitorWidget":
        settings["APPLICATION_EXTENSION_API_ONLY"] = "YES"
    if target == "RemoteStatsMonitor":
        settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    product_type = {"RemoteStatsMonitor": "com.apple.product-type.application", "RemoteStatsMonitorWidget": "com.apple.product-type.app-extension", "RemoteStatsMonitorSSHAskpass": "com.apple.product-type.tool"}[target]
    add("target:" + target, "PBXNativeTarget", buildConfigurationList=configurations(target, settings), buildPhases=phases,
        buildRules=[], dependencies=dependencies, name=target, productName=settings["PRODUCT_NAME"], productReference=products[target], productType=product_type)

add("project", "PBXProject", attributes=dict(LastUpgradeCheck="2700", BuildIndependentTargetsInParallel="YES"),
    buildConfigurationList=configurations("project", {}), compatibilityVersion="Xcode 15.0", developmentRegion="en",
    hasScannedForEncodings=0, knownRegions=["en", "Base"], mainGroup=root_group, productRefGroup=product_group,
    projectDirPath="", projectRoot="", targets=list(target_ids.values()))

project = ROOT / "RemoteStatsMonitor.xcodeproj"
project.mkdir(exist_ok=True)
document = dict(archiveVersion=1, classes={}, objectVersion=60, objects=objects, rootObject=project_id)
(project / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode(document) + "\n")
schemes = project / "xcshareddata/xcschemes"
schemes.mkdir(parents=True, exist_ok=True)
(schemes / "RemoteStatsMonitor.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.7">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids['RemoteStatsMonitor']}" BuildableName="Remote Stats Monitor.app" BlueprintName="RemoteStatsMonitor" ReferencedContainer="container:RemoteStatsMonitor.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target_ids['RemoteStatsMonitor']}" BuildableName="Remote Stats Monitor.app" BlueprintName="RemoteStatsMonitor" ReferencedContainer="container:RemoteStatsMonitor.xcodeproj"/></BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print("Generated RemoteStatsMonitor.xcodeproj")
