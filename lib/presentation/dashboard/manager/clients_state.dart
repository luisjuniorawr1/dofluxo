import '../../../domain/entities/client_entity.dart';

abstract class ClientsState {}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<ClientEntity> clients;
  ClientsLoaded(this.clients);
}

class ClientsError extends ClientsState {
  final String message;
  ClientsError(this.message);
}