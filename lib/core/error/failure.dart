import 'package:equatable/equatable.dart';

/// Cross-cutting failure type. Feature failures extend or map into this.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

final class IoFailure extends Failure {
  const IoFailure(super.message);
}
