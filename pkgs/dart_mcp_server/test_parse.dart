import 'dart:convert';
import 'package:vm_service_protos/vm_service_protos.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  final event = TrackEvent(
    trackUuid: Int64(748),
    type: TrackEvent_Type.TYPE_SLICE_BEGIN,
    categories: ['Embedder'],
    name: 'Frame Request Pending',
  );
  print(jsonEncode(event.toProto3Json()));
}
