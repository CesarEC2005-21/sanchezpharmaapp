import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/usuario_model.dart';
import '../models/rol_model.dart';
import '../../core/constants/api_constants.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST(ApiConstants.login)
  Future<LoginResponse> login(@Body() LoginRequest request);

  @POST(ApiConstants.logout)
  Future<HttpResponse<dynamic>> logout();

  @GET(ApiConstants.usuarios)
  Future<HttpResponse<dynamic>> getUsuarios();

  @GET(ApiConstants.roles)
  Future<HttpResponse<dynamic>> getRoles();

  @POST(ApiConstants.registrarUsuario)
  Future<HttpResponse<dynamic>> registrarUsuario(@Body() Map<String, dynamic> usuario);

  @PUT(ApiConstants.editarUsuario)
  Future<HttpResponse<dynamic>> editarUsuario(@Body() Map<String, dynamic> usuario);

  @DELETE('${ApiConstants.eliminarUsuario}/{id}')
  Future<HttpResponse<dynamic>> eliminarUsuario(@Path('id') int id);
}

