import 'package:appflowy/rgatu/portal_config.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';

/// Seeds the private ZVS-26 RGATU workspace once.
///
/// This application is intentionally single-group. There is no group picker,
/// multi-tenant university portal or schedule module here.
class RgatuPortalSeeder {
  const RgatuPortalSeeder._();

  static const String _marker = '🎓 ЗВС-26 · РГАТУ';

  static const List<String> _subjects = [
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

  static const List<String> _teachers = [
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
        Log.error('ZVS-26 portal seeder: failed to read views: ${error.msg}');
        return true;
      },
    );

    if (alreadySeeded) return;

    await _createDocument(parentId: workspaceId, name: _marker);
    await _createDocument(parentId: workspaceId, name: '📢 Важное');

    final semester = await _createDocument(
      parentId: workspaceId,
      name: '1️⃣ 1 семестр',
    );
    if (semester != null) {
      for (final subject in _subjects) {
        await _createDocument(parentId: semester.id, name: subject);
      }
    }

    await _createDocument(parentId: workspaceId, name: '📝 ДКР и задания');

    final sessions = await _createDocument(
      parentId: workspaceId,
      name: '🎓 Сессии',
    );
    if (sessions != null) {
      await _createDocument(parentId: sessions.id, name: 'Установочная сессия');
      await _createDocument(parentId: sessions.id, name: 'Экзаменационная сессия');
      await _createDocument(parentId: sessions.id, name: 'Зачёты и экзамены');
    }

    final teachers = await _createDocument(
      parentId: workspaceId,
      name: '👨‍🏫 Преподаватели',
    );
    if (teachers != null) {
      for (final teacher in _teachers) {
        await _createDocument(parentId: teachers.id, name: teacher);
      }
    }

    await _createDocument(parentId: workspaceId, name: '📚 Материалы');

    final university = await _createDocument(
      parentId: workspaceId,
      name: '🏫 РГАТУ',
    );
    if (university != null) {
      await _createDocument(parentId: university.id, name: 'ЛК1');
      await _createDocument(parentId: university.id, name: 'ЛК2');
      await _createDocument(parentId: university.id, name: 'ФЗО');
      await _createDocument(parentId: university.id, name: 'Корпуса и аудитории');
      await _createDocument(parentId: university.id, name: 'Полезные ссылки');
    }

    final group = await _createDocument(
      parentId: workspaceId,
      name: '👥 Наша группа',
    );
    if (group != null) {
      await _createDocument(parentId: group.id, name: 'Участники');
      await _createDocument(parentId: group.id, name: 'Объявления');
      await _createDocument(parentId: group.id, name: 'Договорённости');
    }

    await _createDocument(parentId: workspaceId, name: '🗃 Архив');

    Log.info(
      'Private ${RgatuPortalConfig.group} RGATU portal seeded for workspace '
      '$workspaceId',
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
        Log.error('ZVS-26 portal seeder: failed to create "$name": ${error.msg}');
        return null;
      },
    );
  }
}
