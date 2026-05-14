import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_rider_app/core/error/failures.dart';
import 'package:taxi_rider_app/core/result/result.dart';

void main() {
  test('AppResult success carries value', () {
    const Success<int, Failure> r = Success(7);
    expect(r.value, 7);
  });

  test('AppResult failure carries error', () {
    const FailureResult<int, Failure> r = FailureResult(AuthFailure('x'));
    expect(r.error.message, 'x');
  });
}
