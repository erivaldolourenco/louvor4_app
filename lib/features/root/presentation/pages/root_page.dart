import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/music_projects/data/impl/music_projects_repository_impl.dart';
import 'package:louvor4_app/features/music_projects/presentation/cubit/project_cubit.dart';
import 'package:louvor4_app/features/music_projects/presentation/pages/music_projects_tab_page.dart';
import 'package:louvor4_app/features/music_projects/presentation/widgets/project_selector_bottom_sheet.dart';
import 'package:louvor4_app/features/songs/presentation/pages/songs_list_page.dart';
import 'package:louvor4_app/features/user_profile/apresentation/pages/profile_page.dart';

import '../../../events/presentation/pages/events_list_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;
  late final ProjectCubit _projectCubit;

  @override
  void initState() {
    super.initState();
    _projectCubit = ProjectCubit(MusicProjectsRepositoryImpl())..loadProjects();
  }

  @override
  void dispose() {
    _projectCubit.close();
    super.dispose();
  }

  Future<void> _go(int i, BuildContext modalContext) async {
    if (i == 1) {
      final selected = await showProjectSelector(modalContext);
      if (!mounted) return;

      if (selected != null) {
        setState(() => _index = 1);
      }
      return;
    }

    if (_index == i) return;
    setState(() => _index = i);
  }

  Widget _buildIcon(
    String assetName,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    return SvgPicture.asset(
      assetName,
      height: isActive ? 32 : 28,
      width: isActive ? 32 : 28,
      colorFilter: ColorFilter.mode(
        isActive ? activeColor : inactiveColor,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    const inactiveColor = Color(0xFF4D4D4D);

    return BlocProvider.value(
      value: _projectCubit,
      child: Builder(
        builder: (modalContext) {
          return Scaffold(
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1.0),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => _go(i, modalContext),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: activeColor,
                unselectedItemColor: inactiveColor,
                selectedFontSize: 14,
                unselectedFontSize: 14,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  BottomNavigationBarItem(
                    label: 'Início',
                    icon: _buildIcon(
                      'assets/icons/layout-dashboard.svg',
                      _index == 0,
                      activeColor,
                      inactiveColor,
                    ),
                    activeIcon: _buildIcon(
                      'assets/icons/layout-dashboard.svg',
                      true,
                      activeColor,
                      inactiveColor,
                    ),
                  ),
                  BottomNavigationBarItem(
                    label: 'Projetos',
                    icon: _buildIcon(
                      'assets/icons/music.svg',
                      _index == 1,
                      activeColor,
                      inactiveColor,
                    ),
                    activeIcon: _buildIcon(
                      'assets/icons/music.svg',
                      true,
                      activeColor,
                      inactiveColor,
                    ),
                  ),
                  BottomNavigationBarItem(
                    label: 'Músicas',
                    icon: _buildIcon(
                      'assets/icons/audio-lines.svg',
                      _index == 2,
                      activeColor,
                      inactiveColor,
                    ),
                    activeIcon: _buildIcon(
                      'assets/icons/audio-lines.svg',
                      true,
                      activeColor,
                      inactiveColor,
                    ),
                  ),
                  BottomNavigationBarItem(
                    label: 'Perfil',
                    icon: _buildIcon(
                      'assets/icons/circle-user-round.svg',
                      _index == 3,
                      activeColor,
                      inactiveColor,
                    ),
                    activeIcon: _buildIcon(
                      'assets/icons/circle-user-round.svg',
                      true,
                      activeColor,
                      inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
            body: IndexedStack(
              index: _index,
              children: const [
                EventsListPage(),
                MusicProjectsTabPage(),
                SongsListPage(),
                ProfilePage(),
              ],
            ),
          );
        },
      ),
    );
  }
}
