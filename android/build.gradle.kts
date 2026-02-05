allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force newer androidx.core to fix lStar attribute issue with isar_flutter_libs
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.0")
            force("androidx.core:core-ktx:1.13.0")
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for isar_flutter_libs and other packages
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)

        // Fix missing namespace
        val currentNamespace = android.namespace
        if (currentNamespace == null || currentNamespace.isEmpty()) {
            val groupName = project.group?.toString() ?: ""
            android.namespace = if (groupName.isNotEmpty()) {
                groupName
            } else {
                "com.${project.name.replace("-", "_").replace(".", "_")}"
            }
        }

        // Force compileSdkVersion 36 for all library modules
        android.compileSdk = 36
    }

    // Disable verifyReleaseResources for isar_flutter_libs (fixes lStar issue)
    tasks.whenTaskAdded {
        if (name == "verifyReleaseResources" && project.name == "isar_flutter_libs") {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
