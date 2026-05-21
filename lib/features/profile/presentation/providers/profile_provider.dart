import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

class ProfileStats {
  const ProfileStats({
    required this.orderCount,
    required this.favoriteCount,
  });

  final int orderCount;
  final int favoriteCount;
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final orderCount = ref.watch(orderCountProvider);
  final favorites = ref.watch(favoritesListProvider).value ?? [];
  return ProfileStats(
    orderCount: orderCount,
    favoriteCount: favorites.length,
  );
});

enum ProfileUpdateStatus { idle, loading, success, error }

class ProfileUpdateState {
  const ProfileUpdateState({
    this.status = ProfileUpdateStatus.idle,
    this.errorMessage,
  });

  final ProfileUpdateStatus status;
  final String? errorMessage;

  bool get isLoading => status == ProfileUpdateStatus.loading;
  bool get hasError => status == ProfileUpdateStatus.error;
  bool get isSuccess => status == ProfileUpdateStatus.success;

  ProfileUpdateState copyWith({
    ProfileUpdateStatus? status,
    String? errorMessage,
  }) =>
      ProfileUpdateState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

class ProfileNotifier extends StateNotifier<ProfileUpdateState> {
  ProfileNotifier(this._ref) : super(const ProfileUpdateState());

  final Ref _ref;

  User? get _user => _ref.read(currentUserProvider);

  Future<bool> updateDisplayName(String displayName) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: 'Display name cannot be empty.',
      );
      return false;
    }

    state = state.copyWith(status: ProfileUpdateStatus.loading);
    try {
      await _user?.updateDisplayName(name);
      state = state.copyWith(status: ProfileUpdateStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: 'Email cannot be empty.',
      );
      return false;
    }

    state = state.copyWith(status: ProfileUpdateStatus.loading);
    try {
      await _user?.verifyBeforeUpdateEmail(trimmed);
      state = state.copyWith(status: ProfileUpdateStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: ProfileUpdateStatus.loading);
    try {
      await _ref.read(authNotifierProvider.notifier).signOut();
      state = const ProfileUpdateState();
    } catch (e) {
      state = state.copyWith(
        status: ProfileUpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearStatus() {
    state = const ProfileUpdateState();
  }
}

final profileNotifierProvider =
StateNotifierProvider<ProfileNotifier, ProfileUpdateState>((ref) {
  return ProfileNotifier(ref);
});