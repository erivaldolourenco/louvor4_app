import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/navigation/app_route_observer.dart';
import 'package:louvor4_app/features/events/data/impl/events_repository_impl.dart';
import 'package:louvor4_app/features/events/presentation/cubit/events_cubit.dart';
import 'package:louvor4_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:louvor4_app/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:louvor4_app/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:louvor4_app/features/notifications/presentation/pages/avisos_page.dart';
import 'package:louvor4_app/features/music_projects/data/impl/music_projects_repository_impl.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_cubit.dart';
import 'package:louvor4_app/features/music_projects/presentation/pages/music_projects_tab_page.dart';
import 'package:louvor4_app/features/music_projects/presentation/widgets/project_selector_bottom_sheet.dart';
import 'package:louvor4_app/features/songs/presentation/pages/songs_list_page.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_bottom_navigation_bar.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_navigation_drawer.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_cubit.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_state.dart';
import 'package:louvor4_app/features/user_profile/apresentation/pages/profile_page.dart';
import 'package:louvor4_app/features/user_profile/apresentation/pages/user_unavailability_page.dart';
import 'package:louvor4_app/features/user_profile/data/impl/user_repository_impl.dart';

import '../../../events/presentation/pages/events_list_page.dart';

class RootPage extends StatefulWidget {
  static const routeName = '/root';

  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage>
    with RouteAware, WidgetsBindingObserver {
  static const int _tabCount = 4;
  static const Duration _homeRefreshInterval = Duration(minutes: 10);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  int _transitionTick = 0;
  Offset _transitionBeginOffset = Offset.zero;
  late final ProjectCubit _projectCubit;
  late final UserCubit _userCubit;
  late final EventsCubit _eventsCubit;
  late final NotificationsCubit _notificationsCubit;
  ModalRoute<dynamic>? _subscribedRoute;
  DateTime? _lastEventsRefreshAt;
  DateTime? _lastNotificationsRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _projectCubit = ProjectCubit(MusicProjectsRepositoryImpl())..loadProjects();
    _userCubit = UserCubit(UserRepositoryImpl())..load();
    _eventsCubit = EventsCubit(EventsRepositoryImpl())..load();
    _lastEventsRefreshAt = DateTime.now();
    _notificationsCubit = NotificationsCubit(NotificationsRepositoryImpl())
      ..load();
    _lastNotificationsRefreshAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _projectCubit.close();
    _userCubit.close();
    _eventsCubit.close();
    _notificationsCubit.close();
    super.dispose();
  }

  Future<void> _go(int i, BuildContext modalContext) async {
    await _navigateToIndex(i, modalContext);
  }

  void _setIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _tabCount || _index == newIndex) return;

    final movingForward = newIndex > _index;
    setState(() {
      _index = newIndex;
      _transitionTick += 1;
      _transitionBeginOffset = movingForward
          ? const Offset(0.08, 0)
          : const Offset(-0.08, 0);
    });

    if (newIndex == 0) {
      _refreshHomeIfStale();
    }
  }

  Future<void> _navigateToIndex(int newIndex, BuildContext modalContext) async {
    if (newIndex < 0 || newIndex >= _tabCount) return;

    if (newIndex == 1) {
      final selected = await showProjectSelector(modalContext);
      if (!mounted) return;

      if (selected != null) {
        _setIndex(1);
      }
      return;
    }

    _setIndex(newIndex);
  }

  void _handleHorizontalDragEnd(
    DragEndDetails details,
    BuildContext modalContext,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    const minSwipeVelocity = 250;

    if (velocity.abs() < minSwipeVelocity) return;

    if (velocity < 0) {
      _handleSwipeTarget(_index + 1, modalContext);
      return;
    }

    _handleSwipeTarget(_index - 1, modalContext);
  }

  void _handleSwipeTarget(int targetIndex, BuildContext modalContext) {
    if (targetIndex < 0 || targetIndex >= _tabCount) return;
    if (targetIndex == 1) {
      _setIndex(1);
      return;
    }

    _navigateToIndex(targetIndex, modalContext);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _openRoute(String routeName) async {
    Navigator.of(context).pop();
    await Navigator.of(context).pushNamed(routeName);
    if (!mounted) return;
    if (routeName == ProfilePage.routeName) {
      _userCubit.load();
    }
    _refreshHomeIfStale();
  }

  void _refreshEvents({bool force = false}) {
    if (!force && _isHomeRefreshStillFresh(_lastEventsRefreshAt)) return;
    _eventsCubit.load();
    _lastEventsRefreshAt = DateTime.now();
  }

  void _refreshNotifications({bool force = false}) {
    if (!force && _isHomeRefreshStillFresh(_lastNotificationsRefreshAt)) {
      return;
    }
    _notificationsCubit.refresh();
    _lastNotificationsRefreshAt = DateTime.now();
  }

  void _refreshHomeIfStale() {
    _refreshEvents();
    _refreshNotifications();
  }

  bool _isHomeRefreshStillFresh(DateTime? lastRefreshAt) {
    if (lastRefreshAt == null) return false;
    return DateTime.now().difference(lastRefreshAt) < _homeRefreshInterval;
  }

  @override
  void didPopNext() {
    _refreshHomeIfStale();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHomeIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _projectCubit),
        BlocProvider.value(value: _userCubit),
        BlocProvider.value(value: _eventsCubit),
        BlocProvider.value(value: _notificationsCubit),
      ],
      child: Builder(
        builder: (modalContext) {
          return BlocBuilder<UserCubit, UserState>(
            builder: (context, userState) {
              return Scaffold(
                key: _scaffoldKey,
                drawerScrimColor: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.28),
                drawer: RootNavigationDrawer(
                  user: userState.user,
                  isLoadingUser: userState.status == UserStatus.loading,
                  onProfileTap: () => _openRoute(ProfilePage.routeName),
                  onUnavailabilityTap: () =>
                      _openRoute(UserUnavailabilityPage.routeName),
                ),
                bottomNavigationBar:
                    BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, notificationsState) {
                        return RootBottomNavigationBar(
                          currentIndex: _index,
                          unreadNotificationsCount:
                              notificationsState.unreadCount,
                          onTap: (i) => _go(i, modalContext),
                        );
                      },
                    ),
                body: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) =>
                      _handleHorizontalDragEnd(details, modalContext),
                  child: TweenAnimationBuilder<Offset>(
                    key: ValueKey(_transitionTick),
                    tween: Tween<Offset>(
                      begin: _transitionBeginOffset,
                      end: Offset.zero,
                    ),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, offset, child) {
                      final opacity = (1 - (offset.dx.abs() * 4)).clamp(
                        0.82,
                        1.0,
                      );

                      return Transform.translate(
                        offset: Offset(
                          offset.dx * MediaQuery.sizeOf(context).width,
                          0,
                        ),
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: IndexedStack(
                      index: _index,
                      children: [
                        EventsListPage(
                          onOpenDrawer: _openDrawer,
                          user: userState.user,
                          isLoadingUser: userState.status == UserStatus.loading,
                        ),
                        MusicProjectsTabPage(
                          onGoHome: () => _setIndex(0),
                        ),
                        const SongsListPage(),
                        const AvisosPage(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
