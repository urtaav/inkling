# Estos plugins llaman a sus clases desde Dart por JNI; R8 no ve esas
# llamadas y en release las borraba (NoSuchMethodError):
# shared_preferences al leer el avance y path_provider al guardar grabaciones.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
