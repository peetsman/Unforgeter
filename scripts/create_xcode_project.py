"""Regenerate the small, dependency-free Xcode project from the app's Swift files."""
from pathlib import Path
import hashlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def identifier(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def generate():
    sources = sorted((ROOT / "Unforgeter").rglob("*.swift"))
    project, target, group, products, app, phase = map(identifier, [
        "project", "target", "group", "products", "app", "sources"
    ])
    project_configs, target_configs = identifier("project-configs"), identifier("target-configs")
    objects = []
    children, builds = [], []
    for source in sources:
        path = source.relative_to(ROOT).as_posix()
        ref, build = identifier(path), identifier("build:" + path)
        children.append(ref)
        builds.append(build)
        objects.extend([
            f'{ref} = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = SOURCE_ROOT; }};',
            f'{build} = {{isa = PBXBuildFile; fileRef = {ref}; }};',
        ])
    objects.extend([
        f'{app} = {{isa = PBXFileReference; explicitFileType = wrapper.application; path = Unforgeter.app; sourceTree = BUILT_PRODUCTS_DIR; }};',
        f'{group} = {{isa = PBXGroup; children = ({", ".join(children + [products])},); sourceTree = "<group>"; }};',
        f'{products} = {{isa = PBXGroup; children = ({app},); name = Products; sourceTree = "<group>"; }};',
        f'{phase} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(builds)},); runOnlyForDeploymentPostprocessing = 0; }};',
        f'{target} = {{isa = PBXNativeTarget; buildConfigurationList = {target_configs}; buildPhases = ({phase},); buildRules = (); dependencies = (); name = Unforgeter; productName = Unforgeter; productReference = {app}; productType = "com.apple.product-type.application"; }};',
        f'{project} = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{{target} = {{CreatedOnToolsVersion = 16.0; }}; }}; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base,); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},); }};',
    ])
    for config in ("Debug", "Release"):
        project_settings = {
            "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
            "SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "SWIFT_VERSION": "5.0", "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu17", "SWIFT_STRICT_CONCURRENCY": "targeted",
            "DEBUG_INFORMATION_FORMAT": "dwarf" if config == "Debug" else "dwarf-with-dsym",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if config == "Debug" else "-O",
        }
        if config == "Debug":
            project_settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG $(inherited)"
            project_settings["ENABLE_TESTABILITY"] = "YES"
            project_settings["ONLY_ACTIVE_ARCH"] = "YES"
        else:
            project_settings["SWIFT_COMPILATION_MODE"] = "wholemodule"
            project_settings["VALIDATE_PRODUCT"] = "YES"
        target_settings = {
            "PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": "com.peetsman.Unforgeter",
            "INFOPLIST_FILE": "Unforgeter/Resources/Info.plist", "GENERATE_INFOPLIST_FILE": "NO",
            "CODE_SIGN_STYLE": "Automatic", "TARGETED_DEVICE_FAMILY": "1",
            "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "SUPPORTS_MACCATALYST": "NO",
            "CURRENT_PROJECT_VERSION": "1", "MARKETING_VERSION": "0.1.0",
            "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
        }
        for owner, settings in [("project", project_settings), ("target", target_settings)]:
            values = " ".join(f'{key} = "{value}";' for key, value in settings.items())
            objects.append(f'{identifier(owner + config)} = {{isa = XCBuildConfiguration; buildSettings = {{{values}}}; name = {config}; }};')
    for owner, config_id in [("project", project_configs), ("target", target_configs)]:
        objects.append(f'{config_id} = {{isa = XCConfigurationList; buildConfigurations = ({identifier(owner + "Debug")}, {identifier(owner + "Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};')
    directory = ROOT / "Unforgeter.xcodeproj"
    directory.mkdir(exist_ok=True)
    content = '// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n'
    content += "\n".join("\t\t" + obj for obj in objects)
    content += f'\n\t}};\n\trootObject = {project};\n}}\n'
    (directory / "project.pbxproj").write_text(content, encoding="utf-8", newline="\n")

    scheme = ET.Element("Scheme", LastUpgradeVersion="1600", version="1.3")
    build_action = ET.SubElement(scheme, "BuildAction", parallelizeBuildables="YES", buildImplicitDependencies="YES")
    entries = ET.SubElement(build_action, "BuildActionEntries")
    entry = ET.SubElement(entries, "BuildActionEntry", **{f"buildFor{purpose}": "YES" for purpose in ["Testing", "Running", "Profiling", "Archiving", "Analyzing"]})

    def reference(parent):
        ET.SubElement(parent, "BuildableReference", BuildableIdentifier="primary", BlueprintIdentifier=target,
                      BuildableName="Unforgeter.app", BlueprintName="Unforgeter", ReferencedContainer="container:Unforgeter.xcodeproj")

    reference(entry)
    test = ET.SubElement(scheme, "TestAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", shouldUseLaunchSchemeArgsEnv="YES")
    ET.SubElement(test, "Testables")
    launch = ET.SubElement(scheme, "LaunchAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", launchStyle="0", useCustomWorkingDirectory="NO", ignoresPersistentStateOnLaunch="NO", debugDocumentVersioning="YES", debugServiceExtension="internal", allowLocationSimulation="YES")
    reference(ET.SubElement(launch, "BuildableProductRunnable", runnableDebuggingMode="0"))
    profile = ET.SubElement(scheme, "ProfileAction", buildConfiguration="Release", shouldUseLaunchSchemeArgsEnv="YES", savedToolIdentifier="", useCustomWorkingDirectory="NO", debugDocumentVersioning="YES")
    reference(ET.SubElement(profile, "BuildableProductRunnable", runnableDebuggingMode="0"))
    ET.SubElement(scheme, "AnalyzeAction", buildConfiguration="Debug")
    ET.SubElement(scheme, "ArchiveAction", buildConfiguration="Release", revealArchiveInOrganizer="YES")
    ET.indent(scheme)
    schemes = directory / "xcshareddata/xcschemes"
    schemes.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(scheme).write(schemes / "Unforgeter.xcscheme", encoding="UTF-8", xml_declaration=True)
    print(f"Generated Xcode project with {len(sources)} Swift app files.")


if __name__ == "__main__":
    generate()
