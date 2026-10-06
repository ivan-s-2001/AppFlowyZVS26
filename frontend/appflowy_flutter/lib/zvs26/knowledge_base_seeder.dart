import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';

/// Creates the initial ZVS-26 knowledge-base structure once per workspace.
///
/// The marker page makes this operation idempotent, so opening the workspace
/// again does not duplicate pages.
class Zvs26KnowledgeBaseSeeder {
  const Zvs26KnowledgeBaseSeeder._();

  static const String _marker = '1️⃣ 1 семестр';

  // Subjects are seeded from the current ZVS-26 first-year installation-session
  // schedule snapshot (06.10.2026). The schedule integration can replace this
  // static list with synchronized data later.
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
    if (workspaceId.isEmpty) {
      return;
    }

    final allViewsResult = await ViewBackendService.getAllViews();
    final alreadySeeded = allViewsResult.fold(
      (views) => views.items.any((view) => view.name == _marker),
      (error) {
        Log.error('ZVS-26 seeder: unable to read workspace views: ${error.msg}');
        // Fail closed. A transient read error must not create duplicate trees.
        return true;
      },
    );

    if (alreadySeeded) {
      return;
    }

    await _createDocument(parentId: workspaceId, name: '🏠 Главная');

    final semester = await _createDocument(
      parentId: workspaceId,
      name: _marker,
    );

    if (semester != null) {
      for (final subject in _subjects) {
        await _createDocument(parentId: semester.id, name: subject);
      }
    }

    final sessions = await _createDocument(
      parentId: workspaceId,
      name: '🎓 Сессии',
    );

    if (sessions != null) {
      await _createDocument(
        parentId: sessions.id,
        name: 'Установочная сессия',
      );
      await _createDocument(
        parentId: sessions.id,
        name: 'Экзаменационная сессия',
      );
    }

    await _createDocument(
      parentId: workspaceId,
      name: '📝 ДКР и задания',
    );

    final teachers = await _createDocument(
      parentId: workspaceId,
      name: '👨‍🏫 Преподаватели',
    );

    if (teachers != null) {
      for (final teacher in _teachers) {
        await _createDocument(parentId: teachers.id, name: teacher);
      }
    }

    await _createDocument(parentId: workspaceId, name: '📎 Материалы');
    await _createDocument(parentId: workspaceId, name: '🔗 Важные ссылки');
    await _createDocument(parentId: workspaceId, name: '🗃 Архив');

    Log.info('ZVS-26 knowledge base seeded for workspace $workspaceId');
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
        Log.error('ZVS-26 seeder: failed to create "$name": ${error.msg}');
        return null;
      },
    );
  }
}
