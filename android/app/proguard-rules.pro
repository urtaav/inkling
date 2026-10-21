# Estos plugins llaman a sus clases desde Dart por JNI, buscando cada método
# por su firma exacta. R8 no ve esas llamadas: en release renombraba
# kotlin.coroutines.Continuation (parte de la firma de los métodos suspend) y
# fallaba con NoSuchMethodError al leer el avance.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep interface kotlin.coroutines.Continuation { *; }
