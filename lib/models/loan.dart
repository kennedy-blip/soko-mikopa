import 'dart:math';
class Loan {
 final String id,name,phone,note; final double principal,rate; final int terms; final DateTime start,created;
 Loan({required this.id,required this.name,required this.phone,required this.note,required this.principal,required this.rate,required this.terms,required this.start,required this.created});
 double get total=>principal*(1+rate/100); double get installment=>total/terms;
 DateTime due(int i){final m=start.month+i+1;final last=DateTime(start.year,m+1,0).day;return DateTime(start.year,m,min(start.day,last));}
 Map<String,dynamic> toMap()=>{'id':id,'name':name,'phone':phone,'note':note,'principal':principal,'rate':rate,'terms':terms,'start':start.toIso8601String(),'created':created.toIso8601String()};
 factory Loan.fromMap(Map<String,dynamic> m)=>Loan(id:m['id'],name:m['name'],phone:m['phone']??'',note:m['note']??'',principal:(m['principal'] as num).toDouble(),rate:(m['rate'] as num).toDouble(),terms:m['terms'],start:DateTime.parse(m['start']),created:DateTime.parse(m['created']));
}
