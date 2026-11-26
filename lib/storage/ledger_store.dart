import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/repayment.dart';
class LedgerStore {
 LedgerStore._(); static final instance=LedgerStore._(); static const _uuid=Uuid();
 late Box<String> _loans,_payments; final revision=ValueNotifier<int>(0);
 Future<void> init() async { _loans=await Hive.openBox<String>('loans_v1'); _payments=await Hive.openBox<String>('repayments_v1'); }
 List<Loan> get loans=>_loans.values.map((s)=>Loan.fromMap(jsonDecode(s))).toList()..sort((a,b)=>b.created.compareTo(a.created));
 List<Repayment> get payments=>_payments.values.map((s)=>Repayment.fromMap(jsonDecode(s))).toList()..sort((a,b)=>b.date.compareTo(a.date));
 double paid(String id)=>payments.where((p)=>p.loanId==id).fold(0,(s,p)=>s+p.amount);
 double balance(Loan l)=>(l.total-paid(l.id)).clamp(0,double.infinity);
 Future<void> addLoan({required String name,required String phone,required String note,required double principal,required double rate,required int terms,required DateTime start}) async {final l=Loan(id:_uuid.v4(),name:name.trim(),phone:phone.trim(),note:note.trim(),principal:principal,rate:rate,terms:terms,start:start,created:DateTime.now());await _loans.put(l.id,jsonEncode(l.toMap()));_touch();}
 Future<void> addPayment({required String loanId,required double amount,required String mode,required String note}) async {final l=loans.firstWhere((x)=>x.id==loanId);if(amount<=0||amount>balance(l)+.001)throw ArgumentError('Repayment must be positive and no greater than the outstanding balance.');final p=Repayment(id:_uuid.v4(),loanId:loanId,mode:mode,note:note.trim(),amount:amount,date:DateTime.now());await _payments.put(p.id,jsonEncode(p.toMap()));_touch();}
 Future<void> deleteLoan(String id) async {for(final p in payments.where((p)=>p.loanId==id).toList()){await _payments.delete(p.id);}await _loans.delete(id);_touch();}
 void _touch()=>revision.value++;
 int get recordCount=>_loans.length+_payments.length;
 String exportJson()=>const JsonEncoder.withIndent('  ').convert({'product':'SokoMikopo','exportedAt':DateTime.now().toIso8601String(),'loans':loans.map((e)=>e.toMap()).toList(),'repayments':payments.map((e)=>e.toMap()).toList()});
}
