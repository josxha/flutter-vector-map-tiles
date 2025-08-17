import 'package:executor_lib/executor_lib.dart';

Executor newConcurrentExecutor({required int concurrency}) =>
    concurrency > 0 ? PoolExecutor(concurrency: concurrency) : QueueExecutor();
