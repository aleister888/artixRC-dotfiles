// Desactivar cuentas de firefox
user_pref("identity.fxaccounts.enabled", false);
user_pref("identity.fxaccounts.toolbar.enabled", false);

// Permitir las extensions instaladas por el script
user_pref("extensions.autoDisableScopes", 0);

// Desactivar pocket
user_pref("extensions.pocket.enabled", false);

// No autocompletar URLs
user_pref("browser.urlbar.autoFill", false);

// Permitir acceder a sitios no https:
user_pref("dom.security.https_only_mode", false);

// Arreglar problemas con algunos logins
user_pref("network.http.referer.XOriginPolicy", 0);

// Mostrar siempre los marcadores
user_pref("browser.toolbars.bookmarks.visibility", "always");

// Barra de tareas del sistema
user_pref("browser.tabs.inTitlebar", 0);

// Mantener cookies hasta que estas expiren o se borren manualmente
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("privacy.clearOnShutdown.cookies", false);

// Desactivar notificaciones
user_pref("dom.push.enabled", false);

// Desactivar funciones expermientales
user_pref("browser.preferences.experimental", false);
user_pref("browser.preferences.experimental.hidden", true);

// Permitir UI personalizado
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Desactivar el baúl de contraseñas
user_pref("signon.rememberSignons", false);
