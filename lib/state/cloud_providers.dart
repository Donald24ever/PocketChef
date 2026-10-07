import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/cloud_store.dart';

final cloudStoreProvider = Provider<CloudStore>((ref) => const CloudStore());