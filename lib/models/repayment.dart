class Repayment {
 final String id,loanId,mode,note; final double amount; final DateTime date;
 Repayment({required this.id,required this.loanId,required this.mode,required this.note,required this.amount,required this.date});
 Map<String,dynamic> toMap()=>{'id':id,'loanId':loanId,'mode':mode,'note':note,'amount':amount,'date':date.toIso8601String()};
 factory Repayment.fromMap(Map<String,dynamic> m)=>Repayment(id:m['id'],loanId:m['loanId'],mode:m['mode'],note:m['note']??'',amount:(m['amount'] as num).toDouble(),date:DateTime.parse(m['date']));
}
