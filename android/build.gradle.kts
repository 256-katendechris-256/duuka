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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for isar_flutter_libs and other packages missing namespace
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        val currentNamespace = android.namespace
        if (currentNamespace == null || currentNamespace.isEmpty()) {
            val groupName = project.group?.toString() ?: ""
            android.namespace = if (groupName.isNotEmpty()) {
                groupName
            } else {
                "com.${project.name.replace("-", "_").replace(".", "_")}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
