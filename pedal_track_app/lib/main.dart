// ignore_for_file: unused_element
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, ChangeNotifier, protected;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dependencyInjector();
  await initDependencies();
  final Routes appRoutes = Routes();
  runApp(
    PedalTrackApp(
      appRoutes: appRoutes,
      settingViewModel: locator<SettingViewModel>(),
    ),
  );
}

final locator = GetIt.instance;

void dependencyInjector() {
  _startConnectionService();
  _startHttpService();
  _startStorageService();
  _startFeatureSetting();
  _startFeatureAuth();
  _startFeatureBottom();
  _startFeatureBikes();
  _startFeatureRides();
  _startFeatureParts();
  _startFeatureHistory();
}

void _startConnectionService() => locator
    .registerLazySingleton<ConnectionService>(() => ConnectionServiceImpl());
void _startHttpService() =>
    locator.registerLazySingleton<HttpService>(() => HttpServiceImpl());
void _startStorageService() =>
    locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
void _startFeatureSetting() {
  locator.registerCachedFactory<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

void _startFeatureAuth() {
  locator.registerCachedFactory<AuthRepository>(
    () => AuthRepositoryImpl(
      connectionService: locator<ConnectionService>(),
      httpService: locator<HttpService>(),
      storageService: locator<StorageService>(),
    ),
  );
  locator.registerLazySingleton<AuthViewModel>(
    () => AuthViewModelImpl(authRepository: locator<AuthRepository>()),
  );
}

void _startFeatureBottom() =>
    locator.registerLazySingleton<BottomViewModel>(() => BottomViewModelImpl());
void _startFeatureBikes() {
  locator.registerCachedFactory<BikeRepository>(
    () => BikeRepositoryImpl(httpService: locator<HttpService>()),
  );
  locator.registerLazySingleton<BikeViewModel>(
    () => BikeViewModelImpl(bikeRepository: locator<BikeRepository>()),
  );
}

void _startFeatureRides() {
  locator.registerCachedFactory<RideRepository>(
    () => RideRepositoryImpl(httpService: locator<HttpService>()),
  );
  locator.registerLazySingleton<RideViewModel>(
    () => RideViewModelImpl(rideRepository: locator<RideRepository>()),
  );
}

void _startFeatureParts() {
  locator.registerCachedFactory<PartRepository>(
    () => PartRepositoryImpl(httpService: locator<HttpService>()),
  );
  locator.registerLazySingleton<PartViewModel>(
    () => PartViewModelImpl(partRepository: locator<PartRepository>()),
  );
}

void _startFeatureHistory() {
  locator.registerCachedFactory<HistoryRepository>(
    () => HistoryRepositoryImpl(httpService: locator<HttpService>()),
  );
  locator.registerLazySingleton<HistoryViewModel>(
    () => HistoryViewModelImpl(historyRepository: locator<HistoryRepository>()),
  );
}

Future<void> initDependencies() async {
  await locator<StorageService>().initStorage();
  await Future.wait([locator<SettingViewModel>().getTheme()]);
  final token = await locator<StorageService>().getStringValue(
    key: ValueConstant.tokenKey,
  );
  if (token != null) locator<HttpService>().setAuthorizationToken(token);
}

// ============================================================
// APP
// ============================================================

class PedalTrackApp extends StatelessWidget {
  final Routes appRoutes;
  final SettingViewModel settingViewModel;

  const PedalTrackApp({
    super.key,
    required this.appRoutes,
    required this.settingViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return StateBuilderWidget<SettingViewModel, SettingModel>(
      viewModel: settingViewModel,
      builder: (context, settingModel) => MaterialApp.router(
        title: 'PedalTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settingModel.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        routerConfig: appRoutes.routes,
      ),
    );
  }
}

// ============================================================
// THEME
// ============================================================

class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF38E07B);
  static const Color _primaryDark = Color(0xFF1DB954);
  static const Color _danger = Color(0xFFFF4D4D);
  static const Color _warning = Color(0xFFFFB020);
  static const Color _neutral = Color(0xFF888780);
  static const Color _bgLight = Color(0xFFF6F8F7);
  static const Color _surfLight = Color(0xFFFFFFFF);
  static const Color _txtPrimLight = Color(0xFF0D1F16);
  static const Color _txtSecLight = Color(0xFF4A5568);
  static const Color _bgDark = Color(0xFF122017);
  static const Color _surfDark = Color(0xFF1C2E22);
  static const Color _surfDark2 = Color(0xFF243B2A);
  static const Color _txtPrimDark = Color(0xFFECFDF5);
  static const Color _txtSecDark = Color(0xFF9DC8AC);

  static Color get primary => _primary;
  static Color get primaryDark => _primaryDark;
  static Color get danger => _danger;
  static Color get warning => _warning;
  static Color get neutral => _neutral;
  static Color get bgDark => _bgDark;
  static Color get surfDark => _surfDark;
  static Color get surfDark2 => _surfDark2;
  static Color get txtPrimDark => _txtPrimDark;
  static Color get txtSecDark => _txtSecDark;
  static Color get bgLight => _bgLight;

  static const String _font = 'Lexend';

  static ThemeData get light => _build(
    ColorScheme.light(
      primary: _primary,
      onPrimary: _txtPrimLight,
      secondary: _primaryDark,
      onSecondary: _surfLight,
      error: _danger,
      surface: _surfLight,
      onSurface: _txtPrimLight,
      surfaceContainerHighest: _bgLight,
      outline: _neutral,
    ),
    _bgLight,
    _surfLight,
    _txtPrimLight,
    _txtSecLight,
  );

  static ThemeData get dark => _build(
    ColorScheme.dark(
      primary: _primary,
      onPrimary: _bgDark,
      secondary: _primaryDark,
      onSecondary: _bgDark,
      error: _danger,
      surface: _surfDark,
      onSurface: _txtPrimDark,
      surfaceContainerHighest: _bgDark,
      outline: _neutral,
    ),
    _bgDark,
    _surfDark,
    _txtPrimDark,
    _txtSecDark,
  );

  static ThemeData _build(
    ColorScheme cs,
    Color bg,
    Color surf,
    Color txtP,
    Color txtS,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: _font,
      scaffoldBackgroundColor: bg,
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txtP,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtP,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surf,
        elevation: 0,
        indicatorColor: _primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? IconThemeData(color: _primary, size: 24)
              : IconThemeData(color: txtS, size: 24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                )
              : TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: txtS,
                ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: txtS.withValues(alpha: 0.6),
          fontFamily: _font,
        ),
        labelStyle: TextStyle(color: txtS, fontFamily: _font),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _bgDark,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: _primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _bgDark,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surf.withValues(alpha: 0.5),
        selectedColor: _primary.withValues(alpha: 0.2),
        side: BorderSide(color: _neutral.withValues(alpha: 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(
          fontFamily: _font,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: txtP,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: _neutral.withValues(alpha: 0.15),
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surf,
        contentTextStyle: TextStyle(
          fontFamily: _font,
          color: txtP,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actionTextColor: _primary,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _font,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: txtP,
        ),
        headlineMedium: TextStyle(
          fontFamily: _font,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: txtP,
        ),
        headlineSmall: TextStyle(
          fontFamily: _font,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtP,
        ),
        titleLarge: TextStyle(
          fontFamily: _font,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: txtP,
        ),
        titleMedium: TextStyle(
          fontFamily: _font,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: txtP,
        ),
        bodyLarge: TextStyle(
          fontFamily: _font,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: txtP,
        ),
        bodyMedium: TextStyle(
          fontFamily: _font,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: txtP,
        ),
        bodySmall: TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: txtS,
        ),
        labelLarge: TextStyle(
          fontFamily: _font,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: txtP,
        ),
        labelMedium: TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: txtS,
        ),
      ),
    );
  }
}

// ============================================================
// EXCEPTIONS
// ============================================================

abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.m = 'Sem conexão com a internet.']);
}

class AuthException extends AppException {
  const AuthException([super.m = 'Credenciais inválidas.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.m = 'Sessão expirada. Faça login novamente.',
  ]);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException([super.m = 'Erro no servidor.', this.statusCode]);
}

class NotFoundAppException extends AppException {
  const NotFoundAppException([super.m = 'Recurso não encontrado.']);
}

class ConflictException extends AppException {
  const ConflictException([super.m = 'Operação não permitida.']);
}

class UnknownException extends AppException {
  const UnknownException([super.m = 'Erro inesperado.']);
}

// ============================================================
// APP STATE & RESULT
// ============================================================

sealed class AppState<T> {
  const AppState();
}

final class InitialState<T> extends AppState<T> {
  const InitialState();
}

final class LoadingState<T> extends AppState<T> {
  const LoadingState();
}

final class SuccessState<T> extends AppState<T> {
  final T data;
  const SuccessState({required this.data});
}

final class ErrorState<T> extends AppState<T> {
  final AppException error;
  const ErrorState({required this.error});
}

sealed class Result<S, E extends AppException> {
  const Result();
  T fold<T>({
    required T Function(S) onSuccess,
    required T Function(E) onError,
  }) {
    switch (this) {
      case Success(value: final v):
        return onSuccess(v);
      case Error(error: final e):
        return onError(e);
    }
  }
}

final class Success<S, E extends AppException> extends Result<S, E> {
  final S value;
  const Success({required this.value});
}

final class Error<S, E extends AppException> extends Result<S, E> {
  final E error;
  const Error({required this.error});
}

// ============================================================
// STATE MANAGEMENT
// ============================================================

abstract class StateManagement<T> extends ChangeNotifier {
  late T _state;
  StateManagement() {
    _state = build();
  }
  @protected
  T build();
  T get state => _state;
  @protected
  void emitState(T newState) {
    if (identical(_state, newState)) return;
    _state = newState;
    notifyListeners();
  }

  @override
  String toString() => 'StateManagement<$T>(state: $_state)';
}

@protected
typedef StateBuilder<S> = Widget Function(BuildContext context, S state);

class StateBuilderWidget<V extends StateManagement<S>, S>
    extends StatelessWidget {
  final V viewModel;
  final StateBuilder<S> builder;
  final Widget? child;
  const StateBuilderWidget({
    super.key,
    required this.viewModel,
    required this.builder,
    this.child,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    child: child,
    builder: (context, child) => builder(context, viewModel.state),
  );
}

// ============================================================
// CONSTANTS
// ============================================================

class ValueConstant {
  ValueConstant._();
  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static String get _base => _isAndroid && !kIsWeb
      ? 'http://10.0.2.2:5035/api'
      : 'http://localhost:5035/api';
  static String get tokenKey => 'AccessToken';
  static String get darkModeKey => 'DarkMode';
  static String get register => '$_base/auth/register';
  static String get login => '$_base/auth/login';
  static String get bikes => '$_base/bikes';
  static String bike(int id) => '$_base/bikes/$id';
  static String rides(int b) => '$_base/bikes/$b/rides';
  static String parts(int b) => '$_base/bikes/$b/parts';
  static String part(int b, int p) => '$_base/bikes/$b/parts/$p';
  static String exchangePart(int b, int p) =>
      '$_base/bikes/$b/parts/$p/exchange';
  static String partExchanges(int b, int p) =>
      '$_base/bikes/$b/parts/$p/exchanges';
  static String history(int b) => '$_base/bikes/$b/history';
  static String alerts(int b) => '$_base/bikes/$b/alerts';
  static String checklists(int b) => '$_base/bikes/$b/checklists';
}

// ============================================================
// ROUTES
// ============================================================

class Routes {
  static String get home => '/splash';
  GoRouter get routes => _routes;
  final GoRouter _routes = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: home,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) => SplashView(authViewModel: locator<AuthViewModel>()),
      ),
      GoRoute(
        path: AuthRoutes.login,
        builder: (c, s) =>
            LoginAuthView(authViewModel: locator<AuthViewModel>()),
      ),
      GoRoute(
        path: AuthRoutes.register,
        builder: (c, s) =>
            RegisterAuthView(authViewModel: locator<AuthViewModel>()),
      ),
      GoRoute(
        path: BottomRoutes.bottom,
        builder: (c, s) => BottomView(
          bottomViewModel: locator<BottomViewModel>(),
          settingViewModel: locator<SettingViewModel>(),
          bikeViewModel: locator<BikeViewModel>(),
          rideViewModel: locator<RideViewModel>(),
          partViewModel: locator<PartViewModel>(),
          historyViewModel: locator<HistoryViewModel>(),
        ),
      ),
      GoRoute(
        path: '/parts/:partId',
        builder: (c, s) => PartDetailView(
          partId: int.parse(s.pathParameters['partId']!),
          partViewModel: locator<PartViewModel>(),
        ),
      ),
    ],
  );
}

class AuthRoutes {
  static String get login => '/auth/login';
  static String get register => '/auth/register';
}

class BottomRoutes {
  static String get bottom => '/home';
}

// ============================================================
// CONNECTION SERVICE
// ============================================================

abstract interface class ConnectionService {
  bool get isConnected;
  Future<void> checkConnection();
}

class ConnectionServiceImpl implements ConnectionService {
  final Connectivity _conn = Connectivity();
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;
  @override
  Future<void> checkConnection() async {
    try {
      final r = await _conn.checkConnectivity();
      _isConnected = !r.contains(ConnectivityResult.none);
    } catch (e) {
      throw NetworkException('$e');
    }
  }
}

// ============================================================
// HTTP SERVICE
// ============================================================

typedef HttpResult = ({int? statusCode, Object? data, String? error});

abstract interface class HttpService {
  Future<HttpResult> getData({
    required String path,
    dynamic data,
    bool useAuth = true,
  });
  Future<HttpResult> postData({
    required String path,
    dynamic data,
    bool useAuth = true,
  });
  Future<HttpResult> putData({
    required String path,
    dynamic data,
    bool useAuth = true,
  });
  Future<HttpResult> deleteData({required String path, bool useAuth = true});
  Future<HttpResult> updateData({
    required String path,
    dynamic data,
    bool useAuth = true,
  });
  void setAuthorizationToken(String token);
  void clearAuthorizationToken();
  void setBaseUrl(String baseUrl);
  void addInterceptor(Interceptor interceptor);
  void removeAllInterceptors();
}

class HttpServiceImpl implements HttpService {
  final Dio _auth = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final Dio _noAuth = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  HttpServiceImpl() {
    final i = InterceptorsWrapper(
      onRequest: (o, h) {
        debugPrint('➡️ ${o.method} ${o.uri}');
        return h.next(o);
      },
      onResponse: (r, h) {
        debugPrint('✅ ${r.statusCode}');
        return h.next(r);
      },
      onError: (DioException e, h) {
        debugPrint('❌ ${e.message}');
        return h.next(e);
      },
    );
    _auth.interceptors.add(i);
    _noAuth.interceptors.add(i);
  }

  Dio _c(bool a) => a ? _auth : _noAuth;
  HttpResult _ok(Response r) =>
      (statusCode: r.statusCode, data: r.data, error: null);
  HttpResult _err(DioException e) => (
    statusCode: e.response?.statusCode,
    data: e.response?.data,
    error: e.message,
  );
  HttpResult _gen(Object e) => (statusCode: null, data: null, error: '$e');

  @override
  Future<HttpResult> getData({
    required String path,
    dynamic data,
    bool useAuth = true,
  }) async {
    try {
      return _ok(await _c(useAuth).get(path, data: data));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _gen(e);
    }
  }

  @override
  Future<HttpResult> postData({
    required String path,
    dynamic data,
    bool useAuth = true,
  }) async {
    try {
      return _ok(await _c(useAuth).post(path, data: data));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _gen(e);
    }
  }

  @override
  Future<HttpResult> putData({
    required String path,
    dynamic data,
    bool useAuth = true,
  }) async {
    try {
      return _ok(await _c(useAuth).put(path, data: data));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _gen(e);
    }
  }

  @override
  Future<HttpResult> updateData({
    required String path,
    dynamic data,
    bool useAuth = true,
  }) async => putData(path: path, data: data, useAuth: useAuth);
  @override
  Future<HttpResult> deleteData({
    required String path,
    bool useAuth = true,
  }) async {
    try {
      return _ok(await _c(useAuth).delete(path));
    } on DioException catch (e) {
      return _err(e);
    } catch (e) {
      return _gen(e);
    }
  }

  @override
  void setAuthorizationToken(String t) {
    _auth.options.headers['Authorization'] = 'Bearer $t';
  }

  @override
  void clearAuthorizationToken() {
    _auth.options.headers.remove('Authorization');
  }

  @override
  void setBaseUrl(String u) {
    _auth.options.baseUrl = u;
    _noAuth.options.baseUrl = u;
  }

  @override
  void addInterceptor(Interceptor i) {
    _auth.interceptors.add(i);
    _noAuth.interceptors.add(i);
  }

  @override
  void removeAllInterceptors() {
    _auth.interceptors.clear();
    _noAuth.interceptors.clear();
  }
}

// ============================================================
// STORAGE SERVICE
// ============================================================

abstract interface class StorageService {
  Future<void> initStorage();
  Future<bool?> getBoolValue({required String key});
  Future<void> setBoolValue({required String key, required bool value});
  Future<String?> getStringValue({required String key});
  Future<void> setStringValue({required String key, required String value});
  Future<void> removeValue({required String key});
  Future<void> clearStorage();
}

class StorageServiceImpl implements StorageService {
  late final SharedPreferences _s;
  @override
  Future<void> initStorage() async {
    _s = await SharedPreferences.getInstance();
  }

  @override
  Future<bool?> getBoolValue({required String key}) async => _s.getBool(key);
  @override
  Future<void> setBoolValue({required String key, required bool value}) async =>
      _s.setBool(key, value);
  @override
  Future<String?> getStringValue({required String key}) async =>
      _s.getString(key);
  @override
  Future<void> setStringValue({
    required String key,
    required String value,
  }) async => _s.setString(key, value);
  @override
  Future<void> removeValue({required String key}) async => _s.remove(key);
  @override
  Future<void> clearStorage() async => _s.clear();
}

// ============================================================
// MODELS
// ============================================================

class UserModel {
  final int? id;
  final String? name;
  final String? email;
  UserModel({this.id, this.name, this.email});
  factory UserModel.fromJson(Map<String, dynamic> j) =>
      UserModel(id: j['id'], name: j['name'], email: j['email']);
}

enum PartStatus { active, replaced }

class PartModel {
  final int? id;
  final int? bikeId;
  final String? name;
  final double? expectedDurationKm;
  final double? kmRidden;
  final double? pricePaid;
  final DateTime? installedAt;
  final PartStatus? status;
  final bool? alertSent;
  final DateTime? createdAt;

  PartModel({
    this.id,
    this.bikeId,
    this.name,
    this.expectedDurationKm,
    this.kmRidden,
    this.pricePaid,
    this.installedAt,
    this.status,
    this.alertSent,
    this.createdAt,
  });

  factory PartModel.fromJson(Map<String, dynamic> j) => PartModel(
    id: j['id'],
    bikeId: j['bikeId'],
    name: j['name'],
    expectedDurationKm: (j['expectedDurationKm'] as num?)?.toDouble(),
    kmRidden: (j['kmRidden'] as num?)?.toDouble(),
    pricePaid: (j['pricePaid'] as num?)?.toDouble(),
    installedAt: j['installedAt'] != null
        ? DateTime.tryParse(j['installedAt'])
        : null,
    status: j['status'] == 'Active' ? PartStatus.active : PartStatus.replaced,
    alertSent: j['alertSent'] as bool?,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'])
        : null,
  );

  double? get progressPercent {
    if (expectedDurationKm == null || expectedDurationKm == 0) return null;
    return ((kmRidden ?? 0) / expectedDurationKm!) * 100;
  }

  bool get isOverLimit => (progressPercent ?? 0) > 100;
}

class BikeModel {
  final int? id;
  final int? userId;
  final String? nickname;
  final String? brand;
  final String? model;
  final String? photoBase64;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PartModel> parts;

  BikeModel({
    this.id,
    this.userId,
    this.nickname,
    this.brand,
    this.model,
    this.photoBase64,
    this.createdAt,
    this.updatedAt,
    this.parts = const [],
  });

  factory BikeModel.fromJson(Map<String, dynamic> j) => BikeModel(
    id: j['id'],
    userId: j['userId'],
    nickname: j['nickname'],
    brand: j['brand'],
    model: j['model'],
    photoBase64: j['photoBase64'],
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'])
        : null,
    updatedAt: j['updatedAt'] != null
        ? DateTime.tryParse(j['updatedAt'])
        : null,
    parts: (j['parts'] as List<dynamic>? ?? [])
        .map((e) => PartModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  double get totalKmRidden => parts
      .where((p) => p.status == PartStatus.active)
      .fold(0.0, (s, p) => s + (p.kmRidden ?? 0));
  List<PartModel> get criticalParts => parts
      .where(
        (p) => p.status == PartStatus.active && (p.progressPercent ?? 0) >= 80,
      )
      .toList();
}

class RideModel {
  final int? id;
  final int? bikeId;
  final double? distanceKm;
  final String? terrain;
  final DateTime? riddenAt;
  final DateTime? createdAt;
  RideModel({
    this.id,
    this.bikeId,
    this.distanceKm,
    this.terrain,
    this.riddenAt,
    this.createdAt,
  });
  factory RideModel.fromJson(Map<String, dynamic> j) => RideModel(
    id: j['id'],
    bikeId: j['bikeId'],
    distanceKm: (j['distanceKm'] as num?)?.toDouble(),
    terrain: j['terrain'],
    riddenAt: j['riddenAt'] != null ? DateTime.tryParse(j['riddenAt']) : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'])
        : null,
  );
}

class PartExchangeModel {
  final int? id;
  final int? partId;
  final int? bikeId;
  final String? partName;
  final double? expectedDurationKm;
  final double? actualKmReached;
  final double? pricePaidAtTime;
  final String? notes;
  final DateTime? exchangedAt;
  PartExchangeModel({
    this.id,
    this.partId,
    this.bikeId,
    this.partName,
    this.expectedDurationKm,
    this.actualKmReached,
    this.pricePaidAtTime,
    this.notes,
    this.exchangedAt,
  });
  factory PartExchangeModel.fromJson(Map<String, dynamic> j) =>
      PartExchangeModel(
        id: j['id'],
        partId: j['partId'],
        bikeId: j['bikeId'],
        partName: j['partName'],
        expectedDurationKm: (j['expectedDurationKm'] as num?)?.toDouble(),
        actualKmReached: (j['actualKmReached'] as num?)?.toDouble(),
        pricePaidAtTime: (j['pricePaidAtTime'] as num?)?.toDouble(),
        notes: j['notes'],
        exchangedAt: j['exchangedAt'] != null
            ? DateTime.tryParse(j['exchangedAt'])
            : null,
      );
  bool get wasPremature => (actualKmReached ?? 0) < (expectedDurationKm ?? 0);
}

class ChecklistModel {
  final int? id;
  final int? bikeId;
  final DateTime? executedAt;
  final String? itemsChecked;
  final String? notes;
  ChecklistModel({
    this.id,
    this.bikeId,
    this.executedAt,
    this.itemsChecked,
    this.notes,
  });
  factory ChecklistModel.fromJson(Map<String, dynamic> j) => ChecklistModel(
    id: j['id'],
    bikeId: j['bikeId'],
    executedAt: j['executedAt'] != null
        ? DateTime.tryParse(j['executedAt'])
        : null,
    itemsChecked: j['itemsChecked'],
    notes: j['notes'],
  );
  List<String> get items =>
      itemsChecked
          ?.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      [];
}

class AlertModel {
  final int? id;
  final int? bikeId;
  final int? partId;
  final String? message;
  final DateTime? triggeredAt;
  AlertModel({
    this.id,
    this.bikeId,
    this.partId,
    this.message,
    this.triggeredAt,
  });
  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
    id: j['id'],
    bikeId: j['bikeId'],
    partId: j['partId'],
    message: j['message'],
    triggeredAt: j['triggeredAt'] != null
        ? DateTime.tryParse(j['triggeredAt'])
        : null,
  );
}

class HistoryModel {
  final List<RideModel> rides;
  final List<PartExchangeModel> partExchanges;
  final List<ChecklistModel> checklists;
  HistoryModel({
    this.rides = const [],
    this.partExchanges = const [],
    this.checklists = const [],
  });
  factory HistoryModel.fromJson(Map<String, dynamic> j) => HistoryModel(
    rides: (j['rides'] as List? ?? [])
        .map((e) => RideModel.fromJson(e))
        .toList(),
    partExchanges: (j['partExchanges'] as List? ?? [])
        .map((e) => PartExchangeModel.fromJson(e))
        .toList(),
    checklists: (j['checklists'] as List? ?? [])
        .map((e) => ChecklistModel.fromJson(e))
        .toList(),
  );
}

// ============================================================
// SETTING FEATURE
// ============================================================

class SettingModel {
  final bool isDarkTheme;
  SettingModel({this.isDarkTheme = true});
  SettingModel copyWith({bool? isDarkTheme}) =>
      SettingModel(isDarkTheme: isDarkTheme ?? this.isDarkTheme);
}

abstract interface class SettingRepository {
  Future<SettingModel> readTheme();
  Future<void> updateTheme({required bool isDarkTheme});
}

class SettingRepositoryImpl implements SettingRepository {
  final StorageService storageService;
  SettingRepositoryImpl({required this.storageService});
  @override
  Future<SettingModel> readTheme() async {
    final v = await storageService.getBoolValue(key: ValueConstant.darkModeKey);
    return SettingModel(isDarkTheme: v ?? true);
  }

  @override
  Future<void> updateTheme({required bool isDarkTheme}) async {
    await storageService.setBoolValue(
      key: ValueConstant.darkModeKey,
      value: isDarkTheme,
    );
  }
}

abstract interface class SettingViewModel
    extends StateManagement<SettingModel> {
  Future<void> getTheme();
  Future<void> changeTheme({required bool isDarkTheme});
}

class SettingViewModelImpl extends StateManagement<SettingModel>
    implements SettingViewModel {
  final SettingRepository settingRepository;
  SettingViewModelImpl({required this.settingRepository});
  @override
  SettingModel build() => SettingModel();
  @override
  Future<void> getTheme() async =>
      emitState(await settingRepository.readTheme());
  @override
  Future<void> changeTheme({required bool isDarkTheme}) async {
    await settingRepository.updateTheme(isDarkTheme: isDarkTheme);
    emitState(state.copyWith(isDarkTheme: isDarkTheme));
  }
}

// ============================================================
// BOTTOM FEATURE
// ============================================================

class BottomModel {
  final int indexTab;
  const BottomModel({this.indexTab = 0});
}

abstract interface class BottomViewModel extends StateManagement<BottomModel> {
  void updateIndex(int index);
}

class BottomViewModelImpl extends StateManagement<BottomModel>
    implements BottomViewModel {
  @override
  BottomModel build() => const BottomModel();
  @override
  void updateIndex(int index) => emitState(BottomModel(indexTab: index));
}

// ============================================================
// AUTH FEATURE
// ============================================================

class AuthStateModel {
  final bool hasToken;
  final AppState<UserModel> loginState;
  final AppState<UserModel> registerState;
  const AuthStateModel({
    this.hasToken = false,
    this.loginState = const InitialState(),
    this.registerState = const InitialState(),
  });
  AuthStateModel copyWith({
    bool? hasToken,
    AppState<UserModel>? loginState,
    AppState<UserModel>? registerState,
  }) => AuthStateModel(
    hasToken: hasToken ?? this.hasToken,
    loginState: loginState ?? this.loginState,
    registerState: registerState ?? this.registerState,
  );
}

typedef AuthLoginResult = Result<UserModel, AppException>;

abstract interface class AuthRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  });
  Future<AuthLoginResult> register({
    required String name,
    required String email,
    required String password,
  });
  Future<bool> hasToken();
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final ConnectionService connectionService;
  final HttpService httpService;
  final StorageService storageService;
  AuthRepositoryImpl({
    required this.connectionService,
    required this.httpService,
    required this.storageService,
  });

  AppException _map(HttpResult r) {
    if (r.statusCode == 401) return const UnauthorizedException();
    if (r.statusCode == 409)
      return const ConflictException('Email já cadastrado.');
    return ServerException('Erro ${r.statusCode}', r.statusCode);
  }

  @override
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await connectionService.checkConnection();
      if (!connectionService.isConnected)
        return const Error(error: NetworkException());
      final r = await httpService.postData(
        path: ValueConstant.login,
        data: {'email': email, 'password': password},
        useAuth: false,
      );
      if (r.statusCode == 200 && r.data != null) {
        final token = (r.data as Map<String, dynamic>)['accessToken'] as String;
        await storageService.setStringValue(
          key: ValueConstant.tokenKey,
          value: token,
        );
        httpService.setAuthorizationToken(token);
        return Success(value: UserModel(email: email));
      }
      return Error(error: _map(r));
    } on AppException catch (e) {
      return Error(error: e);
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<AuthLoginResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await connectionService.checkConnection();
      if (!connectionService.isConnected)
        return const Error(error: NetworkException());
      final r = await httpService.postData(
        path: ValueConstant.register,
        data: {'name': name, 'email': email, 'password': password},
        useAuth: false,
      );
      if ((r.statusCode == 201 || r.statusCode == 200) && r.data != null)
        return Success(
          value: UserModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } on AppException catch (e) {
      return Error(error: e);
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<bool> hasToken() async {
    final t = await storageService.getStringValue(key: ValueConstant.tokenKey);
    return t != null && t.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await storageService.removeValue(key: ValueConstant.tokenKey);
    httpService.clearAuthorizationToken();
  }
}

abstract interface class AuthViewModel extends StateManagement<AuthStateModel> {
  Future<void> checkToken();
  Future<void> login({required String email, required String password});
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
}

class AuthViewModelImpl extends StateManagement<AuthStateModel>
    implements AuthViewModel {
  final AuthRepository authRepository;
  AuthViewModelImpl({required this.authRepository});
  @override
  AuthStateModel build() => const AuthStateModel();
  @override
  Future<void> checkToken() async {
    emitState(state.copyWith(hasToken: await authRepository.hasToken()));
  }

  @override
  Future<void> login({required String email, required String password}) async {
    emitState(state.copyWith(loginState: const LoadingState()));
    final r = await authRepository.login(email: email, password: password);
    emitState(
      state.copyWith(
        loginState: r.fold(
          onSuccess: (v) => SuccessState(data: v),
          onError: (e) => ErrorState(error: e),
        ),
      ),
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emitState(state.copyWith(registerState: const LoadingState()));
    final r = await authRepository.register(
      name: name,
      email: email,
      password: password,
    );
    emitState(
      state.copyWith(
        registerState: r.fold(
          onSuccess: (v) => SuccessState(data: v),
          onError: (e) => ErrorState(error: e),
        ),
      ),
    );
  }

  @override
  Future<void> logout() async {
    await authRepository.logout();
    emitState(const AuthStateModel());
  }
}

// ============================================================
// BIKE FEATURE
// ============================================================

typedef BikeState = AppState<List<BikeModel>>;
typedef BikeResult = Result<BikeModel, AppException>;

abstract interface class BikeRepository {
  Future<Result<List<BikeModel>, AppException>> findAll();
  Future<BikeResult> create({
    required String nickname,
    required String brand,
    required String model,
    String? photoBase64,
  });
  Future<BikeResult> update({
    required int id,
    String? nickname,
    String? brand,
    String? model,
    String? photoBase64,
  });
  Future<Result<bool, AppException>> delete({required int id});
}

class BikeRepositoryImpl implements BikeRepository {
  final HttpService httpService;
  BikeRepositoryImpl({required this.httpService});
  AppException _map(HttpResult r) {
    if (r.statusCode == 401) return const UnauthorizedException();
    if (r.statusCode == 404)
      return const NotFoundAppException('Bicicleta não encontrada.');
    return ServerException('Erro ${r.statusCode}', r.statusCode);
  }

  @override
  Future<Result<List<BikeModel>, AppException>> findAll() async {
    try {
      final r = await httpService.getData(path: ValueConstant.bikes);
      if (r.statusCode == 200 && r.data != null)
        return Success(
          value: (r.data as List)
              .map((e) => BikeModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<BikeResult> create({
    required String nickname,
    required String brand,
    required String model,
    String? photoBase64,
  }) async {
    try {
      final r = await httpService.postData(
        path: ValueConstant.bikes,
        data: {
          'nickname': nickname,
          'brand': brand,
          'model': model,
          'photoBase64': photoBase64,
        },
      );
      if (r.statusCode == 201 && r.data != null)
        return Success(
          value: BikeModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<BikeResult> update({
    required int id,
    String? nickname,
    String? brand,
    String? model,
    String? photoBase64,
  }) async {
    try {
      final r = await httpService.putData(
        path: ValueConstant.bike(id),
        data: {
          'nickname': nickname,
          'brand': brand,
          'model': model,
          'photoBase64': photoBase64,
        },
      );
      if (r.statusCode == 200 && r.data != null)
        return Success(
          value: BikeModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<Result<bool, AppException>> delete({required int id}) async {
    try {
      final r = await httpService.deleteData(path: ValueConstant.bike(id));
      if (r.statusCode == 204) return const Success(value: true);
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }
}

abstract interface class BikeViewModel extends StateManagement<BikeState> {
  int? get selectedBikeId;
  BikeModel? get selectedBike;
  Future<void> loadBikes();
  void selectBike(int id);
  Future<BikeResult> createBike({
    required String nickname,
    required String brand,
    required String model,
    String? photoBase64,
  });
  Future<void> deleteBike({required int id});
}

class BikeViewModelImpl extends StateManagement<BikeState>
    implements BikeViewModel {
  final BikeRepository bikeRepository;
  int? _selectedBikeId;
  BikeViewModelImpl({required this.bikeRepository});
  @override
  BikeState build() => const InitialState();
  @override
  int? get selectedBikeId => _selectedBikeId;
  @override
  BikeModel? get selectedBike {
    if (state is! SuccessState<List<BikeModel>>) return null;
    final bikes = (state as SuccessState<List<BikeModel>>).data;
    try {
      return bikes.firstWhere((b) => b.id == _selectedBikeId);
    } catch (_) {
      return bikes.isNotEmpty ? bikes.first : null;
    }
  }

  @override
  Future<void> loadBikes() async {
    emitState(const LoadingState());
    final r = await bikeRepository.findAll();
    emitState(
      r.fold(
        onSuccess: (bikes) {
          if (_selectedBikeId == null && bikes.isNotEmpty)
            _selectedBikeId = bikes.first.id;
          return SuccessState(data: bikes);
        },
        onError: (e) => ErrorState(error: e),
      ),
    );
  }

  @override
  void selectBike(int id) {
    _selectedBikeId = id;
    notifyListeners();
  }

  @override
  Future<BikeResult> createBike({
    required String nickname,
    required String brand,
    required String model,
    String? photoBase64,
  }) async {
    final r = await bikeRepository.create(
      nickname: nickname,
      brand: brand,
      model: model,
      photoBase64: photoBase64,
    );
    if (r is Success) await loadBikes();
    return r;
  }

  @override
  Future<void> deleteBike({required int id}) async {
    await bikeRepository.delete(id: id);
    if (_selectedBikeId == id) _selectedBikeId = null;
    await loadBikes();
  }
}

// ============================================================
// RIDE FEATURE
// ============================================================

typedef RideState = AppState<List<RideModel>>;

abstract interface class RideRepository {
  Future<Result<List<RideModel>, AppException>> findAll({required int bikeId});
  Future<Result<RideModel, AppException>> create({
    required int bikeId,
    required double distanceKm,
    required String terrain,
    DateTime? riddenAt,
  });
}

class RideRepositoryImpl implements RideRepository {
  final HttpService httpService;
  RideRepositoryImpl({required this.httpService});
  AppException _map(HttpResult r) {
    if (r.statusCode == 401) return const UnauthorizedException();
    return ServerException('Erro ${r.statusCode}', r.statusCode);
  }

  @override
  Future<Result<List<RideModel>, AppException>> findAll({
    required int bikeId,
  }) async {
    try {
      final r = await httpService.getData(path: ValueConstant.rides(bikeId));
      if (r.statusCode == 200 && r.data != null)
        return Success(
          value: (r.data as List)
              .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<Result<RideModel, AppException>> create({
    required int bikeId,
    required double distanceKm,
    required String terrain,
    DateTime? riddenAt,
  }) async {
    try {
      final r = await httpService.postData(
        path: ValueConstant.rides(bikeId),
        data: {
          'distanceKm': distanceKm,
          'terrain': terrain,
          'riddenAt': (riddenAt ?? DateTime.now()).toIso8601String(),
        },
      );
      if (r.statusCode == 201 && r.data != null)
        return Success(
          value: RideModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }
}

abstract interface class RideViewModel extends StateManagement<RideState> {
  Future<void> loadRides({required int bikeId});
  Future<Result<RideModel, AppException>> createRide({
    required int bikeId,
    required double distanceKm,
    required String terrain,
    DateTime? riddenAt,
  });
}

class RideViewModelImpl extends StateManagement<RideState>
    implements RideViewModel {
  final RideRepository rideRepository;
  RideViewModelImpl({required this.rideRepository});
  @override
  RideState build() => const InitialState();
  @override
  Future<void> loadRides({required int bikeId}) async {
    emitState(const LoadingState());
    final r = await rideRepository.findAll(bikeId: bikeId);
    emitState(
      r.fold(
        onSuccess: (v) => SuccessState(data: v),
        onError: (e) => ErrorState(error: e),
      ),
    );
  }

  @override
  Future<Result<RideModel, AppException>> createRide({
    required int bikeId,
    required double distanceKm,
    required String terrain,
    DateTime? riddenAt,
  }) async {
    final r = await rideRepository.create(
      bikeId: bikeId,
      distanceKm: distanceKm,
      terrain: terrain,
      riddenAt: riddenAt,
    );
    if (r is Success) await loadRides(bikeId: bikeId);
    return r;
  }
}

// ============================================================
// PART FEATURE
// ============================================================

typedef PartState = AppState<List<PartModel>>;

abstract interface class PartRepository {
  Future<Result<List<PartModel>, AppException>> findAll({required int bikeId});
  Future<Result<PartModel, AppException>> create({
    required int bikeId,
    required String name,
    required double expectedDurationKm,
    required double pricePaid,
    DateTime? installedAt,
  });
  Future<Result<PartExchangeModel, AppException>> exchange({
    required int bikeId,
    required int partId,
    String? notes,
  });
}

class PartRepositoryImpl implements PartRepository {
  final HttpService httpService;
  PartRepositoryImpl({required this.httpService});
  AppException _map(HttpResult r) {
    if (r.statusCode == 401) return const UnauthorizedException();
    if (r.statusCode == 409)
      return const ConflictException('Peça já foi trocada.');
    return ServerException('Erro ${r.statusCode}', r.statusCode);
  }

  @override
  Future<Result<List<PartModel>, AppException>> findAll({
    required int bikeId,
  }) async {
    try {
      final r = await httpService.getData(path: ValueConstant.parts(bikeId));
      if (r.statusCode == 200 && r.data != null)
        return Success(
          value: (r.data as List)
              .map((e) => PartModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<Result<PartModel, AppException>> create({
    required int bikeId,
    required String name,
    required double expectedDurationKm,
    required double pricePaid,
    DateTime? installedAt,
  }) async {
    try {
      final r = await httpService.postData(
        path: ValueConstant.parts(bikeId),
        data: {
          'name': name,
          'expectedDurationKm': expectedDurationKm,
          'pricePaid': pricePaid,
          'installedAt': (installedAt ?? DateTime.now()).toIso8601String(),
        },
      );
      if (r.statusCode == 201 && r.data != null)
        return Success(
          value: PartModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<Result<PartExchangeModel, AppException>> exchange({
    required int bikeId,
    required int partId,
    String? notes,
  }) async {
    try {
      final r = await httpService.postData(
        path: ValueConstant.exchangePart(bikeId, partId),
        data: {'notes': notes},
      );
      if (r.statusCode == 201 && r.data != null)
        return Success(
          value: PartExchangeModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }
}

abstract interface class PartViewModel extends StateManagement<PartState> {
  Future<void> loadParts({required int bikeId});
  Future<Result<PartModel, AppException>> createPart({
    required int bikeId,
    required String name,
    required double expectedDurationKm,
    required double pricePaid,
    DateTime? installedAt,
  });
  Future<Result<PartExchangeModel, AppException>> exchangePart({
    required int bikeId,
    required int partId,
    String? notes,
  });
}

class PartViewModelImpl extends StateManagement<PartState>
    implements PartViewModel {
  final PartRepository partRepository;
  PartViewModelImpl({required this.partRepository});
  @override
  PartState build() => const InitialState();
  @override
  Future<void> loadParts({required int bikeId}) async {
    emitState(const LoadingState());
    final r = await partRepository.findAll(bikeId: bikeId);
    emitState(
      r.fold(
        onSuccess: (v) => SuccessState(data: v),
        onError: (e) => ErrorState(error: e),
      ),
    );
  }

  @override
  Future<Result<PartModel, AppException>> createPart({
    required int bikeId,
    required String name,
    required double expectedDurationKm,
    required double pricePaid,
    DateTime? installedAt,
  }) async {
    final r = await partRepository.create(
      bikeId: bikeId,
      name: name,
      expectedDurationKm: expectedDurationKm,
      pricePaid: pricePaid,
      installedAt: installedAt,
    );
    if (r is Success) await loadParts(bikeId: bikeId);
    return r;
  }

  @override
  Future<Result<PartExchangeModel, AppException>> exchangePart({
    required int bikeId,
    required int partId,
    String? notes,
  }) async {
    final r = await partRepository.exchange(
      bikeId: bikeId,
      partId: partId,
      notes: notes,
    );
    if (r is Success) await loadParts(bikeId: bikeId);
    return r;
  }
}

// ============================================================
// HISTORY FEATURE
// ============================================================

typedef HistoryState = AppState<HistoryModel>;

abstract interface class HistoryRepository {
  Future<Result<HistoryModel, AppException>> findAll({required int bikeId});
  Future<Result<ChecklistModel, AppException>> createChecklist({
    required int bikeId,
    required String itemsChecked,
    String? notes,
    DateTime? executedAt,
  });
}

class HistoryRepositoryImpl implements HistoryRepository {
  final HttpService httpService;
  HistoryRepositoryImpl({required this.httpService});
  AppException _map(HttpResult r) {
    if (r.statusCode == 401) return const UnauthorizedException();
    return ServerException('Erro ${r.statusCode}', r.statusCode);
  }

  @override
  Future<Result<HistoryModel, AppException>> findAll({
    required int bikeId,
  }) async {
    try {
      final r = await httpService.getData(path: ValueConstant.history(bikeId));
      if (r.statusCode == 200 && r.data != null)
        return Success(
          value: HistoryModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }

  @override
  Future<Result<ChecklistModel, AppException>> createChecklist({
    required int bikeId,
    required String itemsChecked,
    String? notes,
    DateTime? executedAt,
  }) async {
    try {
      final r = await httpService.postData(
        path: ValueConstant.checklists(bikeId),
        data: {
          'itemsChecked': itemsChecked,
          'notes': notes,
          'executedAt': (executedAt ?? DateTime.now()).toIso8601String(),
        },
      );
      if ((r.statusCode == 201 || r.statusCode == 200) && r.data != null)
        return Success(
          value: ChecklistModel.fromJson(r.data as Map<String, dynamic>),
        );
      return Error(error: _map(r));
    } catch (e) {
      return Error(error: UnknownException('$e'));
    }
  }
}

abstract interface class HistoryViewModel
    extends StateManagement<HistoryState> {
  Future<void> loadHistory({required int bikeId});
  Future<Result<ChecklistModel, AppException>> createChecklist({
    required int bikeId,
    required String itemsChecked,
    String? notes,
  });
}

class HistoryViewModelImpl extends StateManagement<HistoryState>
    implements HistoryViewModel {
  final HistoryRepository historyRepository;
  HistoryViewModelImpl({required this.historyRepository});
  @override
  HistoryState build() => const InitialState();
  @override
  Future<void> loadHistory({required int bikeId}) async {
    emitState(const LoadingState());
    final r = await historyRepository.findAll(bikeId: bikeId);
    emitState(
      r.fold(
        onSuccess: (v) => SuccessState(data: v),
        onError: (e) => ErrorState(error: e),
      ),
    );
  }

  @override
  Future<Result<ChecklistModel, AppException>> createChecklist({
    required int bikeId,
    required String itemsChecked,
    String? notes,
  }) async {
    final r = await historyRepository.createChecklist(
      bikeId: bikeId,
      itemsChecked: itemsChecked,
      notes: notes,
    );
    if (r is Success) await loadHistory(bikeId: bikeId);
    return r;
  }
}

// ============================================================
// HELPERS
// ============================================================

Color _progressColor(double percent) {
  if (percent >= 90) return AppTheme.danger;
  if (percent >= 70) return AppTheme.warning;
  return AppTheme.primary;
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

String _terrainLabel(String t) => switch (t.toLowerCase()) {
  'seco' => '☀️ Seco',
  'chuva' => '🌧 Chuva',
  'lama' => '💧 Lama',
  'trilha' => '⛰️ Trilha',
  'asfalto' => '🏙️ Asfalto',
  _ => t,
};

void _showSnack(BuildContext ctx, String msg, {SnackBarAction? action}) =>
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(content: Text(msg), action: action));

Widget _darkCard({
  required Widget child,
  double opacity = 0.07,
  BorderRadius? radius,
}) => Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: radius ?? BorderRadius.circular(16),
  ),
  child: child,
);

// ============================================================
// SPLASH VIEW
// ============================================================

class SplashView extends StatefulWidget {
  final AuthViewModel authViewModel;
  const SplashView({super.key, required this.authViewModel});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.authViewModel.checkToken();
      if (!mounted) return;
      if (widget.authViewModel.state.hasToken) {
        context.go(BottomRoutes.bottom);
      } else {
        context.go(AuthRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pedal_bike, size: 44, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Text(
            'PedalTrack',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.txtPrimDark,
            ),
          ),
          const SizedBox(height: 40),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// LOGIN VIEW
// ============================================================

class LoginAuthView extends StatefulWidget {
  final AuthViewModel authViewModel;
  const LoginAuthView({super.key, required this.authViewModel});
  @override
  State<LoginAuthView> createState() => _LoginAuthViewState();
}

class _LoginAuthViewState extends State<LoginAuthView> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await widget.authViewModel.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    final s = widget.authViewModel.state.loginState;
    if (s is SuccessState<UserModel>) {
      context.go(BottomRoutes.bottom);
    } else if (s is ErrorState<UserModel>) {
      _showSnack(context, s.error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AuthRoutes.register),
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: AppTheme.txtSecDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pedal_bike,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bem-vindo de volta',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.txtPrimDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entre para continuar',
                      style: TextStyle(
                        color: AppTheme.txtSecDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppTheme.txtPrimDark),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        fillColor: AppTheme.surfDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: TextStyle(color: AppTheme.txtPrimDark),
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        fillColor: AppTheme.surfDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.txtSecDark,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            color: AppTheme.txtSecDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StateBuilderWidget<AuthViewModel, AuthStateModel>(
                      viewModel: widget.authViewModel,
                      builder: (_, s) {
                        final loading = s.loginState is LoadingState;
                        return ElevatedButton(
                          onPressed: loading ? null : _login,
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Entrar'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// REGISTER VIEW
// ============================================================

class RegisterAuthView extends StatefulWidget {
  final AuthViewModel authViewModel;
  const RegisterAuthView({super.key, required this.authViewModel});
  @override
  State<RegisterAuthView> createState() => _RegisterAuthViewState();
}

class _RegisterAuthViewState extends State<RegisterAuthView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      _showSnack(context, 'As senhas não coincidem.');
      return;
    }
    await widget.authViewModel.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    final s = widget.authViewModel.state.registerState;
    if (s is SuccessState<UserModel>) {
      _showSnack(context, 'Conta criada! Faça login.');
      context.go(AuthRoutes.login);
    } else if (s is ErrorState<UserModel>) {
      _showSnack(context, s.error.message);
    }
  }

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        style: TextStyle(color: AppTheme.txtPrimDark),
        decoration: InputDecoration(
          hintText: hint,
          fillColor: AppTheme.surfDark,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.txtPrimDark,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Criar conta',
        style: TextStyle(
          color: AppTheme.txtPrimDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 24),
        _field(_nameCtrl, 'Nome completo'),
        const SizedBox(height: 16),
        _field(_emailCtrl, 'Email'),
        const SizedBox(height: 16),
        _field(_passCtrl, 'Senha', obscure: true),
        const SizedBox(height: 16),
        _field(_confirmCtrl, 'Confirmar senha', obscure: true),
        const SizedBox(height: 28),
        StateBuilderWidget<AuthViewModel, AuthStateModel>(
          viewModel: widget.authViewModel,
          builder: (_, s) {
            final loading = s.registerState is LoadingState;
            return ElevatedButton(
              onPressed: loading ? null : _register,
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Criar conta'),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}

// ============================================================
// BOTTOM VIEW
// ============================================================

class BottomView extends StatefulWidget {
  final BottomViewModel bottomViewModel;
  final SettingViewModel settingViewModel;
  final BikeViewModel bikeViewModel;
  final RideViewModel rideViewModel;
  final PartViewModel partViewModel;
  final HistoryViewModel historyViewModel;

  const BottomView({
    super.key,
    required this.bottomViewModel,
    required this.settingViewModel,
    required this.bikeViewModel,
    required this.rideViewModel,
    required this.partViewModel,
    required this.historyViewModel,
  });

  @override
  State<BottomView> createState() => _BottomViewState();
}

class _BottomViewState extends State<BottomView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.bikeViewModel.loadBikes();
      final id = widget.bikeViewModel.selectedBikeId;
      if (id != null) {
        await Future.wait([
          widget.partViewModel.loadParts(bikeId: id),
          widget.rideViewModel.loadRides(bikeId: id),
          widget.historyViewModel.loadHistory(bikeId: id),
        ]);
      }
    });
  }

  List<Widget> get _views => [
    HomeView(
      bikeViewModel: widget.bikeViewModel,
      partViewModel: widget.partViewModel,
      rideViewModel: widget.rideViewModel,
      bottomViewModel: widget.bottomViewModel,
    ),
    BikesView(
      bikeViewModel: widget.bikeViewModel,
      partViewModel: widget.partViewModel,
      rideViewModel: widget.rideViewModel,
      historyViewModel: widget.historyViewModel,
    ),
    MaintenanceView(
      bikeViewModel: widget.bikeViewModel,
      partViewModel: widget.partViewModel,
      historyViewModel: widget.historyViewModel,
    ),
    RecordsView(
      bikeViewModel: widget.bikeViewModel,
      rideViewModel: widget.rideViewModel,
      historyViewModel: widget.historyViewModel,
    ),
    ProfileView(
      settingViewModel: widget.settingViewModel,
      authViewModel: locator<AuthViewModel>(),
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      StateBuilderWidget<BottomViewModel, BottomModel>(
        viewModel: widget.bottomViewModel,
        builder: (_, s) => Scaffold(
          body: _views[s.indexTab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: s.indexTab,
            onDestinationSelected: widget.bottomViewModel.updateIndex,
            animationDuration: const Duration(milliseconds: 400),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.pedal_bike_outlined),
                selectedIcon: Icon(Icons.pedal_bike),
                label: 'Bicicletas',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: 'Manutenção',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Registros',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      );
}

// ============================================================
// HOME VIEW
// ============================================================

class HomeView extends StatelessWidget {
  final BikeViewModel bikeViewModel;
  final PartViewModel partViewModel;
  final RideViewModel rideViewModel;
  final BottomViewModel bottomViewModel;

  const HomeView({
    super.key,
    required this.bikeViewModel,
    required this.partViewModel,
    required this.rideViewModel,
    required this.bottomViewModel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      centerTitle: false,
      title: StateBuilderWidget<BikeViewModel, BikeState>(
        viewModel: bikeViewModel,
        builder: (_, s) {
          final name = bikeViewModel.selectedBike?.nickname ?? 'PedalTrack';
          return Text(
            'Olá 👋  $name',
            style: TextStyle(
              color: AppTheme.txtPrimDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline, color: AppTheme.txtSecDark),
          onPressed: () => bottomViewModel.updateIndex(4),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        await bikeViewModel.loadBikes();
        final id = bikeViewModel.selectedBikeId;
        if (id != null) {
          await partViewModel.loadParts(bikeId: id);
          await rideViewModel.loadRides(bikeId: id);
        }
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            StateBuilderWidget<PartViewModel, PartState>(
              viewModel: partViewModel,
              builder: (_, s) {
                final parts = s is SuccessState<List<PartModel>>
                    ? s.data
                    : <PartModel>[];
                final hasCritical = parts.any(
                  (p) =>
                      p.status == PartStatus.active &&
                      (p.progressPercent ?? 0) >= 90,
                );
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasCritical
                                  ? 'Atenção necessária!'
                                  : 'Manutenção em dia!',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.txtPrimDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasCritical
                                  ? 'Algumas peças precisam de atenção.'
                                  : 'Sua bike está pronta para pedalar.',
                              style: TextStyle(
                                color: AppTheme.txtSecDark,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasCritical
                              ? Icons.warning_amber_rounded
                              : Icons.task_alt,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Stats
            StateBuilderWidget<BikeViewModel, BikeState>(
              viewModel: bikeViewModel,
              builder: (_, s) {
                final bike = bikeViewModel.selectedBike;
                return StateBuilderWidget<RideViewModel, RideState>(
                  viewModel: rideViewModel,
                  builder: (_, rs) {
                    final rides = rs is SuccessState<List<RideModel>>
                        ? rs.data
                        : <RideModel>[];
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.route,
                            title: 'Total km',
                            value:
                                '${(bike?.totalKmRidden ?? 0).toStringAsFixed(0)} km',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pedal_bike,
                            title: 'Passeios',
                            value: '${rides.length}',
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Peças críticas
            StateBuilderWidget<PartViewModel, PartState>(
              viewModel: partViewModel,
              builder: (_, s) {
                if (s is! SuccessState<List<PartModel>>)
                  return const SizedBox.shrink();
                final critical = s.data
                    .where(
                      (p) =>
                          p.status == PartStatus.active &&
                          (p.progressPercent ?? 0) >= 80,
                    )
                    .toList();
                if (critical.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Peças em atenção',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppTheme.txtPrimDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${critical.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...critical.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PartProgressCard(part: p),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            // Bikes carrossel
            StateBuilderWidget<BikeViewModel, BikeState>(
              viewModel: bikeViewModel,
              builder: (_, s) {
                if (s is! SuccessState<List<BikeModel>>)
                  return const SizedBox.shrink();
                final bikes = s.data;
                if (bikes.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas Bicicletas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppTheme.txtPrimDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: bikes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) => _HomeBikeCard(
                          bike: bikes[i],
                          isSelected:
                              bikes[i].id == bikeViewModel.selectedBikeId,
                          onTap: () async {
                            bikeViewModel.selectBike(bikes[i].id!);
                            await partViewModel.loadParts(bikeId: bikes[i].id!);
                            await rideViewModel.loadRides(bikeId: bikes[i].id!);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showFabSheet(context),
      child: const Icon(Icons.add),
    ),
  );

  void _showFabSheet(BuildContext ctx) {
    final bikeId = bikeViewModel.selectedBikeId;
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppTheme.surfDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.directions_bike_outlined,
                color: AppTheme.primary,
              ),
              title: Text(
                'Registrar passeio',
                style: TextStyle(color: AppTheme.txtPrimDark),
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (bikeId != null)
                  _showRideSheet(ctx, bikeId);
                else
                  _showSnack(ctx, 'Selecione uma bicicleta.');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: AppTheme.primary),
              title: Text(
                'Instalar peça',
                style: TextStyle(color: AppTheme.txtPrimDark),
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (bikeId != null)
                  _showPartSheet(ctx, bikeId);
                else
                  _showSnack(ctx, 'Selecione uma bicicleta.');
              },
            ),
            ListTile(
              leading: Icon(Icons.pedal_bike_outlined, color: AppTheme.primary),
              title: Text(
                'Adicionar bicicleta',
                style: TextStyle(color: AppTheme.txtPrimDark),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showAddBikeSheet(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRideSheet(BuildContext ctx, int bikeId) =>
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _RegisterRideSheet(
          bikeId: bikeId,
          rideViewModel: rideViewModel,
          onSaved: () {
            if (ctx.mounted) _showSnack(ctx, 'Passeio registrado!');
          },
        ),
      );

  void _showPartSheet(BuildContext ctx, int bikeId) =>
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _InstallPartSheet(
          bikeId: bikeId,
          partViewModel: partViewModel,
          onSaved: () {
            if (ctx.mounted) _showSnack(ctx, 'Peça instalada.');
          },
        ),
      );

  void _showAddBikeSheet(BuildContext ctx) => showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: AppTheme.surfDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddBikeSheet(
      bikeViewModel: bikeViewModel,
      onSaved: () {
        if (ctx.mounted) _showSnack(ctx, 'Bicicleta adicionada!');
      },
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => _darkCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.txtSecDark),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: AppTheme.txtSecDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.txtPrimDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeBikeCard extends StatelessWidget {
  final BikeModel bike;
  final bool isSelected;
  final VoidCallback onTap;
  const _HomeBikeCard({
    required this.bike,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfDark2,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppTheme.primary, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: bike.photoBase64 != null
                ? Image.memory(
                    base64Decode(bike.photoBase64!.split(',').last),
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 110,
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    child: Center(
                      child: Icon(
                        Icons.pedal_bike,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike.nickname ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.txtPrimDark,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${bike.brand ?? ''} ${bike.model ?? ''}',
                  style: TextStyle(fontSize: 12, color: AppTheme.txtSecDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ============================================================
// BIKES VIEW
// ============================================================

class BikesView extends StatelessWidget {
  final BikeViewModel bikeViewModel;
  final PartViewModel partViewModel;
  final RideViewModel rideViewModel;
  final HistoryViewModel historyViewModel;
  const BikesView({
    super.key,
    required this.bikeViewModel,
    required this.partViewModel,
    required this.rideViewModel,
    required this.historyViewModel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      title: Text(
        'Minhas Bicicletas',
        style: TextStyle(color: AppTheme.txtPrimDark),
      ),
    ),
    body: StateBuilderWidget<BikeViewModel, BikeState>(
      viewModel: bikeViewModel,
      builder: (ctx, s) => switch (s) {
        InitialState() => const SizedBox.shrink(),
        LoadingState() => Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        SuccessState(data: final bikes) =>
          bikes.isEmpty
              ? _EmptyState(
                  icon: Icons.pedal_bike_outlined,
                  message: 'Nenhuma bicicleta.\nToque em + para adicionar.',
                )
              : RefreshIndicator(
                  onRefresh: bikeViewModel.loadBikes,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surfDark,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bikes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _BikeListCard(
                      bike: bikes[i],
                      onTap: () async {
                        bikeViewModel.selectBike(bikes[i].id!);
                        await partViewModel.loadParts(bikeId: bikes[i].id!);
                        await rideViewModel.loadRides(bikeId: bikes[i].id!);
                        await historyViewModel.loadHistory(
                          bikeId: bikes[i].id!,
                        );
                        if (ctx.mounted)
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => BikeDetailView(
                                bike: bikes[i],
                                partViewModel: partViewModel,
                                rideViewModel: rideViewModel,
                              ),
                            ),
                          );
                      },
                      onDelete: () async {
                        await bikeViewModel.deleteBike(id: bikes[i].id!);
                        if (ctx.mounted) _showSnack(ctx, 'Bicicleta removida.');
                      },
                    ),
                  ),
                ),
        ErrorState(error: final e) => Center(
          child: Text(e.message, style: TextStyle(color: AppTheme.txtSecDark)),
        ),
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _AddBikeSheet(
          bikeViewModel: bikeViewModel,
          onSaved: () {
            if (context.mounted) _showSnack(context, 'Bicicleta adicionada!');
          },
        ),
      ),
      child: const Icon(Icons.add),
    ),
  );
}

class _BikeListCard extends StatelessWidget {
  final BikeModel bike;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _BikeListCard({
    required this.bike,
    required this.onTap,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final critical = bike.criticalParts;
    return GestureDetector(
      onTap: onTap,
      child: _darkCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: bike.photoBase64 != null
                        ? Image.memory(
                            base64Decode(bike.photoBase64!.split(',').last),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.pedal_bike,
                              color: AppTheme.primary,
                              size: 36,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bike.nickname ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.txtPrimDark,
                          ),
                        ),
                        Text(
                          '${bike.brand ?? ''} ${bike.model ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.txtSecDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bike.totalKmRidden.toStringAsFixed(0)} km acumulados',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.danger.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (critical.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${critical.length} peça(s) precisam de atenção',
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BIKE DETAIL VIEW
// ============================================================

class BikeDetailView extends StatelessWidget {
  final BikeModel bike;
  final PartViewModel partViewModel;
  final RideViewModel rideViewModel;
  const BikeDetailView({
    super.key,
    required this.bike,
    required this.partViewModel,
    required this.rideViewModel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_outlined,
          color: AppTheme.txtPrimDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        bike.nickname ?? '',
        style: TextStyle(color: AppTheme.txtPrimDark),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Foto circular
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfDark2,
            ),
            clipBehavior: Clip.antiAlias,
            child: bike.photoBase64 != null
                ? Image.memory(
                    base64Decode(bike.photoBase64!.split(',').last),
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.pedal_bike, size: 60, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          bike.nickname ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppTheme.txtPrimDark,
          ),
        ),
        Text(
          '${bike.brand ?? ''} · ${bike.model ?? ''}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.txtSecDark),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route,
                title: 'Km acumulados',
                value: '${bike.totalKmRidden.toStringAsFixed(0)} km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.settings_outlined,
                title: 'Peças ativas',
                value:
                    '${bike.parts.where((p) => p.status == PartStatus.active).length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Peças',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 12),
        StateBuilderWidget<PartViewModel, PartState>(
          viewModel: partViewModel,
          builder: (ctx, s) {
            if (s is! SuccessState<List<PartModel>>)
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            final parts = s.data.where((p) => p.bikeId == bike.id).toList();
            if (parts.isEmpty)
              return _EmptyState(
                icon: Icons.settings_outlined,
                message: 'Nenhuma peça instalada.',
              );
            return Column(
              children: parts
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PartProgressCard(
                        part: p,
                        trailing: p.status == PartStatus.active
                            ? TextButton(
                                onPressed: () =>
                                    _showExchangeSheet(ctx, bike.id!, p),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Trocar',
                                  style: TextStyle(fontSize: 13),
                                ),
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Últimos passeios',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 12),
        StateBuilderWidget<RideViewModel, RideState>(
          viewModel: rideViewModel,
          builder: (_, s) {
            if (s is! SuccessState<List<RideModel>>)
              return const SizedBox.shrink();
            final rides = s.data
                .where((r) => r.bikeId == bike.id)
                .take(5)
                .toList();
            if (rides.isEmpty)
              return _EmptyState(
                icon: Icons.history,
                message: 'Nenhum passeio.',
              );
            return Column(
              children: rides
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RideListItem(ride: r),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.surfDark,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _InstallPartSheet(
              bikeId: bike.id!,
              partViewModel: partViewModel,
              onSaved: () {
                if (context.mounted) _showSnack(context, 'Peça instalada.');
              },
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Instalar peça'),
        ),
        const SizedBox(height: 80),
      ],
    ),
  );

  void _showExchangeSheet(BuildContext ctx, int bikeId, PartModel part) =>
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _ExchangePartSheet(
          bikeId: bikeId,
          part: part,
          partViewModel: partViewModel,
          onSaved: () {
            if (ctx.mounted) _showSnack(ctx, 'Peça trocada.');
          },
        ),
      );
}

// ============================================================
// MAINTENANCE VIEW
// ============================================================

class MaintenanceView extends StatelessWidget {
  final BikeViewModel bikeViewModel;
  final PartViewModel partViewModel;
  final HistoryViewModel historyViewModel;
  const MaintenanceView({
    super.key,
    required this.bikeViewModel,
    required this.partViewModel,
    required this.historyViewModel,
  });

  static const List<String> _items = [
    'corrente',
    'pneus',
    'freios',
    'câmbio',
    'iluminação',
    'pedal',
    'banco',
    'chassi',
    'cubo/aro',
    'cabos',
  ];
  static const Map<String, IconData> _icons = {
    'corrente': Icons.link,
    'pneus': Icons.tire_repair,
    'freios': Icons.disc_full,
    'câmbio': Icons.settings_input_component,
    'iluminação': Icons.light_mode_outlined,
    'pedal': Icons.directions_bike,
    'banco': Icons.event_seat_outlined,
    'chassi': Icons.architecture,
    'cubo/aro': Icons.circle_outlined,
    'cabos': Icons.cable,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      title: Text('Manutenção', style: TextStyle(color: AppTheme.txtPrimDark)),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        Text(
          'Desgaste das Peças',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 12),
        StateBuilderWidget<PartViewModel, PartState>(
          viewModel: partViewModel,
          builder: (ctx, s) {
            if (s is LoadingState)
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            if (s is! SuccessState<List<PartModel>>)
              return _EmptyState(
                icon: Icons.settings_outlined,
                message: 'Selecione uma bicicleta.',
              );
            final parts = s.data
                .where((p) => p.status == PartStatus.active)
                .toList();
            if (parts.isEmpty)
              return _EmptyState(
                icon: Icons.settings_outlined,
                message: 'Nenhuma peça instalada.',
              );
            return Column(
              children: parts
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PartProgressCard(
                        part: p,
                        trailing: TextButton(
                          onPressed: () {
                            final bikeId = bikeViewModel.selectedBikeId;
                            if (bikeId == null) return;
                            showModalBottomSheet<void>(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: AppTheme.surfDark,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => _ExchangePartSheet(
                                bikeId: bikeId,
                                part: p,
                                partViewModel: partViewModel,
                                onSaved: () {
                                  if (ctx.mounted)
                                    _showSnack(ctx, 'Peça trocada.');
                                },
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Trocar',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Checklist de Manutenção',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.txtPrimDark,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showChecklistSheet(context),
              icon: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primary,
                size: 18,
              ),
              label: Text(
                'Executar',
                style: TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._items.map(
          (item) => _MaintenanceItemTile(
            icon: _icons[item] ?? Icons.build_outlined,
            title: item[0].toUpperCase() + item.substring(1),
          ),
        ),
        const SizedBox(height: 80),
      ],
    ),
  );

  void _showChecklistSheet(BuildContext ctx) {
    final bikeId = bikeViewModel.selectedBikeId;
    if (bikeId == null) {
      _showSnack(ctx, 'Selecione uma bicicleta primeiro.');
      return;
    }
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChecklistSheet(
        bikeId: bikeId,
        historyViewModel: historyViewModel,
        checklistItems: _items,
        onSaved: () {
          if (ctx.mounted) _showSnack(ctx, 'Checklist salvo!');
        },
      ),
    );
  }
}

class _MaintenanceItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  const _MaintenanceItemTile({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _darkCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.txtPrimDark,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.txtSecDark,
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// RECORDS VIEW
// ============================================================

class RecordsView extends StatefulWidget {
  final BikeViewModel bikeViewModel;
  final RideViewModel rideViewModel;
  final HistoryViewModel historyViewModel;
  const RecordsView({
    super.key,
    required this.bikeViewModel,
    required this.rideViewModel,
    required this.historyViewModel,
  });
  @override
  State<RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<RecordsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      title: Text('Registros', style: TextStyle(color: AppTheme.txtPrimDark)),
      bottom: TabBar(
        controller: _tab,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.txtSecDark,
        indicatorColor: AppTheme.primary,
        tabs: const [
          Tab(text: 'Passeios'),
          Tab(text: 'Trocas'),
          Tab(text: 'Checklists'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        // Passeios
        StateBuilderWidget<RideViewModel, RideState>(
          viewModel: widget.rideViewModel,
          builder: (_, s) => switch (s) {
            InitialState() || LoadingState() => Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
            SuccessState(data: final rides) =>
              rides.isEmpty
                  ? _EmptyState(
                      icon: Icons.history,
                      message: 'Nenhum passeio registrado.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final id = widget.bikeViewModel.selectedBikeId;
                        if (id != null)
                          await widget.rideViewModel.loadRides(bikeId: id);
                      },
                      color: AppTheme.primary,
                      backgroundColor: AppTheme.surfDark,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: rides.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RideListItem(ride: rides[i]),
                      ),
                    ),
            ErrorState(error: final e) => Center(
              child: Text(
                e.message,
                style: TextStyle(color: AppTheme.txtSecDark),
              ),
            ),
          },
        ),
        // Trocas
        StateBuilderWidget<HistoryViewModel, HistoryState>(
          viewModel: widget.historyViewModel,
          builder: (_, s) {
            if (s is! SuccessState<HistoryModel>)
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            final ex = s.data.partExchanges;
            if (ex.isEmpty)
              return _EmptyState(
                icon: Icons.sync_alt,
                message: 'Nenhuma troca registrada.',
              );
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ex.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ExchangeListItem(exchange: ex[i]),
            );
          },
        ),
        // Checklists
        StateBuilderWidget<HistoryViewModel, HistoryState>(
          viewModel: widget.historyViewModel,
          builder: (_, s) {
            if (s is! SuccessState<HistoryModel>)
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            final cls = s.data.checklists;
            if (cls.isEmpty)
              return _EmptyState(
                icon: Icons.checklist_outlined,
                message: 'Nenhum checklist registrado.',
              );
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cls.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ChecklistListItem(checklist: cls[i]),
            );
          },
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        final bikeId = widget.bikeViewModel.selectedBikeId;
        if (bikeId == null) {
          _showSnack(context, 'Selecione uma bicicleta.');
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppTheme.surfDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _RegisterRideSheet(
            bikeId: bikeId,
            rideViewModel: widget.rideViewModel,
            onSaved: () {
              if (context.mounted) _showSnack(context, 'Passeio registrado!');
            },
          ),
        );
      },
      child: const Icon(Icons.add),
    ),
  );
}

class _RideListItem extends StatelessWidget {
  final RideModel ride;
  const _RideListItem({required this.ride});
  @override
  Widget build(BuildContext context) => _darkCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.riddenAt != null ? _fmtDate(ride.riddenAt!) : '—',
                style: TextStyle(fontSize: 12, color: AppTheme.txtSecDark),
              ),
              const SizedBox(height: 2),
              Text(
                '${ride.distanceKm?.toStringAsFixed(1) ?? '0'} km',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.txtPrimDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfDark2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ride.terrain != null ? _terrainLabel(ride.terrain!) : '—',
              style: TextStyle(fontSize: 13, color: AppTheme.txtSecDark),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExchangeListItem extends StatelessWidget {
  final PartExchangeModel exchange;
  const _ExchangeListItem({required this.exchange});
  @override
  Widget build(BuildContext context) => _darkCard(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exchange.partName ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.txtPrimDark,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (exchange.wasPremature
                              ? AppTheme.warning
                              : AppTheme.primary)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  exchange.wasPremature ? 'Prematura' : 'Normal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exchange.wasPremature
                        ? AppTheme.warning
                        : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${exchange.actualKmReached?.toStringAsFixed(0)} km de ${exchange.expectedDurationKm?.toStringAsFixed(0)} km esperados',
            style: TextStyle(fontSize: 13, color: AppTheme.txtSecDark),
          ),
          if (exchange.exchangedAt != null)
            Text(
              _fmtDate(exchange.exchangedAt!),
              style: TextStyle(fontSize: 12, color: AppTheme.txtSecDark),
            ),
          if (exchange.notes != null && exchange.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${exchange.notes}"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.txtSecDark,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ChecklistListItem extends StatelessWidget {
  final ChecklistModel checklist;
  const _ChecklistListItem({required this.checklist});
  @override
  Widget build(BuildContext context) => _darkCard(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                checklist.executedAt != null
                    ? _fmtDate(checklist.executedAt!)
                    : '—',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.txtPrimDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: checklist.items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (checklist.notes != null && checklist.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              checklist.notes!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.txtSecDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ============================================================
// PROFILE VIEW
// ============================================================

class ProfileView extends StatelessWidget {
  final SettingViewModel settingViewModel;
  final AuthViewModel authViewModel;
  const ProfileView({
    super.key,
    required this.settingViewModel,
    required this.authViewModel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      title: Text('Perfil', style: TextStyle(color: AppTheme.txtPrimDark)),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                child: Icon(Icons.person, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Ciclista',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.txtPrimDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'CONFIGURAÇÕES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.txtSecDark,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _darkCard(
          child: Column(
            children: [
              StateBuilderWidget<SettingViewModel, SettingModel>(
                viewModel: settingViewModel,
                builder: (_, s) => SwitchListTile(
                  title: Text(
                    'Tema escuro',
                    style: TextStyle(
                      color: AppTheme.txtPrimDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  secondary: Icon(
                    s.isDarkTheme
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppTheme.primary,
                  ),
                  value: s.isDarkTheme,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (v) =>
                      settingViewModel.changeTheme(isDarkTheme: v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'CONTA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.txtSecDark,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _darkCard(
          child: Column(
            children: [
              _ProfileTile(
                icon: Icons.lock_outline,
                title: 'Privacidade e Segurança',
                onTap: () {},
              ),
              Divider(
                color: AppTheme.neutral.withValues(alpha: 0.15),
                height: 1,
              ),
              _ProfileTile(
                icon: Icons.help_outline,
                title: 'Ajuda e Suporte',
                onTap: () {},
              ),
              Divider(
                color: AppTheme.neutral.withValues(alpha: 0.15),
                height: 1,
              ),
              _ProfileTile(
                icon: Icons.notifications_outlined,
                title: 'Notificações',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger.withValues(alpha: 0.12),
            foregroundColor: AppTheme.danger,
            elevation: 0,
          ),
          onPressed: () async {
            await authViewModel.logout();
            if (context.mounted) context.go(AuthRoutes.login);
          },
          icon: const Icon(Icons.logout),
          label: const Text(
            'Encerrar Sessão',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.txtPrimDark,
                fontSize: 15,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.txtSecDark, size: 20),
        ],
      ),
    ),
  );
}

// ============================================================
// PART DETAIL VIEW
// ============================================================

class PartDetailView extends StatelessWidget {
  final int partId;
  final PartViewModel partViewModel;
  const PartDetailView({
    super.key,
    required this.partId,
    required this.partViewModel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDark,
    appBar: AppBar(
      backgroundColor: AppTheme.bgDark,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_outlined,
          color: AppTheme.txtPrimDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detalhe da Peça',
        style: TextStyle(color: AppTheme.txtPrimDark),
      ),
    ),
    body: StateBuilderWidget<PartViewModel, PartState>(
      viewModel: partViewModel,
      builder: (ctx, s) {
        if (s is! SuccessState<List<PartModel>>)
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        final part = s.data.where((p) => p.id == partId).firstOrNull;
        if (part == null)
          return Center(
            child: Text(
              'Peça não encontrada.',
              style: TextStyle(color: AppTheme.txtSecDark),
            ),
          );
        final pct = part.progressPercent ?? 0;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    part.name ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.txtPrimDark,
                    ),
                  ),
                ),
                _StatusBadge(
                  label: part.status == PartStatus.active ? 'Ativa' : 'Trocada',
                  color: part.status == PartStatus.active
                      ? AppTheme.primary
                      : AppTheme.neutral,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _darkCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: _progressColor(pct),
                      ),
                    ),
                    if (part.isOverLimit)
                      Text(
                        '+${((part.kmRidden ?? 0) - (part.expectedDurationKm ?? 0)).clamp(0, double.infinity).toStringAsFixed(0)} km além do esperado',
                        style: TextStyle(color: AppTheme.danger, fontSize: 13),
                      ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        color: _progressColor(pct),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        minHeight: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(part.kmRidden ?? 0).toStringAsFixed(0)} km',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.txtPrimDark,
                              ),
                            ),
                            Text(
                              'rodados',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.txtSecDark,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(part.expectedDurationKm ?? 0).toStringAsFixed(0)} km',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.txtPrimDark,
                              ),
                            ),
                            Text(
                              'esperados',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.txtSecDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _darkCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Preço pago',
                      value: 'R\$ ${(part.pricePaid ?? 0).toStringAsFixed(2)}',
                    ),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 24,
                    ),
                    _InfoRow(
                      label: 'Instalada em',
                      value: part.installedAt != null
                          ? _fmtDate(part.installedAt!)
                          : '—',
                    ),
                    if (!part.isOverLimit &&
                        part.status == PartStatus.active) ...[
                      Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 24,
                      ),
                      _InfoRow(
                        label: 'Km restantes',
                        value:
                            '${((part.expectedDurationKm ?? 0) - (part.kmRidden ?? 0)).clamp(0, double.infinity).toStringAsFixed(0)} km',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (part.status == PartStatus.active) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final bikeId = locator<BikeViewModel>().selectedBikeId;
                  if (bikeId == null) return;
                  showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.surfDark,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => _ExchangePartSheet(
                      bikeId: bikeId,
                      part: part,
                      partViewModel: partViewModel,
                      onSaved: () {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(ctx, 'Peça trocada.');
                        }
                      },
                    ),
                  );
                },
                child: const Text('Trocar peça'),
              ),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: AppTheme.txtSecDark, fontSize: 14)),
      Text(
        value,
        style: TextStyle(
          color: AppTheme.txtPrimDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

// ============================================================
// SHARED WIDGETS
// ============================================================

class _PartProgressCard extends StatelessWidget {
  final PartModel part;
  final Widget? trailing;
  const _PartProgressCard({required this.part, this.trailing});
  @override
  Widget build(BuildContext context) {
    final pct = part.progressPercent ?? 0;
    final color = _progressColor(pct);
    final replaced = part.status == PartStatus.replaced;
    return Opacity(
      opacity: replaced ? 0.5 : 1.0,
      child: _darkCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      part.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.txtPrimDark,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (part.isOverLimit)
                    _StatusBadge(label: 'Hora extra', color: AppTheme.danger),
                  if (replaced)
                    _StatusBadge(label: 'Trocada', color: AppTheme.neutral),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        color: color,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(part.kmRidden ?? 0).toStringAsFixed(0)} / ${(part.expectedDurationKm ?? 0).toStringAsFixed(0)} km',
                    style: TextStyle(fontSize: 12, color: AppTheme.txtSecDark),
                  ),
                  Text(
                    'R\$ ${(part.pricePaid ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.txtSecDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 64, color: AppTheme.txtSecDark.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.txtSecDark, fontSize: 14),
        ),
      ],
    ),
  );
}

// ============================================================
// BOTTOM SHEETS
// ============================================================

class _RegisterRideSheet extends StatefulWidget {
  final int bikeId;
  final RideViewModel rideViewModel;
  final VoidCallback onSaved;
  const _RegisterRideSheet({
    required this.bikeId,
    required this.rideViewModel,
    required this.onSaved,
  });
  @override
  State<_RegisterRideSheet> createState() => _RegisterRideSheetState();
}

class _RegisterRideSheetState extends State<_RegisterRideSheet> {
  final _distCtrl = TextEditingController();
  String _terrain = 'seco';
  DateTime _date = DateTime.now();
  bool _loading = false;
  static const _terrains = [
    ('seco', '☀️ Seco'),
    ('chuva', '🌧 Chuva'),
    ('lama', '💧 Lama'),
    ('trilha', '⛰️ Trilha'),
    ('asfalto', '🏙️ Asfalto'),
  ];
  @override
  void dispose() {
    _distCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final km = double.tryParse(_distCtrl.text.replaceAll(',', '.'));
    if (km == null || km <= 0) return;
    setState(() => _loading = true);
    await widget.rideViewModel.createRide(
      bikeId: widget.bikeId,
      distanceKm: km,
      terrain: _terrain,
      riddenAt: _date,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar passeio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _distCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: AppTheme.txtPrimDark,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: '0',
            fillColor: AppTheme.surfDark2,
            suffixText: 'km',
            suffixStyle: TextStyle(color: AppTheme.txtSecDark, fontSize: 18),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Terreno',
          style: TextStyle(color: AppTheme.txtSecDark, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _terrains
              .map(
                (t) => ChoiceChip(
                  label: Text(t.$2),
                  selected: _terrain == t.$1,
                  onSelected: (_) => setState(() => _terrain = t.$1),
                  backgroundColor: AppTheme.surfDark2,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _terrain == t.$1
                        ? AppTheme.primary
                        : AppTheme.txtSecDark,
                    fontWeight: _terrain == t.$1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: _terrain == t.$1
                        ? AppTheme.primary
                        : Colors.transparent,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Data: ',
              style: TextStyle(color: AppTheme.txtSecDark, fontSize: 13),
            ),
            TextButton(
              onPressed: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (p != null) setState(() => _date = p);
              },
              child: Text(
                _fmtDate(_date),
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Registrar passeio'),
        ),
      ],
    ),
  );
}

class _InstallPartSheet extends StatefulWidget {
  final int bikeId;
  final PartViewModel partViewModel;
  final VoidCallback onSaved;
  const _InstallPartSheet({
    required this.bikeId,
    required this.partViewModel,
    required this.onSaved,
  });
  @override
  State<_InstallPartSheet> createState() => _InstallPartSheetState();
}

class _InstallPartSheetState extends State<_InstallPartSheet> {
  final _nameCtrl = TextEditingController();
  final _durCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;
  @override
  void dispose() {
    _nameCtrl.dispose();
    _durCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final dur = double.tryParse(_durCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || dur == null || dur <= 0) return;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _loading = true);
    await widget.partViewModel.createPart(
      bikeId: widget.bikeId,
      name: name,
      expectedDurationKm: dur,
      pricePaid: price,
      installedAt: _date,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? type,
    String? suffix,
  }) => TextField(
    controller: c,
    keyboardType: type,
    style: TextStyle(color: AppTheme.txtPrimDark),
    decoration: InputDecoration(
      hintText: hint,
      fillColor: AppTheme.surfDark2,
      suffixText: suffix,
      suffixStyle: TextStyle(color: AppTheme.txtSecDark),
    ),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instalar nova peça',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 20),
        _field(_nameCtrl, 'Nome da peça (ex: Pneu Traseiro)'),
        const SizedBox(height: 12),
        _field(
          _durCtrl,
          'Duração esperada',
          type: const TextInputType.numberWithOptions(decimal: true),
          suffix: 'km',
        ),
        const SizedBox(height: 12),
        _field(
          _priceCtrl,
          'Preço pago (opcional)',
          type: const TextInputType.numberWithOptions(decimal: true),
          suffix: 'R\$',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Instalada em: ',
              style: TextStyle(color: AppTheme.txtSecDark, fontSize: 13),
            ),
            TextButton(
              onPressed: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (p != null) setState(() => _date = p);
              },
              child: Text(
                _fmtDate(_date),
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Instalar peça'),
        ),
      ],
    ),
  );
}

class _ExchangePartSheet extends StatefulWidget {
  final int bikeId;
  final PartModel part;
  final PartViewModel partViewModel;
  final VoidCallback onSaved;
  const _ExchangePartSheet({
    required this.bikeId,
    required this.part,
    required this.partViewModel,
    required this.onSaved,
  });
  @override
  State<_ExchangePartSheet> createState() => _ExchangePartSheetState();
}

class _ExchangePartSheetState extends State<_ExchangePartSheet> {
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await widget.partViewModel.exchangePart(
      bikeId: widget.bikeId,
      partId: widget.part.id!,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trocar peça',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"${widget.part.name}" será encerrada com ${(widget.part.kmRidden ?? 0).toStringAsFixed(0)} km. Ação irreversível.',
          style: TextStyle(color: AppTheme.txtSecDark, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          style: TextStyle(color: AppTheme.txtPrimDark),
          decoration: InputDecoration(
            hintText: 'Observação (opcional)',
            fillColor: AppTheme.surfDark2,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AddBikeSheet extends StatefulWidget {
  final BikeViewModel bikeViewModel;
  final VoidCallback onSaved;
  const _AddBikeSheet({required this.bikeViewModel, required this.onSaved});
  @override
  State<_AddBikeSheet> createState() => _AddBikeSheetState();
}

class _AddBikeSheetState extends State<_AddBikeSheet> {
  final _nicknameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  String? _photoBase64;
  bool _loading = false;
  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      setState(
        () => _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}',
      );
    } catch (_) {}
  }

  Future<void> _submit() async {
    final nickname = _nicknameCtrl.text.trim();
    final brand = _brandCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (nickname.isEmpty || brand.isEmpty || model.isEmpty) return;
    setState(() => _loading = true);
    await widget.bikeViewModel.createBike(
      nickname: nickname,
      brand: brand,
      model: model,
      photoBase64: _photoBase64,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    style: TextStyle(color: AppTheme.txtPrimDark),
    decoration: InputDecoration(hintText: hint, fillColor: AppTheme.surfDark2),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nova bicicleta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfDark2,
              ),
              clipBehavior: Clip.antiAlias,
              child: _photoBase64 != null
                  ? Image.memory(
                      base64Decode(_photoBase64!.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Foto',
                          style: TextStyle(
                            color: AppTheme.txtSecDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _field(_nicknameCtrl, 'Apelido (ex: Minha MTB)'),
        const SizedBox(height: 12),
        _field(_brandCtrl, 'Marca'),
        const SizedBox(height: 12),
        _field(_modelCtrl, 'Modelo'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Cadastrar bicicleta'),
        ),
      ],
    ),
  );
}

class _ChecklistSheet extends StatefulWidget {
  final int bikeId;
  final HistoryViewModel historyViewModel;
  final List<String> checklistItems;
  final VoidCallback onSaved;
  const _ChecklistSheet({
    required this.bikeId,
    required this.historyViewModel,
    required this.checklistItems,
    required this.onSaved,
  });
  @override
  State<_ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends State<_ChecklistSheet> {
  final Set<String> _selected = {};
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    await widget.historyViewModel.createChecklist(
      bikeId: widget.bikeId,
      itemsChecked: _selected.join(','),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 24,
      right: 24,
      top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Checklist de Manutenção',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.txtPrimDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.5,
          children: widget.checklistItems.map((item) {
            final sel = _selected.contains(item);
            return GestureDetector(
              onTap: () => setState(
                () => sel ? _selected.remove(item) : _selected.add(item),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : AppTheme.surfDark2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppTheme.primary : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: sel ? AppTheme.primary : AppTheme.txtSecDark,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item[0].toUpperCase() + item.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          color: sel ? AppTheme.primary : AppTheme.txtSecDark,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: TextStyle(color: AppTheme.txtPrimDark),
          decoration: InputDecoration(
            hintText: 'Observação (opcional)',
            fillColor: AppTheme.surfDark2,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading || _selected.isEmpty ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Salvar checklist'),
        ),
      ],
    ),
  );
}
