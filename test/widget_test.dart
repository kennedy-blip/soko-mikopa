import 'package:flutter_test/flutter_test.dart';
import 'package:soko_mikopo/models/loan.dart';

void main() {
  test('loan calculates total and installment amount', () {
    final loan = Loan(
      id: 'loan-1', name: 'Sample', phone: '', note: '',
      principal: 10000, rate: 10, terms: 4,
      start: DateTime(2026, 1, 15), created: DateTime(2026, 1, 1),
    );
    expect(loan.total, 11000);
    expect(loan.installment, 2750);
    expect(loan.due(0), DateTime(2026, 2, 15));
  });
}
