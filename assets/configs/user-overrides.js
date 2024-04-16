// Desactivar cuentas de microsoft
user_pref("identity.fxaccounts.enabled", false);
user_pref("identity.fxaccounts.toolbar.enabled", false);

// Desactivar pocket
user_pref("extensions.pocket.enabled", false);

// No autocompletar URLs
user_pref("browser.urlbar.autoFill", false);

// Permitir acceder a sitios no https:
user_pref("dom.security.https_only_mode", false);

// Mantener cookies hasta que el usuario las borre o estas expiren:
user_pref("network.cookie.lifetimePolicy", 0);

user_pref("dom.webnotifications.serviceworker.enabled", false);

// No borrar las cookies al salir
user_pref("privacy.clearOnShutdown.cookies", false);

// Arreglar problemas con algunos logins
user_pref("network.http.referer.XOriginPolicy", 0);

// Mostrar siempre los marcadores
user_pref("browser.toolbars.bookmarks.visibility", "always");
