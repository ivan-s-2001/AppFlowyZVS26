import 'package:appflowy/rgatu/portal_config.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';

/// Seeds the RGATU student portal on first workspace open.
///
/// ZVS-26 is the pilot profile, but the structure is intentionally group-agnostic:
/// group selection/sync can replace [RgatuPortalConfig.defaultGroup] later.
class RgatuPortalSeeder {
  const RgatuPortalSeeder._();

  static const String _marker = '🎓 РГАТУ Студент';

  static const List<String> _pilotSubjects = [
    'Экономика',
    'Культурология',
    'Математический анализ',
    'Физическая культура',
    'История России',
    'Линейная алгебра и геометрия',
    'Теоретические основы информатики и ИКТ',
    'Иностранный язык',
    'Дискретная математика',
    'Основы программирования',
  ];

  static const List<String> _pilotTeachers = [
    'Авдеева В.В.',
    'Бурцев А.И.',
    'Гайдуков Э.А.',
    'Гусарова Н.И.',
    'Каленов А.С.',
    'Сидорова И.М.',
    'Сизов П.В.',
    'Ферагина Е.А.',
    'Фоменко С.А.',
    'Чижикова Н.В.',
  ];

  static Future<void> ensureSeeded(String workspaceId) async {
    if (workspaceId.isEmpty) return;

    final allViewsResult = await ViewBackendService.getAllViews();
    final alreadySeeded = allViewsResult.fold(
      (views) => views.items.any((view) => view.name == _marker),
      (error) {
        Log.error('RGATU portal seeder: failed to read views: ${error.msg}');
        return true;
      },
    );

    if (alreadySeeded) return;

    await _createDocument(parentId: workspaceId, name: _marker);

    await _createDocument(
      parentId: workspaceId,
      name: '👤 Профиль · ${RgatuPortalConfig.defaultGroup}',
    );

    final schedule = await _createDocument(
      parentId: workspaceId,
      name: '📅 Расписание',
    );
    if (schedule != null) {
      await _createDocument(parentId: schedule.id, name: 'По группе');
      await _createDocument(parentId: schedule.id, name: 'По преподавателю');
      await _createDocument(parentId: schedule.id, name: 'Изменения расписания');
    }

    final group = await _createDocument(
      parentId: workspaceId,
      name: '👥 Моя группа · ${RgatuPortalConfig.defaultGroup}',
    );

    if (group != null) {
      final semester = await _createDocument(
        parentId: group.id,
        name: '1️⃣ 1 семестр',
      );
      if (semester != null) {
        for (final subject in _pilotSubjects) {
          await _createDocument(parentId: semester.id, name: subject);
        }
      }

      await _createDocument(parentId: group.id, name: '📢 Объявления группы');
      await _createDocument(parentId: group.id, name: '📎 Материалы группы');
    }

    final sessions = await _createDocument(
      parentId: workspaceId,
      name: '🎓 Сессии',
    );
    if (sessions != null) {
      await _createDocument(parentId: sessions.id, name: 'Установочная сессия');
      await _createDocument(parentId: sessions.id, name: 'Экзаменационная сессия');
      await _createDocument(parentId: sessions.id, name: 'Зачёты и экзамены');
    }

    await _createDocument(parentId: workspaceId, name: '📝 ДКР и задания');

    final teachers = await _createDocument(
      parentId: workspaceId,
      name: '👨‍🏫 Преподаватели',
    );
    if (teachers != null) {
      for (final teacher in _pilotTeachers) {
        await _createDocument(parentId: teachers.id, name: teacher);
      }
    }

    final campus = await _createDocument(
      parentId: workspaceId,
      name: '🏫 Корпуса и аудитории',
    );
    if (campus != null) {
      await _createDocument(parentId: campus.id, name: 'Главный корпус');
      await _createDocument(parentId: campus.id, name: 'Корпус 1');
      await _createDocument(parentId: campus.id, name: 'Корпус 3');
      await _createDocument(parentId: campus.id, name: 'Как читать номер аудитории');
    }

    final accounts = await _createDocument(
      parentId: workspaceId,
      name: '🔐 Личные кабинеты и сервисы',
    );
    if (accounts != null) {
      await _createDocument(parentId: accounts.id, name: 'ЛК1');
      await _createDocument(parentId: accounts.id, name: 'ЛК2');
      await _createDocument(parentId: accounts.id, name: 'Сайт РГАТУ');
      await _createDocument(parentId: accounts.id, name: 'ФЗО');
    }

    await _createDocument(parentId: workspaceId, name: '📚 Общая база знаний');
    await _createDocument(parentId: workspaceId, name: '📎 Общие материалы');
    await _createDocument(parentId: workspaceId, name: '🗃 Архив');

    Log.info(
      'RGATU student portal seeded for workspace $workspaceId; '
      'pilot group: ${RgatuPortalConfig.defaultGroup}',
    );
  }

  static Future<ViewPB?> _createDocument({
    required String parentId,
    required String name,
  }) async {
    final result = await ViewBackendService.createView(
      layoutType: ViewLayoutPB.Document,
      parentViewId: parentId,
      name: name,
    );

    return result.fold(
      (view) => view,
      (error) {
        Log.error('RGATU portal seeder: failed to create "$name": ${error.msg}');
        return null;
      },
    );
  }
}
