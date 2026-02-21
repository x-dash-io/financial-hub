import org.gradle.api.Project

fun Project.fallbackAndroidNamespace(): String {
    val manifest = file("src/main/AndroidManifest.xml")
    if (manifest.exists()) {
        val manifestPackage =
            Regex("""\bpackage\s*=\s*"([^"]+)"""")
                .find(manifest.readText())
                ?.groupValues
                ?.getOrNull(1)
        if (!manifestPackage.isNullOrBlank()) {
            return manifestPackage
        }
    }

    val groupValue = group.toString()
    if (groupValue.isNotBlank() && groupValue != "unspecified") {
        return groupValue
    }

    val safeProjectName = name.replace(Regex("[^A-Za-z0-9_]"), "_")
    return "com.financialhub.$safeProjectName"
}

fun Project.ensureAndroidNamespace() {
    val androidExtension = extensions.findByName("android") ?: return
    val getNamespace =
        androidExtension.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        } ?: return
    val existingNamespace = getNamespace.invoke(androidExtension) as? String
    if (!existingNamespace.isNullOrBlank()) return

    val setNamespace =
        androidExtension.javaClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterCount == 1
        } ?: return
    setNamespace.invoke(androidExtension, fallbackAndroidNamespace())
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    plugins.withId("com.android.application") {
        ensureAndroidNamespace()
    }
    plugins.withId("com.android.library") {
        ensureAndroidNamespace()
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
