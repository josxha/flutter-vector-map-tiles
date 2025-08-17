import 'package:test/test.dart';
import 'package:vector_map_tiles/src/model/safe_change_notifier.dart';

void main() {
  group('SafeChangeNotifier', () {
    late SafeChangeNotifier notifier;

    setUp(() {
      notifier = SafeChangeNotifier();
    });

    tearDown(() {
      if (!notifier.isDisposed) {
        notifier.dispose();
      }
    });

    group('initialization', () {
      test('starts in non-disposed state', () {
        expect(notifier.isDisposed, isFalse);
      });
    });

    group('disposal', () {
      test('marks notifier as disposed when dispose is called', () {
        notifier.dispose();

        expect(notifier.isDisposed, isTrue);
      });

      test('throws error on multiple disposal calls', () {
        notifier.dispose();
        expect(notifier.isDisposed, isTrue);

        expect(() => notifier.dispose(), throwsA(isA<Error>()));
        expect(notifier.isDisposed, isTrue);
      });
    });

    group('notification behavior', () {
      test('notifies listeners when not disposed', () {
        var notificationCount = 0;
        notifier.addListener(() => notificationCount++);

        notifier.notifyListeners();

        expect(notificationCount, equals(1));
      });

      test('prevents notification after disposal', () {
        var notificationCount = 0;
        notifier.addListener(() => notificationCount++);

        notifier.dispose();
        notifier.notifyListeners();

        expect(notificationCount, equals(0));
      });

      test('notifies multiple listeners when not disposed', () {
        var firstListenerCount = 0;
        var secondListenerCount = 0;

        notifier.addListener(() => firstListenerCount++);
        notifier.addListener(() => secondListenerCount++);

        notifier.notifyListeners();

        expect(firstListenerCount, equals(1));
        expect(secondListenerCount, equals(1));
      });

      test('prevents notification to all listeners after disposal', () {
        var firstListenerCount = 0;
        var secondListenerCount = 0;

        notifier.addListener(() => firstListenerCount++);
        notifier.addListener(() => secondListenerCount++);

        notifier.dispose();
        notifier.notifyListeners();

        expect(firstListenerCount, equals(0));
        expect(secondListenerCount, equals(0));
      });
    });

    group('listener management', () {
      test('allows adding listeners before disposal', () {
        expect(() => notifier.addListener(() {}), returnsNormally);
      });

      test('allows removing listeners before disposal', () {
        void listener() {}
        notifier.addListener(listener);

        expect(() => notifier.removeListener(listener), returnsNormally);
      });

      test('maintains listener functionality until disposal', () {
        var notificationCount = 0;
        void listener() => notificationCount++;

        notifier.addListener(listener);
        notifier.notifyListeners();
        expect(notificationCount, equals(1));

        notifier.removeListener(listener);
        notifier.notifyListeners();
        expect(notificationCount, equals(1));
      });
    });

    group('edge cases', () {
      test('handles notification calls without listeners', () {
        expect(() => notifier.notifyListeners(), returnsNormally);
      });

      test('handles notification calls without listeners after disposal', () {
        notifier.dispose();

        expect(() => notifier.notifyListeners(), returnsNormally);
      });

      test(
        'maintains disposal state across multiple notification attempts',
        () {
          notifier.dispose();

          notifier.notifyListeners();
          notifier.notifyListeners();
          notifier.notifyListeners();

          expect(notifier.isDisposed, isTrue);
        },
      );
    });
  });
}
