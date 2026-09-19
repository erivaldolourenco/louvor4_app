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
import 'package:louvor4_app/features/song_categories/presentation/pages/song_categories_page.dart';
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
  bool _movingForward = true;
  int _tabArrivalNonce = 0;
  bool _tabArrivalLandOnLast = false;
  // Índice da página a que o comando de chegada acima se aplica — só
  // fica preenchido para a única build seguinte à transição que o gerou;
  // sem isso, uma visita futura e não relacionada ao mesmo índice poderia
  // reaplicar um comando antigo (ver _setIndex).
  int? _tabArrivalForIndex;
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
    _notificationsCubit = NotificationsCubit(
      NotificationsRepositoryImpl(),
      onProjectInviteAccepted: _projectCubit.invalidateProjects,
    )..load();
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

  void _setIndex(int newIndex, {bool? arrivalLandOnLast}) {
    if (newIndex < 0 || newIndex >= _tabCount || _index == newIndex) return;

    final movingForward = newIndex > _index;
    setState(() {
      _movingForward = movingForward;
      _index = newIndex;
      if (arrivalLandOnLast != null) {
        _tabArrivalNonce += 1;
        _tabArrivalLandOnLast = arrivalLandOnLast;
        _tabArrivalForIndex = newIndex;
      }
    });

    if (arrivalLandOnLast != null) {
      // O comando só deve valer para a build que acabou de montar a
      // página de destino — limpa logo em seguida para não ser reaplicado
      // numa visita futura e não relacionada ao mesmo índice.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _tabArrivalForIndex = null);
      });
    }

    if (newIndex == 0) {
      _refreshHomeIfStale();
    }
  }

  Future<void> _navigateToIndex(
    int newIndex,
    BuildContext modalContext, {
    bool? arrivalLandOnLast,
  }) async {
    if (newIndex < 0 || newIndex >= _tabCount) return;

    if (newIndex == 1) {
      if (_projectCubit.state.activeProject != null) {
        _setIndex(1, arrivalLandOnLast: arrivalLandOnLast);
        return;
      }

      final selected = await showProjectSelector(modalContext);
      if (!mounted) return;

      if (selected != null) {
        _setIndex(1, arrivalLandOnLast: arrivalLandOnLast);
      }
      return;
    }

    _setIndex(newIndex, arrivalLandOnLast: arrivalLandOnLast);
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
    final arrivalLandOnLast = targetIndex < _index;
    if (targetIndex == 1) {
      _setIndex(1, arrivalLandOnLast: arrivalLandOnLast);
      return;
    }

    _navigateToIndex(
      targetIndex,
      modalContext,
      arrivalLandOnLast: arrivalLandOnLast,
    );
  }

  /// Chamado quando o usuário arrasta além da primeira/última aba interna
  /// de uma página (Início, Projetos, Músicas) — avança ou volta para a
  /// página adjacente do menu inferior, entrando já na aba correspondente
  /// (primeira ao avançar, última ao voltar), como se fosse um carrossel
  /// único de abas.
  void _handleEdgeSwipe(bool forward, BuildContext modalContext) {
    final targetIndex = _index + (forward ? 1 : -1);
    _handleSwipeTarget(targetIndex, modalContext);
  }

  Widget _buildPage(int index, BuildContext modalContext, UserState userState) {
    switch (index) {
      case 0:
        return EventsListPage(
          onOpenDrawer: _openDrawer,
          user: userState.user,
          isLoadingUser: userState.status == UserStatus.loading,
          onSwipeToNextPage: () => _handleEdgeSwipe(true, modalContext),
          onSwipeToPreviousPage: () => _handleEdgeSwipe(false, modalContext),
          tabArrivalToken: _tabArrivalForIndex == 0 ? _tabArrivalNonce : null,
          tabArrivalLandOnLast: _tabArrivalLandOnLast,
        );
      case 1:
        return MusicProjectsTabPage(
          onGoHome: () => _setIndex(0),
          onSwipeToNextPage: () => _handleEdgeSwipe(true, modalContext),
          onSwipeToPreviousPage: () => _handleEdgeSwipe(false, modalContext),
          tabArrivalToken: _tabArrivalForIndex == 1 ? _tabArrivalNonce : null,
          tabArrivalLandOnLast: _tabArrivalLandOnLast,
        );
      case 2:
        return SongsListPage(
          onSwipeToNextPage: () => _handleEdgeSwipe(true, modalContext),
          onSwipeToPreviousPage: () => _handleEdgeSwipe(false, modalContext),
          tabArrivalToken: _tabArrivalForIndex == 2 ? _tabArrivalNonce : null,
          tabArrivalLandOnLast: _tabArrivalLandOnLast,
        );
      default:
        return const AvisosPage();
    }
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

  Future<void> _openProjectSelector(BuildContext modalContext) async {
    Navigator.of(context).pop();
    final selected = await showProjectSelector(modalContext);
    if (!mounted) return;
    if (selected != null) {
      _setIndex(1);
    }
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
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _setIndex(0);
      },
      child: MultiBlocProvider(
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
                    onSongCategoriesTap: () =>
                        _openRoute(SongCategoriesPage.routeName),
                    onProjectsTap: () => _openProjectSelector(modalContext),
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeInOutCubicEmphasized,
                      switchOutCurve: Curves.easeInOutCubicEmphasized,
                      transitionBuilder: (child, animation) {
                        final isEntering = child.key == ValueKey(_index);
                        final direction = _movingForward ? 1.0 : -1.0;
                        // Desloca só uma fração da largura (não 100%) e
                        // combina com fade — um corte brusco de borda a
                        // borda parece mais "duro" que um deslize curto
                        // com esmaecimento, mesmo com a mesma curva/duração.
                        final tween = isEntering
                            ? Tween<Offset>(
                                begin: Offset(direction * 0.28, 0),
                                end: Offset.zero,
                              )
                            : Tween<Offset>(
                                begin: Offset.zero,
                                end: Offset(-direction * 0.28, 0),
                              );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: tween.animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: _buildPage(_index, modalContext, userState),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
