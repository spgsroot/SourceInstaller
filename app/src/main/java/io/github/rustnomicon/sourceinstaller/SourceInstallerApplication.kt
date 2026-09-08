package io.github.rustnomicon.sourceinstaller

import android.app.Application
import io.github.rustnomicon.sourceinstaller.di.AppContainer

class SourceInstallerApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
